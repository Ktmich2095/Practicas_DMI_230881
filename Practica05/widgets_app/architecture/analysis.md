# Widgets App — arquitectura real

Inspección completa de los 19 archivos Dart de `lib/` y de `pubspec.yaml`, el 27 de octubre de 2026. El diagrama describe **el árbol de trabajo actual**, que contiene archivos modificados y sin seguimiento. No se atribuyen esos cambios al commit HEAD. `working-tree-evidence.json` registra rutas, símbolos, líneas y hashes de los archivos inspeccionados; `source-evidence.json` relaciona los nodos con sus archivos. `candidate.json` conserva la topología reproducible de Archify. Las referencias se mantienen fuera del campo `sources` del candidato porque Archify exige para ese campo evidencia de un commit, que no contiene esta implementación actual.

## Inicio y navegación

`main()` crea `ProviderScope → MainApp`, un `ConsumerWidget`. `MainApp` observa `themeNotifierProvider`, obtiene `AppTheme.getTheme()` y configura `MaterialApp.router` con `appRouter`.

`config/router/app_router.dart` contiene 11 `GoRoute` sin ShellRoute, rutas anidadas, guardas o redirecciones. Inicio en `/`. `screens.dart` reexporta las pantallas; no es un controlador ni un servicio.

| Ruta | Pantalla | Implementación |
|---|---|---|
| `/` | HomeScreen | Scaffold, `_HomeView`, ListView.builder y `_CustomListTile`; integra SideMenu |
| `/buttons` | ButtonsScreen | `_ButtonsView`, variantes de botones Material y CustomButton; retorno con context.pop |
| `/cards` | CardsScreen | `_CardsView`, lista constante cards y `_CardType1` a `_CardType4`; la cuarta variante obtiene fotos remotas |
| `/progress` | ProgressScreen | `_ProgressView`, `_ControlledProgresIndicator`, Stream.periodic y StreamBuilder; indicadores circular y lineal |
| `/snackbars` | SnackbarScreen | ScaffoldMessenger, SnackBar, showDialog y showAboutDialog; botones de diálogo usan context.pop |
| `/animated` | AnimatedScreen | Estado local de tamaño, color y radio; Random, setState y AnimatedContainer |
| `/ui-controls` | UiControlsScreen | `_UiControlsView`, enum Transportation, SwitchListTile, RadioListTile, CheckboxListTile y ExpansionTile; setState |
| `/tutorial` | AppTutorialScreen | SlideInfo, slides y `_Slide`; PageView y PageController; endReached con setState; FadeInRight y context.pop |
| `/infinite` | InfiniteScrollScreen | Lista imagesIds, ScrollController, isLoading, RefreshIndicator; Future.delayed simula carga; FadeIn, SpinPerfect y context.pop |
| `/counter-river` | CounterScreen | ConsumerWidget; observa e incrementa counterProvider, observa y alterna isDarkmodeProvider |
| `/theme-changer` | ThemeChangerScreen | ConsumerWidget y `_ThemeChangerView`; observa colorListProvider y themeNotifierProvider, alterna modo y selecciona color |

`config/menu/menu_items.dart` define `MenuItem` y diez `appMenuItems`. HomeScreen y SideMenu leen la misma lista y ejecutan `context.push(menuItem.link)`. SideMenu mantiene `navDrawerIndex` con setState, divide los destinos en dos grupos y cierra el drawer mediante la GlobalKey que recibe de HomeScreen. Las flechas de `appRouter` hacia grupos de pantallas significan construcción por sus builders, no llamadas entre esas pantallas. Los grupos del gráfico son agrupaciones de lectura, no clases adicionales.

## Composición y estado

