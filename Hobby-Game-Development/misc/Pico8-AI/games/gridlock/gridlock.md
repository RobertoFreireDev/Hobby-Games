# Gridlock — design

A sliding-block puzzle for PICO-8. Rectangular pieces are locked to a 6x6 board and can only
slide along their own long axis. One piece is the **main piece**; the goal is to clear a path
and drive it out through the exit on the right wall.

**You get exactly par moves.** Par is the true minimum. Spend one move more than that and the
whole board detonates and the level restarts. There is no such thing as a sloppy win.

---

## 1. Board

- Grid is **6x6 cells**. Coordinates are `(x, y)` with `x` growing right, `y` growing down,
  both `0..5`.
- Cells are either empty or occupied by exactly one piece. No overlap is ever legal.
- The board is fully enclosed by walls except for a single **exit gap** in the right wall at
  row `y = 2`.

```
      x0 x1 x2 x3 x4 x5
 y0    .  .  .  .  .  .
 y1    .  .  .  .  .  .
 y2    .  .  .  .  .  .  --> EXIT
 y3    .  .  .  .  .  .
 y4    .  .  .  .  .  .
 y5    .  .  .  .  .  .
```

## 2. Pieces

Every piece is a 1-cell-thick rectangle defined by four values:

| Field | Range | Meaning |
|---|---|---|
| `x` | 0..5 | column of the top-left cell |
| `y` | 0..5 | row of the top-left cell |
| `len` | 2 or 3 | length in cells |
| `dir` | 0 / 1 | 0 = horizontal, 1 = vertical |

Rules:

- **Axis lock.** A horizontal piece only moves left/right. A vertical piece only moves up/down.
  Pieces never rotate.
- **One cell per move.** A move shifts a piece by exactly one cell. Longer slides are just
  several moves — and on this board, several moves out of a very short budget.
- **No jumping.** The single cell the piece is advancing into must be inside the board and empty.
- **All moves are reversible.** No state can be permanently lost, so a level can never be
  soft-locked — only overspent.

### The main piece

- Always **horizontal, `len = 2`, on row 2** — the exit row.
- It is the only piece that may leave the board, and only through the gap. The exit check is
  guarded on the piece index, so a horizontal piece that happened to sit flush against the
  right wall on another row cannot sneak out.
- Drawn red with a **white outline**, which no other piece ever has. At a 16px cell the red body
  alone is not enough to separate it from the pink and peach pieces.

### Piece count

Every level uses **exactly 12 pieces** including the main one — a mix of 2s and 3s covering 25 to
28 of the 36 cells. That is the density where a 6x6 board still has legal moves but almost every
one of them is forced, and it keeps the state space small enough that the solver can prove par by
walking it exhaustively.

## 3. Exit rule

The main piece exits when it is flush against the right wall (`x + len == 6`) and the player
presses right once more.

- That final press triggers the win; it does **not** count as a move.
- Consequence: par is measured as "moves needed to park the main piece flush right".

## 4. The move budget

- The HUD is one line and one number: `moves n/par`. It turns yellow with 3 left and red at 0,
  and green on the level-clear panel, where hitting par exactly is the win rather than the edge
  of failure.
- The move that takes `moves` past `par` does not get rejected — it lands, and *then* the board
  detonates: white-out, pieces thrown off the screen with gravity, sparks, screen shake, and a
  falling minor sting. Then a panel: par, what you spent, and the button to retry.
- Detonating is the only failure state. Nothing is lost but the level's progress.

Rationale: showing par and letting the player go over it made par decorative. Making par the
budget turns every move into a decision, which is the whole appeal of the genre. It also removes
"best moves" as a stat — every completion is exactly par, so the cart records a solved flag
instead of a score.

## 5. Controls

Two modes, one button to toggle between them.

**Cursor mode (default)**
- D-pad: moves a 1-cell cursor freely around the board, clamped to `0..5`.
- X: grab the piece under the cursor. On an empty cell, play the "denied" sound and do nothing.

