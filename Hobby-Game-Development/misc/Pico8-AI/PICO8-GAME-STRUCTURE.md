# PICO8-GAME-STRUCTURE.md — How to lay out the Lua of a cart

> Scope: how the code is *organised*. For the numbers that make a jump feel right and decide
> which layouts are reachable, see [PICO8-PHYSICS.md](PICO8-PHYSICS.md). For running and
> testing the result, [PICO8-TOOLING.md](PICO8-TOOLING.md).

## File layout
One flat file, in this order. Only top-level *executed* code (particle tables,
`add(types,...)`) is order-sensitive; function bodies may reference later globals.

```
-- ~game title~ / -- author   <- lines 1-2 are drawn onto the cart label
-- globals --        every mutable game-wide value, one per line
-- entry point --    _init, title_screen, begin_game, level_index, is_title
-- effects --        background particle tables, built at load time
-- player entity --  one block per entity type, each followed by add(types,x)
-- object functions -- init_object, destroy_object, kill_player
-- room functions -- restart_room, next_room, load_room
-- update function -- _update
-- drawing functions -- _draw, draw_object
-- helper functions -- clamp, appr, sign, maybe, solid_at, tile_flag_at, tile_at
```
Banner style is `-- name --` over a dash line. Comments cost no tokens — use them freely.

## Globals and game states
Declare all cross-cutting state up front: `room={x=0,y=0}`, `objects={}`, `types={}`,
`freeze=0`, `shake=0`, `will_restart`, `delay_restart`, `sfx_timer`, plus named buttons
(`k_jump=4`). No state-machine object: screens are functions that reset globals and call
`load_room`, with `level_index()` / `is_title()` as predicates. **The menu is a level** —
one code path draws everything, `is_title()` gates the differences.

## Entity types
A type is a plain table of callbacks taking the instance as `this` (an explicit parameter —
no `self`, no `:` calls, no metatables).
```lua
spring = {
  tile=18,            -- map tile that auto-spawns it in load_room (optional)
  if_not_fruit=true,  -- optional spawn condition checked in init_object
  init=function(this) this.hide_in=0 end,
  update=function(this)
    local hit=this.collide(player,0,0)
    if hit~=nil and hit.spd.y>=0 then hit.spd.y=-3 end
  end }        -- omit draw to get the default spr(this.spr,...)
add(types,spring)
```
Types with no `tile` (smoke, orb, platform) stay out of `types` and are spawned by code.
Behaviour another type triggers goes in a free function beside it (`break_fall_floor(obj)`).

## The object factory
`init_object(type,x,y)` allocates the instance, sets the common fields — `collideable`,
`solids`, `spr=type.tile`, `flip`, `x/y`, `hitbox={x,y,w,h}` (an **offset** from x/y),
`spd`, `rem` — attaches the closures `is_solid / collide / check / move / move_x / move_y`,
`add(objects,obj)`, calls `type.init(obj)`, and **returns obj** so callers can finish inline:
`init_object(platform,tx*8,ty*8).dir=-1`. `destroy_object` is `del(objects,obj)`.

**Sub-pixel movement:** accumulate fractions in `rem`, then move whole pixels.
```lua
obj.rem.x+=ox  local amount=flr(obj.rem.x+0.5)  obj.rem.x-=amount  obj.move_x(amount,0)
```
`move_x`/`move_y` step **one pixel at a time, x and y separately**, zeroing `spd`/`rem` on
contact. That separation is what makes wall-slides and corners feel right.

This is one of two viable collision models. The cheaper alternative — move the full delta,
then snap out of the overlapped tile — saves tokens and is fine while no single frame crosses
a whole tile, but its resolve formulas are an off-by-one minefield. Pick deliberately;
[PICO8-PHYSICS.md](PICO8-PHYSICS.md) has both, with the exact snap arithmetic.

**Collision:** `obj.collide(type,ox,oy)` is a rect-overlap scan over `objects` returning the
other object or nil; the offset asks "would I touch X if I moved here?". O(n²) is fine at
this scale. `collideable=false` makes an entity intangible without destroying it.

