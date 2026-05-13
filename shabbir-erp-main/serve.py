import http.server
import socketserver
import os

PORT = 5000
DIRECTORY = "build/web"

PATCHED_BOOTSTRAP_SUFFIX = """
if (!window._flutter) {
  window._flutter = {};
}
_flutter.buildConfig = {"engineRevision":"18818009497c581ede5d8a3b8b833b81d00cebb7","builds":[{"compileTarget":"dart2js","renderer":"html","mainJsPath":"main.dart.js"}]};

_flutter.loader.load({
  config: {
    renderer: "html"
  }
});
"""

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def log_message(self, format, *args):
        pass

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

    def do_GET(self):
        path = self.path.split("?")[0]

        # Patch flutter_bootstrap.js to force HTML renderer (no WebGL required)
        if path == "/flutter_bootstrap.js":
            filepath = os.path.join(DIRECTORY, "flutter_bootstrap.js")
            with open(filepath, "r") as f:
                content = f.read()

            # Strip everything after the sourcemap comment
            sourcemap_end = content.find("//# sourceMappingURL=flutter.js.map")
            if sourcemap_end != -1:
                js_part = content[:sourcemap_end + len("//# sourceMappingURL=flutter.js.map")]
            else:
                js_part = content

            patched = js_part + "\n" + PATCHED_BOOTSTRAP_SUFFIX
            encoded = patched.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/javascript")
            self.send_header("Content-Length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)
            return

        # Disable service worker by returning empty JS
        if path.startswith("/flutter_service_worker.js"):
            response = b"// service worker disabled\n"
            self.send_response(200)
            self.send_header("Content-Type", "application/javascript")
            self.send_header("Content-Length", str(len(response)))
            self.end_headers()
            self.wfile.write(response)
            return

        file_path = os.path.join(DIRECTORY, path.lstrip("/"))
        if not os.path.exists(file_path) or os.path.isdir(file_path):
            self.path = "/index.html"
        return super().do_GET()

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

with ReusableTCPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"Serving Flutter web app on port {PORT}")
    httpd.serve_forever()
