"""Rebuild the Archify specification from inspected, committed source ranges."""
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
APP = ROOT / 'Practica04/toktik'
OUT = APP / 'architecture/provider-local'


def source(path, label):
    full = 'Practica04/toktik/lib/' + path
    content = subprocess.check_output(
        ['git', 'show', 'HEAD:' + full], cwd=ROOT, text=True, encoding='utf-8'
    )
    return {'path': full, 'line': 1, 'end_line': len(content.splitlines()), 'label': label}


def node(id, kind, label, detail, x, y, sources):
    return {'id': id, 'type': kind, 'label': label, 'sublabel': detail,
            'pos': [x, y], 'size': [330, 100], 'sources': sources}


def edge(id, start, end, label, **extra):
    return {'id': id, 'from': start, 'to': end, 'label': label, **extra}


translations = json.loads((APP / 'architecture/initial/candidate.json').read_text(encoding='utf-8'))['meta']['translations']
candidate = {
    'schema_version': 1,
    'diagram_type': 'architecture',
    'meta': {
        'title': 'TokTik - Arquitectura con Provider Local',
        'output': 'architecture/provider-local/index.html',
        'locale': 'es', 'translations': translations,
        'quality_profile': 'showcase',
        'repository': {
            'url': 'https://github.com/Ktmich2095/Practicas_DMI_230881.git',
            'revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
            'provider': 'github', 'link_mode': 'web',
        },
        'legend': {'entries': {
            'frontend': {'label': 'Presentación: Screens y Widgets'},
            'backend': {'label': 'Estado local: ChangeNotifier'},
            'database': {'label': 'Dominio: entidad Dart (sin base de datos)'},
            'external': {'label': 'Composición de la aplicación'},
        }},
    },
    'components': [
        node('composition', 'external', 'main() / MultiProvider', 'MyApp inicia StartupScreen', 40, 40,
             [source('main.dart', 'Registro e inyección')]),
        node('screen', 'frontend', 'DiscoverScreen', 'section y _positions: estado del widget', 40, 270,
             [source('presentation/screens/discover/discover_screen.dart', 'Pantalla y selección local')]),
        node('scroll', 'frontend', 'VideoScrollableView', 'PageController y página visible', 430, 270,
             [source('presentation/shared/video_scrollable_view.dart', 'Scroll vertical y lifecycle')]),
        node('player', 'frontend', 'FullscreenPlayer', 'VideoButtons + ExpandableCaption', 820, 270,
             [source('presentation/widgets/video/fullscreen_player.dart', 'Reproductor visual'),
              source('presentation/shared/video_buttons.dart', 'Favoritos y sonido'),
              source('presentation/widgets/video/expandable_caption.dart', 'expanded: estado del widget')]),
        node('discover', 'backend', 'DiscoverProvider', 'videos, favoritos y estados de carga', 40, 570,
             [source('presentation/providers/discover_provider.dart', 'ChangeNotifier del catálogo')]),
        node('playback', 'backend', 'PlaybackCoordinator', 'controladores, pausa y silencio', 430, 570,
             [source('presentation/providers/playback_coordinator.dart', 'Estado de reproducción'),
              source('main.dart', 'Callback onQualifiedView')]),
        node('settings', 'backend', 'SettingsProvider', 'AppPreferences y temporada activa', 820, 570,
             [source('presentation/providers/settings_provider.dart', 'Estado de preferencias')]),
        node('entity', 'database', 'VideoPost', 'Entidad Dart; List<VideoPost> en memoria', 40, 870,
             [source('domain/entities/video_post.dart', 'Modelo independiente de Flutter'),
              source('presentation/providers/discover_provider.dart', 'Listas mantenidas por el Provider')]),
    ],
    'boundaries': [
        {'kind': 'region', 'label': 'PRESENTACIÓN · Screens y Widgets', 'wraps': ['screen', 'scroll', 'player'], 'pad': 32},
        {'kind': 'region', 'label': 'PRESENTACIÓN · Providers y estado en memoria', 'wraps': ['discover', 'playback', 'settings'], 'pad': 32},
        {'kind': 'region', 'label': 'DOMINIO · Datos independientes de Flutter', 'wraps': ['entity'], 'pad': 32},
    ],
    'connections': [
        edge('startup-screen', 'composition', 'screen', 'tras la intro'),
        edge('screen-scroll', 'screen', 'scroll', 'videos', variant='emphasis'),
        edge('scroll-player', 'scroll', 'player', 'VideoPost', variant='emphasis'),
        edge('screen-discover', 'screen', 'discover', 'watch / acciones'),
        edge('scroll-playback', 'scroll', 'playback', 'select / escucha'),
        edge('player-playback', 'player', 'playback', 'pausa / sonido'),
        edge('buttons-settings', 'player', 'settings', 'watch: tema'),
        edge('playback-views', 'playback', 'discover', 'vistas'),
        edge('discover-entity', 'discover', 'entity', 'listas locales'),
    ],
    'cards': [
        {'dot': 'cyan', 'title': '01 · Objetivo y alcance', 'items': [
            'Primer diagrama: presentación y estado local dentro de la app.',
            'No representa un backend; Providers pertenecen a presentación.',
            'La app ya usa Repository y DataSources: quedan fuera de esta vista.',
        ]},
        {'dot': 'emerald', 'title': '02 · Acciones y actualización', 'items': [
            'La UI lee con context.watch y envía acciones al Provider.',
            'notifyListeners reconstruye los widgets que escuchan el estado.',
            'VideoButtons llama toggleFavorite; PlaybackCoordinator registra vistas.',
        ]},
        {'dot': 'violet', 'title': '03 · CLEAN y estado efímero', 'items': [
            'VideoPost es dominio Dart; no importa Flutter ni Provider.',
            'setState controla pestañas y texto expandido; no son Providers.',
            'No existe un Provider alternativo que cargue una lista fija sin Repository.',
        ]},
        {'dot': 'amber', 'title': '04 · Componentes complementarios', 'items': [
            'SettingsSheet edita SettingsProvider; MultiProvider registra dependencias.',
            'StartupProvider, SeasonIdentityProvider e IntroAudioProvider coordinan el arranque.',
            'ThemeAudioProvider conserva la barrera de audio; no es una fuente del catálogo.',
        ]},
    ],
}
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'candidate.json').write_text(json.dumps(candidate, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('architecture/provider-local/candidate.json')
