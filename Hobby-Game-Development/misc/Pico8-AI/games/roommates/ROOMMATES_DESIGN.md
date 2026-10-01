# ROOMMATES — Game Design Document

A sliding-tile puzzle for PICO-8. Rearrange a room full of people until nobody is upset.

---

## 1. Concept

The board is a 6×6 room. 35 people, 1 empty floor tile. You slide one person at a time into the
gap, 15-puzzle style. Every person has an opinion about who they stand next to and where they
stand. **The level is solved the moment no one on the board is mad.**

The critical difference from a classic 15-puzzle: there is no single "correct picture" to
reconstruct. There are many valid arrangements. You are not restoring an image, you are
satisfying a constraint system. This is what makes the puzzle feel like reasoning instead of
mechanical unscrambling.

---

## 2. Core loop

1. Read the board. Find who is mad (their sprite tells you).
2. Slide people into the gap to change adjacencies.
3. After each slide, every person re-evaluates their mood.
4. When zero people are mad → level complete.

---

## 3. The people and the rules

Four types. **These rules never change between levels.** Learn them once. What changes each
level is the cast (fresh sprites), the head-count of each type, and the starting scramble.

| ID | Name | Rule | Mad when |
|----|------|------|----------|
| **A** | **Drifter** | Easygoing, but keeps away from Clingers. | Orthogonally adjacent to any **D** |
| **B** | **Homebody** | Wants to be inside, away from Loners. | On the **outer ring**, OR adjacent to any **C** |
| **C** | **Loner** | Wants space from the sociable types. | Adjacent to any **B** or any **D** |
| **D** | **Clinger** | Needs a Homebody, tolerates nobody else. | **Not** adjacent to at least one **B**, OR adjacent to any **A** or any **C** |

### Relationship graph

```
        A ──✕── D ──✕── C ──✕── B
                └──♥──────────────┘
                  (D requires B)

  ✕ = mutual conflict          ♥ = D needs at least one B neighbour
  Same-type pairs (A+A, B+B, C+C, D+D) are always fine.
  B is additionally banned from the outer ring.
```

### Adjacency definition

**Orthogonal only** — up, down, left, right. Diagonals do not count.
The **empty tile is not a person**. Standing next to the gap is neutral: it neither causes a
conflict nor satisfies D's requirement.

### Why these four rules

They are chosen so the solved state has an emergent *shape* rather than an arbitrary layout:

- D must be walled in by B (nothing else may touch it).
- B must be off the ring, so the B-shell lives in the inner 4×4.
- C may not touch B or D, so C must be pushed outward.
- A is the only type that can safely sit between the B-shell and the C-crowd.

The solution is therefore always some variant of **core → shell → buffer → crowd**:

```
 C C C C C C      D = Clinger core
 C A A A A C      B = Homebody shell (must stay off the ring)
 C A B B A C      A = Drifter buffer (only type that can touch both B and C)
 C A B D A C      C = Loner crowd (fills whatever is left)
 C A A A A C
 C C C C · C      · = gap
```

Players discover this pattern around level 3 or 4 and then spend the rest of the game
executing it under tighter and tighter piece budgets. That progression is the game.

---

## 4. Board

- **Grid:** 6 × 6 = 36 cells.
- **Tile:** 16 × 16 px.
- **Board size:** 96 × 96 px, drawn at screen offset `(16, 16)` — perfectly centred on PICO-8's
  128 × 128 screen.
- **Occupancy:** 35 people + 1 empty cell.
- **Outer ring:** the 20 perimeter cells (row 1, row 6, col 1, col 6). Referenced by B's rule.
- **Interior:** the inner 4×4 (rows 2–5, cols 2–5) = 16 cells.

### Movement

Tap/press a direction, or select a tile adjacent to the gap. A person may move **only** if the
gap is orthogonally adjacent to them. One tile per move. No multi-tile pushes, no wrapping.

Recommended control: D-pad moves the *gap* (i.e. pressing ⬅️ slides the person to the right of
the gap leftwards). This is faster than cursor-based selection and needs no on-screen cursor,
which matters because the game shows nothing but the board.

---

## 5. Screens

Four screens. One line of HUD in gameplay, nothing more.

### 5.1 Intro

- Title, centred.
- Three options, cycled with ⬆️/⬇️: **PLAY**, **HOW TO PLAY**, **CLEAR PROGRESS**.
- Under them, `room n/32` — the room the save file is on, so the player can see what PLAY
  will resume before pressing it.
