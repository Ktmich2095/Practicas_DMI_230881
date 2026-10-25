"""Check portable links/resources and record the exact inspected source bytes."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib, json, re, subprocess

folder = Path(__file__).resolve().parent
app = folder.parent
repo = app.parent.parent
class Links(HTMLParser):
    def __init__(self): super().__init__(); self.links=[]; self.resources=[]
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if 'href' in a: self.links.append(a['href'])
        if 'src' in a: self.resources.append(a['src'])
        if tag=='link' and a.get('rel')=='stylesheet': self.resources.append(a['href'])
def inspect(file):
    parsed=Links(); parsed.feed(file.read_text(encoding='utf-8'))
    local=[]
    for ref in parsed.links+parsed.resources:
        uri=urlsplit(ref)
        if uri.scheme or uri.netloc or not uri.path: continue
        target=(file.parent/unquote(uri.path)).resolve()
        if target.is_dir(): target=target/'index.html'
        local.append(dict(link=ref,exists=target.is_file(),relative=not uri.path.startswith('/'),resource=ref in parsed.resources))
    return dict(local=local,external=[x for x in parsed.links if urlsplit(x).scheme in ['http','https']],runtimeExternalResources=[x for x in parsed.resources if urlsplit(x).scheme in ['http','https']])
menu=inspect(repo/'index.html'); diagram=inspect(folder/'index.html')
original=subprocess.check_output(['git','show','main:index.html'],cwd=repo).decode('utf-8')
old=Links();old.feed(original)
current=Links();current.feed((repo/'index.html').read_text(encoding='utf-8'))
files=[p for p in folder.rglob('*') if p.is_file()]
ignored=[]
for file in files+[repo/'index.html']:
    if subprocess.run(['git','check-ignore','--quiet',str(file)],cwd=repo).returncode==0: ignored.append(str(file.relative_to(repo)))
source_files=sorted((app/'lib').rglob('*.dart'))+[app/'pubspec.yaml']
evidence=[]
for source in source_files:
    text=source.read_text(encoding='utf-8')
    evidence.append(dict(path=source.relative_to(app).as_posix(),sha256=hashlib.sha256(source.read_bytes()).hexdigest(),lines=len(text.splitlines()),symbols=[dict(line=i,text=line.strip()) for i,line in enumerate(text.splitlines(),1) if re.match(r'\s*(class |enum |final .*Provider|final appRouter|const appMenuItems|export )',line)]))
record=dict(basis='working-tree',date='2026-10-27',head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo).decode().strip(),note='HEAD is identity only. Modified/untracked source bytes are NOT attributed to this revision.',files=evidence)
(folder/'working-tree-evidence.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
result=dict(diagram=diagram,menu=menu,allOriginalLinksPreserved=all(x in current.links for x in old.links),ignoredFiles=ignored,newCardTargetExists=(repo/'Practica05/widgets_app/architecture/index.html').is_file(),newCardLinkCount=current.links.count('Practica05/widgets_app/architecture/index.html'),svgExists=(folder/'architecture.svg').is_file(),previousPracticeMissingLinks=[x['link'] for x in menu['local'] if not x['exists']])
result['newDeliverableOK']=result['newCardTargetExists'] and result['newCardLinkCount']==1 and result['svgExists'] and result['allOriginalLinksPreserved'] and not ignored and all(x['exists'] and x['relative'] for x in diagram['local']) and not diagram['runtimeExternalResources']
(folder/'site-check.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
assert result['newDeliverableOK']
