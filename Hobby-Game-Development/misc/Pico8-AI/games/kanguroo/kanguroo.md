# KANGUROO — Design Doc

A Sokoban variant for PICO-8. You are a kangaroo in the Australian desert: you
**jump 2 tiles at a time**, you can't turn without committing to a move, and
water is lethal — for you and for your boxes.

---

## 1. Scenes

State machine with a single `scene` variable: `"intro"` → `"levels"` → `"game"`,
plus `"tut"` hanging off the title as a read-only side page.

| Scene    | Content                                                          | Exit |
|----------|------------------------------------------------------------------|------|
| `intro`  | Title, kangaroo sprite, ❎/🅾️ prompts, ambient music              | ❎ → `levels`, 🅾️ → `tut` |
| `tut`    | One static page: the four rules, each next to the tile it describes | ❎ or 🅾️ → `intro` |
| `levels` | 4x4 grid of 16 level tiles, cursor, cleared/locked state          | ❎ → `game`, 🅾️ → `intro` |
| `game`   | Board only — no HUD, no counters. Pause-menu entry.               | pause menu → `levels` |

Each scene implements `_init_x()`, `_update_x()`, `_draw_x()`; the global
`_update60`/`_draw` dispatch on `scene`.

Run the game at **60fps** (`_update60`) — the jump animations need the extra
frames to read smoothly.

---

## 2. Controls

| Input | Action |
|-------|--------|
| ⬅️ ➡️ ⬆️ ⬇️ | Attempt a jump in that direction. One press = one move (`btnp`, no repeat while animating). |
| 🅾️ (hold 2s) | Restart current level. |
| 🅾️ | Open the how-to-play page (in `intro`); leave it (in `tut`). |
| ❎ | **Undo** the last move (in `game`). Confirm (in `intro` / `levels`). |
| Pause menu | `menuitem(1, "back to levels", ...)` → returns to `levels`. Register on entering `game`, clear with `menuitem(1)` on leaving. |

**No free rotation.** Pressing a direction *always* attempts a move in that
direction. The kangaroo's facing is a result of the move, never an action of its
own — so you can't "look before you leap".

**Restart hold:** count frames while `btn(🅾️)` is held; at 120 frames trigger the
restart. Reset the counter the moment the button is released. Once the counter
passes ~15 frames, draw a small filling ring around the kangaroo so the hold is
discoverable — no HUD element, the feedback lives on the character itself.

---

## 3. Board & rendering

- Logical board: **10 x 10 tiles**.
- Tile size: **12 x 12 pixels** → 120 x 120 px board.
- Centered on the 128 x 128 screen: origin at `(4, 4)`.
- Screen position of tile `(cx, cy)`: `x = 4 + cx*12`, `y = 4 + cy*12`.

### Drawing 12x12 tiles

PICO-8 sprites are 8x8, so 12x12 art doesn't map onto sprite IDs. Lay the tile
art out as a **12x12 grid inside the spritesheet** (10 columns fit across 120 of
the 128 px) and blit with `sspr`:

```lua
function draw_tile(id, x, y)
  sspr(id%10*12, flr(id/10)*12, 12, 12, x, y)
end
```

That gives up to 100 tile graphics. Keep the actor sprites (kangaroo frames) in
the same layout so everything uses one draw path.

### Draw order

1. Sand background + decoration (static, per level)
2. Goal markers
3. Water tiles (animated shimmer, 2 frames)
4. Walls / rocks
5. Boxes (with shadow)
6. Kangaroo (with shadow — shadow stays on the ground during a jump)
7. Particles (dust, splash)

The board is the entire game screen. No level number, no move counter, no
progress text — the 8px margins around the board stay empty sand.

---

## 4. Tiles & entities

Static tile map (`board[y][x]`), plus separate lists for boxes and the player.

| Char | Tile | Blocks jump? | Notes |
|------|------|--------------|-------|
| `.`  | sand (floor) | no | |
| `#`  | rock (wall) | yes | |
| `~`  | water | no | lethal on landing |
| `o`  | goal | no | box target |
| ` `  | outside / border | yes | treated as wall |

Dynamic:

| Char in level data | Meaning |
|--------------------|---------|
| `b` | box on sand |
| `B` | box starting on a goal |
| `p` | player start |

Boxes live in a table: `{x, y, ax, ay, state}` where `ax/ay` are animated pixel
offsets and `state` is `"idle"`, `"sliding"`, or `"sinking"`.

---

## 5. Movement resolution

Given direction `(dx, dy)`, let `t1` be the tile at `+1` and `t2` the tile at
`+2`. Resolve in this order:

```
if t1 is wall/border:
    → BLOCKED. No movement. sfx: blocked.

elseif t1 has a box:
    if t2 is free (not wall/border/box):
        → PUSH. Box moves to t2, player moves to t1 (1-tile hop).
          If t2 is water → box sinks → LOSE.
    else:
        → BLOCKED. sfx: blocked.

elseif t2 is wall/border/box:
    → HOP 1. Player lands on t1.
      If t1 is water → LOSE.

else:
    → JUMP 2. Player arcs over t1 and lands on t2.
      If t2 is water → LOSE.
```

