> **Superseded.** This is the original design, kept for the reasoning behind it.
> The shipped game has since been reworked: **four** layers instead of three,
> each drawn in its own quadrant instead of stacked with offsets; stacks hang
> from layer 1 downward; every stone is white when face up and dark grey with a
> red "?" while buried, so depth is read from the panel, not from three greys;
> the cursor visits buried stones and 🅾️ marks one with a guess; and a board
> ships only if the tally and its laws leave exactly one way to fill the buried
> cells. [README.md](README.md) is the current spec.

# STONE LOGIC — Design Document

**Platform:** PICO-8 (v0.2.7) · **Genre:** Deduction puzzle / Mahjong solitaire
**Working title:** STONE LOGIC
**One line:** A mahjong solitaire where the board is a logic problem — the laws tell you what is hidden under the stones, and one careless pair loses the round.

---

## 1. Design Pillars

1. **It is a puzzle, not a search.** Every board is solvable, but wrong (legal) moves exist and are fatal. Winning is deduction, not scanning.
2. **Hidden information with fair rules.** Covered stones hide their face. Three published *Laws* per round make the hidden faces deducible.
3. **Zero friction navigation.** The cursor can only ever sit on a legally selectable stone. The player never fights the input.
4. **Readable, professional, dithered.** Three greys, black icons, dithered bevels and shadows. Depth is read by value, never by hue.

---

## 2. Board Geometry

| Item | Value |
|---|---|
| Screen | 128 × 128 |
| Grid | 10 × 10 cells |
| Cell / stone | 12 × 12 px |
| Playfield | 120 × 120 px |
| Margin | 4 px on all sides |
| Layers | 3 (always) |
| Stones per round | 60 (30 pairs) |
| Faces (types) | 6 × 10 stones each |

```
cell_x(c) = 4 + c*12          -- c = 0..9
cell_y(r) = 4 + r*12          -- r = 0..9
```

### 2.1 Layer depth offset

Layer 1 is the front (top of the stack), layer 3 is the back (base).
Front layers are drawn shifted up-left by 2 px per level to read as a stack.

| Layer | Name | Draw offset | Slab colour | Bevel | Shadow |
|---|---|---|---|---|---|
| 1 | FRONT | (−4, −4) | 7 (white) | 6 | 5 |
| 2 | MID | (−2, −2) | 6 (light grey) | 5 | 13 |
| 3 | BACK | (0, 0) | 5 (dark grey) | 13 | 1 |

Layers 1 and 2 are always inset inside the layer-3 silhouette, so the negative
offsets never push a stone off screen.

**Draw order:** layer 3 → layer 2 → layer 1 (back to front), each layer's rows
top to bottom so shadows fall correctly.

### 2.2 HUD ribbon

A 128 × 14 ribbon lives at `y = 114`. All shipped silhouettes use rows **0–8**
only, so the ribbon never covers a stone. (If a custom template uses row 9, the
ribbon collapses into a 3-glyph corner counter instead.)

Ribbon contents: `PAIRS 30` (left) · law glyphs (centre) · layer filter dot (right).

---

## 3. Core Rules

### 3.1 Free stone

A stone is **free** (selectable) when both are true:

- **Not covered** — no stone occupies the same `(col,row)` on the layer in front of it.
- **One flank open** — the cell to its left *or* the cell to its right on **its own layer** is empty.

```lua
function is_free(t)
  if occ(t.c, t.r, t.l-1) then return false end   -- covered by a front layer
  return not (occ(t.c-1, t.r, t.l) and occ(t.c+1, t.r, t.l))
end
```

Vertical neighbours never block. This is the classic rule and it is easy to
teach in one tutorial screen.

### 3.2 Matching

- Select two stones with the **same face**.
- Both must be **free**.
- **Both must be on the same layer.** Cross-layer matches are illegal — this is
  the single house rule that turns the board into a layered logic problem.

### 3.3 Hidden faces

A stone whose cell is covered by a front-layer stone **does not show its face** —
it draws as a blank slab in its layer colour. Its face is revealed (with a
dither fade) the moment the covering stone is cleared.

Side-blocked stones still show their face; only *covering* hides information.
This is visually honest: a covered slab is 2 px of visible sliver anyway.

### 3.4 Win / Fail

- **Win:** board empty.
- **Fail:** stones remain and no legal match exists. Every board ships solvable,
  so a dead end is always the player's deduction error.
- On fail: `RETRY` (same layout, same seed) or `NEW LAYOUT`. Retry is the whole
  learning loop — the player now knows what was hidden.
