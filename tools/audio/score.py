"""The DanMu score: six looping cues written as note strings (see music_lib.py).

Instruments are General MIDI programs rendered with MuseScore's MS Basic soundfont:
koto 107, shamisen 106, shakuhachi 77, taiko 116, strings, fretless/fingered bass.
"""
from music_lib import Song, arpeggio, bass, drums, hits, pad, stabs

KOTO, SHAMISEN, SHAKUHACHI, TAIKO = 107, 106, 77, 116
FLUTE, VIOLIN, STRINGS_FAST, STRINGS_SLOW, TREMOLO = 73, 40, 48, 49, 44
HARP, FINGER_BASS, FRETLESS, BRASS, TIMPANI, BELLS = 46, 33, 35, 61, 47, 14
LEAD, DOUBLE, ARP, COMP, PAD, BASS, DRUM_TAIKO, EXTRA = 0, 1, 2, 3, 4, 5, 6, 7

DRIVE = {"k": "x...x...x...x.x.", "s": "....x.......x...", "h": "x.x.x.x.x.x.x.x."}
DRIVE_B = {"k": "x.....x.x...x...", "s": "....x.......x..x", "h": "x.x.x.x.x.x.x.x."}
FILL = {"k": "x...x...x.......", "s": "....x.....x.xxxx", "h": "x.x.x.x.x......."}
HALF = {"k": "x...............", "s": "........x.......", "r": "x...x...x...x..."}
BOSS_BEAT = {"k": "x..x..x...x..x..", "s": "....x.......x...", "h": "xxxxxxxxxxxxxxxx"}
BOSS_FILL = {"k": "x..x..x...x.....", "s": "....x...xxxxXxXx", "h": "xxxxxxxx........"}


def lay_drums(song: Song, first_bar: int, bars: int, groove: dict, fill: dict, crash: bool = True) -> None:
    for offset in range(bars):
        lanes = dict(fill if offset == bars - 1 else groove)
        if crash and offset == 0:
            lanes["c"] = "x..............."
        drums(song, first_bar + offset, lanes)


def title() -> Song:
    """掛軸夜想 / Nocturne of the Hanging Scroll: D in-scale, 76 BPM, shakuhachi over koto."""
    song = Song(76, 20)
    song.channel(LEAD, SHAKUHACHI, 104, 70, 70)
    song.channel(ARP, KOTO, 92, 50, 60)
    song.channel(PAD, STRINGS_SLOW, 62, 64, 90)
    song.channel(BASS, FRETLESS, 80, 64, 30)
    song.channel(DRUM_TAIKO, TAIKO, 78, 64, 60)
    chords = ["Dm", "Dm", "Bb", "Bb", "Gm", "Gm", "Eb", "Asus"] * 2 + ["Dm", "Bb", "Eb", "Asus"]
    song.melody(LEAD, 0, """
        r:8 A4:6 Bb4:2 | A4:12 r:4 | D5:6 Eb5:2 D5:4 Bb4:4 | A4:12 r:4 |
        G4:6 A4:2 Bb4:4 D5:4 | Eb5:8 D5:4 r:4 | Bb4:6 A4:2 G4:4 Eb4:4 | D4:12 r:4 |
        r:4 D5:4 Eb5:4 G5:4 | A5:10 G5:2 Eb5:4 | D5:6 Eb5:2 D5:4 Bb4:4 | A4:12 r:4 |
        G4:4 Bb4:4 D5:4 G5:4 | A5:8 Bb5:4 A5:4 | G5:6 Eb5:2 D5:4 Bb4:4 | A4:12 r:4 |
        r:16 | D5:8 A4:8 | Bb4:6 A4:2 G4:8 | D4:12 r:4""", 78, gate=0.97)
    arpeggio(song, ARP, chords, [0, 1, 2, 4, 3, 2, 1, 2], 2, 58)
    pad(song, PAD, chords, 50)
    for bar, name in enumerate(chords):
        song.add(BASS, bar * 16, 15, {"D": 38, "B": 34, "G": 43, "E": 39, "A": 33}[name[0]], 70)
        if bar % 2 == 0:
            hits(song, DRUM_TAIKO, bar, "x.............x.", 45, 60)
    return song


