# RING SORT — PICO-8 Design Document

A logic puzzle where the player moves colored rings between 8 vertical pillars until every
pillar holds rings of a single color. A neighbor-blocking rule set turns the classic sort
puzzle into a constraint-satisfaction problem.

- **Platform:** PICO-8 (128×128, 16 colors, 8×8 sprites)
- **Genre:** Logic puzzle, single player, no timer
- **Levels:** 20, handcrafted + solver-verified
- **Session length:** 1–4 min per level

---

## 1. Core loop

1. Player picks a level on the intro screen.
2. Board loads: 8 pillars, some filled with mixed rings, some empty.
3. Player lifts the **top** ring of a pillar and drops it on another pillar.
4. A drop is legal only if the destination has room **and** the ring below is not a
   forbidden neighbor.
5. When every pillar is empty or single-colored, the level is solved and the next unlocks.

**There is no undo.** Every move is committed. This is the central design tension: the
player must plan before touching a ring, because a bad move can permanently lock a level.
See §7 for how the game handles dead states.

---

## 2. Rules

### 2.1 Board
| Property | Value |
|---|---|
| Pillars | **8, always** (every level) |
| Pillar capacity `K` | 2–5 rings, uniform within a level |
| Colors `C` | 4–7 per level |
| Rings per color | exactly `K` |
| Free pillars | `8 - C` |
| Total rings | `C × K` |

### 2.2 Movement
- Only the **topmost** ring of a pillar can be lifted.
- A lifted ring can only be dropped on a pillar (no discarding, no swapping).
- A ring can be dropped back onto its source pillar for free (cancel — costs no move).
- A pillar at capacity `K` rejects all drops.
- Empty pillars accept any ring regardless of rules.

### 2.3 Neighbor blocking rule
Each level defines 0–4 **forbidden pairs** `{A, B}` of distinct colors.

> If `{A, B}` is forbidden, a ring of color A may never rest directly on top of or directly
> below a ring of color B, on any pillar.

The rule is **symmetric** and **strictly adjacent** — it only constrains rings touching each
other. A pillar `[A, C, B]` is legal even if `{A,B}` is forbidden, because C separates them.

Because rings only ever enter a pillar at the top, one check covers both directions:

```
can_place(color, pillar):
    if #pillar >= K            -> false   (full)
    if #pillar == 0            -> true    (empty pillar accepts anything)
    if forbidden(color, top_of(pillar)) -> false
    return true
```

**Constraints on rule generation:**
- Never `{A, A}` — a self-pair makes the level unsolvable (a solved pillar stacks a color on itself).
- Forbidden pairs never block the **win state**, since a finished pillar is monochrome.
- Rules only ever restrict the *path* to the solution, never the solution itself.

**Rule topology is a difficulty knob:**
| Shape | Example | Effect |
|---|---|---|
| Disjoint | `{A,B}`, `{C,D}` | Mild. Two independent constraints. |
| Chain | `{A,B}`, `{B,C}` | Hard. B becomes hard to park anywhere. |
| Hub | `{A,B}`, `{A,C}`, `{A,D}` | Brutal. A is almost untouchable — needs a dedicated free pillar. |

Use disjoint pairs before level 10, chains from 10–15, hub/chain mixes for 16–20.

### 2.4 Win condition
Every pillar is either empty or contains rings of exactly one color. Because each color has
exactly `K` rings and capacity is `K`, this always means `C` full monochrome pillars and
`8 - C` empty ones.

---

## 3. Level progression

`K` = rings per pillar, `C` = colors, `F` = free pillars (`8-C`), `R` = number of forbidden pairs.

