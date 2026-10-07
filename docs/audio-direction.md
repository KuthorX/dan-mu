# Audio direction: night scroll and ofuda

## Concept
The game looks like a hanging scroll painted at night: ink-wash sky, rice-paper talismans and a vermilion seal. The score works the same way. Plucked strings (koto, shamisen) carry the rhythm the way brush strokes carry the picture. The shakuhachi is the night air. Taiko and bronze are used only where the art uses vermilion: bosses, bombs and death. Nothing is chiptune and nothing is neon. Every frequent sound is paper or wood. The big sounds are skin and metal.

Touhou convention is kept: stages are fast and melodic, bosses are faster and denser, and the title and results cues are slow.

## Music (audio/music/*.mp3, 44.1 kHz stereo, 128 kbps CBR, seamless loops)
| Cue | Used for | Key / mode | Tempo | Length | Lead / texture | What it should feel like |
| --- | --- | --- | --- | --- | --- | --- |
| `title` 掛軸夜想 Nocturne of the Hanging Scroll | title menu | D in-scale (D Eb G A Bb) | 76 BPM | 63.2 s (20 bars) | shakuhachi melody, koto 8th-note arpeggios, slow strings, fretless bass, a taiko hit every two bars | Unrolling a scroll at night: quiet and spacious, with a b2 (Eb) colour. No drum kit. |
| `stage_a` 墨風参道 Ink Wind on the Shrine Road | stages 1-3 | A minor with hirajoshi colour (F, B) | 150 BPM | 76.8 s (48 bars) | shakuhachi lead doubled by koto an octave below, koto 16th ostinato, offbeat shamisen stabs, pumping finger bass, rock kit and taiko | Driving and bright. Structure: intro, A, A', B (higher register), breakdown with a koto solo and half-time drums, A'. |
| `stage_b` 提灯行列 Lantern Procession at the Torn Border | stages 4-5, endless waves | E in-scale (E F A B C) | 160 BPM | 60.0 s (40 bars) | shamisen lead (short gate), flute answering in B, tremolo strings, taiko 3-3-2 hits in the breakdown | Darker and faster than stage_a. The F-over-E half-step clash is the hook. |
| `boss` 朱印之誓 Oath of the Vermilion Seal | bosses 1-4 | D minor with in-scale flats (Eb chord, A major dominant) | 170 BPM | 79.1 s (56 bars) | violin lead doubled by shakuhachi an octave below, 16th shamisen ostinato, brass stabs in the intro and outro, timpani every four bars, 16th hats | Spell-card urgency: busy, dense and dramatic, with a climbing breakdown over tremolo strings. |
| `boss_final` 最後の御札 The Last Talisman | stage 5 boss, endless bosses | E minor with Phrygian F | 180 BPM | 64.0 s (48 bars) | shakuhachi lead and violin, melody phrased 3-3-2 against the beat, koto and shamisen ostinati, tubular bell swells | The fastest and most syncopated cue. It should feel like a different fight, not the boss theme played faster. |
| `results` 紙上の夜明け Dawn on Rice Paper | after a clear or a game over (starts once the jingle ends) | G major pentatonic (yo-scale feel) | 76 BPM | 63.2 s (20 bars) | koto melody, harp arpeggios, slow strings, shakuhachi long tones in the middle | Morning light on paper. Calm and resolved, the only major-mode cue. |

Loudness: every cue is normalised to -18 LUFS integrated, and true peak is at most -1.8 dBTP. In game the music player sits at -2 dB.

Loop method: each cue is rendered three times back to back and the middle pass is kept, so the reverb tail of the loop end is already sounding at the loop start. The first 50 ms are crossfaded with the audio that followed the middle pass. Godot reports the exact loop lengths above, which means the LAME gapless header is honoured. The jump at the seam is at most 0.012, well below the 99.9th-percentile sample step of each track (0.057-0.163).

## Sound effects (audio/sfx/*.wav, 44.1 kHz mono 16-bit, imported as QOA)
All effects are peak-normalised to -1.5 dBFS (true peak at most -1.1 dBTP). Relative loudness is set per event in `scripts/audio_manager.gd`.

| Event | File | Sound | In-game level / rate limit |
| --- | --- | --- | --- |
| player shot | `shot`, `shot_focus` | 50 ms band-passed brush flick (1.4-3.8 kHz, or 0.9-2.4 kHz focused) with a soft sine thump. No pitch, so it doesn't fatigue. | -22 / -21 dB, at most one every 60 ms |
| enemy fire | `enemy_fire`, `enemy_ring`, `enemy_spiral` | breathy puffs with a falling tone. Ring is lower; spiral sweeps its band downward. | -20 to -18 dB, 0.1-0.18 s |
| graze | `graze` | paper hiss (3.5-7 kHz) plus a faint E7 chime | -15 dB, 35 ms |
| enemy hit (new) | `enemy_hit` | dull wood tock at 820 Hz | -20 dB, 80 ms |
| enemy kill | `enemy_down` | paper burst that closes from 6 kHz to 900 Hz, plus a "pon" 330→150 Hz | -10 dB |
| point / power item | `pickup`, `pickup_power` | Karplus-Strong koto pluck G6, or C6 then G6 | -14 / -13 dB |
| extend (new) | `extend` | koto arpeggio G-B-D-G with a bell | -5 dB |
| bomb | `bomb` | taiko strike, rising wind, low gong shimmer (1.8 s) | -3 dB |
| spell card declare (new) | `spell_declare` | seal stamp (90 Hz thud with a paper slap), then an in-scale koto triad D-A-Eb with a bell | -4 dB |
| spell break | `phase_break` | paper tear, taiko, D6+A6 bell chord | -4 dB |
| player death | `player_hit` | "pichuun": short blip, then a falling vibrato tone 1.4 kHz→180 Hz over a taiko thud | -3 dB |
| UI move (new) | `ui_move` | tiny wood click | -12 dB |
| confirm | `confirm` | hyoshigi double clack with a pluck | -8 dB |
| pause / cancel (new) | `pause`, `cancel` | low wood tocks, falling | -8 / -9 dB |
| stage clear | `stage_clear` | koto arpeggio to a held E6 over A major strings (2.6 s) | jingle player -4 dB |
| game clear | `game_clear` | koto run in G pentatonic, shakuhachi, tubular bell (4.2 s) | jingle |
| game over (new) | `game_over` | shakuhachi falling A-G-Eb-D over low koto (3.6 s) | jingle |

## Sources and licences
- All music and jingles were composed in code (`tools/audio/score.py`, `tools/audio/sfx.py`) and rendered with FluidSynth using MuseScore's **MS Basic** General MIDI soundfont (MIT; derived from FluidR3). The licence and attribution are in `audio/MS-Basic-soundfont-LICENSE.md`.
- All other effects are synthesised with numpy/scipy. No samples or packs were downloaded.

## Regenerating
```
python3 tools/audio/render_music.py   # audio/music/*.mp3 (needs fluidsynth, lame, ffmpeg)
python3 tools/audio/sfx.py            # audio/sfx/*.wav
python3 tools/audio/analyze.py        # duration, LUFS, RMS, true peak, loop seam; spectrograms in tools/audio/.cache/spectra
```
The music `.import` files set `loop=true`.