def stage_a() -> Song:
    """墨風参道 / Ink Wind on the Shrine Road: A minor with hirajoshi colour, 150 BPM."""
    song = Song(150, 48)
    song.channel(LEAD, SHAKUHACHI, 110, 64, 45)
    song.channel(DOUBLE, KOTO, 70, 40, 40)
    song.channel(ARP, KOTO, 84, 88, 40)
    song.channel(COMP, SHAMISEN, 78, 30, 30)
    song.channel(PAD, STRINGS_FAST, 58, 64, 70)
    song.channel(BASS, FINGER_BASS, 100, 64, 10)
    song.channel(DRUM_TAIKO, TAIKO, 92, 64, 40)
    intro = ["Am", "Am", "F", "G"]
    a1 = ["Am", "F", "G", "Am", "Dm", "F", "E", "E"]
    a2 = ["Am", "F", "G", "Am", "Dm", "F", "E", "Am"]
    b = ["F", "G", "Em", "Am", "F", "G", "Esus", "E"]
    c = ["Dm", "Am", "Dm", "Am", "Bb", "F", "E", "E"]
    outro = ["Dm", "Dm", "E", "E"]
    chords = intro + a1 + a2 + b + c + a2 + outro
    melody_a = """A4:2 C5:2 E5:4 D5:2 C5:2 B4:2 C5:2 | A4:6 C5:2 F5:4 E5:4 |
        D5:2 E5:2 G5:4 E5:2 D5:2 B4:4 | A4:12 r:4 |
        D5:2 F5:2 A5:4 G5:2 F5:2 E5:2 D5:2 | C5:4 F5:4 A5:4 C6:4 |"""
    end_1 = "B5:4 A5:2 G#5:2 E5:4 F5:2 G#5:2 | A5:4 G#5:2 B5:2 E5:8"
    end_2 = "B4:2 C5:2 D5:2 E5:2 G#5:4 B5:4 | A5:12 r:4"
    song.melody(LEAD, 4, melody_a + end_1, 92)
    song.melody(LEAD, 12, melody_a + end_2, 92)
    song.melody(LEAD, 20, """C6:6 A5:2 F5:4 A5:4 | B5:6 G5:2 D5:4 B5:4 | E5:2 G5:2 B5:4 E6:4 D6:4 | C6:8 B5:4 A5:4 |
        A5:6 C6:2 F6:4 E6:4 | D6:4 B5:4 G5:4 D6:4 | E6:8 D6:4 B5:4 | G#5:8 B5:4 E6:4""", 96)
    song.melody(LEAD, 28, """D5:16 | E5:16 | F5:16 | E5:12 r:4 | D5:8 F5:8 | C5:8 A4:8 | B4:16 | G#4:8 B4:4 E5:4""", 80)
    song.melody(LEAD, 36, melody_a + end_2, 96)
    song.melody(DOUBLE, 4, melody_a + end_1, 62, gate=0.5, octave_shift=-1)
    song.melody(DOUBLE, 36, melody_a + end_2, 62, gate=0.5, octave_shift=-1)
    koto_chords = intro + [None] * 8 + [None] * 8 + [None] * 8 + c + [None] * 8 + outro
    arpeggio(song, ARP, koto_chords, [0, 2, 3, 2, 4, 3, 5, 3], 1, 66, gate=1.4)
    arpeggio(song, ARP, [None] * 4 + a1 + a2 + b + [None] * 8 + a2, [0, 2, 3, 5], 2, 54, gate=1.2)
    stabs(song, COMP, chords, "..x...x...x...x.", 66, octave=4, length=0.8)
    pad(song, PAD, chords, 44)
    bass(song, BASS, chords, "r.r.o.r.r.r.o.rf", 84)
    lay_drums(song, 0, 4, {"k": "x.......x.......", "h": "x.x.x.x.x.x.x.x."}, FILL, crash=False)
    lay_drums(song, 4, 8, DRIVE, FILL)
    lay_drums(song, 12, 8, DRIVE_B, FILL)
    lay_drums(song, 20, 8, DRIVE, FILL)
    lay_drums(song, 28, 8, HALF, FILL)
    lay_drums(song, 36, 8, DRIVE_B, FILL)
    lay_drums(song, 44, 4, DRIVE, FILL, crash=False)
    for bar in range(48):
        hits(song, DRUM_TAIKO, bar, "X.....x.....x..." if 28 <= bar < 36 else "x.........x.....", 45, 70)
    return song