**Terrain** is read through sprite flags, never a tile list: `tile_flag_at(x,y,w,h,flag)`
loops the covered 8×8 cells calling `fget(tile_at(i,j),flag)`; `solid_at` is flag 0, `ice_at`
flag 4. The same flag byte is the `layers` mask for `map()` (4 bg, 2 terrain, 8 fg).

## Rooms
The map is a grid of 16×16-tile screens; `room` is a window, not a copy. `load_room(x,y)`
resets per-room flags, `foreach(objects,destroy_object)` (safe — `foreach` tolerates
deletion), sets `room.x/y`, then scans `tx,ty=0..15` calling `mget(room.x*16+tx,...)` and
spawning any `type.tile==tile`. Entities live in **room space 0..127** (`tx*8`), so `map()`
draws at the screen origin and no camera math is needed. Restart is deferred
(`will_restart=true delay_restart=15`) so the death animation plays.

**If you consume map tiles with `mset`** — the simplest way to do pickups, breakable blocks
or one-shot triggers — the map in RAM is now permanently altered, and restarting the room
will not bring them back. Restore it from cart ROM:

```lua
reload(0x2000,0x2000,0x1000)   -- map rows 0..31, straight from the .p8 on disk
```

Call it at the top of your restart/newgame function. Two constraints: `reload` reads the
**cart file**, so it only works on a saved cart (and a test harness needs its own copy of the
asset sections); and `reload`/`cstore` are capped at **64 calls per cycle**, so reset once per
restart, never per frame. The alternative — spawning pickups as objects at load and never
touching the map — costs more tokens but avoids the whole issue.

## `_update` — fixed order
1. Bump/wrap counters (`frames=(frames+1)%30`) — never let a frame counter overflow.
2. Tick `music_timer`, `sfx_timer`.
3. `if freeze>0 then freeze-=1 return end` — hit-stop skips the whole frame.
4. Screenshake: `shake-=1 camera() if shake>0 then camera(-2+rnd(5),-2+rnd(5)) end`.
5. Deferred restart countdown.
6. `foreach(objects,function(obj) obj.move(obj.spd.x,obj.spd.y) ... type.update(obj) end)` —
   the loop applies physics, the type only does behaviour.
7. Global transitions (title → game) last.

## `_draw` — explicit layering, no z-sort
`if freeze>0 then return end`, then `pal()`, bg fill, clouds, `map(...,4)` bg terrain,
objects that sit behind terrain, `map(...,2)` terrain, all other objects via `draw_object`,
`map(...,8)` fg terrain, particles, four `rectfill`s outside 0..127 to mask the screenshake
camera offset, HUD last. `draw_object` calls `type.draw` or falls back to `spr`.

## Idioms
- **`appr(val,target,amount)`** — the workhorse: acceleration, friction, gravity, easing.
- **Coyote time / input buffer** as integer counters (`grace=6`, `jbuffer=4`, decrement each frame).
- **Edge-triggered input**: `local jump=btn(k_jump) and not this.p_jump  this.p_jump=btn(k_jump)`.
- **Input as a number**: `btn(k_right) and 1 or (btn(k_left) and -1 or 0)`, multiplied into speed and facing.
- **Integer state machines**: `this.state` 0/1/2 plus a `this.delay` countdown.
- **Animation from a float**: `this.spr_off+=0.25  this.spr=1+this.spr_off%4` — `spr` floors it;
  bobbing is `this.y=this.start+sin(this.off/40)*2.5` (sin is inverted, 0..1 per turn).
- **Juice = three globals**: `freeze`, `shake`, and a `smoke` puff on every state change.
- **Cosmetic particles** are plain tables built once and updated in `_draw`, never in `objects`.
- **Token economy**: one generic factory + type tables, flags over tile comparisons, the
  `tile` registry so level design is a map edit. Comments/`local`/`end`/`,` are free.

## Gotchas
- `this` is a parameter; never `obj:update()`.
- Deleting inside `foreach` is safe; inside `for i=1,count(objects)` it is not.
- `hitbox` is an offset — forgetting to add it is the classic off-by-8. Types that grow it
  temporarily must restore it in the same function.
- Logic in `draw` is skipped entirely while `freeze>0`. Keep logic in `update`.
- Celeste's `kill_player` calls `restart_room()` inside its 8-iteration particle loop; it
  only works because the call is idempotent. Put it after the loop.
