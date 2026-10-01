# ROTAMAZE — build notes

Implementation of [rotamaze-design.md](rotamaze-design.md). Everything ships in
[game.p8](game.p8); `tools/` builds and verifies it.

## Art direction: 1-bit dungeon

Black ground, one flat ink per element, greys made by dithering (`fillp`), no
gradients and no shading — 1-bit in structure. Hue is used for exactly two jobs,
both of them informational: **whose wall is this** and **what am I about to
turn**.

**Tile colour is the wall's signature.** Walls live on tiles, not on edges, so a
wall on your tile and a wall on your neighbour's sit one pixel apart and used to
be impossible to tell apart. Every tile now draws its walls in its own colour,
`tc[(col+row)%6+1]` cycling white → dark grey → pink → grey → brown → indigo.
The order is picked so neighbouring tiles never land on similar tones, and the
diagonal banding means no two tiles that touch — in x or y — share an ink. A
2px "thick wall" now reads as two different colours side by side, which is
exactly what it is: two walls, two tiles, two rotations to clear.

| Element | How it is drawn |
|---|---|
| Walls | 1px lines on the inside of the tile edge, in that tile's own colour |
| Floor | black, with a sparse grit pixel on ~18% of tiles in the tile's colour (`gt[]`, hashed from tile + maze index, so a maze always looks the same) |
| Player | a **red** 4x4 block, inset 2px from the tile edge so it never touches a wall, with a yellow pip on the facing side |
| Faced tile | a **yellow** 4x4 rect at the same inset — same size, same gap, so the pair reads as "this token, that tile" — *and* the tile's whole set of walls blinks between its own colour and yellow every 8 frames, which shows the player the exact walls ❎ is about to swing. A full 6x6 outline while a rotation animates |
| Exit | a 6x6 checkerboard field that flips phase every 8 frames. A shimmering *texture* can never be misread as another token on the board, which a ring or a blob can |
| Blocked wall | redrawn 1px inward for 3 frames, so it visibly thickens — you can see *whose* wall stopped you |
| Counter at 0 | inverted (black on a white slab) |
| Board frame, title bands | `fillp(0x5a5a)` stone dither |

Nothing on the board is a sprite: walls, token, marker and exit are all drawn in
code, and the sprite sheet ships empty. `tools/art.js` still holds the pointed
token silhouette — it is the shape the cover art draws.

Captured with `tools/shot.js`: [title](shot_title.png), [board](shot_board.png),
[mid-maze](shot_mid.png), [win](shot_win.png), [stuck](shot_stuck.png), and the
cover art in [label.png](label.png).

## Where the mazes live

The design offered baked seeds or packed layouts (§9.1). This takes **packed
layouts** — safer, and it means the shipped bytes are the exact bytes that were
verified, with no in-cart generator to drift.

64 mazes × 110 bytes = **7040 bytes at 0x1000..0x2b7f**, which is `__gfx__`
lines 64–127 (sprites 128–255) running straight into the map region. Sprites
0–127 and the top half of the sheet are untouched.

```
byte   0..104   210 tiles, one nibble each (even tile = low nibble)
byte   105      start tile index (0..209)
byte   106      exit tile index
byte   107      start facing (0..3)
byte   108      MOV budget
byte   109      ACT budget
```

## One rule the design gets wrong

§5 says "from any tile, the player can rotate all four neighbours for 4 ACT and
0 MOV", and §10.2 drops facing from the solver's state on the strength of it.

**That only holds for neighbours you cannot walk into.** By §5.1, an arrow press
toward an *open* neighbour moves you — so you cannot aim at a tile you could
step into, unless you happen to already be facing it because that was the
direction of your last move. Facing is free to change only toward blocked
directions.

The cart implements §5.1's table exactly, and the offline solver keeps facing in
its search state (`state = tile*4 + facing`, blocked turns are 0-cost edges,
moves cost 1 MOV). Dropping it would have produced budgets no player could hit.

