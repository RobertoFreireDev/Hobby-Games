# Snakebox — PICO-8 Implementation Guide

A slow-paced, turn-based puzzle game. The snake only moves when you press a
direction — there is no timer, no auto-advance. The puzzle comes from routing a
growing body across three stacked floors connected by doors. You play on one
floor at a time; the other two sit beside it as minimaps, small enough to read
at a glance and far too small to play on.

---

## 1. Rules

- **Turn-based.** One button press = one tile of movement. Nothing happens
  between presses.
- **Grid.** 6 x 6 tiles. Each snake piece (head and body) is **16 x 16 px**.
- **Floors.** Three floors: A, B, C. Each is its own 6 x 6 grid.
- **View.** The board always shows the floor the **head** is on. There is no
  view control and nothing to press: the other two floors are on screen at the
  same time as **24 x 24 px minimaps** down the right-hand side, one 4 px block
  per tile (§2). There is no movement lock either — it existed to stop a
  player pressing a direction while scouting elsewhere, and there is no longer
  a state in which the player is looking somewhere they cannot move.
- **Doors.** Each floor has 2 doors. Stepping onto a door moves the head to the
  linked door on the destination floor — **unless a segment is standing in
  that doorway**, in which case the passage is shut and the press is refused
  like a bite. Any part of the snake counts, tail included. This is the one
  place the body can block a tile the head never actually lands on, and
  nothing else catches it: the head never comes to rest on the door it leaves
  through, so the only cell the collision test ever sees is the far end of the
  passage. See §7.3 — it costs you the ability to reach a floor whose doors
  you have both plugged, and that is the intended price.
- **The body can span floors.** Segments each remember their own floor and stay
  where they were laid down. Only segments on the head's floor are drawn at
  full size; the rest are blocks on the two minimaps.
- **Walls block.** Moving into an edge does nothing — the move is simply not
  taken. It is not a loss.
- **No reverse gear.** A press that would land the head on its **neck**
  (`snake[2]`) is refused the same way an edge is — no move, no death. Without
  this the rule only appears to hold: at length 3 or more the neck is a body
  segment and stepping onto it is a bite, but at **length 2 the neck is also the
  tail**, so it vacates on the same turn and the snake walks backwards through
  itself. The test is on the tile the head would *land* on, after any door
  transit, so a transit that happens to drop you on your own neck is refused
  too, while an ordinary move after a transit is not (the neck is on the floor
  you came from).
- **Blocks.** Each floor has **1 or 2** solid wall tiles in its interior,
  randomised per game. They block movement exactly like an edge does, and they
  are not part of the fill target. Two placement rules keep them from making
  pockets (§7.6): neither ever sits on one of the four tiles **diagonally
  inside a board corner**, and where there are two they keep **a clear tile
  between them** (Chebyshev >= 2), so they never fuse into a 2-tile bar or an
  L that a floor has to be threaded around.
- **No self-bite while there is another way to go.** A press that would land
  the head on a body segment is **refused**, not fatal, exactly like a wall —
  but it gets its own sound (`sfx_deny`, §8.9) so the player hears that the
  press was received and deliberately dropped, rather than missed. This is a
  puzzle with no clock: a misfired direction on a board you are studying is a
  slip, not a decision, and there is nothing to be gained by ending the run for
  it. The neck keeps the plain bump — it is refused by `dest()` as terrain, and
  it is the most-repeated failed press in the game, so it gets the quietest
  sound (§8.9).
- **Death has one form the player can reach: the dead end.** Every direction
  out of the head is an edge, a block, the neck or a segment, so there is no
  move left that isn't a bite. The game calls this the moment it becomes true,
  instead of making the player prove it by walking into a wall four times. One
  of the four directions is always the neck and `dest()` already refuses it, so
  what this really tests is that all **3 real exits** are shut — at every
  length, including 2.
  - The bite death still exists in the code, guarded by `trapped()`, and it is
    unreachable: the dead end is tested after every move and at the start
    re-roll, so a turn never begins with every exit shut. That is the point of
    keeping it. Refusing a bite unconditionally would turn any future hole in
    `trapped()` into a **soft lock** — a board where every press is denied and
    the game never ends. With the guard, such a hole is still an honest death.
- **Goal: fill every non-wall, non-door tile of all three floors with snake
  parts** — 96 to 99 tiles depending on the wall roll, head plus body. Doors are
  transit, not floor space: no food spawns on one, and a segment resting on one
  counts toward nothing. See §7; this is the constraint that shapes everything
  else.
- **Score** is food eaten, shown in the bottom bar alongside fill progress.
- **The best score persists.** The highest score ever reached on this machine
  is saved to cart data and shown on the right of the score line, in every
  state — so the number the player is chasing is on screen while they play and
  still on screen under the game-over panel. It is written the moment it is
  beaten, not on death: see §4's saved state.

---

## 2. Screen layout

PICO-8 is 128 x 128. The board is 6 x 16 = **96 x 96 px** and it does **not**
centre horizontally: it sits against the left margin, and the strip on the
right holds the two minimaps.

```
x:  0 2                    97 100    125 127
y:  0 +--------------------------------------+
    4 | +---------------------+       b      |   board:      (2,4)-(97,99)
      | |                     |    +------+  |   minimap 1: (101,20)-(124,43)
      | |     6x6 board       |    |      |  |
      | |     96 x 96 px      |    +------+  |
      | |                     |       c      |
      | |                     |    +------+  |   minimap 2: (101,68)-(124,91)
   99 | +---------------------+    |      |  |
  103 |                            +------+  |
  104 |  BOTTOM BAR  (128 x 24)              |   score+best / floor+fill
  127 +--------------------------------------+
```

```lua
tile   = 16
cols   = 6
rows   = 6
bar_h  = 24                            -- two text rows + 5 px above and below
bar_y  = 128 - bar_h                   -- 104
marg   = 2                             -- screen margin, and the board/column gutter
ox, oy = marg, (bar_y - rows*tile) \2   -- 2, 4
mm_x, mm_y      = 101, 20              -- first block of the first minimap
mm_tile, mm_gap = 4, 48                -- 4 px a tile, 48 px between the two
bcx    = ox + cols*tile \2              -- 50: board centre, for the end panels
```

Tile (gx, gy) draws at `ox + gx*tile`, `oy + gy*tile`.

Vertically nothing moved: the bar leaves 104 px, the board takes 96 of them,
and `oy` is what is left over, halved — still derived from `bar_y`, never a
literal. Horizontally the board gave up its centring to the column. `ox + 96`
is the board's right edge; `marg` past that puts the minimap outline at x=100
and its first block at x=101, and the column ends at x=125 against the same
2 px margin the left edge has.

The pair is centred against the board it stands beside. Each minimap is 24 px
of blocks under an 8 px label row — 32 px in all — and they are 48 px apart, so
the two together span y=11 to y=92 inside the board's 4..99.

### Minimaps

Each is one floor at quarter scale: `cols x rows` blocks of `mm_tile` px. They
hold no state of their own and are not interactive — every frame they are drawn
straight from `walls`, `doors`, `food` and `snake`.

| Block | Ink | Why that one |
|---|---|---|
| Free tile | 2 | the ink the board's own grid lines are drawn in |
| Snake segment | 11 | body green |
| Wall | 5 | wall grey |
| Door | 12 | the door's highlight, **not** its base 13 |
| Food | 8 | food red |

Two readings the drawing order depends on:

- **The door is 12, not 13.** 13 is the door's base colour, but it is also the
  floor's dither colour, and a 4 x 4 block of it beside the free-tile ink is
  mush. 12 is the door's own highlight, so the minimap still borrows from the
  door's palette instead of inventing a colour.
- **A segment resting on a door draws as body.** An occupied door is genuinely
  shut, at both ends: `dest()` refuses the step *into* a doorway that holds a
  segment (§7.3), and `fatal()` tests the *landing* cell, so a far end covered
  by your own body refuses the move too. There are only two doors per floor to
  hold in your head, and losing track of the body is losing the map.

Which floor lands in which slot follows the old O-cycle: slot 1 is
`view % 3 + 1` and slot 2 the one after it, so the floor one step "forward"
through the stack is always the top minimap.

A minimap carries the 1 px colour-0 outline every piece in this game carries
(§6.1). Against `cls(0)` it is invisible, exactly like the board's own outer
`rect` — it is there so the rule has no exceptions, and so the element still
holds its silhouette the day the background stops being black.

### The bar

The bar is two 8 px text rows at `bar_y + 5 / 13`. There is no third row: a
control hint the player reads once is not worth 8 px of permanent screen — and
with the view toggle gone there is no control left to hint at.

Rows are built the same way — a left column from x=5 and a right column flush
to x=123, each margin 5 px minus the pixel `oprint()` costs (§6.1):

| row | left column | right column |
|---|---|---|
| 1 | `score n  fill n/n` (7) | `best n` (9 if this run set it, else 6) |
| 2 | `floor  a  n/n` (6) | — |

Row 2's right column went with the toggle. `head a` existed to tell a player
scouting floor C that their head was on A; with the board pinned to the head's
floor it can only repeat what the left column already says.

Widest row 1 is `score 103  fill 99/99` — 103 is the ceiling on score
(`total_cells + 6 - 2`, §7.1) and 99 the ceiling on `total_cells`. That is
21 chars inked out to x=88, against `best 103` inked from x=90: **one bare
column, at x=89**. It fits, with nothing to spare, and any string that grows
by a character collides. Widest row 2 is `floor  a  33/33` (15 chars, ending
at x=64), with the whole right half of the row bare. Both measured with
`pget`.

---

---

## 3. Doors

### Topology

Six doors total, two per floor, one to each of the other two floors:

| Floor | Door 1 | Door 2 |
|-------|--------|--------|
| A     | -> B   | -> C   |
| B     | -> A   | -> C   |
| C     | -> A   | -> B   |

Doors are **paired**: the A->B door and the B->A door are two ends of the same
passage. Step on A's B-door and the head appears on B's A-door tile.

### Placement constraints

Doors are randomised each game, subject to:

1. **At least 1 tile from a corner** — `min_corner_dist = 1`, measured as
   Chebyshev distance. At 1 this excludes the four corner tiles themselves.
   Raise to 2 if you want a full empty tile of clearance around each corner.
2. **At least 2 tiles between the two doors on the same floor** —
   `min_door_dist = 2`, Chebyshev, so the two doors are never adjacent, not even
   diagonally.

Both are constants at the top of the file — see §8 if these readings don't match
what you had in mind.

Placement is rejection sampling: build the list of legal tiles once, pick two at
random, re-pick if they're too close. With 6 x 6 there are 32 legal tiles at
`min_corner_dist = 1`, so this settles in a couple of tries.

---

## 4. Data structures

```lua
-- one segment per body piece; head is index 1
snake = {
  {x=2, y=3, f=1},   -- head, floor 1 (A)
  {x=1, y=3, f=1},
}

-- doors[floor] = two door records
doors = {
  [1] = { {x=2,y=0,to=2}, {x=4,y=3,to=3} },
  [2] = { {x=1,y=2,to=1}, {x=5,y=4,to=3} },
  [3] = { {x=3,y=5,to=1}, {x=0,y=2,to=2} },
}

-- walls[floor] = 1 or 2 solid interior tiles
walls = {
  [1] = { {x=2,y=1}, {x=4,y=3} },
  [2] = { {x=1,y=3} },
  [3] = { {x=2,y=4}, {x=4,y=1} },
}

food  = {x=4, y=1, f=3}   -- nil once the board is full
view  = 1        -- the floor on the board: a cache of snake[1].f, not a control
score = 0
best     = 0     -- highest score ever, loaded from cart data at boot
new_best = false -- does *this* run own that record?
gameover = false
won      = false
```