def stage_b() -> Song:
    """提灯行列 / Lantern Procession at the Torn Border: E in-scale, 160 BPM, shamisen lead."""
    song = Song(160, 40)
    song.channel(LEAD, SHAMISEN, 112, 60, 40)
    song.channel(DOUBLE, FLUTE, 74, 76, 60)
    song.channel(ARP, KOTO, 82, 92, 40)
    song.channel(PAD, TREMOLO, 52, 64, 70)
    song.channel(BASS, FINGER_BASS, 104, 64, 10)
    song.channel(DRUM_TAIKO, TAIKO, 100, 64, 40)
    intro = ["Em", "F", "Em", "F"]
    a = ["Em", "F", "Em", "Am", "Dm", "C", "B5", "B5"]
    a_end = ["Em", "F", "Em", "Am", "Dm", "C", "B5", "Em"]
    b = ["Am", "F", "C", "E", "Am", "F", "B5", "B5"]
    c = ["Em", "F", "Em", "F", "Em", "F", "B5", "B5"]
    outro = ["Am", "B5", "Em", "B5"]
    chords = intro + a + b + c + a_end + outro
    melody_a = """E5:3 F5:1 E5:2 B4:2 C5:4 B4:4 | A4:2 B4:2 C5:2 F5:2 E5:8 |
        E5:2 G5:2 B5:4 A5:2 G5:2 F5:2 E5:2 | A5:12 r:4 |
        D5:2 F5:2 A5:4 C6:4 B5:2 A5:2 | G5:4 E5:4 C5:4 E5:4 |"""
    song.melody(LEAD, 4, melody_a + "F5:6 E5:2 D#5:4 B4:4 | F#5:4 A5:4 B5:8", 94, gate=0.7)
    song.melody(LEAD, 12, """C6:6 B5:2 A5:4 E5:4 | F5:6 A5:2 C6:8 | E6:4 D6:2 C6:2 B5:4 G5:4 | G#5:8 B5:8 |
        A5:2 B5:2 C6:4 E6:4 C6:4 | F6:8 E6:4 C6:4 | B5:4 A5:2 F5:2 D#5:4 F#5:4 | B5:12 r:4""", 96, gate=0.7)
    song.melody(LEAD, 20, """E5:3 E5:3 E5:2 r:8 | F5:3 F5:3 F5:2 r:8 | E5:3 G5:3 B5:2 r:8 | C6:3 B5:3 A5:2 r:8 |
        B5:16 | C6:16 | B5:8 A5:8 | F#5:4 A5:4 B5:4 D#6:4""", 96, gate=0.6)
    song.melody(LEAD, 28, melody_a + "D#5:2 F#5:2 A5:2 B5:2 C6:4 B5:4 | E5:12 r:4", 96, gate=0.7)
    song.melody(DOUBLE, 12, """C6:6 B5:2 A5:4 E5:4 | F5:6 A5:2 C6:8 | E6:4 D6:2 C6:2 B5:4 G5:4 | G#5:8 B5:8 |
        A5:2 B5:2 C6:4 E6:4 C6:4 | F6:8 E6:4 C6:4 | B5:4 A5:2 F5:2 D#5:4 F#5:4 | B5:12 r:4""", 66, octave_shift=-1)
    song.melody(DOUBLE, 20, "r:16 | r:16 | r:16 | r:16 | E6:16 | F6:16 | E6:8 C6:8 | B5:16", 70)
    arpeggio(song, ARP, chords, [0, 1, 2, 3, 2, 1, 4, 2], 1, 60, octave=4, gate=1.3)
    pad(song, PAD, chords, 40)
    bass(song, BASS, chords, "r.rr.rr.r.rr.ro.", 84)
    lay_drums(song, 0, 4, {"k": "x...x...x...x...", "h": "..x...x...x...x."}, FILL, crash=False)
    lay_drums(song, 4, 8, DRIVE_B, FILL)
    lay_drums(song, 12, 8, DRIVE, FILL)
    lay_drums(song, 20, 8, HALF, FILL)
    lay_drums(song, 28, 8, DRIVE_B, FILL)
    lay_drums(song, 36, 4, DRIVE, FILL, crash=False)
    for bar in range(40):
        pattern = "X..x..X...x.X..." if 20 <= bar < 28 else "x.......x..x...."
        hits(song, DRUM_TAIKO, bar, pattern, 43, 72)
    return song


