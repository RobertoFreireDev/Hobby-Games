# Pattern Hunt — PICO-8 Design Doc

*Describes the shipped cart. Where this doc and `game.p8` disagree, the cart wins.*

## Concept
A minimalist deduction puzzle. The player is shown a grid of single digits.
Hidden inside it are six groups of three touching cells that all follow **one**
secret rule, drawn fresh each round from a pool of three. The player must work
out which rule this board is built on and find every group that follows it.
Reach 100% to win.

There is no undo and no second chance — one wrong submission ends the round.
The board is never labelled: the game does not name the rule, before or after
the player finds it. It doesn't need to, because the generator guarantees that
*every* trio on the board satisfying *any* of the three rules is one of the six
it placed on purpose (see "Generator constraints") — so a correct read is never
punished, and there is nothing left for a label to protect the player from. The
game is meant to be **a little hard**: see "Difficulty".

## Core Loop
1. A grid is generated (see "Grid Generation") and wipes in cell by cell.
2. Player moves a cursor around the grid with ⬅️➡️⬆️⬇️ (see "Controls").
3. Player presses ❎ to add the cursor cell to the current **selection**
   (❎ again on a selected cell removes it). The selection is drawn inverted and
   is **capped at 3 cells** — a 4th press is refused, because every instance in
   the grid is exactly 3 cells (see "Generator constraints").
4. Player presses 🅾️ to **submit** the selection (ignored below 3 cells).
   The engine validates it (see "Submission Validity"): three live cells,
   connected, satisfying **any** of the three rules.
   - Valid → the group is cleared, its digits tween into the score box, the
     score rises.
   - Filler, a disconnected trio, or anything else → **lose**.

   Testing against all three rules rather than against the round's own costs
   nothing and hides nothing: on a generated board only the round's rule can
   ever match, so "matches a rule" and "matches *this* rule" are the same
   predicate.
5. Repeat until either the player loses, or all six groups have been cleared and
   the score reads 100% → **win**.

## Controls
Keyboard/gamepad only — **no mouse, no devkit input**. The cart must play
identically on the BBS and on a handheld.

| Input | Action |
|---|---|
| ⬅️ ➡️ ⬆️ ⬇️ | Move the cursor one cell along that row/column, **skipping over cleared cells**. If nothing live remains in that direction the cursor stays put and makes no sound. No wrap — wrapping breaks row/column scanning, which is how the player actually reads the grid. |
| ❎ | Toggle the cursor cell in/out of the selection. Refused once 3 cells are held — refusal has its own two-note "no" tick (SFX 10), so a capped selection is audible without a message. |
| 🅾️ | Submit the selection. Ignored below 3 cells — the guard against a fatal stray press. |

Off the board the same buttons mean something else: on the intro 🅾️ opens the
tutorial and ❎ skips the trace / starts a round; on the tutorial ⬅️➡️ flip the
page and 🅾️ goes back. See "Intro Screen" and "Tutorial Screen".

Cursor repeat is hand-rolled, not `btnp`'s 15/4 default (too sluggish for
scanning a grid): move immediately on press, then after 8 held frames repeat
every 3 frames, tracked per-direction in `hd`.

**Cleared cells are skipped, not traversed.** An earlier build let the cursor
rest in the holes a solved group left behind, which meant a player scanning a row
kept stopping on nothing. `mv` now steps past them, and `fix()` hops the cursor
to the nearest live cell (Manhattan distance) after a clear so it never ends the
tween standing on a cell it just removed.

## Grid Generation

### Numbers
Every cell holds a **single digit, 0–9**. One glyph per cell keeps the grid tight
and perfectly aligned, and the whole board can be read in a single sweep — the
work is spotting relationships between cells, never decoding a cell.

The cost is a small alphabet: with only ten values, coincidental agreement is
cheap. Difficulty therefore comes from the size of the board and from the
generator having to actively *suppress* accidents, not from the arithmetic being
laborious.

### Adjacency is 8-way
Two cells touch if they are orthogonal **or diagonal** neighbours. `nbc[i]` (a
list) and `nbm[i]` (a lookup) are precomputed once in `_init` for all 110 cells
and are the only place adjacency is defined.

Diagonals matter more than they look: at 4-way a 3-cell group can only be a
straight run or an L, and after two rounds the player is scanning for two
silhouettes. At 8-way the legal shapes include diagonal runs, elbows and tight
clumps, so shape stops being a filter and the arithmetic has to do the work.

### Pattern rules — a property of the triple, not of a pair
Every group in this game is **exactly three cells**, so a rule is a predicate on
three digits, `vok(a, b, c, f)` — order-independent, evaluated on the multiset.

| `f` | Rule | `vok(a,b,c,f)` | Reads as |
|---|---|---|---|
| 1 | `equals` | `min == max` | three of the same digit |
| 2 | `1 delta` | `max - min == 2` **and** all three distinct | three consecutive digits in any order |
| 3 | `same hue` | `a%6 == b%6 == c%6` | three digits drawn in the same colour |