Floors are `1, 2, 3` internally and displayed as `a, b, c` via
`floor_name = {"a","b","c"}`.

### Saved state

One number survives the process. `cartdata()` opens 64 persistent 32-bit slots,
of which this game uses one:

| Slot | Holds |
|---|---|
| 0 | `best` — highest score ever reached on this machine |

```lua
cartdata("rfreire_snakebox")   -- once per run, in _init, before new_game
best = dget(0)                 -- 0 on a machine that has never run the cart
...
dset(0, best)                  -- on the bite that beats the record
```

Three decisions worth keeping:

- **Written on the bite, not on the death.** The obvious place is `die()`, but a
  run abandoned from the pause menu — or by quitting PICO-8 — never reaches it,
  and the record it earned is lost. Writing at the moment `score` passes `best`
  costs the same one `dset` per record and cannot be escaped. It also covers the
  win, which is a bite like any other (`score += 1` happens before the win test)
  and would otherwise be the one ending that never banked its score.
- **`best` and `new_best` are different lifetimes.** `best` is loaded once at
  boot and only ever rises; `new_best` is reset by `new_game()`, because it
  answers "did *this* run set it", which is what the bar colours on.
- **The id is the cart's name, not the slot's.** `cartdata` ids are global
  across every cart on the machine, so they want a prefix (`rfreire_`), and
  changing one abandons every save already written under the old name. Pick the
  name the game will ship under — which is why this one was written as
  `rfreire_snakebox` while the cart was still called *multi-floor snake*, and
  why the rename to **snakebox** cost no saves: the id never moved.

---

## 5. Code

### Constants and setup

```lua
tile, cols, rows = 16, 6, 6
-- the bar is two 8px text rows with a 5px margin above and below, and the
-- board takes 96px of the 104 left over, so oy is 4. horizontally the board
-- no longer centres: it sits against the left margin and the minimap column
-- takes the 26px strip on the right (section 2)
bar_h = 24
bar_y = 128 - bar_h
marg  = 2
ox, oy = marg, (bar_y - rows*tile) \2
-- minimap column. ox+96 is the board right edge, +marg puts the outline at
-- x=100, so the first 4px block starts at 101. two of them, 48px apart,
-- which centres the pair against the board it stands beside
mm_x, mm_y, mm_tile, mm_gap = 101, 20, 4, 48
bcx = ox + cols*tile \2   -- board centre x, for the two end panels
total_cells = 0          -- set by new_game(): 108 minus walls minus the 6 doors

-- 1 or 2 blocks a floor. where there are two they keep a clear tile between
-- them (chebyshev >= 2) so they never fuse into a bar or an l, and neither
-- ever sits diagonally inside a board corner (7.6)
wall_min, wall_max = 1, 2

min_corner_dist = 1
min_door_dist   = 2
wall_corner_dist = 2
min_wall_dist   = 2

floor_name = {"a","b","c"}

-- art style (see section 6)
ink_outline = 0          -- one outline colour for every sprite and every string

dith_25 = 0b1010000010100000   -- board floor
dith_50 = 0b1010010110100101   -- bar seam, game-over veil

-- audio (see section 8)
sfx_step = {0,1,2,3,4,5}   -- one per board row, C major pentatonic
sfx_eat, sfx_door, sfx_bump = 6, 7, 8
sfx_die, sfx_win = 10, 11
sfx_deny = 27
-- slots 9 and 26 were the view-toggle clicks. the toggle is gone -- the two
-- floors you are not standing on are always on screen now (section 2) -- but
-- the slots stay where they are: every music pattern is written against this
-- numbering, and closing the gap would renumber the bed
mus_main = 0

function _init()
  poke(0x5f5c, 255)  -- disable btnp auto-repeat: one press = one step
  palt(0, false)     -- the pieces' outlines are colour 0 (section 6.6)
  palt(14, true)     -- ...and 14 cuts out their rounded corners
  -- o and x are deliberately left unbound now that the view toggle is gone.
  -- this is a slow puzzle with an hour of board behind it and no clock to
  -- punish a pause, so a face button that restarts is one stray press from
  -- throwing the run away. restart stays on the menu, two deliberate inputs in
  menuitem(1, "restart", new_game)
  -- one cartdata() per run, and before new_game(), so the bar can read best
  -- on frame one. dget returns 0 where no save exists (section 4).
  cartdata("rfreire_snakebox")
  best = dget(0)
  new_game()
end

function new_game()
  gen_doors()
  gen_walls()
  -- 6 = 2 doors x 3 floors. doors hold no food and fill nothing, so they
  -- come out of the target as well (section 7.2)
  total_cells = cols * rows * 3 - wall_count - 6
  -- view is no longer a control: it is a cache of snake[1].f, kept global
  -- because the whole draw path reads it. the head always starts on floor 1
  view, score = 1, 0
  -- best is loaded once at boot and survives this; new_best is per-game,
  -- because it answers "did this run set the record" (section 4)
  new_best = false
  gameover, won = false, false
  -- not dead code: free_cell reads occupancy off snake, so the last game's
  -- body has to go before the first roll of this one
  snake = {}
  -- a start cell can still be boxed in -- two doors and a wall around an
  -- edge tile do it -- and free_neighbor then falls back to the head itself,
  -- so re-roll until the tail is a real cell.
  -- not trapped() is the belt to that braces. at 1-2 walls a floor it can no
  -- longer fire: a trapped start needs all 3 non-neck exits shut, doors are
  -- open at the roll (nothing is standing in one yet), an interior head would
  -- need 3 walls, and a border head always keeps a border neighbour no wall
  -- can reach. it stays because its absence is a turn-1 death, and because
  -- the wall cap is a tuning constant that could move back.
  -- (never name this local `t` — that shadows the `t()` clock.)
  -- this always terminates: the four corners can never hold a wall or a door,
  -- and a corner's two neighbours are border tiles no wall can reach.
  local h, tl
  repeat
    h  = free_cell(1)
    tl = free_neighbor(1, h)
    snake = { {x=h.x,y=h.y,f=1,dx=h.x-tl.x,dy=h.y-tl.y}, {x=tl.x,y=tl.y,f=1} }
  until (tl.x ~= h.x or tl.y ~= h.y) and not trapped()
  -- the head carries its facing so draw_snake can point the eyes (section 6.6)
  spawn_food()
  music(mus_main, 2000, 7)   -- channels 0-2 reserved for music, 3 for sfx
end
```

### Door generation

```lua
function cheb(ax, ay, bx, by)
  return max(abs(ax-bx), abs(ay-by))
end

-- chebyshev distance to the nearest corner
function corner_dist(x, y)
  return max(min(x, cols-1-x), min(y, rows-1-y))
end

function legal_door_cells()
  local c = {}
  for x = 0, cols-1 do
    for y = 0, rows-1 do
      if corner_dist(x, y) >= min_corner_dist then
        add(c, {x=x, y=y})
      end
    end
  end
  return c
end

function gen_doors()
  local dest = { {2,3}, {1,3}, {1,2} }  -- where floor f's two doors lead
  local cells = legal_door_cells()
  doors = {}
  for f = 1, 3 do
    local a, b
    repeat
      a = rnd(cells)
      b = rnd(cells)
    until cheb(a.x, a.y, b.x, b.y) >= min_door_dist
    doors[f] = {
      {x=a.x, y=a.y, to=dest[f][1]},
      {x=b.x, y=b.y, to=dest[f][2]}
    }
  end
end

function door_at(f, x, y)
  for d in all(doors[f]) do
    if d.x == x and d.y == y then return d end
  end
end

-- the far end of the passage: floor g's door back to floor f
function paired_door(f, g)
  for d in all(doors[g]) do
    if d.to == f then return d end
  end
end
```

### Wall generation

Interior tiles only — `1..cols-2` in each axis — **minus the four tiles
diagonally inside a board corner**. Both restrictions are doing real work, not
framing: see §7.6.

```lua
function wall_at(f, x, y)
  for w in all(walls[f]) do
    if w.x == x and w.y == y then return true end
  end
  return false
end

-- interior only, so the border ring stays open and no floor is ever cut in
-- two -- and never the four tiles diagonally inside a board corner, which is
-- what corner_dist >= 2 excludes. a wall on one of those pins its corner into
-- a forced three-tile run (the corner plus both its neighbours, each down to
-- one way on), the tightest pocket this geometry can make. 12 tiles are left
function legal_wall_cells()
  local c = {}
  for x = 1, cols-2 do
    for y = 1, rows-2 do
      if corner_dist(x, y) >= wall_corner_dist then
        add(c, {x=x, y=y})
      end
    end
  end
  return c
end

function gen_walls()
  walls = {}
  wall_count = 0
  local cells = legal_wall_cells()
  for f = 1, 3 do
    local n = wall_min + flr(rnd(wall_max - wall_min + 1))
    local w
    -- the whole set is re-rolled, not each tile in turn: the spacing rule is
    -- the only one a second pick can fail, and rolling the pair together
    -- cannot paint itself into a corner the way sequential picking can.
    -- it always terminates -- at most 2 of the 12 cells are doors, and the
    -- remaining 10 are full of pairs at cheb >= 2
    repeat
      w = {}
      for i = 1, n do
        local c = rnd(cells)
        add(w, {x=c.x, y=c.y})
      end
    until not door_at(f, w[1].x, w[1].y)
          and (n < 2 or (not door_at(f, w[2].x, w[2].y)
               and cheb(w[1].x, w[1].y, w[2].x, w[2].y) >= min_wall_dist))
    walls[f] = w
    wall_count += n
  end
end
```

`rnd(cells)` hands back the *same* table every time it picks a cell, so the
copy in `add(w, {x=c.x, y=c.y})` is not ceremony: without it two floors that
roll the same tile share one record, and anything that later writes to a wall
writes to three floors at once.

### Free-cell helpers

```lua
function occupied(x, y, f)
  for s in all(snake) do
    if s.x == x and s.y == y and s.f == f then return true end
  end
  return false
end

function free_cell(f)
  local c
  repeat
    c = {x = flr(rnd(cols)), y = flr(rnd(rows))}
  until not door_at(f, c.x, c.y) and not wall_at(f, c.x, c.y)
        and not occupied(c.x, c.y, f)
  return c
end

function free_neighbor(f, c)
  local dirs = {{-1,0},{1,0},{0,-1},{0,1}}
  for d in all(dirs) do
    local x, y = c.x + d[1], c.y + d[2]
    if x >= 0 and x < cols and y >= 0 and y < rows
       and not door_at(f, x, y) and not wall_at(f, x, y) then
      return {x=x, y=y}
    end
  end
  return c  -- fallback for safety
end

-- one integer per cell, so occupancy can be a lookup instead of a scan
function cell_id(x, y, f) return f*36 + y*6 + x end

function free_cells()
  local taken = {}
  for s in all(snake) do taken[cell_id(s.x, s.y, s.f)] = true end
  local c = {}
  for f = 1, 3 do
    for y = 0, rows-1 do
      for x = 0, cols-1 do
        if not taken[cell_id(x, y, f)] and not wall_at(f, x, y)
           and not door_at(f, x, y) then
          add(c, {x=x, y=y, f=f})
        end
      end
    end
  end
  return c
end

-- food spawns only where the snake can come to rest: no wall, no door, no
-- tile it already holds. excluding doors used to deadlock the endgame (the
-- last free cells were often exactly the doors) — see 7.2 for why taking them
-- out of total_cells at the same time is what fixes that.
function spawn_food()
  local c = free_cells()
  if #c == 0 then food = nil return end   -- board full; the win check catches it
  food = rnd(c)
end
```

