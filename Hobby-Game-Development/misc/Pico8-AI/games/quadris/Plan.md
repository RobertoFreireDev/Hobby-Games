# QUADRIS — definitions

A Tetris variant for PICO-8 where gravity points **inward from all four edges**. Pieces spawn at
the middle of an edge and fall toward a permanently-solid 4×4 block at the centre. Instead of
clearing full *rows*, you clear full *rings* — square annuli concentric with the centre — after
which everything outside the cleared ring shifts one step inward.

This document is the spec: every definition, constant and rule in the shipped cart.

**Files:** [game.lua](game.lua) is the whole game. [game.p8](game.p8) is the cart —
`#include game.lua` plus generated `__sfx__` and `__music__`. No `__gfx__`, `__map__` or `__gff__`:
every block is a `rectfill` and all text uses the built-in font.

---

## 1. Geometry

| Thing | Value |
|---|---|
| Screen | 128×128, 30 fps (`_update`) |
| Border | 8 px on all four sides, colour 5 (dark grey) |
| Playfield | x,y = 8..119 → 112×112 px |
| Block | 4×4 px → **28×28 grid** |
| Score bar | the bottom 8 px margin (y 120..127) |

- Cell `(cx,cy)` → screen pixel `(8+cx*4, 8+cy*4)`.
- **Centre solid:** cells 12..15 in both axes (4×4), colour 5. Pre-filled into the board at init, so
  it needs no special case in collision — it is just occupied space that never clears. It exists so
  the first pieces have something to land against.
- **Board storage:** flat table `bd[x+y*28]`, value = colour, `nil` = empty.

### Rings

`ringof(x,y) = min(x, y, 27-x, 27-y)`

- Ring `r` is the square annulus with side `s = 28-2r`, holding `4s-4 = 108-8r` cells.
- **Rings 0..11 are playable.** Ring 0 = the outer edge (108 cells); ring 11 = the 6×6 annulus
  hugging the centre (20 cells). Rings 12–13 *are* the centre block and are never cleared.
- Inner rings are small and clear easily, outer rings are huge, so play naturally funnels inward —
  which the inward shift then reinforces.

---

## 2. Coordinate systems

All four spawn sides share **one** code path via a per-side transform. Work in local `(u,v)` where
`v` = depth from the spawn edge (gravity is always `+v`) and `u` = lateral position (the d-pad is
always `±u`). `tob(u,v)` converts to board coordinates at collision and draw time.

| Side | Direction of travel | Transform to board `(x,y)` |
|---|---|---|
| 0 top | down (`+y`) | `x=u,   y=v` |
| 1 right | left (`-x`) | `x=27-v, y=u` |
| 2 bottom | up (`-y`) | `x=27-u, y=27-v` |
| 3 left | right (`+x`) | `x=v,   y=27-u` |

These are the four rotations of the square, so adjacency is preserved and the piece shape data is
identical on every side. Collision, movement, lock and spawn are each written once.

> The original brief listed the travel directions as `-y/+x/-x/+y` for top/right/left/bottom, which
> points *away* from the centre. Pieces fall *toward* the centre, so the directions are as tabulated
> above.

---

## 3. Pieces

Seven tetrominoes, stored as one 63-char string of 9-char records:
`[boxsize][x0y0][x1y1][x2y2][x3y3]`, decoded into `pd` at init.

| Piece | Shape | Box | Record | Colour |
|---|---|---|---|---|
| I | straight line | 4 | `401112131` | 12 blue |
| O | 2×2 square | 2 | `200100111` | 10 yellow |
| T | T-shape | 3 | `310011121` | 13 indigo |
| S | S-shape | 3 | `310200111` | 11 green |
| Z | Z-shape | 3 | `300101121` | 8 red |
| J | J-shape | 3 | `300011121` | 1 dark blue |
| L | L-shape | 3 | `320011121` | 9 orange |

PICO-8's 16-colour palette has no true cyan, so I takes the closest blue (12) and J the dark navy
(1). Each block is drawn as a 4×4 fill plus one lighter highlight pixel from the `hl` lookup, which
is what keeps J legible against the black board.

**Rotation** is 90° CW inside the piece's own box: `nx, ny = n-1-y, x`. Using each piece's own box
size is what stops T/S/Z/J/L drifting, and makes O stationary under rotation.