| # | K | C | F | R | Rule shape | Intent |
|---|---|---|---|---|---|---|
| 1 | 2 | 4 | 4 | 0 | — | Teach lift/drop. Nearly unlosable. |
| 2 | 2 | 5 | 3 | 0 | — | Same, less space. |
| 3 | 2 | 6 | 2 | 0 | — | Space pressure introduced. |
| 4 | 2 | 6 | 2 | 1 | disjoint | **Rule tutorial.** Force a blocked drop early. |
| 5 | 3 | 5 | 3 | 1 | disjoint | Deeper stacks, forgiving space. |
| 6 | 3 | 6 | 2 | 1 | disjoint | — |
| 7 | 3 | 6 | 2 | 2 | disjoint | Two constraints to track. |
| 8 | 3 | 7 | 1 | 1 | disjoint | **One free pillar.** Space is the puzzle. |
| 9 | 4 | 5 | 3 | 2 | disjoint | Buffer level before the spike. |
| 10 | 4 | 6 | 2 | 2 | chain | **Difficulty spike starts here.** |
| 11 | 4 | 6 | 2 | 3 | chain | — |
| 12 | 4 | 7 | 1 | 2 | chain | 1 free pillar + chain. |
| 13 | 4 | 7 | 1 | 3 | chain | — |
| 14 | 5 | 5 | 3 | 3 | chain | Max depth introduced with breathing room. |
| 15 | 5 | 6 | 2 | 3 | chain | — |
| 16 | 5 | 6 | 2 | 4 | chain + hub | — |
| 17 | 5 | 7 | 1 | 3 | hub | The hub color needs the free pillar reserved. |
| 18 | 5 | 7 | 1 | 4 | hub | — |
| 19 | 5 | 7 | 1 | 4 | long chain | — |
| 20 | 5 | 7 | 1 | 4 | hub + chain | Finale. Target ≥ 45 optimal moves. |

**Difficulty targets (minimum optimal move count, from the offline solver):**
- Levels 1–4: 4–12 moves
- Levels 5–9: 12–22 moves
- Levels 10–15: 24–38 moves
- Levels 16–20: 38–55 moves

**Measured pars** (`node verify.js`, re-measured from the strings in the cart):

| # | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| par | 6 | 7 | 9 | 8 | 13 | 17 | 16 | 23 | 18 | 24 |

| # | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 |
|---|---|---|---|---|---|---|---|---|---|---|
| par | 24 | 35 | 33 | 25 | 31 | **32** | 42 | 43 | 43 | 41 |

> **Level 16 misses its target and is shipped anyway.** It measures 32 against a floor of 38.
> This is a limit of the level's own spec, not a bad board: with `K=5, C=6` there are only 30
> rings, and a re-run at 4× the sampling (1000 candidates, 384 s) still topped out at 32.
> Forbidden pairs constrain the *path* to the solution, not its length — compare level 15, the
> same `K=5, C=6` with one rule fewer, at par 31, against level 17, which adds a seventh colour
> and jumps to 42. A seventh colour is worth ~10 moves; a fourth rule is worth ~1. So the
> 38–55 band is only reachable from `C=7`, i.e. from level 17 on.
>
> The curve is still monotone across the seam (31 → 32 → 42), and level 16's job in the
> progression is its rule topology — the first hub/chain mix — rather than its length. Reaching
> 38 would mean promoting it to `C=7`, which would move the deliberate 2-free-pillars →
> 1-free-pillar step from level 17 to level 16 and make the two levels the same shape. Not
> worth it for a number.

---

## 4. Level generation & storage

Levels are **generated offline** (Lua or Python script, not shipped in the cart) and pasted
in as data. Runtime generation is not worth the tokens and cannot guarantee solvability.

**Generator algorithm (reverse shuffle + verify):**
1. Build the solved state: `C` monochrome pillars of `K` rings, `F` empty.
2. Pick the rule set for the level (see §2.3 shapes).
3. Apply `N` random **reverse** moves (take top ring, place elsewhere), rejecting any move
   that would create a forbidden adjacency. Every intermediate state stays rule-legal.