### Update — one press, one step

Three helpers carry the movement rules, and the dead-end check reuses all of
them. That reuse is the point: a `trapped()` that reimplements "can I go this
way" will drift out of step with `try_move()` and start ending games early.

```lua
dirs4 = {{-1,0},{1,0},{0,-1},{0,1}}

function step_sound(ny)
  sfx(sfx_step[rows - ny], 3)   -- channel 3: the one music doesn't own
end

function _update()
  if gameover or won then return end

  if btnp(0) then try_move(-1, 0) end
  if btnp(1) then try_move( 1, 0) end
  if btnp(2) then try_move( 0,-1) end
  if btnp(3) then try_move( 0, 1) end
end

-- where a step lands, or nil when an edge, a block or the neck refuses it.
-- the 4th return says the step transited a door, so try_move can play the
-- sweep without door_at having to be called twice.
function dest(h, dx, dy)
  local nx, ny, nf = h.x + dx, h.y + dy, h.f

  -- edges and interior blocks both refuse the move; neither kills.
  -- checked on the current floor, before any door transit.
  if nx < 0 or nx >= cols or ny < 0 or ny >= rows
     or wall_at(nf, nx, ny) then return end

  -- stepping onto a door transits to the paired door on the target floor --
  -- unless a segment is standing in that doorway, in which case the passage
  -- is shut. any part of the body counts, tail included. nothing else would
  -- have caught this: the head never rests on the door it leaves through, so
  -- fatal() only ever sees the far end of the passage.
  -- refused as nil plus a flag, because what refused is a body and not
  -- terrain -- try_move sounds it like a bite
  local thru = false
  local d = door_at(nf, nx, ny)
  if d then
    if occupied(nx, ny, nf) then return nil, true end
    local p = paired_door(nf, d.to)
    nx, ny, nf, thru = p.x, p.y, d.to, true
  end

  -- the neck is never somewhere you can land: the snake has no reverse gear.
  -- at length 2 the neck is also the tail, so nothing else refuses it — the
  -- tail vacates and the head walks straight back through its own body.
  -- checked after the transit, since a door can drop you onto the neck too.
  local k = snake[2]
  if k and k.x == nx and k.y == ny and k.f == nf then return end

  return nx, ny, nf, thru
end

-- growing is resolved first: the tail vacates unless we grow.
-- tested against the landing cell, which after a transit is the far end of
-- the passage. the door that was stepped on is dest()'s business, not this.
function fatal(nx, ny, nf)
  local grow = food and food.x == nx and food.y == ny and food.f == nf
  for i = 1, grow and #snake or #snake - 1 do
    local s = snake[i]
    if s.x == nx and s.y == ny and s.f == nf then return true end
  end
  return false
end

-- no survivable move left. note it asks dest() and fatal() rather than
-- re-deriving the rules, so doors, walls, the neck and the vacating tail are
-- all handled exactly as a real move would handle them. the neck being
-- refused inside dest() is what makes this "all 3 real exits are shut"
-- rather than "all 4", at every length.
function trapped()
  for d in all(dirs4) do
    local nx, ny, nf = dest(snake[1], d[1], d[2])
    if nx and not fatal(nx, ny, nf) then return false end
  end
  return true
end

function die(msg)
  gameover = true
  over_msg = msg          -- the panel names which death it was
  music(-1, 400)
  sfx(sfx_die, 3)
end

function try_move(dx, dy)
  local h = snake[1]
  -- no movement lock any more: the board is always the head's floor, so there
  -- is no state in which the player is looking somewhere they cannot move
  local nx, ny, nf, thru = dest(h, dx, dy)
  if not nx then
    -- with no landing, dest's second return is the reason it refused: true
    -- for a segment standing in a doorway, which is the body saying no and
    -- gets the body's sound, and nil for an edge, a block or the neck, which
    -- is terrain and gets the bump
    sfx(ny and sfx_deny or sfx_bump, 3)
    return
  end
  -- a bite is refused whenever the player has somewhere else to go: the press
  -- is heard (sfx_deny) and not taken. the trapped() guard is the "no way out"
  -- case the refusal must never swallow -- it cannot be true here, and that is
  -- exactly why it is written: it keeps a missed dead end an honest death
  -- instead of a board where every press is denied forever
  if fatal(nx, ny, nf) then
    if trapped() then
      die("bit yourself")
    else
      sfx(sfx_deny, 3)
    end
    return
  end

  -- after the refusal: a press that never became a step plays no door sweep
  if thru then sfx(sfx_door, 3) end

  local grow = food and food.x == nx and food.y == ny and food.f == nf

  add(snake, {x=nx, y=ny, f=nf, dx=dx, dy=dy}, 1)   -- facing, for the eyes   -- new head at the front
  if grow then
    score += 1
    sfx(sfx_eat, 3)
    -- banked on the bite, not in die(): a run abandoned from the pause menu
    -- never reaches die(), and the winning bite is a bite like any other
    if score > best then
      best = score
      new_best = true
      dset(0, best)
    end
    if filled() >= total_cells then   -- every non-door tile on every floor
      won = true
      food = nil
      music(-1, 1000)
      sfx(sfx_win, 3)
    else
      spawn_food()
    end
  else
    deli(snake, #snake)               -- drop the tail
    step_sound(ny)                    -- pitch follows the row: see 8.7
  end

  -- the board is the head's floor, always; the other two are the minimaps
  view = nf

  -- a filled board is a win, not a trap: the last head has nowhere to go
  -- either. order matters, and won is set just above.
  if not won and trapped() then die("no way out") end
end
```

### Draw

```lua
function _draw()
  cls(0)
  draw_board()
  draw_walls()
  draw_doors()
  draw_food()
  draw_snake()
  draw_minimaps()
  draw_bar()
  if won then
    draw_win()
  elseif gameover then
    draw_gameover()
  end
end

function px(gx) return ox + gx * tile end
function py(gy) return oy + gy * tile end

-- outlined text. every string that reaches the screen goes through this.
-- 8-way so there are no diagonal gaps over busy backgrounds.
function oprint(s, x, y, c, o)
  o = o or ink_outline
  for dx = -1, 1 do
    for dy = -1, 1 do
      if dx ~= 0 or dy ~= 0 then print(s, x+dx, y+dy, o) end
    end
  end
  print(s, x, y, c)
end

function draw_board()
  fillp(dith_25)
  rectfill(ox, oy, ox + cols*tile - 1, oy + rows*tile - 1, 1 + 13*16)
  fillp()
  -- grid lines are colour 2, NOT 0: black lines would swallow tile outlines.
  -- interior posts only -- px(cols)/py(rows) land 1px OUTSIDE the rect below,
  -- and that stray line only stayed invisible while the bar sat on top of it
  for i = 1, cols-1 do line(px(i), oy, px(i), oy + rows*tile - 1, 2) end
  for j = 1, rows-1 do line(ox, py(j), ox + cols*tile - 1, py(j), 2) end
  rect(ox, oy, ox + cols*tile - 1, oy + rows*tile - 1, ink_outline)
end

-- every piece is one 2x2 sprite; outline, dither and shading are all baked
-- into the art, so nothing below sets a colour or a fill pattern (section 6.6)
function draw_walls()
  for w in all(walls[view]) do
    spr(9, px(w.x), py(w.y), 2, 2)
  end
end

function draw_doors()
  for d in all(doors[view]) do
    spr(7, px(d.x), py(d.y), 2, 2)
    -- centred in the door's recessed panel, which is what keeps the 7 legible
    oprint(floor_name[d.to], px(d.x)+6, py(d.y)+5, 7)
  end
end

function draw_food()
  if food and food.f == view then spr(5, px(food.x), py(food.y), 2, 2) end
end

function draw_snake()
  for i = #snake, 1, -1 do          -- back to front so the head sits on top
    local s = snake[i]
    if s.f == view then
      if i == #snake and i > 1 then
        spr(13, px(s.x), py(s.y), 2, 2)                   -- the tail tile
      elseif i > 1 then
        spr(3, px(s.x), py(s.y), 2, 2)
      elseif s.dx ~= 0 then
        spr(1, px(s.x), py(s.y), 2, 2, s.dx < 0)          -- flip_x faces left
      else
        spr(11, px(s.x), py(s.y), 2, 2, false, s.dy < 0)  -- flip_y faces up
      end
    end
  end
end

-- the two floors the board is not showing, one 4px block per tile. each block
-- takes its piece's own identifying colour (section 6.5); the door and the
-- body-on-a-door readings are argued in section 2
function draw_minimaps()
  -- one pass over the body, not a scan per cell: 96 segments across 72 cells
  -- is real work every frame, and cell_id already exists for exactly this
  local taken = {}
  for s in all(snake) do taken[cell_id(s.x, s.y, s.f)] = true end
  for i = 1, 2 do
    -- cycle order, so the floor one step "forward" is always the top slot
    local f = (view + i - 1) % 3 + 1
    local my = mm_y + (i-1) * mm_gap
    oprint(floor_name[f], mm_x + 10, my - 9, 7)
    rect(mm_x-1, my-1, mm_x + cols*mm_tile, my + rows*mm_tile, ink_outline)
    for gx = 0, cols-1 do
      for gy = 0, rows-1 do
        local c = 2
        if wall_at(f, gx, gy) then c = 5
        elseif taken[cell_id(gx, gy, f)] then c = 11
        elseif food and food.f == f and food.x == gx and food.y == gy then c = 8
        elseif door_at(f, gx, gy) then c = 12
        end
        local bx, by = mm_x + gx*mm_tile, my + gy*mm_tile
        rectfill(bx, by, bx + mm_tile-1, by + mm_tile-1, c)
      end
    end
  end
end

-- a segment resting on a door is in transit, not filling floor space, so it
-- counts nowhere. pass f for one floor, pass nothing for the whole board.
function filled(f)
  local n = 0
  for s in all(snake) do
    if (not f or s.f == f) and not door_at(s.f, s.x, s.y) then n += 1 end
  end
  return n
end

function draw_bar()
  rectfill(0, bar_y, 127, 127, 5)
  fillp(dith_50)
  rectfill(0, bar_y + 1, 127, bar_y + 2, 5 + 0*16)  -- softened seam
  fillp()
  line(0, bar_y, 127, bar_y, ink_outline)
  oprint("score "..score.."  fill "..filled().."/"..total_cells, 5, bar_y+5, 7)
  -- second column of row 1, right-aligned against the same 5 px margin the
  -- left one uses: 4 px per character, and oprint needs the last of them for
  -- the outline. 9 while this run owns the record, 6 when it doesn't — the
  -- bar's own alert and secondary inks, no new colour (section 6.5).
  local bs = "best "..best
  oprint(bs, 123 - #bs*4, bar_y + 5, new_best and 9 or 6)
  -- "view" was the label while it was a control. it names the board's floor
  -- now, and the head is always on it -- which is what retired row 2s right
  -- column: "head a" could only ever say what this line already says
  oprint("floor  "..floor_name[view].."  "..filled(view).."/"
         ..(cols*rows - #walls[view] - #doors[view]), 5, bar_y + 13, 6)
end

-- an outlined plate with an inner rim in its own light shade, so both end
-- screens are lit exactly like every piece on the board (section 6.5). its
-- bounds are derived from ox rather than placed, so it covers the board and
-- nothing else -- the minimap column stays readable under a finished game,
-- and a draw literal left behind when the board moves is what cost a bug
-- last time
function panel(c, c2)
  local x0, x1 = ox+4, ox + cols*tile - 5
  rectfill(x0, 40, x1, 64, c)
  rect(x0, 40, x1, 64, ink_outline)
  rect(x0+1, 41, x1-1, 63, c2)
end

function draw_gameover()
  fillp(dith_50 + 0b0.1)            -- .1 = second colour transparent
  rectfill(ox, oy, ox + cols*tile - 1, oy + rows*tile - 1, 0)
  fillp()
  panel(1, 13)
  -- two deaths share one panel, so the line is centred rather than placed:
  -- 4 px per character, halved, off the board's centre -- bcx, not 64, since
  -- the board no longer sits in the middle of the screen
  oprint(over_msg, bcx - #over_msg * 2, 46, 8)
  oprint("menu: restart", bcx - 26, 55, 6)
end

function draw_win()
  panel(3, 11)                      -- no veil: the full board is the reward
  oprint("every tile", bcx - 20, 46, 10)
  oprint("menu: restart", bcx - 26, 55, 7)
end
```

