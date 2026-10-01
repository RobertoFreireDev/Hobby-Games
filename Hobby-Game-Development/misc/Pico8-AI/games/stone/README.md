# STONE LOGIC — cart notes

A deduction solitaire on four layers. Twelve fixed boards; on each one the
faces of the buried stones are *forced* by the tally and the laws, and at
least one legal opening throws the board away. Everything lives in `game.p8`
(`__lua__` plus generated `__gfx__` / `__label__` / `__sfx__` / `__music__`).

```
pico8.exe games/stone/game.p8          # play
node games/stone/levelgen.js           # search the ladder -> levels.json  (slow)
node games/stone/levelgen.js 7 11      # re-search just those rungs, merge into levels.json
node games/stone/levelgen.js tut       # re-search just the four lessons
node games/stone/levelgen.js report    # the proof table, read back out of levels.json
node games/stone/mk.js                 # splice code.lua + levels.json into game.p8
node games/stone/gen.js                # regenerate sprites, sfx and music
node games/stone/verify.js             # re-prove every shipped board, from the cart
node games/stone/mktest.js             # build test.p8, smoke.p8, shot.p8
pico8.exe -x games/stone/test.p8       # rule/level proof   (prints ALL LEVELS PASS)
pico8.exe -x games/stone/smoke.p8      # every screen drawn (prints SMOKE OK)
pico8.exe -x games/stone/shot.p8       # dump screens to shot.p8l
node shot2png.js games/stone/shot.p8l games/stone/shot.png
```

`test.p8`, `smoke.p8`, `shot.p8`, `shot.p8l` and the `_g*.p8l` splits are build
output — delete them after a run. `code.lua` is the source of truth for the
`__lua__` section; edit it, not the cart, unless you are working inside the
PICO-8 editor (and then copy back). `levelgen.js` is a random search, so a full
re-run will not reproduce the shipped boards; `levels.json` is the artifact.

## The rules

- **Cells and layers.** A board is a set of *stacks* on a grid of at most 4x4
  cells. A stack **hangs from layer 1 downward**: height 1 fills layer 1 alone,
  height 4 fills layers 1-2-3-4. So layer 1 always carries the whole footprint
  and the deeper layers shrink.
- **The four panels.** Each layer is drawn in its own quadrant — **1 top left,
  2 top right, 3 bottom left, 4 bottom right**. A cell keeps the same position
  in all four, so a stack reads straight across the screen: the stone at layer 2
  is the one directly under the layer-1 stone in the matching spot of the
  next panel.
- **Face up or buried.** A stone is buried while another sits in its cell one
  layer up. Face up it draws **white** with its face in the face's own colour;
  buried it draws **dark grey** with a red **"?"**. Nothing else marks depth —
  the panel a stone is in already says which layer it is on.
- **Reach.** A stone can be taken the moment nothing sits on it. Nothing else:
  no open flank, no edge. Faces match across layers and across panels.
- **Marks.** The cursor visits buried stones too. 🅾️ on one steps its mark
  round the six faces and back to no mark, exactly like a minesweeper flag. A
  mark draws as that face's glyph *on the grey*, so it is never mistaken for a
  stone that is really face up. Uncovering a stone drops its mark.
- **The tally.** The HUD row of faces counts every stone of that face still on
  the table, buried ones included. Visible faces subtracted from the tally give
  the exact multiset of what is buried — half of every deduction.
- **The laws** — one to four per board, all true of the board *as dealt*:
  - `>` **bond** — every X touches a Y
  - `x` **taboo** — no X touches a Y (X and Y may be the same face: no two of
    them stacked or side by side)
  - `-n` **depth** — no X on layer n, `n` now running **1..4**
  "Touch" means one stone rests directly on the other, or the two sit at the
  same layer in cells that share an edge.
- **The deduction.** Tally plus laws leave **exactly one** way to fill the
  buried cells. That is checked, not hoped for: see below. So the board is
  fully knowable before the first move, and the game is choosing an order that
  does not bury a stone you still need.
- **Losing.** The round ends when nothing face up matches. Every stone stays
  where it is and every buried face is turned over on its grey, the laws stay
  on the ribbon, and the stones of any face now stacked on itself get a red
  rim. Then ❎ retry or 🅾️ title.

## How the boards are made (`levelgen.js`)

Boards are generated forwards and filtered hard. A candidate is a connected
blob of cells in a 4x4 grid, a height per cell, and a bag of faces in even
counts. It survives only if all of this holds:

1. **Clearable, and losable.** `winnable` memoises over the vector of stack
   heights, so a position is described entirely by how far down each stack has
   been eaten. At least one opening must win and at least `traps` of them must
   lose.
