# PORTAL FLOW — PICO-8 Design Document

> Connect every pair. Fill every tile. Now do it through a wormhole.

A pipe-connecting puzzle (Flow Free family) with one twist: some boards contain a
**portal pair**. A pipe that enters one portal comes out of the other. Both portal
tiles are consumed by the same pipe, so the portal is never a shortcut — it is a
constraint that splits one path across two regions of the board.

---

## 1. High concept

| | |
|---|---|
| Genre | Grid logic puzzle, no timer, no fail state |
| Session | 30s–4min per level, 16 hand-authored levels |
| Boards | 4x4 → 7x7, tiles are 16x16 px |
| Twist | Portal pair (max 2 portal tiles per board) |
| Tone | Calm, tactile, "juicy": every input has a sound and a motion |
| Art | Professional pixel art with dithered shading |
| Audio | Slow classical-inspired arrangements, no noise channel, no loops that nag |

---

## 2. Core rules (base Flow)

1. The board holds pairs of coloured **dots**. Each colour appears exactly twice.
2. The player draws a **pipe** from one dot of a colour to its twin, moving only
   orthogonally between adjacent tiles.
3. A pipe may not cross another pipe. Drawing over an existing pipe **truncates**
   that pipe from the crossed tile onward (it does not block the input — the older
   path gives way, Flow Free style).
4. A pipe may not cross itself. Retracing back over your own tail erases it.
5. A level is won when **every colour is connected** AND **every tile on the board
   is covered**. A fully connected board with one empty tile is not a win — this is
   the whole design, and the UI must communicate it (see §7 HUD).

### Move / undo semantics

| Action | Result |
|---|---|
| Grab a dot | Clears that colour's existing path, starts a fresh one from that dot |
| Grab the middle of an existing pipe | Truncates the pipe at that tile and continues drawing from there |
| Move onto the tail tile you just left | Erases one segment (retrace) |
| Move onto the twin dot | Colour is connected, path locks, input releases |
| Release input | Path stays as drawn (partial paths are allowed and persist) |
| `X` tap | Undo last completed colour |
| `X` hold 1s | Clear the whole board (with a confirm flash + sfx) |

There is no move counter penalty and no star rating. Levels are pass/fail only, but
the **best move count** is stored per level and shown on the level card (§4), which
gives optimisation-minded players a reason to replay without punishing anyone else.

---

## 3. The portal mechanic

### 3.1 Definition

- Portals always come in a **pair** (A and B). They are visually identical twins,
  drawn in a neutral colour (indigo/white) so they never read as a flow colour.
- **Hard cap: 2 portal tiles per board — exactly one pair.** The level format and the
  runtime support a second pair (`MAX_PORTAL_PAIRS`), but ship value is `1`.
- Portals occupy real board tiles. They count toward the "fill every tile" win
  condition.

### 3.2 Traversal rules

1. Moving a pipe head into portal **A** immediately teleports the head to portal
   **B**. Both A and B become occupied by that pipe in the same step.
2. From B, the player may continue in **any free orthogonal direction** (exit
   direction is not locked to the entry direction). This keeps the mechanic readable
   with d-pad input and adds branching instead of forcing a single line.
3. A portal pair can be used by **only one colour**, because using it occupies both
   tiles. Once a pipe holds the pair, another pipe entering A is rejected (soft
   rejection: sfx + 2-frame shake, no pipe break).
4. Portals are **bidirectional**: entering B exits at A. It is one object, not a
   one-way door.
5. Retracing back through B pulls the head back out of A, freeing both tiles at once.
6. Truncating a pipe at any tile before the portal frees **both** portal tiles.
7. **Dots are never placed on a portal tile.** A portal is always a pass-through.

### 3.3 Why the exit is free, not momentum-locked

Momentum-preserving exits (exit B in the same direction you entered A) are the other
common choice. Rejected because: with a 4-way d-pad the player can't see the exit
side before committing, so it reads as random. Free exit keeps the portal a *routing*
puzzle rather than a *memorisation* puzzle. If playtesting shows levels are too soft,
the alternative is a one-line change — the level format has a `mode` field reserved.