**A blocked rotation is rejected** — no wall kicks. With four gravity directions and a solid centre,
kick tables would need per-side handling; rejection is predictable and cheap.

---

## 4. Controls

| Input | Action |
|---|---|
| d-pad | move `±u` — left/right for a piece from the top or bottom, up/down for one from the left or right |
| ❎ (button 5) | rotate 90° CW (edge-triggered, `btnp`) |
| 🅾️ (button 4) | soft drop (held, `btn`) |
| pause menu | **restart** (`menuitem(1,"restart",startgame)`) |

---

## 5. Gameplay rules

- **Spawn:** the side cycles strictly `0→1→2→3→0…` (N→E→S→W). The piece type is pulled from the
  front of the 3-deep preview queue. The box sits flush with the edge (`v=0`), laterally centred at
  `u=14`, so its origin is `14-flr(n/2)`.
- **Fall:** constant, 12 frames per cell (~2.5 cells/s). Soft drop = 2 frames per cell. There is no
  difficulty ramp; a run ends only when one of the game-over rules fires.
- **Lock delay:** 15 frames once the piece cannot advance. Moving or rotating resets it, capped at a
  30-frame total so a piece cannot be stalled indefinitely.
- **Solid test:** out of bounds, or `bd[x+y*28]` set.

### Ring clear + inward shift

After a lock, rings 0..11 are scanned for full ones. For each cleared ring `R`, rings `R-1` down to
`0` each move one step inward:

```lua
function inward(x,y,r)
 local nx,ny=x,y
 if y==r    then ny=y+1 end
 if y==27-r then ny=y-1 end
 if x==r    then nx=x+1 end
 if x==27-r then nx=x-1 end
 return mid(r+1,nx,26-r), mid(r+1,ny,26-r)
end
```

Corner cells move diagonally; every other cell moves straight in. Processing inner-to-outer
guarantees a ring is always vacated before it is written to.

**Ring `r` holds exactly 8 more cells than ring `r+1`, so the shift cannot be lossless.** At each
corner, three source cells map to one target; **first writer wins and the overflow is discarded** —
8 cells per shifted ring. This is invisible in play and is the intended behaviour.

When several rings are full at once they are processed innermost-first, and each prior clear pulls
the remaining ones one ring deeper — so the `k`-th ring processed is cleared at index `r+k`.

- **Scoring:** for each cleared ring, `(108-8r) × (number of rings cleared this lock)`. Bigger outer
  rings pay more and multi-ring clears multiply.

### Game over — three ways

1. **Block out** — a new piece cannot spawn because its cells are already occupied.
2. **Cross out** — a piece locks with any cell on the far edge (`v = 27`), i.e. it travelled the
   whole board and reached the opposite border.
3. There is no time or speed limit; those two are the only ways to lose.

On game over the board keeps the fatal piece drawn in place, the music fades out over 0.3 s, and ❎
restarts.

---

## 6. Screens

Integer state `st`: `0` intro → `1` play → `2` game over, dispatched from `_update` and `_draw`.

### Bottom bar (y 120..127)

```
y=120 ┌────────────────────────────────────────────────────────┐
      │ 1240                                    ▓▓   ▓▓▓▓  ▓▓▓▓ │
      │                                       ▓▓▓▓     ▓▓  ▓▓   │
y=127 └────────────────────────────────────────────────────────┘
        x=2  score, white                       x=98 108 118
```

- Score prints at `(2,121)` in white — the 5 px font sits inside rows 121–125.
- **The next 3 pieces** are drawn at **2×2 px per block**, so a tetromino is at most 8×8 px and fits
  the 8 px bar exactly. Slots at x = 98, 108, 118 (8 px wide, 2 px gap).
- Most pieces are smaller than their box (I horizontal = 8×2, O = 4×4, the rest 6×4), so each is
  centred in its slot rather than drawn from the box origin.
- The spawn *side* is not previewed — the N→E→S→W cycle is fixed, so it is already known.

---

## 7. Audio

The tune is an **original melody**. Its two stylistic sources are both public domain — Korobeiniki
(the Russian folk dance used as the Tetris theme) and Fučík's *Entrance of the Gladiators* (1897,
the circus galop) — but nothing here is a transcription of either.

