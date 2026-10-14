"""Original TokTik vector identity -> SVG, PNG, Android adaptive icons + WAV.

Only the optional generator needs Pillow. Runtime assets are already packaged.
Run with Python + Pillow (or PYTHONPATH pointing at .tools/branding).
"""
from pathlib import Path
import math
import array
import wave
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'android/app/src/main/res'
BRAND = ROOT / 'assets/branding'
PALETTES = {
    'normal': ('#07090F', '#FFFFFF', '#5DE2D2', '#FF527C'),
    'halloween': ('#160B24', '#FFA040', '#BD86FF', '#FF6F27'),
    'christmas': ('#09291F', '#FFFFFF', '#FFD36A', '#EF4D58'),
    'valentine': ('#8C284E', '#FFFFFF', '#FF90BD', '#FF526A'),
}


class Drawing:
    def __init__(self):
        self.image = Image.new('RGBA', (768, 768))
        self.draw = ImageDraw.Draw(self.image)
        self.svg = []

    def rect(self, box, color, radius=0):
        self.draw.rounded_rectangle(tuple(int(v * 3) for v in box), radius=radius * 3, fill=color)
        x, y, r, b = box
        self.svg.append(f'<rect x="{x}" y="{y}" width="{r-x}" height="{b-y}" rx="{radius}" fill="{color}"/>')

    def poly(self, points, color):
        self.draw.polygon([(int(x * 3), int(y * 3)) for x, y in points], fill=color)
        self.svg.append('<polygon points="' + ' '.join(f'{x},{y}' for x, y in points) + f'" fill="{color}"/>')

    def ellipse(self, box, color):
        self.draw.ellipse(tuple(int(v * 3) for v in box), fill=color)
        x, y, r, b = box
        self.svg.append(f'<ellipse cx="{(x+r)/2}" cy="{(y+b)/2}" rx="{(r-x)/2}" ry="{(b-y)/2}" fill="{color}"/>')

    def line(self, points, color, width=2):
        self.draw.line([(int(x * 3), int(y * 3)) for x, y in points], fill=color, width=width * 3)
        self.svg.append('<polyline points="' + ' '.join(f'{x},{y}' for x, y in points) + f'" stroke="{color}" stroke-width="{width}" fill="none"/>')


def heart(d, cx, cy, scale, color):
    points = []
    for n in range(64):
        t = n * math.tau / 64
        points.append((cx + scale * math.sin(t) ** 3,
            cy - scale * (13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t)) / 16))
    d.poly(points, color)


def logo(season):
    _, white, primary, accent = PALETTES[season]
    d = Drawing()
    # Motion echoes followed by a geometric T + play symbol, shared by all variants.
    for dx, dy, color in [(-5, 4, primary), (5, -4, accent), (0, 0, white)]:
        d.rect((62+dx, 72+dy, 187+dx, 99+dy), color, 12)
        d.rect((76+dx, 84+dy, 103+dx, 181+dy), color, 12)
        d.poly([(119+dx, 110+dy), (169+dx, 140+dy), (119+dx, 171+dy)], color)
    d.rect((128, 189, 183, 195), primary, 3)
    d.mark = d.image.copy()
    if season == 'halloween':
        d.ellipse((167, 168, 218, 207), '#FF852D')
        d.line([(193, 168), (195, 159), (201, 161)], '#76B764', 4)
        d.poly([(176, 181), (186, 181), (181, 188)], '#FFE373')
        d.poly([(197, 181), (207, 181), (202, 188)], '#FFE373')
        d.poly([(180, 195), (185, 198), (190, 194), (195, 198), (204, 194)], '#4B1924')
        d.poly([(39, 53), (49, 58), (55, 51), (61, 58), (75, 52), (65, 68), (55, 64), (45, 69)], primary)
    elif season == 'christmas':
        d.poly([(75, 69), (94, 34), (154, 67)], '#EE4956')
        d.rect((70, 65, 161, 78), '#FFFFFF', 6)
        d.ellipse((90, 29, 105, 44), '#FFFFFF')
        for x, y in [(204, 109), (47, 145), (190, 196)]:
            d.line([(x-7, y), (x+7, y)], primary, 2)
            d.line([(x, y-7), (x, y+7)], primary, 2)
    elif season == 'valentine':
        heart(d, 192, 187, 24, '#FF526A')
        heart(d, 51, 62, 10, primary)
        d.ellipse((210, 74, 217, 81), '#FFF4F8')
    return d


