import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { fileURLToPath } from 'node:url';
import { ChromeVisualBrowser } from '../.agents/skills/archify/bin/visual-check.mjs';

const dir = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(dir, '../../..');
const browser = new ChromeVisualBrowser('C:/Program Files/Google/Chrome/Application/chrome.exe');
const report = {diagram:[],menu:[],export:{}};
const server = http.createServer((req,res)=>{
  const relative = decodeURIComponent(new URL(req.url,'http://localhost').pathname).replace(/^\/Practicas_DMI_230881\//,'');
  const filename = path.resolve(repo,relative || 'index.html');
  if (!filename.startsWith(repo+path.sep) || !fs.existsSync(filename)) { res.writeHead(404);res.end();return; }
  res.setHeader('Content-Type', filename.endsWith('.html') ? 'text/html; charset=utf-8' : 'application/octet-stream');
  res.end(fs.readFileSync(filename));
});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const base = `http://127.0.0.1:${server.address().port}/Practicas_DMI_230881/`;
try {
 const session = await browser.sessionPromise;
 const evaluate = async expression => {
   const result = await browser.cdp.send('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true},session);
   if(result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
   return result.result.value;
 };
 const navigate = async url=>{
   const loaded=browser.cdp.waitFor('Page.loadEventFired',session); loaded.catch(()=>{});
   await browser.cdp.send('Page.navigate',{url},session); await loaded;
 };
 for(const width of [390,768,1440]) {
   await browser.inspect({artifactPath:path.join(dir,'index.html'),width,height:900,theme:'dark',writeScreenshot:bytes=>fs.writeFileSync(path.join(dir,`diagram-${width}.png`),bytes)});
   const state = await evaluate(`(async()=>{
     const panel=document.querySelector('.diagram-container');
     const before=Archify.view.state();
     const initialScroll=panel.scrollLeft;
     Archify.view.zoomIn();
     await new Promise(r=>setTimeout(r,150));
     const after=Archify.view.state();
     Archify.view.centerAt(1000,450,{instant:true});
     await new Promise(r=>setTimeout(r,150));
     const panned=Archify.view.state();
     const out={width:innerWidth,scrollWidth:document.documentElement.scrollWidth,before,after,panned,initialScroll,finalScroll:panel.scrollLeft,zoomChanged:after.scale>before.scale,panChanged:innerWidth<=720?panel.scrollLeft!==initialScroll:after.x!==panned.x || after.y!==panned.y};
     Archify.view.reset();return out;
   })()`);
   report.diagram.push(state);
 }
 const svg = await evaluate(`(async()=>{
   let exported;
   const original=URL.createObjectURL;
   URL.createObjectURL=function(blob){exported=blob;return original.call(this,blob)};
   try { await Archify.exportMenu.run('svg'); return {svg:await exported.text(),canonical:document.documentElement.getAttribute('data-last-export-canonical')}; }
   finally { URL.createObjectURL=original; }
 })()`);
 fs.writeFileSync(path.join(dir,'architecture.svg'),svg.svg);
 report.export={canonical:svg.canonical,bytes:Buffer.byteLength(svg.svg)};
 for(const width of [390,768,1440]) {
   await browser.cdp.send('Emulation.setDeviceMetricsOverride',{width,height:900,deviceScaleFactor:1,mobile:false},session);
   await navigate(base+'index.html');
   const state=await evaluate(`({width:innerWidth,scrollWidth:document.documentElement.scrollWidth,cards:[...document.querySelectorAll('.card .number')].map(n=>n.textContent),link:document.querySelector('a[href="Practica05/widgets_app/architecture/index.html"]').getAttribute('href')})`);
   report.menu.push(state);
   const capture=await browser.cdp.send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false},session);
   fs.writeFileSync(path.join(dir,`menu-${width}.png`),Buffer.from(capture.data,'base64'));
   if(width===390){
     await evaluate(`(async()=>{document.querySelector('.card:last-child').scrollIntoView({behavior:'instant'});await new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))})()`);
     const cardCapture=await browser.cdp.send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false},session);
     fs.writeFileSync(path.join(dir,'menu-practice05-390.png'),Buffer.from(cardCapture.data,'base64'));
   }
 }
 await navigate(base+'Practica05/widgets_app/architecture/index.html');
 report.pagesPrefixNavigation=await evaluate(`({title:document.title,viewer:!!window.Archify,url:location.pathname})`);
 report.ok=report.diagram.every(x=>x.scrollWidth<=x.width && x.zoomChanged && x.panChanged) && report.menu.every(x=>x.scrollWidth<=x.width && x.cards.length===4) && report.export.canonical==='true' && report.pagesPrefixNavigation.viewer;
 fs.writeFileSync(path.join(dir,'responsive-export-check.json'),JSON.stringify(report,null,2));
 console.log(JSON.stringify(report,null,2));
 if(!report.ok) process.exitCode=1;
} finally { await browser.close(); await new Promise(resolve=>server.close(resolve)); }
