const http = require("http");
const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

const root = __dirname;
const phpCgi = "C:\\xampp\\php\\php-cgi.exe";
const port = Number(process.env.PORT || 8000);
const types = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".png": "image/png",
  ".jpeg": "image/jpeg",
  ".jpg": "image/jpeg",
  ".mp4": "video/mp4"
};

function runPhp(req, res, filePath, urlPath) {
  if (!fs.existsSync(phpCgi)) {
    res.writeHead(500, { "Content-Type": "application/json; charset=utf-8" });
    res.end(JSON.stringify({ ok: false, error: "PHP CGI not found at C:\\xampp\\php\\php-cgi.exe" }));
    return;
  }

  const chunks = [];
  req.on("data", (chunk) => chunks.push(chunk));
  req.on("end", () => {
    const body = Buffer.concat(chunks);
    const query = req.url.includes("?") ? req.url.slice(req.url.indexOf("?") + 1) : "";
    const php = spawn(phpCgi, [], {
      cwd: root,
      env: {
        ...process.env,
        REDIRECT_STATUS: "1",
        GATEWAY_INTERFACE: "CGI/1.1",
        SCRIPT_FILENAME: filePath,
        SCRIPT_NAME: `/${urlPath}`,
        REQUEST_METHOD: req.method,
        QUERY_STRING: query,
        CONTENT_TYPE: req.headers["content-type"] || "",
        CONTENT_LENGTH: String(body.length)
      }
    });

    const output = [];
    const errors = [];
    php.stdout.on("data", (chunk) => output.push(chunk));
    php.stderr.on("data", (chunk) => errors.push(chunk));
    php.on("close", (code) => {
      if (code !== 0) {
        res.writeHead(500, { "Content-Type": "application/json; charset=utf-8" });
        res.end(JSON.stringify({ ok: false, error: Buffer.concat(errors).toString() || "PHP API failed" }));
        return;
      }
      const raw = Buffer.concat(output).toString();
      const splitAt = raw.indexOf("\r\n\r\n") >= 0 ? raw.indexOf("\r\n\r\n") + 4 : raw.indexOf("\n\n") + 2;
      let payload = splitAt > 1 ? raw.slice(splitAt) : raw;
      const jsonStart = payload.search(/[\[{]/);
      if (jsonStart > 0) {
        payload = payload.slice(jsonStart);
      }
      res.writeHead(200, { "Content-Type": "application/json; charset=utf-8" });
      res.end(payload);
    });
    php.stdin.end(body);
  });
}

const server = http.createServer((req, res) => {
  const urlPath = decodeURIComponent(req.url.split("?")[0]);
  const filePath = path.join(root, urlPath === "/" ? "index.html" : urlPath);
  if (!filePath.startsWith(root)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }
  if (path.extname(filePath) === ".php") {
    runPhp(req, res, filePath, urlPath);
    return;
  }
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end("Not found");
      return;
    }
    res.writeHead(200, { "Content-Type": types[path.extname(filePath)] || "application/octet-stream" });
    res.end(data);
  });
});

server.listen(port, () => {
  console.log(`Motorstock running at http://localhost:${port}/index.html`);
});