Notes:
- Water never blocks — it's always a legal landing, just a fatal one. This is the
  core of the difficulty: the 2-tile default means you must *plan* which hops get
  shortened by obstacles.
- The kangaroo jumps *over* `t1` on a 2-tile jump, but a box at `t1` is pushed
  rather than jumped over. Keep it that way — it's what makes boxes readable as
  obstacles.
- The player never pushes two boxes at once, and never pushes a box two tiles.

### No move economy

There is **no move limit, no move counter, and no par score**. The difficulty
comes entirely from the three restrictions — the 2-tile default jump, the
inability to turn without committing to a move, and lethal water. Don't add
timers, star ratings, or efficiency scoring; they'd fight the calm tone and
punish the experimentation the puzzles are built around.

### Undo (❎)

Every resolved move pushes a snapshot onto an undo stack **before** applying it:

```lua
add(undo_stack, {
  px = player.x, py = player.y, pf = player.face,
  boxes = copy_box_positions()   -- {x,y} per box, in stable order
})
```

- ❎ pops the last snapshot and restores it instantly (no animation, or a 4-frame
  fade — undo should feel free, not ceremonial). Play the undo sfx.
- Undo is unlimited within a level and ignored while an animation is playing.
- The stack is cleared on level load, on restart, and on death (a lethal move is
  not undoable — water still means starting the level over).
- Snapshots are tiny (2 ints for the player, 2 per box); a 10x10 level with
  ≤6 boxes costs ~14 numbers per move. No cap needed.

---

## 6. Win / lose

**Win:** every box is on a goal tile. On win: freeze input, play the completion
jingle, small celebration (dust puffs + kangaroo hop in place), mark the level
cleared, then return to `levels` after ~90 frames.

**Lose → immediate level restart:**
- Player lands on water.
- A pushed box ends up in water.

Lose is not a game-over screen: play the sink animation, hold ~45 frames, then
reload the current level from its data and clear the undo stack. Nothing is
counted or shown — a failed attempt leaves no trace.

---

## 7. Animation

All animation is driven by a simple `anim` table: `{t, dur, kind, ...}` where `t`
counts up to `dur`. Input is ignored while `anim` is active.

| Kind | Duration | Motion |
|------|----------|--------|
| hop 1 tile | 10 frames | Short parabolic arc, peak ~4px |
| jump 2 tiles | 16 frames | Higher arc, peak ~9px, slight squash on takeoff/landing |
| push box | 12 frames | Player hops 1 tile; box slides linearly, no arc |
| blocked | 6 frames | Player nudges ~2px toward the wall and springs back |
| water sink | 30 frames | Sprite drops 3px, squashes, alpha-flickers out; ripple rings expand |
| level complete | 90 frames | Two small hops in place |

Arc helper:

```lua
function arc(t, dur, h)
  local p = t/dur
  return -sin(p*0.5)*h   -- pico-8 sin: 0..1 = full turn
end
```

Extras that sell the feel: 3–5 dust particles at each landing, a shadow that
scales down as jump height increases, and a 1px vertical squash on the frame of
impact.

---

## 8. SFX

**Two variants per interaction, chosen randomly** (`sfx(base + flr(rnd(2)))`) so
repeated moves don't sound mechanical.

| Interaction | SFX slots |
|-------------|-----------|
| hop 1 tile | 0, 1 |
| jump 2 tiles | 2, 3 |
| push box | 4, 5 |
| blocked / can't jump | 6, 7 |
| landing thud (sand) | 8, 9 |
| player falls in water | 10, 11 |
| box falls in water | 12, 13 |
| level complete | 14, 15 |
| menu cursor move | 16, 17 |
| menu confirm | 18, 19 |
| restart triggered | 20, 21 |
| undo | 22, 23 |

Reserve **sfx 32–47** for music patterns. Keep game sfx short (under ~0.4s) and
low-volume relative to the music — this is a calm game.

Tonal direction: soft wooden/clave-like ticks for hops, a deeper thump for the
2-tile landing, a dry scrape for box pushes, a muted low bonk for blocked, and a
soft `plip` + descending tail for water. Undo is a short reversed-sounding rise —
quiet enough to spam without irritation.

---

## 9. Level data

16 levels, stored as strings of 100 characters (10 rows x 10 columns), one entry
per level:

```lua
levels = {
  -- level 1
  "##########"..
  "#........#"..
  "#..o.....#"..
  "#........#"..
  "#...b....#"..
  "#........#"..
  "#..p..~..#"..
  "#........#"..
  "#........#"..
  "##########",
  -- ...
}
```

Parse once into `board`, `boxes`, `player` on level load. Strings are cheap in
tokens (1 token per level) — this matters, since the 8192-token budget will be
tight with animation and 3 scenes.

### Islands

Water isn't just a hazard — it's the terrain that makes the 2-tile jump
*necessary*. Build levels around **islands**: patches of sand separated by
1-tile water channels that can only be crossed by a clean 2-tile jump.

