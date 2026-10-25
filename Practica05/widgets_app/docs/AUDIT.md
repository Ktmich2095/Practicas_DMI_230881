# Auditoría inicial

Alcance exclusivo: Practica05/widgets_app. El estado inicial de Git estaba limpio; no se crearon proyectos ni se cambiaron ramas.

Ya existían once pantallas, menú centralizado, GoRouter, MaterialApp.router, Material 3, módulos config y presentation/{screens,providers,widgets}, contador StateProvider, ThemeNotifier con StateNotifierProvider y tutorial animate_do.

Problemas encontrados:

- Assets inexistentes y sin declaración en pubspec.
- Acciones de botones y tarjetas vacías.
- El contador alternaba un provider de brillo que MainApp no observaba.
- El progreso comparaba con 100 aunque el rango esperado es 0–1.
- Carga de páginas y refresco podían modificar la misma lista simultáneamente; existían mutaciones después de esperar sin comprobar montaje primero.
- Imágenes sin error/reintento y permiso INTERNET ausente del manifiesto principal.
- Texto de relleno y composición rígida en tutorial; drawer con overflow en pruebas.
- APIs obsoletas de radios y colores para el Flutter instalado.
- Una sola prueba de contador y README de plantilla.

Flutter 3.47.2 y Dart 3.13.2 satisfacen SDK ^3.9.2. Pub resolvió Riverpod 2.6.1, GoRouter 17.5.0 y animate_do 4.2.0. No fue necesario cambiar Flutter, Riverpod ni Gradle.

Android usa Gradle 8.14. Flutter elige JDK 25 de Android Studio; el primer build falló por incompatibilidad. Se encontró JDK 21 instalado y se reintentó mediante una opción del proceso para el daemon. Doctor también informó licencias Android pendientes. Ver VALIDATION.md.

Archify estaba instalado como habilidad local. Se leyó SKILL.md y se ejecutaron doctor y demo antes de los diagramas.

La validación detectó además que el NDK predeterminado de Flutter (28.2) no estaba instalado. Se seleccionó el NDK 27 existente en la configuración Android del proyecto para evitar instalar herramientas globales.
