#!/usr/bin/env python3
"""Builds DanMu's sound effects into audio/sfx/*.wav (44.1 kHz 16-bit; mono effects,
stereo jingles) by layering preset hits from the SFX sheet with numpy synthesis.

Palette: paper and wood for frequent events (brush flicks, wood blocks, Plucked String
"koto" plucks, Ceramic ticks), bronze and taiko for big ones (Wudang Mountain bell,
MS Basic taiko). Every effect layers at least two sources, so none is a bare preset hit.
Jingles are short koto / pan-flute phrases cut from the same sheet render.

    arch -arm64 /tmp/audiokit/venv/bin/python tools/audio/sfx_sheet.py     # sheet MIDI + spec
    lockf -t 3600 /tmp/audiokit/render.lock arch -arm64 /tmp/audiokit/venv/bin/python \
        /tmp/audiokit/render.py tools/audio/.cache/sfx_sheet/sheet.json
    arch -arm64 /tmp/audiokit/venv/bin/python tools/audio/sfx.py            # layer + normalise
"""
import json
import pathlib
import sys

import numpy as np
import pedalboard
import pyloudnorm
import soundfile
from scipy import signal

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from sfx_sheet import JINGLES, WORK as SHEET  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
RATE = 44100
TARGET_LUFS = -16.0
CEILING_DBTP = -1.0
MEASURE_MIN = 0.4  # pyloudnorm needs one 400 ms block; shorter effects are zero-padded to it
OUT = ROOT / "audio" / "sfx"
rng = np.random.default_rng(7)


# ---- numpy synthesis ------------------------------------------------------------

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


def taper(samples: np.ndarray, seconds: float = 0.02) -> np.ndarray:
    """1 ms fade-in and a squared fade-out, so no layer starts or ends on a click."""
    out = np.array(samples, dtype=np.float64)
    length = min(len(out) // 2, int(seconds * RATE))
    head = min(len(out) // 4, int(0.001 * RATE))
    if length:
        out[-length:] *= np.linspace(1, 0, length)[(slice(None),) + (None,) * (out.ndim - 1)] ** 2
    if head:
        out[:head] *= np.linspace(0, 1, head)[(slice(None),) + (None,) * (out.ndim - 1)]
    return out


def norm(samples: np.ndarray) -> np.ndarray:
    peak = np.max(np.abs(samples))
    return samples / peak if peak > 0 else samples


def place(total: float, *parts, channels: int = 1) -> np.ndarray:
    """Mixes (offset_seconds, gain, samples) parts into one buffer; each part is
    peak-normalised first, so `gain` is the layer's level relative to the others."""
    shape = (int(total * RATE),) if channels == 1 else (int(total * RATE), channels)
    out = np.zeros(shape)
    for offset, gain, samples in parts:
        start = int(offset * RATE)
        end = min(len(out), start + len(samples))
        out[start:end] += gain * taper(norm(samples)[:end - start])
    return out


def wood(freq: float, duration: float = 0.06, tau: float = 0.012) -> np.ndarray:
    t = t_axis(duration)
    tone = np.sin(2 * np.pi * freq * t) + 0.4 * np.sin(2 * np.pi * freq * 2.71 * t) * np.exp(-t / (tau * 0.4))
    click = band(noise(duration), 1500, 5000) * decay(t, 0.002)
    return tone * decay(t, tau) + 0.5 * click


def brush(duration: float, low: float, high: float, thump: float) -> np.ndarray:
    t = t_axis(duration)
    flick = lowpass(band(noise(duration), low, high), 5000) * decay(t, 0.009)
    return flick + 0.35 * np.sin(2 * np.pi * thump * t) * decay(t, 0.008)


def puff(low: float, high: float, duration: float, tone: float) -> np.ndarray:
    t = t_axis(duration)
    breath = band(noise(duration), low, high) * decay(t, duration * 0.3, 0.006)
    return breath + 0.4 * glide(t, tone, tone * 0.75) * decay(t, duration * 0.25, 0.004)


def spiral_sweep(duration: float = 0.18) -> np.ndarray:
    t = t_axis(duration)
    source = noise(duration)
    sweep = t / t[-1]
    mixed = band(source, 1600, 2800) * (1 - sweep) + band(source, 600, 1200) * sweep
    return mixed * decay(t, 0.05, 0.004)


def hiss(duration: float) -> np.ndarray:
    t = t_axis(duration)
    return band(noise(duration), 3500, 7000) * decay(t, 0.012)


def paper_burst(duration: float) -> np.ndarray:
    t = t_axis(duration)
    source = noise(duration)
    sweep = np.clip(t / 0.12, 0, 1)
    return (lowpass(source, 6000) * (1 - sweep) + lowpass(source, 900) * sweep) * decay(t, 0.05, 0.002)


def pon(duration: float) -> np.ndarray:
    t = t_axis(duration)
    return glide(t, 330, 150, 0.6) * decay(t, 0.06, 0.002)


def wind(duration: float) -> np.ndarray:
    t = t_axis(duration)
    source = noise(duration)
    progress = np.clip(t / (duration / 2), 0, 1)
    gust = band(source, 250, 700) * (1 - progress) + band(source, 900, 2600) * progress
    return gust * np.sin(np.pi * np.clip(t / (duration * 0.9), 0, 1)) ** 2


def stamp(duration: float = 0.3) -> np.ndarray:
    t = t_axis(duration)
    return 0.9 * np.sin(2 * np.pi * 90 * t) * decay(t, 0.06, 0.001) + 0.6 * band(noise(duration), 700, 3000) * decay(t, 0.02)


def tear(duration: float = 0.2) -> np.ndarray:
    t = t_axis(duration)
    return band(noise(duration), 2000, 6000) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 38 * t))) * decay(t, 0.06, 0.002)