---

## 6. Art style

Four rules, applied to every pixel that reaches the screen.

### 6.1 Outlining — mandatory for all text

**No raw `print()` ever reaches the screen.** Every string goes through
`oprint()`, which draws the text nine times: eight 1 px offsets in
`ink_outline`, then the fill colour on top. Treat a bare `print()` in the draw
path as a bug — it's the easiest rule in this list to violate by accident when
adding a debug readout.

- **8-way, not 4-way.** Cardinal-only outlining is 5 passes instead of 9, but
  leaves diagonal gaps that show up over the dithered floor. Use 8-way for
  anything drawn over the board; 4-way is defensible on the flat bar, but the
  inconsistency isn't worth the 4 saved calls.
- **One outline colour, globally.** `ink_outline = 0` for text *and* sprites.
  Per-object outline colours are the fastest way to make a set of pieces stop
  reading as a set.
- **Budget the extra pixel.** An outlined string is 1 px wider and taller on
  every side, which is why the bar text starts at x=5 rather than x=4.
- **Cost.** 9 `print()` calls per string; the bar plus two door labels is about
  45 per frame. That's negligible here. If text ever gets heavy, pre-render the
  outlined strings once to the sprite sheet and `spr()` them.

The same rule applies to art: **every 16 x 16 piece carries a 1 px outline in
colour 0**, baked into the sprite. Two consequences worth planning around — the
usable interior is **14 x 14**, and the grid lines cannot be black, or the
outlines dissolve into them wherever a piece sits against a line. That's why
`draw_board()` draws its lines in colour 2.

### 6.2 Dithering

PICO-8 gives you a hardware 4 x 4 fill pattern via `fillp()`. Each of the 16
bits is one pixel: a **0 bit takes the low nibble** of the current colour, a
**1 bit takes the high nibble**. So `rectfill(..., 11 + 3*16)` under a 50 %
pattern paints a green/dark-green checker.

| Density | Constant  | Value                  |
|---------|-----------|------------------------|
| 12.5 %  | `dith_12` | `0b1000000000100000`   |
| 25 %    | `dith_25` | `0b1010000010100000`   |
| 50 %    | `dith_50` | `0b1010010110100101`   |
| 75 %    | `dith_75` | `0b1111010111110101`   |

Adding `0b0.1` to a pattern makes the high-nibble pixels **transparent** instead
of coloured — that's the game-over veil, a 50 % black screen door over the
board.

**The pattern is aligned to screen coordinates, not to the shape.** Normally
that causes dither to crawl when something moves, but this game is saved by its
own geometry: tiles are 16 px, 16 is a multiple of 4, and pieces only ever move
a whole tile. The dither therefore lands identically in every cell and never
shifts during play. If you later animate a piece at sub-tile offsets, that
breaks — bake the dither into the sprite instead of using `fillp`.

The pieces do exactly that already: `spritegen.js` bakes each one's dither into
its sprite at generation time, so `fillp` survives only where a shape is still
drawn by code — the floor, the bar seam and the game-over veil.

Where it's used: the floor (25 % indigo over dark blue, so the play area reads
as texture rather than a slab), each piece's fill blending toward its own dark
shade, the seam under the board, and the game-over veil.

Where it is never used: **on an outline**, and **on text**. Both need to stay
solid to hold their silhouette.

Two gotchas — `fillp` is global state and persists until you call `fillp()` with
no argument, and it applies to the shape functions (`rectfill`, `circfill`,
`ovalfill`, `line`, `rect`…) but **not** to `spr()` or `print()`.

### 6.3 Anti-aliasing

There is no blending in a 16-colour indexed palette, so AA here means the manual
kind: placing a single pixel of an intermediate colour in the crook of a
shallow diagonal or curve. It only works where the palette actually contains a
ramp:

| Ramp                | Colours       |
|---------------------|---------------|
| Dark blue → white   | 1, 13, 6, 7   |
| Black → white       | 0, 5, 6, 7    |
| Red → peach         | 8, 9, 10, 15  |
| Brown → peach       | 4, 9, 15      |
| Dark green → green  | 3, 11         |
| Purple → peach      | 2, 14, 15     |

Rules:

- **Shallow slopes and curves only.** AA a 45° line or a straight edge and it
  just goes blurry — those are already as smooth as the grid allows.
- **One intermediate pixel per step.** Two is a gradient, not anti-aliasing.
- **AA against one known background.** A piece can only be anti-aliased for a
  single backdrop, and here that's the dark blue floor for every piece — so it
  works. Anything that will be drawn over an unpredictable background gets an
  outline instead of AA.
- **AA lives inside the outline.** The outline itself stays a hard, solid 1 px
  ring; the softening happens on the fill edge just within it.
- **Never AA text.** That's what the outline is for.
- **Integer positions, no transforms.** `spr(n, x, y, 2, 2)` at whole-pixel
  coordinates only. Scaling or rotating destroys hand-placed AA — which is
  another reason the movement is tile-snapped.

If the base 16 colours don't give you the mid-tone you need, PICO-8's hidden
palette does: `pal(13, 141, 1)` swaps colour 13 for one of the 128–143 range,
which is where most of the useful muted tones live.

### 6.4 Stair-stepping consistency

Along any diagonal or curve, the runs of pixels must form a **monotone**
sequence. `4,3,2,1` is a curve. `3,3,3,3` is a line. `3,1,4,2` is noise, and
reads as a dent even when the viewer can't say why.

```
consistent (2,2,2,2)      broken (2,1,3,1)
##                        ##
  ##                        #
    ##                       ###
      ##                        #
```

- **Keep a small vocabulary of slopes** — 1:1, 1:2, 1:4, 2:1 — and use only
  those across the whole set.
- **Run lengths change by at most 1** between neighbours, and only in one
  direction as a curve tightens.
- **No isolated single pixel** stranded between two longer runs.
- **The outline copies the fill's stepping exactly**, one pixel out. An outline
  that steps differently from the shape it wraps makes the silhouette look
  frayed.
- **Same corner radius on every piece.** Head, body, food and door should share
  one corner, mirrored to all four sides. A 2 px radius fits a 16 x 16 tile
  well:

```
top-left quadrant     . outside   o outline   # fill

. . o o o o o o
. o # # # # # #
o # # # # # # #
o # # # # # # #
```

The outline's left edge moves 2 → 1 → 0 → 0: monotone, no repeats out of order.

### 6.5 Colour roles

Fix these once and don't improvise per piece.

| Role              | Fill | Dither  | Hi | Lo | Notes                           |
|-------------------|------|---------|----|----|---------------------------------|
| Outline (all)     | 0    | —       | —  | —  | never dithered, never AA'd      |
| Shadow ink (all)  | 4    | —       | —  | —  | one dark ink, like the outline  |
| Cut-out key       | 14   | —       | —  | —  | `palt(14,true)`; never drawn    |
| Floor             | 1    | 13 @25% | —  | —  |                                 |
| Grid lines        | 2    | —       | —  | —  | must not be 0                   |
| Snake head        | 10   | 9 @25%  | 15 | 4  | eyes: 7 glint on 0              |
| Snake body        | 11   | 3 @50%  | 11 | 4  | no interior motif — see below   |
| Snake tail        | 3    | 11 @25% | 11 | 4  | 12x12, inset 2 px on every side |
| Food              | 8    | 9 @25%  | 9  | 4  | core 15, ringed 10              |
| Door              | 13   | 12 @50% | 12 | 4  | recess 1, letter 7              |
| Wall block        | 5    | 6 @25%  | 6  | 4  | mortar 0; must not read as body |
| Bottom bar        | 5    | 0 @50%  | —  | —  | text 7 / 6 / 9, outline 0       |
| Minimap free tile | 2    | —       | —  | —  | the grid-line ink, reused       |
| Minimap door      | 12   | —       | —  | —  | the door's *hi*, not its 13     |
| Minimap label     | 7    | —       | —  | —  | same ink as the door letters    |

The bar's three inks are roles, not slots: 7 is the primary readout, 6 is
secondary or inert, 9 is "look at this". The best score uses 6 and 9 rather
than introducing a fourth colour — inert while the record belongs to some
earlier run, alert while this run owns it — which is the same reason the
head-on-another-floor hint is 9.

Every piece is lit the same way: a highlight along its top and left edge, a
shadow down its right and along its bottom. Two rules came out of building it,
and both are the difference between a bevel and a smear:

- **The highlight can be the piece's own light colour.** A solid run of 11 over
  a 50 % 11/3 checker still reads, because a continuous line beats scattered
  pixels of the same colour.
- **The shadow cannot be the piece's own dark colour.** A 1 px column of 3 down
  the edge of that same checker is invisible — half the pixels beside it are
  already 3. So the shadow is **one global ink, colour 4**, for exactly the
  reason the outline is one global colour: it is darker than every base pair,
  and it keeps the pieces reading as a set. That is also why 4 cannot be the
  `palt` key, and 14 is.
The minimap blocks are the one place a piece is named by a single flat colour
instead of drawn (§2). They still take their colour from the piece's row above
rather than from a second palette — body 11, wall 5, food 8 — with the door as
the sole exception: its base 13 is also the floor's dither colour, so at 4 px
it dissolves, and the block takes the door's highlight 12 instead. A free tile
borrows the grid-line ink 2, which is what makes a minimap read as the board's
own grid seen from further away.

- **Nothing else goes inside a dithered piece.** The body first carried a scale
  plate drawn in its own 11; against the checker it disappeared on alternate
  rows and came back as noise, breaking the stair-stepping rule in §6.4. The
  body is now a plain bevelled block, and the head carries the personality.

### 6.6 Sprites

Each 16 x 16 piece is a **2 x 2 block of PICO-8's 8 x 8 sprites**:

```lua
spr(n, px(gx), py(gy), 2, 2)
```

A 2x2 sprite starting at index `n` consumes `n`, `n+1`, `n+16`, `n+17`, so the
indices are spaced two apart:

| Piece            | Index | Slots used     | Notes                            |
|------------------|-------|----------------|----------------------------------|
| Head, horizontal | 1     | 1, 2, 17, 18   | `flip_x` when moving left        |
| Body             | 3     | 3, 4, 19, 20   |                                  |
| Food             | 5     | 5, 6, 21, 22   |                                  |
| Door             | 7     | 7, 8, 23, 24   | letter `oprint`ed at +6, +5      |
| Wall             | 9     | 9, 10, 25, 26  |                                  |
| Head, vertical   | 11    | 11, 12, 27, 28 | `flip_y` when moving up          |
| Tail             | 13    | 13, 14, 29, 30 | last segment; no facing          |

