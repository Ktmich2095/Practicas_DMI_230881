# Widgets App · Práctica 05

Aplicación académica de Desarrollo Móvil Integral para explorar componentes de Material Design 3, navegación declarativa con GoRouter y estado reactivo con Riverpod. Se conserva y completa el proyecto existente en la rama `Practica05`.

Objetivo: demostrar widgets visuales e interactivos en once pantallas con temas personalizables, tutorial y galería con carga progresiva.

## Arquitectura y estructura

```text
lib/
  main.dart                      ProviderScope y MaterialApp.router
  config/
    menu/menu_items.dart         Catálogo compartido por inicio y drawer
    router/app_router.dart       Rutas y recuperación de ruta desconocida
    theme/app_theme.dart         Material 3, colores y brillo
  presentation/
    screens/                     Once pantallas por funcionalidad
    providers/                   counterProvider y ThemeNotifier
    widgets/                     SideMenu y RemoteImage
assets/images/                   Tres PNG del tutorial y GIF de carga
integration_test/                Prueba de imágenes por HTTPS real
test/widget_test.dart            Pruebas automatizadas
docs/                            Portal estático, diagramas y evidencias
.archify/                        Candidatos JSON editables
```

Se conserva `presentation/` como contenedor de screens, providers y widgets. GoRouter construye las pantallas; los providers administran contador y tema, y MainApp observa el tema. Las pantallas de tarjetas y galería comparten RemoteImage con carga, error y reintento. No existe backend; la paginación simula latencia y las fotos usan HTTPS real.

## Instalación y ejecución

Clonar el [repositorio GitHub](https://github.com/Ktmich2095/Practicas_DMI_230881.git), seleccionar la rama `Practica05` y entrar en `Practica05/widgets_app`:

```powershell
flutter pub get
flutter run
flutter analyze
flutter test
flutter build web --no-wasm-dry-run
flutter build apk --debug
```

## Pantallas implementadas

| Ruta | Pantalla y demostración |
|---|---|
| / | HomeScreen: catálogo y menú lateral agrupado |
| /counter-river | CounterScreen: incrementar, disminuir y reiniciar al valor inicial 5 |
| /buttons | ButtonsScreen: variantes Material, deshabilitados y botón personalizado |
| /cards | CardsScreen: elevaciones, contornos, colores y fotos remotas |
| /progress | ProgressScreen: indicadores determinados e indeterminados con Stream |
| /snackbars | SnackbarScreen: notificaciones, confirmación y licencias |
| /animated | AnimatedScreen: formas, colores y bordes aleatorios |
| /ui-controls | UiControlsScreen: switch, radios, checkboxes y expansión |
| /tutorial | AppTutorialScreen: imágenes locales, anterior, siguiente, comenzar y salir |
| /infinite | InfiniteScrollScreen: paginación, refresco y regreso al inicio |
| /theme-changer | ThemeChangerScreen: nueve colores y modo claro/oscuro |

El inicio y el drawer usan `context.push`; el tutorial utiliza `context.pop` cuando hay una ruta anterior y vuelve al inicio en acceso directo. Las fotos se agregan de cinco en cinco, con bloqueo de cargas duplicadas, descarte de respuestas anteriores tras refrescar y protección al desmontar el widget.



### Capturas

| Pantalla | Pantalla | Pantalla |
|---|---|---|
| **Inicio**<br><img src="docs/evidence/screenshots/01-inicio.png" width="240" alt="Captura real: Inicio"> | **Contador Riverpod**<br><img src="docs/evidence/screenshots/02-contador.png" width="240" alt="Captura real: Contador Riverpod"> | **Botones**<br><img src="docs/evidence/screenshots/03-botones.png" width="240" alt="Captura real: Botones"> |
| **Tarjetas**<br><img src="docs/evidence/screenshots/04-tarjetas.png" width="240" alt="Captura real: Tarjetas"> | **Tarjetas con imágenes**<br><img src="docs/evidence/screenshots/04-tarjetas-imagenes.png" width="240" alt="Captura real: Tarjetas con imágenes"> | **Progreso**<br><img src="docs/evidence/screenshots/05-progreso.png" width="240" alt="Captura real: Progreso"> |
| **Notificaciones y diálogos**<br><img src="docs/evidence/screenshots/06-dialogos.png" width="240" alt="Captura real: Notificaciones y diálogos"> | **Confirmación**<br><img src="docs/evidence/screenshots/06-confirmacion.png" width="240" alt="Captura real: Confirmación"> | **Acerca de**<br><img src="docs/evidence/screenshots/06-acerca-de.png" width="240" alt="Captura real: Acerca de"> |
| **SnackBar**<br><img src="docs/evidence/screenshots/06-snackbar.png" width="240" alt="Captura real: SnackBar"> | **Animaciones**<br><img src="docs/evidence/screenshots/07-animaciones.png" width="240" alt="Captura real: Animaciones"> | **Controles interactivos**<br><img src="docs/evidence/screenshots/08-controles.png" width="240" alt="Captura real: Controles interactivos"> |
| **Tutorial · inicio**<br><img src="docs/evidence/screenshots/09-tutorial.png" width="240" alt="Captura real: Tutorial · inicio"> | **Tutorial · paso 2**<br><img src="docs/evidence/screenshots/09-tutorial-paso-2.png" width="240" alt="Captura real: Tutorial · paso 2"> | **Tutorial · finalizar**<br><img src="docs/evidence/screenshots/09-tutorial-final.png" width="240" alt="Captura real: Tutorial · finalizar"> |
| **Lista infinita y refresco**<br><img src="docs/evidence/screenshots/10-lista-infinita.png" width="240" alt="Captura real: Lista infinita y refresco"> | **Colores**<br><img src="docs/evidence/screenshots/11-temas.png" width="240" alt="Captura real: Colores"> | **Tema oscuro**<br><img src="docs/evidence/screenshots/12-tema-oscuro.png" width="240" alt="Captura real: Tema oscuro"> |
| **Menú lateral**<br><img src="docs/evidence/screenshots/13-menu-lateral.png" width="240" alt="Captura real: Menú lateral"> |  |  |



## Diagramas Archify

- [Portal listo para publicación](docs/index.html).
- [Diagrama general](docs/diagrams/general.html).
- [Diagrama específico](docs/diagrams/especifica.html).


### Vistas previas de Archify

[![Arquitectura general](docs/evidence/screenshots/archify-general/general.visual-check.1440x900.light.png)](docs/diagrams/general.html)

[![Pantallas y dependencias](docs/evidence/screenshots/archify-especifica/especifica.visual-check.1440x900.dark.png)](docs/diagrams/especifica.html)
