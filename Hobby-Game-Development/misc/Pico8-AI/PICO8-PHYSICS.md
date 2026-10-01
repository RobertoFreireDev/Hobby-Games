# PICO8-PHYSICS.md — Platformer physics and the geometry it implies

**The point of this doc:** your gravity and jump constants silently decide which level
layouts are possible. Pick them first, read the reachability off the table, and design the
map to that vocabulary. Doing it the other way round produces levels that look fine in the
editor and are impossible to play.

All numbers assume `_update` at **30fps**. For `_update60`, halve the accelerations and
speeds (`grav/2`, `jmp/2`, `acc/2`, `mxs/2`) to keep the same arc in world units.

---

## The arc

```lua
grav=0.35   jmp=-4.8   acc=0.5   mxs=2
-- friction: dx *= 0.8 on the ground, 0.93 in the air
-- terminal fall speed: 4
```

Per frame, in this order:

```lua
if ax!=0 then p.dx+=ax*acc end
p.dx*=p.gr and 0.8 or 0.93
p.dx=mid(-mxs,p.dx,mxs)
-- jump goes here (see coyote/buffer below)
if p.dy<-1 and not btn(k_jump) then p.dy=-1 end  -- variable height
p.dy=min(p.dy+grav,4)
```

Ground friction of `0.8` with `acc=0.5` settles at exactly `0.5*0.8/0.2 = 2` px/frame, so
`mxs=2` is the natural cap rather than an arbitrary clamp — keep them consistent if you
retune.

**Do not use the closed form** `apex = jmp²/(2·grav)` for anything tight. It says 32.9px for
the constants above; the discrete simulation gives **30.5px**, ~7% lower, because the first
frame applies gravity before the position update. That 2.4px difference is the whole margin
on a 3-tile jump. Use the table.

## Reachability table

Apex is measured from a standing start at full run speed, jump held. "Max step" is the
tallest platform you can *reliably* land on — `flr((apex-4)/8)` tiles, keeping a 4px margin
for the sub-pixel snap.

| jmp | grav | apex px | airtime | range px | range tiles | max step |
|---|---|---|---|---|---|---|
| -4.2 | 0.35 | 23.1 | 23 | 46 | 5.75 | **2 tiles** |
| -4.4 | 0.32 | 28.1 | 27 | 54 | 6.75 | 3 tiles |
| -4.4 | 0.35 | 25.5 | 25 | 50 | 6.25 | 2 tiles |
| -4.6 | 0.32 | 30.8 | 28 | 56 | 7.00 | 3 tiles |
| -4.6 | 0.35 | 28.0 | 26 | 52 | 6.50 | 2 tiles |
| **-4.8** | **0.35** | **30.5** | **27** | **54** | **6.75** | **3 tiles** |
| -4.8 | 0.32 | 33.6 | 30 | 60 | 7.50 | 3 tiles |
| -4.8 | 0.40 | 26.4 | 24 | 48 | 6.00 | 2 tiles |
| -5.0 | 0.35 | 33.3 | 28 | 56 | 7.00 | 3 tiles |
| -5.2 | 0.32 | 39.7 | 32 | 64 | 8.00 | 4 tiles |

The bold row is the recommended default and is **verified against the real engine**
(`pico8 -x` reported `APEX=30.5507`). The rest come from a simulation that matches the
engine at that point.

### Read this row as a design brief

`jmp=-4.8, grav=0.35` gives you:

- **A 3-tile (24px) step up is reachable**, with 6.5px to spare.
- **A 4-tile (32px) step is not.** This is a feature — it is the wall you build with.
- **A gap up to 6 tiles (48px) clears** on a flat run-jump; 6.75 tiles is the true limit, so
  6 is the largest gap you should ship.
- **Never put a platform above row 4.** A player standing on row 4 (`y=32`) apexes at
  `y=1.5`; on row 3 they leave the top of the screen. Cap platforms at row 5 for a
  non-scrolling 16-row level.

Two mistakes this table exists to prevent, both of which look fine in the map editor:
shipping `-4.2/0.35` (apex 23.1px) while the level uses 3-tile steps needing 24px — every
one unreachable by 0.9px — and building 4- and 5-tile staircases that no constant in the
usable range can climb.

### Variable jump height

Releasing the button clamps `dy` to `-1`. Hold time maps to apex like this (`-4.8/0.35`):

| hold | 1f | 2f | 4f | 6f | 8f | 12f+ |
|---|---|---|---|---|---|---|
| apex | 5.4 | 9.5 | 16.7 | 22.4 | 26.8 | 30.5 |