The head is two tiles because the eyes have to point where you last moved: the
head segment carries the `dx, dy` of the step that made it, and `spr`'s flip
flags cover the other two directions. Mirroring is safe where scaling and
rotation are not — it preserves the pixel structure exactly.

The tail is a tile of its own for the same reason the head is: the two ends of
a long body have to be told apart at a glance, and on a board you only ever see
one floor of, "which end am I about to run out of" is the question the player is
actually asking. It carries **no facing**, unlike the head — the taper says
"end" from any direction, and giving it one would mean storing a direction on a
segment that has none.

Two things had to be true for it to read as a tail rather than as a discoloured
body block:

- **It is smaller.** 12 x 12, inset 2 px on every side, with the same corner
  radius and the same bevel as every other piece — so the floor shows through
  around it. That silhouette does most of the work; the colour only confirms it.
- **It is not the body's checker with the colours swapped.** The first attempt
  was 3 fill / 11 dither at 50 %, which is pixel-for-pixel the body's 11/3
  checker inverted — and a 50 % checker of two colours looks the same whichever
  way round it is. It is 25 % instead: mostly 3, with 11 scattered through it,
  which reads as *darker* rather than as *different noise*.

**`spr()` treats colour 0 as transparent by default**, which would erase the
outline every piece depends on. Set the palette once, in `_init`:

```lua
palt(0,false)   -- black is the outline, not a hole
palt(14,true)   -- 14 is the key colour the rounded corners are cut out with
```

The art is generated by `spritegen.js`, which writes each piece as ASCII
*materials* rather than colours — `#` base, `h` highlight, `d` shadow, `o`
outline, `.` cut-out — and resolves them per piece, baking the dither in. It
asserts every row is 16 chars and every `__gfx__` line is 128 digits, because a
single short line silently corrupts everything after it. That generator is what
keeps `fillp()` out of the draw path: outline, dither and shading all live in
the sprite now, and `oprint()` is the only style left in code.

### 6.7 Checklist

- [ ] No bare `print()` anywhere in the draw path
- [ ] `palt(0,false)` set, or every outline is a hole
- [ ] Every sprite has a 1 px colour-0 border on all four sides
- [ ] No shadow drawn in a colour its own piece already dithers with
- [ ] `fillp()` reset after every dithered draw
- [ ] No dither on any outline or any glyph
- [ ] Grid lines are not colour 0
- [ ] AA only on slopes shallower than 45°, one pixel per step
- [ ] Every piece uses the same corner radius and the same slope vocabulary
- [ ] Outline stepping matches fill stepping exactly
- [ ] All sprite draws at integer coordinates, no scaling or rotation

### 6.8 Cover art

The `__label__` is drawn by `labelgen.p8`, a throwaway cart that composes the
128 x 128 image with plain drawing calls, reads it back with `pget` and prints it as
hex; `label-tool.js` splices that into the cart. See
[PICO8-LABEL.md](PICO8-LABEL.md) for the pipeline.

**It does not touch the sprite sheet.** Reusing the 16 x 16 pieces would have made the
label a screenshot at a size where a screenshot stops reading: 16 px tiles leave room
for a 6 x 6 board and nothing else, so the title and the "three floors" idea would both
have been squeezed out. The label re-draws every piece at **10 px** instead, from the
same §6.5 colour roles — outline 0, shadow ink 4, head 10/9 with black eyes, body 11/3,
food 8/9 with a 15 core, door 13/12, wall 5/6, tail 14/8 inset 1 px on every side so
the floor shows around it the way the 12-in-16 sprite does. Same set, different scale.
The cover has to show **both** ends of the snake or it is showing a rope, which is why
the tail is on it at all.

What the composition has to say, in the order it reads:

1. **The name.** A 4 x 5 block font at **3 px a cell** — 12 x 15 per letter, 110 px for
   the eight-letter word. The cell was 4 while the game was called `snake`; at that size
   `snakebox` needs 142 px and does not fit a 128 px cover, so the cell dropped to 3 and
   the advance to 14. The 3 x 5 *grid* PICO8-LABEL.md suggests is one column too narrow
   whatever the cell size: `n` and `k` need an interior diagonal, and at 3 wide they came
   out as `h` and a bracket. Emboss the outer contour only (light 7 top-left, shadow 4
   bottom-right), over a black halo, over a colour-2 drop shadow drawn **first** so the
   halo eats all but its outer edge — drawn last, it becomes a purple slab under the whole
   word. Both offsets are **one cell**, not a fixed 2 px: at cs=3 a 2 px halo closes on a
   2-cell counter from both sides and the `o` goes solid.
2. **Three floors.** Three 6 x 6 plates offset one cell up and to the right, back to
   front, each darker than the one in front of it (`0/1` @50 %, `1/0` @25 %,
   `1/13` @25 %), each with a black drop shadow and a lit rim along its top and left
   edge. The value ramp does the depth; the rim is what makes the steps visible at 1x.
3. **The body spans floors.** Three segments sit on floor **b**'s right-hand column, so
   the front plate cuts them off — the body visibly continues onto a floor you can't
   see. This is the one rule of the game a still image can show.
4. **The bar**, rebuilt exactly as `draw_bar()` builds it, carrying the title and the
   author. It costs the bottom 15 rows and buys the only legible text on the label. It
   is **not** the game's bar and does not track it: the game's is 24 rows of live state,
   this one is artwork. It used to carry a control hint too, which was removed when the
   view toggle it named stopped existing (section 2).

Judge it at **1x**, always. Everything above survived that test; two things that didn't:
a brown (colour 4) plate shadow, which fringed the whole stack in warm lines, and a
background glow in 13, which put the plates' own highlight colour into the sky and
flattened them into it. The background is now one hue — a `0`/`1` dithered vignette.

---

## 7. The fill goal

The win condition is `filled() >= total_cells` — one segment per tile the snake
can come to rest on, across all three floors. It's checked the moment a food is
eaten, because that's the only moment the snake grows.

`filled()` is not `#snake`. Door tiles are transit, not floor space: they're out
of `total_cells`, out of the food pool, and a segment sitting on one counts
toward nothing. So `filled() == #snake - (segments currently on doors)`.

### 7.1 What the numbers say

- **96 to 99 tiles**, not 108. Each floor loses 1 or 2 to walls and exactly 2 to
  doors, so the target is `108 - wall_count - 6` and it changes every game.
  `total_cells` is computed in `new_game()` after `gen_walls()`, never hardcoded.
- The snake starts at length 2 with both segments off the doors, so `filled()`
  starts at 2 and a win needs **at least 94 to 97 food** — one more for every
  segment parked on a door at the moment the board fills. Score is therefore not
  capped at `total_cells - 2`; don't assert that it is.
- At fill F there are `total_cells - F` free cells. Food gets scarcer as you go,
  which is the intended difficulty curve.
- `filled()` is not monotonic. Growing raises it by 1, but an ordinary step that
  lands the head on a door while the tail leaves a floor tile lowers it by 1
  (and the reverse raises it). It never gets stuck, though: food exists exactly
  while `filled() < total_cells`, so there is always another one to eat.

### 7.2 Two bugs the goal exposes

Both were latent in the earlier code and are fixed above.

**Food on door tiles, and the deadlock behind it.** This one was fixed twice.

The original `spawn_food()` excluded doors, which is fine at length 4 and fatal
near the end: the last free cells tend to be exactly the doors, so there was no
legal spawn, no growth, no win, and the rejection loop spun forever. The first
fix made doors valid spawn sites. That cleared the deadlock but produced a
worse-looking bug — food materialising *inside a doorway*, on a tile you can
only reach by arriving through the passage, which reads as broken even though
it was reachable.

The real fix is to take doors out of **both** halves at once:

| | walls | doors |
|---|---|---|
| in `free_cells()` (food pool)? | no | no |
| in `total_cells` (fill target)? | no | no |
| can hold a segment? | no | yes — by arriving through it |
| can be *entered* while holding one? | n/a | no — the doorway is shut (§7.3) |

Doors now behave like walls for accounting and like floor for movement. The
deadlock is gone because an empty free list no longer means "only doors left",
it means `filled() == total_cells` — a full board, which is the win. The rule
that keeps the two halves honest: **anything excluded from the food pool must
be excluded from the fill target too**, or the game can reach a state where it
can neither spawn nor win. That's what `filled()` skipping door-borne segments
enforces on the counting side.

**Rejection sampling had to go.** `repeat … until free` is fine on an empty
board and unbounded on a full one. `free_cells()` builds the list once from an
occupancy lookup and picks from it, so a full board returns an empty list
instead of hanging.

### 7.3 The door tiles are the hard part

Under the current instant-transit rule, stepping onto door `pA→B` puts the head
on `pB→A` — the head never rests on the door it left through. So:

> A door tile can only be occupied by **arriving through it from the other
> floor**, never by walking onto it from its own floor.

Three consequences, all of which make the fill goal much sharper than it looks:

1. **Door tiles are not part of the goal any more, and that's why.** A door can
   only be occupied by arriving through it, so requiring all 6 to be filled
   would have forced all 6 crossings, in one specific order — see below. Taking
   them out of `total_cells` (7.2) drops that requirement entirely: the player
   crosses as often as the route needs and no more.
2. **The Eulerian constraint is what you avoid by doing that.** Had the doors
   stayed in the target: treat the floors as nodes and the 6 crossings as
   directed edges; every floor has in-degree 2 and out-degree 2, so the crossing
   order is forced into a circuit `A→B→C→A→C→B→A` — 7 blocks, floor A covered in
   three separate visits. A second use of any crossing would land the head on a
   tile its own body already holds. That is a much harder puzzle than the brief
   asks for, and it was invisible to the player.
3. **An occupied door is shut.** This one was reversed after play. The
   collision check runs against the *final* position after transit, not the
   door tile you stepped on, so by default you could walk straight through a
   doorway your own body was sitting in — which is the one place in the game
   where the snake visibly passes through itself. `dest()` now tests
   `occupied(nx, ny, nf)` *before* the transit branch and refuses the step.

   Three things follow, and the first is the price:

   - **You can strand a floor.** Park a segment on both of floor A's doors and
     floor A is unreachable for as long as those segments sit there. That is
     now a mistake the player can make, and making it is a normal part of a
     puzzle where the body is the obstacle — the same way filling a corridor
     is. It costs some boards their win, on top of §7.4.
   - **The tail counts.** A tail on a door vacates on the same tick, so
     allowing it would be *correct* — and indistinguishable, to the player,
     from walking through the middle of the body. The rule is "any part of me
     in a doorway shuts it", because a rule the player can see is worth more
     than one extra legal move. (Growth can never be what keeps it there:
     food never spawns on a door, so a transit step never grows.)
   - **It is a body refusal, not terrain.** Put it in `dest()` so `trapped()`
     inherits it — otherwise the two drift, per §12 — but sound it with
     `sfx_deny`, not `sfx_bump`. `dest()` signals which by returning `nil`
     plus a flag where it would otherwise return a landing.

   And it is not a soft lock: `trapped()` calls the same `dest()`, so a head
   whose only exits are shut doors dies "no way out" on the move that put it
   there — verified by hand-building exactly that position.
4. **Landing on your own neck is refused, wherever it comes from.** A transit
   that would drop the head on `snake[2]` is rejected by `dest()` like an edge —
   see §1. An ordinary step taken straight after a transit is *not* affected:
   the neck is back on the floor you came from, so nothing is behind you.

### 7.4 Random layouts are not guaranteed solvable

