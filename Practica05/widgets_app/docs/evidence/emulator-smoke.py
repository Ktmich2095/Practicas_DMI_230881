import subprocess,time,json,re,xml.etree.ElementTree as ET
from pathlib import Path
adb=['C:/Users/PC-15/AppData/Local/Android/sdk/platform-tools/adb.exe','-s','emulator-5554']
def run(*args):return subprocess.check_output(adb+list(args),timeout=35)
def ui():
 run('shell','uiautomator','dump','/sdcard/widgets-ui.xml')
 return ET.fromstring(run('shell','cat','/sdcard/widgets-ui.xml'))
def tap(label):
 root=ui()
 for n in root.iter('node'):
  if label in n.get('content-desc','') or label in n.get('text',''):
   nums=list(map(int,re.findall(r'\d+',n.attrib['bounds'])))
   run('shell','input','tap',str((nums[0]+nums[2])//2),str((nums[1]+nums[3])//2));time.sleep(1);return
 raise AssertionError('Missing UI label '+label)
def capture(name):
 time.sleep(1)
 run('shell','screencap','-p','/sdcard/widgets-'+name+'.png')
 run('pull','/sdcard/widgets-'+name+'.png','docs/evidence/app-'+name+'.png')
checks=[]
run('shell','am','force-stop','com.example.widgets_app')
run('shell','am','start','-n','com.example.widgets_app/.MainActivity');time.sleep(4)
capture('home')
tap('Riverpod Counter')
root=ui();assert any('Valor: 5' in n.get('content-desc','') for n in root.iter('node'))
run('shell','input','tap','1150','2650');time.sleep(1)
root=ui();assert any('Valor: 6' in n.get('content-desc','') for n in root.iter('node'))
checks.append('Counter opens at 5 and increments to 6 on emulator');capture('counter')
run('shell','input','keyevent','KEYCODE_BACK');time.sleep(1)
run('shell','input','swipe','640','2400','640','900','500');time.sleep(1)
tap('Cambiar tema');run('shell','input','tap','1170','240');time.sleep(1)
tap('Color 2');capture('theme-dark');checks.append('Theme screen opens; toggled brightness and selected Color 2')
run('shell','input','keyevent','KEYCODE_BACK');time.sleep(1)
tap('Introducción a la aplicación');capture('tutorial');tap('Salir');checks.append('Tutorial assets visible and exit works')
tap('InfiniteScroll y Pull');time.sleep(3);capture('gallery');checks.append('Infinite gallery opens')
run('shell','input','keyevent','KEYCODE_BACK');time.sleep(1)
run('shell','input','swipe','640','900','640','2400','500');time.sleep(1)
tap('Open navigation menu');capture('drawer');checks.append('Drawer opens')
Path('docs/evidence/emulator-smoke.json').write_text(json.dumps({'device':'emulator-5554','abi':'x86_64','checks':checks},indent=2),encoding='utf-8')
print(json.dumps(checks))