A 6-frame tap gets 22.4px — just under a 3-tile step. That is the gap between a "careful"
and a "committed" jump, and it is what makes held-jump platforming feel expressive.

---

## Collision: two models, pick one deliberately

### A. Pixel stepping (Celeste-style, what PICO8-GAME-STRUCTURE.md prescribes)

Accumulate sub-pixel movement in `rem`, then step **one pixel at a time**, x and y
separately, zeroing speed on contact. More tokens, but immune to off-by-one errors and it
is what makes wall-slides and corner behaviour feel right. **Prefer this unless tokens are
tight.**

### B. Move-and-snap (cheaper)

Move the full delta, then snap out of any tile you overlap. Only valid while
`|dx| < 8` and `|dy| < 8` — a single frame must never cross a whole tile. With
`mxs=2` and terminal fall `4`, that holds.

With hitbox offset `hx=1, hy=1, hw=6, hh=7` (so occupied pixels are `x+1..x+6` and
`y+1..y+7`, feet exclusive at `y+8`):

```lua
-- x, after p.x+=p.dx
if hit(p.x,p.y) then
 if p.dx>0 then p.x=flr((p.x+6)/8)*8-7      -- rightmost pixel is x+6
 else          p.x=(flr((p.x+1)/8)+1)*8-1   -- leftmost pixel is x+1
 end
 p.dx=0
end

-- y, after p.y+=p.dy
if hit(p.x,p.y) then
 if p.dy>0 then p.y=flr((p.y+7)/8)*8-8  p.gr=true
 else          p.y=(flr((p.y+1)/8)+1)*8-1
 end
 p.dy=0
end
```

Derive these rather than copying blind if you change the hitbox: the constant after `flr` is
the *last occupied pixel* on that side, and the trailing subtraction converts the tile
boundary back to a sprite origin. Getting one wrong gives a player who sinks 1px into
floors or sticks 1px off walls — visible, and easy to misread as a drawing bug.

```lua
function hit(x,y)
 for i=flr((x+1)/8),flr((x+6)/8) do
  for j=flr((y+1)/8),flr((y+7)/8) do
   if fget(mget(i,j),0) then return true end
  end
 end
end
```

**Use a tighter box for hazards than for solids.** Testing spikes with the full hitbox kills
the player for standing in the adjacent tile. `x+2..x+5, y+3..y+7` reads as fair.

## Coyote time and input buffering

Non-negotiable for anything with a jump; both are integer counters.

```lua
if btnp(4) or btnp(5) then p.buf=6 end   -- buffer: jump pressed slightly early
if p.buf>0 then p.buf-=1 end
if p.coy>0 then p.coy-=1 end
if p.buf>0 and p.coy>0 then              -- fire
 p.dy=jmp p.buf=0 p.coy=0 p.gr=false
end
...
if p.gr then p.coy=6 end                 -- refresh every grounded frame
```

6 frames each at 30fps. Set `p.coy=6` at spawn too, or the first frame of the game eats a
jump press.

---

## Verify the level, don't eyeball it

A level is a claim that every objective is reachable. Check it. Port `domove()` and `hit()`
to a script (see [PICO8-TOOLING.md](PICO8-TOOLING.md) — Node is the available runtime), then
flood the level:

1. Start from the spawn tile as the only known standing position.
2. From each known position, simulate jumps across the input space — run speed
   `-2..2` × air steering `-1/0/1` × hold `1..24` frames — plus plain walks off ledges.
3. Record every landing as a new standing position; record every coin/objective tile the
   *trajectory* overlaps, not just the landings.
4. Repeat to a fixed point. Anything unvisited is unreachable.

A level that reads as completely reasonable in ASCII art can still strand a quarter of its
pickups behind a step 1px too tall — this sweep is what catches that. Validate the port by
comparing one measured apex against `pico8 -x` before trusting its verdict.

## Gotchas

- Sprite `0` must not carry the solid flag — `mget` returns `0` for out-of-bounds tiles, so a
  solid sprite 0 walls off the entire outside of the map.
- `p.x`/`p.y` stay fractional between snaps. Always `flr` before converting to tile coords;
  never compare positions for equality.
- Clamp x to the level (`mid(0,p.x,lvlw*8-8)`) *before* the collision test, or the resolve
  step can push the player back inside from out of bounds.
- Falling off the bottom needs an explicit kill (`if p.y>136`), otherwise the player
  accelerates forever at terminal velocity in empty space.
- A player standing exactly on a tile boundary is not overlapping it. Off-by-one bugs here
  read as "sometimes I can jump, sometimes I can't."