This is the honest limitation. A full fill is a Hamiltonian path through the
~100-cell movement graph, and `gen_doors()` places doors at random with no check
that such a path exists. Some seeds will be unwinnable, and the player has no
way to tell.

Hamiltonian path is NP-hard and 100 cells is far too many to verify inside a
PICO-8 frame budget, so brute-force validation at generation time isn't an
option. Practical choices, cheapest first:

- **Ship it as-is** and add a reroll key on the title screen. Most layouts are
  probably fine; you just can't promise it.
- **Hand-author the layouts.** Replace `gen_doors()` with a table of door sets
  you've solved yourself. This is what turns it from a random-board game into a
  designed puzzle, and is what I'd do if the fill is the *point* of the game.
- **Switch to rest-then-transit** (see §7.5), which makes the geometry much more
  tractable and gives you a real solvability test.

### 7.5 The variant worth considering

If the fill goal is central, changing one rule buys a lot:

> **Rest-then-transit.** Stepping onto a door occupies it normally. The *next*
> move transits to the paired door on the target floor, whatever direction is
> pressed.

A single crossing now fills **both** ends of a passage, so you need 3 crossings
instead of 6, and the floor sequence collapses to `A→B→C→A` — four blocks
instead of seven. Floors B and C are each covered by one unbroken path, which
makes them checkable:

A 6 x 6 grid is bipartite, 18 tiles of each colour under `(x+y) % 2`. A
Hamiltonian path over 36 tiles alternates colour and has an even length, so its
two endpoints must be **opposite colours**. Floor B's path runs from `pB→A` to
`pB→C`, so:

```lua
-- necessary condition for a full fill on a single-visit floor
(pb_a.x + pb_a.y) % 2 ~= (pb_c.x + pb_c.y) % 2
```

Same for floor C. That's a two-line test in `gen_doors()` that rejects a large
class of unsolvable layouts for free. It's necessary, not sufficient — but for
grid graphs with both sides even it's very nearly the whole story. Floor A gets
no such test, since it's split across two blocks and has slack.

The cost is that transit stops being instant, which changes the feel. Your call
— it's a real tradeoff, not a strict improvement.

### 7.6 Walls: two things that come free, one that doesn't

**Free thing 1: walls can never disconnect a floor.** Restricting them to the
interior (`1..4` on each axis) isn't only aesthetic. The border ring — row 0,
row 5, column 0, column 5 — is guaranteed wall-free, and it's a cycle that
touches every edge tile. So every edge tile is mutually reachable. An interior
tile is cut off only if all four of its neighbours are walls, which needs 4
walls; isolating a pair needs 6. With a cap of 2 per floor, neither is close to
possible. No connectivity check required at generation time.

**Free thing 2: a door can never be sealed.** An interior door has 4 neighbours
and at most 2 walls exist on its floor, so at least two stay open. An edge door
has at most one wallable neighbour, so at least two stay open.

**The thing the cap does not buy: pockets.** Connectivity is not the same
property as comfort. No wall placement can strictly trap a cell — the tightest
thing this geometry makes is a *forced run*, a stretch of cells each with one
way on — but a forced run is where a snake dies for a reason the player reads
as unfair, because the body arrives and the run turns into a trap after the
fact. Two rules cut the worst of them, and both are one `if` at generation:

- **Never the four tiles diagonally inside a board corner** — (1,1), (1,4),
  (4,1), (4,4), which is exactly `corner_dist >= 2`. A wall at (1,1) drops
  both (1,0) and (0,1) to one exit each, and the board corner already has
  two; the three of them become a forced 3-tile run with an entrance at each
  end. That's the tightest pocket available here, and it is free to exclude:
  12 of the 16 interior tiles remain.
- **Two walls keep a clear tile between them** — Chebyshev >= 2, so they never
  fuse. Two adjacent walls behave like one 2-tile obstacle, and a diagonal
  pair pinches the two cells between them down to one exit apiece.

Neither rule is a solvability guarantee. They remove the layouts that look
like a bug, which is a different and much cheaper goal than §7.4's.

**The thing that isn't free: walls break the colour balance.** This one matters
and it's cheap to check.

A 6 x 6 grid is bipartite — 18 tiles of each colour under `(x+y) % 2`. A
Hamiltonian path alternates colour, so over `n` tiles the counts must come out
within one of each other. Removing walls shifts that:

| Walls on a floor | Tiles left | Needed colour split of the walls |
|------------------|-----------|-----------------------------------|
| 1                | 35        | either colour — 1 wall can't unbalance |
| 2                | 34        | one of each colour                |

Two walls of the *same* colour leave 16 and 18 — a gap of two, and no
Hamiltonian path over that floor exists at all. `gen_walls()` as written
doesn't check this, so some layouts are unwinnable for a reason that has
nothing to do with where the doors went. Dropping the cap from 3 to 2 halved
the exposure for free: the 3-wall roll, which needed a 2:1 split, is gone, and
the 1-wall roll cannot be wrong at all.

It also **flips the door condition from §7.5**. For a floor visited once, the
path's endpoints are its two door tiles, and endpoint colours match iff the tile
count is odd:

| Walls | Tiles | Door tiles must be | Plus                                  |
|-------|-------|--------------------|---------------------------------------|
| 1     | 35    | the same colour    | — (either colour works)               |
| 2     | 34    | opposite colours   | one wall of each colour               |

That first row is worth reading twice — with an odd tile count, the rule from
§7.5 inverts.
If you implement the rest-then-transit variant and want a solvability filter,
both columns have to be checked together, and checking one without the other is
worse than checking neither, because it looks like it works.

The cheap fix, if you'd rather not reason about it: **force the colour split in
`gen_walls()`** by tracking `(x+y) % 2` as you place and rejecting a candidate
that would overshoot its quota. That's a handful of lines and it removes the
whole class of dead layouts.

As with §7.4, none of this is sufficient — it's a necessary condition that's
cheap enough to be worth enforcing, on a problem where the sufficient check is
out of reach.

---

## 8. Music and sound

Target: slow, cheerful, pastoral. Something that breathes rather than drives.

### 8.1 What the music has to carry

Two facts about this game shape every decision below.

**Nothing moves between presses.** In a real-time snake the music competes with
motion for the player's sense of time. Here it *is* the sense of time — the only
thing on screen that changes while the player sits thinking about a move. That
argues against percussion: a drum pulse implies a tempo the gameplay doesn't
have, and it turns thinking time into time pressure.

**Sessions are long.** A full fill is 106 food and several hundred moves. A
12-second loop will be heard a hundred times. Loop *length* matters far more
than hook strength here — aim for 45–60 seconds before anything repeats, and
prefer a bed that's pleasant at the twentieth pass over one that's charming at
the first.

### 8.2 Tempo

An SFX's `speed` field is the duration of one note in 1/128ths of a second. At
16th-note resolution:

```
bpm = 1920 / speed
```

| Speed | BPM  | One 32-note SFX |
|-------|------|-----------------|
| 16    | 120  | 4.0 s (2 bars)  |
| 20    | 96   | 5.0 s           |
| 24    | 80   | 6.0 s           |
| 28    | 69   | 7.0 s           |
| 32    | 60   | 8.0 s (2 bars)  |

**Use speed 28 or 32.** At 32 one SFX is exactly two bars of 4/4 at 60 BPM, so
eight patterns gives a 64-second loop — right in the target range with no
repetition tricks needed.

### 8.3 Instrument palette

| # | Waveform   | Reads as              | Use for                        |
|---|------------|-----------------------|--------------------------------|
| 0 | Triangle   | flute, ocarina, soft  | melody, bass — the workhorse   |
| 1 | Tilted saw | mellow reed           | warm counter-melody            |
| 2 | Saw        | bright, buzzy         | avoid — too arcade             |
| 3 | Square     | hollow, chiptune      | avoid at volume; fine very quiet |
| 4 | Pulse      | thin, reedy, birdlike | bird flourishes, sparkle       |
| 5 | Organ      | warm, wide            | sustained pad                  |
| 6 | Noise      | wind, water, leaves   | ambience — sparingly, vol 1–2  |
| 7 | Phaser     | swooshy, drifting     | one-off transitions            |

Triangle for melody and bass, organ for the pad, pulse for the occasional bird
figure. Saw and square are what make PICO-8 music sound like an arcade cabinet,
which is the opposite of the brief.

### 8.4 Harmony

**Key of C, major pentatonic** (C D E G A). Pentatonic has no semitone clashes,
so nothing you play against it can sound wrong — which matters here because §8.7
generates notes from the player's board position, and those notes have to
consonate with whatever the bed is doing at the time.

For the progression, prefer a **slow two-chord vamp over maj7 chords** to a
four-chord pop turnaround. `Cmaj7 → Fmaj7` for four bars each is calm and
unresolved in a pleasant way; I–V–vi–IV is cheerful but arrives somewhere every
four bars, and arrival implies progress the player may not be making.

Register: bass on pitches 12–24 (C1–C2), pad 24–36, melody 36–60 (C3–C5).
PICO-8's full range is 0–63, C0 to D#5.

### 8.5 Channel budget — the real constraint

PICO-8 has **four channels total**, shared between music and `sfx()`. Reserve
three for music and leave one for gameplay:

```lua
music(mus_main, 2000, 7)   -- mask 0b111: channels 0,1,2 are music-only
```

That leaves exactly **three musical voices**: bass, pad, melody. There is no
fourth channel for a constant noise-based wind or water bed — you have to choose.

The resolution: **don't run continuous ambience.** Fold the nature character
into the melody channel as sparse pulse-wave bird figures during the melody's
rests, using effect 6 or 7 (arpeggio) for a two- or three-note chirp. It costs
no extra channel, and intermittent birdsong reads as outdoors more convincingly
than a constant noise wash anyway, which tends to sound like tape hiss.

### 8.6 Pattern layout

Eight patterns, 64 seconds, loop back to 0:

| Pattern | Bars | Chord  | Ch 0 (bass) | Ch 1 (pad) | Ch 2 (melody) |
|---------|------|--------|-------------|------------|---------------|
| 0       | 1–2  | Cmaj7  | sfx 12      | sfx 16     | sfx 20        |
| 1       | 3–4  | Cmaj7  | sfx 12      | sfx 16     | sfx 21        |
| 2       | 5–6  | Fmaj7  | sfx 13      | sfx 17     | sfx 22        |
| 3       | 7–8  | Fmaj7  | sfx 13      | sfx 17     | — (rest)      |
| 4       | 9–10 | Am7    | sfx 14      | sfx 18     | sfx 23        |
| 5       | 11–12| Am7    | sfx 14      | sfx 18     | sfx 24        |
| 6       | 13–14| Fmaj7  | sfx 13      | sfx 17     | sfx 25        |
| 7       | 15–16| G7sus4 | sfx 15      | sfx 19     | — (rest)      |

Set the loop-back flag on pattern 7. The two melody rests are deliberate: they
give the pad room to breathe and they're where the bird figures go.

### 8.7 Making movement musical

The step sound is the one piece of audio that fires constantly, so it can't be a
click. Instead, **derive its pitch from the head's row**, so the board becomes an
instrument and moving up the grid plays up the scale:

```lua
sfx_step = {0,1,2,3,4,5}   -- C D E G A C' — one octave of C major pentatonic
```

Six rows, six notes. Bottom row is the root, top row the octave. Because the
scale is pentatonic and the bed is in C, every step consonates with whatever
chord is playing — the player is improvising over the vamp without knowing it.

```lua
function step_sound(ny)
  sfx(sfx_step[rows - ny], 3)   -- channel 3: the one music doesn't own
end
```

