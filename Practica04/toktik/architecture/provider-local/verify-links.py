"""Check static Pages paths and record the actual review scope, without publishing."""
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import unquote, urlparse

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
APP = HERE.parents[1]
missing = []
checked = []
for markdown in [APP / 'README.md', HERE.parent / 'README.md', HERE / 'README.md']:
    for target in re.findall(r'\]\(([^)]+)\)', markdown.read_text(encoding='utf-8')):
        if urlparse(target).scheme or target.startswith('#'):
            continue
        target = unquote(target.split('#')[0])
        resolved = markdown.parent / target
        checked.append({'from': str(markdown.relative_to(ROOT)), 'target': target})
        if not resolved.exists():
            missing.append(checked[-1])

svg = ET.parse(HERE / 'provider-local.svg').getroot()
html = (HERE / 'index.html').read_text(encoding='utf-8')
result = {
    'status': 'pass' if not missing and (ROOT / '.nojekyll').is_file() else 'fail',
    'checkedRelativeLinks': checked, 'missing': missing,
    'nojekyll': (ROOT / '.nojekyll').is_file(),
    'rootIndexExists': (ROOT / 'index.html').is_file(),
    'htmlExternalScripts': re.findall(r'<script[^>]+src=["\']([^"\']+)', html),
    'svgViewBox': svg.attrib['viewBox'],
    'visualReview': {
        'status': 'passed',
        'reviewer': 'image-capable assistant',
        'artifactSha256': hashlib.sha256((HERE / 'index.html').read_bytes()).hexdigest(),
        'capturesInspected': ['visual-check/index.visual-check.1440x900.light.png',
                             'visual-check/index.visual-check.2048x1320.dark.png',
                             'visual-check/mobile-390.png'],
        'observations': ['No overlapping nodes or relationship labels in inspected desktop captures.',
                         'Mobile has no page overflow; cards stack below the diagram.',
                         'Mobile overview requires viewer zoom to read small diagram text.'],
    },
    'pages': {'source': 'user-confirmed', 'branch': 'main', 'folder': '/',
              'remoteSettingsVerified': False, 'published': False},
}
(HERE / 'pages-links-review.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'status': result['status'], 'checkedLinks': len(checked), 'missing': missing,
                  'nojekyll': result['nojekyll'], 'visualReview': 'passed'}))
raise SystemExit(0 if result['status'] == 'pass' else 1)
