"""Build the diagram from the inspected working tree; never modifies Flutter."""
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
components, connections = [], []
def node(id, label, sublabel, x, y, paths, kind='frontend'):
    components.append(dict(id=id, type=kind, label=label, sublabel=sublabel,
        pos=[x,y], size=[230,70], sources=[dict(path=p, line=1) for p in paths]))
def edge(a,b,label=None):
    item=dict(id=f'{a}-{b}',from_=a,to=b)
    item['from']=item.pop('from_')
    if label: item['label']=label
    connections.append(item)
node('app','MainApp + ProviderScope','MaterialApp.router · ConsumerWidget',40,40,['lib/main.dart'])
node('router','appRouter','GoRouter · 11 rutas · inicio /',400,40,['lib/config/router/app_router.dart'])
node('home','HomeScreen','_HomeView + _CustomListTile',760,40,['lib/presentation/screens/home/home_screen.dart'])
node('theme','ThemeNotifier / AppTheme','Estado global → ThemeData Material 3',40,210,['lib/presentation/providers/theme_provider.dart','lib/config/theme/app_theme.dart'],'backend')
node('menu','appMenuItems','10 destinos · MenuItem',760,210,['lib/config/menu/menu_items.dart'])
node('drawer','SideMenu','NavigationDrawer · selección local',760,380,['lib/presentation/widgets/side_menu.dart'])
node('demos','Botones, tarjetas y avisos','ButtonsScreen · CardsScreen · SnackbarScreen',400,380,['lib/presentation/screens/buttons/buttons_screen.dart','lib/presentation/screens/cards/cards_screen.dart','lib/presentation/screens/snackbar/snackbar_screen.dart'])
node('local','Animación y controles','AnimatedScreen · UiControlsScreen · setState',400,550,['lib/presentation/screens/animated/animated_screen.dart','lib/presentation/screens/ui_controls/ui_controls_screen.dart'])
node('tutorial','Tutorial y progreso','AppTutorialScreen · ProgressScreen',760,550,['lib/presentation/screens/app_tutorial/app_tutorial_screen.dart','lib/presentation/screens/progress/progress_screen.dart'])
node('counter','CounterScreen','counterProvider = 5 · isDarkmodeProvider',40,550,['lib/presentation/screens/counter/counter_screen.dart','lib/presentation/providers/counter_provider.dart'],'frontend')
node('changer','ThemeChangerScreen','colorListProvider · ThemeNotifier',40,380,['lib/presentation/screens/theme_changer/theme_changer_screen.dart'])
node('infinite','InfiniteScrollScreen','ScrollController · refresh · carga simulada',400,720,['lib/presentation/screens/infinite_scroll/infinite_scroll_screen.dart'])
node('images','picsum.photos','Imágenes remotas · HTTPS',760,720,['lib/presentation/screens/cards/cards_screen.dart','lib/presentation/screens/infinite_scroll/infinite_scroll_screen.dart'],'external')
edge('app','router','configura'); edge('app','theme','observa'); edge('router','home','/'); edge('home','menu','lee'); edge('home','drawer','drawer'); edge('drawer','menu','lee')
for target in ['demos','local','tutorial','counter','changer','infinite']: edge('router',target)
edge('changer','theme','modifica'); edge('infinite','images','HTTPS'); edge('demos','images','HTTPS')
data=dict(schema_version=1,diagram_type='architecture',meta=dict(title='Widgets App — arquitectura de interfaces Flutter',locale='es',output='architecture/index.html',quality_profile='showcase'),components=components,connections=connections,cards=[
 dict(dot='violet',title='Navegación real',items=['HomeScreen y SideMenu leen appMenuItems y llaman context.push(menuItem.link).','appRouter construye las 11 pantallas. Las flechas sin etiqueta desde appRouter representan sus builders.','screens.dart es un archivo de exportaciones, no una capa de ejecución.']),
 dict(dot='cyan',title='Widgets y estado',items=['CustomButton: ClipRRect + Material + InkWell; se usa en ButtonsScreen.','CardsScreen compone _CardType1, _CardType2, _CardType3 y _CardType4.','Tutorial: SlideInfo, slides, _Slide y PageController. Progreso: _ControlledProgresIndicator con StreamBuilder.','CounterScreen modifica counterProvider e isDarkmodeProvider. Este último NO controla el tema de MainApp.','MainApp observa themeNotifierProvider; ThemeChangerScreen cambia modo y color. selectedColorProvider está declarado sin uso activo.']),
 dict(dot='amber',title='Alcance y diferencias detectadas',items=['Mapa del árbol de trabajo del 27/10/2026; no representa exclusivamente el commit HEAD. Fuentes locales en source-evidence.json y analysis.md.','pubspec.yaml declara Flutter, cupertino_icons y go_router; flutter_riverpod y animate_do están importados pero no declarados.','assets/images/1.png, 2.png, 3.png y jar-loading.gif están referenciados, pero faltan y no están registrados.','La paginación se simula con Future.delayed y listas en memoria; no hay backend propio, repositorios ni almacenamiento persistente.'])])
data['meta']['legend'] = dict(entries=dict(frontend=dict(label='Interfaz y configuración'),backend=dict(label='Estado en memoria'),external=dict(label='Imágenes externas')))
evidence = {c['id']: c.pop('sources') for c in components}
placements = {'app':[40,40], 'theme':[40,210], 'changer':[40,380], 'counter':[40,550],
 'router':[400,210], 'home':[760,40], 'menu':[1120,40], 'drawer':[1120,210],
 'demos':[760,210], 'infinite':[760,380], 'images':[1120,380], 'local':[400,550], 'tutorial':[760,550]}
for c in components:
    c['pos'] = placements[c['id']]
(root/'architecture/source-evidence.json').write_text(json.dumps(dict(basis='working-tree', reason='Uncommitted source files cannot be attributed to HEAD', components=evidence),ensure_ascii=False,indent=2),encoding='utf-8')
(root/'architecture/candidate.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
