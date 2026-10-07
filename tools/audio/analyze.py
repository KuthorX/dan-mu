#!/usr/bin/env python3
"""Reports duration, loudness, true peak and loop-seam continuity for audio/ files,
and writes spectrograms to tools/audio/.cache/spectra/. No playback involved.

    python3 tools/audio/analyze.py
"""
import pathlib
import subprocess
import sys

import numpy as np
from scipy.io import wavfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from audio_common import CACHE, ROOT, measure  # noqa: E402

SPECTRA = CACHE / "spectra"


def decode(path: pathlib.Path) -> tuple:
    temp = CACHE / "_decode.wav"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(path), "-c:a", "pcm_f32le", str(temp)], check=True)
    rate, data = wavfile.read(temp)
    return rate, data.reshape(len(data), -1).astype(np.float64)


def seam_report(data: np.ndarray, rate: int) -> str:
    """Compares the jump across the loop seam with ordinary sample-to-sample steps
    (a click would exceed them). The RMS of the last vs first 50 ms is informational:
    a downbeat at the loop start is legitimately louder than the bar before it."""
    window = int(0.05 * rate)
    steps = np.abs(np.diff(data, axis=0)).max(axis=1)
    typical = np.percentile(steps, 99.9)
    jump = np.abs(data[-1] - data[0]).max()
    tail_rms = np.sqrt(np.mean(data[-window:] ** 2))
    head_rms = np.sqrt(np.mean(data[:window] ** 2))
    ratio_db = 20 * np.log10(max(tail_rms, 1e-9) / max(head_rms, 1e-9))
    verdict = "ok" if jump <= typical else "CLICK?"
    return f"seam jump {jump:.4f} vs p99.9 step {typical:.4f} {verdict}; tail/head RMS {ratio_db:+.1f} dB"


def main() -> None:
    SPECTRA.mkdir(parents=True, exist_ok=True)
    for folder in ("music", "sfx"):
        print(f"== {folder}")
        for path in sorted((ROOT / "audio" / folder).glob("*")):
            if path.suffix not in (".mp3", ".wav"):
                continue
            rate, data = decode(path)
            stats = measure(path)
            rms = 20 * np.log10(np.sqrt(np.mean(data ** 2)))
            lufs = f"{stats['lufs']:6.1f} LUFS" if stats["lufs"] > -70 else "  (<0.4s)  "
            line = f"{path.name:22s} {len(data) / rate:6.2f}s  {lufs}  RMS {rms:6.1f} dBFS  TP {stats['true_peak']:5.1f} dBTP"
            if folder == "music":
                line += "  " + seam_report(data, rate)
            print(line)
            subprocess.run([
                "ffmpeg", "-y", "-loglevel", "error", "-i", str(path),
                "-lavfi", "showspectrumpic=s=800x300:legend=0", str(SPECTRA / f"{path.stem}.png"),
            ], check=True)


if __name__ == "__main__":
    main()
