"""Reuse the existing main-branch menu and add only practice 05."""
from pathlib import Path
import subprocess

repo = Path(__file__).resolve().parents[3]
target = repo / 'index.html'
original = subprocess.check_output(['git','show','main:index.html'], cwd=repo).decode('utf-8').replace('\r\n','\n')
base = target.read_text(encoding='utf-8') if target.exists() else original
card = '''          <article class="card teal">
            <div class="content">
              <span class="number">Práctica 05</span>
              <h3>Widgets App — Componentes e Interfaces Flutter</h3>
              <p class="description">Exploración de botones, tarjetas, indicadores, diálogos, animaciones y controles Material 3. Incluye navegación con GoRouter, contador y temas con Riverpod, tutorial y desplazamiento infinito con actualización.</p>
              <div class="tags"><span>Flutter</span><span>Dart</span><span>Material 3</span><span>GoRouter</span><span>Riverpod</span></div>
              <a class="button" href="Practica05/widgets_app/architecture/index.html" aria-label="Ver arquitectura de Práctica 05 — Widgets App">Ver arquitectura <span class="arrow" aria-hidden="true">→</span></a>
            </div>
          </article>
'''
if 'Practica05/widgets_app/architecture/index.html' not in base:
    marker = '        </div>\n        <p class="note">'
    assert base.count(marker) == 1
    base = base.replace(marker,card+marker)
    base = base.replace('Del primer contador al chat y los videos cortos.', 'Del primer contador al chat, los videos cortos y la exploración de widgets.')
target.write_text(base,encoding='utf-8',newline='\n')
assert all(link in base for link in __import__('re').findall(r'href="([^"]+)"',original))
print(f'Menú actualizado conservando todos los enlaces originales: {target}')
