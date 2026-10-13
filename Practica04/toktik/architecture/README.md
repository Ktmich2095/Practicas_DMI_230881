# Diagramas de TokTik

- [Modelo inicial](initial/index.html): Pantalla → Provider local → Lista.
- [Modelo final](final/index.html): capas, repositorios, fuentes y persistencia.

Los HTML incluyen SVG, estilos, controles, tema claro/oscuro y exportación,
y se pueden abrir independientemente o publicar en GitHub Pages.
Las rutas de publicación son relativas. Cada carpeta conserva `candidate.json`
y los recibos de validación de Archify.

Representan el diseño del árbol de trabajo local. No se enlazan los cambios
sin commit a un SHA de Git. El modelo final se contrastó con `lib/main.dart`,
los contratos en `lib/domain/`, los providers de presentación y los datasources,
mappers, repositorios y almacenamiento de infraestructura.

Ambos modelos pasaron `validate`, `deliver`, `check` y `browser-check` con
perfil showcase. Esto verifica estructura, geometría y navegador; no constituye
una inspección visual humana ni una prueba de la aplicación Flutter.
