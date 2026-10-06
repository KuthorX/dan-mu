#!/usr/bin/env python3
"""Builds the display fonts in fonts/ from their OFL sources.

Noto Serif SC (instanced to Bold) and Ma Shan Zheng are subset to the characters
used in i18n/translations.csv plus printable ASCII, so the web build stays small.
Every Label also falls back to the full Noto Sans CJK SC, so a character missing
from a subset still renders. Re-run after adding new text to translations.csv:

    https_proxy=http://127.0.0.1:7890 python3 tools/art/subset_fonts.py
"""
import os
import pathlib
import shutil
import subprocess
import urllib.request

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = pathlib.Path(__file__).resolve().parents[2]
CACHE = ROOT / "tools" / "art" / ".cache"
FONTS = ROOT / "fonts"
LICENSES = FONTS / "licenses"
GOOGLE_FONTS = "https://raw.githubusercontent.com/google/fonts/main/ofl/"
SOURCES = {
    "NotoSerifSC.ttf": "notoserifsc/NotoSerifSC%5Bwght%5D.ttf",
    "MaShanZheng-Regular.ttf": "mashanzheng/MaShanZheng-Regular.ttf",
}
LICENSE_SOURCES = {
    "NotoSerifSC-OFL.txt": "notoserifsc/OFL.txt",
    "MaShanZheng-OFL.txt": "mashanzheng/OFL.txt",
}
EXTRA_CHARS = "「」『』·・×∞…—–→←↑↓《》、。，！？：；（）％／＋"


def fetch(name: str, path: str, target_dir: pathlib.Path) -> pathlib.Path:
    target = target_dir / name
    if not target.exists():
        target_dir.mkdir(parents=True, exist_ok=True)
        print("download", path)
        with urllib.request.urlopen(GOOGLE_FONTS + path, timeout=300) as response:
            target.write_bytes(response.read())
    return target


def used_characters() -> str:
    text = (ROOT / "i18n" / "translations.csv").read_text(encoding="utf-8")
    chars = set(text) | set(EXTRA_CHARS) | {chr(code) for code in range(0x20, 0x7F)}
    chars.discard("\n")
    chars.discard("\r")
    return "".join(sorted(chars))


def subset(source: pathlib.Path, target: pathlib.Path, chars: str) -> None:
    text_file = CACHE / "chars.txt"
    text_file.write_text(chars, encoding="utf-8")
    subprocess.run([
        "pyftsubset", str(source), f"--text-file={text_file}",
        f"--output-file={target}", "--layout-features=*", "--no-hinting",
    ], check=True)
    print("wrote", target.relative_to(ROOT), os.path.getsize(target) // 1024, "KiB")


def main() -> None:
    sources = {name: fetch(name, path, CACHE) for name, path in SOURCES.items()}
    for name, path in LICENSE_SOURCES.items():
        fetch(name, path, LICENSES)
    chars = used_characters()
    serif_bold = CACHE / "NotoSerifSC-Bold.ttf"
    instancer.instantiateVariableFont(TTFont(sources["NotoSerifSC.ttf"]), {"wght": 700}).save(serif_bold)
    subset(serif_bold, FONTS / "NotoSerifSC-Bold-subset.ttf", chars)
    subset(sources["MaShanZheng-Regular.ttf"], FONTS / "MaShanZheng-subset.ttf", chars)


if __name__ == "__main__":
    main()
