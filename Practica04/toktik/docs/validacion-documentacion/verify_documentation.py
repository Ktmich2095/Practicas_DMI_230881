"""Check local documentation and the existing main-branch publishing baseline."""
import hashlib
import json
import re
import subprocess
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlparse

from markdown_it import MarkdownIt

HERE = Path(__file__).resolve().parent
APP = HERE.parents[1]
ROOT = HERE.parents[3]
parser = MarkdownIt('commonmark', {'html': True}).enable('table')
baseline = json.loads((HERE / 'protected-files-before.json').read_text(encoding='utf-8'))
checked, missing, external, anchors, active_media = [], [], [], [], []
main_paths = set(subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', baseline['indexBaseCommit']], cwd=ROOT, text=True).splitlines())


def headings(text):
    values, seen = set(), {}
    tokens = parser.parse(text)
    for i, token in enumerate(tokens):
        if token.type == 'heading_open':
            label = tokens[i + 1].content.lower()
            slug = re.sub(r'[^\w\- ]', '', label).replace(' ', '-')
            duplicate = seen.get(slug, 0)
            seen[slug] = duplicate + 1
            values.add(slug + (f'-{duplicate}' if duplicate else ''))
    return values


class Links(HTMLParser):
    def __init__(self, origin):
        super().__init__()
        self.origin = origin
        self.ids = set()

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        if tag in ['img', 'video', 'source']:
            active_media.append({'from':self.origin.relative_to(ROOT).as_posix(),'tag':tag,'src':attrs.get('src')})
        for key in ['href', 'src']:
            if key in attrs:
                check(self.origin, attrs[key])


def check(origin, target):
    url = urlparse(target)
    if url.scheme or target.startswith('//'):
        external.append(target)
        return
    path = (origin.parent / unquote(url.path)).resolve() if url.path else origin
    relative = path.relative_to(ROOT).as_posix()
    if path.is_dir():
        path = path / 'index.html'
        relative = path.relative_to(ROOT).as_posix()
    exists = path.is_file()
    in_main = relative in main_paths
    row = {'from':origin.relative_to(ROOT).as_posix(),'target':target,
           'inWorkingTree':exists,'inPublishingMain':in_main}
    checked.append(row)
    if not exists and not in_main:
        missing.append(row)
    if url.fragment and exists:
        anchors.append((path, unquote(url.fragment), row))


markdown = [APP / 'README.md', APP / 'docs/GUIA_TECNICA.md', *sorted((APP / 'docs/evidencias').rglob('*.md'))]
for source in markdown:
    Links(source).feed(parser.render(source.read_text(encoding='utf-8')))
index = (ROOT / 'index.html').read_text(encoding='utf-8')
root_parser = Links(ROOT / 'index.html')
root_parser.feed(index)
for path, fragment, row in anchors:
    if path.suffix == '.md':
        available = headings(path.read_text(encoding='utf-8'))
    else:
        available = set(re.findall(r'\bid=["\']([^"\']+)', path.read_text(encoding='utf-8')))
        # Architecture's original script also supports these semantic fragments.
        if path == APP / 'architecture/index.html':
            available.update(['provider-local','provider-repository-datasources'])
    if fragment not in available:
        missing.append({**row,'missingFragment':fragment})

changed = [name for name, expected in baseline['files'].items()
           if not (ROOT / name).is_file() or hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != expected]
cards = re.findall(r'<article\b[\s\S]*?</article>', index)
preserved = cards[:2] == baseline['originalCards']
new_technical = (APP / 'README.md').read_text(encoding='utf-8') + '\n' + (APP / 'docs/GUIA_TECNICA.md').read_text(encoding='utf-8')
original_path = ROOT / '.buildlog/toktik-readme-before.md'
if original_path.is_file():
    code_blocks = re.findall(r'```[^\n]*\n([\s\S]*?)```', original_path.read_text(encoding='utf-8'))
    if baseline.get('technicalCodeBlocks') != code_blocks:
        baseline['technicalCodeBlocks'] = code_blocks
        (HERE / 'protected-files-before.json').write_text(json.dumps(baseline, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
else:
    code_blocks = baseline['technicalCodeBlocks']
missing_code = [block for block in code_blocks if block not in new_technical]
report = {
    'status':'pass' if not missing and not changed and preserved and len(cards)==3 and not missing_code and (ROOT / '.nojekyll').is_file() else 'fail',
    'relativeLinksChecked':len(checked),'missingLinksOrAnchors':missing,
    'links':checked,'externalLinksNotRechecked':sorted(set(external)),
    'firstTwoCardsPreservedExactly':preserved,'rootCards':len(cards),
    'rootIndexSource':{'branch':'main','revision':baseline['indexBaseCommit'],'sha256':baseline['indexBaseSha256']},
    'protectedFilesChecked':len(baseline['files']),'modifiedProtectedFiles':changed,
    'diagramsUnchanged':not any('/architecture/' in name for name in changed),
    'originalTechnicalCodeBlocks':len(code_blocks),'missingTechnicalCodeBlocks':missing_code,
    'activeEvidenceMedia':active_media,'nojekyll':(ROOT / '.nojekyll').is_file(),
    'publishing':{'branch':'main','folder':'/','published':False,
        'note':'Existing practice 02/03 diagram links are retained and verified against real main Git objects; absent locally on Practica04.'},
}
(HERE / 'documentation-check.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

# Temporary Markdown preview for browser QA only; not another published homepage.
preview = parser.render((APP / 'README.md').read_text(encoding='utf-8'))
styles = '''*{box-sizing:border-box}body{margin:0;background:#0d1117;color:#e6edf3;font:16px/1.65 system-ui,sans-serif}main{max-width:980px;margin:auto;padding:32px 20px}h1,h2,h3{line-height:1.3;overflow-wrap:anywhere}h2{margin-top:40px;border-bottom:1px solid #30363d;padding-bottom:10px}a{color:#68d8cf}table{display:block;overflow:auto;border-collapse:collapse;max-width:100%}td,th{border:1px solid #30363d;padding:8px 12px;min-width:100px}pre{overflow:auto;background:#161b22;padding:16px;border-radius:10px}code{overflow-wrap:anywhere}p,li{overflow-wrap:anywhere}img,video{max-width:100%;height:auto}'''
preview = '<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>TokTik · vista Markdown de verificación</title><style>'+styles+'</style><main>'+preview+'</main></html>'
(ROOT / '.buildlog/toktik-readme-preview.html').write_text(preview,encoding='utf-8')
print(json.dumps({key:report[key] for key in ['status','relativeLinksChecked','missingLinksOrAnchors','firstTwoCardsPreservedExactly','rootCards','protectedFilesChecked','modifiedProtectedFiles','diagramsUnchanged','originalTechnicalCodeBlocks','missingTechnicalCodeBlocks','nojekyll']},ensure_ascii=False))
raise SystemExit(0 if report['status']=='pass' else 1)
