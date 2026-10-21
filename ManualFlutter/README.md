# Manual de instalación y configuración de Flutter

Esta carpeta contiene una guía paso a paso para preparar y validar en Windows un entorno de desarrollo Flutter para Android. El documento principal es [Manual_Flutter_.pdf](./Manual_Flutter_.pdf); este README resume su alcance y el orden recomendado para consultarlo.

## Objetivo

Instalar, configurar y comprobar las herramientas necesarias para ejecutar una aplicación Flutter existente en un emulador o dispositivo Android, preparar Docker según las necesidades reales del proyecto y publicar el trabajo en GitHub.

## Requisitos del equipo

| Nivel | Requisitos |
|---|---|
| Mínimos | CPU x64, 8 GB de RAM, 30 GB de espacio libre, virtualización habilitada y conexión a Internet. |
| Recomendados | Intel Core i5 / AMD Ryzen 5 o superior, 16 GB de RAM o más, SSD, al menos 50 GB libres y virtualización habilitada. |

Android Studio, el emulador y Docker pueden consumir recursos al mismo tiempo. En equipos con memoria limitada, conviene cerrar los servicios que no se estén utilizando.

## Herramientas incluidas

- **Windows 10/11** como sistema anfitrión.
- **WSL2 con Ubuntu 24.04 LTS**, como soporte Linux y backend de Docker cuando se necesite.
- **Visual Studio Code**, con las extensiones de Flutter y Dart.
- **JDK 21 LTS (Eclipse Temurin)** y **Apache Maven 3.9.x**.
- **Node.js LTS** y **npm**.
- **Android Studio**, Android SDK, SDK Tools y emulador Android.
- **Flutter Stable** y **Dart**.
- **Docker Desktop** y **Docker Compose**.
- **Git** y **GitHub** para control de versiones y publicación.

## Recorrido del manual

Se recomienda seguir las secciones del manual en PDF en este orden:

1. Comprobar Windows, arquitectura del sistema y virtualización.
2. Instalar y verificar WSL2 y Ubuntu 24.04 LTS.
3. Instalar Visual Studio Code y las extensiones necesarias.
4. Instalar JDK 21, Maven, Node.js y npm; verificar sus versiones y variables de entorno.
5. Instalar Android Studio, configurar Android SDK y crear un dispositivo virtual (AVD).
6. Instalar Flutter y Dart, configurar el `PATH` y revisar `flutter doctor`.
7. Validar la aplicación Flutter existente con `flutter pub get`, `flutter devices` y `flutter run`.
8. Instalar Docker Desktop y Docker Compose; preparar y comprobar la contenerización si el proyecto lo requiere.
9. Revisar Git, crear un commit y publicar el proyecto en GitHub.
10. Completar la prueba final y el checklist, conservando evidencias reales de los pasos realizados.

## Consideraciones

- Visual Studio Code se utiliza para editar y ejecutar el proyecto; Android Studio administra el SDK, las herramientas Android y el emulador.
- WSL2 se configura en la medida necesaria para Docker Desktop. No implica que el emulador Android o el APK se ejecuten dentro de Docker.
- La configuración de Docker debe corresponder a los servicios reales del proyecto; no se deben agregar servicios ficticios.
- Las capturas y evidencias deben reflejar pasos ejecutados, y no deben mostrar contraseñas, tokens, claves privadas ni otros datos sensibles.

Para instrucciones detalladas, comandos, solución de problemas y referencias oficiales, consulta [Manual_Flutter_.pdf](./Manual_Flutter_.pdf).
