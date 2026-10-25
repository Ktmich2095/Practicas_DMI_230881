// Verify the repository menu -> Practice 05 portal -> Archify chain under the Pages prefix.
import { createServer } from 'node:http';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import { execFileSync } from 'node:child_process';
import { ChromeVisualBrowser } from '../.agents/skills/archify/bin/visual-check.mjs';

const root = resolve('../..');
const prefix = '/Practicas_DMI_230881/';
const out = resolve('docs/evidence/screenshots');
await mkdir(out, { recursive: true });
const report = { checkedAt: new Date().toISOString(), prefix, pages: [], links: [], ok: false };
const types = { '.html': 'text/html; charset=utf-8', '.json': 'application/json', '.png': 'image/png', '.md': 'text/plain; charset=utf-8' };
const server = createServer(async (req, res) => {
  const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  if (pathname === '/favicon.ico') return res.writeHead(204).end();
  if (!pathname.startsWith(prefix)) return res.writeHead(404).end();
  const relative = pathname.slice(prefix.length);
  const file = resolve(root, (relative || 'index.html') + (relative.endsWith('/') ? 'index.html' : ''));
  if (!file.startsWith(root + sep)) return res.writeHead(403).end();
  try { res.writeHead(200, { 'Content-Type': types[extname(file)] || 'application/octet-stream' }).end(await readFile(file)); }
  catch { res.writeHead(404).end(); }
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
const browser = new ChromeVisualBrowser('C:/Program Files/Google/Chrome/Application/chrome.exe');
const wait = ms => new Promise(r => setTimeout(r, ms));
try {
  const session = await browser.sessionPromise;
  const send = (method, params = {}) => browser.cdp.send(method, params, session);
  const evaluate = async expression => {
    const r = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
    if (r.exceptionDetails) throw Error(JSON.stringify(r.exceptionDetails));
    return r.result.value;
  };
  const base = `http://127.0.0.1:${server.address().port}${prefix}`;
  const portal = 'Practica05/widgets_app/docs/';
  for (const width of [390, 1440]) {
    await send('Emulation.setDeviceMetricsOverride', { width, height: 1000, deviceScaleFactor: 1, mobile: false });
    for (const page of ['index.html', portal + 'index.html', portal + 'diagrams/general.html', portal + 'diagrams/especifica.html']) {
      await send('Page.navigate', { url: base + page });
      await wait(600);
      const info = await evaluate(`({title:document.title,width:innerWidth,scrollWidth:document.documentElement.scrollWidth,cards:document.querySelectorAll('.grid > .card').length,viewer:!!window.Archify,links:[...document.querySelectorAll('a[href],img[src]')].map(e=>e.getAttribute('href')||e.getAttribute('src'))})`);
      if (info.scrollWidth > width) throw Error(`Overflow ${width}: ${page}`);
      if (page === 'index.html' && info.cards !== 4) throw Error('Expected the original three cards plus practice 05');
      if (page.includes('diagrams/')) {
        if (!info.viewer) throw Error(`Missing Archify viewer: ${page}`);
        info.zoomWorks = await evaluate(`(() => { const before=Archify.view.state().scale; Archify.view.zoomIn(); const after=Archify.view.state().scale; Archify.view.reset(); return after>before; })()`);
        if (!info.zoomWorks) throw Error(`Archify zoom failed: ${page}`);
      }
      // Validate all practice 05 destinations, not historical links to other branches' practices.
      if (page !== 'index.html') {
        for (const link of info.links.filter(x => x && !/^(#|https?:|mailto:|data:)/.test(x))) {
          const url = new URL(link, base + page); url.hash = '';
          const response = await fetch(url);
          report.links.push({ path: url.pathname, status: response.status });
          if (!response.ok) throw Error(`Broken link: ${url.pathname}`);
        }
      } else {
        const original = execFileSync('git', ['show', 'HEAD:index.html'], { cwd: root, encoding: 'utf8' });
        const links = [...original.matchAll(/href="([^"]+)"/g)].map(m => m[1]);
        if (!links.every(link => info.links.includes(link))) throw Error('An original menu link was changed');
        if (!info.links.includes(portal + 'index.html')) throw Error('Missing practice 05 portal link');
        await evaluate(`document.querySelector('.card:last-child').scrollIntoView({behavior:'instant',block:'center'})`);
      }
      if (page === 'index.html' || page === portal + 'index.html') {
        const shot = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false });
        await writeFile(resolve(out, `${page === 'index.html' ? 'menu-practicas' : 'portal-practica05'}-${width}.png`), Buffer.from(shot.data, 'base64'));
      }
      report.pages.push({ page, width, title: info.title, cards: info.cards, viewer: info.viewer, zoomWorks: info.zoomWorks, overflow: false });
    }
  }
  for (const name of ['general', 'especifica']) {
    const json = await (await fetch(base + portal + `diagrams/${name}.archify.json`)).json();
    if (json.diagram_type !== 'architecture' || !json.components.length) throw Error('Invalid editable source');
  }
  // All embedded screenshots in both READMEs must exist at their actual relative paths.
  for (const file of ['README.md', '../README.md']) {
    // The folder-level README is optional; the Flutter project's README is required.
    let text;
    try { text = await readFile(file, 'utf8'); }
    catch (error) { if (file === '../README.md' && error.code === 'ENOENT') continue; throw error; }
    const dir = resolve(file, '..');
    for (const match of text.matchAll(/(?:src="|!\[[^\]]*\]\()([^"\s)]+)/g)) {
      if (!/^https?:/.test(match[1])) await readFile(resolve(dir, match[1]));
    }
  }
  report.ok = true;
} catch (error) { report.error = String(error); process.exitCode = 1; }
finally {
  await writeFile(resolve(out, 'site-check.json'), JSON.stringify(report, null, 2));
  await browser.close(); server.closeAllConnections(); server.close();
}
console.log(JSON.stringify({ ok: report.ok, pages: report.pages.length, links: report.links.length, error: report.error }));