def pichuun() -> tuple:
    """Short blip and a falling vibrato tone 1.4 kHz -> 180 Hz (the classic death cue)."""
    t_blip = t_axis(0.06)
    blip = np.tanh(3 * np.sin(2 * np.pi * 1760 * t_blip)) * decay(t_blip, 0.03, 0.001)
    t_fall = t_axis(0.7)
    vibrato = 1 + 0.02 * np.sin(2 * np.pi * 11 * t_fall)
    freq = 1400 * (180 / 1400) ** (t_fall / t_fall[-1]) * vibrato
    fall = np.sin(2 * np.pi * np.cumsum(freq) / RATE) * decay(t_fall, 0.28, 0.004)
    burst = lowpass(noise(0.4), 3000) * decay(t_axis(0.4), 0.08)
    return blip, fall, burst


# ---- preset layers from the sheet render -------------------------------------------

class Sheet:
    """Dry stems of the SFX sheet; `cut` returns one event's window from one stem."""

    def __init__(self) -> None:
        self.windows = json.loads((SHEET / "windows.json").read_text())
        self.stems = {}

    def _stem(self, sound: str) -> np.ndarray:
        if sound not in self.stems:
            data, rate = soundfile.read(SHEET / "stems" / f"{sound}.wav", dtype="float64")
            if rate != RATE:
                raise SystemExit(f"{sound}: unexpected rate {rate}")
            self.stems[sound] = data
        return self.stems[sound]

    def cut(self, event: str, sound: str, seconds: float, stereo: bool = False) -> np.ndarray:
        start, length = self.windows[event]
        first = int(start * RATE)
        piece = self._stem(sound)[first:first + int(min(seconds, length) * RATE)]
        if not np.any(piece):
            raise SystemExit(f"{event}/{sound}: silent layer")
        return piece if stereo else piece.mean(axis=1)


def fx(samples: np.ndarray, *plugins) -> np.ndarray:
    board = pedalboard.Pedalboard(list(plugins))
    data = samples.T if samples.ndim == 2 else samples[None, :]
    out = board(data.astype(np.float32), RATE, reset=True).astype(np.float64)
    return out.T if samples.ndim == 2 else out[0]


