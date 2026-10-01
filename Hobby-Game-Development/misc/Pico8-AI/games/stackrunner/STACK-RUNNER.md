# Stack Runner

A 16-floor grid puzzle for PICO-8. The whole game lives in `game.p8`.

**You have no free movement.** Every step you take is spent from a stack of movement cards you
pick up off the floor, and whatever you don't spend comes with you to the next floor. Each floor
is a routing problem; the sixteen floors together are one long budget.

---

## Controls

| Input | Action |
|---|---|
| ⬅️ ➡️ ⬆️ ⬇️ | Spend the **top** movement card and travel that far in that direction |
| ❎ | Use the **top** item |
| 🅾️ | Rewind one action — unlimited, back to the start of the floor |
| Pause menu | **back a level** — return to the previous floor and re-solve it differently |
| Pause menu | **restart level** — reset this floor to the stacks you arrived with |

The intro screen starts with ❎.

## Music

One slow loop plays throughout -- title, tutorial, floors and the win screen -- and never
restarts. It is an A-minor progression (Am F Dm E | Am C Dm E) at roughly 34 seconds a lap: a held
bass drone, a soft four-note arpeggio, and a sparse organ lead. It is meant to sit under the
puzzle rather than push it along, since most of your time on a floor is spent thinking.

The music holds channels 0-2. Channel 3 is left free, so sound effects never interrupt it.

## The two stacks

The bottom bar shows both, separated by `|`: **movements** on the left (max 5), **items** on the
right (max 3). Both are **last in, first out** — the card you picked up most recently is the one
you spend next. The blinking outline marks the top of each stack.

Walking over a card picks it up, including cards you merely pass through mid-move. You watch it
happen: your character walks the route one square at a time, facing the way it is going, and each
card leaves the floor and lands in the bar as you step on it. Nothing else on the floor — bombs,
guards, the stair — reacts until the walk has finished. **If a stack is full the card is left on
the floor.** With an empty movement stack you cannot move at all — rewind,
restart, or drop back a floor.

You start the game with two ⬦1 cards.

### Movement cards

| Card | Effect |
|---|---|
| 1 pip | Move 1 square |
| 2 pips | Move 2 squares |
| 3 pips | Move 3 squares |
| » | Move until something stops you |

A card is spent only if you actually leave the cell. A move blocked at step one — by a wall, the
board edge, a closed door, a guard, a live bomb or a crate that cannot be pushed — costs nothing:
the card stays on the stack, nothing else on the floor resolves (no bomb tick, no guard turn), and
you hear a buzz. Once you have moved at least one square the card is gone, even if the rest of the
distance is blocked.

### Items

| Item | Effect |
|---|---|
| Bomb | Lands **one square ahead of you**, in the direction you last moved. It detonates at the end of your *next* movement, destroying crates and guards orthogonally adjacent to it. You are never hurt by it. |
| Switch | Flips every door on the floor: closed becomes open, open becomes closed. |

While a bomb is on top of your item stack, the square it would land on blinks white. A bomb can only
be thrown onto empty floor — not into a wall, a crate, or a guard. Because the bomb lands one
square ahead and damages what is adjacent to *it*, **you destroy things two squares away**, which is
exactly what lets you clear a guard without ever standing beside one.

## The grid

10 × 9 squares of 12 × 12 pixels, at a 4px margin, with a 16px bar along the bottom. Each square
holds at most one thing.

| Glyph | Thing | Behaviour |
|---|---|---|
| `#` | Wall | Solid. Everything outside the board counts as wall. |
| `o` | Crate | Pushes one square per step of your move, but only into **empty floor** — not onto a card, a door, the stair, another crate, or a guard. If it can't move, neither can you. |
| `-` `=` | Door | Closed is solid; open is walkable. Only the switch changes them. |
| `2` | Guard | If you *end a move* orthogonally beside it, you're caught and the floor restarts. Diagonals are safe, and **passing through** its reach mid-move is safe — only where you stop matters. |
| `^` | Stair | Step on it to descend. The stair on floor 16 finishes the game. |

The guard never moves. Everything on a floor is deterministic, so rewind is exact.

### Order of resolution

After a movement finishes — not after each step — the floor settles in this order:

1. An armed bomb detonates.
2. **Stair check.** Reaching the stair wins even if a guard is standing next to it.
3. Guard check. If you are still beside one, the floor restarts.

## Carrying stacks between floors

The moment you arrive on a floor, the stacks you arrived with are saved as that floor's **entry
state**.

- **Restart** puts back exactly those cards, not what you have left.
- **Back a level** returns you to the previous floor with *its* saved entry state, so you can solve
  it a different way and arrive with a different stack.