**Form:** A A′ B A″, 32 bars over 8 patterns, **25.6 s loop**. A minor (A sections), C major (trio).
2/4 at 150 bpm on a 16th-note grid → `speed = 12` → 0.1 s per row, 8 rows per bar, 32 rows
(4 bars) per pattern.

Three voices: melody (pulse), an oom-pah bass alternating root and fifth with a mid chord stab
(saw + pulse), and a noise percussion channel.

> **Ties:** a held note is the same pitch again with effect `1` (slide). Sliding to an identical
> pitch changes nothing and does not retrigger the envelope — a clean legato tie, where repeating
> the pitch with effect `0` would click on every 16th.

### Slot map

| Slots | Use | Channel |
|---|---|---|
| `00`–`03` | game SFX: spawn, lock, ring clear, game over | **3 only** |
| `08`–`0e` | melody | 0 |
| `10`–`13` | oom-pah bass | 1 |
| `18`–`1b` | percussion | 2 |

### Channel discipline

Music takes channels 0–2 via `music(0,0,7)`; **every game SFX is pinned to channel 3** with
`sfx(n,3)`. No music pattern ever names channel 3 (it is `44` in all 8 patterns), and the generator
asserts that. With `sfx(n,-1)` auto-pick a sound would eventually steal a music channel and audibly
chop the melody; pinning makes that impossible. Verified — see §9.

### The four game SFX

| Slot | Sound | Design |
|---|---|---|
| `00` | spawn | pulse arpeggio C4→G4→C5, 0.1 s — bright, above the bass |
| `01` | lock | noise click + saw thud, 0.1 s — sits in the drum register so it reads as part of the beat |
| `02` | ring clear | an **A major** arpeggio over the A *minor* tune; the raised third is what makes it land as a reward |
| `03` | game over | saw glissando A3 chromatically down to A1, fading out over 1 s |

---

## 8. Implementation map

`game.lua`, organised with `-->8` tab breaks (free, per `CLAUDE.md`): data / update / draw.

| Function | Role |
|---|---|
| `_init` | decode `pd`, palettes, `menuitem` |
| `startgame` | reset board, fill centre, seed queue, start music |
| `tob`, `sol`, `fits` | coordinate transform and collision |
| `spawn`, `lock`, `gameover` | piece lifecycle |
| `rcells`, `clearrings`, `clearring`, `inward` | ring detection, clear and inward shift |
| `bake`, `blk`, `drpiece`, `drbar`, `drintro`, `drover` | rendering |

**Rendering:** the settled board only changes on a lock, so `bake()` draws it once and snapshots the
screen to `0x8000`; every other frame is a single `memcpy(0x6000,0x8000,0x2000)` with the active
piece and HUD drawn on top. The border and centre block are baked in and cost nothing per frame.
This is what keeps a fully-populated board cheap — see §9.

---

## 9. Verification

Per `PICO8-TOOLING.md`, a cart that has not been through `-x` is unverified. Assets are generated by
a Node script kept in a scratch directory, not the repo.

**Measured results:**

| Check | Result |
|---|---|
| Generator asserts (168-char SFX lines, music line format, per-bar row counts, ch3 unused, slot disjointness) | all pass |
| Round-trip: re-parse the written cart and render the hex back to note names | matches the intended tune |
| Play smoke test, 420 frames of synthetic input | 7 locks, side cycles 0→1→2→3, clean exit |
| Ring clear (fill rings 11 and 10, mark ring 9) | both cleared, score 96 = 20×2 + 28×2, centre 16 cells intact, marker ring 12→10→8 cells confirming the documented 8-per-ring overflow drop |
| Game over: far edge / ordinary lock / blocked spawn | `st`=2 / 1 / 2 as specified |
| Audio routing while a game SFX plays | ch0=8, ch1=16, ch2=24 unchanged; ch3 carries the SFX |
| Worst-case render, every playable cell filled | **peak CPU 0.0214** at 30 fps |

**Not verifiable headlessly:** `-x` does not run the audio clock (the note index never advances), so
music *sequencing* and how the tune actually sounds must be checked by ear with the cart running
normally. The hex is structurally verified; the musicality is not.

**Also unverified:** the code token count against the 8192 cap — there is no runtime stat for it, so
it is only visible in the PICO-8 editor's code view.
