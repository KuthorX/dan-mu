#!/usr/bin/env python3
"""Renders the score in score.py to seamless looping MP3s in audio/music/.

Each cue is written to MIDI three times back to back and rendered with FluidSynth
(MS Basic soundfont, chorus off so the render is periodic). The middle pass is
kept, so reverb tails from the end of the loop are already present at its start,
and its first 50 ms are crossfaded with the audio that followed the middle pass
to hide FluidSynth's 64-sample event quantisation. Loudness is set to -18 LUFS.

    python3 tools/audio/render_music.py [cue ...]
"""
import pathlib
import subprocess
import sys

import numpy as np
from scipy.io import wavfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from audio_common import CACHE, ROOT, loudness, write_mp3  # noqa: E402
from score import SONGS  # noqa: E402

SOUNDFONT = "/Applications/MuseScore 4.app/Contents/Resources/sound/MS Basic.sf3"
RATE = 44100
TARGET_LUFS = -18.0
SEAM = int(0.05 * RATE)
OUT = ROOT / "audio" / "music"


def render(name: str) -> None:
    song = SONGS[name]()
    midi_path = CACHE / f"{name}.mid"
    wav_path = CACHE / f"{name}_raw.wav"
    song.write(midi_path, repeats=3)
    subprocess.run([
        "fluidsynth", "-ni", "-q", "-C0", "-R1", "-g", "0.35", "-r", str(RATE),
        "-o", "audio.file.format=float", "-F", str(wav_path), SOUNDFONT, str(midi_path),
    ], check=True)
    _, raw = wavfile.read(wav_path)
    raw = raw.astype(np.float64)
    loop = int(round(song.seconds() * RATE))
    body = raw[loop:2 * loop].copy()
    ramp = np.linspace(0.0, 1.0, SEAM)[:, None]
    body[:SEAM] = body[:SEAM] * ramp + raw[2 * loop:2 * loop + SEAM] * (1.0 - ramp)
    gain = 10 ** ((TARGET_LUFS - loudness(body, RATE)) / 20.0)
    body *= gain
    target = OUT / f"{name}.mp3"
    write_mp3(body, RATE, target, bitrate=128)
    print(f"{name}: {loop / RATE:.2f}s gain {20 * np.log10(gain):+.1f} dB -> {target.relative_to(ROOT)}")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    CACHE.mkdir(parents=True, exist_ok=True)
    for name in sys.argv[1:] or SONGS:
        render(name)


if __name__ == "__main__":
    main()
