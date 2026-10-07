#!/usr/bin/env python3
"""Synthesises DanMu's sound effects into audio/sfx/*.wav (44.1 kHz mono 16-bit).

Palette: paper and wood for frequent events (brush flicks, hyoshigi clacks, koto
plucks via Karplus-Strong), bronze and taiko for big ones (bomb, spell, death).
Jingles (stage clear, game clear, game over) are short koto/shakuhachi phrases
rendered with FluidSynth from the same soundfont as the music.

    python3 tools/audio/sfx.py
"""
import pathlib
import subprocess
import sys

import numpy as np
from scipy import signal
from scipy.io import wavfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from audio_common import CACHE, ROOT, write_wav16  # noqa: E402
from music_lib import Song, pitch  # noqa: E402
from render_music import SOUNDFONT  # noqa: E402

RATE = 44100
PEAK = 10 ** (-1.5 / 20)
OUT = ROOT / "audio" / "sfx"
rng = np.random.default_rng(7)


def t_axis(duration: float) -> np.ndarray:
    return np.arange(int(duration * RATE)) / RATE


def decay(t: np.ndarray, tau: float, attack: float = 0.001) -> np.ndarray:
    return np.minimum(t / attack, 1.0) * np.exp(-t / tau)


def band(x: np.ndarray, low: float, high: float) -> np.ndarray:
    return signal.sosfilt(signal.butter(2, [low, high], "bandpass", fs=RATE, output="sos"), x)


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    return signal.sosfilt(signal.butter(2, cutoff, "lowpass", fs=RATE, output="sos"), x)


def noise(duration: float) -> np.ndarray:
    return rng.uniform(-1.0, 1.0, int(duration * RATE))


def glide(t: np.ndarray, start: float, end: float, curve: float = 1.0) -> np.ndarray:
    """Sine whose frequency moves exponentially from start to end over t."""
    ratio = (t / t[-1]) ** curve
    freq = start * (end / start) ** ratio
    return np.sin(2 * np.pi * np.cumsum(freq) / RATE)


def pluck(freq: float, duration: float, brightness: float = 0.5, damping: float = 0.996) -> np.ndarray:
    """Karplus-Strong string: a koto-like pluck."""
    period = max(2, int(RATE / freq))
    buffer = lowpass(rng.uniform(-1, 1, period), 1000 + 8000 * brightness)
    out = np.zeros(int(duration * RATE))
    for index in range(len(out)):
        out[index] = buffer[index % period]
        buffer[index % period] = damping * 0.5 * (buffer[index % period] + buffer[(index + 1) % period])
    return out * decay(t_axis(duration), duration * 0.6, 0.0005)


def bell(freq: float, duration: float, tau: float, ratios=(1.0, 2.76, 5.4, 8.93)) -> np.ndarray:
    t = t_axis(duration)
    return sum(np.sin(2 * np.pi * freq * ratio * t) * decay(t, tau / (1 + index * 0.8), 0.002) / (1 + index)
               for index, ratio in enumerate(ratios))