### 3.4 Edge cases to implement explicitly

| Case | Behaviour |
|---|---|
| Portal is the tile immediately next to a dot | Legal. Common source of good puzzles. |
| Pipe head is on B and the only free neighbour is A | Illegal (would re-enter itself). Reject with soft sfx. |
| Both portals are walled in by other pipes | Level is now unsolvable; **do not** hard-fail. The player rebuilds. |
| Portal pair unused at win-check time | Not a win — portal tiles are uncovered tiles. |
| Player truncates a foreign pipe that owns the portals | Portals free instantly, ownership transfers only on actual entry. |

---

## 4. Screens

### 4.1 Intro / Level select

Single screen, no separate title screen — the title lives at the top of the select
screen so the player is one button from playing.

```
+------------------------------+
|      P O R T A L  F L O W    |  <- 16px logo sprites, gentle 1px float
|                              |
|   [1*][2*][3*][4 ][5 ][6 ]   |  <- 4x4 grid of level cards, 20x20 each
|   [7 ][8 ][9 ][10][11][12]   |
|   [13][14][15][16]           |
|                              |
| lv 04  5x5  1 portal   ❍ 21  |  <- info line for the highlighted card
|            ❎ play            |
+------------------------------+
```

Card states:

| State | Look |
|---|---|
| Cleared | Filled card, colour-tinted, small star, best-move count |
| Unlocked | Outlined card, level number, soft pulse if it's the next one to play |
| Locked | Dithered dark card with a lock glyph, number hidden |

- Cursor moves with the d-pad, wrapping at row ends. Cards ease-in on entry (staggered
  by index, ~3 frames apart) so the screen feels alive on every return from a level.
- **Progression reset:** the pause menu on the select screen carries a
  `menuitem("clear progress")` that wipes cleared flags and best moves on the spot.
  It replaces the "back to levels" slot, which is meaningless here.
- The next uncleared level is auto-highlighted on entry.

### 4.2 Game

Board only, centred, nothing else competing for attention.

```
ox = 64 - (w*16)/2
oy = 64 - (h*16)/2
```

| Board | Pixels | Margin |
|---|---|---|
| 4x4 | 64x64 | 32 px all round |
| 5x5 | 80x80 | 24 px |
| 6x6 | 96x96 | 16 px |
| 7x7 | 112x112 | **8 px** |

HUD is margin-only, so it must survive the 8 px worst case:

- Top-left, 1 line: `lv 12` in white with a 1px dark outline.
- Top-right, 1 line: `4/6` colours connected, plus a tiny fill meter — a 1px-tall bar
  the width of the board showing `covered_tiles / total_tiles`. This is how the player
  learns that "all connected" ≠ "solved" without a single line of tutorial text.
- Bottom margin stays empty on 7x7. On smaller boards it shows `🅾️ back  ❎ undo`.

### 4.3 Transitions

- Select → Game: the chosen card scales up into the board frame over 12 frames, other
  cards slide off-screen.
- Game → Win: see §8.
- Win → Select: board contracts back into its card, which then plays the star pop.

---

## 5. Controls

Both schemes are always live; no options menu.

**Gamepad / keyboard (primary)**

| Input | Action |
|---|---|
| d-pad | Move cursor (1 tile per press, repeat after 12 frames at 4-frame rate) |
| `❎` hold + d-pad | Draw (cursor drags the pipe head) |
| `❎` tap on a dot | Grab and stay grabbed (sticky mode — move without holding, tap again to release) |
| `🅾️` | Undo last colour / hold to clear board |
| pause menu | in a level: back to select. on the select screen: clear progress |

Sticky mode matters: holding a button while pressing direction keys is uncomfortable
on a keyboard for a 3-minute puzzle. Tap-to-grab is the default path; hold-to-drag is
supported because it's what muscle memory expects.

**Mouse (`poke(0x5f2d,1)`)**

Press on a dot or pipe, drag across tiles, release to drop. The cursor sprite is
hidden while the mouse is active and returns on the next d-pad press.