**Grab mode**
- D-pad: attempts to move the held piece. Presses along the wrong axis are rejected with the
  denied sound and cost nothing.
- The cursor travels with the piece, so releasing leaves the cursor sitting on it.
- X: drop the piece and return to cursor mode.

**O is not a game button.** During play it does nothing on a tap; **held for 30 frames it restarts
the level**, with a gauge filling along the footer so the player can see it coming and let go. It
latches on fire, so one long press resets once however long it is held. On a cart where a single
wasted move ends the run, restarting is the verb a player reaches for most, and burying it in the
pause menu put it two menus away from the mistake that caused it. Keeping grab and drop on X
alone also means no press can ever be ambiguous.

Pause menu still holds **reset level** and **skip level**.

Rationale: spatial selection beats cycling through a list. With 12 pieces a cycling selector
would force the player to hunt; a free cursor lets them point at what they are already looking at.

## 6. Screens

- **Title.** Big double-size wordmark, the rule stated up front ("one wasted move and the whole
  board blows up"), a menu, and the solved count. Plain black behind it — party balloons drifted
  up the title at one point and were cut; the screen states a threat, and bobbing balloons argued
  with it.

  The menu is built fresh on every arrival at the title, because its entries depend on what is
  saved: **continue lv N** and **erase progress** only appear once there is something to continue
  or erase, so a first run shows nothing but **start**. Up/down move a blinking `>` marker,
  X or O activate.

- **Erase progress.** A modal over the title: how many solved levels and unlocked levels are about
  to go, then X to erase and O to keep. Erasing zeroes all 12 solved flags and the unlock point,
  then rebuilds the menu — which drops back to a single **start** entry, so the result of the
  action is visible immediately.

  It is behind a confirm because it is the one thing in the cart a player cannot undo, and the
  title screen is where a stray press is most likely — it is the screen people mash through.
  X-confirms / O-cancels matches the rest of the game, where X is always the affirmative.
- **Level clear.** Always "perfect", because there is no other way to finish.
- **Detonation.** See section 4.
- **All clear.** After level 12, with party balloons rising behind it. Its text lines are drawn
  on an opaque black cell (the P8SCII background escape) so a balloon passing behind a line can
  never eat a letter — the `b` argument to `ctr`/`gp` that the title no longer needs.

## 7. Progression and saves

`cartdata("gridlock_rjf_4")`:

| Slot | Contents |
|---|---|
| 0-11 | 1 if that level has been solved, else 0 |
| 63 | highest level unlocked, used by "continue" |

**Erase progress** on the title menu zeroes every one of those slots (section 6).

The id is bumped on every change to the level set. `_1` stored per-level best move counts, which
this version has no use for; `_2` and `_3` held level sets this one replaces. Reusing an id would
leave a returning player unlocked past the end of a shorter game and credited with levels that no
longer exist.

## 8. Level format

Each level is a single string: **4 characters per piece**, concatenated, no separators. The
**first piece is always the main piece**.

`x` `y` `len` `dir`, every one of them a single decimal digit — `x` and `y` are `0..5`, `len` is
2 or 3, `dir` is 0 or 1.

Worked example — the first eight characters of a level:

```
0220  ->  x=0, y=2, len=2, dir=horizontal   (the main piece)
1420  ->  x=1, y=4, len=2, dir=horizontal
4221  ->  x=4, y=2, len=2, dir=vertical
```

Parsing walks the string in steps of four, one `tonum` per field. The 12x12 version needed a
base-12 character table here; a 6x6 board fits in plain digits and the table is gone.

### Verified level set

12 levels, par 15 to 25, 245 optimal moves end to end — one level per par from 15 to 24, then two
at 25 so the finale is a second hardest rather than a step down:

| Par | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Levels | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 |

Every board carries 12 pieces, so all of them are close to full. The levels are chosen so the
*solution* reaches into the corners too, not just the lane: 6 to 11 distinct pieces move in the
optimal path, across 5 or more of the nine 2x2 zones.

**Difficulty climbs every single level.** Par never goes backwards, and the fuller difficulty
number `pick-levels.js` ranks on — par, plus the obligations the opening forces on you and the
spread of the answer across the board — is strictly higher for each level than for the one
before. That ranking exists because par alone is easy to inflate: a board can pad its par with an
empty run-up for the main piece and still be three shoves and a drive-out.

**No two levels look alike.** With only twelve of them there is no room for two boards a player
would mistake for each other, so at pick time distinctness outranks raw difficulty: for each rung
of the par ramp `pick-levels.js` takes the candidate whose 36-cell occupancy mask is *least* like
every board already chosen, and only breaks ties on the difficulty score. The shipped set's
closest pair differs in 13 of the 36 cells. The generator dedupes first on its own — mulberry32
for exact 32-bit random state, rejection of any repeated encoded string, and a 6-cell minimum
difference against every board already in the pool.

Par is a hard budget, so it has to be exactly right — a par one too low makes a level
unwinnable. Every level is checked twice (section 11).

### Authoring constraints

The generator enforces these before a candidate is even solved:

1. Main piece starts on row 2, `x` in `0..2`.
2. No other **horizontal** piece sits on row 2. Keeping the exit row free of same-axis traffic
   makes the blocking relationships legible — the player sees vertical bars to shove aside, not
   a train to shunt. It also removes any chance of a second piece reaching the gap.
3. Placement is uniform over the whole 6x6 board, and `len = 3` pieces are drawn one time in
   four. Three-cell pieces lock a 6x6 board solid if there are too many of them: half the row
   they sit in is gone, and the board stops having legal moves at all.

And these once it has been solved, on the board and on its optimal path:

4. At least 2 pieces sit in the lane at the start, so the opening already obliges you to move
   specific pieces however you play, and at least 2 more sit in *those* pieces' escape routes.
   This second tier is what makes a board a knot rather than a queue of one-way shoves.
5. The answer moves at least 5 distinct pieces, spread across at least 5 of the nine 2x2 zones.
6. The answer returns at least twice to a piece it has already moved. A solution you can walk
   straight down, moving each blocker once and never coming back, is the thing that reads as
   "just push the pieces out of the way".
7. Par lands in 15..25. Below that the level is over before the knot is felt; above it the run of
   perfect moves the budget demands stops being something a player can hold in their head.

### Why breadth-first search, not A*

A 12x12 board could not afford a blind walk: a dozen-plus pieces wiggling independently on 144
cells push the reachable component past 10^5 states long before the search reaches depth 15, so
that version used A* with the standard Rush Hour heuristic. At 6x6 with 12 pieces the component
is small enough to walk exhaustively in milliseconds, and BFS is used instead. That matters more
than speed: par is a hard move budget, and a par one too low ships an unwinnable level, so the
solver that sets it should be the one with nothing to get wrong. BFS has no heuristic that could
turn out to be inadmissible.

A move is **one cell**, not "slide a piece as far as it goes" — that is what the cart charges the
player for, so it has to be what the solver counts. It makes these pars roughly twice the
piece-move numbers a Rush Hour puzzle would quote.

Two things carry over from the A* version:

- **A state is one byte per piece** — the single coordinate that piece can change. The rest of
  the board is fixed, so that is all the visited map has to remember.
- **No parent pointers.** The distance map alone reconstructs the path, by walking back from the
  goal to any neighbour one step closer to the start. The walk tries the blockers before the main
  piece, so the path it returns is the interleaved solution a player would find rather than
  "clear everything, then drive out" — which matters, because the metrics above are read off it.

Boards whose component runs past 400k states are written off rather than solved slowly; at this
density that is rare, and the climb has plenty of other places to go.

### Why the boards are climbed, not rolled

Rolling a whole board at random and hoping for a long par does not work: at 12 pieces on 36 cells
most random boards are either already solved or completely dead, and the ones in between land far
short of par 15. Par comes from *interlock*, not from crowding — density on its own just removes
legal moves.

So a board is **climbed** instead. Mutate one piece — relocate or reshape it, or shift the main
piece's start — re-solve, and keep the mutation when the difficulty score goes up. The piece count
never changes, so every board the climb passes through still ships 12 pieces. A sideways step is taken too, so the climb can cross a plateau, but it counts against the
patience counter that triggers a restart. Every solvable board the climb passes through is
offered to the pool, which is where the gentler early levels come from.

Restarts alternate between a fresh random board and re-climbing from one of the best boards the
run has already found. The long pars only ever sit a few mutations away from an already-tangled
board; they never turn up in a fresh roll. Six seeded 200-second runs produce ~1300 candidates
spread across every par from 15 to 25, which is the pool the picker then chooses twelve distinct
boards from.

## 9. Screen layout (128x128)

| Region | Y | Contents |
|---|---|---|
| HUD | 6 | `moves n/par`, centred, and nothing else |
| Board frame | 18-121 | 4px bezel around the play area |
| Play area | 22-117 | 6 x 16px cells, origin `x = 12` |
| Footer | 122 | button reminder, or the reset gauge |

Board origin is `(12, 22)`, cell size **16px**. The board is still the same 96x96 pixels it has
always been — six cells at 16px instead of twelve at 8 — so the frame, exit gap and arrow keep
their proportions and only the contents got bigger. It sits 2px lower than the 12x12 version did,
because the HUD collapsed from two lines to one and the footer needed the room back.

The HUD carries a single number. `lv n/12` and `solved n/12` were on it and are gone: the level
number is on the clear panel and the solved count is on the title, and neither is a thing you act
on mid-puzzle. The budget is, and on its own it is unmissable.

Piece rendering per cell block: a dark outline, the body fill, a lighter top edge, a darker bottom
one, and the four corner pixels knocked back to the board colour so the slab reads as rounded.
There is a 2px gap to the next piece. At 8px none of that fitted — the 12x12 version had the top
edge alone, and a drop shadow before that which filled the gaps and turned the board to mush.
16px cells are where the shading finally pays for itself: without the lit top and shaded bottom, a
row of same-coloured blocks reads as one flat wall. The held piece gets a blinking bright outline
(inverted for the main piece, which is already outlined white); the cursor is four corner brackets
rather than a full box, so it never hides the piece underneath.

## 10. Audio

Slots 0-7 are gameplay, slots 8-17 are music. **Music owns channels 0-2 and channel 3 is left
unused in every pattern**, and every gameplay `sfx()` call names channel 3 explicitly. Without
that, a slide sound steals a voice from the bed and the music stutters on every button press.

| Event | Sound |
|---|---|
| Piece slides | short low noise thunk — the workhorse, quiet enough to hear 25 times in a row |
| Grab / drop | rising and falling two-note blips, mirrored so the mode change is audible; the falling one doubles as the reset confirmation |
| Rejected input | low square buzz; fires for wall, occupant and wrong-axis alike |
| Cursor step | very quiet high tick |
| Exit | five-note rising arpeggio |
| Detonation | hard noise hit tearing downward, then a sagging minor fall |

**The balloon-party bed** (`gen-sfx.js`): C major, 150bpm, sixteenth-note grid, four patterns of
two bars each looping — C/G, Am/F, C/G, F/G — with a drum fill on the last. Bass is a tilted saw
bouncing root/octave with a fifth before each turnaround; melody is a pulse wave sitting on the
offbeats for lift; drums are noise kick/snare/hat.

The exit is also animated: the main piece slides right, off the board and off the screen, before
the results panel appears. The reward for solving the puzzle is watching the thing you have been
shoving around finally get out.

X or O cut that animation short. It runs ~14 frames, and a player reaching for the button to pass
the level hits it inside that window — so without the skip, the first half-second of presses after
every win is swallowed and the game reads as unresponsive at the exact moment it should feel good.
One tap ends the drive-out, the next passes the level.

**Every prompt names both buttons where both work** — the results panel reads "O X next", not
"X next". Anywhere the two buttons are interchangeable the prompt has to say so, or the label
teaches the player a restriction the game does not have. `gp()` takes a glyph count for this,
since a button glyph draws 8px against a character's 4 and centring is done by hand. The
exceptions are the screens where the buttons genuinely differ: the erase confirm's "X erase" /
"O keep", and the footer during play, which reads "X grab" / "O hold=reset".

## 11. Tooling

Everything in the cart's data sections is generated, and everything is verified twice — once
outside PICO-8 against an independent model, once inside PICO-8 against the cart's own code.

| Script | Does |
|---|---|
| `gen-levels.js` | hill-climbs boards, solving each with exact BFS; writes `candidates<seed>.json` (par-bucketed pool). Takes seconds-to-run and a seed |
| `pick-levels.js` | walks the 15..25 par ramp, taking the board least like the ones already picked at each rung; re-solves every pick before writing `levels.json` |
| `set-levels.js` | writes `levels.json` into the `lvs=`/`prs=` lines of `game.p8` |
| `verify-levels.js` | parses the levels back **out of the cart**, re-solves all 12, checks geometry, piece count, par, the par window and that par never drops; writes `solutions.json` |
| `gen-sfx.js` | writes `__sfx__` and `__music__` |
| `check-music.js` | parses those back out as note names — the only way to check tempo and pattern order, since headless `-x` never advances the audio clock |
| `mkharness.js` + `driver.lua` | `_test.p8` = the cart with a test driver appended to `__lua__` |
| `mkshots.js` + `shotgen.lua` | `_shot.p8`; running it dumps one `shot_<name>.p8l` per screen |
| `p8l-to-png.js` | turns those dumps into PNGs to look at |
| `labelgen.p8` | draws the cart label — block-font wordmark over the finale board — and dumps it as hex |
| `label-tool.js` (repo root) | splices that dump into `__label__` and renders a preview PNG |

`game.p8` is the source of truth for the code — there is no `game.lua` and no `#include`, and
`set-levels.js` only rewrites two data lines, so editing the cart in PICO-8 and regenerating
levels do not fight. `_test.p8`, `_shot.p8`, `candidates*.json` and the `shot_*` files are build output.

### What the in-cart harness proves

- Every one of the 12 levels is beatable in exactly par, by replaying `solutions.json` through
  the cart's own `mv()` — not through the solver's model of it. Any drift between the two shows
  up as a rejected move.
- Spending one move past par detonates, at exactly `par + 1`.
- `mv()` accepts exactly the moves the board allows and refuses every off-axis press, checked
  piece by piece and direction by direction, with `at()` as the oracle.
- The cursor reaches all four edges of the 6x6 board.
- **X alone grabs and drops.** A tap of O does neither, in either mode.
- **Holding O restarts the level**, and does it exactly once however long the button stays down:
  the latch is checked by moving a piece again mid-hold and asserting the move survives. Releasing
  clears the gauge.
- The win passes the level on **either** button, at both the drive-out and the results panel.
- The title menu carries the right entries for a fresh save and for one partway in; the selection
  clamps at both ends; **erasing takes two presses**, backing out with O leaves every slot intact,
  and confirming clears all 12 flags plus the unlock point and rebuilds the menu.
- The double-size P8SCII escape really does double the text, checked by measuring the drawn
  width and height.
- Music is handed channels 0-2 and gameplay sfx land on channel 3.

Every one of those assertions was confirmed to fail against a deliberately broken copy of the
cart. The first version of the suite passed against both "axis lock removed" and "collision
removed" — replaying an optimal solution only ever makes *legal* moves, so it never noticed the
rules that reject illegal ones. The legality sweep exists because of that.

## 12. Possible extensions

- **Undo.** Every move is a piece index plus a delta, so a stack of those is a full history. It
  would take the edge off the budget rule without removing it — an undo could refund the move.
  Hold-to-reset is the cheap version of this and covers most of the need.
- **Wall pieces.** Immovable single cells, which sharply increase difficulty per piece added and
  would shrink the state space enough for the solver to prove much higher pars.
- **Two exits.** A second gap on another wall with a second main piece, both of which must escape.
- **Daily puzzle.** The generator is seeded, so a date-derived seed gives everyone the same board.
