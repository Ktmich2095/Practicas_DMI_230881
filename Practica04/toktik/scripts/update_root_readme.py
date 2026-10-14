"""Add only the Practice 04 row, preserving the root README's other bytes."""
from pathlib import Path

root = Path(__file__).resolve().parents[3] / 'README.md'
raw = root.read_bytes()
text = raw.decode('utf-8')
if '| 4 | TokTik' not in text:
    newline = '\r\n' if '\r\n' in text else '\n'
    rows = text.splitlines(keepends=True)
    for index, line in enumerate(rows):
        if line.startswith('| 3 |'):
            rows.insert(index + 1, '| 4 | TokTik | Videos verticales con arquitectura CLEAN, APIs, favoritos y temas de temporada. | — | Implementada; validación Android pendiente | [Ver práctica](Practica04/toktik/README.md) |' + newline)
            root.write_bytes(''.join(rows).encode('utf-8'))
            print('Added only the Practice 04 row.')
            break
    else:
        raise RuntimeError('Practice 03 row not found; no changes made.')
else:
    # Normalize only the newly added row, without changing previous content.
    for line in text.splitlines():
        if line.startswith('| 4 | TokTik'):
            text = text.replace(line + '\r\n', line + '\n')
            root.write_bytes(text.encode('utf-8'))
    print('Practice 04 already exists; no changes made.')