---

## 6. Board & data

### 6.1 Level format

Levels are plain strings — one string per row — so they're diffable, hand-editable,
and cheap in tokens. The map sheet is left **completely free** for art (see §7.2).

| Char | Meaning |
|---|---|
| `.` | Empty tile |
| `1`–`7` | Endpoint dot of colour N (must appear exactly twice) |
| `P` | Portal (must appear exactly twice, or zero times) |
| `Q` | Reserved: second portal pair, disabled at ship |

```lua
levels={
 -- 01 : first contact. 3 colours, no portal.
 {"1...",
  "23.1",
  ".3.2",
  "...."},

 -- 02 : the portal teaches itself. top row and bottom row only meet through P.
 {"1..P",
  "2...",
  "2...",
  "P..1"},
}
```

Board width/height are derived from the string table (`#g[1]`, `#g`), so no size
fields to keep in sync.

### 6.2 Runtime structures

```
board.cell[x][y] = {
  kind    = "empty" | "dot" | "portal",
  dot     = colour index or nil,
  owner   = flow index or nil,   -- which pipe covers this tile
  prev    = dir or nil,          -- where the pipe came from (for glyph pick)
  next    = dir or nil,          -- where it leaves (nil = head/cap)
}

flow[i] = {
  col   = 1..7,
  a, b  = {x,y} endpoints,
  path  = { {x,y}, {x,y}, ... },  -- ordered, may contain a portal jump
  done  = bool,
}

portal = { {x,y}, {x,y} }   -- or nil
portal_owner = flow index or nil
```

**Portal jump in the path array:** two consecutive entries are non-adjacent exactly
when the jump happened. The renderer uses that as its signal — draw a cap into the
entry side of A, a cap out of the exit side of B, plus the "linked" portal overlay on
both. No extra flags needed.

### 6.3 Win check

```
win = (every flow.done) and (covered_tiles == w*h)
```
where a portal tile counts as covered only when `portal_owner ~= nil`.

### 6.4 Save data

```
cartdata("rbt_portalflow_1")
dset(0) = cleared bitfield (levels 1..16 as bits)
dset(1..16) = best move count per level (0 = never cleared)
```
Level `n` is unlocked when level `n-1` is cleared. Level 1 is always unlocked.

---

## 7. Level progression

Difficulty is dialled with three knobs: **board size**, **colour count**, and **how
much the portal is load-bearing**. The portal appears in level 2 and then disappears
for a level or two at a time, so its return keeps feeling like an event.

| # | Size | Colours | Portal | Design intent |
|---|---|---|---|---|
| 1 | 4x4 | 3 | – | Teach: connect + fill. Nearly unmissable. |
| 2 | 4x4 | 2 | ✔ | Teach portal. Top and bottom halves only meet through P. |
| 3 | 5x5 | 3 | – | First real routing choice. One tempting dead end. |
| 4 | 5x5 | 3 | ✔ | Portal is optional-looking but mandatory for full coverage. |
| 5 | 5x5 | 4 | ✔ | Two colours compete for the portal; only one can have it. |
| 6 | 6x6 | 4 | – | Breather. Long snaking paths, no gimmick. |
| 7 | 6x6 | 4 | ✔ | Portals in opposite corners — forces one very long pipe. |
| 8 | 6x6 | 5 | ✔ | Portal sits adjacent to a dot; the obvious grab is wrong. |
| 9 | 6x6 | 6 | ✔ | Six short pipes, tight packing, portal fixes the last two tiles. |
| 10 | 7x7 | 5 | – | Scale shock. Big empty space to fill with few colours. |
| 11 | 7x7 | 5 | ✔ | Portal splits the board into two rooms with one legal crossing. |
| 12 | 7x7 | 6 | ✔ | Portal is a trap for the first colour the player will try. |
| 13 | 7x7 | 6 | ✔ | Both portals boxed in by dots — access is the puzzle. |
| 14 | 7x7 | 7 | ✔ | Max colours. Almost no slack tiles. |
| 15 | 7x7 | 7 | ✔ | Portal must be entered from a specific side or coverage fails. |
| 16 | 7x7 | 7 | ✔ | Finale. Portal + a forced 15-tile pipe. Should take 5+ minutes. |