def taper(samples: np.ndarray, seconds: float = 0.02) -> np.ndarray:
    """Fades the last `seconds` to zero so a truncated decay never ends in a click."""
    length = min(len(samples) // 2, int(seconds * RATE))
    return np.concatenate([samples[:-length], samples[-length:] * np.linspace(1, 0, length) ** 2])


def place(total: float, *parts) -> np.ndarray:
    """Mixes (offset_seconds, gain, samples) parts into one buffer, each part tapered."""
    out = np.zeros(int(total * RATE))
    for offset, gain, samples in parts:
        start = int(offset * RATE)
        end = min(len(out), start + len(samples))
        out[start:end] += gain * taper(samples[:end - start])
    return out


def wood(freq: float, duration: float = 0.06, tau: float = 0.012) -> np.ndarray:
    t = t_axis(duration)
    tone = np.sin(2 * np.pi * freq * t) + 0.4 * np.sin(2 * np.pi * freq * 2.71 * t) * np.exp(-t / (tau * 0.4))
    click = band(noise(duration), 1500, 5000) * decay(t, 0.002)
    return tone * decay(t, tau) + 0.5 * click


# ---- frequent, quiet events --------------------------------------------------

def shot(focused: bool) -> np.ndarray:
    duration = 0.05
    t = t_axis(duration)
    low, high, thump = (900, 2400, 520) if focused else (1400, 3800, 700)
    brush = lowpass(band(noise(duration), low, high), 5000) * decay(t, 0.009)
    return brush + 0.35 * np.sin(2 * np.pi * thump * t) * decay(t, 0.008)


def enemy_puff(low: float, high: float, duration: float, tone: float) -> np.ndarray:
    t = t_axis(duration)
    breath = band(noise(duration), low, high) * decay(t, duration * 0.3, 0.006)
    return breath + 0.4 * glide(t, tone, tone * 0.75) * decay(t, duration * 0.25, 0.004)


def enemy_spiral() -> np.ndarray:
    duration = 0.15
    t = t_axis(duration)
    source = noise(duration)
    sweep = t / t[-1]
    mixed = band(source, 1600, 2800) * (1 - sweep) + band(source, 600, 1200) * sweep
    return mixed * decay(t, 0.05, 0.004) + 0.3 * glide(t, 640, 300) * decay(t, 0.04)


def graze() -> np.ndarray:
    duration = 0.08
    t = t_axis(duration)
    hiss = band(noise(duration), 3500, 7000) * decay(t, 0.012)
    chime = np.sin(2 * np.pi * 2637 * t) * decay(t, 0.02) + 0.3 * np.sin(2 * np.pi * 3951 * t) * decay(t, 0.012)
    return 0.6 * hiss + 0.35 * chime


def enemy_hit() -> np.ndarray:
    return wood(820, 0.05, 0.010)


def ui_move() -> np.ndarray:
    return wood(1320, 0.04, 0.006)


# ---- medium events -----------------------------------------------------------

def enemy_down() -> np.ndarray:
    duration = 0.28
    t = t_axis(duration)
    source = noise(duration)
    sweep = np.clip(t / 0.12, 0, 1)
    paper = (lowpass(source, 6000) * (1 - sweep) + lowpass(source, 900) * sweep) * decay(t, 0.05, 0.002)
    pon = glide(t, 330, 150, 0.6) * decay(t, 0.06, 0.002)
    return 0.7 * paper + 0.6 * pon


def pickup(power_item: bool) -> np.ndarray:
    if power_item:
        return place(0.2, (0, 0.8, pluck(1046.5, 0.15, 0.6)), (0.035, 0.7, pluck(1568.0, 0.16, 0.7)))
    return place(0.14, (0, 1.0, pluck(1568.0, 0.13, 0.7)))


def confirm() -> np.ndarray:
    return place(0.22, (0, 1.0, wood(1900, 0.08, 0.014)), (0.07, 0.9, wood(2300, 0.08, 0.014)),
                 (0.07, 0.35, pluck(1174.7, 0.15, 0.5)))


def pause() -> np.ndarray:
    return place(0.18, (0, 1.0, wood(700, 0.1, 0.025)), (0.06, 0.6, wood(520, 0.1, 0.025)))


def cancel() -> np.ndarray:
    return place(0.16, (0, 0.9, wood(900, 0.08, 0.02)), (0.05, 0.7, wood(600, 0.1, 0.02)))


def extend() -> np.ndarray:
    notes = [784.0, 987.8, 1174.7, 1568.0]
    parts = [(index * 0.07, 0.8, pluck(freq, 0.5, 0.6)) for index, freq in enumerate(notes)]
    return place(1.0, *parts, (0.21, 0.35, bell(1568.0, 0.75, 0.4)))


# ---- big events --------------------------------------------------------------

def taiko(duration: float = 0.8) -> np.ndarray:
    t = t_axis(duration)
    body = glide(t, 95, 52, 0.3) * decay(t, 0.25, 0.002)
    skin = np.sin(2 * np.pi * 180 * t) * decay(t, 0.05, 0.001)
    slap = lowpass(noise(duration), 1800) * decay(t, 0.015)
    return body + 0.35 * skin + 0.4 * slap


def gong(freq: float, duration: float, tau: float) -> np.ndarray:
    return bell(freq, duration, tau, ratios=(1.0, 1.47, 2.09, 2.56, 3.21, 4.1))


def bomb() -> np.ndarray:
    duration = 1.8
    t = t_axis(duration)
    source = noise(duration)
    progress = np.clip(t / 0.9, 0, 1)
    wind = (band(source, 250, 700) * (1 - progress) + band(source, 900, 2600) * progress)
    wind *= np.sin(np.pi * np.clip(t / 1.6, 0, 1)) ** 2
    return place(duration, (0, 1.0, taiko(0.9)), (0, 0.55, wind), (0.02, 0.35, gong(150, 1.7, 0.9)))


def spell_declare() -> np.ndarray:
    duration = 1.3
    t = t_axis(0.3)
    stamp = 0.9 * np.sin(2 * np.pi * 90 * t) * decay(t, 0.06, 0.001) + 0.6 * band(noise(0.3), 700, 3000) * decay(t, 0.02)
    triad = [pitch("D5"), pitch("A5"), pitch("Eb6")]
    plucks = [(0.09 + index * 0.05, 0.55, pluck(440 * 2 ** ((note - 69) / 12), 1.0, 0.7)) for index, note in enumerate(triad)]
    return place(duration, (0, 1.0, stamp), *plucks, (0.2, 0.25, bell(1244.5, 1.0, 0.5)))


def phase_break() -> np.ndarray:
    duration = 1.4
    t = t_axis(0.2)
    tear = band(noise(0.2), 2000, 6000) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 38 * t))) * decay(t, 0.06, 0.002)
    chord = bell(1174.7, 1.3, 0.55) + 0.8 * bell(1760.0, 1.3, 0.45)
    return place(duration, (0, 0.8, tear), (0, 0.9, taiko(0.6)), (0.03, 0.45, chord))


