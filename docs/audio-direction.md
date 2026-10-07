# Audio direction: night scroll and ofuda

## Concept
The game looks like a hanging scroll painted at night: ink-wash sky, rice-paper talismans and a vermilion seal. The score works the same way. Plucked strings (a Vital physical-model "guzheng", Serum 2's metallic Harp Wire standing in for shamisen) carry the rhythm the way brush strokes carry the picture. Breathy pipes (Serum 2 Pan Flute and Flute) are the night air. Taiko and bronze (the Serum 2 Wudang Mountain temple bell) are used only where the art uses vermilion: bosses, bombs and death. Nothing is chiptune and nothing is neon. Every frequent sound is paper or wood. The big sounds are skin and metal.

Touhou convention is kept: stages are fast and melodic, bosses are faster and denser, and the title and results cues are slow.

## Music (audio/music/*.ogg, 44.1 kHz stereo Ogg Vorbis, about 110 kbps, sample-exact seamless loops)
| Cue | Used for | Key / mode | Tempo | Length | Lead / texture | What it should feel like |
| --- | --- | --- | --- | --- | --- | --- |
| `title` 掛軸夜想 Nocturne of the Hanging Scroll | title menu | D in-scale (D Eb G A Bb) | 76 BPM | 63.2 s (20 bars) | Serum 2 Pan Flute (xiao) melody, Vital Plucked String 8th-note arpeggios, Serum 2 Bamboo Forest pad, MS Basic fretless bass, MS Basic taiko every two bars, a Wudang Mountain temple bell every four bars | Unrolling a scroll at night: quiet and spacious, with a b2 (Eb) colour. No drum kit. |
| `stage_a` 墨風参道 Ink Wind on the Shrine Road | stages 1-3 | A minor with hirajoshi colour (F, B) | 150 BPM | 76.8 s (48 bars) | Serum 2 Flute (dizi) lead doubled by MS Basic koto an octave below, Vital Plucked String 16th ostinato, offbeat Serum 2 Harp Wire stabs, Vital Strings Section pad, MS Basic finger bass, kit and taiko | Driving and bright. Structure: intro, A, A', B (higher register), breakdown with a koto solo and half-time drums, A'. |
| `stage_b` 提灯行列 Lantern Procession at the Torn Border | stages 4-5, endless waves | E in-scale (E F A B C) | 160 BPM | 60.0 s (40 bars) | Serum 2 Harp Wire lead (short gate, shamisen role), Serum 2 Pan Flute answering in B, Vital Plucked String arpeggios, Serum 2 Strings Elegy pad, MS Basic bass, kit and taiko 3-3-2 hits in the breakdown | Darker and faster than stage_a. The F-over-E half-step clash is the hook. |
| `boss` 朱印之誓 Oath of the Vermilion Seal | bosses 1-4 | D minor with in-scale flats (Eb chord, A major dominant) | 170 BPM | 79.1 s (56 bars) | Vital A Night in Kalyan reed lead doubled by MS Basic shakuhachi an octave below, 16th Serum 2 Harp Wire ostinato, MS Basic brass stabs in the intro and outro, Serum 2 Ghost Voices pad, timpani every four bars plus Vital Cinema Bells every eight, 16th hats | Spell-card urgency: busy, dense and dramatic, with a climbing breakdown over a ghost-voice pad. |
| `boss_final` 最後の御札 The Last Talisman | stage 5 boss, endless bosses | E minor with Phrygian F | 180 BPM | 64.0 s (48 bars) | Serum 2 Flute lead with MS Basic strings an octave below, melody phrased 3-3-2 against the beat, Vital Plucked String and Serum 2 Harp Wire ostinati, Vital Strings Section pad, Wudang Mountain bell swells | The fastest and most syncopated cue. It should feel like a different fight, not the boss theme played faster. |
| `results` 紙上の夜明け Dawn on Rice Paper | after a clear or a game over (starts once the jingle ends) | G major pentatonic (yo-scale feel) | 76 BPM | 63.2 s (20 bars) | Vital Plucked String melody, MS Basic harp arpeggios, Serum 2 Strings Elegy pad, Serum 2 Pan Flute long tones in the middle | Morning light on paper. Calm and resolved, the only major-mode cue. |

Loudness: every cue is normalised to -18 LUFS integrated with true peak at most -1 dBTP (measured numbers below). In game the music player sits at -2 dB.

Mixing: each part is rendered to its own stem, measured, and set to a fixed loudness for its role (lead -20 LUFS; arpeggio -24.5; double, pad, bass and drums -27; comp -28; taiko -28.5; bells -29; title and results pull bass and taiko down a further 2-2.5 dB) before a gentle 2:1 bus compressor and the final normalisation. This keeps the balance consistent across cues without listening.

Loop method: the score is rendered once with a 6 s tail, and the tail (reverb, bell and pad releases) is folded back onto the start of the loop, so the loop start already contains the end's decay. The seam is checked by comparing the sample jump across it with the 99th-percentile sample step.

Measured (decoded MP3, ffmpeg ebur128; seam = sample jump across the loop point vs the 99.9th-percentile sample step):

| Cue | Length | LUFS | True peak | Seam jump / p99.9 step |
| --- | --- | --- | --- | --- |
| title | 63.16 s | -18.4 | -5.8 dBTP | 0.0045 / 0.108 |
| stage_a | 76.80 s | -18.4 | -6.7 dBTP | 0.0052 / 0.068 |
| stage_b | 60.00 s | -18.4 | -5.9 dBTP | 0.0065 / 0.086 |
| boss | 79.06 s | -18.4 | -4.3 dBTP | 0.0088 / 0.093 |
| boss_final | 64.00 s | -18.4 | -7.4 dBTP | 0.0043 / 0.066 |
| results | 63.16 s | -18.4 | -5.1 dBTP | 0.0065 / 0.100 |

## Sound effects (audio/sfx/, 44.1 kHz, mono effects and stereo jingles; cues over 0.5 s are Ogg Vorbis, shorter ones 16-bit WAV imported as QOA)
Every effect layers at least two sources: preset hits cut from one "SFX sheet" render (`tools/audio/sfx_sheet.py`: Vital Ceramic and Plucked String, Serum 2 Harp Wire, Wudang Mountain and Pan Flute, Vital Strings Section, MS Basic taiko and wood blocks) plus numpy synthesis (brush noise, paper bursts, the death glide). Effects are normalised to -16 LUFS (shorter ones measured over a 400 ms window), never above -1 dBTP; very short or quiet ones stop at the peak ceiling. Relative loudness is set per event in `scripts/audio_manager.gd`, re-levelled so the in-game balance matches the previous mix.

| Event | File | Sound | In-game level / rate limit |
| --- | --- | --- | --- |
| player shot | `shot`, `shot_focus` | 50 ms band-passed brush flick (1.4-3.8 kHz, or 0.9-2.4 kHz focused) with a soft thump and a faint Vital Ceramic tick. Mostly unpitched, so it doesn't fatigue. | -23 / -22.5 dB, at most one every 60 ms |
| enemy fire | `enemy_fire`, `enemy_ring`, `enemy_spiral` | Serum 2 Harp Wire plucks (E5, A4, or a falling B-G-E for spiral) over breathy noise puffs | -26 to -23 dB, 0.1-0.18 s |
| graze | `graze` | paper hiss (3.5-7 kHz) plus a Vital Ceramic tick | -18 dB, 35 ms |
| enemy hit | `enemy_hit` | MS Basic high wood block over a synthesised 820 Hz tock | -22.5 dB, 80 ms |
| enemy kill | `enemy_down` | paper burst that closes from 6 kHz to 900 Hz, a "pon" 330→150 Hz, a low Plucked String A3 and a low wood block | -12 dB |
| point / power item | `pickup`, `pickup_power` | Plucked String G6 (or C6 then G6) with a Ceramic sparkle | -20.5 / -18 dB |
| extend | `extend` | Plucked String arpeggio G-B-D-G with a Wudang Mountain bell | -3.5 dB |
| bomb | `bomb` | MS Basic taiko, rising wind, low Wudang Mountain bell (1.8 s) | -6 dB |
| spell card declare | `spell_declare` | seal stamp (90 Hz thud with a paper slap) and taiko, then an in-scale Plucked String triad D-A-Eb with a Wudang bell | -4 dB |
| spell break | `phase_break` | paper tear, taiko, D5+A5 Wudang bell chord | -3.5 dB |
| player death | `player_hit` | "pichuun": short blip and a Harp Wire ping, then a falling vibrato tone 1.4 kHz→180 Hz over a taiko thud | -3 dB |
| UI move | `ui_move` | tiny wood click, Ceramic tick and claves | -18 dB |
| confirm | `confirm` | double wood-block clack with a Plucked String D6 | -7.5 dB |
| pause / cancel | `pause`, `cancel` | low wood-block tocks, falling | -6.5 / -9.5 dB |
| stage clear | `stage_clear` | Plucked String arpeggio to a held E6 over A major Vital strings, Wudang bell (2.8 s) | jingle player -5 dB |
| game clear | `game_clear` | Plucked String run in G pentatonic, Pan Flute, strings, Wudang bell (4.4 s) | jingle |
| game over | `game_over` | Pan Flute falling A-G-Eb-D over low Plucked String, a soft Wudang bell (3.8 s) | jingle |

## Sources and licences
- Music and SFX were composed programmatically by AI (Claude): the notes are code (`tools/audio/score.py`, `tools/audio/sfx_sheet.py`) and the arrangement, mix and SFX layering are code too (`tools/audio/rescore.py`, `tools/audio/sfx.py`, `tools/audio/palette.py`). Everything was rendered offline with Vital, Serum 2 and the MS Basic soundfont through the audiokit renderer (pedalboard-hosted plugins, FluidSynth, pedalboard built-in effects).
- **Vital** (Matt Tytel; the synth is GPL-3.0). Presets: Factory "Plucked String"; Yuli Yolo pack "A Night in Kalyan"; In The Mix pack "Strings Section"; Billain pack "Cinema Bells"; Databroth pack "Ceramic".
- **Serum 2** (Xfer Records) factory presets: WIND Pan Flute, WIND Flute, PL Harp Wire, BL Wudang Mountain, PD Bamboo Forest Reflections, STR Strings Ensemble - Elegy, PD Ghost Voices.
- **MS Basic** General MIDI soundfont by MuseScore (MIT; derived from FluidR3). Used for koto, shakuhachi, taiko, timpani, harp, brass, strings, basses, the drum kit and wood blocks. The licence and attribution are in `audio/MS-Basic-soundfont-LICENSE.md`.
- No sample packs or downloaded audio are used, and no effect is a bare preset hit.

## Regenerating
Needs the audiokit renderer in `/tmp/audiokit` (arm64 venv, Vital and Serum 2 installed; libsndfile writes the Ogg Vorbis files) and `ffmpeg`. Renders never play audio and never open windows; `lockf` serialises them.
```
PY="arch -arm64 /tmp/audiokit/venv/bin/python"
RENDER="lockf -t 3600 /tmp/audiokit/render.lock $PY /tmp/audiokit/render.py"
$PY tools/audio/rescore.py prepare                      # MIDI + stem specs (tools/audio/.cache/rescore)
for c in title stage_a stage_b boss boss_final results; do $RENDER tools/audio/.cache/rescore/${c}_stems.json; done
$PY tools/audio/rescore.py mix                          # role-levelled mix specs
for c in title stage_a stage_b boss boss_final results; do $RENDER tools/audio/.cache/rescore/${c}_mix.json; done
$PY tools/audio/rescore.py finish                       # audio/music/*.ogg
$PY tools/audio/sfx_sheet.py && $RENDER tools/audio/.cache/sfx_sheet/sheet.json
$PY tools/audio/sfx.py                                  # audio/sfx/*.ogg + *.wav
python3 tools/audio/analyze.py                          # duration, LUFS, true peak, loop seam, spectrograms
```
The music `.import` files set `loop=true`.
