"""Shared helpers for the audio tools: paths, loudness measurement, encoders."""
import pathlib
import re
import subprocess

import numpy as np
from scipy.io import wavfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
CACHE = ROOT / "tools" / "audio" / ".cache"


def _ebur128(path: pathlib.Path) -> dict:
    result = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-af", "ebur128=peak=true", "-f", "null", "-"],
        capture_output=True, text=True, check=True,
    )
    summary = result.stderr.split("Summary:")[-1]
    integrated = re.search(r"I:\s+(-?[\d.]+|-inf) LUFS", summary).group(1)
    peak = re.search(r"Peak:\s+(-?[\d.]+|-inf) dBFS", summary).group(1)
    return {"lufs": float(integrated), "true_peak": float(peak)}


def measure(path: pathlib.Path) -> dict:
    return _ebur128(path)


def loudness(samples: np.ndarray, rate: int) -> float:
    temp = CACHE / "_measure.wav"
    wavfile.write(temp, rate, samples.astype(np.float32))
    return _ebur128(temp)["lufs"]


def write_wav16(samples: np.ndarray, rate: int, target: pathlib.Path) -> None:
    pcm = np.clip(np.round(samples * 32767.0), -32768, 32767).astype(np.int16)
    wavfile.write(target, rate, pcm)


def write_mp3(samples: np.ndarray, rate: int, target: pathlib.Path, bitrate: int) -> None:
    temp = CACHE / "_encode.wav"
    write_wav16(samples, rate, temp)
    subprocess.run(["lame", "--quiet", "--cbr", "-b", str(bitrate), "-q", "2", str(temp), str(target)], check=True)