def build(sheet: Sheet) -> dict:
    cut = sheet.cut
    hp = pedalboard.HighpassFilter
    room = pedalboard.Reverb(room_size=0.35, wet_level=0.12, dry_level=0.9)
    hall = pedalboard.Reverb(room_size=0.8, wet_level=0.25, dry_level=0.85, width=1.0)
    sounds = {
        "shot": lambda: place(0.06, (0, 1.0, brush(0.05, 1400, 3800, 700)), (0, 0.15, cut("shot", "ceramic", 0.06))),
        "shot_focus": lambda: place(0.06, (0, 1.0, brush(0.05, 900, 2400, 520)), (0, 0.15, cut("shot_focus", "ceramic", 0.06))),
        "enemy_fire": lambda: place(0.12, (0, 0.8, cut("enemy_fire", "harp_wire", 0.12)), (0, 0.5, puff(700, 1800, 0.09, 520))),
        "enemy_ring": lambda: place(0.18, (0, 0.8, cut("enemy_ring", "harp_wire", 0.18)), (0, 0.55, puff(400, 1200, 0.13, 330))),
        "enemy_spiral": lambda: place(0.2, (0, 0.8, cut("enemy_spiral", "harp_wire", 0.2)), (0, 0.45, spiral_sweep())),
        "graze": lambda: place(0.1, (0, 0.6, hiss(0.08)), (0, 0.7, cut("graze", "ceramic", 0.1))),
        "enemy_hit": lambda: place(0.07, (0, 0.8, cut("enemy_hit", "gm_kit", 0.07)), (0, 0.6, wood(820, 0.05, 0.010))),
        "enemy_down": lambda: place(0.4, (0, 0.6, paper_burst(0.28)), (0, 0.5, pon(0.28)),
                                    (0, 0.7, fx(cut("enemy_down", "guzheng", 0.4), hp(cutoff_frequency_hz=150))),
                                    (0, 0.5, cut("enemy_down", "gm_kit", 0.1))),
        "pickup": lambda: place(0.2, (0, 1.0, cut("pickup", "guzheng", 0.2)), (0, 0.35, cut("pickup", "ceramic", 0.1))),
        "pickup_power": lambda: place(0.26, (0, 1.0, cut("pickup_power", "guzheng", 0.26)), (0, 0.35, cut("pickup_power", "ceramic", 0.15))),
        "extend": lambda: fx(place(1.1, (0, 1.0, cut("extend", "guzheng", 1.1)), (0.21, 0.55, cut("extend", "wudang", 0.89)[int(0.21 * RATE):])), room),
        "ui_move": lambda: place(0.05, (0, 0.6, wood(1320, 0.04, 0.006)), (0, 0.6, cut("ui_move", "ceramic", 0.05)),
                                 (0, 0.4, cut("ui_move", "gm_kit", 0.05))),
        "confirm": lambda: place(0.26, (0, 1.0, cut("confirm", "gm_kit", 0.26)), (0.07, 0.5, cut("confirm", "guzheng", 0.26)[int(0.07 * RATE):])),
        "pause": lambda: place(0.2, (0, 1.0, cut("pause", "gm_kit", 0.2)), (0, 0.4, wood(700, 0.1, 0.025))),
        "cancel": lambda: place(0.18, (0, 1.0, cut("cancel", "gm_kit", 0.18)), (0.05, 0.35, wood(600, 0.1, 0.02))),
        "bomb": lambda: place(1.8, (0, 1.0, cut("bomb", "gm_taiko", 1.2)), (0, 0.45, wind(1.8)),
                              (0.02, 0.6, cut("bomb", "wudang", 1.8)[int(0.02 * RATE):])),
        "spell_declare": lambda: fx(place(1.4, (0, 0.7, stamp()), (0, 0.8, cut("spell_declare", "gm_taiko", 0.6)),
                                          (0.09, 0.75, cut("spell_declare", "guzheng", 1.4)[int(0.09 * RATE):]),
                                          (0.2, 0.4, cut("spell_declare", "wudang", 1.4)[int(0.2 * RATE):])), room),
        "phase_break": lambda: place(1.4, (0, 0.6, tear()), (0, 0.85, cut("phase_break", "gm_taiko", 0.6)),
                                     (0.03, 0.6, cut("phase_break", "wudang", 1.4)[int(0.03 * RATE):])),
        "player_hit": lambda: _player_hit(cut),
        "stage_clear": lambda: _jingle(cut, "stage_clear", 2.8, {"guzheng": 1.0, "strings": 0.5, "wudang": 0.35}, hall),
        "game_clear": lambda: _jingle(cut, "game_clear", 4.4, {"guzheng": 1.0, "pan_flute": 0.6, "strings": 0.5, "wudang": 0.35}, hall),
        "game_over": lambda: _jingle(cut, "game_over", 3.8, {"pan_flute": 0.9, "guzheng": 0.8, "wudang": 0.3}, hall),
    }
    return sounds


