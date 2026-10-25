// Real screenshots of the compiled Flutter web app. No image generation or mocks.
// Run after: flutter build web --no-web-resources-cdn --no-wasm-dry-run
// Uses the installed Archify Chrome driver (Node 18+) and Chrome.
import { createServer } from 'node:http';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import { ChromeVisualBrowser } from '../.agents/skills/archify/bin/visual-check.mjs';

const root = resolve('build/web');
const out = resolve('docs/evidence/screenshots');
await mkdir(out, { recursive: true });
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.json': 'application/json', '.png': 'image/png', '.gif': 'image/gif', '.ttf': 'font/ttf' };
const server = createServer(async (req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  if (path === '/favicon.ico') return res.writeHead(204).end();
  const file = resolve(root, '.' + (path === '/' ? '/index.html' : path));
  if (!file.startsWith(root + sep)) return res.writeHead(403).end();
  try { res.writeHead(200, { 'Content-Type': mime[extname(file)] || 'application/octet-stream' }).end(await readFile(file)); }
  catch { res.writeHead(404).end(); }
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
const browser = new ChromeVisualBrowser(process.env.CHROME_EXECUTABLE || 'C:/Program Files/Google/Chrome/Application/chrome.exe');
const wait = ms => new Promise(r => setTimeout(r, ms));
const report = { capturedAt: new Date().toISOString(), platform: 'Flutter web / headless Chrome', viewport: { width: 430, height: 932, deviceScaleFactor: 1 }, screenshots: [], exceptions: [], ok: false };
try {
  const session = await browser.sessionPromise;
  browser.cdp.subscribers.add(message => {
    if (message.method === 'Runtime.exceptionThrown') report.exceptions.push(message.params.exceptionDetails);
  });
  const send = (method, params = {}) => browser.cdp.send(method, params, session);
  const evaluate = async expression => {
    const r = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
    if (r.exceptionDetails) throw Error(JSON.stringify(r.exceptionDetails));
    return r.result.value;
  };
  await send('Page.enable'); await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride', { ...report.viewport, mobile: true });
  const base = `http://127.0.0.1:${server.address().port}/`;
  const click = async (x, y) => {
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
    await wait(650);
  };
  const clickLabel = async text => {
    const point = await evaluate(`(() => {
      const all = [...document.querySelectorAll('flt-semantics')];
      const e = all.find(e => (e.getAttribute('aria-label') || e.textContent).trim() === ${JSON.stringify(text)});
      if (!e) return null;
      const r=e.getBoundingClientRect(); return {x:r.x+r.width/2,y:r.y+r.height/2};
    })()`);
    if (!point) throw Error(`Control missing: ${text}`);
    await click(point.x, point.y);
  };
  const navigate = async route => {
    // Reload to capture each screen with a reproducible initial state.
    await send('Page.navigate', { url: `${base}?capture=${Date.now()}#${route}` });
    for (let i = 0; i < 100; i++) {
      const ready = await evaluate(`Boolean(document.querySelector('flutter-view'))`);
      if (ready) break;
      await wait(100);
    }
    await wait(1800);
    await evaluate(`document.querySelector('flt-semantics-placeholder')?.click()`);
    await wait(350);
  };
  const capture = async (name, route, note = '') => {
    const bytes = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false });
    await writeFile(resolve(out, `${name}.png`), Buffer.from(bytes.data, 'base64'));
    const labels = await evaluate(`[...document.querySelectorAll('flt-semantics')].map(e=>e.getAttribute('aria-label') || e.textContent).filter(Boolean)`);
    report.screenshots.push({ file: `${name}.png`, route, note, labels });
    console.log(`Captured ${name}`);
  };
  for (const [name, route] of [
    ['01-inicio', '/'], ['02-contador', '/counter-river'], ['03-botones', '/buttons'],
    ['04-tarjetas', '/cards'], ['05-progreso', '/progress'], ['06-dialogos', '/snackbars'],
    ['07-animaciones', '/animated'], ['08-controles', '/ui-controls'],
    ['09-tutorial', '/tutorial'], ['10-lista-infinita', '/infinite'], ['11-temas', '/theme-changer'],
  ]) {
    await navigate(route);
    if (route === '/animated') await click(386, 888);
    if (route === '/ui-controls') await click(390, 174);
    if (route === '/infinite') await wait(8000);
    await capture(name, route);
    if (route === '/cards') {
      await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 210, y: 500, deltaX: 0, deltaY: 8000 });
      await wait(8000);
      await capture('04-tarjetas-imagenes', route, 'Scrolled to remote-image cards; network state is captured as rendered.');
    }
    if (route === '/snackbars') {
      await clickLabel('Mostrar diálogo'); await capture('06-confirmacion', route);
      await clickLabel('Cancelar'); await clickLabel('Licencias usadas'); await capture('06-acerca-de', route);
      await clickLabel('Close'); await clickLabel('Mostrar Snackbar'); await capture('06-snackbar', route);
    }
    if (route === '/tutorial') {
      await clickLabel('Siguiente'); await capture('09-tutorial-paso-2', route);
      await clickLabel('Siguiente'); await capture('09-tutorial-final', route);
    }
    if (route === '/theme-changer') {
      await click(402, 28); await capture('12-tema-oscuro', route);
    }
  }
  await navigate('/'); await click(28, 28); await capture('13-menu-lateral', '/');
  report.ok = report.exceptions.length === 0;
  if (!report.ok) throw Error('Browser reported exceptions; inspect capture-report.json');
} catch (error) {
  report.error = String(error); process.exitCode = 1;
} finally {
  await writeFile(resolve(out, 'capture-report.json'), JSON.stringify(report, null, 2));
  await browser.close(); server.closeAllConnections(); server.close();
}
console.log(JSON.stringify({ ok: report.ok, count: report.screenshots.length, error: report.error }));
