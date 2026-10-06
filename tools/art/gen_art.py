#!/usr/bin/env python3
"""Paints the raster art for DanMu ("Night Shrine Ofuda" direction).

Everything is procedural ink-and-paper painting, deterministic per seed:
  art/bg/stage{1..5}.png  hanging-scroll ink landscapes, tile vertically (560x1120)
  art/ui/ofuda.png        the bone-washi talisman strip that carries the HUD
  art/ui/sheet.png        washi sheet for pause / result / transition overlays
  art/ui/card.png         small washi card for reward choices
  art/ui/scroll.png       dialogue paper strip
  art/ui/seal.png         vermilion seal stamp (tinted in engine)

Backgrounds stay below ~22% luminance so bullets always read on top of them.
Run:  python3 tools/art/gen_art.py
"""
import math
import pathlib

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[2]
BG_DIR = ROOT / "art" / "bg"
UI_DIR = ROOT / "art" / "ui"
FIELD_W, FIELD_H = 560, 1120

PAPER = np.array([226, 214, 188], dtype=np.float32) / 255.0
INK = np.array([24, 18, 18], dtype=np.float32) / 255.0


# ---------------------------------------------------------------- noise helpers
def periodic_value_noise(rng, height, width, cells_y, cells_x):
    """Smooth value noise that wraps in both axes (so textures tile)."""
    grid = rng.random((cells_y, cells_x)).astype(np.float32)
    ys = np.arange(height, dtype=np.float32) * cells_y / height
    xs = np.arange(width, dtype=np.float32) * cells_x / width
    y0 = np.floor(ys).astype(int)
    x0 = np.floor(xs).astype(int)
    fy = ys - y0
    fx = xs - x0
    fy = fy * fy * (3.0 - 2.0 * fy)
    fx = fx * fx * (3.0 - 2.0 * fx)
    y1 = (y0 + 1) % cells_y
    x1 = (x0 + 1) % cells_x
    y0 %= cells_y
    x0 %= cells_x
    a = grid[np.ix_(y0, x0)]
    b = grid[np.ix_(y0, x1)]
    c = grid[np.ix_(y1, x0)]
    d = grid[np.ix_(y1, x1)]
    top = a + (b - a) * fx[None, :]
    bottom = c + (d - c) * fx[None, :]
    return top + (bottom - top) * fy[:, None]


def fbm(rng, height, width, base_y, base_x, octaves=5, gain=0.5):
    total = np.zeros((height, width), dtype=np.float32)
    amplitude = 1.0
    norm = 0.0
    for octave in range(octaves):
        scale = 2 ** octave
        total += amplitude * periodic_value_noise(rng, height, width, base_y * scale, base_x * scale)
        norm += amplitude
        amplitude *= gain
    return total / norm


def save_rgb(array, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.clip(array * 255.0, 0, 255).astype(np.uint8), "RGB").save(path, optimize=True)


