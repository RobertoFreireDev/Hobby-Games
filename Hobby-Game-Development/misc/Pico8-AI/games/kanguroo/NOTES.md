# kanguroo — implementation notes

The cart is `games/kanguroo/game.p8` (self-contained: code, sprites, sfx, music, label).
`kanguroo.md` is the design doc; this file records what was decided and how to rebuild.

## The three open questions, answered

| Question | Decision |
|---|---|
| Is death undoable? | **No.** Water always means the level restarts, and the undo stack is cleared. ❎ undoes any number of ordinary moves, but never a drowning — that is what keeps the island levels tense. |
| Do boxes fill water? | **No.** A box pushed into water sinks and the level restarts. All 16 levels are designed around boxes never crossing water. |
| Level-select gating | **Progressive.** Level 1 is open; clearing level N unlocks N+1. Persisted with `cartdata("kanguroo_rf")` / `dset(n-1,1)`. Locked cells show a padlock, cleared ones a green tick. Pause-menu slot 1 belongs to whichever scene is on screen — "reset progress" on the title (`resetsave()` wipes all 16 flags), "back to levels" inside a level, nothing on the level select — so the save can only be wiped from the title screen. |

## Deviations from the doc, and why

- **Rocks are grey (5/6/2), not brown (4/2/9).** The doc's rock palette is the same brown as
  the kangaroo; on a 12px tile the player disappeared into the walls. Grey rock keeps one hue
  per type.
- **Orange (9) never appears in the terrain.** Dune decoration was dropped from the board (it
  is still used on the title screen) so orange reads as exactly one thing during play: a box or
  the goal it belongs on.
- **No drone, and a real melody instead.** The doc asks for a sustained pulse drone standing in
  for a didgeridoo, with "a few soft plucked notes with long gaps" over it. A looping 32-step
  sustained note is one unbroken tone for as long as the cart runs, and on the pulse wave with
  vibrato it reads as constant noise rather than atmosphere. Both voices changed:
  - the bottom voice is two or three plucked triangle notes per pattern with a fade-out
    (`bass()` in `gen.js`, sfx 32 and 35), so the low end breathes and then gets out of the way;
  - with no drone holding the bed together, scattered notes had nothing to hang off, so the top
    voice is now an actual phrase — pentatonic on A, a note every four steps (~0.7s at speed
    20), rising and settling back on the root. Sfx 33/34 carry it on the title and level
    select; 36/37 answer it an octave lower and quieter so it stays under the game sfx.
- **Game sfx are routed to channels 2 and 3** (impacts to 3), leaving 0 and 1 to the music
  bed. With auto-channel `sfx()` the jingle stole the drone's channel.
- **Plain sand tiles are not drawn at all** — `cls(15)` covers them and `dec()` returns 0, so a
  board costs ~45 blits instead of 100. Same for the level-select and title backgrounds.

## Art

- **Only the kangaroo is outlined.** `gen.js` has an `ol(rows,col,bg)` helper that traces a
  1px rim around a sprite's silhouette; it is applied to the six player sprites and nothing
  else. The player is the one thing that has to stay readable on top of sand, rock, water and
  a box, so the rim is what marks "this is you" — spending it on terrain too made the board
  noisy and took that cue away. Terrain and boxes carry their own edge colours instead
  (orange crate frame, grey rock lit top-left with a dark base, two-tone shrub).
- `ol()` throws if a core pixel sits on the tile's border row or column, since the rim would
  be clipped there. That is why the player cores are authored inside x1..x10 / y1..y10.
- **The kangaroo's eye is colour 2, not 0.** As colour 0 it was transparent and showed
  whatever tile was behind the head.
- **Water's edge is stroked in Lua, not in the sheet.** Water is a field: an outline baked
  into the tile would draw a grid through every lake. `dwgame` strokes a dark blue (1) line
  on each side of a water tile only where `bt()` says the neighbour is dry, so a lake gets a
  shoreline and stays open in the middle. `bt()` returns 1 off-board, so board edges rim too.
- Decorative pebbles use the boulder's greys so all scenery reads as one material. Dune
  crests are title-screen only — orange stays reserved for box and goal on the board.

