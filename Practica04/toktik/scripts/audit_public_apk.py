"""Check actual APK entries for local secret values without printing them."""
import json
import sys
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
path=Path(sys.argv[1]) if len(sys.argv)>1 else ROOT/'build/app/outputs/flutter-apk/app-release.apk'
keys_path=ROOT/'api_keys.json'
keys=json.loads(keys_path.read_text(encoding='utf-8-sig')) if keys_path.exists() else {}
secrets={name:str(value).strip().encode() for name,value in keys.items() if name.endswith('_API_KEY') and str(value).strip()}
found={name:False for name in secrets}
if not path.exists():
    print(json.dumps({'apkExists':False}))
    raise SystemExit(2)
with zipfile.ZipFile(path) as archive:
    bundled_key_file=any(name.rsplit('/',1)[-1]=='api_keys.json' for name in archive.namelist())
    for item in archive.infolist():
        if item.is_dir():continue
        with archive.open(item) as stream:
            tail=b''
            while chunk:=stream.read(1024*1024):
                sample=tail+chunk
                for name,secret in secrets.items():
                    if secret in sample:found[name]=True
                tail=sample[-max([len(s) for s in secrets.values()]+[1]):]
print(json.dumps({'apkExists':True,'bundledApiKeysJson':bundled_key_file,'localSecretBytesFound':found,
                  'scanScope':'Literal local secret values in every uncompressed APK entry; not proof against unknown/encoded secrets.'}))
raise SystemExit(1 if bundled_key_file or any(found.values()) else 0)
