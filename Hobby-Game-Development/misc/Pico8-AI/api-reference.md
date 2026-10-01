# PICO-8 API Reference

Every callable function, with signature, defaults and return value. `[x=d]` = optional, default `d`.
`→` marks the return value; no `→` means the function returns nothing useful.

## Callbacks (you define, PICO-8 calls)
- `_init()` once at boot · `_update()` 30fps · `_update60()` 60fps · `_draw()` once per visible frame
- `flip()` — push buffer to screen, wait for next frame. Only needed when you define no `_draw`.

## Graphics
- `cls([col=0])` — clear screen, reset clip region
- `camera([x=0],[y=0])` → previous `x,y`. Subtracted from all draw coords.
- `clip([x,y,w,h],[clip_previous])` → previous `x,y,w,h`. No args = full screen.
- `color([col=6])` → previous colour. Sets the default draw colour.
- `pset(x,y,[col])` · `pget(x,y)` → colour 0..15
- `sset(x,y,[col])` · `sget(x,y)` → colour. Sprite-sheet pixel coords 0..127.
- `line(x0,y0,[x1,y1],[col])` — omitting `x1,y1` continues from the last endpoint
- `rect(x0,y0,x1,y1,[col])` · `rectfill(x0,y0,x1,y1,[col])` — inclusive corners
- `circ(x,y,r,[col])` · `circfill(x,y,r,[col])`
- `oval(x0,y0,x1,y1,[col])` · `ovalfill(x0,y0,x1,y1,[col])` — bounding box, not centre+radius
- `spr(n,x,y,[w=1],[h=1],[flip_x],[flip_y])` — `n` 0..255, `w/h` in 8px sprite units
- `sspr(sx,sy,sw,sh,dx,dy,[dw=sw],[dh=sh],[flip_x],[flip_y])` — stretched blit from the sheet
- `pal([c0],[c1],[p=0])` — remap `c0`→`c1`; `p` 0 draw / 1 display / 2 secondary. `pal(tbl,[p])` for many at once; `pal()` resets.
- `palt([c],[t])` — set colour `c` transparent (`t=true`). `palt()` resets to "only 0 transparent". `palt(bitfield)` sets all 16 at once.
- `fillp([pat=0])` → previous pattern. 16-bit fill mask applied to shape/print fills.
- `print(str,[x],[y],[col])` → rightmost x reached. Without `x,y` prints at the cursor and scrolls.
- `cursor([x],[y],[col])` → previous `x,y`. Sets where bare `print` writes.
- P8SCII escapes inside strings: `\f7` fg colour · `\#c` bg colour · `\^w` wide · `\^t` tall · `\^i` invert · `\n` newline
- Character widths: plain ASCII is **4px**; the button glyphs `⬅️ ➡️ ⬆️ ⬇️ 🅾️ ❎` are **8px** but still count as **1** to `#`/`sub`. So `#s*4` only estimates width for pure ASCII — for mixed strings, centre text using `print`'s returned x (draw once off-screen, or subtract after).

## Map
- `map(tx,ty,[sx=0],[sy=0],[tw],[th],[layers])` — draw map tiles `tx,ty` to screen `sx,sy`; `layers` = sprite-flag bitmask (only tiles with all those flags draw). Sprite 0 is never drawn.
- `mget(x,y)` → sprite index at tile `x,y` · `mset(x,y,[v=0])`
- `fget(n,[f])` → bool for flag `f`, or the whole 0..255 bitfield if `f` omitted
- `fset(n,[f],v)` — set flag `f` to bool `v`, or the whole bitfield when `f` omitted
- `tline(x0,y0,x1,y1,mx,my,[mdx=1/8],[mdy=0],[layers])` — line textured from map space; `mx,my` advances by `mdx,mdy` per pixel

## Input
- `btn([b],[pl=0])` → bool if `b` given, else a bitfield of all buttons held
- `btnp([b],[pl=0])` → same, but only on the press frame; auto-repeats after 15 frames, then every 4
- Buttons: `0` left `1` right `2` up `3` down `4` O `5` X. Players `0..7`. Call from `_update`/`_update60`.
- Devkit mouse/keyboard: `poke(0x5f2d,1)` then read `stat(30..39)`. Keep optional in shared carts.

## Audio
- `sfx(n,[channel=-1],[offset=0],[length])` — `channel` -1 auto-pick, -2 stop that sfx; `n=-1` stops all; `n=-2` releases loop
- `music(n,[fade_len=0],[channel_mask=0])` — `n=-1` stops; mask reserves channels from `sfx`

