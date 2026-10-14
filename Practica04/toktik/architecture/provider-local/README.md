# TokTik - Arquitectura con Provider Local

[Abrir diagrama interactivo →](index.html) · [Abrir SVG →](provider-local.svg)

Práctica 04 de Desarrollo Móvil Integral. **Primera entrega únicamente**.

## Objetivo y alcance

Mostrar cómo la interfaz de TokTik consume y modifica el estado local mantenido
por Provider dentro del proceso Flutter. Es una vista de presentación y dominio
de la aplicación existente: no afirma que todo el proyecto carezca de Repository
o DataSources. Esas dependencias ya existen y se omiten deliberadamente en este
primer diagrama. No existe una clase alternativa de Provider que cargue una lista
fija sin repositorios; no se inventó ni implementó una para la ilustración.

## Componentes principales

| Componente real | Responsabilidad |
| --- | --- |
| `main()` / `MultiProvider` / `MyApp` | Componen el árbol de dependencias y muestran `StartupScreen` antes del feed. Provider no es una pantalla ni un servidor. |
| `DiscoverScreen` | Escucha catálogo y ajustes. Selecciona Discover, For You o Favorites. `section` y `_positions` son estado efímero del widget; `setState` cambia la sección. |
| `VideoScrollableView` | Recibe la lista de videos, mantiene `PageController` y la página visible, comunica selección y ciclo de vida a reproducción. Usa `ListenableBuilder`. |
| `FullscreenPlayer` | Dibuja el video, carga y errores; ofrece pausa y reintento. Agrupa `VideoButtons` y `ExpandableCaption` en el diagrama. |
| `VideoButtons` | Escucha `DiscoverProvider`, envía `toggleFavorite` y controla el sonido mediante `PlaybackCoordinator`. |
| `ExpandableCaption` | Conserva localmente `expanded` y lo reinicia cuando cambia el texto. Este estado es `StatefulWidget`, no Provider. |
| `DiscoverProvider` | `ChangeNotifier`: listas de videos, favoritos, métricas y estados de carga/error. Expone datos a los widgets y notifica cambios. La lista local no es una base de datos. |
| `PlaybackCoordinator` | `ChangeNotifier`: controlador visible, pausa, silencio y ciclo de vida. Notifica a la UI y comunica vistas calificadas mediante el callback inyectado en `main.dart`. |
| `SettingsProvider` | `ChangeNotifier`: preferencias actuales y temporada activa. Los Widgets consultan ese estado. `SettingsSheet` permite modificarlo. |
| `VideoPost` | Entidad de dominio Dart con identidad, descripción, URL y metadatos del video. No depende de Flutter ni de Provider. |

Los Providers `StartupProvider`, `SeasonIdentityProvider`, `IntroAudioProvider` y
`ThemeAudioProvider` complementan el arranque, identidad y coordinación sonora;
se mencionan como contexto y no se expanden en este mapa del feed. Tampoco se
añadieron pantallas separadas para las tres pestañas: son secciones reales de
`DiscoverScreen`.

## Conexiones y flujo de datos

1. `main()` registra los Providers. Después de `StartupScreen`, se muestra el feed.
2. `DiscoverScreen` lee el estado con `context.watch`, elige la colección de
   `VideoPost` y la entrega a `VideoScrollableView`.
3. El scroll selecciona el video en `PlaybackCoordinator`; `FullscreenPlayer`
   muestra su controlador y los botones envían acciones de reproducción.
4. `VideoButtons` llama `toggleFavorite` en `DiscoverProvider`. El callback de
   vistas de `PlaybackCoordinator` también actualiza el Provider del catálogo.
5. `notifyListeners()` informa a los consumidores; `context.watch` y
   `ListenableBuilder` reconstruyen la parte correspondiente de la interfaz.
6. Los ajustes cambian el estado de `SettingsProvider`, y sus consumidores leen
   la temporada y preferencias actualizadas.

Las flechas grises representan dependencia o invocación en la dirección indicada;
las verdes muestran la entrega de videos entre Widgets. La actualización reactiva
viaja desde `ChangeNotifier` hacia sus oyentes, aunque una flecha UI → Provider
represente la dependencia de lectura. «vistas» es un callback local, no HTTP.

## Relación con CLEAN

Screens, Widgets y Providers están en presentación. `VideoPost` pertenece al
dominio y no importa Flutter. Provider es el mecanismo de estado de presentación,
no una capa del dominio. Las listas en memoria son objetos de estado, no un
DataSource ni persistencia durable. La arquitectura completa también tiene
contratos de repositorio e implementaciones de infraestructura; se explicarán
en otra entrega. Este documento no certifica un aislamiento perfecto: por ejemplo,
`PlaybackCoordinator` usa directamente `VideoPlayerController` del plugin.

