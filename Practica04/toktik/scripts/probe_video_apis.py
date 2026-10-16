"""Probe credentials locally. Never print keys, request URLs or response bodies."""
import json
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def probe(provider, key):
    result = {'provider': provider, 'credentialPresent': bool(key), 'hasBearerPrefix':key.lower().startswith('bearer ')}
    if not key:
        return result
    if provider == 'Coverr':
        url = 'https://api.coverr.co/videos?' + urllib.parse.urlencode({'page':0,'page_size':3,'urls':'true','sort':'popular'})
        headers = {'Authorization':'Bearer '+key}
    else:
        url = 'https://pixabay.com/api/videos/?' + urllib.parse.urlencode({'key':key,'page':1,'per_page':3,'safesearch':'true','order':'popular'})
        headers = {}
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=20) as response:
            result['httpStatus'] = response.status
            data = json.load(response)
        hits = data.get('hits', [])
        result['hitCount'] = len(hits)
        result['withMedia'] = sum(bool(hit.get('urls' if provider == 'Coverr' else 'videos')) for hit in hits)
        media = None
        for hit in hits:
            if provider == 'Coverr':
                urls = hit.get('urls') or {}
                media = urls.get('mp4_preview') or urls.get('mp4')
            else:
                variants = hit.get('videos') or {}
                media = next((variants.get(size, {}).get('url') for size in ['tiny','small','medium'] if variants.get(size, {}).get('url')), None)
            if media:
                break
        if media:
            try:
                request = urllib.request.Request(media, headers={'Range':'bytes=0-1023'})
                with urllib.request.urlopen(request, timeout=20) as response:
                    result['mediaHttpStatus'] = response.status
                    result['mediaContentType'] = response.headers.get('Content-Type','').split(';')[0]
                    result['mediaSampleBytes'] = len(response.read(1024))
            except urllib.error.HTTPError as error:
                result['mediaHttpStatus'] = error.code
            except Exception:
                result['mediaError'] = 'network_error'
    except urllib.error.HTTPError as error:
        result['httpStatus'] = error.code
        result['networkPolicyBlocked'] = bool(error.headers.get('X-Mitmproxy-Blocked-Reason'))
        body = error.read(65536).decode('utf-8', errors='replace').lower()
        result['responseKind'] = ('access_challenge' if any(marker in body for marker in ['cloudflare','captcha','just a moment','attention required'])
                                  else 'json_api_error' if 'json' in error.headers.get('Content-Type','') else 'other_http_error')
    except Exception:
        result['error'] = 'network_or_json_error'
    return result


if __name__ == '__main__':
    path = ROOT / 'api_keys.json'
    keys = json.loads(path.read_text(encoding='utf-8-sig')) if path.exists() else {}
    report = {'probes':[probe('Coverr',str(keys.get('COVERR_API_KEY','')).strip()),
                        probe('Pixabay',str(keys.get('PIXABAY_API_KEY','')).strip())]}
    print(json.dumps(report))