- Background: the bedroom itself, with a bordered menu panel over it (`1` ground, `7` inner
  border, `0` outer) and a `>` cursor beside the selected option — the Game Boy menu-box
  idiom. The four person sprites idle in a row on the floor below the panel, so the art sells
  itself before any text does.

### 5.2 Tutorial

*Revised during implementation. The first version put all four rules on one screen as 8×8
`sspr` miniatures of the people — unreadable at that size, and the reader had to decode a
symbol language before learning anything. Replaced by four full-size pages.*

**One page per type**, cycled with ⬅️/➡️, ❎ to leave. Nothing is shrunk: every person on a
tutorial page is drawn at the same 16×16 size they appear at on the board, so recognition
transfers directly.

Page layout for type *t*:

```
[16×16 t, content]  NAME             <- name in that type's body colour, wide (^w)
one line of plain-text rule
        [16×16] ✕ [16×16]            <- the conflicting pair, both drawn MAD
              both mad
red outline = mad
⬅️➡️ n/4                        ❎ back
```

| Page | Rule line | Example row |
|------|-----------|-------------|
| **A** Drifter | "happy almost anywhere." | drifter ✕ clinger |
| **B** Homebody | "must stay off the outer edge." | homebody ✕ loner |
| **C** Loner | "wants space." | homebody ✕ loner ✕ clinger |
| **D** Clinger | "must stand by a homebody." | clinger ♥ homebody, then drifter ✕ clinger ✕ loner |

Two details carry the teaching:

1. **The example people are drawn in the mood they cause.** A ✕ row shows both people wearing
   the red mad outline; the ♥ row shows both content. The player learns the mood tell from the
   same picture that teaches the rule, so `red outline = mad` needs only a caption.
2. **No movement page.** Sliding a neighbour into the gap is self-evident from the board; an
   earlier looping 2×2 slide demo was built and cut.

### 5.3 Game

The board, a bedroom drawn around it, and one line of text. No move counter, no timer, no mad
count. All puzzle state must stay legible from the sprites themselves — this is precisely why
mood is sprite-level rather than an overlay icon.

The only HUD is **`room n/32`**, outlined, centred in the floor strip below the rug at
y = 117. It says where the player is in the 32 rooms and nothing else.

### 5.4 Clear progress

Its own confirm screen, reached from the intro. "clear progress? / back to room 1." with
**NO** selected by default; choosing YES does `lv=1 dset(0,1)` and returns to the intro.
Wiping 32 levels of progress is not something a mis-press should be able to do, so the
destructive option never sits under the cursor when the screen opens.

---

## 6. Art direction

### Palette — one hue per type

*Revised during implementation. The four-green ramp was built first and rejected: with a
single hue the four types were hard to tell apart, and mad was hard to spot.*

There is **one sprite set**, drawn in four art indices and recoloured per type at draw time
through the draw palette. Art index 1 is the outline, 3 the body, 4 the highlight.

*Revised again after the first playable: the art was redrawn in the Game Boy Color overworld
idiom.* Three colours plus transparency per sprite is exactly what a GBC object palette
allowed, so the existing 1/3/4 remap already fitted the style — what changed is the drawing.
Every person is now a **big-head 16×16 figure**: head and hair occupy rows 0-9, torso and arms
rows 10-13, feet rows 14-15, with a solid one-pixel outline all the way round and no interior
shading. Faces are two 2×1 eyes and a 2px mouth; that is the whole vocabulary at this size,
which is why mood has to be carried by *shape* (see the readability rule below) rather than by
expression detail alone.

Each type gets its own headgear so the silhouette identifies it before the colour does:

| Type | Silhouette |
|------|------------|
| **A** Drifter | cap with a brim that overhangs the head by a pixel each side |
| **B** Homebody | hair bun on top, hair framing the face down both cheeks |
| **C** Loner | hood up — no chin, face reduced to a slot, eyes 1px |
| **D** Clinger | hair tuft, arms thrown out past the sprite edge to both sides |

The sprites are generated by `gen-sprites.js`, which holds each frame as 16 rows of 16
characters (`.` transparent, `o` outline, `b` body, `h` highlight) and writes the first 32
lines of `__gfx__`. Frames share a common body and differ only in the head rows, and the mad
variants are the happy ones with three rows patched, so the whole cast is a few dozen lines of
ASCII rather than 16 hand-typed sprites. Edit the ASCII, re-run the script, `load game.p8`.

| Type | Body | Highlight | Reads as |
|------|------|-----------|----------|
| **A** Drifter | `12` blue | `7` white | cool, neutral |
| **B** Homebody | `9` orange | `10` yellow | warm, cosy |
| **C** Loner | `11` green | `7` white | cold, apart |
| **D** Clinger | `14` pink | `15` peach | soft, needy |

