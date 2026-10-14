"""Read-only live probe. Writes no credentials and downloads no full videos."""
from pathlib import Path
import json
import urllib.parse
import urllib.request
import datetime

ROOT = Path(__file__).resolve().parents[1]


def get(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'TokTik-Academic-Probe/1.0'})
    with urllib.request.urlopen(request, timeout=15) as response:
        return json.load(response)


def probe():
    query = 'mediatype:movies AND (licenseurl:"https://creativecommons.org/publicdomain/zero/1.0/" OR licenseurl:"http://creativecommons.org/publicdomain/zero/1.0/" OR licenseurl:"https://creativecommons.org/licenses/by/4.0/" OR licenseurl:"http://creativecommons.org/licenses/by/4.0/")'
    search = 'https://archive.org/advancedsearch.php?' + urllib.parse.urlencode({
        'q': query, 'output': 'json', 'rows': 6, 'page': 1,
        'fl[]': 'identifier', 'sort[]': 'downloads desc'})
    report = {'checkedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'provider': 'Internet Archive', 'searchUrl': search, 'items': []}
    try:
        data = get(search)
        docs = data.get('response', {}).get('docs', [])
        report['searchSucceeded'] = True
        report['resultCount'] = len(docs)
        for doc in docs:
            identifier = doc['identifier']
            try:
                metadata = get('https://archive.org/metadata/' + urllib.parse.quote(identifier, safe=''))
                files = [f for f in metadata.get('files', []) if f.get('name', '').lower().endswith('.mp4')
                    and str(f.get('private', '')).lower() != 'true'
                    and 0 < int(f.get('size', 0)) <= 80000000]
                report['items'].append({'identifier': identifier,
                    'license': metadata.get('metadata', {}).get('licenseurl'),
                    'compatibleSizeMp4Count': len(files)})
            except Exception as error:
                report['items'].append({'identifier': identifier, 'error': str(error)})
    except Exception as error:
        report['searchSucceeded'] = False
        report['error'] = str(error)
    output = ROOT / 'docs/live_archive_probe.json'
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False))
    return report['searchSucceeded']


if __name__ == '__main__':
    raise SystemExit(0 if probe() else 1)