4. Run a forward BFS/IDDFS solver on the shuffled state.
   - Reject if unsolvable (shouldn't happen, but a bug guard).
   - Reject if the optimal solution is shorter than the level's difficulty target.
   - Reject if any pillar is already monochrome-and-full at start (feels like a gift).
5. Emit the level string.

**Regenerating levels.** `node gen-levels.js [--from N] [--to M] [--samples S]` appends one
JSON record per level to `levels.jsonl` as it goes, so a long run survives an interrupt and
any sub-range can be redone on its own — each level seeds its own RNG stream, so a re-run of
one level reproduces byte-for-byte. `node setlevels.js levels.jsonl` splices the strings into
the cart; later records win, so re-running a single level and passing its file last replaces
just that entry. `node verify.js` then re-measures whatever is actually in `game.p8`, which is
the check that matters — it reads the shipped strings, not the generator's own output.

**Storage format** — one string per level, cheap in tokens:

```
"K|C|rules|p0,p1,p2,p3,p4,p5,p6,p7"
```

- Colors are single hex digits `0`–`6`.
- `rules` is a flat list of digit pairs: `"0312"` = forbidden `{0,3}` and `{1,2}`. Empty = no rules.
- Each pillar is listed **bottom → top**; `-` means empty.

Example (level 4: K=2, C=6, one rule `{0,3}`):
```lua
"2|6|03|01,34,25,10,43,52,-,-"
```

Parse once on level load into `pillars[8] = {colors...}` and a 7×7 `blocked` lookup table.

---

## 5. Scenes

### 5.1 Scene 1 — Intro

```
        R I N G   S O R T          <- logo, dithered shadow, gentle bob
     ------------------------
          <  LEVEL 07  >           <- ⬅️➡️ cycle unlocked levels
     ------------------------
          [   S T A R T   ]        <- ❎/🅾️ pulsing plate
       ★ ★ ★ ★ ★ ★ ★ ☆ ☆ ☆        <- progress row, 20 pips
```

- `⬅️` / `➡️` — change level. Wraps. Locked levels show a padlock and cannot be selected.
- `❎` or `🅾️` — start.
- Level number rendered with the large custom digits (sprites 88–97).
- Background: slow vertical dither gradient (`fillp` bands), a few drifting ring silhouettes
  in dark blue behind the logo.
- **Pause menu:** `CLEAR PROGRESS`.
  - Two-step confirm — the menu item relabels to `SURE? PRESS AGAIN` on the first press and
    reverts after ~2 seconds or on menu close. Progress deletion is destructive and the
    game has no undo philosophy anywhere, so this one guard is deliberate.

### 5.2 Scene 2 — Game

The eight pillars are laid out as **two rows of four**, not one row of eight.
A row of eight gives each pillar 16 px, which is barely wider than a sprite and
forces rings to read as flat chips. Two rows of four give each pillar 32 px, so
a ring can be 24 px of actual art with visible curvature and a real hole.

```
 LEVEL 12              MOVES 07     <- y 0..8
 ------------------------------
     ▭                              <- held ring, level with the post cap
     ║    ║    ║    ║               <- row 0 posts
   ▭▭▭  ▭▭▭  ▭▭▭  ▭▭▭
   ▬▬▬  ▬▬▬  ▬▬▬  ▬▬▬               <- row 0 bases, y=52
     ║    ║    ║    ║               <- row 1 posts
   ▭▭▭  ▭▭▭  ▭▭▭  ▭▭▭
   ▬▬▬  ▬▬▬  ▬▬▬  ▬▬▬               <- row 1 bases, y=100
      ▲                             <- cursor chevron
 ------------------------------
  [●✗●]  [●✗●]  [●✗●]              <- y 111..127: rule HUD
```

Pillars are numbered in reading order: 1–4 across the top row, 5–8 across the
bottom.

**Layout (pixels):**
| Element | Value |
|---|---|
| Pillar pitch | 32 px — pillar `i` occupies x = `((i-1)%4)*32` .. `+31` |
| Row pitch | 48 px — row `(i-1)\4`, bases at y = 52 and y = 100 |
| Ring art | 24×9, drawn with `sspr` from (0,0); 4 px gap each side |
| Ring pitch | 6 px — each ring **overlaps** the one below by 3 px |
| Stack base | y = `pby(i)`; ring `j` top edge = `pby(i) - 9 - (j-1)*6` |
| Pillar post | 4 px wide at x+14, cap at `pby - 13 - (K-1)*6` |
| Held ring | floats level with the post cap, `pby - 18 - (K-1)*6` |
| Top bar | y 0–8 |
| Rule HUD | y 111–127 |

The held ring's height is one full ring above a *full* stack, so it never merges
into the pile it is hovering over. Where it would land is communicated by its
dithered shadow, which sits on the stack top, not by its own height.

**Ring rendering — three passes per pillar.** A ring is threaded *onto* the
post, not parked in front of it, so each pillar draws in three passes,
bottom-to-top within each:

1. every ring's **far arc** (art rows 0–3, the back of the torus),
2. the **post**,
3. every ring's **near arc** (art rows 4–8, the front of the torus).

The post therefore covers the far arc, shows through the hole, and is covered by
the near arc — which is what makes the ring look like it is around the pillar.
Because pass 3 happens after every pass 1, an upper ring's near arc also
occludes the far arc of the ring beneath it, so the 3 px overlap reads as a
stack rather than as clipping.

`dring` remaps colours 2, 8 and 14 with `pal()` to make the seven colour slots
from one template, so passes 2 and the bases must `pdef()` first — the post is
drawn in exactly those colours and will otherwise inherit the last ring's.

**Controls:**
| Input | Empty hand | Holding a ring |
|---|---|---|
| `⬅️` `➡️` | move cursor within the row | move the held ring within the row |
| `⬆️` `⬇️` | switch row, keeping the column | same, ring travels with the cursor |
| `❎` / `🅾️` | lift top ring of current pillar | drop on current pillar |

- With a 4×2 grid, `⬆️`/`⬇️` are navigation. They were lift/drop aliases when the
  board was a single row of eight and up/down had nothing to steer; both face
  buttons still do lift and drop, so nothing is lost.
- Cursor never wraps past the edges — it clamps at both ends of a row, and
  up/down do nothing from the row that has no neighbour.
- Lifting an empty pillar → soft error blip, small cursor shake, no move counted.
- Dropping onto the source pillar → free cancel, no move counted.
- Illegal drop → **blocked feedback** (see §6.3), no move counted, ring stays in hand.

**Rule HUD (bottom bar):**
Each active rule renders as a small plate: `[ ●  ✗  ● ]` — two 8×8 color pips of the paired
colors with a red X (sprite 72) between them. Up to 4 plates fit across 128 px (28 px each,
4 px gaps). If a level has 0 rules, the bar shows a thin dithered divider and the text
`NO RESTRICTIONS`.

When a drop is blocked, the **specific plate that caused it** flashes: the red X scales up
2× for 8 frames and the plate border pulses red 8→14→8. This teaches the rule without text.

- **Pause menu:** `BACK TO MENU` (returns to intro, discards level progress — re-entering
  the level restarts it clean, which is the game's implicit "restart").

---

## 6. Juice — animation & SFX

Every interaction gets a sound *and* a motion. Nothing snaps instantly.

### 6.1 Animation table
| Event | Animation | Frames |
|---|---|---|
| Cursor move | Pillar cap bounces 2 px, cursor arrow eases with overshoot | 6 |
| Ring lift | Ring rises to the post-cap height with ease-out | 8 |
| Held ring idle | Bobs ±1 px on a sine, casts a dithered shadow on the pillar below | loop |
| Held ring travel | Ease toward the cursor pillar, in both axes when the row changes, + slight lean in the direction of travel | 6 |
| Ring drop | Falls with gravity accel, **squashes** on landing, settles | 10 |

The squash is a scaled `sspr` of the whole template drawn in the near-arc pass,
not a second sprite and not split into arcs — for the eight frames it lasts, the
saving is worth the post showing through the hole rather than over the far arc.
| Landing ripple | Rings below the landed one shift down 1 px and pop back, cascading | 4 each |
| Blocked drop | Held ring shakes horizontally ±2 px, flashes to color 8 for 2 frames | 10 |
| Pillar completed | Rings flash white bottom→top, sparkles (sprites 96–99) rise, pillar cap glows | 20 |
| Level complete | All pillars flash in sequence, rings spin off screen, confetti, banner drops in | 90 |
| Level unlock (intro) | New star pip pops in with a shine sweep | 24 |
| Title logo | Continuous 2 px sine bob, shine sweep every 4 seconds | loop |
| Start button | Scale pulse 1.0→1.06 on a slow sine | loop |

All easing via a small `lerp`/`ease_out` helper — no per-object tween library, keep tokens low.

### 6.2 SFX allocation
Keep the sound palette warm: **avoid instrument 6 (noise)** everywhere, including SFX, so the
audio stays consistent with the calm music. Percussive feel comes from short low triangle
notes with fast decay.

| # | Sound | Notes |
|---|---|---|
| 0 | Cursor move | Very short organ blip, high, vol 2 |
| 1 | Ring lift | Rising 3-note triangle, soft |
| 2 | Ring drop (low stack) | Warm pulse thud + soft click |
| 3 | Ring drop (mid stack) | Same, pitched +3 semitones |
| 4 | Ring drop (high stack) | Same, pitched +6 — stacking *sounds* like it rises |
| 5 | Cancel / drop on source | Soft descending 2-note |
| 6 | **Blocked** | Low organ with fast downward pitch bend, vol 4. Distinct, not harsh. |
| 7 | Empty pillar lift attempt | Tiny muted tick |
| 8 | Pillar completed | 4-note major arpeggio, bright pulse |
| 9 | Level complete | 8-note flourish, two channels |
| 10 | Menu confirm | Clean rising pair |
| 11 | Menu back | Falling pair |
| 12 | Level select tick | Soft wood-block-ish triangle |
| 13 | Star unlock | Shimmer — fast ascending organ run |
| 14 | No moves left | Slow descending minor third, quiet |
| 15 | Title shine | Soft high sweep |

Drop SFX pitch scales with stack height (`sfx(2 + min(2, flr(#pillar/2)))`) — a free
feedback channel that makes the board legible by ear.

### 6.3 Blocked-drop feedback stack
Three simultaneous signals so the rule lands immediately:
1. SFX 6 (low bend).
2. Held ring shake + red flash.
3. The offending HUD rule plate pulses and its red X scales up.

---

## 7. Dead states (no-undo consequence)

With forbidden pairs and no undo, the player can reach a position where no legal move exists,
or where the level is unwinnable. The game must not leave them stuck without acknowledgment.

**Detection:** after every committed move, scan all `8×8` source/destination pairs. If no
legal move produces a *new* state, the board is dead.

```
has_move():
    for src in 0..7:
        if #pillars[src] > 0 and not monochrome_full(src):
            for dst in 0..7:
                if dst != src and can_place(top(src), dst) then return true
    return false
```

**Response:** SFX 14, the board desaturates via `pal()` to greys over 30 frames, and a
banner reads `NO MOVES LEFT — 🅾️ RETRY`. One button press reloads the level from its
string. Cheap to implement, and it keeps "no undo" honest — the punishment is the restart,
not confusion.

*Note:* full unwinnability (legal moves exist but the level can no longer be solved) is
**not** detected at runtime — that would need a solver in-cart. Dead-end detection covers the
frustrating case; the rest is the player's problem, which is the point of a no-undo puzzle.

---

## 8. Art direction

**Professional, dithered, warm.** Rings should read as physical objects with weight, not flat
UI chips.

### 8.1 Palette
| Role | PICO-8 colors |
|---|---|
| Background gradient | 1 → 13 → 12, dithered bands via `fillp` |
| Pillars | 4 (body), 2 (shadow side), 15 (top-edge highlight) |
| Pillar base | 5 with 6 rim light |
| Text | 7 with 0 outline (always outlined) |
| Danger / blocked | 8, accented 14 |

**Ring colors (7 slots)** — each ring uses a body color, a shade, and a highlight:
| Slot | Body | Shade | Highlight |
|---|---|---|---|
| 0 | 8 red | 2 | 14 |
| 1 | 9 orange | 4 | 15 |
| 2 | 10 yellow | 9 | 7 |
| 3 | 11 green | 3 | 7 |
| 4 | 12 blue | 13 | 6 |
| 5 | 14 pink | 2 | 15 |
| 6 | 6 light grey | 5 | 7 |

Levels with `C<7` use slots `0..C-1`, so early levels get maximum hue separation.

### 8.2 Dithering usage
- **Background:** solid colour 1 through the middle, with a three-step dithered fade at the
  top edge (1 -> 13, lightening) and the bottom edge (1 -> 0, darkening), using
  `fillp(0b0101101001011010)` (checker) and `fillp(0b0111110111011111)` (sparse). Each band
  packs two colours into one byte — high nibble on the pattern's set bits, low nibble on the
  clear ones — so `0x1d` over the sparse pattern is mostly 1 with flecks of 13.
  **The centre must stay flat.** The rings are themselves dithered, so a pattern behind them
  competes with their shading and reads as noise instead of depth. The gradient earns its keep
  at the borders and gets out of the way over the board. The bottom fade starts below the
  lower row's bases (y=106) so no pillar stands on a patterned floor.
  Static — never animate the background dither.
- **Rings:** hand-dithered pixel art on the sprite sheet — a 2-row dither band on the lower
  third of each ring blending body → shade gives the torus curvature.
- **Shadows:** the held ring's ground shadow is a `fillp` ellipse in color 0, sparse pattern.
- **Vignette:** dithered dark corners (sprites 120–127) drawn over the board area.
- Reset with `fillp()` after every dithered draw call — a leaked fill pattern is the classic
  PICO-8 bug here.

### 8.3 Sprite sheet allocation
The sheet holds **one** ring template, recoloured seven ways by `pal()` at draw
time, plus a handful of 8×8 UI tiles. That is far less than the allocation
below, which assumed a per-colour sprite for every state — one template plus
`pal()` keeps the seven slots pixel-identical and leaves the sheet nearly empty.

| Region | Content |
|---|---|
| (0,0) 24×9 | The ring template, addressed with `sspr`, not on the tile grid. Rows 0–3 are the far arc, rows 4–8 the near arc. Colours: 0 outline, 8 body, 2 shade, 14 highlight, 1 transparent. |
| spr 4 | 8×8 colour pip for the rule HUD (same template, solid — a hole reads as noise at that size) |
| spr 5 | Red X for the rule plates |
| spr 6 | Padlock (locked level) |
| spr 7 / 8 | Progress pip, cleared / uncleared |
| spr 9 | Level-select arrow (flipped for the right one) |
| spr 10 | Cursor chevron |

Pillars, bases, plates, the vignette, the logo and the large level number are
drawn with primitives and P8SCII wide/tall text instead of sprites — tokens are
the cheaper resource here, and text stays crisp.

Use the map region (shared lower half) for the intro background composition if the sheet
fills up.

---

## 9. Music

**Relaxing, classical-derived, zero noise channel.**

- Never use instrument 6 (noise) in any pattern. Percussion, if any, is a low triangle
  (instrument 0) at volume 1–2 with a 1-tick decay.
- Preferred instruments: **0 triangle** (melody), **5 organ** (pads/harmony),
  **4 pulse** (soft counter-melody), **1 tilted saw** at low volume for warmth.
- Tempo: `SPD 20–26`. Slow. The player is thinking.
- Volume ceiling 4 — the SFX should always sit above the music.
- Draw on public-domain sources: Satie's *Gymnopédies* (sparse, ideal for 3 channels),
  Bach's *Prelude in C* (arpeggio figures that loop beautifully), Chopin nocturne voicings.
  Write **original arrangements in that idiom** rather than transcribing — a 4-channel
  transcription of a piano piece always sounds cramped.

| Patterns | Track | Structure |
|---|---|---|
| 0–3 | Title theme | 4 patterns, slow arpeggio + sustained pad, loops |
| 4–11 | Gameplay A | 8 patterns, ~90 s before repeat, used levels 1–10 |
| 12–19 | Gameplay B | Same mood, minor-key variation, levels 11–20 |
| 20–23 | Level complete | Short flourish, no loop, returns to gameplay track |

Avoid a 4-bar loop repeating forever — with 20 levels the player will hear it for a long
time. Two 8-pattern tracks with internal variation is the minimum for comfort.

---

## 10. Persistence

```lua
cartdata("roberto_ringsort")
```

| Slot | Content |
|---|---|
| 0 | Highest unlocked level, 1–20 |
| 1 | Last selected level (cursor position on intro) |
| 2–21 | Best move count per level, 0 = not yet cleared |

`CLEAR PROGRESS` zeroes slots 0–21 and sets slot 0 back to 1.

---

## 11. Code structure

```
_init()          -- cartdata, build tables, set scene=intro
_update60()      -- dispatch by scene
_draw()          -- dispatch by scene

scenes/
  intro   : upd_intro()  drw_intro()
  game    : upd_game()   drw_game()
  win     : upd_win()    drw_win()      -- overlay on game

core/
  load_level(n)          -- parse level string -> pillars, blocked[][], K, C
  can_place(color, dst)
  do_move(src, dst)
  is_solved()
  has_move()

fx/
  anims  = {}            -- flat list of {t, dur, kind, data}
  add_fx(kind, data, dur)
  upd_fx()  drw_fx()
  particles = {}         -- simple x,y,dx,dy,life,spr
```

**Scene state machine:** a single `scene` string plus a `trans` timer for fades. Keep the
pause-menu items registered per scene — call `menuitem()` on scene entry and clear the unused
slot with `menuitem(2)`.

**Rough token budget (limit 8192):**
| System | Est. tokens |
|---|---|
| State machine + input | 500 |
| Board logic (place/move/solve/deadlock) | 700 |
| Rendering (board, HUD, intro) | 1400 |
| Animation & particles | 900 |
| Level data (20 strings) | 450 |
| Cartdata & menus | 250 |
| **Total** | **~4200**, leaving room for polish |

---

## 12. Open decisions with answers [YES/NO]

Flagging these because they change the feel and are worth deciding before implementation:

1. **Colorblind support.** [YES] Seven ring colors with 4 free palette slots is tight. Optional:
   a tiny 3×3 symbol embedded in each ring's center (dot, bar, cross, ring…). Costs one
   sprite variant per color but makes levels 17–20 readable for everyone.
2. **Move counter — pressure or record?** [NO] Currently displayed and stored as a best score.
   If it creates anxiety in a "relaxing" game, hide it during play and only reveal it on the
   win screen.
3. **Level 4 rule tutorial.** [NO] Consider scripting it: the first blocked drop pauses the game
   for 60 frames and draws an arrow from the held ring to the HUD plate. One-time, stored in
   cartdata.
4. **Free cancel.** [YES] Dropping a ring back on its source costs nothing. If that feels too
   forgiving for a no-undo game, make it cost a move — but keep it legal, since it's the only
   way to re-read the board with a ring in hand.
