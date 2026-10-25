# Demostración de Widgets App en Appetize

**[Probar Widgets App en Appetize](https://appetize.io/app/b_pa45jpzvescit46pg4b3kq6dvy).** Enlace proporcionado por la usuaria y comprobado con HTTP 200. [Registro de comprobación](evidence/delivery-20261109/appetize-link.json).

## Archivo a subir

**APK generado y verificado:** `build/app/outputs/flutter-apk/app-release.apk`, **48,686,330 bytes (46.43 MiB)**. Incluye `arm64-v8a`, `armeabi-v7a` y `x86_64`. Firma APK v2 verificada. Requiere Android 7.0/API 24 o posterior (minSdk 24; targetSdk 36), comprobado con aapt. Para Appetize, seleccionar un dispositivo con Android API 24 o superior; este APK incluye la biblioteca x86_64.

SHA-256: `a8e48cd46c6d82991315218dd25d994dcaf147935e78972534ce2e1771970191`.

El APK está dentro de `Practica05/widgets_app`. Su existencia, tamaño, SHA-256 y ABI están registrados en [apk-release.json](evidence/delivery-20261109/apk-release.json). Ver también el [resultado de compilación](evidence/delivery-20261109/build-outcome.json), la [firma verificada](evidence/delivery-20261109/apk-signature.txt) y los [datos Android del paquete](evidence/delivery-20261109/apk-badging.txt). No usar el manifiesto de un APK histórico como comprobante de un binario actual.

El directorio build/ está excluido de Git. El APK se entrega desde el equipo local; no aparecerá en GitHub al publicar los archivos fuente. La configuración existente firma la variante release con la clave de depuración para la demostración académica; no es una firma de producción para Play Store.

## Para actualizar el APK o verificar la demostración

1. Confirmar que la compilación terminó correctamente y localizar `Practica05/widgets_app/build/app/outputs/flutter-apk/app-release.apk`. Si falta, resolver primero el bloqueo descrito en build-outcome.json y repetir `flutter build apk --release`.
2. Entrar en [Appetize](https://appetize.io/) e iniciar sesión en tu cuenta. No es necesario compartir la contraseña ni tokens con el repositorio.
3. Abrir la opción de cargar una aplicación nueva en el panel de Appetize y seleccionar el archivo APK anterior. Elegir Android y esperar a que finalice el procesamiento.
4. Seleccionar un dispositivo Android compatible con las ABI del APK. Si incluye x86_64, comprobarlo en el entorno Android x86_64 disponible en Appetize. No afirmar compatibilidad solo por haber aceptado la carga: iniciar una sesión y verificar el arranque.
5. Recorrer inicio, contador, botones, tarjetas, progreso, diálogos, animaciones, controles, tutorial, lista infinita y temas. Probar incrementar/disminuir/reiniciar, claro/oscuro y colores, anterior/siguiente/finalizar, carga al final y Pull to Refresh. Confirmar las imágenes descargadas por HTTPS.
6. El enlace actual ya está añadido al catálogo y a los README. Si Appetize genera otro enlace al crear una aplicación nueva, actualizarlo en esos lugares. Registrar la fecha y el resultado de la prueba de funcionamiento.
7. Guardar capturas de esa sesión diferenciándolas de las 19 capturas web existentes. No reemplazar las evidencias anteriores.

Appetize admite APK/APKS; si se dispone de AAB, convertirlo con bundletool antes de cargarlo. Este proyecto solicita generar directamente APK. [Documentación oficial de Android en Appetize](https://docs.appetize.io/platform/app-management/uploading-apps/android).