def generate():
    BRAND.mkdir(parents=True, exist_ok=True)
    for season, (background, _, _, _) in PALETTES.items():
        drawing = logo(season)
        drawing.image.resize((512, 512), Image.Resampling.LANCZOS).save(BRAND / f'logo_{season}.png')
        drawing.mark.resize((512, 512), Image.Resampling.LANCZOS).save(BRAND / f'mark_{season}.png')
        (BRAND / f'logo_{season}.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">' + ''.join(drawing.svg) + '</svg>\n', encoding='utf-8')
        foreground = Image.new('RGBA', (768, 768))
        # Adaptive safe zone: scale mark to the central 66/108 of the canvas.
        fg = drawing.image.resize((470, 470), Image.Resampling.LANCZOS)
        foreground.alpha_composite(fg, (149, 149))
        folder = RES / 'drawable-nodpi'
        folder.mkdir(parents=True, exist_ok=True)
        foreground.resize((432, 432), Image.Resampling.LANCZOS).save(folder / f'toktik_{season}_foreground.png')
        for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
            path = RES / f'mipmap-{density}'
            path.mkdir(parents=True, exist_ok=True)
            icon = Image.new('RGBA', (768,768), background)
            icon.alpha_composite(drawing.image)
            icon.resize((size,size), Image.Resampling.LANCZOS).save(path / f'ic_toktik_{season}.png')
        path = RES / 'mipmap-anydpi-v26'
        path.mkdir(parents=True, exist_ok=True)
        (path / f'ic_toktik_{season}.xml').write_text(f'''<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/toktik_{season}_background" />
    <foreground android:drawable="@drawable/toktik_{season}_foreground" />
</adaptive-icon>\n''', encoding='utf-8')
    colors = '<resources>\n' + ''.join(f'    <color name="toktik_{s}_background">{p[0]}</color>\n' for s,p in PALETTES.items()) + '</resources>\n'
    (RES / 'values/branding_colors.xml').write_text(colors, encoding='utf-8')
    (RES / 'drawable-nodpi/toktik_splash.png').write_bytes((BRAND / 'logo_normal.png').read_bytes())
    previews = Image.new('RGB', (1024, 256))
    for index, season in enumerate(PALETTES):
        panel = Image.new('RGBA', (256, 256), PALETTES[season][0])
        panel.alpha_composite(logo(season).image.resize((256,256), Image.Resampling.LANCZOS))
        previews.paste(panel.convert('RGB'), (index * 256, 0))
    previews.save(BRAND / 'identity_board.png')
    notes = {'normal': [523.25, 783.99], 'halloween': [220, 261.63, 207.65],
        'christmas': [783.99, 1046.5, 1318.51], 'valentine': [659.25, 880, 987.77]}
    for season, frequencies in notes.items():
        rate = 22050; duration = 1.15; samples = array.array('h')
        for n in range(int(rate * duration)):
            t = n / rate; part = t / duration
            frequency = frequencies[min(len(frequencies)-1, int(part * len(frequencies)))]
            envelope = math.sin(math.pi * part) ** 2 * math.exp(-1.3 * part)
            signal = math.sin(math.tau * frequency * t) + .25 * math.sin(math.tau * frequency * 2 * t)
            samples.append(int(32767 * .22 * envelope * signal))
        with wave.open(str(ROOT / f'assets/audio/intro_{season}.wav'), 'wb') as output:
            output.setnchannels(1); output.setsampwidth(2); output.setframerate(rate); output.writeframes(samples.tobytes())
    print('Generated four original logo families, Android icons, a board and four short WAV cues.')


if __name__ == '__main__':
    generate()
