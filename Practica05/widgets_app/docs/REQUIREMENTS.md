# Matriz de requisitos de Práctica 05

| Nº | Requisito | Estado | Archivo(s) | Evidencia |
|---|---|---|---|---|
| 01 | Configuración inicial | COMPLETO | pubspec.yaml, pubspec.lock, assets/images/ | pub get aprobado; Flutter 3.35.6 y Dart 3.9.2 compatibles |
| 02 | Arquitectura modular | COMPLETO | lib/config/, lib/presentation/{screens,providers,widgets}/ | Estructura conservada e inspeccionada |
| 03 | Material Design 3 | COMPLETO | config/theme/app_theme.dart | AppTheme, ColorScheme, claro/oscuro y prueba del tema global |
| 04 | GoRouter | COMPLETO | config/router/app_router.dart, main.dart | Pruebas de todas las rutas y push/pop |
| 05 | Pantalla principal | COMPLETO | screens/home/home_screen.dart | Scaffold, AppBar, ListView.builder y ListTile; captura 01 |
| 06 | Menú lateral | COMPLETO | widgets/side_menu.dart, config/menu/menu_items.dart | Catálogo central, NavigationDrawer agrupado y prueba de navegación; captura 13 |
| 07 | Botones | COMPLETO | screens/buttons/buttons_screen.dart | Variantes Material, deshabilitados, Material/InkWell; prueba de acción; captura 03 |
| 08 | Tarjetas | COMPLETO | screens/cards/cards_screen.dart, widgets/remote_image.dart | Elevaciones, borde, color y fotos HTTPS visibles en captura 04-tarjetas-imagenes |
| 09 | Indicadores de progreso | COMPLETO | screens/progress/progress_screen.dart | Stream.periodic y StreamBuilder; prueba que completa en 1.0 |
| 10 | Notificaciones y diálogos | COMPLETO | screens/snackbar/snackbar_screen.dart | SnackBar, AlertDialog, AboutDialog y pruebas de apertura/cierre |
| 11 | Animaciones | COMPLETO | screens/animated/animated_screen.dart | StatefulWidget, AnimatedContainer y azar; prueba a 480×320 |
| 12 | Controles interactivos | COMPLETO | screens/ui_controls/ui_controls_screen.dart | Switch, Radio, Checkbox, ExpansionTile, enum y setState; prueba interactiva |
| 13 | Tutorial introductorio | COMPLETO | screens/app_tutorial/app_tutorial_screen.dart, assets/images/ | PageView, PageController, PNG, FadeInRight, anterior/siguiente/finalizar; prueba a 320×640 |
| 14 | Lista infinita | COMPLETO | screens/infinite_scroll/infinite_scroll_screen.dart, widgets/remote_image.dart | ScrollController, paginación, FadeInImage, NetworkImage, GIF; prueba de desmontaje |
| 15 | Pull to Refresh | COMPLETO | screens/infinite_scroll/infinite_scroll_screen.dart | RefreshIndicator; pruebas de renovación de IDs y descarte de carga anterior |
| 16 | Contador con Riverpod | COMPLETO | providers/counter_provider.dart, screens/counter/counter_screen.dart | StateProvider, ConsumerWidget, watch/read; incrementar, disminuir y reiniciar a 5 probados |
| 17 | Tema dinámico con Riverpod | COMPLETO | providers/theme_provider.dart, screens/theme_changer/theme_changer_screen.dart | StateNotifierProvider, ThemeNotifier y RadioListTile; color/brillo global probados |
| 18 | Pruebas | PARCIAL | test/widget_test.dart, integration_test/remote_images_test.dart, docs/evidence/ | 12 pruebas automatizadas, análisis sin incidencias y compilación release aprobados |
| 19 | Arquitectura con Archify | COMPLETO | docs/diagrams/general.html, especifica.html y *.archify.json | Dos visores, zoom y fuentes JSON comprobados; URLs públicas HTTP 200 |
| 20 | Documentación y publicación | COMPLETO | README.md, docs/index.html, docs/APPETIZE.md | README académico y 19 capturas conservadas; Pages y enlace Appetize HTTP 200 |
