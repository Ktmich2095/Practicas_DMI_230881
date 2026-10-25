"""Build the static Pages portal from actual screenshot evidence."""
from pathlib import Path
from html import escape
import json

root = Path(__file__).resolve().parents[1]
report = json.loads((root / 'docs/evidence/screenshots/capture-report.json').read_text())
assert report['ok'] and len(report['screenshots']) == 19
titles = ['Inicio', 'Contador Riverpod', 'Botones', 'Tarjetas', 'Tarjetas con imágenes',
          'Indicadores de progreso', 'Notificaciones y diálogos', 'Confirmación', 'Acerca de',
          'SnackBar', 'Animaciones', 'Controles interactivos', 'Tutorial · inicio',
          'Tutorial · paso 2', 'Tutorial · finalizar', 'Lista infinita y refresco',
          'Colores', 'Tema oscuro', 'Menú lateral']
cards = []
for title, shot in zip(titles, report['screenshots']):
    path = f'evidence/screenshots/{shot["file"]}'
    assert (root / 'docs' / path).is_file()
    cards.append(f'<a class="capture" href="{path}"><img loading="lazy" src="{path}" width="430" height="932" alt="Captura real: {escape(title)}"><div><h3>{escape(title)}</h3><code>{escape(shot["route"])}</code></div></a>')

