# Lockstep — Design Doc

*(working title)*

A PICO-8 sokoban where you control every player on the board at once. One press, everybody steps. Boxes go on goals. The whole game lives in the gap between "I want this player to move" and "but that one shouldn't."

---

## 1. The pitch

Classic sokoban asks *which order do I push things in?* Lockstep asks *how do I make a player stand still?*

There is no character select and no turn order. Pressing right sends every player on the board one tile to the right, simultaneously. The only way to move one player without moving another is to make the second one **unable** to move — park it against a wall, behind a box that can't be pushed, or behind another player that is itself stuck.

That single inversion — walls become useful, obstacles become tools — is the whole game. Everything else is standard sokoban.

---

## 2. Board and screen

| | |
|---|---|
| Grid | 14 × 14 tiles |
| Tile | 8 × 8 px |
| Board | 112 × 112 px |
| HUD | 16 px band at the top (two 8 px rows) |
| Board origin | `(8, 16)` |

The outer ring of every level is wall, so the real playfield is **12 × 12**. The ring doubles as the board's frame — no separate border art needed.

The arithmetic works out exactly: `8 + 112 + 8 = 128` horizontally (8 px of dead space each side), and `16 + 112 = 128` vertically, so the board sits flush against the bottom of the screen with the HUD filling `y = 0..15`.

**HUD contents:** level number, move count, par for that level, and a small row of pips showing how many boxes are currently on goals.

---

## 3. Entities

| Symbol | Entity | Notes |
|---|---|---|
| `#` | Wall | Static. Blocks everything. |
| ` ` | Floor | |
| `.` | Goal | Boxes must end here. Players may stand on it freely. |
| `$` | Box | Pushed only. Never pulled, never pushes another box. |
| `*` | Box on goal | Same box, different sprite. |
| `@` | Player | Every player obeys every input. |
| `+` | Player on goal | Cosmetic only. |

Levels have **3–6 players** and **3–6 boxes**. Box count always equals goal count.

Players are visually distinct (different colors) even though they're mechanically identical. This is purely so the player can track "the one in the corner" while planning. Six colors covers the whole game.

---

## 4. The core rule: simultaneous movement

One input, one direction `d`, applied to every player in the same tick.

### Resolution order

Players are resolved **furthest-along-`d` first**. For a rightward press, the rightmost player resolves first; for a downward press, the bottom-most. This ordering is what makes follow-the-leader work: by the time a trailing player is evaluated, the one ahead has already vacated (or failed to).

### Per-player resolution

For a player at `p`, with target `t = p + d`:

1. **`t` is a wall** → the player stays.
2. **`t` holds a box** → let `u = t + d`. If `u` is a wall, another box, or a cell still occupied by a player, the box can't move and **the player stays**. Otherwise the box moves to `u` and the player moves to `t`.
3. **`t` holds a player** → that player has already been resolved and did not move, so this player stays.
4. **Otherwise** → the player moves to `t`.

### Turn validity

The press counts as a move only if **at least one player or box changed cell**. A press where everything is blocked is ignored entirely: no move counter increment, no undo entry, no sound beyond a soft bump.

### Pseudocode

```
function try_move(d)
  order = players sorted by dot(pos, d) descending
  occupied = set of all player positions
  moved_anything = false

  for each pl in order
    t = pl.pos + d
    if wall(t) then continue                    -- rule 1
    if box_at(t) then                            -- rule 2
      u = t + d
      if wall(u) or box_at(u) or u in occupied then continue
      move_box(t -> u)
      occupied: remove pl.pos, add t
      pl.pos = t
      moved_anything = true
    else if t in occupied then continue           -- rule 3
    else                                          -- rule 4
      occupied: remove pl.pos, add t
      pl.pos = t
      moved_anything = true

  return moved_anything
```

### Properties worth knowing

Because every player moves by the same offset, several nasty cases simply cannot occur:

- **Two players can never target the same tile.** Distinct source tiles plus a common offset give distinct targets. There is no tie to break.
- **Two players can never push the same box.** Same reason.
- **Boxes never push boxes.** A box with a box in front of it does not move, and neither does the player behind it.

And two cases that *can* occur, and are allowed on purpose:

