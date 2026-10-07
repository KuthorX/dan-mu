#!/usr/bin/env python3
"""The SFX "sheet": every preset hit that sfx.py layers, laid out on one timeline so all
of them render in a single audiokit run (one plugin instance per sound, not per effect).

    arch -arm64 /tmp/audiokit/venv/bin/python tools/audio/sfx_sheet.py
    lockf -t 3600 /tmp/audiokit/render.lock arch -arm64 /tmp/audiokit/venv/bin/python \
        /tmp/audiokit/render.py tools/audio/.cache/sfx_sheet/sheet.json

Each event gets its own window; sfx.py cuts the window out of each dry stem.
Times are in seconds (the MIDI runs at 60 BPM, so one beat is one second).
"""
import json
import pathlib
import sys

import mido

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from music_lib import pitch  # noqa: E402
from palette import track  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
WORK = ROOT / "tools" / "audio" / ".cache" / "sfx_sheet"
PPQ = 960
SOUNDS = ["ceramic", "guzheng", "wudang", "gm_taiko", "gm_kit", "harp_wire", "pan_flute", "strings"]
HI_WOOD, LOW_WOOD = 76, 77
SFX_WINDOW = 2.5
JINGLE_WINDOW = 7.0


def notes(sound: str, sixteenth: float, items: list, start_at: float = 0.0) -> list:
    """[(start_16th, len_16th, note_name, velocity)] -> [(sound, start_s, dur_s, midi, vel)]."""
    return [(sound, start_at + start * sixteenth, length * sixteenth, pitch(name), velocity)
            for start, length, name, velocity in items]


def _stage_clear() -> list:
    step = 60 / 120 / 4
    koto = [(0, 2, "A4", 92), (2, 2, "C5", 92), (4, 2, "E5", 96), (6, 2, "A5", 100), (8, 12, "E6", 106)]
    pad = [(0, 20, "A3", 80), (0, 20, "E4", 80), (8, 12, "C#5", 76)]
    return notes("guzheng", step, koto) + notes("strings", step, pad) + notes("wudang", step, [(8, 12, "A4", 72)])


def _game_clear() -> list:
    step = 60 / 112 / 4
    koto = [(0, 2, "G4", 90), (2, 2, "A4", 90), (4, 2, "B4", 92), (6, 2, "D5", 95), (8, 2, "E5", 98),
            (10, 2, "G5", 100), (12, 4, "A5", 104), (16, 16, "G5", 110)]
    flute = [(8, 8, "D6", 84), (16, 16, "B5", 88)]
    pad = [(0, 16, "C4", 76), (0, 16, "E4", 76), (0, 16, "G4", 76), (16, 16, "G3", 80), (16, 16, "D4", 80), (16, 16, "B4", 80)]
    return (notes("guzheng", step, koto) + notes("pan_flute", step, flute) + notes("strings", step, pad)
            + notes("wudang", step, [(16, 16, "G4", 76)]))


def _game_over() -> list:
    step = 60 / 84 / 4
    flute = [(0, 4, "A5", 92), (4, 2, "G5", 86), (6, 2, "Eb5", 82), (8, 4, "D5", 86), (12, 12, "D5", 80)]
    koto = [(0, 2, "D3", 88), (8, 2, "Bb2", 84), (12, 12, "D3", 92)]
    return (notes("pan_flute", step, flute) + notes("guzheng", step, koto)
            + notes("wudang", step, [(12, 12, "D4", 64)]))


def _hits(*items) -> list:
    return [(sound, start, length, note, velocity) for sound, start, length, note, velocity in items]