## Level design

The levels are **generated, not hand-placed**. `tools/drafts.js` holds terrain only — rock,
water and goal tiles, one 8x8 interior per level, each built around a single trick. Every
board is then ringed with water by the tooling, so **there is no wall at the edge to bounce a
jump off**: overshooting the board drowns you, and position has to be won against the boxes
and the terrain instead.

`tools/deepen.js` runs a **backward BFS** from every solved state (all boxes on goals, player
anywhere) over the inverse of the movement rules — un-push, un-hop, un-jump. A state's BFS
layer is therefore exactly its optimal solution length, so `tools/bake.js` can pick the
deepest legal start for a terrain and get a level that is solvable by construction and as hard
as that terrain allows. It rejects starts with a box or the player already sitting on a goal,
and terrain whose goals no box can ever be pushed onto.

Nothing is written until three checks pass: the chosen start is replayed down the layers with
the *forward* move rule and must win in exactly its layer count; no tile may have only fatal
exits; and levels under 40 moves are re-solved by an independent forward BFS to confirm the
count really is the optimum. `tools/solve.js` re-runs the replay and the dead-tile check
against the data that actually ships.

| # | trick | boxes | optimal moves |
|---|-------|-------|---------------|
| 1 | comb | 3 | 22 |
| 2 | one gate | 4 | 30 |
| 3 | the bridges | 3 | 36 |
| 4 | chicane | 4 | 37 |
| 5 | the long way home | 5 | 45 |
| 6 | anvils | 3 | 48 |
| 7 | four lakes | 4 | 48 |
| 8 | parity field | 3 | 55 |
| 9 | switchback | 3 | 66 |
| 10 | the channel | 5 | 69 |
| 11 | stepping stones | 3 | 69 |
| 12 | the cross | 4 | 75 |
| 13 | the slash | 4 | 77 |
| 14 | far shore | 5 | 78 |
| 15 | box train | 4 | 88 |
| 16 | the pen | 5 | 112 |

62 boxes and 955 optimal moves across the set, against 26 boxes and 138 moves for the first
pass — that version topped out at 34 moves and eleven of its levels fell in under ten.

## Rebuilding

```bash
cd tools
node --max-old-space-size=7000 bake.js   # drafts.js terrain -> levels.js (~30s)
node solve.js       # verify the shipped levels: replay + dead-tile check
node inject.js      # levels.js -> the level table in ../game.p8, nothing else
node gen.js         # __gfx__, __sfx__, __music__ + level table -> ../game.p8, plus preview.png
node tokens.js      # rough token estimate (~2530 of 8192)
node mkharness.js   # ../_kt.p8 = game.p8 + driver.lua
cd .. && "/c/Program Files (x86)/PICO-8/pico8.exe" -x _kt.p8 > tools/run.log 2>&1
cd tools && node shots.js run.log    # ok/FAIL lines + shot_*.png of every scene
node label.js intro                  # title screen -> __label__
```

`_kt.p8` is build output — delete it after a run. The sprite sheet is a 12x12 grid laid out
10-across (`dt(id,x,y)` blits tile `id` with `sspr`), so the art lives in `gen.js` as ASCII,
not as hand-typed hex.

## What the harness checks

36 assertions, all passing. The driver pins its own fixture boards into lvls[1], [3], [5] and
[7] before the game starts, so its coordinate assertions test the movement rules rather than
whatever the shipped level set currently looks like. It covers: scene transitions, 2-tile jump, wall- and box-shortened hops,
blocked moves (no movement, no undo entry), pushes, undo, win detection and level-clear
persistence, unlock gating, the title screen's progress reset, player drowning, box drowning, level reload after death, the
2-second restart hold, and that the music bed keeps channels 0-1.

Headless `-x` cannot measure `stat(1)` meaningfully and never advances the audio clock, so
frame cost and tempo are unverified — the draw path is kept cheap by construction instead.
Token count is only exact in the PICO-8 editor; `tokens.js` is an estimate.

## Not implemented

Nothing from the design doc except: footprints fade by dropping off a 3-entry list rather
than dimming (the palette has no midtone between sand 15 and mark 4).
