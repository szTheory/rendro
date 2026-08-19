import http from "node:http";
import { readFile, stat } from "node:fs/promises";
import { extname, normalize, resolve, sep } from "node:path";

const root = resolve(process.cwd(), "../..");
const types = { ".css": "text/css", ".html": "text/html", ".js": "text/javascript", ".json": "application/json", ".png": "image/png" };
const allowed = ["assets/rendro/", "brand/tokens/"];
const safePath = (url) => {
  const requested = decodeURIComponent(new URL(url, "http://localhost").pathname).replace(/^\/+/, "");
  const pathname = requested.startsWith("configurator/") || requested === "catalog.json" || requested.startsWith("catalog/")
    ? `assets/rendro/${requested}`
    : requested;
  const candidate = resolve(root, normalize(pathname));
  const relative = candidate.slice(root.length + 1).split(sep).join("/");
  return allowed.some((prefix) => relative.startsWith(prefix)) ? candidate : null;
};

http.createServer(async (request, response) => {
  const file = safePath(request.url);
  try {
    if (!file || !(await stat(file)).isFile()) throw new Error("not found");
    response.writeHead(200, { "content-type": types[extname(file)] || "application/octet-stream", "cache-control": "no-store" });
    response.end(await readFile(file));
  } catch {
    response.writeHead(404, { "content-type": "text/plain" });
    response.end("not found");
  }
}).listen(4174, "127.0.0.1");