Keep these quiet — volume 2–3 in the SFX editor, short (4–6 notes), triangle or
pulse, with a fade-out (effect 5) so they don't stack into mush when the player
moves quickly.

If you'd rather author one SFX and retune it at runtime, the pitch is the low 6
bits of each note's first byte:

```lua
function set_pitch(n, i, pitch)
  local a = 0x3200 + 68*n + 2*i
  poke(a, (peek(a) & 0b11000000) | pitch)
end
```

Six separate SFX is more editor work but no memory-layout risk. Prefer it unless
you need continuous pitch.

### 8.8 State transitions

```lua
-- in new_game()
music(mus_main, 2000, 7)      -- 2 s fade in, channels 0-2 reserved

-- on death
music(-1, 400)
sfx(sfx_die)

-- on win
music(-1, 1000)
sfx(sfx_win)
```

One caveat worth knowing before you build anything clever on top: **`music()`
always restarts a pattern from its first note.** There's no resume and no
seeking. So the tempting idea of switching to a stripped-back pad-only
pattern for some second state will audibly jump the loop on every transition.
If you want that effect, the workable version is to keep one pattern set and
drop the melody by pointing those patterns at silent SFX. (This was originally
written about scouting another floor, which is no longer a state the game has —
the minimaps replaced it, §2 — but the caveat outlives the case.)

### 8.9 SFX slot budget

| Slot  | Sound                          | Notes                        |
|-------|--------------------------------|------------------------------|
| 0–5   | Step, one per pentatonic degree| quiet, 4–6 notes, fade out   |
| 6     | Eat                            | rising two-note figure       |
| 7     | Door transit                   | phaser sweep, ~8 notes       |
| 8     | Blocked by wall                | very soft thud, noise vol 1  |
| 9     | *unused* (was: view toggle fwd)| kept so the bed keeps its ids|
| 10    | Death                          | triangle, effect 3 (drop)    |
| 11    | Win                            | pentatonic run up, 2 bars    |
| 12–15 | Bass patterns                  |                              |
| 16–19 | Pad patterns                   |                              |
| 20–25 | Melody patterns                |                              |
| 26    | *unused* (was: view toggle back)| kept so the bed keeps its ids|
| 27    | Bite refused                   | pitched fall, Am triad       |

Slots 9 and 26 are dead: they were the forward and backward view toggles, and
the view toggle went when the minimaps arrived (§2). **Leave the holes.** Every
music pattern in §8.6 refers to its SFX by number, so closing a gap in the slot
table renumbers the bed and silently re-scores the loop. A dead slot costs
nothing; a renumbered one costs an afternoon.

Leave the bump almost inaudibly quiet. It fires on failed and neutral inputs,
which are the ones a player repeats without thinking, and those are exactly the
sounds that become irritating first.

The deny is the exception, and it is deliberately **not** the bump. The bump
says "there is nothing there" about terrain; the deny says "I heard you, and I
am not letting you do that to yourself". If the two sounded alike the refusal
would read as a dropped input, which is the one thing it must not read as. So it
is pitched where the bump is noise, and audible where the bump is not — a
descending E-C-A, an A minor triad, consonant with the Cmaj7/Am7 vamp it fires
over, for the reason §8.10 gives about the door sweep. It stays short, because
it is still a failed-input sound.

### 8.10 What was built

`audiogen.js` generates both sections and splices them into the cart. Three notes on
where the implementation had to go past the spec above:

**Sustain is slide, not repetition.** PICO-8 re-attacks on every note slot, so a pad written
as the same pitch eight times in a row pulses at 3.75 Hz — the exact drum-like tempo §8.1
says to avoid. Writing the repeats with **effect 1 (slide)** makes them seamless: the first
slot of a held note attacks, every slot after it slides into the pitch it is already on. The
same trick gives the bass its portamento when it drops from root to fifth mid-pattern.

**The first note after a rest must not slide.** Slide interpolates from the previous slot,
and a rest's pitch reads as 0 — so a slide out of silence glides up from C-0. The generator's
`hold()` helper always attacks on its first slot for this reason.

**One-shots have to be pentatonic too, not just the melody.** The door sweep was first
written as an even chromatic ramp, which lands on an augmented triad — it fires mid-move over
whatever the bed is holding and clashed audibly. It is now C E G C E G C.

Verification is split, because headless `-x` never advances the audio clock (see
PICO8-TOOLING.md): channel routing and slot contents are checked in-engine, tempo and pattern
order by parsing the generated text back into a readable table.

---

## 9. Build order

1. **Board only.** Constants, `draw_board()`, `draw_bar()`. Confirm the 96 x 96
   grid sits at (2,4) with a 24 px bar underneath and the right-hand strip
   still empty — the minimaps land there at step 5.
2. **Static snake.** Hardcode two segments on floor 1, draw them. Check tile
   alignment.
3. **Movement.** `try_move()` with no doors and no food. One press, one tile.
   Walls block.
4. **One floor at a time.** Draw only segments where `s.f == view`, with
   `view` a plain global. Verify the snake disappears on floors B and C.
5. **Minimaps.** `draw_minimaps()` for the two floors `view` is not showing.
   Do this before doors and food if you can: it is the only window you have
   into the two floors you cannot see, and every bug after this point is
   easier to read with it on screen.
6. **Doors.** `gen_doors()`, `draw_doors()`, then the transit branch in
   `try_move()`. Verify a body that straddles two floors draws correctly on
   each.
7. **Walls.** `gen_walls()`, `draw_walls()`, and the `wall_at()` clause in the
   move test. Check that `total_cells` moves with the roll — a hardcoded 108
   here means the win never fires, and so does forgetting the `- 6` for the
   doors.
8. **Food, score, growth, death.** Last, because everything else is easier to
   debug without it.
9. **Art pass.** Only now: draw the 16 x 16 pieces with outline, dither and
   consistent stepping, and swap `cell()` for `spr()` one piece at a time.
   Generate them rather than drawing them by hand — `spritegen.js` — and read
   the sheet back out of the cart as ASCII before believing any of it. Two of
   the three real bugs in this pass were pieces whose shading was the same
   colour as their own dither, and both were invisible in the hex and obvious
   in the round-trip.
   `oprint()` should already be in place from step 1 — it costs nothing to use
   it from the first string you draw, and retrofitting it later means hunting
   down every `print()` you left behind.
10. **Fill goal.** The win check is two lines, but test it by hacking
   `total_cells` down to something reachable (say 12) so you can actually hit
   the endgame in under a minute. Full-board bugs only appear at full board.
11. **Persistence.** `cartdata` last, because it is the one step that writes
    outside the process: a bug here survives the restart that clears every
    other bug. Test it by *running the cart three times* — set a record, exit,
    reload and check the bar, then set a worse score and confirm the record
    holds. A single run cannot tell a working `dset` from a global that just
    happens to still be in memory.
12. **Audio.** Step sounds first — they fire on every input, so they're the ones
    you'll notice are wrong. Then the music bed, then the one-shots. Play a full
    ten-minute session before committing to a loop; a bed that's charming for
    thirty seconds is a different thing from one that survives a full fill.

---

## 10. Design decisions worth confirming

These weren't pinned down in the spec, so I picked a reading — each is a
one-line change:

- **Doors are paired ends of one passage.** A's B-door and B's A-door link to
  each other. Alternative: land on a random free tile on the destination floor
  (`nx, ny = free_cell(d.to)`).
- **Transit is instant.** Stepping onto a door puts the head on the far side in
  the same turn, rather than resting on the door and passing through next turn.
  With the fill goal added this is now the single most consequential rule in the
  game — see §7.3 and the rest-then-transit variant in §7.5.
- **The two floors you are not on are on screen, not one keypress away.** The
  original design gave you one floor and a toggle: press O or X to cycle the
  view, and a movement lock so you could not move while looking elsewhere. The
  minimaps (§2) replace all of it. What was lost is small — the hidden floors
  are now 4 px a tile instead of 16, so you read topology off them, not detail.
  What was gained is that the game stopped having a mode: there is no state to
  be in and get stuck in, no lock to explain, no toggle to mis-press, and the
  board is always the thing you can act on. For a puzzle with no clock, a
  keypress that only changes what you are looking at was pure bookkeeping.
- **O and X are left unbound rather than reused.** The obvious candidate is
  restart, and it is the wrong one: a run here is long, there is no clock
  punishing a pause, and a face button that wipes the board is one stray press
  from throwing it away. Restart stays on the pause menu, which costs two
  deliberate inputs. If you want a button restart, bind it to a direction on
  the end screen, where there is nothing else to press.
- **`view` is a cache, not state.** It is `snake[1].f`, written in
  `new_game()` and after every step. Kept as a global because the whole draw
  path reads it, and a function call per tile in `draw_minimaps` is not free.
- **Food never spawns on door tiles**, and a segment resting on one fills
  nothing. The two go together: excluding doors from `free_cells()` alone is
  what deadlocked the endgame (§7.2). Taking them out of `total_cells` and
  `filled()` at the same time is what makes the exclusion safe.
- **A self-bite is refused, not fatal — while there is another way to go.**
  The alternative is the classic snake reading, where walking into yourself
  ends the run. It was rejected because this game has no clock: the player is
  studying a board across three floors, and a wrong direction there is a slip
  of the thumb, not a decision they lived with for the half-second a real-time
  snake gives them. Two consequences worth knowing: the dead end becomes the
  only loss the player can reach, and the run can only end when the board
  genuinely closes around the head. Restore the old reading by deleting the
  `else` branch — but keep the death itself guarded, see §12.
- **The tail is its own tile, the head's facing is not given to it.** Snake
  games usually taper the tail toward the segment ahead of it, which means four
  more tiles or a stored direction per segment. Here the taper is symmetric and
  the read comes from size and shade instead (§6.6).
- **The best score is one number in slot 0.** Per-floor bests, a run history or
  a fewest-moves record are all more cart data; none of them changes the shape
  of the write (§4, saved state).
- **"1 tile from a corner" = `min_corner_dist = 1`**, which excludes only the
  four corner tiles. If you meant a full tile of clearance, set it to `2` (that
  leaves 20 legal tiles, clustered in a plus shape through the middle).
- **"2 tiles between doors" = Chebyshev `>= 2`**, so doors are never touching,
  including diagonally. Switch `cheb()` to Manhattan if diagonal adjacency
  should be allowed.
- **Walls block rather than kill**, and there is no wrapping. For a puzzle the
  wasted press is a gentler punishment than a restart. Interior blocks behave
  identically to edges for the same reason.
- **1 or 2 blocks per floor, interior only, never corner-hugging, never
  touching.** The interior restriction is what makes connectivity free (§7.6);
  the other two remove the pockets that read as unfair deaths. Widening the
  range to the border ring means you have to start checking that the floor is
  still traversable.
- **Blocks are not colour-balanced at generation.** `gen_walls()` places them at
  random, which leaves some layouts unwinnable — see §7.6 for the fix if the
  fill goal matters more than the code staying short. The 1-or-2 cap shrinks
  the exposure but does not close it.
- **A doorway with any part of the snake in it is shut** (§7.3). The looser
  reading — the collision test only ever sees the far end of the passage, so
  an occupied door works as an entrance — is one line shorter and lets you
  plug a door without losing the floor behind it. It also lets the snake walk
  visibly through its own body, which is why it went.
- **Food spawns on any of the three floors.** Restrict to the head's floor with
  `f = snake[1].f` in `spawn_food()` if cross-floor hunting is too much.

---

## 11. Tuning and variations

- **Puzzle pressure.** Add a move counter beside the score and a par value per
  layout.