Island rules that follow from the movement logic:
- A 1-tile-wide water channel is crossable (jump over it, land on the far sand).
- A 2-tile-wide channel is **not** crossable — the landing tile is water.
- A wall or box sitting behind a channel shortens your jump to 1 tile, which
  drops you *into* the water. Obstacles on the far shore are lethal traps, and
  that's the most interesting thing in this game — use it deliberately.
- Boxes can never be pushed across water; they sink. Islands therefore partition
  the puzzle: boxes must already be on the island whose goal they belong to,
  or reach it by a route that hugs land the whole way.

### The 16 levels — one distinct idea each

**The board is ringed with water on every level.** There is no wall at the edge to shorten a
jump against, so overshooting the board drowns you and position has to be won against the
boxes and the terrain. The set is generated from authored terrain by backward BFS — see
NOTES.md — and is ordered by optimal move count, 22 to 112.

Every level should be memorable for a different reason. Don't stack the same
trick twice.

| # | Central idea |
|---|--------------|
| 1 | comb — rock teeth: only a clipped tooth puts you on an even column. 3 boxes, 22 moves. |
| 2 | one gate — one gap in a solid wall, every box threaded through it. 4 boxes, 30 moves. |
| 3 | the bridges — the player leaps the water anywhere, boxes only cross on two bridges. 3 boxes, 36 moves. |
| 4 | chicane — staggered rock pairs reverse which columns you can stop on. 4 boxes, 37 moves. |
| 5 | the long way home — five boxes round a rock block, water biting the corners. 5 boxes, 45 moves. |
| 6 | anvils — four rocks are the only fixed brakes; route against the boxes. 3 boxes, 48 moves. |
| 7 | four lakes — goals on four shores, every box walked the long way. 4 boxes, 48 moves. |
| 8 | parity field — no rocks at all: each box is both cargo and scaffolding. 3 boxes, 55 moves. |
| 9 | switchback — a serpentine with one lane in and no room to turn. 3 boxes, 66 moves. |
| 10 | the channel — two shores, five boxes, two places to change sides. 5 boxes, 69 moves. |
| 11 | stepping stones — scattered single water tiles; the safe stops keep moving. 3 boxes, 69 moves. |
| 12 | the cross — four quadrants, two doorways; empty the wrong one and a box is stranded. 4 boxes, 75 moves. |
| 13 | the slash — a water diagonal that keeps taking away your landing tile. 4 boxes, 77 moves. |
| 14 | far shore — rocks on the far bank shorten the jump that was clearing the lake. 5 boxes, 78 moves. |
| 15 | box train — four goals in a row; filling one blocks the next. 4 boxes, 88 moves. |
| 16 | the pen — a corral with one mouth; the last box in must be the one by the door. 5 boxes, 112 moves. |

Design rules for authoring:
- Because the player can't turn without moving, every level must be solvable
  without "positioning" moves that have nowhere safe to land. Check that from
  every reachable tile, at least one direction is survivable.
- Verify each level has at least one full solution before shipping it — write a
  throwaway BFS solver in a scripting language rather than solving by hand.
- Keep levels visually distinct too: vary the silhouette of the land so the
  level-select grid reads as 16 different places, not 16 rectangles.

---

## 10. Art & music direction

**Mood:** slow, warm, wide-open. Australian desert at late afternoon.

**Palette (PICO-8):**
- Sand: `15` (tan) base with `4` (brown) speckle and `9` (orange) dunes
- Rocks: `4` body, `2` shadow, `9` sun-lit edge
- Water: `12` with `1` depth and `7` highlight (2-frame shimmer)
- Goal: `9` ring, dashed
- Kangaroo: `4` body, `15` belly, `0` eye
- Boxes: `9` crate with `4` slats

Optional: enable the secret palette (`pal(c, c2, 1)`) for dustier ochres if the
default 16 feel too saturated.

**Background detail:** sparse spinifex tufts, a few small rocks, footprint marks
in the sand where the kangaroo has landed (fade after ~3 moves). Keep the play
area readable — decoration lives on the sand tiles only, never on walls or water.

**Music:** slow tempo (~SPD 18–20), pentatonic, sparse. A low sustained drone on
a pulse instrument stands in for a didgeridoo; over it, a few soft plucked notes
with long gaps. Two patterns is plenty:
- Pattern A: intro / level select (a touch brighter)
- Pattern B: in-game loop (drone-heavy, minimal melody)

No music sting on failure — just the water sfx and the reset. Losing should feel
like nothing much happened.

---

## 11. Open questions

- **Should death be undoable?** Right now water always means a restart. Letting
  ❎ step back past a drowning would make experimentation cheaper, but it also
  removes most of the tension from the island levels.
- **Do boxes fill water?** Right now sinking a box loses the level. The
  alternative (box becomes a bridge tile) is a whole different puzzle language.
  Pick one and design all 16 levels around it.
- **Level select gating:** are all 16 unlocked from the start, or does clearing
  level N unlock N+1? Persist with `dset`/`dget` if gated.
