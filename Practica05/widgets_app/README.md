# Widgets App · Práctica 05

Aplicación de Desarrollo Móvil Integral para explorar Material Design 3, navegación declarativa, estado reactivo, animaciones y galerías con carga progresiva. Conserva el proyecto existente y sus once pantallas.

## Tecnologías verificadas

Flutter 3.47.2, Dart 3.13.2 (requisito SDK ^3.9.2), flutter_riverpod 2.6.1, go_router 17.5.0, animate_do 4.2.0 y flutter_lints 5.0.0. Versiones resueltas en pubspec.lock.

Riverpod permanece en 2.x: StateProvider, StateNotifierProvider y StateNotifier se importan desde flutter_riverpod.dart. No se sustituyeron las APIs académicas. Se conservan ConsumerWidget, ref.watch y ref.read. RadioListTile utiliza RadioGroup para evitar APIs obsoletas en el Flutter instalado.

## Estructura

```text
lib/
  main.dart                     ProviderScope y MaterialApp.router
  config/
    menu/menu_items.dart        Catálogo central del menú
    router/app_router.dart      Rutas y recuperación de rutas desconocidas
    theme/app_theme.dart        Material 3, ColorSchemeSeed y brillo
  presentation/
    screens/                    Once pantallas agrupadas por función
    providers/                  Contador y ThemeNotifier
    widgets/                    SideMenu y RemoteImage
assets/images/                  Tres PNG originales y GIF local animado
test/widget_test.dart           Pruebas funcionales y de widgets
docs/                           Portal estático, diagnóstico y evidencias
.archify/                       Candidatos reproducibles de diagramas
```

Se conserva presentation como contenedor de screens, providers y widgets. El estado es local y en memoria; se restablece al reiniciar. La paginación simula latencia de catálogo; la descarga de imágenes sí utiliza HTTPS real.

## Veinte requisitos de entrega

La solicitud enumera quince funciones. Para esta tabla se agregan cinco criterios transversales: arquitectura, calidad, validación, diagramas y documentación/publicación; no se supone una rúbrica externa.

| # | Requisito | Estado | Evidencia |
|---|---|---|---|
| 1 | Scaffold, AppBar, ListView.builder y ListTile | Completado | HomeScreen |
| 2 | NavigationDrawer funcional | Completado | SideMenu, catálogo compartido |
| 3 | Seis botones, iconos, deshabilitados y Material + InkWell | Completado | ButtonsScreen, acciones con SnackBar |
| 4 | Cards con elevación, borde, color e imágenes | Completado | CardsScreen, cuatro variantes |
| 5 | Progreso circular/lineal, determinado/indeterminado y Stream | Completado | Stream.periodic y StreamBuilder, rango 0–1 |
| 6 | SnackBar, ScaffoldMessenger y diálogos | Completado | SnackbarScreen, AlertDialog y AboutDialog |
| 7 | AnimatedContainer con azar y curvas | Completado | StatefulWidget y tamaño limitado al viewport |
| 8 | Switch, radio, checkbox y ExpansionTile | Completado | UiControlsScreen, enumeración y setState |
| 9 | Tutorial PageView, PageController, PNG y FadeInRight | Completado | Siguiente, salir y comenzar |
| 10 | Lista infinita, ScrollController, FadeInImage, NetworkImage y GIF | Completado | InfiniteScrollScreen y RemoteImage |
| 11 | RefreshIndicator con renovación real | Completado | Sustituye IDs y descarta cargas anteriores |
| 12 | Contador reactivo con APIs Riverpod solicitadas | Completado | counterProvider, valor inicial 5 |
| 13 | Tema claro/oscuro, colores y ThemeNotifier | Completado | StateNotifierProvider y RadioListTile |
| 14 | context.push y context.pop | Completado | Menú, drawer, botones y tutorial |
| 15 | Assets declarados | Completado | pubspec.yaml y assets/images/ |
| 16 | Arquitectura modular y configuración central | Completado | config/ y presentation/ |
| 17 | Calidad, carga/error/reintento y pruebas principales | Completado | RemoteImage, 10 pruebas y comprobación ADB en emulador |
| 18 | Validación y APK debug | Parcial | APK x86_64 generado y ejecutado; multi-ABI pendiente por descarga ARM64 |
| 19 | Dos diagramas interactivos Archify | Completado | HTML y recibos de validación/navegador |
| 20 | Documentación y publicación | Parcial | Preparada; Pages y Appetize sin publicar |

