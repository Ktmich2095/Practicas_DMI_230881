# Inventario de la Práctica 04

## Archivos creados

- `lib/config/api/api_config.dart`: claves de compilación y límites HTTP.
- `lib/config/theme/season_style.dart`: paletas, iconos, fuentes, audios y animaciones.
- `lib/domain/entities/{video_source,video_batch,season,app_preferences}.dart`.
- `lib/domain/datasources/video_source_datasource.dart`.
- `lib/domain/repositories/{video_catalog,favorites,preferences,theme_audio}_repository.dart`.
- `lib/infrastructure/datasources/{coverr,pixabay,archive,local_assets}_datasource.dart` y `json_api_client.dart`.
- `lib/infrastructure/mappers/video_mapper.dart`.
- `lib/infrastructure/repositories/{fallback_video,preferences_favorites,shared_preferences,audioplayers_theme}_repository.dart`.
- `lib/infrastructure/storage/preferences_store.dart`.
- `lib/presentation/providers/{playback_coordinator,settings_provider,theme_audio_provider}.dart`.
- `lib/presentation/widgets/settings_sheet.dart` y `video/expandable_caption.dart`.
- `assets/videos/{aurora,atardecer,orbita}.mp4`, `assets/audio/{halloween,christmas,valentine}.wav`, `assets/LICENSE.md`.
- `architecture/initial/` y `architecture/final/`: HTML, especificaciones JSON y recibos de validación; `architecture/README.md`.
- Tests de fuentes, reproducción, temporadas/preferencias, selectores y descripciones; adaptador de almacenamiento en memoria para pruebas.
- Scripts de generación de recursos, consulta real de Archive y actualización limitada del README principal.
- `docs/live_archive_probe.json`, esta relación y `pubspec.lock`.
- `test/live_sources_test.dart`, `scripts/verify_authenticated_sources.py`, `scripts/run_with_api_keys.ps1` y `docs/live_authenticated_probe.json`: verificación autenticada opcional y ejecución sin archivos de credenciales.

## Archivos modificados

- `lib/main.dart`: composición, recuperación de preferencias y registro de dependencias.
- `lib/domain/entities/video_post.dart`: identidad estable, procedencia y metadatos.
- `lib/presentation/providers/discover_provider.dart`: carga, paginación, favoritos y estado de errores.
- `lib/presentation/screens/discover/discover_screen.dart`: secciones, estados y acceso a configuración.
- `lib/presentation/shared/{video_scrollable_view,video_buttons}.dart` y `widgets/video/fullscreen_player.dart`.
- `lib/config/theme/app_theme.dart` y formato de `lib/config/helpers/human_formats.dart`.
- `pubspec.yaml`, `.gitignore`, README de la práctica y prueba de widgets existente.
- `android/app/src/main/AndroidManifest.xml`: permiso de internet y etiqueta TokTik.
- `../../README.md`: únicamente una fila en la tabla existente.

## Implementaciones sustituidas

Se retiraron los contratos `video_posts_datasource.dart` y `video_posts_repository.dart`, el datasource local anterior, `local_video_model.dart`, la lista fija `local_video_posts.dart` y el widget de gradiente anterior. La composición activa usa los contratos, mappers, catálogo de assets y reproductor nuevos; no quedan stubs sin implementar ni una lista de respuestas simuladas en la aplicación.

No se modificaron las prácticas anteriores ni se crearon commits o pushes.

## Ampliación de identidad visual y temporadas

- Recursos originales en `assets/branding/`: cuatro SVG, logos PNG, marcas sin
  decoración y tablero; cuatro efectos `assets/audio/intro_*.wav`.
- `scripts/generate_branding.py`; Pillow sólo interviene en la regeneración.
- Configuración `BrandAssets` y calendario puro Dart `SeasonCalendar`.
- Widgets `TokTikLogo`/`SeasonIntro` y pantallas `StartupScreen`/`IntroPreviewScreen`.
- Providers `StartupProvider`, `SeasonIdentityProvider` e `IntroAudioProvider`;
  repositorios de dominio/infraestructura para ícono y sonido.
- Ajustes existentes: selector “Apariencia y temporadas”, vista previa y sonido
  persistente; coordinación con playback y audio temático.
- Android: puente en `MainActivity`, entrada real `LauncherActivity`, alias,
  `LauncherIcons`, receiver de actualización y recursos legacy/adaptativos.
- Splash nativo negro en estilos anteriores/posteriores a API 31.
- Helper exclusivo de debug y `prepare_android_launcher.ps1`, integrado con el
  lanzador de claves para conservar la ejecución desde Flutter.
- Tests `identity_test.dart`, `startup_preview_test.dart` e integración nativa
  `season_identity_test.dart`; dependencia de desarrollo `integration_test` del SDK.
- README: secuencias, recursos, arquitectura, calendario, sonidos, resultados
  ejecutados y límites reales del launcher/emulador.