- **No undo.** The stakes are the design.

---

## 4. The Laws (puzzle constraints)

Three laws are published per round, shown as glyphs in the HUD ribbon and in
full text on the LAWS panel (hold 🅾️). Every law is guaranteed true of the
initial layout.

### LAW 1 — BALANCE *(always active)*

> Every face appears exactly **10** times.

The player counts visible faces and knows the remainder is hidden. This alone
resolves many endgames.

### LAW 2 — BOND (A → B)

> Every **A** stone is orthogonally adjacent to at least one **B** stone on the same layer.

Used to *place* hidden stones: an isolated B with no visible A around it implies
a hidden A next to it.

### LAW 3 — TABOO (C ✕ D)

> No **C** stone is ever orthogonally adjacent to a **D** stone on the same layer.

Used to *eliminate*: a hidden cell touching a visible D cannot be a C.

### Difficulty ramp (round 4+, one substitution)

- **EDGE (E):** face E never appears on the outer ring of its layer.
- **DEPTH (F):** face F never appears on layer 1.
- Round 7+: only **two** laws published instead of three.

All laws are stated in terms of the **initial** layout, so they stay valid as
reference information for the whole round.

---

## 5. The Fork — why wrong moves exist

The user-facing example, formalised:

> Three stones of face ✦ are free on layer 2 at the same time. Only one of the
> three pairings leaves the board solvable. Picking wrong is legal, feels fine,
> and loses the round eight moves later.

**Why one pairing is correct:** the third ✦ is the only stone that can later
free a specific covered cell, or its future partner is a hidden ✦ that only
becomes reachable through a particular flank.

**Generator guarantee:** every round contains **at least 2 forks** (round 1–3),
scaling to 4+ later. A fork is a board state where ≥1 legal move destroys
solvability.

**Fairness guarantee:** at every fork, the correct branch must be determinable
from information the player can see — visible faces + the three laws + a
lookahead of at most **2 removals**. Forks that need deeper search are rejected
and the board is regenerated. *No guessing, ever.*

---

## 6. Layout Generation

Runs in a coroutine on a `DEALING…` screen so the console never hangs.

### Step 1 — Silhouette

Pick one template from a table (then randomly mirror horizontally). Templates
are stored as per-layer rectangles or 10-bit row masks.

| Template | L3 | L2 | L1 | Total |
|---|---|---|---|---|
| PAGODA | 36 (r1–6 × c2–7) | 16 (r2–5 × c3–6) | 8 (r3–4 × c3–6) | 60 |
| BRIDGE | 32 | 20 | 8 | 60 |
| CROSS | 30 | 20 | 10 | 60 |
| STAIRS | 34 | 18 | 8 | 60 |

Constraint: **total is always 60**, and each layer count is even.

### Step 2 — Reverse solve (guarantees solvability)

```
board := full silhouette (faces unknown)
slots := {}
while board not empty:
    free := all free cells of board
    pick two free cells on the SAME layer  -> slot
    remove both from board
    push slot
```

The resulting 30 slots are a valid removal order played backwards, so a
solution provably exists. Because both cells of a slot share a layer, the
invariant *"each face appears an even number of times on each layer"* is
satisfied automatically.

If no same-layer free pair exists mid-construction, backtrack one slot
(bounded to ~20 retries, then reroll the template).

### Step 3 — Face assignment under the laws

Assign the 6 faces to the 30 slots, 5 slots each (= 10 stones each), then repair:

1. Score the arrangement against the chosen BOND / TABOO laws.
2. While violations > 0: swap the faces of two random slots, keep the swap if
   the violation count drops (hill-climb, ~200 iterations).
3. If it never reaches 0, pick a different law pair and repeat.

Fallback if the budget runs out: **derive** the laws from the finished layout
instead of imposing them (scan for any (A,B) pair where BOND already holds, and
any (C,D) where TABOO already holds). A derived law must eliminate at least 8
candidate placements, otherwise it is rejected as trivial.

### Step 4 — Verification

- **Solvability:** guaranteed by step 2, re-checked by the solver.
- **Fork count:** DFS with a node cap (~4000 nodes, yielding every 200 nodes).
  Count states where a legal move kills solvability. Require ≥ 2.
- **Fairness:** each fork must be resolvable within lookahead depth 2.
- Any check fails → discard and regenerate (cap 6 attempts, then fall back to a
  hand-authored layout stored in the cart).

### Step 5 — Seed

