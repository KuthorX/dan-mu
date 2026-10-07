#!/usr/bin/env python3
"""Re-orchestrates the DanMu score (score.py) for Vital, Serum 2 and MS Basic, rendered
offline by audiokit (/tmp/audiokit/render.py, never plays audio, never opens windows).

Three stages, each a separate command so renders can be serialised with lockf:
    PY=/tmp/audiokit/venv/bin/python          (run with `arch -arm64`)
    $PY tools/audio/rescore.py prepare        # MIDI + stem-render specs in .cache/rescore/
    lockf -t 3600 /tmp/audiokit/render.lock arch -arm64 $PY /tmp/audiokit/render.py .cache/rescore/<cue>_stems.json
    $PY tools/audio/rescore.py mix            # level each stem by role -> <cue>_mix.json
    lockf ... render.py .cache/rescore/<cue>_mix.json
    $PY tools/audio/rescore.py finish         # seamless loop wav -> audio/music/<cue>.ogg

Mixing without listening: every stem is rendered at unity gain, measured (LUFS), and given
the gain that puts it at a fixed level for its role (lead loudest, pads and doubles under).
"""
import json
import pathlib
import subprocess
import sys

import mido
import numpy as np
import pyloudnorm
import soundfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from music_lib import PPQ, chord  # noqa: E402
from palette import track  # noqa: E402
from score import SONGS  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
WORK = ROOT / "tools" / "audio" / ".cache" / "rescore"
OUT = ROOT / "audio" / "music"
RATE = 44100
TARGET_LUFS = -18.0
# libsndfile Vorbis compression level (0 = best, 1 = smallest); 0.7 is about 110 kbps stereo.
OGG_LEVEL = 0.7
TAIL = 6.0

LEAD, DOUBLE, ARP, COMP, PAD, BASS, TAIKO, EXTRA, BELL, DRUMS = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9

# Stem level for each role, in LUFS before the master is normalised to -18.
ROLE_LUFS = {
    "lead": -20.0, "double": -27.0, "arp": -24.5, "comp": -28.0, "pad": -27.0,
    "bass": -27.0, "drums": -27.0, "taiko": -28.5, "extra": -29.0, "bell": -29.0,
}
# The slow cues sit lower in the bass and percussion so the melody floats.
CUE_LUFS = {
    "title": {"bass": -29.0, "taiko": -31.0, "bell": -28.0},
    "results": {"bass": -29.0, "arp": -26.0},
}

ROOM = {"type": "Reverb", "room_size": 0.7, "wet_level": 0.18, "dry_level": 0.85, "width": 0.9}
HALL = {"type": "Reverb", "room_size": 0.88, "wet_level": 0.28, "dry_level": 0.8, "width": 1.0}
PAD_HP = {"type": "HighpassFilter", "cutoff_frequency_hz": 140}
LEAD_HP = {"type": "HighpassFilter", "cutoff_frequency_hz": 180}
BASS_LP = {"type": "LowpassFilter", "cutoff_frequency_hz": 2200}
DARK_LIFT = {"type": "HighShelfFilter", "cutoff_frequency_hz": 2500, "gain_db": 3.0}
TAME_TOP = {"type": "LowpassFilter", "cutoff_frequency_hz": 9000}
GLUE = {"type": "Compressor", "threshold_db": -16, "ratio": 2.0, "attack_ms": 25, "release_ms": 220}

