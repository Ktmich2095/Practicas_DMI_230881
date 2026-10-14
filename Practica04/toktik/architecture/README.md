# Diagramas de TokTik

## Diagramas de Arquitectura

- [Ver arquitectura con Provider Local →](index.html#provider-local).
- [Ver arquitectura con Provider, Repository y DataSources →](index.html#provider-repository-datasources).
- [Navegación compartida HTML](index.html).

### Primera entrega: Provider Local

- [HTML original independiente](provider-local/index.html).
- [SVG exportado por Archify](provider-local/provider-local.svg).
- [Explicación y reproducción de las validaciones](provider-local/README.md).

Vista del estado local de la aplicación real, no una implementación paralela sin
repositorios. La carpeta completa de la primera entrega permanece intacta.

### Segunda entrega: Provider, Repository y DataSources

- [HTML independiente generado por Archify](provider-repository-datasources/index.html).
- [SVG exportado por Archify](provider-repository-datasources/provider-repository-datasources.svg).
- [Explicación, fuentes y validaciones](provider-repository-datasources/README.md).

Organiza Presentation, Domain e Infrastructure y muestra el catálogo local,
Coverr, Pixabay, Internet Archive, conversión JSON y persistencia del dispositivo.
El índice añade navegación externa a ambos visores, sin reescribir sus HTML.

## Material anterior

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