The 32-bit seed of a verified board is shown on the fail/win screen and can be
re-entered from the pause menu. Retry replays the exact same board.

---

## 7. Controls & Navigation

| Input | Action |
|---|---|
| ⬅️➡️⬆️⬇️ | Jump cursor to the nearest **free** stone in that direction |
| ❎ | Select / confirm match / deselect (on the same stone) |
| 🅾️ *(tap)* | Cycle layer focus: ALL → L1 → L2 → L3 (non-focused layers dim by 1 dither step) |
| 🅾️ *(hold)* | LAWS panel overlay |
| ❎ *(hold 0.5s)* | PEEK — pulse-highlight every free stone |
| Pause | Retry seed · New layout · Tutorial · SFX/Music |

### Directional jump

The cursor never lands on a blocked stone. Candidates are filtered to free
stones, then scored:

```lua
-- dir vector (dx,dy); pick smallest cost among candidates in the half-plane
cost = along*1.0 + abs(perp)*2.5     -- forward distance + heavy perpendicular penalty
```

Ties break toward the front layer (lower `l`), then lower row. If no candidate
lies in that direction, wrap to the far side of the board. After a match, the
cursor snaps to the nearest free stone to the cleared cell.

The selected stone stays marked while the cursor moves; a thin dithered line
connects cursor and selection so the intent is always legible.

---

## 8. Art Direction

### 8.1 Palette

Depth is read only by value — no hue on the stones.

```
7  white       layer 1 face
6  light grey  layer 2 face / layer 1 bevel
5  dark grey   layer 3 face / layer 2 bevel
13 mid indigo  layer 3 bevel / deep shadow
1  dark blue   contact shadow
0  black       outline + all icons
8  red         mismatch flash only
10 yellow      match sparkle only
```

### 8.2 Stone anatomy (12 × 12)

```
row 0      1 px black outline (top + left)
rows 1-9   face plate, flat colour
row 10     bevel: dither ramp face→bevel  (fillp 0b0101101001011010)
row 11     bevel solid + 1 px black bottom outline
+2,+2      drop shadow, 4-wide dither in colour 1/0, only where nothing is behind
```

The icon is an **8 × 8 black sprite centred at (+2,+2)** inside the slab. Slabs
are drawn procedurally (`rectfill` + `fillp`), so the sprite sheet only stores
6 icons + particles + font extras. Keeps the sheet almost empty for the
tutorial art.

### 8.3 Dithering rules

- Ramp order: `7 → 6 → 5 → 13 → 1 → 0`.
- Bevels: 50 % checker between the face colour and the next ramp step down.
- Shadows: 25 % dither of colour 1 over the backdrop (never solid black).
- Dimmed layers (layer focus mode): one ramp step down + 50 % dither.
- Backdrop: vertical 3-step dither gradient, `1 → 13 → 5`, static, drawn once
  to the screen at load.

### 8.4 Faces (6 icons, silhouette-first)

| # | Name | Silhouette |
|---|---|---|
| 1 | DOT | filled circle with 1 px highlight |
| 2 | BAMBOO | two vertical bars, notched |
| 3 | WAVE | double S-curve |
| 4 | STAR | 4-point diamond star |
| 5 | MOUNTAIN | solid triangle with a notch |
| 6 | CROSS | thick plus, hollow centre |

All six must be distinguishable at a glance in black on white **and** black on
dark grey — test by rendering all six on all three slab colours side by side.

---

## 9. Juice

### Feedback map

| Event | Visual | Audio |
|---|---|---|
| Cursor move | Corner brackets snap + 2 px overshoot ease | SFX 0 — short blip, pitch by layer |
| Select | Stone lifts 1 px, white outline pulse, shadow grows | SFX 1 — rising blip |
| Deselect | Drops back, dust puff | SFX 2 |
| Match | Both stones squash → pop (`sspr` scale 1.0→1.25→0), 8 sparkle particles, 1 px screenshake, 1-frame `pal` flash | SFX 3 — arpeggio, +2 semitones per combo |
| Reveal | Uncovered face fades in over 4 frames of animated `fillp` | SFX 5 — soft chime |
| Mismatch | 3-frame horizontal shake, red rim flash (colour 8) | SFX 4 — low buzz |
| No free pair of that face | Every visible stone of that face blinks once | SFX 4 (quiet) |
| Deal in | Stones fall from the top with 3-frame stagger + landing dust | SFX 9 arpeggio sweep |
| Win | Sparkle cascade left→right over cleared cells, seed stamp | SFX 6 — fanfare |
| Dead end | Board desaturates via `pal` to the 1/13/5 ramp, `NO MOVES` stamp with drop-in | SFX 7 — descending |