def boss() -> Song:
    """朱印之誓 / Oath of the Vermilion Seal: D minor with in-scale flats, 170 BPM, violin+shakuhachi."""
    song = Song(170, 56)
    song.channel(LEAD, VIOLIN, 108, 58, 45)
    song.channel(DOUBLE, SHAKUHACHI, 88, 72, 50)
    song.channel(ARP, SHAMISEN, 82, 90, 30)
    song.channel(COMP, BRASS, 76, 40, 40)
    song.channel(PAD, TREMOLO, 56, 64, 60)
    song.channel(BASS, FINGER_BASS, 106, 64, 10)
    song.channel(DRUM_TAIKO, TAIKO, 104, 64, 40)
    song.channel(EXTRA, TIMPANI, 90, 64, 40)
    intro = ["Dm", "Dm", "Bb", "A"]
    a1 = ["Dm", "Bb", "C", "Dm", "Gm", "Eb", "A", "A"]
    a2 = ["Dm", "Bb", "C", "Dm", "Gm", "Eb", "A", "Dm"]
    b = ["Bb", "C", "Am", "Dm", "Gm", "C", "F", "A"]
    c = ["Dm", "Dm", "Eb", "Eb", "Dm", "Dm", "A", "A"]
    outro = ["Bb", "C", "A", "A"]
    chords = intro + a1 + a2 + b + b + c + a2 + outro
    melody_a = """D5:4 A5:4 G5:2 F5:2 E5:2 F5:2 | D5:6 F5:2 Bb5:4 A5:4 |
        G5:2 A5:2 C6:4 Bb5:2 A5:2 G5:4 | A5:12 r:4 |
        G5:2 Bb5:2 D6:4 C6:2 Bb5:2 A5:2 G5:2 | Bb5:4 Eb6:4 D6:2 C6:2 Bb5:4 |"""
    melody_b = """F6:6 D6:2 Bb5:8 | G6:6 E6:2 C6:8 | E6:4 C6:4 A5:4 C6:4 | D6:8 A5:8 |
        Bb5:4 D6:4 G6:4 F6:2 Eb6:2 | E6:4 G6:4 C7:4 Bb6:4 |"""
    lines = [
        (4, melody_a + "A5:4 C#6:4 E6:4 G6:4 | F6:4 E6:2 D6:2 C#6:8"),
        (12, melody_a + "A5:2 Bb5:2 C#6:2 E6:2 D6:4 C#6:4 | D6:12 r:4"),
        (20, melody_b + "A6:6 G6:2 F6:4 C6:4 | E6:8 C#6:8"),
        (28, melody_b + "A6:4 F6:4 C6:4 A5:4 | C#6:4 E6:4 A6:8"),
        (36, "D6:16 | Eb6:16 | G6:8 F6:8 | Eb6:16 | D6:16 | F6:16 | E6:16 | C#6:8 E6:8"),
        (44, melody_a + "A5:2 Bb5:2 C#6:2 E6:2 D6:4 C#6:4 | D6:12 r:4"),
    ]
    for first, text in lines:
        song.melody(LEAD, first, text, 96, gate=0.95)
        song.melody(DOUBLE, first, text, 72, gate=0.9, octave_shift=-1)
    arpeggio(song, ARP, chords, [0, 0, 2, 0, 3, 0, 2, 1], 1, 62, octave=3, gate=0.9)
    stabs(song, COMP, intro + [None] * 48 + outro, "X..x..x...x.x...", 74, octave=4, length=1.5)
    stabs(song, COMP, [None] * 4 + a1 + a2 + b + b + [None] * 8 + a2 + [None] * 4, "x.......x.......", 50, octave=4, length=6)
    pad(song, PAD, chords, 42)
    bass(song, BASS, chords, "rr.rr.rr.rr.rorf", 82)
    lay_drums(song, 0, 4, {"k": "X..x..x...x.x...", "s": "X..x..x...x.x..."}, BOSS_FILL, crash=False)
    for first, groove in ((4, BOSS_BEAT), (12, BOSS_BEAT), (20, DRIVE_B), (28, BOSS_BEAT), (36, HALF), (44, BOSS_BEAT)):
        lay_drums(song, first, 8, groove, BOSS_FILL)
    lay_drums(song, 52, 4, {"k": "X..x..x...x.x...", "s": "X..x..x...x.x..."}, BOSS_FILL, crash=False)
    for bar in range(56):
        hits(song, DRUM_TAIKO, bar, "X...x...X...x.x." if 36 <= bar < 44 else "x.......x.......", 45, 76)
        if bar % 4 == 0:
            hits(song, EXTRA, bar, "x...............", 38, 80)
    return song