def save_rgba(rgb, alpha, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    data = np.dstack([rgb, alpha[..., None]])
    Image.fromarray(np.clip(data * 255.0, 0, 255).astype(np.uint8), "RGBA").save(path, optimize=True)


# ---------------------------------------------------------------- backgrounds
STAGES = {
    1: {"ink": (7, 8, 14), "mist": (36, 42, 66), "rim": (110, 120, 156), "motif": "stars"},
    2: {"ink": (16, 8, 8), "mist": (92, 40, 22), "rim": (190, 96, 50), "motif": "furnace"},
    3: {"ink": (12, 10, 18), "mist": (56, 48, 74), "rim": (130, 116, 160), "motif": "walls"},
    4: {"ink": (17, 6, 10), "mist": (74, 24, 34), "rim": (170, 70, 76), "motif": "eclipse"},
    5: {"ink": (5, 13, 15), "mist": (22, 66, 66), "rim": (70, 170, 160), "motif": "gate"},
}
BAND_COUNT = 4


def ridge_line(rng, width, lift):
    """A hanging-scroll ridge: a few soft peaks pushed toward the edges plus fine detail."""
    xs = np.linspace(0.0, 1.0, width, dtype=np.float32)
    ridge = np.zeros(width, dtype=np.float32)
    for _peak in range(int(rng.integers(2, 4))):
        side = rng.choice([-1.0, 1.0])
        centre = 0.5 + side * rng.uniform(0.18, 0.5)
        spread = rng.uniform(0.07, 0.16)
        ridge = np.maximum(ridge, rng.uniform(0.55, 1.0) * np.exp(-((xs - centre) / spread) ** 2 * 0.9))
    # brush-wobble detail: a smoothed random walk, not sines, so no two ridges rhyme
    walk = np.cumsum(rng.normal(0.0, 1.0, width)).astype(np.float32)
    walk -= np.linspace(walk[0], walk[-1], width, dtype=np.float32)
    kernel = np.hanning(9).astype(np.float32)
    walk = np.convolve(walk, kernel / kernel.sum(), mode="same")
    detail = walk / (np.abs(walk).max() + 1e-6) * 0.1
    return (ridge + detail * (0.35 + ridge)) * lift


def paint_stage(stage, spec, rng):
    height, width = FIELD_H, FIELD_W
    ink = np.array(spec["ink"], dtype=np.float32) / 255.0
    mist = np.array(spec["mist"], dtype=np.float32) / 255.0
    rim = np.array(spec["rim"], dtype=np.float32) / 255.0
    rows = np.arange(height, dtype=np.float32)[:, None]
    nearest_depth = np.full((height, width), 1e9, dtype=np.float32)
    mist_amount = np.zeros((height, width), dtype=np.float32)
    wet_edge = np.zeros((height, width), dtype=np.float32)
    ridges = []
    for band in range(BAND_COUNT):
        base = height * (band + 0.85) / BAND_COUNT + rng.uniform(-24.0, 24.0)
        ridge = base - ridge_line(rng, width, rng.uniform(110.0, 190.0))
        ridges.append(ridge)
        depth = (rows - ridge[None, :]) % height
        above = (ridge[None, :] - rows) % height
        nearest_depth = np.minimum(nearest_depth, depth)
        mist_amount = np.maximum(mist_amount, np.exp(-above / 150.0) * (1.0 - np.exp(-above / 10.0)))
        # ink pools where the brush first touched: a dark wet edge just under the ridge
        wet_edge = np.maximum(wet_edge, np.exp(-depth / 9.0) * (depth < 40))
    # dry-brush cun strokes: long vertical streaks where the hairs ran out of ink
    streaks = fbm(rng, height, width, 5, 150, octaves=2)
    # strokes start at the ridge and lift off down the slope
    dry = np.clip((streaks - 0.55) * 4.0, 0.0, 1.0) * np.exp(-nearest_depth / 90.0) * (nearest_depth > 3.0)
    grain = fbm(rng, height, width, 40, 20, octaves=3)
    body = ink[None, None, :] * (0.92 + 0.12 * grain[..., None])
    # mist pools at each mountain's foot and thins upward into the ridge above
    haze = (mist_amount * 0.55).clip(0.0, 1.0) ** 1.5
    # where the brush ran dry, the mist behind shows through the stroke
    haze = np.maximum(haze, dry * 0.22)
    field = body * (1.0 - haze[..., None]) + mist[None, None, :] * haze[..., None]
    field *= (1.0 - 0.55 * wet_edge)[..., None]
    image = Image.fromarray(np.clip(field * 255.0, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    rim_rgb = tuple(int(v * 255) for v in rim)
    ink_rgb = tuple(int(v * 255 * 0.7) for v in ink)
    motif = spec["motif"]
    for repeat in (-height, 0, height):
        if motif == "eclipse":
            centre_x, centre_y = width * 0.5, height * 0.34 + repeat
            draw.ellipse((centre_x - 133, centre_y - 133, centre_x + 133, centre_y + 133), outline=rim_rgb + (70,), width=2)
            draw.ellipse((centre_x - 130, centre_y - 130, centre_x + 130, centre_y + 130), fill=ink_rgb + (255,))
    if motif == "stars":
        for _ in range(180):
            x, y = int(rng.integers(0, width)), int(rng.integers(0, height))
            draw.point((x, y), fill=(190, 200, 230, int(rng.integers(50, 130))))
    for band, ridge in enumerate(ridges):
        if motif == "walls" and band % 2 == 0:
            start = int(rng.integers(20, 160))
            stop = min(width - 10, start + int(rng.integers(180, 320)))
            for repeat in (-height, 0, height):
                top_line = [(x, float(ridge[x]) - 20 + repeat) for x in range(start, stop, 4)]
                bottom_line = [(x, float(ridge[x]) + 40 + repeat) for x in range(stop - 4, start - 4, -4)]
                draw.polygon(top_line + bottom_line, fill=ink_rgb + (235,))
                for x in range(start, stop - 8, 16):
                    top = float(ridge[x]) - 20 + repeat
                    draw.rectangle((x, top - 8, x + 8, top), fill=ink_rgb + (235,))
                tower = start + (stop - start) // 2
                tower_top = float(ridge[tower]) - 58 + repeat
                draw.rectangle((tower - 12, tower_top, tower + 12, tower_top + 50), fill=ink_rgb + (235,))
                draw.polygon([(tower - 20, tower_top), (tower + 20, tower_top), (tower, tower_top - 18)], fill=ink_rgb + (235,))
        if motif == "gate" and band % 2 == 1:
            x = int(rng.integers(60, width - 200))
            ground = float(ridge[min(x + 70, width - 1)]) + 10
            for repeat in (-height, 0, height):
                g = ground + repeat
                draw.rectangle((x + 18, g - 120, x + 30, g), fill=ink_rgb + (240,))
                draw.rectangle((x + 112, g - 120, x + 124, g), fill=ink_rgb + (240,))
                draw.polygon([(x, g - 128), (x + 142, g - 128), (x + 136, g - 118), (x + 6, g - 118)], fill=ink_rgb + (240,))
                draw.rectangle((x + 10, g - 104, x + 132, g - 98), fill=ink_rgb + (240,))
        if motif == "furnace":
            # smoke columns rising from the furnace peaks
            peak = int(np.argmin(ridge))
            for repeat in (-height, 0, height):
                top = float(ridge[peak]) + repeat
                for puff in range(7):
                    radius = 10 + puff * 7
                    offset = math.sin(puff * 1.3) * 10
                    cy = top - 14 - puff * 20
                    draw.ellipse((peak + offset - radius, cy - radius * 0.6, peak + offset + radius, cy + radius * 0.6), fill=rim_rgb + (max(6, 34 - puff * 4),))
    overlay = overlay.filter(ImageFilter.GaussianBlur(1.4))
    image = Image.alpha_composite(image, overlay).convert("RGB")
    save_rgb(np.asarray(image, dtype=np.float32) / 255.0, BG_DIR / f"stage{stage}.png")


# ---------------------------------------------------------------- paper
def paper_texture(rng, height, width, deckle=7.0, shadow=8):
    """Bone washi with kozo fibres, mottling and a torn (deckled) edge."""
    full_h, full_w = height + shadow * 2, width + shadow * 2
    mottle = fbm(rng, full_h, full_w, max(2, full_h // 120), max(2, full_w // 120), octaves=5)
    grain = rng.random((full_h, full_w)).astype(np.float32)
    rgb = PAPER[None, None, :] * (0.93 + 0.1 * mottle[..., None]) - (grain[..., None] - 0.5) * 0.025
    fibres = Image.new("L", (full_w, full_h), 0)
    draw = ImageDraw.Draw(fibres)
    for _ in range(int(full_w * full_h / 900)):
        x, y = rng.uniform(0, full_w), rng.uniform(0, full_h)
        angle = rng.uniform(0, math.tau)
        length = rng.uniform(6, 26)
        points = [(x, y)]
        for _segment in range(4):
            angle += rng.uniform(-0.5, 0.5)
            x += math.cos(angle) * length / 4
            y += math.sin(angle) * length / 4
            points.append((x, y))
        draw.line(points, fill=int(rng.integers(60, 160)), width=1)
    fibre_map = np.asarray(fibres.filter(ImageFilter.GaussianBlur(0.4)), dtype=np.float32) / 255.0
    rgb = rgb * (1.0 - 0.07 * fibre_map[..., None]) + 0.04 * fibre_map[..., None]
    # deckled edge mask
    ys, xs = np.mgrid[0:full_h, 0:full_w].astype(np.float32)
    edge_noise = fbm(rng, full_h, full_w, max(2, full_h // 10), max(2, full_w // 10), octaves=4)
    dist = np.minimum.reduce([xs - shadow, full_w - shadow - 1 - xs, ys - shadow, full_h - shadow - 1 - ys])
    paper_alpha = ((dist + edge_noise * deckle - deckle * 0.5) / 1.5).clip(0.0, 1.0)
    # soft shadow under the sheet so it sits on the frame
    shadow_img = Image.fromarray((paper_alpha * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(shadow * 0.6))
    shadow_alpha = np.roll(np.asarray(shadow_img, dtype=np.float32) / 255.0, (3, 2), axis=(0, 1)) * 0.6
    alpha = paper_alpha + shadow_alpha * (1.0 - paper_alpha)
    rgb = np.where(paper_alpha[..., None] > 0.0, rgb, 0.03)
    rgb = rgb * paper_alpha[..., None] + 0.03 * (1.0 - paper_alpha[..., None])
    rgb = np.where(alpha[..., None] > 1e-4, rgb * np.maximum(paper_alpha, 1e-4)[..., None] / np.maximum(alpha, 1e-4)[..., None], 0.0)
    return rgb, alpha


def paint_seal(rng):
    size = 128
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float32)
    noise = fbm(rng, size, size, 16, 16, octaves=3)
    margin = 6.0
    dist = np.minimum.reduce([xs - margin, size - margin - 1 - xs, ys - margin, size - margin - 1 - ys])
    border = ((dist + noise * 5.0 - 2.5) / 1.2).clip(0.0, 1.0)
    speckle = (fbm(rng, size, size, 24, 24, octaves=2) > 0.74).astype(np.float32)
    alpha = border * (1.0 - 0.6 * speckle) * (0.86 + 0.14 * noise)
    rgb = np.ones((size, size, 3), dtype=np.float32)
    save_rgba(rgb, alpha, UI_DIR / "seal.png")


# ---------------------------------------------------------------- pigment sprites
BULLET_SIZE = 96
SUPERSAMPLE = 4
## Half-extent of each sprite in bullet-radius units (the body radius is 1.0).
BULLET_SHAPES = {"orb": 1.3, "diamond": 1.6, "needle": 2.2, "petal": 2.0, "star": 1.7}


def _shape_polygon(shape, rng, unit, centre):
    """Outline of a bullet body in pixels; edges wobble like pigment on paper."""
    if shape == "orb":
        points = [(math.cos(a), math.sin(a)) for a in np.linspace(0, math.tau, 48, endpoint=False)]
    elif shape == "diamond":
        points = [(0.0, -1.3), (0.9, 0.0), (0.0, 1.3), (-0.9, 0.0)]
    elif shape == "needle":
        points = [(0.0, -1.9), (0.5, -0.15), (0.0, 1.7), (-0.5, -0.15)]
    elif shape == "petal":
        points = [(0.0, -1.7), (0.7, -0.6), (0.55, 1.0), (0.0, 1.5), (-0.55, 1.0), (-0.7, -0.6)]
    else:
        points = [(math.cos(-math.pi / 2 + math.tau * i / 10) * (1.4 if i % 2 == 0 else 0.62),
                   math.sin(-math.pi / 2 + math.tau * i / 10) * (1.4 if i % 2 == 0 else 0.62)) for i in range(10)]
    dense = []
    for index, start in enumerate(points):
        end = points[(index + 1) % len(points)]
        for t in np.linspace(0.0, 1.0, 8, endpoint=False):
            wobble = 1.0 + rng.uniform(-0.035, 0.035)
            dense.append(((start[0] + (end[0] - start[0]) * t) * wobble, (start[1] + (end[1] - start[1]) * t) * wobble))
    return [(centre + x * unit, centre + y * unit) for x, y in dense]


def paint_bullet(shape, rng):
    """White pigment drop (tinted in engine) with an ink keyline and a darker pooled rim."""
    size = BULLET_SIZE * SUPERSAMPLE
    unit = size / (2.0 * BULLET_SHAPES[shape])
    mask_img = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask_img).polygon(_shape_polygon(shape, rng, unit, size / 2.0), fill=255)
    keyline_img = mask_img.filter(ImageFilter.MaxFilter(2 * int(unit * 0.16) + 1))
    body = np.asarray(mask_img, dtype=np.float32) / 255.0
    keyline = np.asarray(keyline_img, dtype=np.float32) / 255.0
    # distance-ish falloff from the edge: watercolour pools pigment at the rim
    blurred = np.asarray(mask_img.filter(ImageFilter.GaussianBlur(unit * 0.35)), dtype=np.float32) / 255.0
    grain = fbm(rng, size, size, 24, 24, octaves=3)
    value = (0.58 + 0.42 * np.clip((blurred - 0.5) * 2.2, 0.0, 1.0)) * (0.9 + 0.12 * grain)
    rgb = np.repeat((value * body)[..., None], 3, axis=2)
    alpha = np.maximum(body, keyline * 0.9)
    image = Image.fromarray(np.clip(np.dstack([rgb, alpha[..., None]]) * 255, 0, 255).astype(np.uint8), "RGBA")
    image = image.resize((BULLET_SIZE, BULLET_SIZE), Image.Resampling.LANCZOS)
    (ROOT / "art" / "bullets").mkdir(parents=True, exist_ok=True)
    image.save(ROOT / "art" / "bullets" / f"{shape}.png", optimize=True)


def paint_dab(rng):
    """A single brush dab (lives and bombs on the ofuda), white, tinted in engine."""
    size = 128
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float32)
    angle = np.arctan2(ys - size / 2, xs - size / 2)
    radius = np.hypot(xs - size / 2, ys - size / 2)
    edge = 44.0 + 6.0 * np.sin(angle * 3.0 + 0.7) + 3.0 * np.sin(angle * 7.0 + 2.1)
    noise = fbm(rng, size, size, 12, 12, octaves=4)
    alpha = np.clip((edge + noise * 10.0 - 5.0 - radius) / 2.0, 0.0, 1.0)
    alpha *= 0.82 + 0.18 * fbm(rng, size, size, 30, 30, octaves=2)
    save_rgba(np.ones((size, size, 3), dtype=np.float32), alpha, UI_DIR / "dab.png")


def main():
    for stage, spec in STAGES.items():
        paint_stage(stage, spec, np.random.default_rng(1000 + stage))
    papers = {"ofuda": (324, 924, 21), "sheet": (504, 520, 22), "card": (152, 204, 23), "scroll": (528, 214, 24)}
    for name, (width, height, seed) in papers.items():
        rgb, alpha = paper_texture(np.random.default_rng(seed), height, width)
        save_rgba(rgb, alpha, UI_DIR / f"{name}.png")
    paint_seal(np.random.default_rng(13))
    paint_dab(np.random.default_rng(31))
    for index, shape in enumerate(BULLET_SHAPES):
        paint_bullet(shape, np.random.default_rng(400 + index))


if __name__ == "__main__":
    main()
