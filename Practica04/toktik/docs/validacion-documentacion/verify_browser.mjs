// Browser QA of the publication tree: real main files + current documentation.
// The temporary HTTP server exists only during this check; Pages is static.
import { spawn, execFileSync } from 'node:child_process';
import { createServer } from 'node:http';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve, dirname, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const folder = dirname(fileURLToPath(import.meta.url));
const root = resolve(folder, '../../../..');
const appPath = 'Practica04/toktik/';
const prefix = '/Practicas_DMI_230881/';
const mainPaths = new Set(execFileSync('git',['ls-tree','-r','--name-only','main'],{cwd:root,encoding:'utf8'}).trim().split('\n'));
const servedFromMain = new Set();
const mime = {'.html':'text/html; charset=utf-8','.svg':'image/svg+xml','.png':'image/png','.md':'text/plain; charset=utf-8','.js':'text/javascript','.css':'text/css'};
const server = createServer(async (request,response) => {
  try {
    const pathname = decodeURIComponent(new URL(request.url,'http://127.0.0.1').pathname);
    if(pathname.endsWith('/favicon.ico')) { response.writeHead(204);response.end();return; }
    if(!pathname.startsWith(prefix)) { response.writeHead(404);response.end();return; }
    let relative = pathname.slice(prefix.length);
    if(relative==='__readme_preview__') {
      const content=(await readFile(resolve(root,'.buildlog/toktik-readme-preview.html'),'utf8')).replace('<title>','<base href="'+prefix+appPath+'"><title>');
      response.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});response.end(content);return;
    }
    if(!relative||relative.endsWith('/')) relative+='index.html';
    const file = resolve(root,relative);
    if(!file.startsWith(root+'/')&&!file.startsWith(root+'\\')) throw Error('Invalid path');
    let body;
    try { body=await readFile(file); }
    catch(error) {
      if(!mainPaths.has(relative)) { response.writeHead(404);response.end();return; }
      body=execFileSync('git',['show','main:'+relative],{cwd:root,maxBuffer:20*1024*1024});
      servedFromMain.add(relative);
    }
    response.writeHead(200,{'Content-Type':mime[extname(relative)]||'application/octet-stream'});
    response.end(body);
  } catch(error) { response.writeHead(500);response.end(String(error)); }
});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const origin='http://127.0.0.1:'+server.address().port;
const base=origin+prefix;
const profile=resolve(root,'.buildlog/documentation-browser-profile');
await mkdir(profile,{recursive:true});
const chrome=spawn('C:/Program Files/Google/Chrome/Application/chrome.exe',[
  '--headless=new','--disable-gpu','--no-first-run','--no-default-browser-check',
  '--remote-debugging-pipe','--user-data-dir='+profile
],{stdio:['ignore','ignore','ignore','pipe','pipe'],windowsHide:true});
let sequence=0,buffer='',sessionId;
const pending=new Map(),runtimeErrors=[],failedResponses=[];
chrome.stdio[4].on('data',chunk=>{
  buffer+=chunk.toString();let end;
  while((end=buffer.indexOf('\0'))>=0) {
    const message=JSON.parse(buffer.slice(0,end));buffer=buffer.slice(end+1);
    if(message.method==='Runtime.exceptionThrown') runtimeErrors.push(message.params.exceptionDetails.text);
    if(message.method==='Network.responseReceived'&&message.params.response.status>=400) failedResponses.push({url:message.params.response.url,status:message.params.response.status});
    if(pending.has(message.id)) {
      const item=pending.get(message.id);clearTimeout(item.timer);pending.delete(message.id);
      if(message.error)item.reject(new Error(JSON.stringify(message.error)));else item.resolve(message.result);
    }
  }
});
function send(method,params={},sid) {
  return new Promise((resolve,reject)=>{
    const id=++sequence,timer=setTimeout(()=>{pending.delete(id);reject(new Error('CDP timeout: '+method));},20000);
    pending.set(id,{resolve,reject,timer});
    chrome.stdio[3].write(JSON.stringify({id,method,params,...(sid?{sessionId:sid}:{})})+'\0');
  });
}
async function evaluate(expression) {
  const result=await send('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true},sessionId);
  if(result.exceptionDetails)throw Error(JSON.stringify(result.exceptionDetails));
  return result.result.value;
}
const pause=ms=>new Promise(r=>setTimeout(r,ms));
async function navigate(url,ready='document.readyState === "complete"') {
  await send('Page.navigate',{url},sessionId);
  for(let i=0;i<80;i++) { if(await evaluate(ready))return;await pause(100); }
  throw Error('Page did not become ready: '+url);
}
async function capture(name,full=false) {
  const metrics=await send('Page.getLayoutMetrics',{},sessionId);
  const options=full?{captureBeyondViewport:true,clip:{x:0,y:0,width:Math.ceil(metrics.cssContentSize.width),height:Math.ceil(metrics.cssContentSize.height),scale:1}}:{};
  const result=await send('Page.captureScreenshot',{format:'png',...options},sessionId);
  await writeFile(resolve(folder,name),Buffer.from(result.data,'base64'));
}
try {
  const target=await send('Target.createTarget',{url:'about:blank'});
  ({sessionId}=await send('Target.attachToTarget',{targetId:target.targetId,flatten:true}));
  for(const method of ['Runtime.enable','Page.enable','Network.enable'])await send(method,{},sessionId);
  const menu=[];
  for(const width of [320,390,768,1024,1440]) {
    await send('Emulation.setDeviceMetricsOverride',{width,height:900,deviceScaleFactor:1,mobile:width<500},sessionId);
    await navigate(base,'document.readyState === "complete" && document.querySelectorAll("article.card").length === 3');
    const row=await evaluate(`(()=>{const cards=[...document.querySelectorAll('article.card')];const rects=cards.map(c=>{const r=c.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height}});return {width:innerWidth,scrollWidth:document.documentElement.scrollWidth,columns:getComputedStyle(document.querySelector('.grid')).gridTemplateColumns,cards:cards.length,rects,buttons:[...document.querySelectorAll('.toktik .button')].map(a=>({href:a.getAttribute('href'),label:a.textContent.trim()})),overlaps:rects.some((a,i)=>rects.some((b,j)=>j>i&&a.x<b.x+b.w&&b.x<a.x+a.w&&a.y<b.y+b.h&&b.y<a.y+a.h))}})()`);
    menu.push(row);
    if(width===390||width===1440)await capture('menu-'+width+'.png',true);
  }
  await evaluate(`document.querySelector('.toktik .button').scrollIntoView({block:'center',behavior:'instant'})`);
  const button=await evaluate(`(()=>{const r=document.querySelector('.toktik .button').getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2}})()`);
  await send('Input.dispatchMouseEvent',{type:'mouseMoved',x:button.x,y:button.y},sessionId);await pause(300);
  const hover=await evaluate(`({transform:getComputedStyle(document.querySelector('.toktik .button')).transform,filter:getComputedStyle(document.querySelector('.toktik .button')).filter})`);
  await send('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-motion',value:'reduce'}]},sessionId);
  const reducedMotion=await evaluate(`({duration:getComputedStyle(document.querySelector('.toktik .button')).transitionDuration,transform:getComputedStyle(document.querySelector('.toktik .button')).transform})`);
  await send('Emulation.setEmulatedMedia',{features:[]},sessionId);
  const destinations=[];
  const links=await evaluate(`[...document.querySelectorAll('article .button')].map(a=>({href:a.href,label:a.getAttribute('aria-label')}))`);
  for(const link of links) {
    await navigate(link.href,`document.readyState === 'complete' && !!document.querySelector('svg')`);
    destinations.push({...link,title:await evaluate('document.title'),svg:await evaluate('document.querySelectorAll("svg[role=img]").length')});
  }
  const readme=[];
  for(const width of [320,390,768,1440]) {
    await send('Emulation.setDeviceMetricsOverride',{width,height:900,deviceScaleFactor:1,mobile:width<500},sessionId);
    await navigate(base+'__readme_preview__',`document.readyState === 'complete' && !!document.querySelector('h1')`);
    readme.push(await evaluate(`({width:innerWidth,scrollWidth:document.documentElement.scrollWidth,headings:document.querySelectorAll('h2,h3').length,activeMedia:document.querySelectorAll('img,video,source').length})`));
    if(width===390||width===1440)await capture('readme-'+width+'.png');
  }
  const report={
    status:menu.every(m=>m.scrollWidth<=m.width&&m.cards===3&&!m.overlaps)&&readme.every(m=>m.scrollWidth<=m.width&&m.activeMedia===0)&&destinations.length===4&&destinations.every(d=>d.svg>0)&&runtimeErrors.length===0&&failedResponses.length===0&&hover.transform!=='none'&&reducedMotion.duration==='0s'?'pass':'fail',
    testPublicationPrefix:prefix,sourceOverlay:'Current workspace; unchanged old practice assets read from actual main Git objects when absent locally',
    rootSha256:createHash('sha256').update(await readFile(resolve(root,'index.html'))).digest('hex'),
    menu,hover,reducedMotion,destinations,readme,runtimeErrors,failedResponses,servedFromMain:[...servedFromMain],
    productionRequiresLocalServer:false,
  };
  await writeFile(resolve(folder,'browser-check.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify(report));
  if(report.status!=='pass')process.exitCode=1;
} finally {
  await send('Browser.close').catch(()=>chrome.kill());
  await new Promise(resolve=>server.close(resolve));
}
