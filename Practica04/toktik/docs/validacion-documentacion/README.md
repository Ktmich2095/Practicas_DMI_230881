# Validación de la documentación

Estas capturas y recibos verifican el sitio documental; **no son evidencias del
funcionamiento de TokTik**. Las grabaciones y capturas académicas se agregan en
`docs/evidencias/`.

## Alcance de los cambios

- README de TokTik reorganizado; información técnica extensa conservada en
  `docs/GUIA_TECNICA.md`, incluidos los 14 bloques de comandos/esquemas anteriores.
- Carpetas y plantillas de evidencias, sin imágenes ni videos ficticios.
- `index.html` raíz reutilizado desde `main`, commit
  `965c6acea76e0f0e8e8c5c818ba3c65004b677b8`, porque no estaba en el árbol de
  trabajo de `Practica04`. Sus dos tarjetas originales se conservaron byte a byte.
- Tarjeta TokTik con dos accesos reales a los diagramas existentes. La cuadrícula
  adapta el número de columnas al ancho disponible.

## Comprobaciones

`documentation-check.json` comprueba rutas y anclas activas, distingue comentarios
y ejemplos de los enlaces reales y compara 545 archivos protegidos. Incluye
código, assets, otras prácticas y todos los archivos de arquitectura. Ninguno se
modificó durante esta revisión. `.nojekyll` permanece en la raíz.

`browser-check.json` registra pruebas reales con Chrome a 320, 390, 768, 1024 y
1440 píxeles, sin desbordamiento horizontal ni tarjetas superpuestas. También
comprueba los cuatro destinos del menú, los botones hover y movimiento reducido,
la vista Markdown del README a cuatro anchos y la ausencia de errores JavaScript
y respuestas HTTP fallidas.

Las páginas de arquitectura de las prácticas 02/03 existen en `main`, aunque
sus carpetas `.archify` no están en esta rama local. Para comprobar la publicación
prevista, el servidor temporal de prueba lee **los blobs Git reales de main**
cuando esos archivos no están en el árbol actual. Se mantiene el prefijo público
`/Practicas_DMI_230881/`. No se copiaron archivos ni se alteraron esas prácticas;
esta comprobación no afirma que esos HTML existan en el disco de `Practica04`.

El servidor de pruebas se cierra al terminar. El sitio publicado contiene HTML
estático y no lo necesita. La vista Markdown es temporal (`.buildlog/`), no una
segunda página principal ni una copia destinada a publicarse.

## Capturas

- `menu-1440.png` y `menu-390.png`: menú de arquitecturas completo.
- `readme-1440.png` y `readme-390.png`: vista de lectura de verificación del README.

Se inspeccionaron las capturas de escritorio y móvil: títulos, botones, tarjetas
y texto sin superposiciones. Los espacios pendientes de medios no intentan
cargar imágenes, posters o videos inexistentes.

## Repetir las comprobaciones

Desde la raíz del repositorio:

```powershell
python Practica04/toktik/docs/validacion-documentacion/verify_documentation.py
node Practica04/toktik/docs/validacion-documentacion/verify_browser.mjs
```

La comprobación Markdown usa `markdown-it-py`, disponible en el entorno de esta
revisión. El script de navegador usa Node.js y Chrome en Windows; su ruta está
indicada en el archivo. Estas herramientas no son dependencias de GitHub Pages.
La verificación de preservación utiliza `protected-files-before.json`.

Los registros de Flutter siguen siendo históricos: esta revisión no ejecutó
Flutter ni cambió su código. No se publicaron archivos ni se hicieron commits,
merges o push. La publicación sigue configurada, según lo indicado por el
usuario, desde `main / raíz`.