The all-distinct clause is what stops `1,1,3` from passing on the span alone.
`5,5,5` fails `1 delta`; `2,3,4` fails `equals`.

**`f=3` subsumes `f=1`.** Digits are coloured `hue[v%6+1]` (see "Colour as a
pattern channel"), so three identical digits are necessarily three identical
hues. The containment is deliberate and is spent twice: `hit()` only sweeps
families 2 and 3 to suppress accidents of all three, and `inst()` only tests 2
and 3 to accept all three. It also means an `equals` group is technically a legal
`same hue` group — harmless, since a board only ever carries one family's groups.

`1 delta` is disjoint from both: `v, v+1, v+2` land on three consecutive entries
of a six-hue wheel, so a run is never monochrome.

### One family per round
`gen()` picks `tr` at random from `{1, 2, 3}` and seeds **only** that family. The
player's job is to work out which of the three the board is built on, and there
is no lock and no label because there is nothing to lock or label against.

An earlier build put two families on one board — five groups of one, three of the
other — and locked the player to whichever they submitted first, printing its
name in the bottom-left of the HUD. That made a round two games: a one-shot
deduction, then a search *under a label*, where the label existed only to stop
the player forgetting their own inference. One rule per board deletes the lock,
the label and the forgetting problem in a single move, and it makes the decoys
unnecessary: on a one-rule board, anything that looks like a pattern **is** the
pattern, so the board itself can no longer lie about which game is being played.

Three rules is the ceiling. A fourth pushes the opening read back towards a
lottery, and `same hue` is already the outer edge of what stays instantly
nameable. An even earlier pass had eight rules across three families of
*pairwise* relations (`diff k`, `sum s`, `double`), with connected components as
groups: it generated beautifully and played like a raffle.

### Submission Validity — three live cells, connected, matching
`inst()` is the whole of validation, and it takes no arguments:

```lua
function inst()
 if #sel!=3 then return false end
 local a,b,c=sel[1],sel[2],sel[3]
 if g[a]<0 or g[b]<0 or g[c]<0 then
  return false
 end
 local e=0
 if nbm[a][b] then e+=1 end
 if nbm[a][c] then e+=1 end
 if nbm[b][c] then e+=1 end
 if e<2 then return false end
 return vok(g[a],g[b],g[c],2)
  or vok(g[a],g[b],g[c],3)
end
```

1. **Exactly 3 cells**, none of them already cleared.
2. **Connected** — of the three possible pairs, at least two must touch. For
   three cells that is exactly the definition of a connected subgraph: a chain
   (2 edges) or a triangle (3). Three digits scattered across the board fail
   here, as does a pair plus a detached third.
3. **Matches a rule** on all three digits — `1 delta` or `same hue`, the second
   of which also covers `equals`.

Validation no longer needs to know which family the round is running. Because the
filler completes nothing, a triple that satisfies any rule is one the generator
seeded, and every seeded group belongs to `tr`. So a two-clause test on the digits
is exactly as strict as a test against `tr` would be, and it doesn't have to
carry a lock through the round to say so.

**There is no maximality test any more, and none is needed.** The previous design
had to prove a group couldn't be extended, because a loose rule would otherwise
let any handful of agreeing cells count. Here the *generator* carries that burden
instead (see "filler completes nothing" below): if no filler cell can ever
complete a pattern, then every triple that satisfies a family is one the
generator deliberately placed, and "is this a real group?" is answered by
arithmetic alone. Moving the constraint from validation to generation is the
single biggest change in the design — it deleted the rule that punished hardest
(submitting a *correct* group one cell short and losing for it) without loosening
anything the player can exploit.

### Generator constraints
`gen()` makes up to **10 full attempts**; each attempt:

- Picks the round's family `tr` at random from the three.
- Seeds **6 instances** of `tr`, **exactly 3 cells each**. `seed()` tries up to
  30 random start cells, then grows the group by repeatedly attaching a random
  free neighbour, so instances appear as runs, bends, diagonals and clumps, never
  as a stamped shape. Nothing else is seeded — there are no decoys.
- Instances are separated by at least one cell — `fre(i, id)` refuses a cell
  whose 8-neighbourhood already touches a different group — so two groups can
  never fuse, and clearing one can never damage another.
- Digits, then shuffled into the three cells so the group is never in reading
  order:
  - `equals` — one random `v` in 0–9, three times.
  - `1 delta` — `v` in 0–7, giving `v, v+1, v+2`.
  - `same hue` — `v` in 0–3, giving `v, v+6` and a coin-flip repeat of one of
    them. Only hues 0–3 have two digits apiece (`hue[4]`/`hue[5]` are reachable
    only by 4 and 5), and forcing both members in guarantees the trio is **never
    all-equal** — so a `same hue` group always reads as a real colour match,
    never as an `equals` group wearing a different hat.
- **Fills every remaining cell with a digit that completes nothing.** `fill(i)`
  shuffles 0–9 and picks the first value for which `hit(i)` — "does placing this
  create *any* triple of *any* of the three families through this cell?" — is
  false. If no digit works, the cell is filled at random and the attempt is
  marked failed.
- Verifies the finished grid with a full rescan: `#scan(tr)==6`, i.e. `tot==18`,
  or the attempt is thrown away and the grid regenerated.

**The filler suppresses all three families, not just the round's.** That is the
clause that pays for deleting the label. If filler could throw up an accidental
`equals` trio during a `1 delta` round, a player who spotted it would submit a
perfectly reasonable read and lose to a rule they had no way to know was inactive.
Because no filler cell can complete any of the three, every pattern visible on the
board is a scorable one, and an unlabelled board is fair.

Fixed 3-cell instances are the single biggest legibility win in the game: the
player is always scanning for the same size, and the 3-cell selection cap makes
over-selection impossible rather than fatal.

**The `hit`/`fill` invariant is the load-bearing one.** With a ten-value alphabet
and 8-way adjacency a naive random fill throws up accidental `equals`, `1 delta`
and (very often) `same hue` triples constantly. The earlier design fought this
after the fact, by
rescanning and perturbing until the board came clean — up to 30 perturbation
passes an attempt, with each fix able to create a fresh accident next door.
Refusing the bad digit at placement time is both cheaper and total: the board is
correct by construction, and the rescan at the end is a cheap assertion rather
than a search. It only ever runs between rounds, so its cost is invisible.

### How triples are enumerated
`tri(i, f, lo)` returns every 8-connected triple through cell `i` that matches
`f`, in two shapes: `b` and `c` both touching `i`, and `c` hanging off `b` only
(the chain where `i` is an end). `scan(f)` sweeps all 110 cells with `lo=true`,
which keeps only triples where `i` is the lowest-indexed cell, so a grid-wide
sweep counts each group exactly once. `hit(i)` is the same machinery run over
families 2 and 3 with no `lo` filter — two sweeps, not three, because `f=3`
already contains `f=1`.

Counted as silhouettes rather than as placements, those two shapes come to
**20** distinct triples up to translation — 4 straight runs, 4 tight 2x2 blocks
and 12 bends. `mksh()` on the tutorial screen derives that set from the same
definition and draws all of it (see "Tutorial Screen").

### Grid size
Numbers must be reserved space at their **highlighted (cursor) scale**, not their
resting scale — since that's the largest they'll ever be drawn, sizing for it
guarantees nothing ever overlaps. A one-digit number is a 3x5px glyph on a 4px
advance; the cursor cell is drawn with the P8SCII wide+tall escapes `\^w\^t`
(`w2` in the code), which double it to exactly 8x10px — no `sspr` needed, and the
2x factor is exact rather than approximated.

- `min cell_size` = 8 + 1 = **9px**
- available_height = 128 − 5 − 5 = 118 → up to **13 rows**
- available_width = 128 − 2 = 126 → up to **14 cols**

Those are a floor, not a target: packing the screen to 14 x 13 = 182 cells turns
a scan into a search.

**Chosen: 11 cols x 10 rows = 110 cells at an 11px pitch** — a 121 x 110 board
with its origin at `gx,gy = (4, 5)`. Cell `i` (1-based) sits at column
`(i-1)%11`, row `(i-1)\11`.

```
x: 4 .. 124   (11 * 11 = 121)   left margin 4, right margin 3
y: 5 .. 114   (10 * 11 = 110)   3px of air under the top rule at y=1
                                5px of air over the bottom rule at y=120
```

An 11px cell still clears the 8x10 highlighted digit, so nothing overlaps at the
largest scale anything is ever drawn. Within a cell:

| Element | Offset from cell origin | Size |
|---|---|---|
| Resting digit | `+4, +3` | 3x5 |
| Cursor digit (`\^w\^t`) | `+2, +1` | 8x10 |
| Selected swatch | `+2, +1` → `+8, +9` | 7x9 |
| Selected **and** cursor swatch | `+1, +0` → `+9, +10` | 9x11 |
| Cleared marker | `+5, +5` | 1px dot |

The board is deliberately dense: six instances put structure in 18 of the 110
cells — about a sixth — and the rest is filler that is *guaranteed* inert.

The cursor starts at cell **61** (row 5, col 5), near the middle, so the first
scan can go any direction.

### Grid reveal
`rv` counts up 5 cells a frame from 0 and `dgrid` draws only the first `rv`
cells, so the board wipes in over ~22 frames in reading order while SFX 09 sweeps
upward. Input is ignored until it completes — a fraction of a second, but it stops
a held button from moving the cursor before the player has seen the grid.

## Cursor Highlight — visual only, not a hint
The cursor cell, and only the cursor cell, is drawn at 2x. It exists purely so the
player can read a number larger before committing — it never indicates
correctness, and it never highlights neighbours (an implicit neighbour shape would
silently contradict the free-form selection). It is drawn only while `st==1`, so
the win/lose screen shows the final board without a cursor sitting on it.

The player identifies real patterns the way a human solves a "spot the pattern"
puzzle: by scanning the whole grid and noticing which touching cells share a
relationship — not by anything the cursor shows them.

## Visual Style

### Palette
Six hues carry the game: **red 8, orange 9, green 11, blue 12, indigo 13,
pink 14**, on black. Neutrals (white 7, light_gray 6, dark_gray 5) are for chrome
and state, never for numbers.

### Colour as a pattern channel
Each number is coloured by a property of **the number itself**, never by whether
it belongs to a pattern:

```lua
hue={8,9,11,12,13,14}   -- red orange green blue indigo pink
c=hue[v%6+1]
```

Ten digits folded into six hues, so 6–9 reuse the hues of 0–3. Colour used to be
a hint that lied often enough to stay honest. It is now **one of the three
rules**, which changes what it means on screen:

- **`same hue` reads as a flat-coloured trio** — three cells in one colour whose
  digits are not all the same, e.g. red `0 6 0` or green `2 8 8`. This is the
  only rule the eye can resolve without arithmetic, and it is meant to be.
- **`equals` reads as one flat colour too**, and identical digits on top of it.
  Since a flat-colour trio is possible only where the generator put one, an
  `equals` board gives itself up quickly. That is accepted: with three rules in
  the pool, one of them being the fast one is a pacing feature, not a leak.
- **`1 delta` reads as three neighbouring hues** — `v, v+1, v+2` map to three
  consecutive entries of the six-hue wheel (wrapping), so a group draws itself as
  a small local gradient: red-orange-green, indigo-pink-red, in whatever order
  the generator scattered them. A gradient trio is *not* proof — `1,2,8` shows the
  same three hues and is not a run — so `1 delta` boards are the ones where the
  eye finds candidates and arithmetic decides.
- **The absence of colour information is information.** No flat-coloured trio
  anywhere on the board means the round is not `equals` and not `same hue`. That
  is a legitimate deduction, available from a single sweep, and it is the
  replacement for the label the HUD used to print.

**Colour still never marks membership.** Filler and instances are coloured by the
same one-line rule; what changed is that the rule can now *be* the pattern, not
that the drawing knows which cells are special. Do not add a second colour channel
encoding membership — that turns the hunt into a colouring book.

### Cell states
| State | Drawing |
|---|---|
| Resting | The digit in its hue, one 3x5 glyph. |
| Cursor | Same hue, `\^w\^t` at 2x. No underline, no box — scale alone carries it, and adding a second marker would compete with the selected swatch. |
| Selected | Hue `rectfill` swatch with the digit punched out in black 0 (inverted). Reads instantly without spending a colour. |
| Selected **and** cursor | The swatch grows to fill the cell edge-to-edge and the punched-out digit is drawn at 2x. The two states have to stack legibly, since the player is nearly always standing on a cell they just picked. |
| Cleared | Empty, with a 1px dark_gray 5 dot marking where a found group was. |

### Intro Screen
An old retro PC, drawn purely with lines (wireframe, no fill) from a flat table of
**28 segments** (`pc`, four numbers each), animating from 0% to 100% as if
progressively traced on screen — one segment every 3 frames, ~2.8s in total. Each
stroke takes the next hue in the palette cycle, so the machine assembles itself in
colour, then settles to a uniform indigo 13 when complete.

The title sits above it in indigo 13, with `find sets of 3` under it in
light_gray 6 — the one piece of instruction in the cart. It replaces nothing the
player could deduce: the group size is a fixed property of the build, not
something to be discovered, and learning it by having a 4th ❎ press refused
mid-round is a worse first thirty seconds than being told.

**The rule pool is not printed here, and must not be.** A line naming `equals`,
`1 delta` and `same hue` was drafted and cut: it turns the opening read from
"what is going on in this grid?" into "which of these three is it?", which is a
much smaller question and a much duller one. The player is meant to discover the
vocabulary the same way they discover a round's rule — by looking at the board.
`find sets of 3` says the only thing they cannot see for themselves.

The rule pool *is* spelled out one press away, on the tutorial screen below. That
is not a walk-back of the paragraph above: what it protects is the player who
never asks. A line on the intro is read by everyone whether they wanted it or
not; a screen behind 🅾️ is read only by someone who has decided they would
rather be told than deduce it, and that player was going to bounce off the cold
open anyway.

Two prompts sit under the wireframe once the trace finishes: `🅾️ how to play` in
light_gray 6 at y=111, `❎ start` in white 7 at y=119. Both clear the keyboard's
bottom edge at y=106. ❎ during the trace **skips to the finished drawing**; ❎
once `❎ start` is showing begins the round. 🅾️ opens the tutorial at any point,
trace finished or not. The intro is silent — the bed starts with the first round.

### Tutorial Screen
`st=4`, two pages, flipped with ⬅️/➡️ and left with 🅾️ — which returns to the
intro with `it` forced to `sn*3`, so the wireframe comes back finished rather than
re-tracing. `tt` is the screen's own frame counter, reset on entry and on every
page flip so both animations always start from the top. Nothing else in the cart
runs while it is up: no grid exists yet, and `_update`/`_draw` branch on `st==4`
before they reach `uplay`/`dgrid`.

**Page 1 — shapes.** The 20 legal silhouettes, drawn as 3x3 mini-boxes seven to a
row (pitch 16px across, 17px down), each cell a 3px square with a dark_blue 1 dot
marking the empties so a shape reads against its own box and not its neighbour's.
They fill in one every 3 frames (~0.7s for all 20), then a highlight walks the
gallery at one shape every 14 frames: a dark_blue 1 tile behind it, its cells in
white 7 against indigo 13 for the rest, and its family name — `line`, `bend` or
`block` — printed underneath.

`mksh()` generates the table rather than storing it: every pair of neighbours of a
hinge cell (C(8,2) = 28 of them), normalised to the bounding box, deduped on a
9-bit 3x3 mask, then centred in the box. That collapses to **20**: 4 `line` (the
hinge's two neighbours are opposite), 4 `block` (three cells of a 2x2 — the mask
is 2x2), 12 `bend`. It is the same predicate `inst()` validates with, derived the
same way, so the gallery cannot drift from what the game accepts — which is the
whole reason it is computed and not a hand-typed table of coordinates.

**Page 2 — patterns.** The three rules, named and worked: `equals` / three of a
kind (`7 7 7`), `1 delta` / a run in any order (`5 3 4`), `same hue` / three of a
colour (`3 9 9`). Each row is picked up a cell at a time on a 64-frame loop — one
swatch every 10 frames, held, then all three strobing white 7 for the last 20 —
so the animation is the submission the player is about to make. The digits are
drawn with the grid's own swatch geometry, and the driver asserts each trio
against `vok` so an edited example cannot quietly stop being an instance of the
rule it sits next to.

Under them, `0` through `9` in their hues with `colours repeat every 6`. That is
the one thing on either page the board itself does not teach: `same hue` is
invisible until you know the wheel wraps, and `3` and `9` being the same blue
looks like a coincidence until it is stated once.

### HUD Layout
- **Top line:** horizontal indigo 13 line, offset 1px from the top edge.
- **Bottom line:** horizontal indigo 13 line at y=120. The bar just above it
  (y 116–122, cleared to black every frame) is the whole of the game's text UI:
  - **Centered, white 7:** the score percentage. It is the only thing in the bar
    during play — the bottom-left rule name is gone (see "No rule reveal").
  - **On win/lose:** the bar is replaced by a single centered message —
    `solved! ❎ new grid` in green 11, `wrong! ❎ new grid` in red 8. Centering
    budgets `#m*4+4`, because ❎ counts as one character but draws 8px wide.
- On score gain the percentage flashes pink 14 for 4 frames and is drawn `\^w`
  (double width) for 2; on win it holds green 11, on loss red 8.
- **Grid area:** everything between the two lines.

**The end-of-round message lives in the bottom bar, not over the grid.** It was
briefly centered on the board, which is where a banner naturally wants to go — but
on a loss that is exactly the wrong place. The player has just been told they were
wrong and the first thing they want is to look at the grid and work out what they
misread. Covering the middle of the board with the word "wrong!" denies them the
only thing that would teach them anything. The bar is the one place a message can
go without hiding evidence.

### No rule reveal — and none is needed
The HUD used to print the locked family by name in the bottom-left the moment the
first group was submitted. That text is gone, along with `lr` and `fnm()`.

It existed to solve a problem that the two-family board created and that the
one-family board does not have. Under the old rules a round was two games — a
one-shot deduction, then a search *under a lock* — and the second half was not
really search but *memory of an inference*: the player re-deriving "wait, was it
equals or the run?" from cells they had already cleared, with a slip costing them
a round they had genuinely solved. Naming the rule bought that back.

With one rule per board there is no lock to remember and no other family arguing
against it. Every valid trio on the board follows the same rule, so:

- The player cannot be punished for a correct read of a pattern that is "the
  wrong family" — there is no wrong family present.
- The rule is re-derivable at any moment from the cells still on screen, not just
  from the ones already cleared.
- A found group is itself the reveal, in the only form the game needs: the next
  five look like it.

What survives is the sound. SFX 05 still fires on the round's first successful
submission — the moment the rule is proved — because that moment is still the
round's turning point even without a caption on it.

The tutorial screen does not touch any of this. It names the three rules that
*exist*; it never names the one **this board** is built on, and it is not
reachable from a round in progress — 🅾️ during play is the submit key and stays
that way. The deduction the game is made of is which of the three is live right
now, and that answer is still only in the cells.

## Score Tween — digits fly to the score
When a submission is valid the cleared digits don't just vanish. One cell is one
digit, so every cleared cell sends its single glyph flying from the grid to the
score readout at the bottom, and the score counts up as they land.

- **Target:** `(tx, ty) = (62, 115)`, the score percentage's slot on the bottom
  line.
- **Duration:** 26 frames a digit.
- **Stagger:** departures are spaced 5 frames apart (`f=-k*5`, counted up before
  the digit is drawn). Since every digit shares one endpoint, the stagger is what
  guarantees no two occupy the arrival zone at once.
- **Bow direction alternates** by lane parity (`(k%2)*2-1`), so with three digits
  in flight the arcs read as left / right / left rather than as a bundle.
- **Fan-out:** each digit's path bows 9px sideways, perpendicular to the flight,
  so trails separate instead of stacking:

  ```lua
  p=f.f/26                          -- 0..1
  e=1-(1-p)^3                       -- ease-out cubic
  x=f.x+(tx-f.x)*e-sin(p*.5)*9*f.l
  y=f.y+(ty-f.y)*e
  ```

  `sin` is inverted in PICO-8 (screen-space y-down), hence the leading minus so
  the bow arcs outward. It peaks at `p=0.5` and returns to zero on arrival, so
  every path still lands exactly on target.
- **Shrink:** the digit is drawn `\^w\^t` at 2x for the first half of the flight
  and 1x (nudged `+1,+2` to stay centred) for the second, so it arrives the same
  size as the number it joins. A continuous scale isn't available without `sspr`,
  and the single switch at the apex is invisible at this speed.
- **Landing:** each arrival adds 1 to `got`, flashes and pops the percentage, and
  fires SFX 04 a step higher than the last (`fk` indexes the pitch ladder).
- **Nothing else updates while digits are in flight** — `uplay` returns early
  while `#fl > 0`, so input, the idle timer and the win check all wait for the
  arcs to finish.

A group therefore reads as three separate arcs resolving into one rising number,
over roughly 36 frames — and since every group is 3 cells, every clear has the
same rhythm and the same worth.

## Audio

### Music — slow, classical, quietly tense
The bed is a PICO-8 reduction in the manner of **Beethoven's Moonlight Sonata,
1st movement** — slow, arpeggiated, C# minor. Everything is generated by
`gen-audio.js`, which refuses any pitch outside C# minor unless it is written
through an explicit escape hatch.

- **16 bars of 16 slots at SFX speed 32** (0.25s a slot, ~75bpm feel) — two bars
  per music pattern, so **8 patterns make a 64-second loop**.
- Progression: `i - V7 - i - III | VI - III - iv - V7 | i - VI - iv - VII | III -
  VII - iv - V7` (c#m, G#7, E, A, f#m, B). It turns over on an unresolved
  dominant; that one chord is the entire source of tension, nothing else in the
  mix pushes.
- **Channel 0:** octave bass, waveform 0 (triangle), volume 2 — root on the chord
  change, the octave halfway through, a fifth pushing into the next chord every
  other bar.
- **Channel 1:** the arpeggio ostinato, waveform 0, volume 2. Six 16-slot
  right-hand figures, one per bar, never the same figure twice running, several
  containing real rests — an ostinato that sounds on every slot for 64 seconds has
  nowhere for the ear to reset.
- **Channel 2:** sparse melody, waveform 0, volume 3 — four notes a bar on a
  rotating rhythm, all distinct within the bar and confined to the chord's own
  pitch classes.
- **Channel 3:** reserved for SFX. Every `music` call passes mask 7 and every
  `sfx` call names channel 3, so an interaction sound can never steal a musical
  voice.

**Two banks, not a fade.** Patterns **0–7 are the calm bank** (bass + arp, melody
channel unused); patterns **8–15 are the same bars with the melody voice added**.
The melody is the pressure meter:

```lua
-- 900 idle frames (30s) with no successful submission
music(mid(0,stat(24),7)+8,400,7)     -- jump to the tense twin of the current pattern
-- on the next successful clear
music(mid(0,stat(24)-8,7),400,7)     -- back down to the calm twin
```

`stat(24)` is the pattern currently playing, so the switch happens **at the same
point in the progression** with a 400ms crossfade — the harmony never jumps, a
voice just arrives or leaves. `idle` resets on every clear.

The bed also **runs on across rounds**: `newround()` only calls `music(0,0,7)` if
the music has stopped or the tense bank is still up, so a player starting their
fifth grid doesn't hear the loop restart from bar 1 every time.

**No background noise.** Waveform 6 (noise) is banned from every music pattern and
every SFX in this cart — no hiss, no percussion bed, no "texture" layer. The mix
stays clean enough that the interaction sounds sit clearly on top of it.

**Generator-enforced rules** (`gen-audio.js` throws rather than emitting): no
chord or figure repeats into the next bar; no melody note repeats inside a bar; no
two bars share a melody; and no two voices may sound a semitone or major 7th apart
in the same slot, with the tritone allowed only inside G#7 where it is the chord's
own colour.

### SFX — one for every interaction
Every player action makes a sound. Nothing in the game is silent. All are played
as `sfx(n, 3, …)`.

| # | Trigger | Sound |
|---|---|---|
| 00 | Cursor move | Pentatonic ladder **indexed by grid row** (`sfx(0,3,row,1)`), b4 at the top down to c#3 at the bottom — walking the board plays a scale instead of ticking one pitch. Triangle, volume 2. The most-heard sound in the cart by a wide margin. |
| 01 | Select a cell (❎ on) | Rising organ pluck, indexed by selection size. |
| 02 | Deselect a cell (❎ off) | The same ladder falling. |
| 03 | Submit (🅾️) | Short downward phaser glide with slide. The "committed" sound. |
| 04 | Digit lands in score | Bright pulse tick, one per arriving digit, pitch climbing per landing. |
| 05 | Round's first valid group (`got==0`) | Warm rising c#m arpeggio — the round's one moment of relief, and now its only "you have the rule" signal. |
| 06 | Invalid submission / lose | Low descending chromatic dyad, square + vibrato, sinking into the bass. The one place a note is *meant* to leave the key. No crash, no noise. |
| 07 | Win | Ascending flourish lifting C# minor into E major — the relative major, so it resolves the music rather than interrupting it. |
| 08 | *(authored, unused)* | Sparse tick intended for the intro trace; the wireframe currently animates in silence. |
| 09 | Grid reveal | Soft ascending organ sweep as the numbers wipe in. |
| 10 | Selection full (4th ❎) | Two-note "no" tick. It used to share slot 0 with the cursor blip, which made that one pitch even more relentless. |

**Pitch-ladder trick.** SFX 00, 01, 02 and 04 each hold a run of pitches in one
slot and are played a single note at a time with the offset and length arguments:

```lua
sfx(4,3,min(fk,7),1)   -- play note fk only: the k-th digit lands a step higher
```

That gives climbing feedback across a whole selection or a whole tween from one
SFX slot, instead of burning a slot per pitch. Every index is clamped to the
ladder's length.

**Ducking.** The lose sting calls `music(-1,20)` and the win flourish
`music(-1,30)`, so the bed is gone by the time the sting lands.

## Scoring
The denominator is fixed the moment the grid is generated: the total cell count
across every instance **in the finished grid**, `tot = #scan(tr)*3`, never the
seed count. Six groups of three makes it **18** on every board, and `gen()` uses
`tot==18` as its acceptance test — the scoring number and the generator's
correctness check are the same number, so a board that would score wrong is a
board that is never handed to the player.

```
score% = round(got * 100 / tot)      -- got = digits landed, not groups cleared
```

The counter advances digit-by-digit as the tween lands, not in one jump, so a
group reads as three ticks upward. With `tot` fixed at 18, a group is always worth
exactly a sixth of the round — 17%, 33%, 50%, 67%, 83%, 100% — so the bar reads
the same way every time.

`tot` is now set by `gen()` rather than by the first successful submission, which
is what let the first submission stop being a special case in `subm()`.

## Difficulty
The target is "a little hard" — a player should lose their first several rounds
and feel it was their own misread, not the game's fault. The knobs:

| Knob | Setting | Why |
|---|---|---|
| Numbers | single digit, 0–9 | One glyph per cell: the board reads at a glance, so the work is finding structure, not decoding cells. |
| Grid | 11 x 10 = 110 cells | A bigger board offsets the smaller alphabet — coincidence is cheap at ten values, so the hunt needs room. |
| Rule pool | 3 | Few enough that the opening read is a deduction rather than a lottery. A fourth would tip it. |
| Rules per board | 1, chosen at random | Anything on the board that looks like a pattern *is* the pattern. No decoys, no lock, no label. |
| Adjacency | 8-way | Legal shapes are varied enough that silhouette is not a shortcut. |
| Instances | 6, **exactly 3 cells** | Every one must be found for 100%. More instances means more chances to spot the *first* one, which is the hard one. |
| Selection cap | 3 cells | Matches the fixed instance size. Over-selecting is impossible instead of fatal. |
| Filler | completes nothing, in any of the three families | Every triple that satisfies any rule was placed on purpose. No accidental groups, no unscorable ones, and no round-specific traps. |
| Mistakes allowed | 0 | One bad submission ends the round. |
| Feedback before submit | none | The cursor never validates; only 🅾️ resolves. |
| Rule name | never shown | Not before (it's the game) and not after (nothing left to protect). The intro names the group size only. |
| Timer | none | Pressure comes from the melody arriving after 30 idle seconds, not a clock. |

**The three rules are not equally hard, on purpose.** `same hue` and `equals`
both resolve to "a flat-coloured trio" and can be found by sweeping the board
without doing arithmetic; `1 delta` cannot. Since the filler suppresses hue
accidents as well, a flat-coloured trio is always real — so roughly two rounds in
three open fast, and the third is the slow one. The variance is the pacing: a run
of quick boards makes a `1 delta` board land as a change of gear rather than as
more of the same.

### Where the difficulty was moved, not removed
Earlier passes were hard in the wrong places. Variable group sizes (3–5) meant a
player who had correctly identified the rule could still lose by stopping one cell
short; an uncapped selection made a stray ❎ fatal; a maximality test punished
knowing the rule but misjudging the boundary; and an eight-rule pool made the
opening guess close to unguessable. All four punish *execution* or *luck*, and
neither is what this game is about.

Fixed 3-cell groups, a 3-cell selection cap, inert filler and one rule per board
all target the same thing: everything after "I know the rule" should be
mechanical. The difficulty stays concentrated where it belongs — the single
unaided, un-hinted inference of which of the three rules this board is built on.

Dropping the decoys and the lock removed the last two ways to lose while being
right: submitting a genuine pattern that happened to belong to the other family,
and forgetting mid-round which family you had locked. Both punished the player for
reading the board correctly. What is left to lose to is misreading it.

If playtesting shows it's *still* too punishing, loosen in this order: instances
to 5, then allow one mistake per round. Do **not** add a fourth rule, put two
rules back on one board, uncap the selection, or add cursor-side validation —
those are the mechanic. And do not print the round's rule anywhere: with one rule
per board, that *is* the answer, not a restatement of it.

## Win / Lose Conditions
- **Win** (`st=2`): `got` reaches `tot` with no invalid submission along the way.
  Music stops with a 30ms fade, SFX 07 plays, the bar reads `solved! ❎ new grid`.
- **Lose** (`st=3`): any submission that isn't a connected trio of three live
  cells matching one of the three rules — filler, a scattered selection, a trio
  whose digits simply don't relate. Music fades over 20ms, SFX 06 plays, the bar
  reads `wrong! ❎ new grid`.
- ❎ on either screen starts a new round. The grid stays on screen underneath, so a
  losing player can look at the board and work out what they misread.

State lives in one variable: `st` = 0 intro, 1 playing, 2 won, 3 lost, 4 tutorial.

## Verification
The cart is exercised headlessly, not by hand:

```
# from this folder; the tools moved to tools/ when the game was archived, so
# every driver now needs naming explicitly
DRIVER=tools/driver.lua node tools/mkharness.js   # _test.p8 = game.p8 + driver
pico8.exe -x _test.p8            # printh output; the driver shuts itself down
DRIVER=tools/driver.lua node tools/mkharness.js <mutation>   # broken on purpose
```

`driver.lua` fakes `btn`/`btnp` and drives the real `_update`, checking:

- the rule predicate directly, including that `vok(v,v,v,3)` holds for all ten
  digits — the containment `inst()` and `hit()` both rely on;
- the generator's invariants: every cell filled, exactly 6 instances, `tot==18`,
  no two instances touching, every instance size 3;
- **that the round's family is the only rule on the board** — for each of `f=1,2,3`
  every triple `scan(f)` returns must be one of the six groups `scan(tr)` found.
  This is the assertion the missing HUD label rests on, and it is the one the
  `nofill` and `nohue` mutations blow up;
- that all three families actually get generated over the run;
- `inst()`'s acceptance and rejection cases, including a diagonal and an L bend of
  each shape and an unrelated trio;
- that a short selection never commits, that a filler trio loses, that a full
  solve lands on exactly 100%, and that the cursor only ever rests on live cells.

`scan()` is cross-checked against an independent brute-force oracle that sweeps
every 3x3 box, so the two agree by different routes. The suite runs ~810
assertions over 12 iterations, each generating several fresh boards.

`smoke.lua` is a second driver that leaves `_draw` in place and reads the screen
back with `pget`, so the HUD, the reveal and the tween are checked as pixels.

`tut.lua` is a third, for the tutorial screen — `DRIVER=tools/tut.lua node
tools/mkharness.js`, ~174 assertions. It proves the shape table is what the
gallery claims (20 entries, 4 `line` / 4 `block` / 12 `bend`, every entry three
distinct cells inside its 3x3 box, at least two of the three pairs touching, no
two entries the same silhouette), that each worked example on page 2 satisfies
`vok` for its own family and only its own, that 🅾️ and ⬅️➡️ move between intro
and pages, and that leaving the tutorial lands on a *finished* trace. It then
dumps five screens for `png.js`: both pages mid-animation and settled, plus the
intro with its two prompts.

> Under `-x` PICO-8 skips draws, and a `pget` dump lags the state that produced
> it by a frame or three. `tut.lua` therefore *holds* each state across a
> six-frame window before dumping, instead of setting it on a single frame —
> the first pass of this driver labelled three screens with the wrong page.

`mkharness.js` carries a table of **mutations** — each one deliberately breaks a
guarantee the suite claims to check. All ten are caught:

| Mutation | Breaks | Failures |
|---|---|---|
| `nofill` | filler may complete patterns | 2099 |
| `nosep` | seeded groups may touch | 32 |
| `noconn` | scattered cells accepted | 48 |
| `norun` | `1 delta` drops all-distinct | 200 |
| `nodiag` | 4-way adjacency | 36 |
| `nohue` | `same hue` never matches | 448 |
| `onefam` | every board uses family 1 | 1 |
| `nofloor` | a 2-cell selection commits | 12 |
| `noskip` | cursor steps onto a cleared cell | 38 |
| `nofix` | cursor stays on the group it cleared | 12 |

A suite that still passes under a mutation isn't testing that guarantee.
`onefam` catching exactly one failure is correct — the only thing it breaks is
family coverage, and exactly one assertion checks it.

Audio and the intro geometry are generated, not hand-typed: `node gen-audio.js`
rewrites the `__sfx__` and `__music__` sections in place and fails the build on any
theory violation.

## Cart budget
~2880 of 8192 tokens, of which the tutorial screen is ~770. There are no sprites
and no map — the entire game is `__lua__` plus generated audio and the cart
label, drawn with `print`, `line`, `rectfill` and `pset`.
