#!/usr/bin/env python3
"""chrome-loads.py — load URLs one after another in a running Chrome and report each page's
timings, so a Chrome-vs-Seam comparison can use the SAME pages, machine and hour as lab.sh.

Chrome must run with --remote-debugging-port=9222 (reach it through an ssh tunnel from the dev
box: `ssh -L 9222:127.0.0.1:9222 root@<laptop>`; Chrome only answers Host: localhost). One tab,
sequential, 40 s cap per page. Prints one JSON line per URL: navigationStart→responseStart /
domContentLoadedEventEnd / loadEventEnd, first-contentful-paint, and the wall time until load.
Standard library only (the laptops have no python; this runs on the dev box).

    python3 chrome-loads.py localhost:9222 https://a.com https://b.com …
"""
import base64, json, os, socket, struct, sys, time, urllib.request

HOST = sys.argv[1] if len(sys.argv) > 1 else "localhost:9222"
URLS = sys.argv[2:]
CAP = float(os.environ.get("MS", "40000")) / 1000.0


class WS:
    """Minimal RFC 6455 client: text frames, client-masked, no extensions."""
    def __init__(self, url):
        _, rest = url.split("://", 1)
        hostport, path = rest.split("/", 1)
        host, port = hostport.split(":") if ":" in hostport else (hostport, "80")
        self.s = socket.create_connection((host, int(port)), timeout=60)
        key = base64.b64encode(os.urandom(16)).decode()
        self.s.sendall((f"GET /{path} HTTP/1.1\r\nHost: {hostport}\r\nUpgrade: websocket\r\n"
                        f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
        buf = b""
        while b"\r\n\r\n" not in buf:
            buf += self.s.recv(4096)
        if b" 101 " not in buf.split(b"\r\n", 1)[0]:
            raise RuntimeError("websocket handshake failed: " + buf.split(b"\r\n", 1)[0].decode(errors="replace"))
        self.rest = buf.split(b"\r\n\r\n", 1)[1]
        self.id = 0

    def _recvn(self, n):
        out = self.rest[:n]; self.rest = self.rest[n:]
        while len(out) < n:
            chunk = self.s.recv(min(65536, n - len(out)))
            if not chunk:
                raise ConnectionError("websocket closed")
            out += chunk
        return out

    def send(self, obj):
        data = json.dumps(obj).encode()
        hdr = bytearray([0x81])
        n = len(data)
        if n < 126: hdr.append(0x80 | n)
        elif n < 65536: hdr += bytes([0x80 | 126]) + struct.pack(">H", n)
        else: hdr += bytes([0x80 | 127]) + struct.pack(">Q", n)
        mask = os.urandom(4)
        self.s.sendall(bytes(hdr) + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

    def recv(self):
        while True:
            b0, b1 = self._recvn(2)
            op = b0 & 0x0F; n = b1 & 0x7F
            if n == 126: n = struct.unpack(">H", self._recvn(2))[0]
            elif n == 127: n = struct.unpack(">Q", self._recvn(8))[0]
            if b1 & 0x80: self._recvn(4)   # servers do not mask
            data = self._recvn(n)
            if op == 0x1: return json.loads(data)
            if op == 0x8: raise ConnectionError("websocket closed by peer")
            if op == 0x9:   # ping -> pong
                mask = os.urandom(4)
                self.s.sendall(bytes([0x8A, 0x80 | len(data)]) + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

    def call(self, method, **params):
        self.id += 1; mid = self.id
        self.send({"id": mid, "method": method, "params": params})
        while True:
            m = self.recv()
            if m.get("id") == mid:
                if "error" in m: raise RuntimeError(f"{method}: {m['error']}")
                return m.get("result", {})


def main():
    base = f"http://{HOST}"
    ver = json.load(urllib.request.urlopen(base + "/json/version", timeout=10))
    print(json.dumps({"browser": ver.get("Browser"), "ua": ver.get("User-Agent", "")[:80]}), flush=True)
    tab = json.loads(urllib.request.urlopen(urllib.request.Request(base + "/json/new?about:blank", method="PUT"), timeout=10).read())
    ws = WS(tab["webSocketDebuggerUrl"])
    ws.call("Page.enable")
    total0 = time.time()
    for url in URLS:
        t0 = time.time()
        ws.call("Page.navigate", url=url)
        row = {"url": url}
        while time.time() - t0 < CAP:
            r = ws.call("Runtime.evaluate", returnByValue=True, expression=(
                "(function(){var t=performance.timing;var p=performance.getEntriesByType('paint')"
                ".filter(function(e){return e.name==='first-contentful-paint'})[0];"
                "return {rs:t.responseStart-t.navigationStart,dcl:t.domContentLoadedEventEnd-t.navigationStart,"
                "load:t.loadEventEnd>0?t.loadEventEnd-t.navigationStart:0,fcp:p?Math.round(p.startTime):0,"
                "state:document.readyState,href:location.href,phases:(function(){var N=performance.getEntriesByType('navigation')[0];if(!N)return null;return {redirect:Math.round(N.redirectEnd-N.redirectStart),fetchStart:Math.round(N.fetchStart),dns:Math.round(N.domainLookupEnd-N.domainLookupStart),connect:Math.round(N.connectEnd-N.connectStart),tls:N.secureConnectionStart?Math.round(N.connectEnd-N.secureConnectionStart):0,ttfb:Math.round(N.responseStart-N.requestStart),response:Math.round(N.responseEnd-N.responseStart),proto:N.nextHopProtocol};})()};})()"))
            v = r.get("result", {}).get("value") or {}
            if v.get("load") and v.get("href", "about:blank") != "about:blank":
                row.update(v); break
            time.sleep(0.25)
        row["wall_ms"] = round((time.time() - t0) * 1000)
        if "load" not in row: row.update(v); row["timeout"] = True
        print(json.dumps(row), flush=True)
        time.sleep(1.0)
    print(json.dumps({"total_wall_s": round(time.time() - total0, 1), "pages": len(URLS)}), flush=True)
    try: urllib.request.urlopen(base + "/json/close/" + tab["id"], timeout=5).read()
    except Exception: pass


if __name__ == "__main__":
    main()