# channel -> (role, palette sound, fx, pan). Channels follow score.py.
ARRANGEMENTS = {
    "title": {
        LEAD: ("lead", "pan_flute", [LEAD_HP, HALL], 0.0),
        ARP: ("arp", "guzheng", [ROOM], -0.25),
        PAD: ("pad", "bamboo_pad", [PAD_HP], 0.0),
        BASS: ("bass", "gm_fretless", [BASS_LP], 0.0),
        TAIKO: ("taiko", "gm_taiko", [ROOM], 0.0),
        BELL: ("bell", "wudang", [PAD_HP], 0.15),
    },
    "stage_a": {
        LEAD: ("lead", "flute", [LEAD_HP, ROOM], 0.0),
        DOUBLE: ("double", "gm_koto", [ROOM], -0.3),
        ARP: ("arp", "guzheng", [ROOM], 0.3),
        COMP: ("comp", "harp_wire", [TAME_TOP, ROOM], -0.35),
        PAD: ("pad", "strings", [PAD_HP], 0.0),
        BASS: ("bass", "gm_finger_bass", [BASS_LP], 0.0),
        TAIKO: ("taiko", "gm_taiko", [ROOM], 0.0),
        DRUMS: ("drums", "gm_kit", [], 0.0),
    },
    "stage_b": {
        LEAD: ("lead", "harp_wire", [LEAD_HP, TAME_TOP, ROOM], 0.0),
        DOUBLE: ("double", "pan_flute", [LEAD_HP, HALL], 0.3),
        ARP: ("arp", "guzheng", [ROOM], -0.3),
        PAD: ("pad", "elegy", [PAD_HP], 0.0),
        BASS: ("bass", "gm_finger_bass", [BASS_LP], 0.0),
        TAIKO: ("taiko", "gm_taiko", [ROOM], 0.0),
        DRUMS: ("drums", "gm_kit", [], 0.0),
    },
    "boss": {
        LEAD: ("lead", "kalyan", [LEAD_HP, ROOM], 0.0),
        DOUBLE: ("double", "gm_shakuhachi", [ROOM], 0.25),
        ARP: ("arp", "harp_wire", [TAME_TOP, ROOM], -0.3),
        COMP: ("comp", "gm_brass", [ROOM], 0.2),
        PAD: ("pad", "ghost_voices", [PAD_HP, DARK_LIFT], 0.0),
        BASS: ("bass", "gm_finger_bass", [BASS_LP], 0.0),
        TAIKO: ("taiko", "gm_taiko", [ROOM], 0.0),
        EXTRA: ("extra", "gm_timpani", [ROOM], 0.0),
        BELL: ("bell", "cinema_bells", [PAD_HP], 0.0),
        DRUMS: ("drums", "gm_kit", [], 0.0),
    },
    "boss_final": {
        LEAD: ("lead", "flute", [LEAD_HP, ROOM], 0.0),
        DOUBLE: ("double", "gm_strings", [ROOM], 0.25),
        ARP: ("arp", "guzheng", [ROOM], -0.3),
        COMP: ("comp", "harp_wire", [TAME_TOP, ROOM], 0.35),
        PAD: ("pad", "strings", [PAD_HP], 0.0),
        BASS: ("bass", "gm_finger_bass", [BASS_LP], 0.0),
        TAIKO: ("taiko", "gm_taiko", [ROOM], 0.0),
        EXTRA: ("extra", "wudang", [PAD_HP], -0.1),
        DRUMS: ("drums", "gm_kit", [], 0.0),
    },
    "results": {
        LEAD: ("lead", "guzheng", [ROOM], 0.0),
        DOUBLE: ("double", "pan_flute", [LEAD_HP, HALL], 0.3),
        ARP: ("arp", "gm_harp", [ROOM], -0.3),
        PAD: ("pad", "elegy", [PAD_HP], 0.0),
        BASS: ("bass", "gm_fretless", [BASS_LP], 0.0),
    },
}

# Temple-bell accents added on top of score.py: (bar, chord) every few bars, an octave up.
BELL_BARS = {"title": 4, "boss": 8}