def boss_final() -> Song:
    """最後の御札 / The Last Talisman: E minor, 3-3-2 syncopation, 180 BPM."""
    song = Song(180, 48)
    song.channel(LEAD, SHAKUHACHI, 110, 64, 45)
    song.channel(DOUBLE, VIOLIN, 92, 50, 45)
    song.channel(ARP, KOTO, 86, 90, 30)
    song.channel(COMP, SHAMISEN, 84, 36, 30)
    song.channel(PAD, STRINGS_FAST, 60, 64, 60)
    song.channel(BASS, FINGER_BASS, 108, 64, 10)
    song.channel(DRUM_TAIKO, TAIKO, 108, 64, 40)
    song.channel(EXTRA, BELLS, 62, 70, 80)
    intro = ["Em", "C", "D", "B"]
    a1 = ["Em", "C", "D", "Em", "Am", "F", "B", "B"]
    a2 = ["Em", "C", "D", "Em", "Am", "F", "B", "Em"]
    b = ["C", "D", "Bm", "Em", "Am", "D", "G", "B"]
    c = ["Em", "F", "Em", "F", "Am", "B", "Em", "B"]
    outro = ["Am", "F", "B", "B"]
    chords = intro + a1 + a2 + b + c + a2 + outro
    melody_a = """E5:3 B5:3 E6:2 D6:2 B5:2 G5:4 | E5:3 G5:3 C6:2 B5:4 G5:4 |
        F#5:3 A5:3 D6:2 C6:2 A5:2 F#5:4 | G5:2 F#5:2 E5:12 |
        A5:3 C6:3 E6:2 F6:2 E6:2 C6:4 | F6:3 E6:3 C6:2 A5:8 |"""
    lines = [
        (4, melody_a + "B5:3 C6:3 D#6:2 F#6:4 A6:4 | G6:4 F#6:4 D#6:4 B5:4"),
        (12, melody_a + "B5:3 D#6:3 F#6:2 A6:4 G6:2 F#6:2 | E6:12 r:4"),
        (20, """G6:8 E6:4 C6:4 | F#6:8 D6:4 A5:4 | B5:4 D6:4 F#6:4 B6:4 | G6:12 r:4 |
            E6:4 A6:4 C7:4 B6:4 | A6:6 F#6:2 D6:8 | B6:4 G6:4 D6:4 G6:4 | F#6:4 A6:4 B6:8"""),
        (28, """E6:3 E6:3 F6:2 E6:8 | F6:3 F6:3 A6:2 F6:8 | E6:3 B5:3 E6:2 G6:8 | A6:3 F6:3 C6:2 A5:8 |
            E6:16 | F#6:16 | G6:8 B6:8 | A6:8 F#6:8"""),
        (36, melody_a + "B5:3 D#6:3 F#6:2 A6:4 G6:2 F#6:2 | E6:12 r:4"),
    ]
    for first, text in lines:
        song.melody(LEAD, first, text, 98, gate=0.9)
        song.melody(DOUBLE, first, text, 70, gate=0.9, octave_shift=-1)
    arpeggio(song, ARP, chords, [0, 2, 4, 2, 3, 5, 4, 2], 1, 58, octave=4, gate=1.2)
    stabs(song, COMP, chords, "x..x..x.x..x..x.", 64, octave=4, length=0.7)
    pad(song, PAD, chords, 44)
    bass(song, BASS, chords, "r..r..o.r..r..f.", 88)
    lay_drums(song, 0, 4, {"k": "x..x..x.x..x..x.", "s": "......x.......x."}, BOSS_FILL, crash=False)
    for first, groove in ((4, BOSS_BEAT), (12, BOSS_BEAT), (20, DRIVE_B), (28, HALF), (36, BOSS_BEAT)):
        lay_drums(song, first, 8, groove, BOSS_FILL)
    lay_drums(song, 44, 4, BOSS_BEAT, BOSS_FILL, crash=False)
    for bar in range(48):
        hits(song, DRUM_TAIKO, bar, "X..x..x.X..x..x." if 28 <= bar < 36 else "x..x..x.........", 43, 74)
        if bar % 8 == 4:
            song.add(EXTRA, bar * 16, 16, 76, 70)
    return song