- **Compartido:** SideMenu está en `presentation/widgets`. CustomButton es público, pero se declara y utiliza en la pantalla de botones: `ClipRRect → Material → InkWell`. No se observa reutilización de CustomButton fuera de esa pantalla. Las vistas y cuatro variantes privadas de tarjetas son composición interna.
- **Riverpod:** counterProvider es `StateProvider<int>` con valor inicial 5. themeNotifierProvider es `StateNotifierProvider<ThemeNotifier, AppTheme>`. ThemeNotifier cambia su estado con copyWith. colorListProvider expone nueve colores.
- **Dos estados de modo diferentes:** CounterScreen modifica isDarkmodeProvider, pero MainApp observa themeNotifierProvider. Por tanto, el botón del contador no cambia el tema global. ThemeChangerScreen sí modifica el estado que observa MainApp. selectedColorProvider está declarado pero sus consumidores aparecen comentados.
- **Estado local:** AnimatedScreen, `_UiControlsView`, AppTutorialScreen, InfiniteScrollScreen y SideMenu emplean StatefulWidget/setState. Los controladores de página y scroll se liberan en dispose.
- **Progreso:** Stream.periodic produce `(value * 2) / 100`; el filtro implementado es `value < 100`, no `value <= 1`. Se documenta lo observado sin corregir el código.
- **Datos e imágenes:** CardsScreen e InfiniteScrollScreen solicitan imágenes HTTPS a picsum.photos. La paginación solo añade identificadores en memoria tras una demora. No existe backend propio, capa repository, base de datos ni persistencia local en `lib/`.

## Dependencias y recursos de Flutter

`pubspec.yaml` establece Dart `^3.9.2`, Flutter SDK, `cupertino_icons: ^1.0.8` y `go_router: ^17.2.3`; para desarrollo, flutter_test SDK y flutter_lints `^5.0.0`. Material Icons está activado. No se observa uso de CupertinoIcons en `lib/`.

El código importa **flutter_riverpod** y **animate_do**, pero no los declara en el manifiesto actual. También referencia `assets/images/1.png`, `2.png`, `3.png` y `jar-loading.gif`, ausentes en esta copia y sin registro activo de assets en pubspec.yaml. Estas diferencias afectan a Flutter; el diagrama HTML no necesita esos paquetes ni imágenes. No se ha modificado código funcional para resolverlas.

## Menú y publicación

El índice raíz no estaba en el árbol de trabajo de la rama Practica05. Se recuperó su contenido de la rama local `main` mediante lectura de Git, sin checkout, merge o commit. Se añadió la tarjeta Práctica 05 después de TokTik y se amplió una frase introductoria. CSS, encabezado, datos personales, pie, tarjetas anteriores y todos sus href se conservaron.

Enlace relativo desde la raíz: `Practica05/widgets_app/architecture/index.html`. El HTML de Archify es autónomo: incluye estilos, JavaScript e iconos. `architecture.svg` procede del exportador canónico, sin controles ni estado temporal. No se requieren CDN, fuentes externas, servidor de Flutter o compilación para verlo en GitHub Pages.

Las arquitecturas anteriores y `Practica04/toktik/videos.html` referenciados por el menú de main no están presentes en esta rama. Sus enlaces se conservaron; `site-check.json` enumera los destinos ausentes. Deben estar disponibles en la rama publicada para que funcione el menú completo. No se restauran archivos de otras prácticas porque quedan fuera de esta tarea.

## Validación

`review-3/index.finalize-summary.json` contiene la validación final de Archify: validate, deliver, check y browser-check. Los recibos anteriores corresponden a versiones previas y no sustituyen al recibo final.

`responsive-export-check.json` verifica el diagrama y las cuatro tarjetas a 390, 768 y 1440 px, el cambio de estado de cámara al acercar y recentrar, la exportación SVG canónica y la navegación HTTP usando el prefijo `/Practicas_DMI_230881/`. Las capturas `diagram-*.png` y `menu-*.png` permiten revisión visual. `site-check.json` comprueba rutas locales, conservación de enlaces, recursos externos de ejecución y exclusiones por gitignore. No valida la disponibilidad remota de los servicios de GitHub o Appetize ni la configuración de Pages de la cuenta.

Repetición desde widgets_app: `node architecture/verify-browser.mjs` (requiere la skill instalada y Chrome) y `python architecture/verify-site.py`. `build_candidate.py` regenera el candidato; la skill debe ejecutar finalize después para actualizar el HTML y sus recibos. Ningún script auxiliar es necesario para abrir el diagrama publicado.