def player_hit() -> np.ndarray:
    duration = 0.8
    t_blip = t_axis(0.06)
    blip = np.tanh(3 * np.sin(2 * np.pi * 1760 * t_blip)) * decay(t_blip, 0.03, 0.001)
    t_fall = t_axis(0.7)
    vibrato = 1 + 0.02 * np.sin(2 * np.pi * 11 * t_fall)
    freq = 1400 * (180 / 1400) ** (t_fall / t_fall[-1]) * vibrato
    fall = np.sin(2 * np.pi * np.cumsum(freq) / RATE) * decay(t_fall, 0.28, 0.004)
    burst = lowpass(noise(0.4), 3000) * decay(t_axis(0.4), 0.08)
    return place(duration, (0, 0.5, blip), (0.04, 0.7, fall), (0.04, 0.45, burst), (0.04, 0.6, taiko(0.5)))


# ---- jingles (FluidSynth) ------------------------------------------------------

def jingle(name: str, bpm: float, parts: list, seconds: float) -> np.ndarray:
    """parts: [(program, [(start_16th, len_16th, note_name, velocity)])]."""
    song = Song(bpm, 4)
    for channel, (program, notes) in enumerate(parts):
        song.channel(channel, program, 110, 64, 70)
        for start, length, note, velocity in notes:
            song.add(channel, start, length, pitch(note), velocity)
    midi_path = CACHE / f"jingle_{name}.mid"
    wav_path = CACHE / f"jingle_{name}.wav"
    song.write(midi_path, repeats=1)
    subprocess.run(["fluidsynth", "-ni", "-q", "-C0", "-R1", "-g", "0.5", "-r", str(RATE),
                    "-o", "audio.file.format=float", "-F", str(wav_path), SOUNDFONT, str(midi_path)], check=True)
    _, data = wavfile.read(wav_path)
    mono = data.astype(np.float64).mean(axis=1)[:int(seconds * RATE)]
    fade = int(0.3 * RATE)
    mono[-fade:] *= np.linspace(1, 0, fade) ** 2
    return mono


def stage_clear() -> np.ndarray:
    koto = [(0, 2, "A4", 90), (2, 2, "C5", 90), (4, 2, "E5", 95), (6, 2, "A5", 100), (8, 12, "E6", 105)]
    pad = [(0, 20, "A3", 70), (0, 20, "E4", 70), (8, 12, "C#5", 70)]
    return jingle("stage_clear", 120, [(107, koto), (49, pad)], 2.6)


def game_clear() -> np.ndarray:
    koto = [(0, 2, "G4", 90), (2, 2, "A4", 90), (4, 2, "B4", 92), (6, 2, "D5", 95), (8, 2, "E5", 98),
            (10, 2, "G5", 100), (12, 4, "A5", 104), (16, 16, "G5", 108)]
    flute = [(8, 8, "D6", 80), (16, 16, "B5", 84)]
    pad = [(0, 16, "C4", 64), (0, 16, "E4", 64), (0, 16, "G4", 64), (16, 16, "G3", 70), (16, 16, "D4", 70), (16, 16, "B4", 70)]
    bells = [(16, 16, "G5", 70)]
    return jingle("game_clear", 112, [(107, koto), (77, flute), (49, pad), (14, bells)], 4.2)


def game_over() -> np.ndarray:
    flute = [(0, 4, "A5", 90), (4, 2, "G5", 84), (6, 2, "Eb5", 80), (8, 4, "D5", 84), (12, 12, "D4", 80)]
    koto = [(0, 2, "D3", 80), (8, 2, "Bb2", 76), (12, 12, "D2", 84)]
    return jingle("game_over", 84, [(77, flute), (107, koto)], 3.6)


SOUNDS = {
    "shot": lambda: shot(False), "shot_focus": lambda: shot(True),
    "enemy_fire": lambda: enemy_puff(700, 1800, 0.09, 520), "enemy_ring": lambda: enemy_puff(400, 1200, 0.13, 330),
    "enemy_spiral": enemy_spiral, "graze": graze, "enemy_hit": enemy_hit, "enemy_down": enemy_down,
    "pickup": lambda: pickup(False), "pickup_power": lambda: pickup(True), "extend": extend,
    "ui_move": ui_move, "confirm": confirm, "pause": pause, "cancel": cancel,
    "bomb": bomb, "spell_declare": spell_declare, "phase_break": phase_break, "player_hit": player_hit,
    "stage_clear": stage_clear, "game_clear": game_clear, "game_over": game_over,
}


def finish(samples: np.ndarray) -> np.ndarray:
    fade = min(len(samples) // 4, int(0.01 * RATE))
    samples = samples - np.mean(samples)
    samples[-fade:] *= np.linspace(1, 0, fade)
    return samples * (PEAK / np.max(np.abs(samples)))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    CACHE.mkdir(parents=True, exist_ok=True)
    for name, build in SOUNDS.items():
        samples = finish(build())
        write_wav16(samples, RATE, OUT / f"{name}.wav")
        print(f"{name}: {len(samples) / RATE:.2f}s")


if __name__ == "__main__":
    main()