Rug `5`, so both outline colours and all four body colours read against it. UI text stays off
indices 1/3/4, which the draw palette remaps per person.

### The bedroom

*Added after the board played well on plain black: the people needed somewhere to be. Redrawn
with the sprites: the dithered version read as noise next to hard-outlined GBC figures.* Built
from `rectfill`/`line`/`pset` only — no sprite, no map tile — and deliberately the quietest
thing on screen. The rule that replaced dithering: **flat colour with drawn seams**, the way a
GBC tileset works. Every surface is one solid colour with a repeating 8- or 16-pixel motif
scored into it, so the room has texture without any 50 % checkerboard for the eye to fight.

| Element | Draw |
|---------|------|
| Wall, y 0-12 | solid `13`, `1` wallpaper dots on an offset 8px grid (y = 3 and y = 8) |
| Skirting, y 13-15 | solid `4`, `6` rail on top, `2` shadow beneath |
| Floor, y 16-127 | solid `4`, `2` plank seams — a line every 8px, verticals every 32px staggered by row |
| Rug (the board), 15-112 | solid `5`, double `6` border, `6` dotted lattice on the 16px cell grid |
| Window, x 82-104 | `6` frame and mullions, `12` sky, `3` hills on the lower half, `7` sun |
| Picture | `9` frame, `1` ground, `10` moon, `7` stars |
| Lamp | `6` stem, `10` shade |
| Plant, x 3-12 | `9` pot, `4` rim, `3`/`11` two-tone fronds |

Two things earn their keep. The **plank seams stagger** (`(y\8%2)*16` picks the vertical
offset) so the floor reads as boards rather than as a grid. The **rug lattice sits exactly on
the 16px cell boundaries**, which quietly tells the player where the tiles are without drawing
a game-y grid over the puzzle.

The rug stays `5`: both outline colours and all four body colours read against it, and it is
the one surface people actually stand on.

`_draw` still opens with `pal()` and `fillp()`. Nothing sets `fillp` any more, but the
per-person palette remap is global state that would otherwise leak into the next frame, and
the reset is one token.

### Text

Every on-screen string goes through `pr(s,x,y,c)`, which prints it in `0` at the eight
surrounding offsets and then in `c` on top. The one-pixel black outline is what keeps the
room line legible over the wood floor and the tutorial captions legible beside red
sprites. It costs 9 `print` calls per string, and only a handful are ever on screen.

### Readability rule

Mood is carried by **three** signals at once, so it survives at a glance across a 6×6 board:

- **Outline colour.** Content people are outlined in black (`0`); mad people are outlined in
  red (`8`) — the same remap turns their eyes, brows and mouth red too, which is why the mad
  face is drawn entirely in the outline index.
- **Hue stays constant**, so recolouring for mood never costs type identity.
- **Face and motion:**

  - **Content:** flat 2×1 eyes, small 2px smile, no brows.
  - **Mad:** brows added one row above the eyes and one pixel *outward*, eyes pulled one pixel
    *inward* — the two rows together read as a slant — and the mouth widened to a 4px frown.
    The idle also runs about twice as fast (see §7).

At 16×16 there is no room for a posture change that survives a 6×6 board, so mood is carried
by the outline colour at distance and by the brow slant up close. Both cues change together;
neither is load-bearing on its own.

---

## 7. Animation

### Idle

Every person has a 2-frame idle loop: legs apart / arms down on frame A, legs together / arms
up on frame B, which reads as a small shuffle in place — the GBC overworld walk cycle standing
still.

**Stagger the phase per tile** by `(col + row) % 4` so the room breathes as a wave instead of
pulsing in unison. This one detail does more for the game's feel than any other animation work.

**Mad people fidget faster.** `drawp` picks the step length from mood — 11 frames content,
5 frames mad — so an upset room visibly buzzes and a solved one settles. It is a second
motion-level mood cue for free, and it is what makes a mad person findable in peripheral
vision even before you read the red outline.

The clinger's outstretched arms move between rows 10 and 11 across the two frames, so its idle
reads as reaching rather than shuffling — one type with a distinct motion, which is as far as
the 8×8-slot budget stretches.

### Mood transition

After every completed slide, re-evaluate all 35 people. For each person whose mood **changed**,
play a 2-frame transition animation, then settle into the corresponding idle loop:

- **Content → Mad:** a startle — sharp pop up, then drop into the mad pose.
- **Mad → Content:** a relief — a small exhale/slump, then rise into the content pose.

People whose mood did not change keep looping their current idle uninterrupted. Do not replay
the transition on unchanged tiles; the whole point is that motion draws the eye to what your
last move actually broke or fixed.