## Pantallas

| Ruta | Pantalla |
|---|---|
| / | HomeScreen |
| /counter-river | CounterScreen |
| /buttons | ButtonsScreen |
| /cards | CardsScreen |
| /progress | ProgressScreen |
| /snackbars | SnackbarScreen |
| /animated | AnimatedScreen |
| /ui-controls | UiControlsScreen |
| /tutorial | AppTutorialScreen |
| /infinite | InfiniteScrollScreen |
| /theme-changer | ThemeChangerScreen |

Tocar una opción del inicio o del drawer para navegar. Atrás regresa a la pantalla anterior. Las rutas desconocidas muestran una acción para volver al inicio. La galería carga cinco fotos al acercarse al final; arrastrar hacia abajo desde el inicio renueva las cinco fotos. Su botón flotante desplaza al principio. Las fotos fallidas permiten reintentar.

## Instalación, ejecución y validación

Desde Practica05/widgets_app, con Flutter y SDK Android configurados:

```powershell
flutter pub get
flutter run
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Se necesita conexión para dependencias y fotos. Las demás demostraciones y tutorial usan recursos locales. INTERNET está declarado en el manifiesto Android principal.

En este equipo Flutter selecciona Java 25 de Android Studio, incompatible con Gradle 8.14. Hay un JDK 21 instalado. Para seleccionar el JDK del daemon solo en la terminal actual, sin cambiar versiones ni configuración global:

```powershell
$env:GRADLE_OPTS='"-Dorg.gradle.java.home=C:/Program Files/Java/jdk-21.0.10"'
flutter build apk --debug
```

El proyecto fija NDK 27.0.12077973, ya instalado en este equipo y suficiente para sus dependencias Dart; así evita la instalación automática del NDK 28 solicitado por defecto por Flutter. No se cambiaron Flutter, Gradle, AGP ni Kotlin. Adaptar la ruta del JDK en otros equipos. Si aparecen licencias Android pendientes, el propietario debe revisarlas con flutter doctor --android-licenses. No se aceptaron licencias automáticamente. Se generó y ejecutó un APK debug x86_64 con `flutter build apk --debug --target-platform android-x64`. Está en `build/app/outputs/flutter-apk/app-debug.apk`; es para emuladores x86_64 y no sirve como APK universal para teléfonos ARM. El build predeterminado multi-ABI quedó bloqueado por la descarga del motor ARM64. Para repetirlo, usar JDK 21 como se indica arriba y completar la descarga. El hash, tamaño y ABI del APK están en [apk.json](docs/evidence/apk.json). No se versionan binarios de compilación.

## Diagramas y evidencias

- [Portal de documentación](docs/index.html).
- [Arquitectura general](docs/diagrams/general.html): SDK, paquetes, capas, estado y assets.
- [Arquitectura específica](docs/diagrams/especifica.html): rutas, grupos de pantallas, providers y widgets.
- [Auditoría inicial](docs/AUDIT.md) y [validación real](docs/VALIDATION.md).
- [Pruebas](docs/evidence/flutter-test.txt) y [análisis estático](docs/evidence/flutter-analyze.txt).

Los HTML son independientes; abrirlos localmente o mediante Pages. GitHub muestra su código, por lo que se deben descargar para interactuar antes de publicar. Incluyen controles de tema y exploración del visor Archify.

Archify 3.2.0 pasó doctor y generación de demo. Ambos diagramas pasaron validate, deliver, check y browser-check. Candidatos: .archify/architecture-*-20261030/candidate.json. Recibos vigentes: docs/evidence/archify-general-final/ y docs/evidence/archify-specific-final/.

Describen el árbol local inspeccionado sin commit. No se atribuyen cambios locales a HEAD: se documentan fuentes en tarjetas y SHA-256 en docs/evidence/source-manifest.json. Las pantallas se agrupan por responsabilidad y las tarjetas enumeran las once rutas. No existe backend ni persistencia.

Se generaron e inspeccionaron capturas reales de los diagramas en claro/oscuro a 1440×900; sus recibos incluyen otras a 2048×1320.

También se instaló y abrió el APK en emulator-5554 (Android 17, x86_64). La comprobación ADB verificó contador 5→6, navegación, color/tema oscuro y salida del tutorial. Se inspeccionaron estas capturas reales:

| Evidencia | Captura |
|---|---|
| Inicio claro | [Inicio](docs/evidence/app-home.png) |
| Contador en 6 | [Contador](docs/evidence/app-counter.png) |
| Color 2 y tema oscuro | [Tema](docs/evidence/app-theme-dark.png) |
| Tutorial y asset original | [Tutorial](docs/evidence/app-tutorial.png) |
| Galería en carga | [Galería](docs/evidence/app-gallery.png) |
| Drawer oscuro | [Drawer](docs/evidence/app-drawer.png) |

[Registro de comprobación ADB](docs/evidence/emulator-smoke.json). Las fotos no terminaron de descargar durante la captura de la galería; la evidencia muestra el GIF de carga, no una descarga exitosa. El manejo de error y reintento está cubierto por flutter_test con HTTP simulado. Los PNG del tutorial son assets originales, no capturas.


## Publicar en GitHub Pages

No se publicó ni se configuró un workflow en la raíz del repositorio, porque el alcance es solo esta práctica.

1. Revisar y publicar posteriormente los archivos mediante el procedimiento del propietario.
2. En Settings → Pages, elegir GitHub Actions para publicar esta subcarpeta. El modo de rama solo admite raíz o /docs de la raíz del repositorio, no esta carpeta anidada.
3. Preparar posteriormente un workflow en la raíz que haga checkout, configure Pages, cargue Practica05/widgets_app/docs con actions/upload-pages-artifact y despliegue con actions/deploy-pages. Permisos pages: write e id-token: write, entorno github-pages. Verificar versiones vigentes de las acciones al implementarlo.
4. Confirmar el despliegue en Actions y abrir la URL que GitHub entregue. Probar diagrams/general.html y diagrams/especifica.html.

Este portal no publica automáticamente Flutter web. No hay URL pública confirmada. [Documentación oficial de Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).

## Generar APK y publicar en Appetize

1. Para repetir el APK validado, usar `flutter build apk --debug --target-platform android-x64` con JDK 21. Para un APK multi-ABI, completar primero la descarga ARM64 y ejecutar `flutter build apk --debug`. El APK x86_64 ya fue probado en el emulador local; confirmar que el entorno Android seleccionado en Appetize sea compatible con esa ABI.
2. Entrar a la cuenta Appetize y abrir la opción de carga de aplicaciones.
3. Subir build/app/outputs/flutter-apk/app-debug.apk, seleccionar Android y esperar procesamiento. Appetize admite APK; no sustituirlo por AAB.
4. Iniciar una sesión y comprobar navegación, tutorial, tema e imágenes remotas.
5. Copiar el enlace realmente generado y añadirlo aquí junto con capturas y fecha de comprobación.

No se cargó la aplicación ni hay enlace Appetize confirmado. No incluir tokens o credenciales en el repositorio. [Documentación oficial Android de Appetize](https://docs.appetize.io/platform/app-management/uploading-apps/android).

Inventario completo: [archivos creados y modificados](docs/CHANGES.md).