def results() -> Song:
    """紙上の夜明け / Dawn on Rice Paper: G major pentatonic (yo scale feel), 76 BPM, koto + harp."""
    song = Song(76, 20)
    song.channel(LEAD, KOTO, 108, 60, 60)
    song.channel(DOUBLE, SHAKUHACHI, 70, 76, 80)
    song.channel(ARP, HARP, 70, 80, 70)
    song.channel(PAD, STRINGS_SLOW, 58, 64, 90)
    song.channel(BASS, FRETLESS, 72, 64, 40)
    chords = ["G", "Em", "C", "D", "G", "Em", "Am", "D", "C", "D", "Bm", "Em", "C", "D", "G", "G", "C", "Am", "D", "D"]
    song.melody(LEAD, 0, """D5:4 B4:2 A4:2 G4:8 | E5:4 D5:2 B4:2 G4:4 A4:4 | E5:6 G5:2 E5:4 D5:4 | A4:12 r:4 |
        D5:4 E5:2 G5:2 A5:8 | B5:4 A5:2 G5:2 E5:8 | A5:4 G5:2 E5:2 D5:4 E5:4 | D5:12 r:4 |
        G5:6 E5:2 D5:4 E5:4 | A5:8 F#5:4 D5:4 | B5:6 A5:2 F#5:4 D5:4 | E5:12 r:4 |
        E5:4 G5:4 C6:4 B5:4 | A5:6 B5:2 A5:4 F#5:4 | G5:16 | r:8 D5:4 B4:4 |
        C5:6 E5:2 G5:8 | A5:6 G5:2 E5:8 | D5:8 E5:4 F#5:4 | A5:12 r:4""", 84, gate=1.0)
    song.melody(DOUBLE, 8, "E5:16 | F#5:16 | D5:16 | B4:16 | C5:16 | D5:16 | B4:16 | B4:16", 56, gate=0.95)
    arpeggio(song, ARP, chords, [0, 1, 2, 3, 4, 3, 2, 1], 2, 46, octave=3)
    pad(song, PAD, chords, 44)
    for bar, name in enumerate(chords):
        song.add(BASS, bar * 16, 15, {"G": 43, "E": 40, "C": 36, "D": 38, "A": 45, "B": 47}[name[0]], 64)
    return song


SONGS = {
    "title": title, "stage_a": stage_a, "stage_b": stage_b,
    "boss": boss, "boss_final": boss_final, "results": results,
}
