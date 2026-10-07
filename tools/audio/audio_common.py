"""Shared helpers for the audio tools: paths and ffmpeg loudness measurement."""
import pathlib
import re
import subprocess


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
