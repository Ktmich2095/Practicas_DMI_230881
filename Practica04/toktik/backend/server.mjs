// Public catalog gateway. API credentials remain on this server, never in APKs.
// Node 20+, no npm dependencies. Run behind an HTTPS reverse proxy in production.
import {createServer as httpServer} from 'node:http';
import {createServer as httpsServer} from 'node:https';
import {readFileSync} from 'node:fs';
import {pathToFileURL} from 'node:url';

export function createGateway({keys={},fetcher=fetch,now=Date.now,allowedOrigin=''}={}) {
  const cache=new Map(),limits=new Map(),inFlight=new Map();
  const statusMessage=status=>({401:'authentication_rejected',403:'access_denied',404:'upstream_not_found',429:'rate_limited'}[status]||(status>=500?'upstream_unavailable':'upstream_rejected'));
  return async function handler(request,response) {
    const reply=(status,body,extra={})=>{
      response.writeHead(status,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff',...(allowedOrigin?{'Access-Control-Allow-Origin':allowedOrigin}:{}),...extra});
      response.end(JSON.stringify(body));
    };
    const url=new URL(request.url,'http://gateway.invalid');
    if(request.method==='GET'&&url.pathname==='/health')return reply(200,{status:'ok',providers:['coverr','pixabay'].filter(p=>keys[p])});
    if(request.method!=='GET')return reply(405,{error:'method_not_allowed'});
    const match=/^\/v1\/videos\/(coverr|pixabay)$/.exec(url.pathname);
    if(!match)return reply(404,{error:'not_found'});
    const provider=match[1];
    if([...url.searchParams.keys()].some(k=>!['page','per_page','page_size'].includes(k)))return reply(400,{error:'unsupported_parameter'});
    const defaultPage=provider==='coverr'?0:1;
    const page=Number(url.searchParams.get('page')??defaultPage);
    const size=Number(url.searchParams.get('page_size')??url.searchParams.get('per_page')??8);
    if(!Number.isInteger(page)||page<defaultPage||page>100||!Number.isInteger(size)||size<3||size>30)return reply(400,{error:'invalid_pagination'});
    const ip=request.socket.remoteAddress;
    const time=now();
    const bucket=limits.get(ip);
    if(!bucket||bucket.until<=time)limits.set(ip,{count:1,until:time+60000});
    else if(++bucket.count>60)return reply(429,{error:'rate_limited'},{'Retry-After':'60'});
    if(limits.size>1000)for(const [id,value] of limits)if(value.until<=time)limits.delete(id);
    const key=String(keys[provider]??'').trim();
    if(!key)return reply(503,{error:'provider_not_configured',provider});
    const cacheId=`${provider}:${page}:${size}`;
    const saved=cache.get(cacheId);
    if(saved&&saved.until>time)return reply(200,saved.data);
    const query=provider==='coverr'?new URLSearchParams({page:String(page),page_size:String(size),urls:'true',sort:'popular'}):new URLSearchParams({key,page:String(page),per_page:String(size),safesearch:'true',order:'popular'});
    const endpoint=provider==='coverr'?'https://api.coverr.co/videos':'https://pixabay.com/api/videos/';
    try {
      if(!inFlight.has(cacheId)) {
        const task=(async()=>{
          const upstream=await fetcher(endpoint+'?'+query,{headers:provider==='coverr'?{Authorization:'Bearer '+key}:{},redirect:'error',signal:AbortSignal.timeout(12000)});
          if(upstream.status!==200)return {status:upstream.status,data:{error:statusMessage(upstream.status),provider}};
          const raw=await upstream.json();
          if(!Array.isArray(raw.hits))return {status:502,data:{error:'invalid_upstream_schema',provider}};
          // Whitelist top-level fields; no headers or pagination URLs are relayed.
          const data={hits:raw.hits,pages:raw.pages,total:raw.total,totalHits:raw.totalHits,page:raw.page};
          const encoded=JSON.stringify(data);
          if(Object.values(keys).some(secret=>secret&&encoded.includes(secret)))return {status:502,data:{error:'unsafe_upstream_response',provider}};
          if(cache.size>=30)cache.delete(cache.keys().next().value);
          cache.set(cacheId,{data,until:now()+(provider==='pixabay'?86400000:300000)});
          return {status:200,data};
        })();
        inFlight.set(cacheId,task);
      }
      const result=await inFlight.get(cacheId);
      return reply(result.status,result.data);
    } catch {
      return reply(502,{error:'upstream_network_or_json_error',provider});
    } finally { inFlight.delete(cacheId); }
  };
}

if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href) {
  let fileKeys={};
  if(process.env.TOKTIK_KEYS_FILE)fileKeys=JSON.parse(readFileSync(process.env.TOKTIK_KEYS_FILE,'utf8').replace(/^\uFEFF/,''));
  const keys={coverr:process.env.COVERR_API_KEY||fileKeys.COVERR_API_KEY,pixabay:process.env.PIXABAY_API_KEY||fileKeys.PIXABAY_API_KEY};
  const handler=createGateway({keys,allowedOrigin:process.env.ALLOWED_ORIGIN||''});
  const server=process.env.TLS_CERT_PATH&&process.env.TLS_KEY_PATH?httpsServer({cert:readFileSync(process.env.TLS_CERT_PATH),key:readFileSync(process.env.TLS_KEY_PATH)},handler):httpServer(handler);
  server.listen(Number(process.env.PORT||8080),process.env.HOST||'0.0.0.0',()=>console.log('TokTik catalog gateway ready.'));
}