- **Fog.** Drop tiles from a minimap until the snake has visited them, so the
  two floors you are not on are revealed by exploring rather than given.
- **Fixed layouts.** Swap `gen_doors()` for a table of hand-authored door sets
  to make designed levels instead of random ones.
- **Locked doors.** Give a door a `key` field; the transit branch refuses unless
  a key has been collected.
- **One-way doors.** Drop `paired_door()` and give each door an explicit
  `dx, dy, df` destination.
- **Warn instead of ending.** `trapped()` is cheap enough to call every frame,
  so the same function can tint the bar red one move *before* the dead end —
  scan the head's exits and flag the ones that lead to a position with no exits
  of its own. That turns the dead end from a verdict into a puzzle cue, at the
  cost of some of the tension.
- **Undo.** With the dead end detected rather than walked into, a one-step undo
  becomes coherent: keep the previous `snake`/`food` and restore on a key.

---

## 12. Gotchas

- **PICO-8 has no `table.insert` / `table.remove`.** Use `add(t, v, i)` to
  insert at an index and `deli(t, i)` to remove at one. If you're on a build
  older than 0.2.4, `add()` won't take an index — shift manually, or store the
  snake back-to-front and `add()` to the end.
- **`btnp` auto-repeats by default** when a direction is held, which turns a
  turn-based game into a real-time one. `poke(0x5f5c, 255)` in `_init()` turns
  the repeat off.
- **`rnd(n)` returns a float.** Use `flr(rnd(cols))` for a tile index.
  `rnd(table)` returning a random element is a 0.2+ feature.
- **Draw the snake back-to-front** so the head renders over the body when they
  overlap during a growth frame.
- **The `grow` check must run before the self-collision loop.** If you skip the
  tail exclusion, moving into the tile the tail is vacating registers as a false
  death.
- **The dead-end check has to run `after` the move, and after the win test.**
  Run it before the move and you are testing a position the player has already
  escaped; run it before `won` is set and a completed board reports as a loss,
  because a snake filling every tile genuinely has nowhere to go.
- **A dead-end test that duplicates the movement rules will drift.** `trapped()`
  is only correct because it calls the same `dest()` and `fatal()` that
  `try_move()` calls. Reimplement "is this direction free" inline and it will
  miss one of the three things a real move handles — the door transit, the wall
  test running on the *current* floor, or the tail vacating — and each miss ends
  a live game early.
- **The vacating tail is an exit.** A head hemmed in by two edges and two body
  segments is *not* trapped if one of those segments is the tail: it steps away
  on the same tick the head arrives. Any test fixture for this needs a segment
  behind the blocker, or it silently proves nothing.
- **`cartdata()` is once per run, and it must come before the first `dget`.**
  Call it twice and PICO-8 errors; skip it and `dget`/`dset` silently do
  nothing, which looks exactly like a high score that never saves.
- **`dget` on an unwritten slot returns 0, not nil.** Good for a score, a trap
  for anything where 0 is a meaningful value and "never set" is a different
  state — store those offset by one, or keep a separate written flag.
- **A cart data id is global to the machine and permanent.** Every cart on the
  system shares one namespace, so ids want a prefix, and renaming one abandons
  every save written under the old name. Decide it once, before anyone plays.
- **A persistence bug outlives the run that caused it.** Everything else in this
  game resets when the cart reloads; this doesn't. Verifying it takes more than
  one process — see step 11 of §9.
- **Colour numbers:** 0 black, 1 dark blue, 2 dark purple, 3 dark green,
  4 brown, 5 dark grey, 6 light grey, 7 white, 8 red, 9 orange, 10 yellow,
  11 green, 12 blue, 13 indigo, 14 pink, 15 peach.
- **`fillp()` is sticky.** It stays active until reset with a bare `fillp()`.
  Forget once and every later `rectfill` — including the bottom bar — comes out
  dithered. Reset immediately after the draw that needed it, not at the end of
  `_draw()`.
- **`fillp` doesn't touch `spr()` or `print()`.** Dithering in sprites has to be
  drawn by hand in the editor.
- **Black grid lines eat black outlines.** Any two adjacent surfaces that share
  the outline colour will visually merge. This is why the board uses colour 2.
- **`oprint()` shifts your layout.** Text drawn at x is now inked from x-1, so
  anything previously flush against an edge needs a pixel of margin.
- **Never use `repeat … until free` on a filling board.** Rejection sampling has
  no bound once free cells run out. Every "pick a random empty tile" in this
  game goes through `free_cells()`.
- **The starting cell can be boxed in.** `free_neighbor()` returns `c` — the head
  itself — when all four neighbours are doors, walls or off-board. At the
  current wall cap that is two edge doors plus a wall around a border tile:
  `min_door_dist` is 2, so two doors *can* sit either side of an edge cell,
  and its one interior neighbour is wallable. The snake then starts with head
  and tail stacked on one tile, so the fill count is permanently one short and
  the win never fires. Re-roll the start until the tail is a distinct cell
  *and* `trapped()` is false; it always terminates, because the four corners
  can be neither walls (interior only) nor doors (`corner_dist` 0), and a
  corner's two neighbours are border tiles that no wall can reach.
- **`view` stopped being state the moment the toggle went.** It is a cache of
  `snake[1].f`. The movement lock (`if view ~= h.f then return end`) has to
  come out *with* the toggle: with nothing able to desynchronise the two it is
  dead code, and dead code whose failure mode is "silently refuse every input"
  is the worst kind to leave lying around.
- **A minimap of body-coloured blocks needs the body to win ties.** A segment
  can rest on a door tile, and the two want different colours. Draw the door on
  top and the map lies about where your body is — which is the only thing the
  minimap is there to tell you. Wall, then body, then food, then door.
- **`food` can be nil.** Once the board is full there is nowhere to spawn, so
  both `draw_food()` and the `grow` test have to guard for it.
- **`total_cells` is not a constant.** It's `108 - wall_count - 6`, set in
  `new_game()` after `gen_walls()`. Hardcode it and the win either never fires
  or fires early.
- **The food pool and the fill target are one decision, not two.** Exclude a
  kind of tile from `free_cells()` and you must exclude it from `total_cells`
  and from `filled()` as well. Excluding it from only one produces a board that
  can neither spawn food nor declare a win — the door deadlock in §7.2, twice.
- **`#snake` is not the fill.** Segments resting on door tiles are in transit
  and count toward nothing, so the bar and the win check both go through
  `filled()`. `#snake == 2 + score` still holds; `filled() == #snake` does not.
- **A length-2 snake can reverse unless you stop it.** The neck is also the
  tail, so it vacates on the same turn and the "you bit yourself" test — which
  scans `1 .. #snake-1` — never looks at it. Refuse any landing on `snake[2]`
  inside `dest()`, after the door transit, so `trapped()` inherits the rule for
  free. Do *not* implement it as "the pressed direction is the opposite of the
  last one": that also blocks a legal move on the far side of a door, where the
  neck is on the floor you just left.
- **Refusing the bite outright is a soft lock waiting to happen.** Once a bite
  is a refusal rather than a death, the only remaining loss is `trapped()` — so
  a hole in `trapped()` stops being a game that ends early and becomes a game
  that cannot end at all: every direction refused, every press denied, no panel.
  Keep the bite death behind an `if trapped()` guard in `try_move()`. It is
  unreachable while `trapped()` is right, and it is the failure mode's floor
  while it isn't. Test it by building the trapped position by hand and calling
  `try_move()` on it directly — the game itself can never hand you that state.
- **Banning the reversal can strand the start.** Once the neck stops counting
  as a way out, an interior start ringed by three walls is a turn-1 dead end
  that `new_game()` never notices, because `trapped()` is only called after a
  move. Add `not trapped()` to the start re-roll. Dropping the wall cap to 2
  (§7.6) made that unreachable — a trapped start now needs three walls around
  an interior head, or a border head whose border neighbours are all shut,
  and neither is buildable. The guard stays anyway: it is one call, the cap
  is a tuning constant, and what it prevents is a game that is over before
  the first press.
- **The *distinctness* half of that re-roll is still live**, and it is a
  different failure. `free_neighbor()` returns the head itself when all four
  neighbours are doors, walls or off-board — two doors and a wall around an
  edge tile still do it at any wall cap — and the snake then starts with head
  and tail stacked on one tile, so `filled()` is permanently one short and
  the win never fires. Two guards, two causes; deleting the one that went
  quiet does not cover the one that didn't.
- **A body in a doorway has to be refused in `dest()`, not `fatal()`.** The
  head never comes to rest on the door it steps onto — it transits — so the
  only cell `fatal()` ever sees is the far end of the passage. A segment
  standing in the *near* doorway is invisible to every collision test in the
  game, and the snake walks straight through it. The test is
  `occupied(nx, ny, nf)` inside `dest()`, *before* the transit branch, while
  `nf` is still the floor you are standing on. Put it after and you have
  written a slower version of what `fatal()` already does.
- **Refusing a door is a body refusal, and `dest()` only knows how to say no.**
  `dest()` returns `nil` for an edge, a block and the neck, all of which are
  terrain and sound like a bump. A shut doorway is the body saying no and
  wants `sfx_deny`, so `dest()` returns `nil` *plus a flag* — the second
  return, which is `ny` on a successful landing, doubles as the reason there
  isn't one. Keeping the test inside `dest()` is what lets `trapped()` inherit
  it; moving it up into `try_move()` to get the sound right is the drift the
  gotcha above this one warns about.
- **Interior walls can't trap a cell, but they can make a forced run.**
  Connectivity is free (§7.6) and it is not the property you care about. A
  wall diagonally inside a board corner drops both of that corner's
  neighbours to one exit each, and the corner already had two — three cells
  in a row with no way off, which is where a snake dies for a reason the
  player reads as the generator's fault. Exclude those four tiles
  (`corner_dist >= 2`) and keep two walls a clear tile apart.
- **`rnd(t)` hands back the table, not a copy of it.** Picking cells out of a
  prebuilt list and storing the results directly means two floors that roll
  the same tile share one record. Nothing in this game writes to a wall, so
  it is latent — which is exactly how it will be found. Copy on the way in.
- **Test walls before the door transit.** `wall_at(nf, nx, ny)` has to run while
  `nf` is still the current floor. Move it after the transit branch and you'll
  be testing the destination floor for a wall the player never walked into.
- **Every "pick a free tile" needs the wall test too.** `free_cell()`,
  `free_neighbor()` and `free_cells()` all exclude walls; miss one and food
  spawns inside a block, unreachable, and the game silently becomes unwinnable.
- **Test the endgame with a small `total_cells`.** Reaching 95 legitimately
  takes a long time, and the bugs that matter only exist near a full board.
  Cheaper still under `-x`: build the near-full board directly. Assign `snake`
  every free tile but one, put the food on the last one, and step into it —
  that exercises the win check, `filled()`, and the empty-free-list path in
  about a millisecond, and it's how the door accounting above was verified.
- **`music()` has no resume.** It always restarts the pattern from note one, so
  any scheme that switches patterns on a frequent event will audibly jump.
- **Give every SFX in a music pattern the same speed and length.** Mixing them
  makes it ambiguous when the pattern advances; matching them removes the
  question entirely.
- **Don't set loop points on an SFX used in a music pattern.** A looping SFX
  never ends, which can stall the pattern that contains it.
- **Reserved channels aren't absolute.** `music(n, fade, mask)` stops *automatic*
  channel allocation from stealing them, but an explicit `sfx(n, 0)` will still
  cut into channel 0. Pass channel 3 explicitly on every gameplay sound.