Levels 1 and 2 are specified verbatim in §6.1. Levels 3–16 are authored against the
rules below and **must pass the validator before shipping**.

### 7.1 Authoring rules

1. A valid level has **at least one** solution that covers 100% of tiles.
2. Target **exactly one** solution. Multi-solution boards feel mushy; if the solver
   reports 2+, move one dot and re-check.
3. No dot on a portal tile. No portal on the board edge before level 7 (edge portals
   are much harder to reason about).
4. Every colour's two dots must be at least 3 tiles apart (Manhattan) from level 5
   onward — adjacent pairs are free tiles and kill the difficulty curve.
5. Portal-using levels must be **unsolvable with the portal disabled**. If a level
   still solves when you delete the pair, the portal is decoration — redesign it.
6. Keep colour count ≤ board width. 7 colours only ever appear on 7x7.

### 7.2 Validator (offline tool, not shipped in the cart)

A small script (Python or Lua) run at author time:

```
solve(level):
  order flows by endpoint distance descending
  DFS: take the lowest-index unfinished flow, try each free orthogonal
       neighbour of its head
    - stepping onto its twin dot  -> flow done, recurse to next flow
    - stepping onto portal A      -> mark A and B owned, head becomes B
    - stepping onto any other dot -> reject
  prune when:
    - any empty tile has < 2 free-or-endpoint neighbours (stranded tile)
    - any unfinished flow's endpoints are no longer connected through free tiles
    - the free region splits into a component with no unfinished endpoint in it
  accept only when all flows are done and free_tiles == 0
  count solutions, stop at 2
```

Output per level: `solvable? / solution count / longest path / portal required?`.
Rule 5 is checked by running `solve()` twice — once normally, once with the portal
pair replaced by `.` tiles.

---

## 8. Art direction

### 8.1 Palette

Base PICO-8 16 colours. Board and chrome stay cold and quiet so the flow colours are
the only saturated thing on screen.

| Role | Colours |
|---|---|
| Background | `1` dark blue base, dithered toward `13` at the edges (vignette) |
| Board frame | `13` indigo with a `1` drop shadow and a `6` 1px inner highlight |
| Empty tile | `1` with a subtle `13` dither pattern, 1px `13` grid dots at corners |
| Portal | `7`/`6`/`13` ring, `0` centre, `12` inner glow |
| Text | `7` with `1` outline, always |

Flow colours use a 3-step ramp. The pipe sprites are authored **once** in
`7` (highlight) / `6` (body) / `5` (shadow) and recoloured at draw time with `pal()`.
That is the single biggest saving on the sprite sheet.

| # | Name | Highlight | Body | Shadow |
|---|---|---|---|---|
| 1 | red | `14` | `8` | `2` |
| 2 | blue | `7` | `12` | `1` |
| 3 | green | `10` | `11` | `3` |
| 4 | yellow | `7` | `10` | `9` |
| 5 | orange | `10` | `9` | `4` |
| 6 | pink | `15` | `14` | `2` |
| 7 | silver | `7` | `6` | `5` |

Red/orange/pink are the risky trio. Mitigation: each dot carries a distinct 3x3
glyph in its centre (dot, ring, cross, bar, chevron, triangle, diamond) so colour is
never the only channel carrying information.

### 8.2 Dithering

Dithering is used deliberately, not everywhere:

- **Background vignette** — `fillp(0b0101101001011010)` gradient bands from `1` to
  `13`, four bands from centre to edge. Static, drawn once per frame under everything.
- **Pipe body shading** — the top-left half of each pipe segment carries a 2px
  highlight, the bottom-right a dithered transition to the shadow colour. This is
  baked into the sprites, not computed.
- **Locked level cards** — 50% checker of `0` over the card art.
- **Fades** — screen transitions use a 4-step dither ramp (`fillp` patterns
  `0b0000`, `0b0101...`, `0b1010...`, solid) in `0` rather than a palette fade, so it
  reads as pixel art rather than as a video effect.

