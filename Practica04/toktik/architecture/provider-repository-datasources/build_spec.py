"""Author the second diagram. Archify performs rendering and all delivery gates."""
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = HERE.parents[1]
ROOT = HERE.parents[3]


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True, encoding='utf-8').strip()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def protected_files():
    folders = ['lib', 'android', 'test', 'integration_test', 'assets',
               'architecture/provider-local', 'architecture/initial', 'architecture/final']
    paths = [file for folder in folders for file in (APP / folder).rglob('*')
             if file.is_file() and '.gradle' not in file.parts]
    paths += [file for practice in ['Practica02', 'Practica03']
              for file in (ROOT / practice).rglob('*')
              if file.is_file() and not any(part in ['build', '.dart_tool', '.gradle'] for part in file.parts)]
    paths += [APP / 'pubspec.yaml', APP / 'pubspec.lock']
    return {str(p.relative_to(ROOT)).replace('\\', '/'): digest(p) for p in paths}


baseline = HERE / 'protected-files-before.json'
if not baseline.exists():
    baseline.write_text(json.dumps({'head': git('rev-parse', 'HEAD'),
        'branch': git('branch', '--show-current'), 'dirtyPaths': git('status', '--short').splitlines(),
        'files': protected_files()}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def src(path, label):
    full = 'Practica04/toktik/lib/' + path
    committed = git('show', 'HEAD:' + full)
    return {'path': full, 'line': 1, 'end_line': len(committed.splitlines()), 'label': label}


def node(id, kind, label, detail, x, y, sources):
    return {'id': id, 'type': kind, 'label': label, 'sublabel': detail,
            'pos': [x, y], 'size': [310, 100], 'sources': sources}


def edge(id, start, end, label, **extra):
    return {'id': id, 'from': start, 'to': end, 'label': label, **extra}


translations = json.loads((APP / 'architecture/provider-local/candidate.json').read_text(encoding='utf-8'))['meta']['translations']
candidate = {
    'schema_version': 1, 'diagram_type': 'architecture',
    'meta': {
        'title': 'TokTik - Arquitectura con Provider, Repository y DataSources',
        'output': 'architecture/provider-repository-datasources/index.html',
        'locale': 'es', 'translations': translations, 'quality_profile': 'showcase',
        'repository': {'url': git('remote', 'get-url', 'origin'), 'revision': git('rev-parse', 'HEAD'),
                       'provider': 'github', 'link_mode': 'web'},
        'legend': {'entries': {
            'frontend': {'label': 'Presentation: interfaz y estado'},
            'backend': {'label': 'Infrastructure: adaptadores y conversión'},
            'security': {'label': 'Domain: contratos y entidades Dart'},
            'database': {'label': 'Recursos locales y persistencia'},
            'external': {'label': 'Servicios HTTPS externos'},
        }},
    },
    'components': [
        node('interface', 'frontend', 'Screens y Widgets', 'DiscoverScreen · VideoScrollableView', 40, 40,
             [src('presentation/screens/discover/discover_screen.dart', 'Interfaz y watch'),
              src('presentation/shared/video_scrollable_view.dart', 'Entrega de videos al reproductor'),
              src('presentation/widgets/video/fullscreen_player.dart', 'FullscreenPlayer y controles')]),
        node('providers', 'frontend', 'DiscoverProvider', 'SettingsProvider · PlaybackCoordinator', 420, 40,
             [src('presentation/providers/discover_provider.dart', 'fetch y notifyListeners'),
              src('presentation/providers/settings_provider.dart', 'Preferencias y temporada'),
              src('presentation/providers/playback_coordinator.dart', 'Reproducción y callbacks')]),
        node('entities', 'security', 'VideoPost · VideoBatch', 'VideoSource · AppPreferences · métricas', 40, 340,
             [src('domain/entities/video_post.dart', 'Entidad de video'),
              src('domain/entities/video_batch.dart', 'Lote de entidades'),
              src('domain/entities/app_preferences.dart', 'Preferencias de dominio')]),
        node('catalog-contract', 'security', 'VideoCatalogRepository', 'VideoSourceDatasource: fetch / available', 420, 340,
             [src('domain/repositories/video_catalog_repository.dart', 'Contrato del catálogo'),
              src('domain/datasources/video_source_datasource.dart', 'Contrato de fuentes')]),
        node('preferences-contract', 'security', 'Contratos de preferencias', 'Favorites · VideoStatistics · Preferences', 800, 340,
             [src('domain/repositories/favorites_repository.dart', 'FavoritesRepository'),
              src('domain/repositories/video_statistics_repository.dart', 'VideoStatisticsRepository'),
              src('domain/repositories/preferences_repository.dart', 'PreferencesRepository')]),
        node('fallback', 'backend', 'FallbackVideoRepository', 'Ordena fuentes; primer lote válido', 420, 640,
             [src('infrastructure/repositories/fallback_video_repository.dart', 'Selección y fallback'),
              src('main.dart', 'Inyección en VideoCatalogRepository')]),
        node('preferences', 'backend', 'Repositorios de preferencias', 'Favorites · Statistics · SharedPreferences', 800, 640,
             [src('infrastructure/repositories/preferences_favorites_repository.dart', 'PreferencesFavoritesRepository'),
              src('infrastructure/repositories/preferences_statistics_repository.dart', 'PreferencesStatisticsRepository'),
              src('infrastructure/repositories/shared_preferences_repository.dart', 'SharedPreferencesRepository')]),
        node('local', 'backend', 'LocalAssetsDatasource', 'AssetManifest · _post crea VideoPost', 40, 940,
             [src('infrastructure/datasources/local_assets_datasource.dart', 'Catálogo local del bundle')]),
        node('remote', 'backend', 'Coverr / Pixabay / Archive', 'DataSources; primeras dos con clave', 420, 940,
             [src('infrastructure/datasources/coverr_datasource.dart', 'CoverrDatasource'),
              src('infrastructure/datasources/pixabay_datasource.dart', 'PixabayDatasource'),
              src('infrastructure/datasources/archive_datasource.dart', 'ArchiveDatasource')]),
        node('mapper', 'backend', 'VideoMapper', 'JSON remoto y favoritos ↔ VideoPost', 800, 940,
             [src('infrastructure/mappers/video_mapper.dart', 'Conversión defensiva a entidades')]),
        node('assets', 'database', 'assets/videos/*.mp4', 'Bundle Flutter · sin petición HTTP', 40, 1240,
             [src('infrastructure/datasources/local_assets_datasource.dart', 'Lectura del AssetManifest')]),
        node('client', 'backend', 'JsonApiClient', 'http.Client · JSON · timeout de 12 s', 420, 1240,
             [src('infrastructure/datasources/json_api_client.dart', 'HTTP y jsonDecode'),
              src('config/api/api_config.dart', 'Timeout y claves de compilación')]),
        node('store', 'database', 'SharedPreferencesStore', 'PreferencesStore · SharedPreferencesAsync', 800, 1240,
             [src('infrastructure/storage/preferences_store.dart', 'Persistencia del dispositivo')]),
        node('services', 'external', 'Coverr · Pixabay · Internet Archive', 'APIs HTTPS; sin backend propio de TokTik', 420, 1540,
             [src('infrastructure/datasources/coverr_datasource.dart', 'api.coverr.co/videos'),
              src('infrastructure/datasources/pixabay_datasource.dart', 'pixabay.com/api/videos/'),
              src('infrastructure/datasources/archive_datasource.dart', 'archive.org: búsqueda y metadata')]),
    ],
    'boundaries': [
        {'kind': 'region', 'label': 'PRESENTATION · Interfaz y estado reactivo', 'wraps': ['interface', 'providers'], 'pad': 32},
        {'kind': 'region', 'label': 'DOMAIN · Contratos y entidades independientes de Flutter', 'wraps': ['entities', 'catalog-contract', 'preferences-contract'], 'pad': 32},
        {'kind': 'region', 'label': 'INFRASTRUCTURE · Repositories, DataSources, Mapper y adaptadores', 'wraps': ['fallback', 'preferences', 'local', 'remote', 'mapper', 'client'], 'pad': 32},
    ],
    'connections': [
        edge('provider-ui', 'providers', 'interface', 'notifica', variant='emphasis'),
        edge('catalog-provider', 'catalog-contract', 'providers', 'VideoBatch', variant='emphasis'),
        edge('entities-contract', 'entities', 'catalog-contract', 'tipos', variant='dashed'),
        edge('repository-contract', 'fallback', 'catalog-contract', 'implementa / usa', variant='dashed'),
        edge('remote-fallback', 'remote', 'fallback', 'VideoBatch', variant='emphasis'),
        edge('local-fallback', 'local', 'fallback', 'VideoBatch', variant='emphasis'),
        edge('assets-local', 'assets', 'local', 'manifest', variant='emphasis'),
        edge('client-remote', 'client', 'remote', 'JSON', variant='emphasis'),
        edge('services-client', 'services', 'client', 'HTTPS / JSON', variant='emphasis'),
        edge('mapper-remote', 'mapper', 'remote', 'VideoPost', variant='emphasis'),
        edge('preferences-provider', 'preferences-contract', 'providers', 'restaura / guarda'),
        edge('preferences-implements', 'preferences', 'preferences-contract', 'implementan', variant='dashed'),
        edge('preferences-mapper', 'preferences', 'mapper', 'favoritos JSON'),
        edge('store-preferences', 'store', 'preferences', 'lectura / escritura', fromSide='right', toSide='right'),
    ],
    'cards': [
        {'dot': 'cyan', 'title': '01 · Solicitud y respuesta', 'items': [
            'La UI envía acciones; DiscoverProvider llama fetch mediante el contrato.',
            'El retorno fluye de DataSource a Repository, Provider y Widgets.',
            'Verde: datos de retorno. Discontinua: tipos o implementación de contratos.',
        ]},
        {'dot': 'emerald', 'title': '02 · Fuentes reales y respaldo', 'items': [
            'CoverrDatasource y PixabayDatasource se omiten si no hay claves.',
            'ArchiveDatasource consulta búsqueda y metadata; filtra archivos compatibles.',
            'LocalAssetsDatasource enumera el bundle y construye entidades sin VideoMapper.',
            'Fallback prueba fuentes disponibles y devuelve la primera con videos válidos.',
        ]},
        {'dot': 'violet', 'title': '03 · Domain y conversión', 'items': [
            'VideoCatalogRepository y VideoSourceDatasource son contratos de dominio.',
            'VideoBatch transporta videos, fuente, hasMore y avisos.',
            'VideoMapper convierte mapas JSON a VideoPost; no existe una capa Models separada.',
            'Los DataSources llaman al cliente y al mapper; el mapper no realiza HTTP.',
        ]},
        {'dot': 'amber', 'title': '04 · Estado y persistencia', 'items': [
            'PreferencesFavoritesRepository almacena el catálogo favorito con VideoMapper.',
            'PreferencesStatisticsRepository guarda incrementos locales de vistas.',
            'SharedPreferencesRepository guarda ajustes; no almacena los bytes de video.',
            'SharedPreferencesStore adapta PreferencesStore a SharedPreferencesAsync.',
        ]},
        {'dot': 'slate', 'title': '05 · Composición y alcance CLEAN', 'items': [
            'main() inyecta el catálogo, las cuatro fuentes y los Providers.',
            'StartupScreen e intros preceden al feed; identidad y sonido son auxiliares.',
            'VideoPlayerController reproduce las URL o assets; no pasa sus bytes por VideoMapper.',
            'El primer diagrama se conserva; el índice compartido permite alternar entre ambos.',
        ]},
    ],
}
(HERE / 'candidate.json').write_text(json.dumps(candidate, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('architecture/provider-repository-datasources/candidate.json')
