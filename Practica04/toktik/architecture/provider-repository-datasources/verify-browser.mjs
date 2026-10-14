// Export through Archify's own viewer and test the exact delivered artifact.
// No npm dependencies and no web server required.
import { spawn } from 'node:child_process';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { resolve, dirname } from 'node:path';
import { pathToFileURL } from 'node:url';

const folder = dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const html = resolve(folder, 'index.html');
const profile = resolve(folder, '../../build/archify-provider-repository-datasources-browser-profile');
await mkdir(profile, { recursive: true });
const chrome = spawn('C:/Program Files/Google/Chrome/Application/chrome.exe', [
  '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
  '--remote-debugging-pipe', '--user-data-dir=' + profile,
], { stdio: ['ignore', 'ignore', 'ignore', 'pipe', 'pipe'], windowsHide: true });
let sequence = 0, buffer = '';
const pending = new Map();
const runtimeErrors = [];
chrome.stdio[4].on('data', chunk => {
  buffer += chunk.toString();
  let end;
  while ((end = buffer.indexOf('\0')) >= 0) {
    const message = JSON.parse(buffer.slice(0, end));
    buffer = buffer.slice(end + 1);
    if (message.method === 'Runtime.exceptionThrown') runtimeErrors.push(message.params.exceptionDetails.text);
    if (pending.has(message.id)) {
      const { resolve, reject, timer } = pending.get(message.id);
      clearTimeout(timer);
      pending.delete(message.id);
      if (message.error) reject(new Error(JSON.stringify(message.error)));
      else resolve(message.result);
    }
  }
});
function send(method, params = {}, sessionId) {
  return new Promise((resolve, reject) => {
    const id = ++sequence;
    const timer = setTimeout(() => { pending.delete(id); reject(new Error('CDP timeout: ' + method)); }, 20000);
    pending.set(id, { resolve, reject, timer });
    chrome.stdio[3].write(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }) + '\0');
  });
}
let sessionId;
async function evaluate(expression) {
  const result = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true }, sessionId);
  if (result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
  return result.result.value;
}
const pause = ms => new Promise(r => setTimeout(r, ms));
try {
  const target = await send('Target.createTarget', { url: 'about:blank' });
  ({ sessionId } = await send('Target.attachToTarget', { targetId: target.targetId, flatten: true }));
  await send('Runtime.enable', {}, sessionId);
  await send('Page.enable', {}, sessionId);
  await send('Page.navigate', { url: pathToFileURL(html).href }, sessionId);
  for (let i = 0; i < 60; i++) {
    if (await evaluate('document.readyState === "complete" && !!document.querySelector("button[data-format=svg]")')) break;
    await pause(100);
  }
  const measurements = [];
  for (const [width, height] of [[360, 800], [390, 844], [768, 1024], [1440, 900]]) {
    await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: width < 500 }, sessionId);
    await pause(200);
    measurements.push(await evaluate(`JSON.parse(JSON.stringify({width:innerWidth,height:innerHeight,scrollWidth:document.documentElement.scrollWidth,title:document.title,svgCount:document.querySelectorAll('svg[role="img"]').length,externalAssets:[...document.querySelectorAll('script[src],link[rel=stylesheet][href],img[src]')].map(e=>e.getAttribute('src')||e.getAttribute('href'))}))`));
    if (width === 390) {
      const capture = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false }, sessionId);
      await writeFile(resolve(folder, 'visual-check/mobile-390.png'), Buffer.from(capture.data, 'base64'));
    }
    if (width === 1440) {
      const metrics = await send('Page.getLayoutMetrics', {}, sessionId);
      const capture = await send('Page.captureScreenshot', { format:'png', captureBeyondViewport:true,
        clip:{x:0,y:0,width:1440,height:Math.ceil(metrics.cssContentSize.height),scale:1} }, sessionId);
      await writeFile(resolve(folder, 'visual-check/desktop-full.png'), Buffer.from(capture.data, 'base64'));
    }
  }
  // Capture the Blob produced by the viewer's canonical SVG export, unchanged.
  const exported = await evaluate(`(async () => {
    const create = URL.createObjectURL.bind(URL);
    URL.createObjectURL = blob => { window.archifyExportBlob = blob; return create(blob); };
    HTMLAnchorElement.prototype.click = function() {};
    document.querySelector('button[data-format="svg"]').click();
    for(let i=0;i<100&&!window.archifyExportBlob;i++) await new Promise(r=>setTimeout(r,50));
    if(!window.archifyExportBlob) throw Error('Archify did not produce an SVG');
    return {svg:await window.archifyExportBlob.text(), error:document.documentElement.getAttribute('data-last-export-error'),canonical:document.documentElement.getAttribute('data-last-export-canonical')};
  })()`);
  if (exported.error || exported.canonical !== 'true' || !exported.svg.includes('<svg')) throw Error('SVG export failed');
  await writeFile(resolve(folder, 'provider-repository-datasources.svg'), exported.svg);
  await send('Page.navigate', { url: pathToFileURL(resolve(folder, 'provider-repository-datasources.svg')).href }, sessionId);
  await pause(250);
  const standaloneSvg = await evaluate(`({root:document.documentElement.localName,viewBox:document.documentElement.getAttribute('viewBox'),parserErrors:document.querySelectorAll('parsererror').length,labels:document.querySelectorAll('text').length})`);
  const navigation = [];
  for (const width of [390,1440]) {
    await send('Emulation.setDeviceMetricsOverride', {width,height:900,deviceScaleFactor:1,mobile:width<500}, sessionId);
    for (const selected of ['provider-local','provider-repository-datasources']) {
      const url = new URL(pathToFileURL(resolve(folder, '../index.html')));
      url.hash = selected;
      await send('Page.navigate', {url:url.href}, sessionId);
      for(let i=0;i<50;i++) {
        if(await evaluate(`document.querySelector('a[aria-current=page]')?.dataset.diagram === '${selected}' && document.getElementById('diagram')?.getAttribute('src') === '${selected}/index.html'`)) break;
        await pause(100);
      }
      navigation.push(await evaluate(`({width:innerWidth,scrollWidth:document.documentElement.scrollWidth,expected:'${selected}',selected:document.querySelector('a[aria-current=page]')?.dataset.diagram,frame:document.getElementById('diagram')?.getAttribute('src'),standalone:document.getElementById('standalone')?.getAttribute('href'),svg:document.getElementById('svg')?.getAttribute('href')})`));
      if(width===390&&selected==='provider-repository-datasources') {
        const capture = await send('Page.captureScreenshot', {format:'png'}, sessionId);
        await writeFile(resolve(folder,'visual-check/navigation-mobile.png'),Buffer.from(capture.data,'base64'));
      }
    }
  }
  const report = {
    artifactSha256: createHash('sha256').update(await readFile(html)).digest('hex'),
    svgSha256: createHash('sha256').update(exported.svg).digest('hex'),
    svgExport: 'Archify viewer: Exportar > SVG Auto', canonicalExport: exported.canonical === 'true',
    viewports: measurements, standaloneSvg, navigation, runtimeErrors,
    status: measurements.every(m => m.scrollWidth <= m.width && m.svgCount === 1 && m.externalAssets.length === 0) && standaloneSvg.root === 'svg' && standaloneSvg.parserErrors === 0 && standaloneSvg.labels > 0 && navigation.every(n=>n.selected===n.expected&&n.scrollWidth<=n.width&&n.frame===n.selected+'/index.html'&&n.standalone===n.frame&&n.svg.startsWith(n.selected+'/')) && runtimeErrors.length === 0 ? 'pass' : 'fail',
  };
  await writeFile(resolve(folder, 'responsive-export-check.json'), JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify(report));
  if (report.status !== 'pass') process.exitCode = 1;
} finally {
  await send('Browser.close').catch(() => chrome.kill());
}
