// Checks the real site under a repository-style subpath with headless Chrome.
// No npm dependencies or publication. Run: node tool/check_pages.mjs
import { createServer } from 'node:http';
import { readFile, mkdir, mkdtemp, writeFile } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import { spawn } from 'node:child_process';

const root = resolve('docs');
const prefix = '/Practicas_DMI_230881/';
const requests = [];
const server = createServer(async (req, res) => {
  const pathname = new URL(req.url, 'http://localhost').pathname;
  if (pathname === '/favicon.ico') { res.writeHead(204).end(); return; }
  if (!pathname.startsWith(prefix)) { res.writeHead(404).end(); return; }
  const file = resolve(root, decodeURIComponent(pathname.slice(prefix.length)) || 'index.html');
  if (!file.startsWith(root + sep)) { res.writeHead(403).end(); return; }
  try {
    const bytes = await readFile(file);
    const types = { '.html': 'text/html; charset=utf-8', '.png': 'image/png', '.json': 'application/json', '.md': 'text/plain; charset=utf-8' };
    requests.push({ path: pathname, status: 200 });
    res.writeHead(200, { 'Content-Type': types[extname(file)] || 'application/octet-stream' }).end(bytes);
  } catch {
    requests.push({ path: pathname, status: 404 });
    res.writeHead(404).end();
  }
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
await mkdir('build', { recursive: true });
const profile = await mkdtemp(resolve('build/pages-chrome-'));
const chrome = spawn(process.env.CHROME_EXECUTABLE || 'C:/Program Files/Google/Chrome/Application/chrome.exe', [
  '--headless=new', '--remote-debugging-port=0', `--user-data-dir=${profile}`,
  '--disable-background-networking', '--no-first-run', '--no-default-browser-check', 'about:blank',
], { windowsHide: true, stdio: 'ignore' });
let socket;
const result = { prefix, pages: [], requests, ok: false };
try {
  let port;
  for (let i = 0; i < 100; i++) {
    try { port = Number((await readFile(resolve(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0]); break; } catch {}
    await new Promise(r => setTimeout(r, 100));
  }
  if (!port) throw Error('Chrome did not start');
  const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  socket = new WebSocket(targets.find(t => t.type === 'page').webSocketDebuggerUrl);
  await new Promise((r, reject) => { socket.onopen = r; socket.onerror = reject; });
  let next = 0;
  const pending = new Map();
  let failures = [], exceptions = [], resourceURLs = [];
  socket.onmessage = ({ data }) => {
    const message = JSON.parse(data);
    if (message.id) {
      const { resolve, reject } = pending.get(message.id);
      pending.delete(message.id);
      message.error ? reject(Error(JSON.stringify(message.error))) : resolve(message.result);
    }
    if (message.method === 'Network.loadingFailed') failures.push(message.params.errorText);
    if (message.method === 'Runtime.exceptionThrown') exceptions.push(message.params.exceptionDetails.text);
    if (message.method === 'Network.requestWillBeSent') resourceURLs.push(message.params.request.url);
  };
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++next; pending.set(id, { resolve, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
  await send('Page.enable'); await send('Runtime.enable'); await send('Network.enable');
  const base = `http://127.0.0.1:${server.address().port}${prefix}`;
  for (const page of ['index.html', 'diagrams/general.html', 'diagrams/especifica.html']) {
    failures = []; exceptions = []; resourceURLs = [];
    await send('Page.navigate', { url: base + page });
    await new Promise(r => setTimeout(r, 1500));
    const evaluation = await send('Runtime.evaluate', { expression: `(async () => {
      await document.fonts.ready;
      return { title: document.title, svg: document.querySelectorAll('svg').length,
        dependencies: Array.from(document.querySelectorAll('script[src],link[href],img[src]')).map(e=>e.getAttribute('src')||e.getAttribute('href')),
        links: Array.from(document.querySelectorAll('a[href]')).map(e=>e.getAttribute('href')) };
    })()`, awaitPromise: true, returnByValue: true });
    if (evaluation.exceptionDetails) throw Error(JSON.stringify(evaluation.exceptionDetails));
    const info = evaluation.result.value;
    // Chrome may request /favicon.ico implicitly; it is not a page dependency.
    const external = resourceURLs.filter(u => /^https?:/.test(u) && new URL(u).origin !== new URL(base).origin);
    const absolute = info.dependencies.filter(u => u.startsWith('/') || /^(file:|[A-Za-z]:)/.test(u));
    const links = [];
    for (const link of info.links.filter(u => u && !/^(#|https?:|data:|mailto:)/.test(u))) {
      const url = new URL(link, base + page);
      const response = await fetch(url);
      links.push({ href: link, status: response.status });
    }
    const ok = !failures.length && !exceptions.length && !external.length && !absolute.length && links.every(l => l.status === 200);
    result.pages.push({ page, ...info, external, absolute, failures: [...failures], exceptions: [...exceptions], links, ok });
    if (!ok) throw Error(`Page failed: ${page}`);
  }
  result.ok = requests.every(r => r.status === 200);
} catch (error) {
  result.error = String(error); process.exitCode = 1;
} finally {
  socket?.close(); chrome.kill(); server.closeAllConnections(); server.close();
  await writeFile('docs/evidence/pages-relative-check.json', JSON.stringify(result, null, 2));
}
console.log(JSON.stringify({ ok: result.ok, pages: result.pages.map(p => ({ page: p.page, ok: p.ok })), error: result.error }));
