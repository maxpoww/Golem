import sys,functools,http.server
class H(http.server.SimpleHTTPRequestHandler):
    protocol_version="HTTP/1.1"
    def log_message(self,*a): pass
    def end_headers(self):
        self.send_header("Cache-Control","no-store" if self.path.endswith((".html","/")) else "max-age=3600"); super().end_headers()
http.server.ThreadingHTTPServer(("0.0.0.0",int(sys.argv[1])),functools.partial(H,directory=sys.argv[2])).serve_forever()
