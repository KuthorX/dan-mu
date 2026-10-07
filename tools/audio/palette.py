"""Instrument palette for the DanMu rescore, as audiokit (/tmp/audiokit/render.py) specs.

Only the allowed sources are used: Vital and Serum 2 factory presets (hosted headless by
pedalboard), FluidSynth with MuseScore's MS Basic soundfont, and pedalboard built-in FX.
`transpose` corrects presets that sound at a different octave from the played note.
"""
import os

VITAL = os.path.expanduser("~/Music/Vital")
SERUM = "/Library/Audio/Presets/Xfer Records/Serum 2 Presets/Presets/Factory"
DRUM_BANK = 0  # channel 10 (index 9) is the GM percussion channel in FluidSynth


def _vital(path: str, transpose: int = 0) -> dict:
    return {"instrument": {"type": "vital", "preset": f"{VITAL}/{path}"}, "transpose": transpose}


def _serum(path: str, transpose: int = 0) -> dict:
    return {"instrument": {"type": "serum2", "preset": f"{SERUM}/{path}.SerumPreset"}, "transpose": transpose}


def _gm(program: int, bank: int = 0) -> dict:
    return {"instrument": {"type": "fluidsynth", "program": program, "bank": bank, "gain": 0.6}, "transpose": 0}


PALETTE = {
    # Vital
    "guzheng": _vital("Factory/Presets/Plucked String.vital"),
    "kalyan": _vital("Yuli Yolo/Presets/Factory Presets/A Night in Kalyan.vital"),
    "strings": _vital("In The Mix/Presets/Strings Section.vital"),
    "cinema_bells": _vital("Billain/Presets/Factory Presets/Cinema Bells.vital", transpose=24),
    "ceramic": _vital("Databroth/Presets/Factory Presets/Ceramic.vital"),
    # Serum 2
    "pan_flute": _serum("Woodwind/WIND - Pan Flute"),
    "flute": _serum("Woodwind/WIND - Flute"),
    "harp_wire": _serum("Pluck/PL - Harp Wire"),
    "wudang": _serum("Bell/BL - Wudang Mountain"),
    "bamboo_pad": _serum("Pad/PD - Bamboo Forest Reflections"),
    "elegy": _serum("String/STR - Strings Ensemble - Elegy"),
    "ghost_voices": _serum("Pad/PD - Ghost Voices"),
    # FluidSynth + MS Basic (GM)
    "gm_koto": _gm(107),
    "gm_shakuhachi": _gm(77),
    "gm_taiko": _gm(116),
    "gm_timpani": _gm(47),
    "gm_harp": _gm(46),
    "gm_brass": _gm(61),
    "gm_strings": _gm(48),
    "gm_finger_bass": _gm(33),
    "gm_fretless": _gm(35),
    "gm_kit": _gm(0, DRUM_BANK),
}

PRESET_CREDITS = {
    "guzheng": "Vital factory - Plucked String",
    "kalyan": "Vital, Yuli Yolo pack - A Night in Kalyan",
    "strings": "Vital, In The Mix pack - Strings Section",
    "cinema_bells": "Vital, Billain pack - Cinema Bells",
    "ceramic": "Vital, Databroth pack - Ceramic",
    "pan_flute": "Serum 2 factory - WIND Pan Flute",
    "flute": "Serum 2 factory - WIND Flute",
    "harp_wire": "Serum 2 factory - PL Harp Wire",
    "wudang": "Serum 2 factory - BL Wudang Mountain",
    "bamboo_pad": "Serum 2 factory - PD Bamboo Forest Reflections",
    "elegy": "Serum 2 factory - STR Strings Ensemble Elegy",
    "ghost_voices": "Serum 2 factory - PD Ghost Voices",
}


def track(name: str, midi: str, index: int, sound: str, fx=None, pan: float = 0.0, gain_db: float = 0.0) -> dict:
    """One render.py track entry for `sound` from PALETTE."""
    entry = PALETTE[sound]
    return {
        "name": name, "midi": midi, "track": index, "transpose": entry["transpose"],
        "instrument": dict(entry["instrument"]), "fx": list(fx or []), "pan": pan, "gain_db": gain_db,
    }