## Fuentes y trazabilidad

Se inspeccionaron el árbol de trabajo actual y los archivos de composición,
Screens, Widgets, Providers y entidades. Archify verifica las referencias de
`candidate.json` contra el commit `4fb62ef0213a6053c3ef88ebb1c1b2b1d5b9bc81`.
Las responsabilidades representadas se contrastaron también con el árbol actual.
Los cambios sin commit en la aplicación no se presentan como contenido del SHA:
por ejemplo, las mejoras recientes de audio no forman parte de las fuentes
verificadas del gráfico. Cada nodo permite consultar sus archivos de origen.

Las prácticas 02 y 03 sólo contienen plantillas Flutter de `web/index.html`, con
`$FLUTTER_BASE_HREF` y bootstrap de la app; no hay un tema documental compartido
ni índice general de prácticas que reutilizar. Se conserva el estilo clásico de
los diagramas Archify que ya existen en TokTik. No se cambió otra práctica ni se
tocaron las carpetas `architecture/initial` y `architecture/final`.

## Generación real con Archify

Desde `Practica04/toktik`, usando la instalación de la skill Archify:

```powershell
python architecture/provider-local/build_spec.py
node C:/Users/otero/.agents/skills/archify/bin/archify.mjs finalize architecture architecture/provider-local/candidate.json architecture/provider-local/index.html --repo-root ../.. --quality showcase --json
node C:/Users/otero/.agents/skills/archify/bin/archify.mjs visual-check architecture/provider-local/index.html --out-dir architecture/provider-local/visual-check --summary --require-provenance
node architecture/provider-local/verify-browser.mjs
python architecture/provider-local/verify-links.py
```

La ruta de la instalación de Archify es propia de esta máquina; los archivos
publicados no la usan. `build_spec.py` sólo recompone la especificación;
**Archify genera el HTML y su SVG integrado**. El último script abre ese HTML en
Chrome sin interfaz, pulsa la exportación canónica **Exportar → SVG Auto** de
Archify y guarda el resultado en `provider-local.svg`; no dibuja un SVG alternativo.

La primera validación detectó un lienzo demasiado ancho para texto legible.
Se compactó la distribución y se repitió `finalize`, que pasó `validate`,
`deliver`, `check` y `browser-check` sin diagnósticos. Los recibos se conservan
junto al HTML. `visual-check/` contiene capturas claras/oscuras y su contact sheet.
`responsive-export-check.json` vincula el HTML y el SVG por SHA-256 y registra
la comprobación adicional de móvil/tablet/escritorio, sin desbordamiento horizontal
ni errores JavaScript. En móvil se conserva la vista general, con controles de
zoom para explorar el detalle; la explicación aparece en tarjetas apiladas.

La revisión visual inspeccionó las capturas de 1440 × 900 en claro, 2048 × 1320
en oscuro y 390 × 844 en móvil. No se observaron cajas ni etiquetas superpuestas.
El SVG independiente también se abrió en Chrome: 33 textos y ningún error XML.
Se comprobaron 18 enlaces relativos sin destinos ausentes. Los detalles y hashes
están en [el informe de exportación y tamaños](responsive-export-check.json) y
[el informe de rutas y revisión visual](pages-links-review.json).

## GitHub Pages: main / raíz

Configuración informada por el usuario: rama **main**, carpeta **/(root)**.
No se pudo consultar remotamente Settings → Pages porque `gh` no tiene sesión
autenticada. Esta preparación no modifica los ajustes de GitHub.

URL pública esperada cuando estos archivos estén en `main`:

<https://ktmich2095.github.io/Practicas_DMI_230881/Practica04/toktik/architecture/provider-local/>

SVG esperado:

<https://ktmich2095.github.io/Practicas_DMI_230881/Practica04/toktik/architecture/provider-local/provider-local.svg>

El HTML lleva CSS, JavaScript, fuentes y SVG integrados, sin CDN, servidor local,
Flutter bootstrap ni rutas absolutas de recursos. Se agregó `.nojekyll` en la
raíz de publicación. Los enlaces de navegación y descarga son relativos y se
mantienen al servir el repositorio bajo `/Practicas_DMI_230881/`.

No existe un `index.html` raíz para navegar entre prácticas; por ello no se
modificó un índice inexistente. El README de TokTik y el índice Markdown de
arquitectura enlazan esta entrega. La rama local es `Practica04`; los archivos
deberán incorporarse a `main` por el usuario antes de que Pages pueda servirlos.
No se realizaron commits, merges, pushes ni despliegues.