def _player_hit(cut) -> np.ndarray:
    blip, fall, burst = pichuun()
    return place(0.8, (0, 0.45, blip), (0, 0.35, cut("player_hit", "harp_wire", 0.1)), (0.04, 0.7, fall),
                 (0.04, 0.4, burst), (0.04, 0.7, cut("player_hit", "gm_taiko", 0.76)[int(0.04 * RATE):]))


def _jingle(cut, event: str, seconds: float, gains: dict, reverb) -> np.ndarray:
    parts = [(0, gain, cut(event, sound, seconds, stereo=True)) for sound, gain in gains.items()]
    mixed = fx(place(seconds, *parts, channels=2), pedalboard.HighpassFilter(cutoff_frequency_hz=60), reverb)
    fade = int(0.35 * RATE)
    mixed[-fade:] *= (np.linspace(1, 0, fade) ** 2)[:, None]
    return mixed


# ---- levels -------------------------------------------------------------------

def true_peak_db(samples: np.ndarray) -> float:
    up = signal.resample_poly(samples, 4, 1, axis=0)
    return float(20 * np.log10(max(np.max(np.abs(up)), 1e-9)))


def loudness(samples: np.ndarray) -> float:
    minimum = int(MEASURE_MIN * RATE)
    if len(samples) < minimum:
        pad = [(0, minimum - len(samples))] + [(0, 0)] * (samples.ndim - 1)
        samples = np.pad(samples, pad)
    return float(pyloudnorm.Meter(RATE).integrated_loudness(samples))


def finish(samples: np.ndarray) -> np.ndarray:
    """No DC, -16 LUFS (short effects measured over 400 ms), never above -1 dBTP."""
    samples = samples - np.mean(samples, axis=0)
    samples = taper(samples, 0.01)
    gain_db = TARGET_LUFS - loudness(samples)
    samples = samples * 10 ** (gain_db / 20)
    over = true_peak_db(samples) - CEILING_DBTP
    if over > 0:
        samples = samples * 10 ** (-over / 20)
    return samples


def write_wav16(samples: np.ndarray, target: pathlib.Path) -> None:
    pcm = np.clip(np.round(samples * 32767.0), -32768, 32767).astype(np.int16)
    soundfile.write(target, pcm, RATE, subtype="PCM_16")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    sounds = build(Sheet())
    report = {}
    for name, make in sounds.items():
        samples = finish(make())
        if name not in JINGLES and samples.ndim != 1:
            raise SystemExit(f"{name}: effects must be mono")
        write_wav16(samples, OUT / f"{name}.wav")
        report[name] = {"seconds": round(len(samples) / RATE, 3), "lufs": round(loudness(samples), 1),
                        "true_peak": round(true_peak_db(samples), 1)}
        print(f"{name:14s} {report[name]}")
    (SHEET / "levels.json").write_text(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
