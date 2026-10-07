#!/usr/bin/env python3
"""Builds the display fonts in fonts/ from their OFL sources.

Noto Serif SC (instanced to Bold), Ma Shan Zheng and the Noto Sans CJK SC body
font are subset to every character used in i18n/translations.csv, scripts/ and
scenes/ plus printable ASCII, so the build stays small (the full Noto Sans CJK SC
is 16 MB). Re-run after adding new text to translations.csv or any script:

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
NOTO_CJK = "https://raw.githubusercontent.com/notofonts/noto-cjk/main/Sans/"
SOURCES = {
    "NotoSerifSC.ttf": GOOGLE_FONTS + "notoserifsc/NotoSerifSC%5Bwght%5D.ttf",
    "MaShanZheng-Regular.ttf": GOOGLE_FONTS + "mashanzheng/MaShanZheng-Regular.ttf",
    "NotoSansCJKsc-Regular.otf": NOTO_CJK + "OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf",
}
LICENSE_SOURCES = {
    "NotoSerifSC-OFL.txt": GOOGLE_FONTS + "notoserifsc/OFL.txt",
    "MaShanZheng-OFL.txt": GOOGLE_FONTS + "mashanzheng/OFL.txt",
    "NotoSansCJK-OFL.txt": NOTO_CJK + "LICENSE",
}
TEXT_GLOBS = ["i18n/*.csv", "scripts/*.gd", "scenes/*.tscn"]
EXTRA_CHARS = "「」『』·・×∞…—–→←↑↓《》、。，！？：；（）％／＋"


def fetch(name: str, url: str, target_dir: pathlib.Path) -> pathlib.Path:
    target = target_dir / name
    if not target.exists():
        target_dir.mkdir(parents=True, exist_ok=True)
        print("download", url)
        with urllib.request.urlopen(url, timeout=300) as response:
            target.write_bytes(response.read())
    return target


def used_characters() -> str:
    chars = set(EXTRA_CHARS) | {chr(code) for code in range(0x20, 0x7F)}
    for pattern in TEXT_GLOBS:
        for path in ROOT.glob(pattern):
            chars |= set(path.read_text(encoding="utf-8"))
    chars = {char for char in chars if char.isprintable() and char != "\ufeff"}
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
    subset(sources["NotoSansCJKsc-Regular.otf"], FONTS / "NotoSansCJKsc-Regular-subset.otf", chars)
    report_missing(FONTS / "NotoSansCJKsc-Regular-subset.otf", chars)


def report_missing(font_path: pathlib.Path, chars: str) -> None:
    cmap = TTFont(font_path).getBestCmap()
    missing = [char for char in chars if not char.isspace() and ord(char) not in cmap]
    print(font_path.name, "missing glyphs:", len(missing), "".join(missing))


if __name__ == "__main__":
    main()
