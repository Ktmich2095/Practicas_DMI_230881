# TokTik - Arquitectura con Provider, Repository y DataSources

[Abrir segundo diagrama →](index.html) · [Abrir SVG →](provider-repository-datasources.svg)

[Ver arquitectura con Provider Local →](../index.html#provider-local)

[Ver arquitectura con Provider, Repository y DataSources →](../index.html#provider-repository-datasources)

Segunda entrega de la Práctica 04 de Desarrollo Móvil Integral. El índice HTML
compartido añade navegación sin modificar ningún archivo de `provider-local/`.
Ambos diagramas usan el visor Archify clásico, estático, con la misma tipografía,
tarjetas, temas claro/oscuro, controles de zoom y exportación.

## Objetivo

Explicar la arquitectura CLEAN real que lleva metadatos de video desde fuentes
locales o APIs hasta la interfaz. Las flechas verdes representan el retorno de
datos; las discontinuas distinguen tipos e implementación de contratos. Las
solicitudes se hacen en sentido inverso al retorno. No son llamadas HTTP entre
Provider y Repository: esas interacciones suceden dentro del proceso Flutter.

Los nodos que agrupan clases son agrupaciones documentales, no nuevas clases.
Por ejemplo, «Repositorios de preferencias» reúne tres implementaciones reales.
El rol semántico de color de Archify se renombra en la leyenda: Domain no es un
servicio de seguridad, ni Presentation es un servidor remoto.

## Presentation: pantallas, Widgets y Providers

| Componentes reales | Función |
| --- | --- |
| `DiscoverScreen` | Escucha `DiscoverProvider` y `SettingsProvider`; presenta Discover, For You o Favorites. Son secciones de la misma pantalla. |
| `VideoScrollableView` | Recibe `List<VideoPost>`, controla el scroll vertical y selecciona el video en `PlaybackCoordinator`. |
| `FullscreenPlayer`, `VideoButtons`, `ExpandableCaption` | Muestran el controlador del video, favorito, sonido, métricas y descripción expandible. |
| `SettingsSheet`, `TokTikLogo` | Ajustes de fuente/temporada y presentación de la identidad visual. Se documentan como consumidores auxiliares de estado. |
| `DiscoverProvider` | Solicita lotes al contrato del catálogo; mantiene listas, favoritos, carga, errores y paginación; llama `notifyListeners()`. |
| `SettingsProvider` | Restaura y guarda `AppPreferences`; calcula la temporada activa según preferencia manual o calendario. |
| `PlaybackCoordinator` | Mantiene controladores y reproducción visible; pausa, silencio y lifecycle. Comunica vistas calificadas a `DiscoverProvider` mediante un callback inyectado. |
| `StartupScreen`, `StartupProvider`, `SeasonIdentityProvider`, `IntroAudioProvider`, `ThemeAudioProvider`, `IntroPreviewScreen` | Coordinan arranque, identidad e intros. Son complementarios al recorrido del catálogo y se mantienen como contexto, sin desplegar otra cadena de fuentes de video. |

`main()` es la raíz de composición: crea `http.Client`, `JsonApiClient`, los
cuatro DataSources, `FallbackVideoRepository` y los Providers. Inyecta el catálogo
con el tipo `VideoCatalogRepository` mediante Provider. El arranque empieza en
`StartupScreen`; no se dibuja una entrada directa que omita la intro.

## Domain: contratos y entidades

| Elemento | Ubicación y responsabilidad |
| --- | --- |
| `VideoCatalogRepository` | `lib/domain/repositories/video_catalog_repository.dart`: contrato `fetch(VideoSource, page)` que retorna `Future<VideoBatch>`. |
| `VideoSourceDatasource` | `lib/domain/datasources/video_source_datasource.dart`: contrato `source`, `available` y `fetch(page)`. Incluye `SourceException`. |
| `FavoritesRepository` | Lectura y guardado de identificadores y snapshots favoritos. |
| `VideoStatisticsRepository` | Lectura y guardado de incrementos de vistas. |
| `PreferencesRepository` | Lectura y guardado de `AppPreferences`. |
| `VideoPost` | Identidad, URL, descripción, autor, procedencia y metadatos de un video. |
| `VideoBatch` | Lista de `VideoPost`, fuente efectiva, `hasMore` y avisos. |
| `VideoSource` | Selección aleatoria, local, Coverr, Pixabay o Archive. |
| `VideoStatistics` | Resolución de métricas; no convierte los datos simulados de demostración en métricas reales de las APIs. |
| `AppPreferences`, `Season`, `SeasonCalendar`, `SeasonRange` | Preferencias y reglas de temporada. Son contexto del estado, no fuentes de video. |

Estos contratos y entidades son Dart sin importar Flutter. No existe una carpeta
de casos de uso ni una capa `Models`/DTO separada en esta implementación. No se
inventaron clases como `VideoModel`, una API propia de TokTik o una base SQL.

## Infrastructure: implementaciones y fuentes

### Catálogo y respaldo

`FallbackVideoRepository` implementa `VideoCatalogRepository` y recibe una lista
de `VideoSourceDatasource`. Prioriza la fuente elegida o baraja el orden si se
selecciona Aleatoria. Omite fuentes no disponibles, prueba las siguientes ante
errores o resultados vacíos, valida enlaces con `LocalAssetsDatasource.valid` y
elimina duplicados dentro del lote. Devuelve **el primer lote no vacío válido**;
no fusiona todas las fuentes. Los avisos explican las alternativas omitidas.

La versión actual del árbol local añade un límite de espera por fuente. El
comportamiento general de selección y respaldo también existe en el commit
verificado por Archify; no se atribuye ese cambio sin commit a dicho SHA.

### DataSources reales

| Clase | Fuente y acceso real | Condición |
| --- | --- | --- |
| `LocalAssetsDatasource` | `AssetManifest` enumera `assets/videos/*.mp4`; `_post` construye `VideoPost` directamente. | Disponible sin claves; sólo ofrece la página inicial. No llama a `VideoMapper` ni hace HTTP. |
| `CoverrDatasource` | `GET https://api.coverr.co/videos` con paginación y `Authorization: Bearer`. Usa `VideoMapper.coverr`. | Requiere `COVERR_API_KEY`; sin ella `available` es falso. |
| `PixabayDatasource` | `GET https://pixabay.com/api/videos/` con clave, paginación y búsqueda segura. Usa `VideoMapper.pixabay`. | Requiere `PIXABAY_API_KEY`; sin ella se omite. |
| `ArchiveDatasource` | `GET https://archive.org/advancedsearch.php`, seguido de `/metadata/{identifier}`. Usa `VideoMapper.archive`. | Sin clave. Consulta metadatos de dos elementos en paralelo y filtra archivos y licencias compatibles. |

Los nombres de variables de clave son configuración, no credenciales incluidas.
La búsqueda Archive exige material declarado CC0 o CC BY; el mapper reconoce
licencias abiertas y descarta elementos oscuros, privados o archivos incompatibles.

`JsonApiClient` comparte un `http.Client`, aplica el timeout de `ApiConfig`
(12 segundos), verifica HTTP 200 y convierte UTF-8/JSON a mapas Dart. Propaga
`SourceException` con errores acotados. **Los DataSources llaman al cliente**;
la flecha verde cliente → DataSources representa la respuesta JSON, no una
inversión de la responsabilidad de petición.

### Mapper y formatos

`VideoMapper` está en `lib/infrastructure/mappers/video_mapper.dart`. Sus métodos
`coverr`, `pixabay` y `archive` transforman mapas de las APIs en entidades
`VideoPost`. Los helpers defensivos aíslan registros inválidos. `toJson` y
`fromJson` serializan/deserializan snapshots de favoritos. El mapper no hace
peticiones de red, no reproduce videos y no representa una API adicional.

### Persistencia local

| Implementación | Contrato de Domain | Datos |
| --- | --- | --- |
| `PreferencesFavoritesRepository` | `FavoritesRepository` | Snapshots favoritos JSON en `toktik.favorite_catalog.v2`; compatibilidad de lectura con identificadores anteriores. Usa `VideoMapper`. |
| `PreferencesStatisticsRepository` | `VideoStatisticsRepository` | Incrementos de vistas en `toktik.view_increments.v1`. |
| `SharedPreferencesRepository` | `PreferencesRepository` | Fuente, temporada y preferencias en `toktik.preferences.v1`. |

Las tres implementaciones acceden al límite `PreferencesStore`. En producción,
`SharedPreferencesStore` lo implementa con `SharedPreferencesAsync`. Persisten
metadatos y preferencias: **no descargan ni almacenan los bytes de los videos**.
La flecha gris de almacenamiento resume lectura y escritura; no es replicación.
La relación repositorios → mapper se aplica a favoritos, no a las tres clases.

Los repositorios de identidad/audio también existen (`AndroidLauncherIconRepository`,
`AudioplayersIntroRepository`, `AudioplayersThemeRepository`, con sus contratos
en Domain). Se registran en `main()` y no participan como DataSources del
catálogo; por eso se mencionan sin inventar conexiones al catálogo.

## Flujo de datos documentado

1. La UI dispara una carga o cambio de fuente; `DiscoverProvider` llama
   `VideoCatalogRepository.fetch`.
2. La implementación inyectada `FallbackVideoRepository` elige el orden de las
   fuentes y consulta su contrato `VideoSourceDatasource`.
3. Una fuente remota solicita JSON mediante `JsonApiClient` y llama `VideoMapper`
   para obtener `VideoPost`. La fuente local lee el manifiesto y crea entidades
   directamente. Cada fuente arma un `VideoBatch`.
4. El repositorio valida el lote y devuelve el primero válido. Provider adopta
   sus videos, fuente efectiva, avisos y paginación y llama `notifyListeners()`.
5. `context.watch` y los listeners reconstruyen los Widgets. El scroll entrega
   cada entidad a `FullscreenPlayer` y `PlaybackCoordinator`.
6. Los bytes del video son reproducidos por `VideoPlayerController` desde assets
   o la URL HTTPS: no circulan como JSON por el Repository ni por el mapper.
7. Favoritos, vistas calificadas y ajustes usan sus propios contratos de
   persistencia. Al restaurarse, vuelven a los Providers y a sus consumidores.

El diagrama combina un recorrido de retorno de datos con relaciones de tipos e
implementación expresamente diferenciadas. El contrato no ejecuta una etapa de
red: representa el tipo usado para inyectar la implementación.

## Relación con CLEAN y límites reales

Presentation depende de contratos y entidades de Domain. Infrastructure
implementa esos contratos y adapta HTTP, assets y preferencias. `main()` conoce
las implementaciones concretas para componer la aplicación. Provider es estado
de presentación, no un servicio de Domain. `VideoSourceDatasource` se define
en Domain y sus implementaciones concretas están en Infrastructure.

La descripción refleja el código, sin prometer una separación perfecta:
`PlaybackCoordinator` usa directamente el plugin `video_player` y no hay una
capa independiente de casos de uso. Los adaptadores de audio e identidad
siguen sus contratos existentes.

## Generación y evidencias

Ejecutado desde `Practica04/toktik` con Archify instalado en esta máquina:

```powershell
python architecture/provider-repository-datasources/build_spec.py
node C:/Users/otero/.agents/skills/archify/bin/archify.mjs finalize architecture architecture/provider-repository-datasources/candidate.json architecture/provider-repository-datasources/index.html --repo-root ../.. --quality showcase --json
node C:/Users/otero/.agents/skills/archify/bin/archify.mjs visual-check architecture/provider-repository-datasources/index.html --out-dir architecture/provider-repository-datasources/visual-check --summary --require-provenance
node architecture/provider-repository-datasources/verify-browser.mjs
python architecture/provider-repository-datasources/verify-site.py
```

Archify genera el HTML y su SVG integrado desde `candidate.json`.
`verify-browser.mjs` pulsa **Exportar → SVG Auto** en ese mismo visor y conserva
el Blob canónico como `provider-repository-datasources.svg`, sin dibujar otra
versión. También prueba el archivo SVG por separado en Chrome. Los scripts de
generación/validación no son dependencias del sitio publicado.

Las referencias de `sources` se verifican contra el commit
`4fb62ef0213a6053c3ef88ebb1c1b2b1d5b9bc81`; las responsabilidades se contrastaron
con el árbol actual. Las diferencias sin commit se identifican en el manifiesto
`protected-files-before.json`, sin presentarlas como contenido del SHA.

Recibos de Archify: `index.finalize-summary.json`, `index.finalize.json`,
`index.delivery.json` e `index.browser-check.json`. Capturas y recibo visual en
`visual-check/`. Validaciones adicionales en `responsive-export-check.json` y
`site-check.json`, con hashes del HTML/SVG y comprobación de archivos protegidos.

Validación realizada: perfil showcase **9/9**, cero errores y cero advertencias.
Las cuatro etapas de `finalize` pasaron, junto con las capturas de `visual-check`.
La comprobación adicional cubre 360, 390, 768 y 1440 píxeles, SVG independiente
sin errores XML y navegación entre ambos diagramas. No hubo errores JavaScript
ni desbordamiento horizontal. Se inspeccionaron capturas claras/oscuras, la
página completa y móvil. Los 520 archivos protegidos conservaron sus hashes,
incluida toda la carpeta del primer diagrama. Las rutas locales verificadas no
tienen destinos ausentes; `.nojekyll` se conserva.

## Publicación junto al primer diagrama

Configuración de Pages informada en la sesión: **main / raíz**. La rama local
sigue siendo `Practica04`. No se cambian ajustes de GitHub ni se publica nada;
`gh` no tenía autenticación en la revisión anterior. Los archivos deben llegar
a `main` mediante el procedimiento que decida el usuario.

- Diagrama independiente esperado:
  <https://ktmich2095.github.io/Practicas_DMI_230881/Practica04/toktik/architecture/provider-repository-datasources/>
- Navegación conjunta, seleccionando el segundo:
  <https://ktmich2095.github.io/Practicas_DMI_230881/Practica04/toktik/architecture/index.html?diagram=provider-repository-datasources>
- SVG esperado:
  <https://ktmich2095.github.io/Practicas_DMI_230881/Practica04/toktik/architecture/provider-repository-datasources/provider-repository-datasources.svg>

CSS, JavaScript, fuentes y SVG del visor están integrados. Las rutas entre
archivos son relativas, sin servidor local ni CDN. Se conserva `.nojekyll` en
la raíz. En móvil las tarjetas se apilan y el zoom permite explorar el gráfico;
el desplazamiento vertical conserva tamaño y proporciones sin recortar datos.
El índice ofrece apertura independiente y descarga SVG si se prefiere salir
del marco de navegación.

No se modificó código funcional, el primer diagrama ni otras prácticas. No se
realizaron commits, merges, pushes ni despliegues.
