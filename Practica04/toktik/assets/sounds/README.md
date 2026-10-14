# Sonidos de bienvenida opcionales

Coloca aquí los MP3 descargados, con estos nombres exactos:

| Tema | Archivo |
| --- | --- |
| Normal | `normal.mp3` |
| Halloween | `halloween.mp3` |
| Navidad | `christmas.mp3` |
| San Valentín | `valentine.mp3` |

No se incluyen ni generan sonidos. El directorio está registrado en pubspec.yaml;
los MP3 individuales no son obligatorios. Si falta uno, la intro permanece en
silencio. Después de agregar archivos, detén y vuelve a ejecutar Flutter para
incorporarlos al bundle.

Se reproduce una vez al mostrar la intro Flutter del tema restaurado o calculado
por calendario, después del splash nativo. Se detiene antes de entrar al feed y
al pasar a segundo plano; volver al primer plano no lo reinicia. El control de
sonido de bienvenida en ajustes es independiente del silencio de los videos.
La vista previa explícita puede reproducirlo de nuevo; no es un nuevo arranque.