- Re-clearing a floor overwrites the entry state of the one below it.

That's the whole strategic layer: a floor you cleared cheaply leaves you richer for the one after,
and a floor you cannot finish is usually a sign to go back one and spend differently.

## The floors

Sixteen floors. Each of the first ten introduces exactly one idea; the last six combine them.
Floors are lean by design — about fifteen cards on the board rather than a carpet of them —
because a card only earns its place if a run can sweep it or a turn needs it. Every card on every
floor was checked: if the floor still solves without it, and still leaves with the same stack, the
card is gone.

| Floor | What it is about |
|---|---|
| 1 | a step costs a card, and cards lie on the floor |
| 2 | the last card you pick up is the next one you spend |
| 3 | runs stop at walls, so which shaft you take is the puzzle |
| 4 | crates push into empty floor only — mind which side you push from |
| 5 | two crates, and only one of them has anywhere to go |
| 6 | passing a guard is safe, stopping beside him is not |
| 7 | two guards, three safe squares: card length is survival |
| 8 | one switch, every door, both directions at once |
| 9 | a crate with the stair behind it can only be bombed |
| 10 | the same throw on a guard: the throw range is the kill range |
| 11 | the fork — four items, three pockets, pick what to carry down |
| 12 | two sealed shafts: the door wants a switch, the guard wants a bomb |
| 13 | a crate is a brake; the guard is what happens without one |
| 14 | the switch swings both ways, and a guard holds the exit |
| 15 | bomb the guard, then keep the switch for the last door |
| 16 | crate in, bomb past, switch out — no other order finishes |

**[LEVELS.md](LEVELS.md)** is the full design record: every floor's grid, what it teaches, the
pieces it uses and how many, the verified line, and the specific mistake it is built to punish.

### How they are verified

The rules are ported to a solver — push legality, blast radius, guard adjacency, the
stair-beats-the-guard ordering, LIFO stacks, both stack caps, walk-order pickups and the free
blocked move. Each floor is searched exhaustively from the stack that actually arrives at it, and
the reachable exit stacks are propagated to the next floor, so the carry-over budget is proved
rather than assumed. Every floor clears the design bar of **at least ten possible paths and at
least two winning lines**; every floor that introduces a piece is re-solved with that piece
neutralised and comes back unsolvable; every guard floor has a reachable death.

The resulting **157-press walkthrough is then replayed through the cart itself** under
`pico8.exe -x`, which reaches the win screen with the stack matching the solver at every floor.

One verified line per floor, with `l`/`r`/`u`/`w` for the four directions and `i` for an item:

```
 1 rrrr               5 rrwlwlul           9 wrriwrwlluur      13 wrrw
 2 wwrruul            6 rrwwwluuulw       10 wwwlliwlwrruul    14 rrwllwlllir
 3 rrwwwlllll         7 wwwrrr            11 wwwuurrwwluwiwlrr 15 rrlllwlwwwrrir
 4 rlrwwwllul         8 wwrrirrr          12 rrrliiwlr         16 wwwrllruiriw
```

These are not the shortest or the prettiest routes — they are proof that the floor is
finishable with the stack you are actually holding when you land on it.

## Building the cart

`game.p8` is generated, not hand-edited. The generator lives in the scratch directory (it is build
tooling, not source) and assembles three things into the cart:

- `code.lua` → the `__lua__` section
- `tiles.js` → 32 hand-drawn 12×12 tiles → the `__gfx__` section, packed 10 per row at a 12px
  stride and blitted with `sspr` (`map()` is not used; the board is drawn from a Lua char grid)
- `levels.js` → 16 rooms of 90 characters → the `__map__` section

Colour 14 is set as the transparency key (`palt(0,false) palt(14,true)`) so tiles can use black
outlines.

The whole cart draws from five colours: black, dark grey, light grey and white for the dungeon,
the player and every HUD element, plus **red for the guard and nothing else**. The guard is
solid red and nothing else on the board carries a single red pixel, so red anywhere on screen
means exactly one thing: something there will kill you if you stop next to it.

## How the tiles are drawn

Four house rules hold across all 32 sprites, and every one of them exists to buy readability at
12×12, where you only get 144 pixels to spend.

- **One light, from the top-left.** Lit edge 7 or 6, body 6, shadow 5, void 0 — the dark side is
  always down-and-right, never a ring around the whole shape. (A ring is pillow shading; it reads
  as inflated rather than lit.)
- **No black outlines.** Shapes are bounded by a darkened version of their own fill, and the
  black floor does the separating. A pure-black ring would cost a big share of 144 pixels and
  would be invisible against a black floor anyway.