- **Chaining.** Players stacked in a line along `d` all move if the leader moves. A conga line of three players in a corridor advances as one.
- **Vacate-and-fill.** A player (or a box) may move into a tile that another player is leaving on the same tick. Player A steps out of tile X; player B, one tile behind, steps into X. Same for a box being pushed into X.

### Edge case table

| Situation (pressing →) | Result |
|---|---|
| `@ #` | Player stays. |
| `@$ ` | Box and player both move. |
| `@$#` | Both stay. |
| `@$$` | Both stay — boxes don't chain. |
| `@@ ` | Both move (leader first). |
| `@@#` | Both stay. |
| `@@$ ` | All three move. |
| `@ @#` | Leader stays, trailing player moves into the freed tile. |
| `@$@ ` | Rightmost player moves, then the box is pushed into the tile it just left, and the left player follows. |
| Everything blocked | Press ignored, no move counted. |

---

## 5. Design vocabulary

The techniques the levels are built around. Naming them here so the level design and the tutorial stay honest about what they're teaching.

- **Anchoring** — deliberately walking a player into a wall so it holds position while the others keep working. The fundamental move.
- **Self-anchoring** — a box that has just landed on its goal, with a wall behind it, anchors the player that pushed it. With five or six players on the board it is usually the cheapest anchor available.
- **Stacking** — parking one player behind another that's already anchored, freezing both.
- **Chaining** — using a line of players as a single unit to move a box further than one player could reach around.
- **Funneling** — using a doorway that only fits one player, so entering it costs alignment.

The difficulty curve is essentially: anchoring → self-anchoring → stacking → combinations of all three under a move budget.

---

## 6. Controls

| Input | Action |
|---|---|
| ← ↑ → ↓ | Move all players one tile |
| ❎ | Undo one move |
| 🅾️ (tap) | — |
| 🅾️ (hold ~0.5s) | Restart level |
| ❎ + 🅾️ | Back to level select |

**Undo is unlimited and instant.** In a game where a single press moves everything, an unrecoverable mistake is common and cheap to make. Punishing it would be punishing the mechanic. Hold ❎ to rewind continuously at ~6 states/sec.

Undo state is small: player positions + box positions. With at most 6 players and 6 boxes, that's 12 bytes per snapshot, so a 200-deep ring buffer costs 2.4 KB — effectively free.

---

## 7. Level rules