Transitions should be staggered by a few frames outward from the moved tile, so a cascading
change reads as a ripple.

### Slide

Person tweens across the 16 px in ~6 frames, ease-out. Mood re-evaluation fires when the tween
lands, not when input is pressed.

### Win

When the mad count hits zero: every person plays one synchronised content-idle beat, the board
holds for ~1 s, then advances. No text.

---

## 8. Sprite budget

PICO-8 offers 256 8×8 slots. One 16×16 person = 4 slots.

| Asset | Frames | 16×16 units | 8×8 slots |
|-------|--------|-------------|-----------|
| 4 types × content idle | 2 | 8 | 32 |
| 4 types × mad idle | 2 | 8 | 32 |
| **Total** | | | **64 / 256** |

Built smaller than budgeted. The transition is a code-driven hop (a few pixels of vertical
offset over 8 frames) rather than its own frames; the tutorial re-uses the same 16×16 person
sprites at full size, annotated with drawn ✕ and ♥ marks; and the whole bedroom is `rectfill`
and `line`, not a single tile.

The 64 slots are sprite indices 0-15 (content) and 32-47 (mad), i.e. the first four rows of the
sheet — exactly the first 32 lines of `__gfx__`, which is the range `gen-sprites.js` owns.
Anything else added to the sheet must start at line 32 or later.

---

## 9. Level generation

### 9.1 Principle — generate the goal first, then scramble

Never randomise the board and then check solvability. Instead:

1. **Build a guaranteed-valid arrangement** using the template below.
2. **Scramble it with N random legal slides.**

This gives two guarantees for free:

- The level is always solvable (the scramble is reversible move-for-move).
- Sliding-puzzle parity is never an issue, because you never left the reachable state space.

It also means the scramble depth `N` is your difficulty dial: it is an upper bound on the
solution length.

### 9.2 The goal-arrangement algorithm

```
1. Pick a D-cluster of size d ∈ {1,2,3,4}, placed inside the inner 2×2
   (rows 3–4, cols 3–4). This guarantees its shell stays off the ring.

2. SHELL := every cell orthogonally adjacent to the D-cluster.
   Assign all of them B.
   (D now touches only B and D → D is content. B is interior → legal.)

3. BUFFER := every cell orthogonally adjacent to SHELL, not already assigned.
   Assign all of them A.
   (A never touches D, because every D-neighbour is already in SHELL.)

4. FREE := all remaining cells.
   No FREE cell touches B or D, so it may safely hold A or C.
   Place the level's C count here; fill the rest with A; place the gap here too.

5. Scramble with N random legal slides, rejecting immediate move reversals.
```

Because BUFFER is defined as *all* cells adjacent to the B-shell, C can never end up touching B
or D. The construction is correct by definition, not by search.

### 9.3 The four cores

| Core | d (D) | b (B shell) | Buffer (forced A) | Free cells |
|------|-------|-------------|-------------------|------------|
| I | 1 (single) | 4 | 8 | 23 |
| II | 2 (domino) | 6 | 10 | 18 |
| III | 3 (L-tromino) | 7 | 11 | 15 |
| IV | 4 (2×2 square) | 8 | 12 | 12 |

Bigger core → more of the board is structurally forced → harder. Cores map directly to the
game's four difficulty tiers.

---

## 10. The 32 levels

Eight levels per core, varying the C-count within the free region. Every row sums to
35 people + 1 gap.