Never dither the flow pipes' body colour against the background — it breaks the
readability of "is this tile filled".

### 8.3 Sprite sheet plan

16x16 tiles occupy 2x2 sprites, so a tile at sheet position `(tx,ty)` has base index
`ty*32 + tx*2` and is drawn with `spr(base, x, y, 2, 2)`.

Since levels are strings, **the whole 128x128 sheet is available** — including sprites
128–255, which share memory with the map. Do not write map data.

| Sheet rows | Sprites | Contents |
|---|---|---|
| 0–1 | 0–31 | Tile set A: empty tile, pipe straight-V, pipe straight-H, elbow, cap-V, cap-H, dot idle, dot connected |
| 2–3 | 32–63 | Tile set B: portal frames 0–3, portal-linked overlay, cursor frame, lock card, star |
| 4–5 | 64–95 | Level-select cards (unlocked / cleared / locked / highlighted), fill-meter caps |
| 6–7 | 96–127 | 8x8 items: particles (spark, ring, mote), glyph set for colour-blind dots, UI arrows, star pop frames |
| 8–11 | 128–191 | Title logo, 16x16 letterforms for "PORTAL FLOW" |
| 12–15 | 192–255 | Cover-art elements, decorative corner ornaments, spare |

**Mirroring saves ~10 tiles.** Only one elbow is drawn; the other three come from
`spr(..., flip_x, flip_y)`. Only one vertical cap and one horizontal cap are drawn;
their opposites are flips. Everything colour-varying is `pal()`-swapped, not
duplicated.

Glyph selection at draw time, per covered tile, from `prev`/`next` directions:

| prev / next | Glyph |
|---|---|
| N–S or S–N | straight vertical |
| E–W or W–E | straight horizontal |
| any perpendicular pair | elbow, flipped to match |
| next == nil (head) | cap pointing back at `prev` |
| tile is a dot | dot sprite + cap toward `next` |
| tile is a portal, owned | portal frame + linked overlay + cap toward the open side |

### 8.4 Cover art (the `__label__`)

PICO-8 cover art is the 128x128 label captured with **F7** from a running cart. Build
a hidden `state="cover"` reachable with a dev key so the exact frame is reproducible.

Composition:

- Background: the dithered indigo vignette, darkest at the corners.
- Centre-left: a 5x5 fragment of a board at a slight visual tilt (fake it with a 1px
  vertical offset per column), three pipes woven through it.
- Centre-right: one portal, wide open, with a red pipe entering it and the same red
  pipe re-emerging from a second portal near the bottom-left — the whole mechanic
  legible in one glance.
- Title in 16x16 letterforms across the top third, `7` fill, `1` outline, `13` shadow
  offset 2px down-right.
- No credits, no "press start" — the label should read as a poster.

---

## 9. Juice: animation catalogue

Every entry here has a matching sfx in §10. Nothing in this game is silent and
nothing snaps without easing.

**Idle / ambient**

| Element | Motion |
|---|---|
| Unconnected dots | Radius pulse between body and highlight colour, 48-frame sine, phase offset per dot so they never pulse in unison |
| Connected dots | Steady bright, tiny 1px inner sparkle every ~2s, random |
| Portals | 4-frame rotation loop at 8 fps; both portals in the pair run the **same** frame so the twinning is obvious |
| Portal (owned) | Rotation speeds to 12 fps, inner glow shifts to the owning flow's colour |
| Cursor | 1px vertical bob, 30-frame cycle; corner brackets, not a filled box |
| Board frame | Static. The frame is the only calm thing on screen. |

**Interaction**

