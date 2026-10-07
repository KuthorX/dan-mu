"""Tiny score toolkit: note-string parser, chord parser and part generators -> MIDI.

Notation for melodies (durations are in sixteenth notes, 16 per 4/4 bar):
    "A4:4 C5:2 r:2 Bb4:8 | ..."   note:duration, r = rest, ~ = tie to previous note.
Bars are separated by "|" and every bar is asserted to be exactly 16 sixteenths,
so a typo fails loudly instead of shifting the whole tune.
"""
import re

import mido

PPQ = 480
SIXTEENTH = PPQ // 4
BAR = SIXTEENTH * 16
NOTE_INDEX = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
CHORD_SHAPES = {
    "": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10],
    "maj7": [0, 4, 7, 11], "sus": [0, 5, 7], "5": [0, 7], "dim": [0, 3, 6],
}
DRUM = {"k": 36, "s": 38, "h": 42, "o": 46, "c": 49, "r": 51, "t": 45, "T": 50, "w": 76}


def pitch(name: str) -> int:
    match = re.fullmatch(r"([A-G])([#b]?)(-?\d)", name)
    if not match:
        raise ValueError(f"bad note {name!r}")
    letter, accidental, octave = match.groups()
    offset = {"#": 1, "b": -1, "": 0}[accidental]
    return 12 * (int(octave) + 1) + NOTE_INDEX[letter] + offset


def chord(name: str, octave: int = 3) -> list:
    """'Am' -> [57, 60, 64] (root in the given octave)."""
    match = re.fullmatch(r"([A-G][#b]?)(.*)", name)
    root_name, quality = match.groups()
    root = pitch(f"{root_name}{octave}")
    return [root + interval for interval in CHORD_SHAPES[quality]]


def parse_line(text: str) -> list:
    """Returns [(start_16th, length_16th, midi_pitch)] for a melody string."""
    notes = []
    position = 0
    for bar_index, bar in enumerate(text.split("|")):
        bar_length = 0
        for token in bar.split():
            name, length = token.split(":")
            length = int(length)
            if name == "~":
                start, previous_length, previous_pitch = notes[-1]
                notes[-1] = (start, previous_length + length, previous_pitch)
            elif name != "r":
                notes.append((position, length, pitch(name)))
            position += length
            bar_length += length
        if bar.strip() and bar_length != 16:
            raise ValueError(f"bar {bar_index + 1} has {bar_length} sixteenths: {bar.strip()!r}")
    return notes


class Song:
    """Collects note events per channel and writes a looped type-1 MIDI file."""

    def __init__(self, bpm: float, bars: int):
        self.bpm = bpm
        self.bars = bars
        self.channels = {}

    def channel(self, number: int, program: int, volume: int, pan: int = 64, reverb: int = 40):
        self.channels[number] = {"program": program, "volume": volume, "pan": pan, "reverb": reverb, "notes": []}

    def add(self, number: int, start_16th: float, length_16th: float, note: int, velocity: int) -> None:
        self.channels[number]["notes"].append((int(start_16th * SIXTEENTH), max(1, int(length_16th * SIXTEENTH)), note, velocity))

    def melody(self, number: int, bar: int, text: str, velocity: int, gate: float = 0.92, octave_shift: int = 0) -> None:
        for start, length, note in parse_line(text):
            accent = 8 if start % 4 == 0 else 0
            self.add(number, bar * 16 + start, length * gate, note + 12 * octave_shift, min(127, velocity + accent))

    def seconds(self) -> float:
        return self.bars * 4 * 60.0 / self.bpm

    def write(self, path, repeats: int) -> None:
        midi = mido.MidiFile(ticks_per_beat=PPQ)
        tempo_track = mido.MidiTrack()
        tempo_track.append(mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(self.bpm), time=0))
        midi.tracks.append(tempo_track)
        loop_ticks = self.bars * BAR
        for number, data in sorted(self.channels.items()):
            track = mido.MidiTrack()
            track.append(mido.Message("program_change", channel=number, program=data["program"], time=0))
            for control, value in ((7, data["volume"]), (10, data["pan"]), (91, data["reverb"]), (93, 0)):
                track.append(mido.Message("control_change", channel=number, control=control, value=value, time=0))
            events = []
            for repeat in range(repeats):
                for start, length, note, velocity in data["notes"]:
                    begin = start + repeat * loop_ticks
                    events.append((begin + length, 0, note, 0))
                    events.append((begin, 1, note, velocity))
            events.sort()
            now = 0
            for tick, is_on, note, velocity in events:
                kind = "note_on" if is_on else "note_off"
                track.append(mido.Message(kind, channel=number, note=note, velocity=velocity, time=tick - now))
                now = tick
            midi.tracks.append(track)
        midi.save(path)


# ---- part generators -------------------------------------------------------

def pad(song: Song, number: int, chords: list, velocity: int, octave: int = 4) -> None:
    """Sustained chord per bar (one chord name per bar)."""
    for bar, name in enumerate(chords):
        for note in chord(name, octave):
            song.add(number, bar * 16, 16, note, velocity)


def arpeggio(song: Song, number: int, chords: list, order: list, step: int, velocity: int, octave: int = 4, gate: float = 1.6) -> None:
    """Broken chord: `order` indexes into the chord tones extended over two octaves."""
    for bar, name in enumerate(chords):
        if name is None:
            continue
        tones = chord(name, octave)
        ladder = tones + [note + 12 for note in tones] + [note + 24 for note in tones]
        for index, slot in enumerate(range(0, 16, step)):
            note = ladder[order[index % len(order)]]
            accent = 10 if slot % 8 == 0 else 0
            song.add(number, bar * 16 + slot, step * gate, note, velocity + accent)


def bass(song: Song, number: int, chords: list, pattern: str, velocity: int, octave: int = 2) -> None:
    """pattern per bar, 16 chars: 'r' root, 'o' octave, 'f' fifth, '.' rest."""
    for bar, name in enumerate(chords):
        if name is None:
            continue
        root = chord(name, octave)[0]
        for slot, symbol in enumerate(pattern):
            if symbol == ".":
                continue
            note = {"r": root, "o": root + 12, "f": root + 7}[symbol]
            song.add(number, bar * 16 + slot, 1.7, note, velocity + (8 if slot % 4 == 0 else 0))


def stabs(song: Song, number: int, chords: list, pattern: str, velocity: int, octave: int = 4, length: float = 1.0) -> None:
    for bar, name in enumerate(chords):
        if name is None:
            continue
        for slot, symbol in enumerate(pattern):
            if symbol != ".":
                for note in chord(name, octave)[1:] + [chord(name, octave + 1)[0]]:
                    song.add(number, bar * 16 + slot, length, note, velocity + (10 if symbol == "X" else 0))


def drums(song: Song, bar: int, lanes: dict, velocity: int = 96) -> None:
    """lanes: {'k': 'x...x...', 's': ...} 16-char strings; X = accent."""
    if 9 not in song.channels:
        song.channel(9, 0, 100, 64, 30)
    for lane, pattern in lanes.items():
        for slot, symbol in enumerate(pattern):
            if symbol in "xX":
                accent = 18 if symbol == "X" else 0
                hat_soft = -24 if lane in "ho" and slot % 4 else 0
                song.add(9, bar * 16 + slot, 1, DRUM[lane], max(1, min(127, velocity + accent + hat_soft)))


def hits(song: Song, number: int, bar: int, pattern: str, note: int, velocity: int) -> None:
    for slot, symbol in enumerate(pattern):
        if symbol in "xX":
            song.add(number, bar * 16 + slot, 4, note, min(127, velocity + (20 if symbol == "X" else 0)))
