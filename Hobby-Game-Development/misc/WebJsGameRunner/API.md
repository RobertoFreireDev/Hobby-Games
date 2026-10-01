# API Reference

Everything `game.js` is allowed to use. The engine passes a single `api` object into
each lifecycle function; there is no other global.

Conventions used below:

- **Colors** — either a palette index `0–15` or a `"#rrggbb"` string.
- **Coordinates** — logical pixels, origin top-left, affected by `api.camera`.
- **Names** — the keys you declared in `assets.js`.
- Angles are **radians**, standard direction (not PICO-8's flipped turns).

---

## Lifecycle

`game.js` defines exactly these three globals. All are optional except `draw`.

```js
function init(api)   { }   // once, after every asset is loaded and decoded
function update(api) { }   // fixed 60 Hz, may run 0..5 times per frame
function draw(api)   { }   // once per rendered frame
```

Allocate everything you need in `init`. Never allocate in `update`/`draw`.

---

## Assets (`assets.js`)

Not an api call — a plain declaration the engine reads before anything else.

```js
const ASSETS = {
  screen: { w: 640, h: 360, bg: 0 },         // logical resolution + clear color
  palette: null,                             // null = PICO-8 16, or ["#000000", ...]
  images:  { hero: "assets/img/hero.png",
             tiles: "assets/img/tiles.png" },
  sfx:     { jump: "assets/sfx/jump.wav",
             hit:  "assets/sfx/hit.wav" },
  music:   { theme: "assets/music/theme.ogg" },
  text:    { family: "monospace", size: 8, color: 7 }   // default print style
};
```

Add a file here and it is preloaded, decoded and reachable by name. That is the only
way an asset enters the game.

---

## System

| Call | Returns | Notes |
|---|---|---|
| `api.w()` | number | Logical screen width |
| `api.h()` | number | Logical screen height |
| `api.dt()` | number | Fixed step, always `1/60` |
| `api.time()` | number | Seconds since `init()` |
| `api.frame()` | number | Update steps elapsed (integer) |
| `api.fps()` | number | Measured frames per second, for debug overlays |
| `api.mobile()` | boolean | `true` on a touch-primary device — see below |

### `api.mobile()`

Constant for the whole session. `true` when the engine decides the player has no
keyboard and no mouse: the device must report touch points, and must *not* also
report a fine, hovering pointer (that rules out touchscreen laptops, which get the
desktop controls). It answers one question — *should the game put its controls on
the screen?* — not "is this a phone".

```js
function init(api) {
  touchUi = api.mobile();
  if (touchUi) setupPad(api);        // bake the on-screen buttons once
}
```

Append `?mobile=1` (or `?mobile=0`) to the url to force it either way. That is the
way to check the touch layout from a desktop browser — including inside
`tools/embed.html`, where the query string goes on the iframe's own url.

---

## Graphics

Called from `draw` only. Drawing from `update` is undefined behaviour.

### Clearing and framing

| Call | Description |
|---|---|
| `api.cls(col?)` | Clear the screen. Defaults to `screen.bg`. Ignores `camera`. |
| `api.camera(x?, y?)` | Offset all subsequent draws by `-x, -y`. No args resets to `0,0`. |
| `api.clip(x?, y?, w?, h?)` | Restrict drawing to a rectangle. No args resets to full screen. |

`clip` is the one call in **screen space**: it is not moved by `camera`, so a HUD
strip stays clipped where you put it while the world shakes underneath. Both
`camera` and `clip` persist across frames until you reset them.

### Sprites

```js
api.spr(name, x, y, opts?)
```

Draw a whole image asset with its top-left at `x, y`.

```js
api.sspr(name, sx, sy, sw, sh, dx, dy, dw?, dh?, opts?)
```

Draw the `sw × sh` region at `sx, sy` of the image into `dw × dh` at `dx, dy`.
`dw/dh` default to `sw/sh`. This is the call to use with a packed spritesheet.

`opts` is an optional object — **reuse one preallocated object**, don't build a
literal per call:

| Key | Default | Meaning |
|---|---|---|
| `fx` | `false` | Flip horizontally |
| `fy` | `false` | Flip vertically |
| `rot` | `0` | Rotation in radians, around the destination center |
| `a` | `1` | Alpha, `0–1` |

Rotation and alpha are noticeably slower than a plain blit; skip `opts` entirely
when you don't need it.

### Recoloring

```js
api.recolor(name, src, sx, sy, sw, sh, from, to)
```

Copy the `sw × sh` region at `sx, sy` of image `src`, swap colors in the copy, and
keep the result as a new image asset called `name`. `from` and `to` are a color
(palette index or `"#rrggbb"`) or two arrays of the same length; every pixel
matching `from[k]` becomes `to[k]`, the first match wins, and fully transparent
pixels are left alone. Matching allows ±8 per channel, so ordinary pixel art with
a fixed palette hits exactly and nothing else does.

**Call this from `init()` only** — it allocates a canvas and reads the pixels
back. It is how one sheet cell becomes a whole set of team colors or state
variants, with no extra png and no per-frame cost:

```js
function init(api) {
  api.recolor("ship_empty", "sprites", 0, 0, 16, 16, 12, 6);    // blue hull -> light grey
}
function draw(api) {
  api.spr(charges > 0 ? "ship" : "ship_empty", x, y);
}
```

The new image is exactly the requested region, so draw it with `spr` (or `sspr`
from `0, 0`), not with the source sheet's coordinates. The name shares the
namespace with `ASSETS.images` and `prerender`.

### Pre-rendering

```js
api.prerender(name, w, h, fn)
```

Draw once into an offscreen `w × h` canvas and keep the result as an image asset
called `name`, usable from then on with `spr` / `sspr`. Inside `fn(api)` every
graphics call works exactly as usual, with `camera` reset and the origin at the
top-left of the new canvas.

**Call this from `init()` only** — it allocates a canvas, and it swaps the render
target while `fn` runs. It is how a static background, a tile map or a block of
never-changing text becomes a single blit per frame instead of hundreds of draw
calls:

```js
function init(api) {
  api.prerender("backdrop", api.w(), api.h(), paintBackdrop);   // once
}
function draw(api) {
  api.spr("backdrop", 0, 0);                                    // every frame
}
```

The name shares the namespace with `ASSETS.images`, so pre-rendering over an
existing image name replaces it.

### Shapes

| Call | Description |
|---|---|
| `api.pset(x, y, col)` | Single pixel |
| `api.line(x0, y0, x1, y1, col)` | Line |
| `api.rect(x, y, w, h, col)` | Rectangle outline |
| `api.rectfill(x, y, w, h, col)` | Filled rectangle |
| `api.circ(x, y, r, col)` | Circle outline |
| `api.circfill(x, y, r, col)` | Filled circle |
| `api.oval(x, y, w, h, col)` | Ellipse outline inscribed in the rectangle |
| `api.ovalfill(x, y, w, h, col)` | Filled ellipse inscribed in the rectangle |

`oval` / `ovalfill` take the same arguments as `rect` / `rectfill` — a bounding box,
not a center and radius. The ellipse touches all four edges of that box, so
`api.oval(x, y, d, d, col)` is the same shape as
`api.circ(x + d / 2, y + d / 2, d / 2, col)`. Use them for anything wider than it is
tall: shadows, health bars, planets, squashed jump poses.

### Text

Text is drawn with the browser's own font rasterizer (canvas `fillText`) — there is
no bitmap font sheet and no font asset. Family, size and color are ordinary CSS
values.

| Call | Description |
|---|---|
| `api.print(str, x, y, col?, size?)` | Draw text. `col`/`size` override the current style for this call only |
| `api.font(family?, size?)` | Set the current font. No args resets to the `ASSETS.text` defaults |
| `api.text_color(col)` | Set the default print color |
| `api.text_align(h?, v?)` | `h`: `"left"` (default) / `"center"` / `"right"`. `v`: `"top"` (default) / `"middle"` / `"bottom"` |
| `api.text_width(str)` | Measured width in logical pixels, using the current font |
| `api.text_height()` | Line height of the current font in logical pixels |

```js
api.font("monospace", 8);
api.print("SCORE " + score, 2, 2, 7);

api.font("Georgia, serif", 16);
api.text_align("center", "middle");
api.print("GAME OVER", api.w() / 2, api.h() / 2, "#ff004d");
```

`x, y` is the anchor point, positioned according to `text_align`. Font state
persists until changed, like `camera` and `clip`; set it in `init()` if it never
varies.

Only fonts already present on the player's machine are safe — generic families
(`monospace`, `sans-serif`, `serif`) and common system stacks. Never reference a
webfont from a CDN; it won't load reliably inside the itch iframe.

Text is rasterized into the logical-resolution buffer and then scaled up with the
rest of the frame. At the default 640×360 that's close to 1:1 on most screens, so
type stays readable — but if you drop `screen.w/h` down to a PICO-8-sized 128×128,
a 6px font is genuinely 6 pixels tall and will look chunky. Raise the logical
resolution rather than adding a second canvas for text.

`fillText` is measurably slower than a sprite blit. Don't redraw large blocks of
text every frame; pre-render static text once into the offscreen background canvas
in `init()`.

---

## Audio

Two independent buses: **sfx** (many overlapping voices) and **music** (one track).
Every call is sample-accurate and returns immediately — no decode, no fetch, no
delay, because everything was decoded at load time.

### Sound effects

```js
const id = api.sfx(name, opts?)
```

Start a sound. Returns a **voice id** (number) you can use to control that one
instance, or `-1` if all voices are busy (32 concurrent by default; oldest is
recycled).

`opts`:

| Key | Default | Meaning |
|---|---|---|
| `vol` | `1` | Volume `0–1` |
| `rate` | `1` | Playback rate / pitch |
| `loop` | `false` | Loop until stopped |
| `pan` | `0` | `-1` left … `1` right |

| Call | Description |
|---|---|
| `api.sfx_stop(id?)` | Stop one voice; no args stops all sfx |
| `api.sfx_pause(id)` | Pause a voice, keeping its position |
| `api.sfx_resume(id)` | Resume a paused voice from where it stopped |
| `api.sfx_playing(id)` | `true` if that voice is still sounding |
| `api.sfx_vol(v)` | Master sfx volume `0–1` |

### Music

| Call | Description |
|---|---|
| `api.music(name, opts?)` | Play a track. `opts`: `{ vol, loop = true, fade, sync }` (fade in seconds) |
| `api.music_stop(fade?)` | Stop, optionally fading out over `fade` seconds |
| `api.music_pause()` | Pause at the current position |
| `api.music_resume()` | Resume from that exact position |
| `api.music_playing()` | Name of the current track, or `null` |
| `api.music_vol(v)` | Master music volume `0–1` |

Starting a new track while one plays crossfades if `fade` is set, otherwise cuts.

**`sync: true`** starts the new track at the position the old one had reached
(`% duration`) instead of at 0. Cut two tracks from the same grid — same length,
same tempo, same chord under every beat — and swapping between them mid-loop
never drops the beat or changes key: the player hears the arrangement thicken,
not the song restart. With a short `fade` (0.3–0.5 s) the change is seamless.
Swapping while paused keeps it paused, so `music_resume()` continues in the new
track at the same spot.

```js
// same 8s loop, four arrangements — layer up as the pressure rises
var m = { vol: 0.55, loop: true, fade: 0.4, sync: true };
if (api.music_playing() !== track) api.music(track, m);
```

The four `theme*` tracks that ship with this repo are built that way — one tune
at four intensities, rendered by `tools/music.js` (a dev script; run
`node tools/music.js` to rebuild the wavs). Anything written to the same 8 s /
120 BPM / A-minor grid drops straight in.

> The engine creates and unlocks the `AudioContext` inside the player's first
> click, and every buffer is decoded before `init()` runs. Audio is therefore
> already live on the first line of `init()` — there is nothing to handle in
> `game.js`. If a browser refuses audio entirely, every audio call becomes a
> no-op (`api.sfx` returns `-1`) and the game keeps running.

Any format the browser can decode works — `.ogg`, `.mp3`, `.wav`, `.m4a`. Ogg is
the smallest for music; short sfx are usually fine as `.wav`.

---

## Input

Single player. All input state is sampled once per fixed update, so `*_p` and `*_r`
are true for exactly one `update` call.

### Buttons

| Index | Key |
|---|---|
| `0` | ← Left |
| `1` | → Right |
| `2` | ↑ Up |
| `3` | ↓ Down |
| `4` | Z |
| `5` | X |
| `6` | C |
| `7` | V |
| `8` | Enter (start / pause) |

| Call | Returns |
|---|---|
| `api.btn(i)` | `true` while the button is held this frame |
| `api.btnp(i)` | `true` on the frame it went down (no auto-repeat) |
| `api.btnr(i)` | `true` on the frame it came up |
| `api.start()` | Same as `api.btn(8)` — Enter held |
| `api.startp()` | Same as `api.btnp(8)` — Enter pressed this frame |
| `api.startr()` | Same as `api.btnr(8)` — Enter released this frame |

```js
if (api.btn(0)) x -= 2;
if (api.btnp(4)) api.sfx("jump");
if (api.startp()) paused = !paused;              // enter toggles pause
```

Enter is button `8` and also has the named `start*` aliases, since a start/pause key
usually reads better by name than by index. The key that dismisses the start overlay
is swallowed by the engine, so pressing Enter to begin never shows up as
`api.startp()` on the first update.

### Mouse

Positions are in logical pixels, already unscaled and letterbox-corrected, and are
clamped to the screen. Buttons: `0` left, `1` middle, `2` right.

| Call | Returns |
|---|---|
| `api.mx()` | Cursor x |
| `api.my()` | Cursor y |
| `api.mbtn(b)` | `true` while held |
| `api.mbtnp(b)` | `true` on the frame it was pressed |
| `api.mbtnr(b)` | `true` on the frame it was released |
| `api.mwheel()` | Scroll delta this frame, `0` if none |
| `api.mouse_over()` | `true` if the cursor is inside the canvas |

Right-click is delivered as button `2`; the context menu is suppressed by the engine.

A touch is also reported through the mouse calls (a tap is a `mbtnp(0)` at that
point), so a mouse-driven game keeps working under a finger. If you draw on-screen
controls, disable mouse steering when `api.mobile()` is true — otherwise a thumb on
the pad reads as the cursor as well.

### Touch

Every finger currently on the screen, in logical pixels. Use this instead of the
mouse calls when you need more than one contact at a time — steering with the left
thumb while the right one fires.

| Call | Returns |
|---|---|
| `api.touches()` | Number of fingers down this frame, `0–10` |
| `api.touch_x(i)` | X of touch `i`, or `-1` if `i >= api.touches()` |
| `api.touch_y(i)` | Y of touch `i`, or `-1` if `i >= api.touches()` |
| `api.touch_id(i)` | Id of touch `i`, or `-1` — same finger, same id, until it lifts |

The list is compacted once per fixed update, so `i` is a slot in *this frame's*
snapshot, not a stable finger id — slots shift as fingers lift. For a button
region that doesn't matter, just test the rect:

```js
for (var k = 0; k < api.touches(); k++) {
  var x = api.touch_x(k), y = api.touch_y(k);
  if (x < 80 && y > api.h() - 80) left = true;    // bottom-left corner held
}
```

For anything that has to follow *one* finger across frames — a drag, an analog
stick — remember `api.touch_id(k)` and look that id up again next frame. The id is
unique while the finger is down and is never reused by a live touch, so a second
finger landing on a button can't steal the drag:

```js
var slot = -1;
for (k = 0; k < api.touches(); k++) if (api.touch_id(k) === dragId) slot = k;
if (slot < 0) dragId = -1;                        // that finger lifted
else { dx = api.touch_x(slot); dy = api.touch_y(slot); }
```

To claim only a *fresh* press, keep last frame's ids and skip any id you already
saw — otherwise a finger that started on a button and slid into the region takes
it over.

There are no press/release edges — compute them yourself by comparing against last
frame's state, which is what a button region needs anyway. Touches are dropped on
blur, tab-out and `pointercancel`, exactly like held keys.

---

## Math and helpers

Thin, allocation-free wrappers. Use these instead of `Math.*` so `game.js` stays
self-contained.

| Call | Description |
|---|---|
| `api.flr(x)` / `api.ceil(x)` / `api.round(x)` | Rounding |
| `api.abs(x)` / `api.sgn(x)` / `api.sqrt(x)` | Basics |
| `api.min(a,b)` / `api.max(a,b)` | Basics |
| `api.mid(a,b,c)` | Middle of three — the usual clamp |
| `api.sin(a)` / `api.cos(a)` / `api.atan2(dy,dx)` | Radians |
| `api.lerp(a,b,t)` | Linear interpolation |
| `api.rnd(n?)` | Random `0..n` (default `0..1`) |
| `api.rndi(n)` | Random integer `0..n-1` |
| `api.srand(seed)` | Seed the generator (deterministic, not `Math.random`) |
| `api.dist(x0,y0,x1,y1)` | Euclidean distance |
| `api.overlap(x0,y0,w0,h0,x1,y1,w1,h1)` | AABB test |

---

## Debug

| Call | Description |
|---|---|
| `api.log(...args)` | Console log, stripped in release builds |
| `api.assert(cond, msg)` | Throws in dev, no-op in release |

Both are gated on the `DEBUG` flag at the top of `engine.js`. There is no build
step: flip it to `false` before zipping and the calls become no-ops (the engine
also stops warning about unknown asset names).

---

## Minimal example

```js
let x, y, s;

function init(api) {
  x = api.w() / 2;
  y = api.h() / 2;
  s = { fx: false };            // preallocated opts, reused every frame
  api.music("theme");
}

function update(api) {
  if (api.btn(0)) { x -= 1; s.fx = true;  }
  if (api.btn(1)) { x += 1; s.fx = false; }
  if (api.btn(2)) y -= 1;
  if (api.btn(3)) y += 1;
  if (api.btnp(4)) api.sfx("jump");
  if (api.mbtnp(0)) { x = api.mx(); y = api.my(); }
  x = api.mid(0, x, api.w() - 8);
  y = api.mid(0, y, api.h() - 8);
}

function draw(api) {
  api.cls(1);
  api.spr("hero", x, y, s);
  api.print("SCORE 0", 2, 2, 7);
}
```
