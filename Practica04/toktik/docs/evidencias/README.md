# Evidencias de TokTik

[Volver al README de TokTik →](../../README.md)

Estas carpetas guardan **capturas y grabaciones reales** para el informe de la
Práctica 04. Los siete videos MP4 y las imágenes de logos y diagramas ya están
disponibles en sus carpetas.

## Inventario previsto

| Carpeta | Archivos previstos | Qué documentan |
| --- | --- | --- |
| `logos/` | `logo_normal.png`, `logo_halloween.png`, `logo_christmas.png`, `logo_valentine.png` | Identidad visual de cada temática utilizada en la app. |
| `videos/` | `videoUno.mp4`, `videoDos.mp4`, `videoTres.mp4` | Funcionamiento general, navegación y funcionalidades principales. |
| `videos/` | `videoSiete.mp4`, `videoSeis.mp4`, `videoCuatro.mp4`, `videoCinco.mp4` | Pantallas de inicio Normal, Halloween, Navidad y San Valentín. |
| `diagramas/` | `provider-local.png`, `provider-repository-datasources.png` | Capturas de los dos diagramas Archify. |

Los videos están integrados en el README de TokTik y en la
[galería HTML para GitHub Pages](../../videos.html).

## Cómo insertar los archivos

1. Abre la galería HTML y comprueba que cada reproductor funcione.
2. Mantén las rutas relativas y las mayúsculas/minúsculas al agregar archivos.
3. Comprueba la vista de GitHub Pages después de publicar los cambios; los
   archivos locales no aparecen en Pages hasta que estén en la rama publicada.

### Imágenes en el README de TokTik

```markdown
![Logo Normal de TokTik utilizado en la aplicación](docs/evidencias/logos/logo_normal.png)
```

Para acotar su tamaño en GitHub:

```html
<img src="docs/evidencias/logos/logo_normal.png"
     alt="Logo Normal de TokTik utilizado en la aplicación" width="320">
```

### Video en el README de GitHub

El README usa elementos `<video>` para las grabaciones. En GitHub Pages, usa la
galería HTML, que ofrece controles nativos y evita iniciar la descarga completa
de todos los clips al abrir la página.

Consulta [la galería de videos](../../videos.html).

## Formatos, rutas y publicación

- Capturas: PNG, JPEG o WebP, legibles y sin datos privados; añade texto alternativo.
- Videos: los archivos existentes son MP4. Comprueba su reproducción en los
  navegadores objetivo antes de publicar; la extensión por sí sola no garantiza
  compatibilidad de códecs.
- Mantén clips breves y de tamaño razonable. No subas archivos vacíos para
  reservar nombres; estas instrucciones ya mantienen las carpetas en Git.
- Usa nombres en minúsculas sin espacios ni acentos; GitHub Pages distingue
  mayúsculas y minúsculas. Las rutas son relativas, sin `C:\`, `file://` o localhost.
- Estos medios son documentación: no pertenecen a `assets/`, no requieren
  cambios en Flutter y no deben registrarse en `pubspec.yaml`.

Base pública esperada si Pages se configura para publicar `Practica04` desde la
raíz del repositorio:

`https://ktmich2095.github.io/Practicas_DMI_230881/Practica04/toktik/videos.html`

Los videos se sirven desde `docs/evidencias/videos/` bajo la misma base.
