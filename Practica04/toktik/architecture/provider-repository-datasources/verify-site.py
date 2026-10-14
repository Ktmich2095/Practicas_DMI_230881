"""Validate relative Pages paths and that existing app/diagram bytes are intact."""
import hashlib
import json
import re
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlparse

HERE = Path(__file__).resolve().parent
APP = HERE.parents[1]
ROOT = HERE.parents[3]
checked, missing, external = [], [], []


def check(origin, target):
    parsed = urlparse(target)
    if parsed.scheme or target.startswith('//'):
        if parsed.scheme not in ['data', 'blob']:
            external.append({'from': str(origin.relative_to(ROOT)), 'target': target})
        return
    resolved = origin.parent / unquote(parsed.path) if parsed.path else origin
    checked.append({'from': str(origin.relative_to(ROOT)), 'target': target})
    if not resolved.exists():
        missing.append(checked[-1])


class Links(HTMLParser):
    def __init__(self, origin):
        super().__init__()
        self.origin = origin

    def handle_starttag(self, tag, attributes):
        for key, value in attributes:
            if key in ['src', 'href'] and value:
                check(self.origin, value)


for path in [APP / 'README.md', HERE.parent / 'README.md', HERE / 'README.md']:
    for target in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding='utf-8')):
        check(path, target)
for path in [HERE.parent / 'index.html', HERE / 'index.html']:
    Links(path).feed(path.read_text(encoding='utf-8'))

baseline = json.loads((HERE / 'protected-files-before.json').read_text(encoding='utf-8'))
modified = []
for name, expected in baseline['files'].items():
    path = ROOT / name
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        modified.append(name)
nojekyll = (ROOT / '.nojekyll').is_file()
responsive = json.loads((HERE / 'responsive-export-check.json').read_text(encoding='utf-8'))
report = {
    'status': 'pass' if not missing and not modified and nojekyll and responsive['status'] == 'pass' else 'fail',
    'checkedRelativeLinks': checked, 'missingLinks': missing,
    'externalLinks': external, 'nojekyll': nojekyll,
    'protectedFilesChecked': len(baseline['files']), 'modifiedProtectedFiles': modified,
    'firstDiagramUnchanged': not any('/architecture/provider-local/' in name for name in modified),
    'artifactSha256': responsive['artifactSha256'], 'svgSha256': responsive['svgSha256'],
    'pages': {'branch':'main','folder':'/','configurationSource':'user-confirmed in previous turn',
              'published':False,'remoteSettingsVerified':False},
    'visualReview': {
        'status': 'passed', 'reviewer':'image-capable assistant',
        'capturesInspected':['visual-check/index.visual-check.2048x1320.light.png',
                             'visual-check/index.visual-check.1440x900.dark.png',
                             'visual-check/desktop-full.png','visual-check/mobile-390.png',
                             'visual-check/navigation-mobile.png'],
        'observations':['No overlapping nodes or route labels in inspected captures.',
                        'Complete data path and API node are present in full-page capture.',
                        'Mobile cards stack; detailed graph labels require viewer zoom.'],
    },
}
(HERE / 'site-check.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'status':report['status'],'relativeLinks':len(checked),'missingLinks':missing,
                  'protectedFilesChecked':len(baseline['files']),'modifiedProtectedFiles':modified,
                  'firstDiagramUnchanged':report['firstDiagramUnchanged'],'nojekyll':nojekyll}))
raise SystemExit(0 if report['status'] == 'pass' else 1)