| Event | Motion |
|---|---|
| Cursor move | Cursor eases over 3 frames rather than jumping |
| Grab dot | Dot scales 16→20px and back over 5 frames, ring particle expands outward |
| Pipe extends | New segment pops in at 120% for 2 frames; head carries a 2px bright tip |
| Pipe retracts | Segment shrinks out over 2 frames, small dust mote falls |
| Pipe truncated by another | The lost segments flash white then dissolve tail-first, 1 frame apart per tile — you can *see* which pipe you cost yourself |
| Portal entry | Ripple ring on A, 6 frames; head "arrives" at B with an inward-collapsing ring; both portals flash the flow colour |
| Illegal move | 1px shake of the cursor only (never the board), 4 frames |
| Colour connected | Both dots pop, a light pulse travels the full length of the pipe from A to B at 4 tiles/frame, 6 sparks at the destination |
| Last colour connected but board not full | The fill meter shakes and flashes; empty tiles pulse once in `6` — the game *points at the problem* instead of just failing to end |
| Undo | Pipe dissolves head-first, faster than it was drawn |
| Clear board | All pipes dissolve simultaneously with a 1-frame per-column stagger, left to right |

**Level complete**

1. Input locks. All pipes flash their highlight colour in a wave, top-left to
   bottom-right, 2 frames per diagonal.
2. Board does a 4-frame squash-and-stretch (`sspr` scale 1.0 → 1.08 → 1.0).
3. 24 particles in the flow colours arc up from the board and fall off-screen.
4. If the portal was used: the portals collapse inward and pop last, one extra beat.
5. Board contracts into its level card on the select screen (§4.3), card flips to
   cleared, star pops, next card's lock shatters into 6 pieces.

Keep the whole sequence under **90 frames**. Juice that outlasts the player's
attention becomes a loading screen.

---

## 10. Audio

### 10.1 SFX map

Reserve `0–19` for sfx, `20–63` for music patterns.

| # | Sound | Character |
|---|---|---|
| 0 | Cursor move | Very short soft tick, waveform 1, vol 2 |
| 1 | Pipe extend | Single note, **pitch rises one semitone per tile** of the current path (caps ~2 octaves). Long pipes literally sing. |
| 2 | Pipe retract | Same note set, descending |
| 3 | Grab dot | Soft pluck, waveform 3 |
| 4 | Release | Muted low pluck |
| 5 | Colour connected | 3-note ascending arpeggio in the level's key |
| 6 | Pipe broken / truncated | Warm descending pair, not harsh — this is a common, non-punished action |
| 7 | Portal enter | Rising glissando, waveform 5, with a slight vibrato |
| 8 | Portal exit | Falling glissando answering #7 (same interval, inverted) |
| 9 | Illegal move | Very quiet low thud, vol 2. Must never sound like a buzzer. |
| 10 | Board full but unsolved | Two soft neutral notes, questioning, not negative |
| 11 | Level complete | 5-note resolving phrase in the level's key |
| 12 | Undo | Short reverse-ish blip |
| 13 | Clear board | Descending sweep |
| 14 | Menu move | Softer variant of #0 |
| 15 | Menu select | Clean fifth |
| 16 | Menu back | Same fifth, inverted |
| 17 | Level unlock | Sparkle, three quick high notes |
| 18 | Star pop | Single bright bell |
| 19 | Card flip | Papery tick |

**Global rules:** waveform 6 (noise) is **never used**, in sfx or music. No sfx exceeds
~0.4s. Rapid sfx (0, 1, 2) are pinned to channel 3 with `sfx(n, 3)` so they can never
steal a music channel.

### 10.2 Music

Three arrangements, each built from public-domain classical material, arranged (not
transcribed) for three channels with the fourth left free for sfx.

| Track | Source material | Used for |
|---|---|---|
| A | Satie, *Gymnopédie No. 1* — that slow 3/4 sway | Level select, cover |
| B | Bach, *Prelude in C*, BWV 846 — the broken-chord figure | Levels 1–8 |
| C | Chopin, *Prelude Op. 28 No. 7* — short, wistful, harmonically rich | Levels 9–16 |

Arrangement constraints, all in service of "relaxing, not repetitive":

- **Tempo:** sfx speed 24–28 (roughly 50–70 bpm). Slower than feels right at first.
- **Channel plan:** ch0 = bass/root movement, sparse; ch1 = harmony pad (waveform 5,
  vol 2–3); ch2 = melody (waveform 1 or 3, vol 3–4). ch3 = permanently free for sfx.