EVENTS = {
    "shot": _hits(("ceramic", 0.0, 0.03, 67, 70)),
    "shot_focus": _hits(("ceramic", 0.0, 0.03, 62, 70)),
    "enemy_fire": _hits(("harp_wire", 0.0, 0.06, pitch("E5"), 96)),
    "enemy_ring": _hits(("harp_wire", 0.0, 0.1, pitch("A4"), 100)),
    "enemy_spiral": _hits(("harp_wire", 0.0, 0.04, pitch("B5"), 92), ("harp_wire", 0.035, 0.04, pitch("G5"), 88),
                          ("harp_wire", 0.07, 0.06, pitch("E5"), 84)),
    "graze": _hits(("ceramic", 0.0, 0.04, 76, 90)),
    "enemy_hit": _hits(("gm_kit", 0.0, 0.05, HI_WOOD, 90)),
    "enemy_down": _hits(("guzheng", 0.0, 0.2, pitch("A3"), 110), ("gm_kit", 0.0, 0.05, LOW_WOOD, 100)),
    "pickup": _hits(("guzheng", 0.0, 0.1, pitch("G6"), 100), ("ceramic", 0.0, 0.03, 72, 64)),
    "pickup_power": _hits(("guzheng", 0.0, 0.08, pitch("C6"), 100), ("guzheng", 0.035, 0.1, pitch("G6"), 104),
                          ("ceramic", 0.035, 0.03, 72, 64)),
    "extend": _hits(*[("guzheng", index * 0.07, 0.3, pitch(name), 104) for index, name in enumerate(["G5", "B5", "D6", "G6"])],
                    ("wudang", 0.21, 0.6, pitch("G5"), 90)),
    "ui_move": _hits(("ceramic", 0.0, 0.03, 64, 80), ("gm_kit", 0.0, 0.03, 75, 60)),
    "confirm": _hits(("gm_kit", 0.0, 0.05, HI_WOOD, 110), ("gm_kit", 0.07, 0.05, HI_WOOD, 104),
                     ("guzheng", 0.07, 0.15, pitch("D6"), 96)),
    "pause": _hits(("gm_kit", 0.0, 0.08, LOW_WOOD, 104), ("gm_kit", 0.06, 0.08, LOW_WOOD, 80)),
    "cancel": _hits(("gm_kit", 0.0, 0.06, HI_WOOD, 96), ("gm_kit", 0.05, 0.08, LOW_WOOD, 96)),
    "bomb": _hits(("gm_taiko", 0.0, 0.5, 36, 127), ("wudang", 0.02, 1.2, pitch("D3"), 110)),
    "spell_declare": _hits(("gm_taiko", 0.0, 0.4, 41, 120),
                           *[("guzheng", 0.09 + index * 0.05, 0.6, pitch(name), 104) for index, name in enumerate(["D5", "A5", "Eb6"])],
                           ("wudang", 0.2, 0.8, pitch("Eb5"), 84)),
    "phase_break": _hits(("gm_taiko", 0.0, 0.4, 43, 124), ("wudang", 0.03, 0.9, pitch("D5"), 96),
                         ("wudang", 0.03, 0.9, pitch("A5"), 90)),
    "player_hit": _hits(("gm_taiko", 0.04, 0.4, 38, 120), ("harp_wire", 0.0, 0.05, pitch("A6"), 100)),
    "stage_clear": _stage_clear(),
    "game_clear": _game_clear(),
    "game_over": _game_over(),
}
JINGLES = {"stage_clear", "game_clear", "game_over"}


def windows() -> dict:
    """event -> (start_s, length_s) on the sheet timeline."""
    out, cursor = {}, 1.0
    for name in EVENTS:
        length = JINGLE_WINDOW if name in JINGLES else SFX_WINDOW
        out[name] = (cursor, length)
        cursor += length
    return out


def write_sheet() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    spans = windows()
    per_sound = {sound: [] for sound in SOUNDS}
    for name, hits in EVENTS.items():
        start, _ = spans[name]
        for sound, offset, length, note, velocity in hits:
            per_sound[sound].append((start + offset, length, note, velocity))
    midi = mido.MidiFile(ticks_per_beat=PPQ)
    for position, sound in enumerate(SOUNDS):
        channel = 9 if sound == "gm_kit" else position
        events = []
        for start, length, note, velocity in per_sound[sound]:
            events.append((round((start + length) * PPQ), 0, mido.Message("note_off", channel=channel, note=note, velocity=0)))
            events.append((round(start * PPQ), 1, mido.Message("note_on", channel=channel, note=note, velocity=velocity)))
        events.sort(key=lambda event: (event[0], event[1]))
        midi_track = mido.MidiTrack()
        if position == 0:
            midi_track.append(mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(60), time=0))
        now = 0
        for tick, _, message in events:
            midi_track.append(message.copy(time=tick - now))
            now = tick
        midi.tracks.append(midi_track)
    midi_path = WORK / "sheet.mid"
    midi.save(midi_path)
    end = max(start + length for start, length in spans.values())
    spec = {"out": str(WORK / "sheet_preview.wav"), "lufs": -18, "tail": 1.0, "length": end,
            "stems_dir": str(WORK / "stems"),
            "tracks": [track(sound, str(midi_path), index, sound) for index, sound in enumerate(SOUNDS)]}
    (WORK / "sheet.json").write_text(json.dumps(spec, indent=1))
    (WORK / "windows.json").write_text(json.dumps(spans, indent=1))
    print(f"sheet: {len(EVENTS)} events, {end:.1f} s, {len(SOUNDS)} sounds")


if __name__ == "__main__":
    write_sheet()