- **A value budget, not just a palette.** Floor and wall never use white. White is reserved for
  the player, the card pips, the stair's nearest tread and the item highlights — so the things
  you act on are always the brightest things on screen.
- **Clustered pixels, one highlight, regular steps.** Same-tone pixels form clumps rather than
  scatter; each rounded shape gets a single 7 glint (the bomb's is at one pixel, up-left); and
  diagonals step in a fixed rhythm (2-2-1 for the floor crack, 2-1 for the wall crack, 2-2-2 for
  the switch's lever) rather than random run lengths, which the eye picks up on at this size.

Dithering appears in exactly two places — one floor slab and one wall course — as a texture band
a few rows deep. A whole sprite of dither is just noise.

The one technique from the usual pixel-art kit that is *not* used is **hue-shifted shading**
(cool shadows, warm highlights). It needs colours outside the locked 0/5/6/7/8 set; the greyscale
ramp carries the volume instead.

### Floor and wall variety

Both the floor and the wall come in **four variants**, picked per cell:

```lua
local v=(x*3+y*7+x*y+lv)%4
```

The hash is deterministic, so a cell keeps its slab across frames, rewinds and restarts — the
board never shimmers. `lv` is in the mix so the same room shape looks different on a later floor.

- **Floor** (tiles 40–43): plain slab, cracked slab, rubble, gravel dither. All four share one
  corner joint tick, so the flagstone grid still reads; only the interior detail varies. They stay
  very dark on purpose — the floor is the background, and everything you can act on has to out-value it.
- **Wall** (tiles 44–47): **identical brick bond in all four** — same course height, same brick
  size, same mortar lines. Only the wear differs: clean, cracked, chipped, worn rough. Varying the
  block *geometry* between neighbouring cells made the wall look like it was built out of four
  different materials; keeping the bond fixed and varying only the surface is what reads as one
  wall that has aged unevenly.

**Levels live in the map sheet** so they can be edited by hand in PICO-8's map editor. Each level
gets its own 16×16 block — 8 blocks per map row, two rows for the 16 floors — which lines up with
one screen of the editor; only the top-left 10×9 of each block is played, the rest is ignored.
Map tile `0` is floor; every other tile is `47+n`, where `n` indexes the string `mchr` in
`__lua__`:

| tile | 0 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cell | `.` | `#` | `o` | `-` | `=` | `^` | `2` | `a` | `b` | `c` | `d` | `x` | `y` | `p` |

Sprites 48–60 are 8×8 legend icons drawn purely so those tiles are recognisable in the map editor —
the board itself is still drawn from the Lua char grid with `sspr` on the 12×12 tiles, and `map()`
is never called.

`loadlv` **reads** the map with `mget` and copies it into the char grid; the player start `p` is
turned into `px,py` in the grid copy only. Nothing ever writes to map RAM, so restart, rewind and
back-a-level all recover the start position from the map and need no `reload()`.

Sprites 40–47 are the floor and wall variants; the sheet now runs to `__gfx__` line 59.

Current size: roughly 2300 of the 8192 token budget — the exact count is only visible in the
PICO-8 editor. Removing the pushing guard took about 550 bytes of Lua out of the cart.

## How it was verified

A JavaScript mirror of the cart's rules drives the level design, and the cart is then tested
against it. The mirror covers push legality, the blast radius, guard adjacency, the
stair-beats-the-guard ordering, LIFO on both stacks, both stack caps, walk-order pickups and
the free blocked move.

Solvability is not assumed. A breadth-first search explores each floor **completely** from the
stack you actually arrive holding, and the set of reachable exit stacks is propagated to the
next floor, so the carry-over budget is proved rather than hoped for. The chain is verified end
to end from the starting `⬦1 ⬦1 ⬦1`.

Two headless runs via `pico8.exe -x` check the real cart:

1. **Floor load** — boots the cart, loads all sixteen floors out of the map, and asserts each
   has exactly one stair and a player start, reporting the piece counts per floor.
2. **Playthrough** — replays the solver's chained walkthrough by overriding the globals
   `btn`/`btnp` (poking `0x5f4c` does not drive `btnp` on this install). It reaches the win
   screen in **157 presses**, printing the exact contents of both stacks at every floor
   entry — all sixteen match the solver, which is what cross-validates the two rule
   implementations.

Per-floor slack is measured too: for every floor, how many of the stacks that can actually
arrive there are able to clear it. Those numbers are in [LEVELS.md](LEVELS.md), and they are
what keeps the floors from being solvable only by one exact sequence.