html = '''<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="description" content="Práctica 05: diagramas interactivos Archify y capturas reales de Widgets App, Material 3, GoRouter y Riverpod.">
<title>Widgets App · Práctica 05</title>
<style>
:root{color-scheme:dark;--bg:#101425;--surface:#191e32;--text:#f1f3fc;--muted:#b1b9d0;--line:#323951;--accent:#b5a3ff}
*{box-sizing:border-box}body{margin:0;background:radial-gradient(ellipse at 90% 0,#30265088,transparent 45%),var(--bg);color:var(--text);font:16px/1.65 system-ui,sans-serif}a{color:var(--accent)}a:focus-visible{outline:3px solid #a9e8da;outline-offset:5px}main,header,footer{width:min(1160px,100% - 40px);margin:auto}header{display:flex;justify-content:space-between;gap:16px;padding:24px 0;border-bottom:1px solid var(--line)}header a{text-decoration:none;font-size:14px}.eyebrow{text-transform:uppercase;letter-spacing:.16em;color:#91d9ca;font-size:12px;font-weight:700}.hero{padding:64px 0 40px;max-width:850px}h1{font-size:clamp(38px,6vw,72px);line-height:1.1;letter-spacing:-.05em;margin:20px 0}h1 span{color:var(--accent)}h2{font-size:28px;letter-spacing:-.03em;margin:0 0 12px}h3{margin:0;font-size:18px}p{color:var(--muted);max-width:76ch}.tags{display:flex;flex-wrap:wrap;gap:8px}.tags span{border:1px solid var(--line);border-radius:30px;padding:4px 12px;font-size:12px;color:var(--muted)}section{padding:22px 0 42px;scroll-margin-top:24px}.diagrams{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px;margin:24px 0}.diagram{border:1px solid var(--line);border-radius:22px;overflow:hidden;background:var(--surface)}.diagram img{display:block;width:100%;height:auto;aspect-ratio:1.6;object-fit:contain}.diagram div{padding:24px}.diagram p{font-size:14px}.button{display:inline-flex;padding:11px 18px;margin:6px 8px 6px 0;border-radius:12px;background:var(--accent);color:#19132e;font-size:14px;font-weight:750;text-decoration:none}.source{display:inline-block;margin-top:10px;font-size:13px}.instructions{padding:24px;border:1px solid var(--line);border-radius:20px;background:var(--surface)}.gallery{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:22px;margin-top:28px}.capture{display:block;min-width:0;overflow:hidden;background:var(--surface);border:1px solid var(--line);border-radius:18px;text-decoration:none;color:var(--text)}.capture img{display:block;width:100%;height:auto;aspect-ratio:430/932;object-fit:contain;background:#f8f9ff}.capture div{padding:16px}.capture h3{font-size:15px}.capture code{font-size:12px;color:var(--muted);overflow-wrap:anywhere}.note{border-left:2px solid #91d9ca;padding-left:18px;font-size:14px}footer{padding:24px 0 36px;border-top:1px solid var(--line);font-size:13px;color:var(--muted)}
@media(max-width:900px){.gallery{grid-template-columns:repeat(3,minmax(0,1fr))}}@media(max-width:640px){header{flex-direction:column;gap:6px}.hero{padding-top:42px}.diagrams{grid-template-columns:1fr}.gallery{grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}.capture div{padding:12px}}@media(max-width:350px){.gallery{grid-template-columns:1fr}}@media(prefers-reduced-motion:no-preference){html{scroll-behavior:smooth}}
</style>
</head>
<body>
<header><a href="../../../index.html">← Menú de prácticas</a><a href="https://github.com/Ktmich2095/Practicas_DMI_230881/tree/main/Practica05">Código y README en GitHub ↗</a></header>
<main>
<section class="hero"><div class="eyebrow">Desarrollo Móvil Integral · Práctica 05</div><h1>Widgets App.<br><span>Explora cada componente.</span></h1><p>Once pantallas para descubrir componentes visuales, navegación declarativa y estado reactivo. Aquí puedes explorar su arquitectura y ver capturas reales de la aplicación actual.</p><div class="tags"><span>Flutter y Dart</span><span>Material Design 3</span><span>GoRouter</span><span>Riverpod</span><span>Archify</span></div></section>
<section id="arquitectura"><h2>Abre los diagramas con Archify</h2><p>Los enlaces abren el visor interactivo generado por Archify. Las imágenes son vistas previas; para explorar y exportar, abre el diagrama.</p>
<div class="diagrams">
<article class="diagram"><a href="diagrams/general.html"><img src="evidence/screenshots/archify-general/general.visual-check.1440x900.light.png" width="1440" height="900" alt="Vista previa de la arquitectura general"></a><div><h3>Arquitectura general</h3><p>Usuario, Flutter, Material 3, GoRouter, Riverpod y recursos locales y remotos.</p><a class="button" href="diagrams/general.html">Abrir en visor Archify →</a><br><a class="source" href="diagrams/general.archify.json" download>Descargar fuente JSON editable</a></div></article>
<article class="diagram"><a href="diagrams/especifica.html"><img src="evidence/screenshots/archify-especifica/especifica.visual-check.1440x900.dark.png" width="1440" height="900" alt="Vista previa de pantallas y dependencias"></a><div><h3>Pantallas y dependencias</h3><p>Rutas, menú lateral, providers, widgets compartidos y gestión de temas.</p><a class="button" href="diagrams/especifica.html">Abrir en visor Archify →</a><br><a class="source" href="diagrams/especifica.archify.json" download>Descargar fuente JSON editable</a></div></article>
</div>
<div class="instructions"><h3>Cómo usar el visor</h3><p>Abre un diagrama y utiliza los controles para ampliar, explorar componentes y cambiar entre claro y oscuro. El menú Exportar permite guardar el diagrama en los formatos disponibles. Cada HTML es independiente: también puedes descargarlo y abrirlo en tu navegador sin instalar Archify ni iniciar sesión.</p><p>Para editar la arquitectura, descarga el JSON y regenera el HTML con Archify. No necesitas el JSON para visualizarlo. Ambos diagramas pasaron las comprobaciones de artefacto y navegador.</p></div>
</section>
<section id="capturas"><div class="eyebrow">Evidencia de la aplicación</div><h2>Las once pantallas, en detalle.</h2><p>19 capturas tomadas el 9 de noviembre de 2026 en Chrome, con viewport de 430×932. Incluyen estados adicionales de diálogos, tutorial y tema oscuro. Toca cualquier imagen para abrirla a tamaño completo.</p><p class="note">Las tarjetas con imágenes y la galería muestran fotos descargadas durante esta sesión en Chrome; su disponibilidad depende del servidor remoto. La galería integra lista infinita y Pull to Refresh; el refresco se verifica con pruebas automatizadas. Son capturas web, no de un emulador Android.</p><div class="gallery">{cards}</div><p><a href="evidence/screenshots/capture-report.json">Ver registro de capturas</a> · <a href="REVIEW-20261109.md">Validación y limitaciones</a> · <a href="../README.md">README del proyecto</a></p></section>
</main><footer>Michelle Castro Otero · Desarrollo Móvil Integral · Arquitecturas documentadas con Archify.</footer>
</body></html>
'''.replace('{cards}', '\n'.join(cards))
(root / 'docs/index.html').write_text(html, encoding='utf-8', newline='\n')
print('Portal generated with both Archify viewers and 19 real screenshots.')