| # | Core | A | B | C | D | Scramble |
|---|------|---|---|---|---|----------|
| 1 | I | 22 | 4 | 8 | 1 | 60 |
| 2 | I | 20 | 4 | 10 | 1 | 65 |
| 3 | I | 18 | 4 | 12 | 1 | 70 |
| 4 | I | 16 | 4 | 14 | 1 | 75 |
| 5 | I | 14 | 4 | 16 | 1 | 80 |
| 6 | I | 12 | 4 | 18 | 1 | 85 |
| 7 | I | 10 | 4 | 20 | 1 | 90 |
| 8 | I | 8 | 4 | 22 | 1 | 100 |
| 9 | II | 24 | 6 | 3 | 2 | 100 |
| 10 | II | 22 | 6 | 5 | 2 | 105 |
| 11 | II | 20 | 6 | 7 | 2 | 110 |
| 12 | II | 18 | 6 | 9 | 2 | 115 |
| 13 | II | 16 | 6 | 11 | 2 | 120 |
| 14 | II | 14 | 6 | 13 | 2 | 125 |
| 15 | II | 12 | 6 | 15 | 2 | 130 |
| 16 | II | 10 | 6 | 17 | 2 | 140 |
| 17 | III | 24 | 7 | 1 | 3 | 140 |
| 18 | III | 22 | 7 | 3 | 3 | 145 |
| 19 | III | 20 | 7 | 5 | 3 | 150 |
| 20 | III | 18 | 7 | 7 | 3 | 155 |
| 21 | III | 16 | 7 | 9 | 3 | 160 |
| 22 | III | 14 | 7 | 11 | 3 | 165 |
| 23 | III | 12 | 7 | 13 | 3 | 170 |
| 24 | III | 11 | 7 | 14 | 3 | 180 |
| 25 | IV | 22 | 8 | 1 | 4 | 180 |
| 26 | IV | 21 | 8 | 2 | 4 | 185 |
| 27 | IV | 20 | 8 | 3 | 4 | 190 |
| 28 | IV | 18 | 8 | 5 | 4 | 195 |
| 29 | IV | 17 | 8 | 6 | 4 | 200 |
| 30 | IV | 15 | 8 | 8 | 4 | 205 |
| 31 | IV | 14 | 8 | 9 | 4 | 210 |
| 32 | IV | 12 | 8 | 11 | 4 | 220 |

Store only these five numbers per level (A, B, C, D, scramble) plus an RNG seed. The generator
rebuilds the goal and the scramble deterministically at load — no level data needs to be
authored by hand, and the whole table costs well under 200 tokens of cart space.

### Multiple solutions

The template produces *one* valid arrangement, but many others exist for the same composition.
The player is never required to find yours. Check the win condition by evaluating all 35 moods,
never by comparing against a stored target layout.

---

## 11. Fresh cast, same rules

Each level generates "new people" without changing anything the player has to relearn:

- The four **rules** are permanent and never reshuffle.
- The four **sprite sets** are permanent too (players need type recognition to be instant).
- The **accessory layer** (hats, tufts, bands) was built and then **cut**: with 16×16 people
  packed edge to edge, anything sitting above the head overlapped the tile above it.
- What varies per level is the **composition** — the core shape, the C count and the scramble —
  plus the idle phase, staggered by `(col + row) % 4` so the room breathes as a wave.

---

## 12. Design risks and tuning

**35 sliding pieces is a lot.** A 6×6 single-gap puzzle can take 150+ moves even when the player
knows exactly what they want. Three mitigations, in order of preference:

1. **Lean on the loose win condition.** Because any valid arrangement wins, the effective
   solution is far shorter than a true 15-puzzle solve. Keep scramble depths at or below the
   table above and playtest before raising them. This is the intended solution.
2. **Immovable furniture.** Mark 2–6 cells as fixed blocks (a couch, a plant). They reduce the
   piece count, still leave exactly one gap, and add real spatial puzzle texture. This is the
   best expansion hook if the game plays long.
3. **Shrink the board to 5×5.** Only if playtesting shows the 6×6 is genuinely tedious. It would
   cost you the ring/interior distinction that makes B's rule interesting, so treat it as a last
   resort.

**Progress.** `cartdata("rf_roommates")`, one slot: `dset(0,lv)` on every level completed,
`lv=mid(1,dget(0),32)` at boot. A fresh save reads `0` and clamps to room 1, so no
initialisation step is needed. Slot 0 is the only one used — nothing else about a run is
worth persisting, because a room is generated from its number alone (§9).

**Undo.** Strongly recommended, even though the screen shows nothing but the board — bind it to
a held button. Long sliding puzzles without undo generate rage, not thought.

**Mad-count feedback.** Resist adding a counter to the game screen. If playtesters get lost,
add a subtle full-board pulse when the mad count decreases instead of a number.

---

## 13. Implementation checklist

- [ ] Extended palette remap to the four greens at boot
- [ ] 6×6 board state (35 person records + gap position)
- [ ] Person record: `{type, accessory, mood, anim_state, anim_frame, phase}`
- [ ] `is_mad(x, y)` evaluating the four rules on orthogonal neighbours
- [ ] Gap-relative D-pad movement with 6-frame ease-out tween
- [ ] Full-board mood re-evaluation on tween completion
- [ ] Change-detection → transition animation, staggered from the moved tile
- [ ] Goal generator (§9.2) + legal-move scrambler with reversal rejection
- [ ] 32-level table (§10)
- [ ] Win check: mad count == 0
- [ ] Intro, Tutorial, Game, Clear-progress screens
- [ ] Bedroom background and outlined text
- [ ] Progress saved to cartdata slot 0
- [ ] Undo stack
- [ ] Add cover art label