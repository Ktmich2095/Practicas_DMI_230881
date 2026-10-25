# Validación real

Entorno: Flutter 3.47.2, Dart 3.13.2, Windows, comprobado el 30 de octubre de 2026. Solo se intervino Practica05/widgets_app.

| Comprobación | Resultado |
|---|---|
| flutter pub get | Aprobado: dependencias resueltas; Riverpod 2.6.1, GoRouter 17.5.0, animate_do 4.2.0 |
| dart format lib test | Aprobado: 21 archivos, 0 cambios en la pasada final |
| flutter analyze | Aprobado: No issues found |
| flutter test | Aprobado: 10 pruebas |
| flutter build apk --debug | Primer intento falló con Java 25/Gradle 8.14; multi-ABI pendiente; APK x86_64 aprobado con --target-platform android-x64 |
| Archify doctor y demo | Aprobados |
| Archify general/específica | validate, deliver, check y browser-check aprobados |
| Capturas de diagramas | visual-check aprobado; capturas claras/oscuras a 1440×900 y 2048×1320 |
| Revisión visual de diagramas | Inspeccionadas capturas claras/oscuras de ambos a 1440×900; sin cruces en la composición final |
| Ejecución en emulador x86_64 | APK instalado y abierto; cinco comprobaciones ADB y seis capturas reales |
| GitHub Pages / Appetize | Pendientes de publicación |

## Cobertura ejecutada

1. Inicio, context.push/pop e incremento del contador de 5 a 6.
2. Navegación desde NavigationDrawer, acción de botón y variante deshabilitada.
3. Selección de color, tema real de MaterialApp, alternancia desde contador y conservación del color.
4. Apertura y regreso de las diez rutas del menú, con comprobación de la pantalla construida.
5. Progreso determinado que termina en 1.0 después de 50 eventos, sin valores fuera de rango.
6. Tutorial con assets reales a 320×640: siguiente y comenzar.
7. Cambios de switch, radio de la enumeración y checkbox.
8. Imagen fallida y acción de reintento sin excepción sin manejar.
9. Paginación que agrega cinco IDs, refresco que sustituye la colección y desmontaje.
10. AlertDialog, AboutDialog y SnackBar.

Las pruebas de widgets sustituyen HTTP por respuestas 400, como hace flutter_test por defecto. Verifican la recuperación de errores; no prueban disponibilidad real de picsum.photos. La carga de catálogo es una simulación asíncrona y las fotos remotas son solicitudes reales en la aplicación.

## Evidencias

- dart-format.txt, flutter-analyze.txt y flutter-test.txt en evidence/.
- flutter-build-apk.txt registra el intento con NDK predeterminado; flutter-build-apk-ndk27.txt registra el último intento con el NDK instalado.
- archify-general-final/ y archify-specific-final/ contienen recibos vigentes y capturas de diagramas. Los recibos de pasadas anteriores son históricos y sus hashes no validan los HTML actuales.
- source-manifest.json contiene hashes de fuentes y assets del árbol local. No atribuye cambios sin commit a la revisión base.

El primer build usó el JDK 25 incluido con Android Studio y falló por incompatibilidad con Gradle 8.14. Se encontró JDK 21 instalado y se seleccionó para el daemon mediante GRADLE_OPTS, solo en el proceso. Un intento quedó detenido descargando por HTTPS; se interrumpieron únicamente sus procesos y se reintentó con acceso de red fuera del sandbox y límites de conexión. No se cambiaron versiones de Flutter, Gradle, AGP ni Kotlin, ni configuraciones globales.

Doctor informó algunas licencias Android pendientes y desajuste de versiones XML entre herramientas de SDK. No se aceptaron licencias automáticamente. El APK efectivamente generado es x86_64; no se presenta como un APK universal ARM.

El reintento con JDK 21 superó la configuración Gradle, pero Flutter lanzó sdkmanager para instalar NDK 28.2.13676358. Se detuvo esa instalación automática por la restricción del usuario contra herramientas globales sin autorización. Se seleccionó NDK 27.0.12077973, ya instalado, únicamente en android/app/build.gradle.kts; el nuevo build no necesita instalar NDK 28.

## Resultado Android final

El intento multi-ABI con NDK 27 se interrumpió después de quedar esperando una descarga HTTPS. El diagnóstico `gradlew.bat --offline assembleDebug`, ejecutado con JAVA_HOME apuntando a JDK 21, llegó a las tareas Android y falló por un único motor ausente de caché: `io.flutter:arm64_v8a_debug:1.0.0-a804b261645ef8c13eb3d5c44a5c2fb0340c5539`. El nombre de la tarea checkDebugDuplicateClasses no implica clases duplicadas: su causa reportada fue el JAR faltante. Ver evidence/gradle-offline.txt.

La compilación `flutter build apk --debug --target-platform android-x64` **terminó correctamente en 64 segundos**. El APK está en build/app/outputs/flutter-apk/app-debug.apk. Se verificó el ZIP: contiene únicamente ABI x86_64. Su SHA-256 y tamaño están en evidence/apk.json. El build multi-ABI queda pendiente de acceso completo a los artefactos ARM64.

Se instaló el APK con ADB en emulator-5554, se abrió MainActivity y se ejecutó evidence/emulator-smoke.py. Su ejecución final aprobó cinco comprobaciones; ver emulator-smoke.json. Se tomaron e inspeccionaron seis capturas: app-home.png, app-counter.png, app-theme-dark.png, app-tutorial.png, app-gallery.png y app-drawer.png. La galería estaba cargando; no se afirma disponibilidad real de las fotos.

Flutter aún identifica su Java global como 25 y puede imprimir ese diagnóstico genérico al interrumpir un build; el daemon utilizado con GRADLE_OPTS fue Java 21 y el build x86_64 confirma que no fue necesario migrar Gradle. Las advertencias de versiones futuras de Gradle/AGP/Kotlin no impidieron este APK.