- **Length:** minimum 8 patterns per track. Four-pattern loops are exactly what makes
  chiptune music grating on a puzzle game where a player sits on one screen for
  minutes. Aim for 60–90 seconds before repeat.
- **Variation:** patterns 5–8 of each track are a variation of 1–4 — same harmony,
  the melody thinned out or moved an octave. The player should not be able to predict
  the next bar after two loops.
- **Silence is an instrument.** Leave whole bars with bass only. Density around 60%.
- **No percussion at all**, and no fast arpeggios above ~8 notes/sec.
- **Transitions:** `music(n, 1200, 0b0111)` for a fade-out on the three music channels
  when moving between screens; the new track starts on the following frame.
- Level-complete sfx (#11) is written in the **key of the currently playing track** so
  it lands as a cadence rather than an interruption. Track B is in C, so #11 resolves
  to C; track C is in A minor.

Pause menu exposes `menuitem` toggles for **music** and **sfx** separately, stored in
`dset(17)` and `dset(18)`.

---

## 11. Technical notes

### 11.1 Structure

Single cart, `_init` / `_update60` / `_draw`, with a state table:

```
states = { intro=..., game=..., win=... }
```

Each state is `{enter, update, draw}`. Transitions are a queued `next_state` applied
at the end of `_update60` so nothing changes mid-frame.

Use `#include` for authoring (`main.lua`, `board.lua`, `render.lua`, `levels.lua`,
`fx.lua`) and let PICO-8 flatten it on export.

### 11.2 Rough token budget (limit 8192)

| Module | Est. tokens |
|---|---|
| State machine + main loop | 250 |
| Board build + level parsing | 450 |
| Input + cursor + mouse | 450 |
| Path logic (extend/retract/truncate) | 750 |
| Portal logic | 250 |
| Rendering (glyph selection, pal swaps, HUD) | 700 |
| Particles + tweens | 400 |
| Level select screen | 550 |
| Level data (16 strings tables) | 450 |
| Audio triggers + save data | 250 |
| **Total** | **~4500** |

Comfortable headroom for polish. The compressed-size limit (15360 bytes) is the one to
watch if the level strings grow.

### 11.3 Performance

At 60 fps the worst case is 49 tiles × (background + pipe + overlay) plus ~30
particles. Well inside budget. The only real cost is `sspr` scaling during the win
squash — restrict it to that 4-frame window.

---

## 12. Build order

1. **Skeleton** — state machine, level string parser, board render with placeholder
   rects. No art.
2. **Path logic** — draw, retrace, truncate, connect, win check. Levels 1 and 3 only.
   This is the whole game; get it feeling right before anything is pretty.
3. **Portals** — traversal, ownership, the path-array jump, all §3.4 edge cases.
   Validate with level 2.
4. **Validator tool** — offline. Then author levels 3–16 against it.
5. **Art pass** — tile sprites, pal ramps, dithered background, glyph set.
6. **Level select + save data.**
7. **Juice pass** — the whole of §9, then the whole of §10 sfx.
8. **Music** — three tracks. Last, because it's the longest single task and the game
   must already be fun in silence.
9. **Cover art / label.**
10. **Playtest** — specifically: does anyone finish level 16, and does anyone get
    stuck on "all connected but not full"?

---

## 13. Open decisions

- **Portal exit direction:** free (chosen) vs momentum-locked. Revisit after level 12
  is playable — if solutions feel too loose, momentum-lock is the fix.
- **Second portal pair:** format supports `Q`, ship cap is one pair. If levels 14–16
  don't reach "really challenging", a second pair on level 16 is the escape hatch.
- **Hint system:** none planned. If playtesters wall at 13+, the cheapest addition is
  "reveal one correct pipe" costing a 10-second cooldown, shown as a `menuitem`.
- **Level 16 length:** if it runs past 6 minutes it should become level 16 of an
  eventual pack 2 and something gentler ends the base game.