### Combos

Consecutive matches with no cursor idle > 90 frames raise a combo counter shown
next to the pairs counter. Combo only affects sound pitch and end-of-round
score — never the puzzle.

### Music

- Pattern 00–01: ambient loop, sparse plucks, low tempo.
- Pattern 02: tension variant, triggered when ≤ 6 pairs remain.
- Pattern 03: win stinger. Pattern 04: fail stinger.

---

## 10. Tutorial

Five scripted mini-boards, replayable from the pause menu, each with a
2-line text box in the HUD ribbon and a bouncing arrow pointer. Player must
perform the action to continue — no passive text screens.

| # | Board | Teaches |
|---|---|---|
| 1 | 6 stones, layer 3 only | Cursor only visits free stones; match two identical stones |
| 2 | 8 stones, layers 3 + 2 | Covering blocks; flanked stones are blocked; try an illegal cross-layer match and see it refused |
| 3 | 10 stones, layers 3 + 2 | Hidden faces: clear a cover, watch the reveal. "You cannot see it — you can *deduce* it" |
| 4 | 12 stones, 3 laws shown | Apply BALANCE + BOND + TABOO to name a hidden face before revealing it; the game asks the player to pick the cell, then reveals |
| 5 | 14 stones, forced fork | Three free ✦. The tutorial lets the wrong choice happen, shows the dead end, then rewinds and walks the correct deduction |

Step 5 is the whole game in miniature and is the last thing the player sees
before round 1.

---

## 11. Round Progression

| Round | Silhouettes | Forks | Laws | Notes |
|---|---|---|---|---|
| 1 | PAGODA | 2 | 3 | Post-tutorial, gentle |
| 2–3 | any | 2–3 | 3 | |
| 4–6 | any | 3 | 3 (one is EDGE/DEPTH) | |
| 7+ | any | 4+ | 2 | Less published information |

Score: `pairs × 10 + time bonus + no-mistake bonus (500)`. Best score and best
streak persist via `cartdata`.

---

## 12. Data Model & Budget

```lua
-- occupancy: 3 layers x 100 cells, flat table
-- key = l*100 + r*10 + c
occ_t = {}                  -- key -> tile index or nil

-- tiles
t = {
  c, r, l,                  -- grid position
  face,                     -- 1..6
  alive,                    -- bool
  hidden,                   -- cached: covered => face not drawn
  ax, ay, asc, atimer       -- animation offsets / scale
}
```

Derived caches (`free`, `hidden`) are rebuilt only after a removal — never
per frame.

### Token budget (PICO-8 cap 8192)

| Module | Est. tokens |
|---|---|
| Core state, tile table, occupancy | 500 |
| Free/hidden/match rules | 350 |
| Generator (silhouettes + reverse solve) | 900 |
| Law assignment + repair | 700 |
| Solver / fork + fairness verification | 900 |
| Cursor navigation | 450 |
| Rendering (slabs, dither, layers, HUD) | 1100 |
| Animation + particles | 700 |
| Tutorial script + text | 900 |
| Menus, score, cartdata | 500 |
| SFX/music triggers | 200 |
| **Total** | **~7200** |

Headroom ≈ 1000 tokens. If the budget tightens, the first cut is the fairness
verifier (replace with a hand-tuned fork heuristic), then the STAIRS template.

---

## 13. Build Order

1. Grid, stone rendering with dither, three layers, static hand-made layout.
2. Free rule + cursor navigation (free stones only) + selection.
3. Matching, removal, reveal, hidden faces.
4. Reverse-solve generator (no laws) — verify boards are always beatable.
5. Solver + fork detection; tune to ≥ 2 forks.
6. Laws: assignment, repair, HUD glyphs, LAWS panel.
7. Fairness verifier + regeneration loop + `DEALING…` coroutine screen.
8. Juice pass: animations, particles, screenshake, SFX, music.
9. Tutorial (5 boards).
10. Menus, score, cartdata, seed display, polish.

---

## 14. Open Questions

- Should side-blocked-but-uncovered stones on layer 3 dim slightly to help the
  eye find free stones, or does PEEK cover that need?
- Is 60 stones the right round length, or does 48 (6 faces × 8) pace better
  after playtesting?
- Should a fail on round 7+ offer a one-move rewind as a mercy, or does that
  dissolve the core tension?