## Math
- `max(a,b)` · `min(a,b)` · `mid(a,b,c)` → the middle of three · `abs(x)` · `sgn(x)` → ±1 (`sgn(0)`=1)
- `flr(x)` → round toward -∞ · `ceil(x)` → round toward +∞ · `sqrt(x)` (negative → 0)
- `rnd([x=1])` → 0 ≤ n < x; if `x` is a table, → a random element. `flr(rnd(n))` for a random integer 0..n-1.
- `srand([s=0])` — seed the generator
- `cos(a)` · `sin(a)` — `a` is 0..1 for a full turn, and **`sin` is inverted** (screen y grows downward)
- `atan2(dx,dy)` → angle 0..1, also y-inverted
- Bitwise fns: `band bor bxor bnot shl shr lshr rotl rotr` (operators `& | ^^ ~ << >> >>>` are cheaper in tokens)

## Strings & values
- `#str` → length · `..` concat · `sub(str,from,[to=-1])` → substring (negative indexes count from the end)
- `chr(n,...)` → string from character codes · `ord(str,[i=1],[n=1])` → `n` character codes starting at `i`
- `tostr(v,[fmt])` → string; `fmt=true` for hex. `tonum(v,[fmt])` → number or `nil` if unparseable.
- `split(str,[sep=","],[convert=true])` → table; `sep` as a number splits into fixed-width chunks
- `type(v)` → "nil"/"boolean"/"number"/"string"/"table"/"function"/"thread"
- `pack(...)` → table with `.n` · `unpack(t,[i=1],[j=#t])` → the elements as multiple values

## Tables
- `add(t,v,[i])` → `v` — append, or insert at index `i`
- `del(t,v)` → the deleted value — removes the **first match by value**
- `deli(t,[i=#t])` → the removed value — removes by index
- `count(t,[v])` → length, or the number of elements equal to `v`
- `all(t)` → iterator for `for v in all(t) do`; deleting the current element mid-loop is safe
- `foreach(t,f)` — calls `f(v)` for each element, starting at `t[1]`
- `pairs(t)` → `k,v` iterator over all keys, including non-integer ones

## Coroutines
- `cocreate(f)` → coroutine · `coresume(c,...)` → `ok, ...` (`ok=false` plus the error on failure)
- `costatus(c)` → "running" / "suspended" / "dead" · `yield(...)` — suspend, passing values back to `coresume`

## Memory & persistence
- `peek(addr,[n=1])` → up to n bytes as multiple values · `poke(addr,...)` writes consecutive bytes
- `peek2/poke2` 16-bit · `peek4/poke4` 32-bit (a full 16:16 fixed-point number)
- `memcpy(dst,src,len)` · `memset(dst,val,len)`
- `reload(dst,src,len,[cart])` — copy from cart ROM (another cart's, if named) into RAM
- `cstore(dst,src,len,[cart])` — write RAM back to the cart file
- `cartdata(id)` → `true` if this save slot is newly created. Call once; `id` must be globally unique.
- `dget(i)` → saved number · `dset(i,v)` — `i` is 0..63
- Map: gfx `0x0` · shared gfx/map `0x1000` · map `0x2000` · flags `0x3000` · sfx `0x3200` · music `0x3100` · screen `0x6000`

## System
- `t()` / `time()` → seconds since cart start (wraps after ~9.1 hours)
- `stat(n)` → system info: `0` mem KB · `1` CPU (1.0 = full frame) · `4` clipboard · `6` cart param · `7` target fps · `16..19` sfx playing per channel · `20..23` note index · `24` music pattern · `30` key waiting / `31` key char · `32,33` mouse x,y · `34` mouse buttons · `36` wheel · `80..85` UTC date/time · `90..95` local date/time
- `menuitem(i,[label],[cb])` — pause-menu entry, `i` 1..5; omit `label` to remove. `cb(b)` receives the button bitfield.
- `printh(str,[filename],[overwrite])` — print to the host console (or a file) for debugging
- `assert(cond,[msg])` → cond · `stop([msg])` — break to the console · `trace([coro],[msg])` → stack traceback string
- `extcmd(cmd)` — host command: "pause", "reset", "shutdown", "screen", "rec", "video", "audio_rec", "label"
- `run([param])` restarts the cart · `reset()` restores draw/audio state to defaults
