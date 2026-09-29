// cdp-driver.mjs <port> <out.json> <proctree.py> <chromePid> <url,url,...>
// Drives headless Chrome exactly like Seam's bench hook drives Seam in sites mode:
// settle 3.5s, then per URL: navigate, wait for load, wait 2.5s, read the page's own
// navigation timing + count responses (all / third-party). CPU + memory from /proc
// (proctree.py) for the whole tree — the same reader used for Seam.
import { execFileSync } from "node:child_process";
import { writeFileSync } from "node:fs";
const [port, out, pt, cpid, list] = process.argv.slice(2);
const urls = list.split(",");
const sleep = ms => new Promise(r => setTimeout(r, ms));
const proc = () => JSON.parse(execFileSync("python3", [pt, cpid]).toString());
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const page = targets.find(t => t.type === "page");
const ws = new WebSocket(page.webSocketDebuggerUrl);
let id = 0; const wait = new Map(); const listeners = [];
ws.onmessage = e => { const m = JSON.parse(e.data); if (m.id && wait.has(m.id)) { wait.get(m.id)(m); wait.delete(m.id); } else listeners.forEach(f => f(m)); };
await new Promise(r => ws.onopen = r);
const send = (method, params = {}) => new Promise(r => { const i = ++id; wait.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
await send("Page.enable"); await send("Network.enable");
const R = { sites: [], startup: {}, loads: [] };
await sleep(parseInt(process.env.SEAM_BENCH_SETTLE || "3500"));
const p0 = proc();
for (const u of urls) {
  let host = ""; try { host = new URL(u).hostname.replace(/^www\./, ""); } catch {}
  const net = { n: 0, n3: 0, kb3: 0, byId: new Map() };
  const onNet = m => {
    if (m.method === "Network.responseReceived") { const h = new URL(m.params.response.url).hostname; net.n++; const third = host && h !== host && !h.endsWith("." + host); net.byId.set(m.params.requestId, third); if (third) net.n3++; }
    if (m.method === "Network.loadingFinished" && net.byId.get(m.params.requestId)) net.kb3 += (m.params.encodedDataLength || 0) / 1024;
  };
  listeners.push(onNet);
  const loaded = new Promise(r => { const f = m => { if (m.method === "Page.loadEventFired") { listeners.splice(listeners.indexOf(f), 1); r(); } }; listeners.push(f); });
  const t = Date.now();
  await send("Page.navigate", { url: u });
  const ok = await Promise.race([loaded.then(() => true), sleep(60000).then(() => false)]);
  const wall = ok ? Date.now() - t : -1;
  await sleep(2500);
  const ev = await send("Runtime.evaluate", { returnByValue: true, expression:
    "(function(){var n=performance.getEntriesByType('navigation')[0]||{};var f=(performance.getEntriesByType('paint')||[]).filter(function(e){return e.name==='first-contentful-paint';})[0];return {dcl:Math.round(n.domContentLoadedEventEnd||0),load:Math.round(n.loadEventEnd||0),fcp:f?Math.round(f.startTime):null};})()" });
  listeners.splice(listeners.indexOf(onNet), 1);
  const v = (ev.result && ev.result.result && ev.result.result.value) || {};
  R.sites.push({ url: u, wallMs: wall, ...v, resp: net.n, resp3p: net.n3, resp3pKB: Math.round(net.kb3) });
}
const p1 = proc();
R.cpuMsTotal = p1.cpuMs - p0.cpuMs; R.memEnd = p1; R.ext = { cpuMs: p1.cpuMs - p0.cpuMs, anonMB: p1.anonMB, rssMB: p1.rssMB, procs: p1.procs };
writeFileSync(out, JSON.stringify(R));
ws.close();