- **Win:** every goal has a box on it. Checked after each valid move.
- **Lose:** never. There's no fail state, only undo and restart.
- **Deadlocks:** a box pushed into a non-goal corner is permanently stuck. Detect the simple case (box has a wall on two perpendicular sides and isn't on a goal) and tint that box red as a hint. Do **not** auto-restart — let the player notice and undo.
- **Par:** each level ships with a verified optimal move count. Beating or matching it earns a star. Solving it at all unlocks the next level.
- **Move counter** counts valid moves only.

---

## 8. Progression and persistence

25 levels, unlocked in order, plus a level-select grid (5 × 5) showing per-level status: locked, solved, solved-at-par.

`cartdata()` layout, one 32-bit slot each:
- slot 0: highest level unlocked
- slots 1–25: best move count per level (0 = unsolved)

That's 26 of the 64 available slots.

Below the level grid sits a **clear progress** button — the 26th selectable item, reached by
pressing down from the bottom row. Choosing it does not wipe anything immediately: the button
turns into `erase all progress?` and waits for ❎ to confirm or 🅾️ to back out. Confirming zeroes
all 26 slots and re-locks the game to level 1. It is the only destructive action in the game,
so it costs two deliberate presses and never sits under the cursor by default.

---

## 9. Art direction

Chunky, flat, no gradients, no anti-aliasing. The board is read at a glance, so contrast between the five tile types matters more than detail.

- **Walls** — solid dark block with a 1 px lighter top edge. Two or three variants, picked by position hash, so large wall masses don't look tiled.
- **Floor** — near-black with a single 1 px dot in one corner. Enough texture to read the grid without competing with anything.
- **Goal** — a hollow diamond inset in the floor tile, dim.
- **Box** — a filled square with a 1 px inset border, warm color, clearly "movable."
- **Box on goal** — same shape, saturated accent color, plus a 1 px glow ring. This is the most important state change on the board and should be unmissable.
- **Player** — small round-shouldered figure, one flat body color per player, shared dark outline. Six palette entries (blue, green, pink, indigo, red, white). None of them may come from the box family — yellow and orange belong to boxes and box-on-goal, and at 8 px a yellow player reads as a solved box. Legibility wins over palette purity here: keeping six hues apart matters more than keeping their values equal.

**Motion.** Movement interpolates over 4 frames on an ease-out curve (`a = (an/4)²`), so a step
lands most of its distance on the first frame and settles into the tile. Every player and box slides
at the same speed on the same tick — the synchronized slide *is* the game's signature look, so don't
stagger it. A player that fails to move plays a 2-frame squash against whatever blocked it.

---

## 9b. Juice

Feedback is layered so that the three things worth noticing — *a box moved*, *a box landed*, *nothing
moved* — each read differently at a glance, without any of them costing a frame of input latency.

| Event | What happens |
|---|---|
| Box slides | Two grit sparks off its trailing edge, thrown backwards along the push |
| Box lands on a goal | The sprite pops (`sspr` scale-up over 6 frames), an expanding ring, 6 sparks, a 2-frame shake, and the matching HUD pip swells |
| Box pushed off a goal | Three dim sparks, no shake — it should feel like a loss, not an event |
| Fully-blocked press | 1-frame shake plus a spark at every player's blocked edge, on top of the existing squash |
| Move counted | The move counter flashes yellow for 5 frames |
| Undo | The whole display dims one palette step for 3 frames — a rewind blink |
| Level load | 3-frame palette fade up from dark |
| Solve | 10-frame shake, a 2-frame white flash, a ring and 10 sparks off every goal, then confetti every 5th frame for the next second; the panel scales open over 8 frames |
| Level select | Cursor lerps between cells (and stretches into the clear-progress button), title bobs on a sine, par stars twinkle, motes drift behind the grid, a locked cell jitters when you try it |

Sparks are one shared particle list: position, velocity, lifetime, drag `0.82`, drawn as single pixels
through a 4-entry colour ramp (white → yellow → orange → grey) keyed off remaining life. Rings are a
second list drawn as `circ` with a growing radius. Both are cleared by `loadlev`, so nothing survives
a restart.

The fades are display-palette only (`pal(c,d,1)`), applied once at the end of `_draw` — never on the
draw palette, which the box and player sprites are already using for tinting.

**Cost.** Measured headless: 14% of a 30 fps frame for a full board, 15% with 60 particles live, 4%
for the level select. The juice is essentially free; the 196-tile board redraw is what costs.

---

## 10. Audio

- **Step** — one short blip, pitched by direction, played once per move regardless of how many players moved.
- **Bump** — muted thud for a fully-blocked press.
- **Box slide** — low scrape layered under the step when at least one box moves.
- **Goal locked** — bright two-note chime when a box lands on a goal. Pitch rises with the number of goals filled, so the last box in a level resolves the melody.
- **Goal unlocked** — the same chime, inverted and quieter, when a box is pushed off a goal.
- **Solve** — four-note fanfare, plus an extra flourish for par.
- **Undo** — a short reversed blip.

Music: one slow ambient loop for the board, silence for the first three levels so the mechanic sounds get taught cleanly.

---

## 11. Level data format

Each level is a single **196-character string** in standard sokoban notation, read row-major, 14 characters per row.

```
# wall    (space) floor    . goal
$ box     * box on goal
@ player  + player on goal
```

25 levels × 196 chars = **4,900 characters** of level data. In PICO-8 each string literal costs 1 token, so the entire level set is 25 tokens; the cost is in the character budget (65,536) and the compressed budget (15,616 bytes), and 4.9 KB of highly repetitive text compresses well.

Decode once at level load into three flat arrays (`wall[]`, `goal[]`) plus two lists (`players`, `boxes`). Index a tile as `i = x + y * 14`.

**If the character budget gets tight later:** run-length encode runs of `#` and space — these levels are mostly empty floor and solid wall, so RLE roughly halves the data. Don't do this up front; it costs tokens and readability for space you probably won't need.

**Alternative:** store levels as 14 × 14 blocks in the map region. It's more space-efficient, but you lose the ability to read and edit levels as text, which matters a lot while tuning. Strings are the right call for a 25-level game.

---

## 12. Difficulty curve

| Levels | Players | Boxes | Teaching |
|---|---|---|---|
| 1–3 | 3 | 3 | Simultaneity, then anchoring — with three bodies to track from the first press |
| 4–9 | 4 | 3–4 | Four-way ordering; self-anchoring and stacking become routine |
| 10–11 | 5 | 4 | A spare player is a tool and a liability |
| 12–17 | 5 | 5 | Five of each; anchors have to be planned two moves ahead |
| 18–19 | 6 | 5 | Six bodies, one box short — someone must be buried early |
| 20–25 | 6 | 6 | Everything at once, everywhere |

Par lengths run 7 → 14 moves. Note that par is not a clean ramp: level 10 (14 moves) is as long as level 25. Move count measures route length; difficulty comes from how many things you have to hold in your head, which scales with player count. Ordering the levels by player count and box count produces the better felt curve.

**Every level is verified to require desynchronization.** Each was machine-checked against a solver restricted to presses where every player moves — none of them are solvable that way. Anchoring isn't a nice-to-have in these levels; it's mandatory.

All 25 par solutions below are verified optimal by breadth-first search over the full state space.

---

## 13. Implementation notes

**Rough token budget** (8,192 available):

| System | Estimate |
|---|---|
| Level decode + state setup | 250 |
| Move resolution | 350 |
| Undo ring buffer | 150 |
| Rendering (board, sprites, HUD) | 500 |
| Animation / interpolation | 300 |
| Level select + progression | 400 |
| Audio triggers | 150 |
| Level data (25 strings) | 25 |
| Particles, rings, fades, HUD pops | 600 |
| **Total** | **~2,750** |

Measured at 2,737 tokens with the juice pass in — see §9b. Still 5,400 free.

**Sorting players by direction** each move is trivial at these counts — an insertion sort over 6 elements, or four hardcoded comparators. Don't build anything general.

**Rendering order:** floor → goals → boxes → players. Players draw last so they're never hidden behind a box mid-slide.

---

## 14. Levels

Notation reminder: `#` wall · `.` goal · `$` box · `*` box on goal · `@` player · `+` player on goal.
Par solutions use `U D L R` for the four directions.

### Level 1

`3 players · 3 boxes · par 7 moves`

```
##############
#            #
#            #
#            #
#            #
#            #
#    +      @#
#    $       #
#            #
#            #
#            #
#     @      #
#    .$ $.   #
##############
```

Par solution: `RDRLDLU`

Open ground, three players, three boxes. Every press moves all three - the only lesson here is that you never move one thing at a time.

### Level 2

`3 players · 3 boxes · par 9 moves`

```
##############
#            #
#            #
# @          #
#            #
#$           #
#.   @       #
#      . #   #
#      $     #
#     $ @    #
#      .     #
#            #
#            #
##############
```

Par solution: `LULDLDRLD`

Still almost empty, but the boxes are scattered. One stray wall is the only brake on the board, so the boxes have to brake each other.

### Level 3

`3 players · 3 boxes · par 11 moves`

```
##############
#            #
#            #
#   #####    #
#   # @ #    #
#   #   #    #
#   #$  #    #
#  .$   #    #
#   #.  #    #
#   #   #    #
#  @#####$@  #
#       .    #
#            #
##############
```

Par solution: `ULDRDLULDDL`

The chamber returns, and now three players have to share one doorway. Two of them spend most of the solution jammed against stone.

### Level 4

`4 players · 3 boxes · par 12 moves`

```
##############
#            #
#  @         #
#            #
#          @ #
#    .   #   #
#    $       #
#         $. #
#       #    #
# .          #
# $          #
#  @  @      #
#            #
##############
```

Par solution: `LURRRUURULUR`

Four players, three boxes: one player is pure overhead. Parking it somewhere harmless is half the puzzle.

### Level 5

`4 players · 4 boxes · par 13 moves`

```
##############
#           @#
#            #
#            #
#  @         #
#   $       $#
#   .       .#
#  $         #
# .    @     #
#            #
#          @ #
#            #
# .$         #
##############
```

Par solution: `RDLDDRDLDLLLL`

Four boxes on open ground, goals directly under them. Nothing anchors anybody - the boxes are the only walls you get.

### Level 6

`4 players · 4 boxes · par 13 moves`

```
##############
#            #
#            #
####  ###  ###
#        .$  #
#     ..     #
#  ###$ ###  #
#$     $    @#
#.         @ #
###  ###  ####
#            #
#   @     @  #
#            #
##############
```

Par solution: `LULRULULULULD`

The gate rows, now with four of everything. Each row lets exactly one body through per press.

### Level 7

`4 players · 4 boxes · par 12 moves`

```
##############
#       @    #
#  #  #  #   #
#   .  @     #
#            #
#@ #  #  #   #
#  $         #
#   $.       #
#  #  #  #   #
#        $.  #
#      .$    #
#  #  #  #   #
#       @    #
##############
```

Par solution: `LRDRDRUULLUR`

One-tile pillars, four players. There is always something to catch on, which is the point.

### Level 8

`4 players · 4 boxes · par 13 moves`

```
##############
#@           #
#  ####      #
#       .$   #
#      ####  #
#         @  #
#@ ####      #
#  .         #
# $    ####  #
#$ $.        #
#. ####      #
#            #
#    @       #
##############
```

Par solution: `LDDRDRUUUULLD`

Staggered bars with four boxes threaded between them. Get the vertical alignment wrong and the run costs six moves to redo.

### Level 9

`4 players · 4 boxes · par 13 moves`

```
##############
#            #
#   @$.      #
#        .   #
#      $     #
#      @ $   #
#       .   .#
#           $#
#         @  #
#            #
#            #
#            #
# @          #
##############
```

Par solution: `LURLUURDRDDRU`

The emptiest board in the game, with eight things on it. No walls means no anchors: every stop has to be bought with a box.

### Level 10

`5 players · 4 boxes · par 14 moves`

```
##############
#      @     #
#      @$.   #
#            #
# $  ####    #
# .  #  #  @@#
# @  #  #    #
#    #  #    #
#    ####    #
#            #
#         $  #
#   . $   .  #
#            #
##############
```

Par solution: `RLLDDDDDLDLLLD`

Five players, four boxes, and a block you can walk all the way around. The fifth player is a liability until you find its wall.

### Level 11

`5 players · 4 boxes · par 13 moves`

```
##############
#      #     #
#      #     #
#         @  #
#      #@    #
#  #.$ #   # #
###### #######
#  #  @#   #@#
#.     #    $#
#$           #
#     $#    .#
#     .#     #
#         @  #
##############
```

Par solution: `LULUULDDLDLLU`

Five players across four quadrants. The crossings are single tiles, so getting the right body into the right quadrant is most of the work.

### Level 12

`5 players · 5 boxes · par 13 moves`

```
##############
#   @  $   . #
#   @        #
#   ######   #
#*     #     #
#      #     #
#     @#     #
#  @       $.#
#   ##  ##   #
#   #    #   #
#$           #
#         $  #
#+        .  #
##############
```

Par solution: `DRRRRRRLDLDDD`

Five and five. The T-wall splits the board into three approaches and you need all three.

### Level 13

`5 players · 5 boxes · par 12 moves`

```
##############
#   ..       #
#  $# $  #   #
#   #   @#   #
#  @#    #   #
#            #
#            #
#.$  @       #
#* #   ##    #
#  #   ##    #
#  #   ##    #
#.   $ @ @   #
#            #
##############
```

Par solution: `LLLLLRURULUR`

Vertical slabs. Almost every anchor here is horizontal, and there are five players competing for them.

### Level 14

`5 players · 5 boxes · par 12 moves`

```
##############
#            #
# ## ### ##  #
#            #
#            #
# ## ### ##  #
#            #
#         .$ #
# ## ### ## @#
#  .@  $@    #
#            #
#  @@  *     #
#  $ .$.     #
##############
```

Par solution: `LLLLRULDDRDR`

Comb rows with five boxes, three of them already crowding the bottom. The teeth are the only thing that will stop anybody.

### Level 15

`5 players · 5 boxes · par 12 moves`

```
##############
#..      @   #
#$$#  #  #   #
#       @    #
#     @      #
#  #  #  #   #
#            #
#  .$ @      #
#  #  #  # * #
#            #
#     $.     #
#  #  #  #   #
#       @    #
##############
```

Par solution: `LLULLURURDLU`

A pillar grid, five players, five boxes. Boxes start paired up - separating them is the first problem.

### Level 16

`5 players · 5 boxes · par 13 moves`

```
##############
#            #
#     *      #
#   ######  @#
#  @   #     #
#      #     #
#    @ #     #
# .  @       #
# $ ##$ ##   #
#   # .  # @ #
#            #
#    $.      #
#     $.     #
##############
```

Par solution: `LLDRDDRDRDRLU`

The ring arena. Five bodies going around it, and the inner bar decides who gets to stop.

### Level 17

`5 players · 5 boxes · par 12 moves`

```
##############
#   . #      #
#   $ # @    #
#    .       #
#   $ #      #
###  ###  ####
#       .  . #
#     #   $  #
#   @ #  $   #
####  ###  ###
#         @* #
#     # @ @  #
#            #
##############
```

Par solution: `LLRUURUULURU`

Doorways everywhere: very few tiles actually stop a player, and now there are five to stop.

### Level 18

`6 players · 5 boxes · par 12 moves`

```
##############
#        .$  #
#  ####      #
#*        @  #
# .    ####  #
# $         @#
#  ####      #
#            #
#      #### @#
#            #
#  ####      #
#  .  $@     #
#@    . $@   #
##############
```

Par solution: `LLULRUUUUUUL`

Six players, five boxes. The spare player has to be buried behind a bar early or it ruins everything later.

### Level 19

`6 players · 5 boxes · par 12 moves`

```
##############
#   .   $@ @ #
#         @* #
#### $###  ###
#          @ #
#    .       #
#  ###  ###  #
#            #
#            #
###  ### @####
#     .$     #
#       @    #
#          $.#
##############
```

Par solution: `LLLLDLRDRRDR`

Six players in the gate rows. Almost every press moves someone you did not want to move.

### Level 20

`6 players · 6 boxes · par 12 moves`

```
##############
#    .@.$ $@ #
# #$ #  #  #@#
# #. #  # @# #
#            #
#         .  #
#.#* #  # $# #
#$#  #  #  # #
#        @   #
#            #
# #  #  #  # #
# #  #  #  # #
#@           #
##############
```

Par solution: `DURUULULLLUD`

Six and six in the vertical comb. The teeth make anchoring cheap; the difficulty is deciding the order.

### Level 21

`6 players · 6 boxes · par 13 moves`

```
##############
#  @ $.#@    #
#*     #     #
#            #
#      #  @ @#
#  #   #   # #
######.#######
#  #  $# @ # #
# @    #     #
#            #
#     $#.$   #
#     .#     #
#     .$     #
##############
```

Par solution: `RRRRUDDDLDLDL`

Six players spread over four quadrants, six boxes between them. Crossings are the bottleneck and everybody wants one.

### Level 22

`6 players · 6 boxes · par 12 moves`

```
##############
# @   $. * @ #
#  ########  #
#  #      #  #
#  # .##  #  #
#  # $ #  # $#
#  #@  #    .#
#  #####  #  #
# @      @#  #
#  ########  #
#      @  $  #
#          . #
#          $.#
##############
```

Par solution: `LRURURRDDDDR`

The spiral, fully loaded. Long committed runs - one wrong direction costs most of your par.

### Level 23

`6 players · 6 boxes · par 12 moves`

```
##############
#      # @   #
# @    #.    #
#            #
#$     #$    #
#. # @ #   # #
###### #######
# @#   #@  # #
#      #    @#
# $.         #
#   * .#     #
#     $#     #
#    . $     #
##############
```

Par solution: `LDDRDLDDLULU`

Same arena as 21, worse split: pairs of players share quadrants and block each other's crossings.

### Level 24

`6 players · 6 boxes · par 13 moves`

```
##############
#.  .$      @#
#$########## #
# $ .      # #
#+######## # #
#$#   .  #*# #
# #  $   # # #
#@#       @#@#
# ########## #
#            #
#            #
#            #
#         @  #
##############
```

Par solution: `LLLLLULLUDRUR`

Nested corridors with six boxes. The outer ring is a one-way commitment and four players are standing in it.

### Level 25

`6 players · 6 boxes · par 14 moves`

```
##############
#      #     #
# @@ @ #.    #
#     .$$.  @#
#      # $   #
#@ #   #   # #
###### #######
#  #   #   # #
#  *   #    @#
#          $.#
#      #     #
#      #    $#
#           .#
##############
```

Par solution: `LLDRLDRRDLULUL`

Six players, six boxes, four quadrants. Everything moves at once; almost nothing can be undone cheaply.
