import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {createGateway} from './server.mjs';

async function gateway(t,options) {
  const server=createServer(createGateway(options));
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  t.after(()=>{server.closeAllConnections();server.close();});
  return 'http://127.0.0.1:'+server.address().port;
}
test('Upstream credentials remain server-side and Pixabay cache lasts 24 hours',async t=>{
  let calls=0,time=0;
  const base=await gateway(t,{keys:{coverr:'fixture-coverr-secret',pixabay:'fixture-pixabay-secret'},now:()=>time,fetcher:async(url,options)=>{
    calls++;
    if(url.startsWith('https://api.coverr.co/'))assert.equal(options.headers.Authorization,'Bearer fixture-coverr-secret');
    else assert.equal(new URL(url).searchParams.get('key'),'fixture-pixabay-secret');
    assert.equal(options.redirect,'error');
    return new Response(JSON.stringify({hits:[{id:1}],totalHits:1}));
  }});
  for(const provider of ['coverr','pixabay']) {
    const response=await fetch(base+'/v1/videos/'+provider);
    assert.equal(response.status,200);
    assert.equal((await response.text()).includes('fixture-'),false);
  }
  time=23*3600000;
  assert.equal((await fetch(base+'/v1/videos/pixabay')).status,200);
  assert.equal(calls,2);
  time=25*3600000;
  await fetch(base+'/v1/videos/pixabay');
  assert.equal(calls,3);
});
for(const status of [401,403,404,429,500])test('Sanitized HTTP '+status,async t=>{
  const base=await gateway(t,{keys:{coverr:'fixture-secret'},fetcher:async()=>new Response('fixture-secret signed?token=private',{status})});
  const response=await fetch(base+'/v1/videos/coverr');
  assert.equal(response.status,status);
  const body=await response.text();
  assert.equal(body.includes('fixture-secret'),false);
  assert.equal(body.includes('token='),false);
});
test('No arbitrary host, auth parameter, invalid page or reflected secret',async t=>{
  const base=await gateway(t,{keys:{coverr:'fixture-secret'},fetcher:async()=>new Response(JSON.stringify({hits:[{key:'fixture-secret'}]}))});
  for(const path of ['/v1/videos/unknown','/v1/videos/coverr?url=https://example.org','/v1/videos/coverr?key=secret','/v1/videos/coverr?page=-1']) {
    assert.ok([400,404].includes((await fetch(base+path)).status));
  }
  const response=await fetch(base+'/v1/videos/coverr');
  assert.equal(response.status,502);
  assert.equal((await response.text()).includes('fixture-secret'),false);
});