Three smaller calls:

- **Blocked-press feedback always plays**, including when you are already facing
  that way. The table says "nothing happens"; §5.1's feedback section says every
  blocked arrow gets a thud. No *state* changes either way — a dead-feeling
  input is worse than a redundant thud.
- **There is a title screen**, which the design does not mention. It carries the
  controls, and the frame count while it sits there seeds the shuffle — without
  that, a cold boot deals the same first maze every time.
- **The ≥3 near-optimal routes rule (§10.2) is applied per tier**: 3 for
  warm-up/standard, 2 for hard, 1 for brutal. §11 asks brutal mazes to run at
  slack 0, which is a request for a near-unique solution; the two rules cannot
  both hold.

## The pool, and how it was verified

`tools/gen.js` builds candidates (perfect maze → braid in loops → cut the
start/exit route until it is severed → scatter decoy cuts → hand each closed
edge to one tile, the other, or both), then solves each one.

The solver is a beam search over rotation configurations, one layer per ACT
spent, with a 0-1 BFS over `(tile, facing)` inside each layer. It is heuristic
in what it *finds* but never wrong about what it finds: every plan it returns is
replayed through a port of the cart's rules before the maze is accepted, so a
shipped budget is always a budget some real sequence of presses achieves.

Accepted mazes must have no zero-rotation solution, an optimal route of at least
18 tiles, start and exit at least 18 apart, and the tier's route count.

| Tier | Count | ACT optimal | Slack (mov, act) |
|---|---|---|---|
| warm-up | 8 | 1–2 | 3, 2 |
| standard | 32 | 3–6 | 2, 1 |
| hard | 16 | 7–9 | 1, 1 |
| brutal | 8 | 10–12 | 0, 0 |

Shipped budgets: **MOV 18–37, ACT 4–12**.

Four layers of checking, all reproducible:

1. `node tools/gen.js` — every candidate's plan is replayed through a JS port of
   `trymv`/`rot` before it can enter the pool.
2. `node tools/test.js --mutants` — 59 rule assertions run inside the real cart,
   plus a mutation pass that breaks the cart eleven different ways and requires
   every mutant to fail. (A test that quotes the cart's own constants agrees
   with whatever the cart believes, so the assertions spell the numbers out.)
3. `node tools/verify.js` — loads all 64 mazes **in the cart** and plays each
   one to the exit with synthetic input, asserting the win state and the exact
   MOV/ACT left over. Takes ~4 minutes: `-x` still runs at 30fps.
4. `node tools/soak.js 4000` — random input across the whole pool, checking the
   invariants (player on the board, counters non-negative, wall values 0–15,
   history never longer than the budget) on every frame.

## Tools

```bash
node tools/gen.js 5000 tools/mazes.json   # build + solve the pool (~10 min)
node tools/trim.js tools/mazes.json       # drop free turns after the win press
node tools/bake.js                        # sprites + sfx + music + pool -> game.p8
node tools/label.js                       # cover art -> labelgen.p8 -> __label__
node tools/test.js --mutants              # rule tests + mutation pass
node tools/verify.js                      # play all 64 inside the cart
node tools/soak.js 4000                   # random input, invariants every frame
node tools/tokens.js                      # rough token estimate (~1600 of 8192)
node tools/shot.js "<script>" 12:name     # screenshot a frame; maze=N, crop=, exec=
node tools/probe.js 40                    # how the generator knobs map to difficulty
```

`bake.js` rewrites only the asset sections, so the Lua in `game.p8` is the
source of truth for code and is safe to edit by hand or in PICO-8.

Each harness writes its own temp cart (`_rules.p8`, `_test.p8`, `_soak.p8`,
`_shot.p8`) so two of them can run at once without deleting each other's work.

**`printh` output arrives on stderr on this machine**, not stdout as
PICO8-TOOLING.md says — every tool here reads both streams.
