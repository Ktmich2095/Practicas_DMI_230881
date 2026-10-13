"""Generate original MP4 loops and WAV motifs; no downloaded media.

Python standard library + FFmpeg with libx264. Optional --ffmpeg <executable>.
"""
from pathlib import Path
import argparse
import array
import math
import shutil
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]


def generate(ffmpeg):
    videos = ROOT / 'assets/videos'
    audio = ROOT / 'assets/audio'
    videos.mkdir(parents=True, exist_ok=True)
    audio.mkdir(parents=True, exist_ok=True)
    palettes = {
        'aurora': (12, 30, 50),
        'atardecer': (50, 15, 30),
        'orbita': (25, 15, 55),
    }
    for name, (r, g, b) in palettes.items():
        # Periodic original color field; T completes one cycle in six seconds.
        filters = (
            'nullsrc=size=360x640:rate=24:duration=6,'
            f"geq=r='{r}+60*(1+sin(X/65+Y/100+T*PI/3))':"
            f"g='{g}+55*(1+sin(Y/85-T*PI/3))':"
            f"b='{b}+65*(1+sin(X/100-Y/110+T*PI/3))'"
        )
        subprocess.run([ffmpeg, '-y', '-loglevel', 'error', '-f', 'lavfi',
            '-i', filters, '-c:v', 'libx264', '-preset', 'fast', '-crf', '24',
            '-pix_fmt', 'yuv420p', '-movflags', '+faststart',
            str(videos / f'{name}.mp4')], check=True)
    motifs = {
        'halloween': (220.0, 261.63, 311.13, 261.63),
        'christmas': (261.63, 329.63, 392.0, 329.63),
        'valentine': (349.23, 440.0, 523.25, 440.0),
    }
    rate = 22050
    for name, notes in motifs.items():
        samples = array.array('h')
        for i in range(rate * 4):
            t = i / rate
            phase = t % 1
            envelope = math.sin(math.pi * phase) ** 2
            frequency = notes[min(3, int(t))]
            sample = .2 * envelope * math.sin(2 * math.pi * frequency * t)
            samples.append(int(32767 * sample))
        with wave.open(str(audio / f'{name}.wav'), 'wb') as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(rate)
            output.writeframes(samples.tobytes())
    print('Created three vertical H.264 MP4 loops and three original WAV motifs.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--ffmpeg', default=shutil.which('ffmpeg'))
    args = parser.parse_args()
    if not args.ffmpeg:
        parser.error('Install FFmpeg or pass --ffmpeg <path>')
    generate(args.ffmpeg)
