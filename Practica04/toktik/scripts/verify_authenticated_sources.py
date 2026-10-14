"""Read keys from stdin, probe real APIs, then run opt-in Flutter tests.

Credentials live only in process memory. Reports contain counts/status only.
No key, response body, request URL or signed video URL is written to disk.
"""
from pathlib import Path
import datetime
import json
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def probe(name, key):
    result = {'provider': name}
    if not key:
        return {**result, 'error': 'missing_credential'}
    if name == 'Coverr':
        url = 'https://api.coverr.co/videos?' + urllib.parse.urlencode({
            'page': 0, 'page_size': 8, 'urls': 'true', 'sort': 'popular'})
        headers = {'Authorization': 'Bearer ' + key}
    else:
        url = 'https://pixabay.com/api/videos/?' + urllib.parse.urlencode({
            'key': key, 'page': 1, 'per_page': 8, 'safesearch': 'true', 'order': 'popular'})
        headers = {}
    try:
        request = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(request, timeout=15) as response:
            data = json.load(response)
            result['httpStatus'] = response.status
        hits = data.get('hits', [])
        result['hitCount'] = len(hits)
        result['firstHitFields'] = sorted(hits[0].keys()) if hits else []
        result['mediaFields'] = sorted(hits[0].get('urls' if name == 'Coverr' else 'videos', {}).keys()) if hits else []
    except urllib.error.HTTPError as error:
        result['httpStatus'] = error.code
        result['error'] = 'http_error'
    except Exception:
        result['error'] = 'network_or_json_error'
    return result


def main():
    print('Waiting for credentials on stdin (not echoed).', flush=True)
    keys = json.loads(sys.stdin.readline())
    coverr = keys.get('coverr', '').strip()
    pixabay = keys.get('pixabay', '').strip()
    report = {'checkedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'pythonProbes': [probe('Coverr', coverr), probe('Pixabay', pixabay)]}
    print(json.dumps(report, ensure_ascii=False), flush=True)
    flutter = shutil.which('flutter')
    if not flutter:
        report['flutterExitCode'] = None
        report['testError'] = 'flutter_not_found'
    else:
        result = subprocess.run([flutter, 'test', 'test/live_sources_test.dart',
            '--dart-define=RUN_LIVE_APIS=true', '--dart-define=COVERR_API_KEY=' + coverr,
            '--dart-define=PIXABAY_API_KEY=' + pixabay], cwd=ROOT,
            capture_output=True, text=True, encoding='utf-8', errors='replace')
        output = result.stdout + result.stderr
        for secret in (coverr, pixabay):
            if secret:
                output = output.replace(secret, '[redacted]')
        print(output, flush=True)
        report['flutterExitCode'] = result.returncode
        report['flutterMappedVideoCounts'] = {
            provider: int(count) for provider, count in re.findall(
                r'(Coverr|Pixabay): (\d+) mapped videos', output)}
    target = ROOT / 'docs/live_authenticated_probe.json'
    target.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    return 0 if report.get('flutterExitCode') == 0 else 1


if __name__ == '__main__':
    raise SystemExit(main())