2. **Forced.** `solutions` counts the fillings of the buried cells that fit the
   tally and the laws, and there must be exactly one. It fills layer by layer,
   which makes the pruning exact: depth and taboo are decided the moment a
   stone is placed, and once layer L is complete every stone on layer L-1 has
   all of its neighbours, so bond can be judged there too.
3. **Every law load-bearing.** The tally *alone* must leave more than one
   filling, and a set that is unique is then reduced greedily — any law that
   can be dropped without the filling going ambiguous is dropped. Depth laws
   about layer 1 are never even offered as candidates: layer 1 is always face
   up, so such a law can never rule a filling out.

The difficulty knobs are the number of buried cells (how much there is to
deduce), the number of stacks (how much there is to order), and how many
openings lose. They do not all rise together — rungs 11 and 12 are the widest
boards with the most ways to throw the game away, and take slightly fewer
buried cells in exchange, because six faces over a dozen buried cells leaves
more fillings than a handful of laws can cut down to one.

`node levelgen.js report` prints the shipped ladder.

## What the cart does

- **Layout** — `deal` centres the board's bounding box in all four panels at
  once, at 11px pitch for a 10px stone, so a 4x4 grid fits a 64x50 quadrant
  with the layer caption above it and the HUD ribbon clear below.
- **Navigation** — directional jump between stones, cost `along + 2.5*|perp|`,
  wrapping when nothing lies that way, springing with a slight overshoot.
  Crossing a panel edge is just a longer jump, so ➡️ from the right of layer 1
  lands in layer 2 and ⬇️ lands in layer 3. **One step per frame**: a diagonal
  on the pad reports two directions at once, and running both walked the cursor
  out and straight back again. While a stone is held the cursor only visits
  stones that can pair with it (`pick`).
- **Buttons** — tap ❎ picks up / puts down, and on a buried stone gives the
  same refusal flash and sound as any impossible pick (but costs no miss); hold
  ❎ peeks at every pair the cursor can reach; tap 🅾️ marks a buried stone, or
  cancels the held one; hold 🅾️ shows the laws in words.
- **One row renderer** (`lrows`) draws a law wherever it appears in full, and
  `lawbar` wherever it appears as glyphs, so the ribbon, the hold-🅾️ panel and
  the `law glyphs` page cannot drift apart.
- **Progression** — a level stays unlocked once cleared (`dget(0)`), so a wall
  can be walked away from and come back to. The title screen's pause menu
  carries **clear progress**, which arms on the first pick and only wipes the
  save on the second.
- **Score** — board size plus a clean-run bonus. Deliberately *not* timed: this
  is a puzzle to sit and think about.
- **Tutorial** — four lessons: match, uncover, a law naming what is buried and
  the mark for writing it down, then the tally. The first two publish no laws,
  because they contain nothing to deduce.

## Cover art

`labelgen.lua` composes the 128x128 `__label__` — title in a 4x5 block font,
then the four panels with layer 1 face up and everything under it a "?".
It is not a cart on its own: it is spliced together with the game's own sprite
sheet so it can draw the real face glyphs.

```
node games/stone/mklabelgen.js                     # labelgen.lua + the sheet -> labelgen.p8
pico8.exe -x games/stone/labelgen.p8 > dump.txt 2>&1
node label-tool.js dump.txt games/stone/game.p8 games/stone/label.png 3
```

`gen.js` rewrites the asset sections but carries `__label__` across untouched,
so regenerating sprites does not cost the cover art.

## Test suite

`verify.js` (node) re-proves every shipped board **by brute force**, sharing no
code with `levelgen.js`: it reads the `lvl`/`lws` tables straight out of
`game.p8`, then enumerates every arrangement of the buried multiset with a full
law check at each one — no pruning, so a mistake in the generator's incremental
checks cannot hide in it. It asserts uniqueness, that the laws are all
load-bearing, that the recorded order clears the board, and that a losing
opening exists.

`test.lua` checks what the *cart* does, in Lua, so a bad splice cannot slip
through:

- nothing floating, an even stone count, even counts per face
- every law exactly true of the dealt board, under the cart's own `touch`
- the recorded order is a legal winning sequence that never lifts a buried stone
- every stone lands inside its own layer panel and clear of the ribbon
- 🅾️ steps a mark through all six faces and back to none, and a reveal drops it
- ❎ on a buried stone refuses without costing a miss
- a diagonal moves the cursor exactly once
- clearing progress takes two picks and only the second writes the save

`smoke.lua` walks every screen and calls the real `_draw` by hand, since
`pico8 -x` never calls it. `shot.lua` dumps those screens to `shot.p8l`.