def bell_part(song, every: int, chords: list) -> list:
    notes = []
    for bar in range(0, song.bars, every):
        root = chord(chords[bar % len(chords)], 5)[0]
        notes.append((bar * 16 * (PPQ // 4), 12 * (PPQ // 4), root, 70))
    return notes


def chord_names(name: str) -> list:
    """The per-bar chord list each score function uses, recovered from its bass/pad notes."""
    return {
        "title": (["Dm", "Dm", "Bb", "Bb", "Gm", "Gm", "Eb", "Asus"] * 2 + ["Dm", "Bb", "Eb", "Asus"]),
        "boss": (["Dm", "Dm", "Bb", "A"] + ["Dm", "Bb", "C", "Dm", "Gm", "Eb", "A", "A"]
                 + ["Dm", "Bb", "C", "Dm", "Gm", "Eb", "A", "Dm"]
                 + ["Bb", "C", "Am", "Dm", "Gm", "C", "F", "A"] * 2
                 + ["Dm", "Dm", "Eb", "Eb", "Dm", "Dm", "A", "A"]
                 + ["Dm", "Bb", "C", "Dm", "Gm", "Eb", "A", "Dm"] + ["Bb", "C", "A", "A"]),
    }[name]


def write_midi(name: str, song) -> tuple:
    """One MIDI track per channel (no CC/program messages; the spec picks the sound).
    Returns (path, {channel: track_index})."""
    parts = {number: list(data["notes"]) for number, data in song.channels.items()}
    if name in BELL_BARS:
        parts[BELL] = bell_part(song, BELL_BARS[name], chord_names(name))
    midi = mido.MidiFile(ticks_per_beat=PPQ)
    index = {}
    for position, number in enumerate(sorted(parts)):
        events = []
        for start, length, note, velocity in parts[number]:
            events.append((start + length, 0, mido.Message("note_off", channel=number, note=note, velocity=0)))
            events.append((start, 1, mido.Message("note_on", channel=number, note=note, velocity=velocity)))
        events.sort(key=lambda event: (event[0], event[1]))
        midi_track = mido.MidiTrack()
        if position == 0:
            midi_track.append(mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(song.bpm), time=0))
        now = 0
        for tick, _, message in events:
            midi_track.append(message.copy(time=tick - now))
            now = tick
        midi.tracks.append(midi_track)
        index[number] = position
    path = WORK / f"{name}.mid"
    midi.save(path)
    return path, index


def prepare() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    plan = {}
    for name, build in SONGS.items():
        song = build()
        midi, index = write_midi(name, song)
        stems_dir = WORK / f"{name}_stems"
        tracks = []
        for number, (role, sound, fx, pan) in sorted(ARRANGEMENTS[name].items()):
            if number not in index:
                raise SystemExit(f"{name}: channel {number} has no notes")
            tracks.append(track(f"{number:02d}_{role}_{sound}", str(midi), index[number], sound, fx, pan))
        missing = set(index) - set(ARRANGEMENTS[name])
        if missing:
            raise SystemExit(f"{name}: channels {sorted(missing)} have no instrument")
        spec = {"out": str(WORK / f"{name}_stems_preview.wav"), "lufs": TARGET_LUFS, "tail": TAIL,
                "loop": song.seconds(), "stems_dir": str(stems_dir), "tracks": tracks}
        (WORK / f"{name}_stems.json").write_text(json.dumps(spec, indent=1))
        plan[name] = {"loop": song.seconds(), "bpm": song.bpm, "bars": song.bars}
    (WORK / "plan.json").write_text(json.dumps(plan, indent=1))
    print("prepared", ", ".join(plan))


def stem_lufs(path: pathlib.Path) -> float:
    data, rate = soundfile.read(path, dtype="float64")
    return pyloudnorm.Meter(rate).integrated_loudness(data)


def mix() -> None:
    plan = json.loads((WORK / "plan.json").read_text())
    for name, info in plan.items():
        stems_dir = WORK / f"{name}_stems"
        tracks = []
        for number, (role, sound, _fx, _pan) in sorted(ARRANGEMENTS[name].items()):
            stem = stems_dir / f"{number:02d}_{role}_{sound}.wav"
            level = stem_lufs(stem)
            if not np.isfinite(level):
                raise SystemExit(f"{stem.name} is silent")
            gain = CUE_LUFS.get(name, {}).get(role, ROLE_LUFS[role]) - level
            print(f"{name:10s} {stem.name:34s} {level:6.1f} LUFS  gain {gain:+5.1f} dB")
            tracks.append({"name": stem.stem, "audio": str(stem), "gain_db": round(gain, 2)})
        spec = {"out": str(WORK / f"{name}.wav"), "lufs": TARGET_LUFS, "ceiling_dbtp": -1.0, "tail": 0.0,
                "loop": info["loop"], "png": True, "master_fx": [GLUE], "tracks": tracks}
        (WORK / f"{name}_mix.json").write_text(json.dumps(spec, indent=1))


def finish() -> None:
    plan = json.loads((WORK / "plan.json").read_text())
    for name in plan:
        source = WORK / f"{name}.wav"
        target = OUT / f"{name}.ogg"
        data, rate = soundfile.read(source, always_2d=True)
        soundfile.write(target, data, rate, format="OGG", subtype="VORBIS", compression_level=OGG_LEVEL)
        if soundfile.info(target).frames != len(data):  # Vorbis keeps the exact loop length
            raise SystemExit(f"{name}: ogg length differs from the loop")
        print(f"{name}: -> {target.relative_to(ROOT)}")


if __name__ == "__main__":
    {"prepare": prepare, "mix": mix, "finish": finish}[sys.argv[1]]()
