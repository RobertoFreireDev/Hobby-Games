# CLAUDE.md

Tiny PICO-8-style game runtime for the browser. Pure HTML + JS, no build step, no
dependencies. Ships as a static folder that runs inside an itch.io iframe.

Full API reference: **[API.md](./API.md)** — read it before writing any `game.js` code.

## File layout

```
index.html      shell: canvas, CSS, script tags, click-to-start overlay
engine.js       loader, api implementation, main loop   <- engine code only
assets.js       asset manifest (plain JS object)
game.js         init / update / draw                    <- game code only
assets/img/     png
assets/sfx/     short wav/ogg
assets/music/   ogg
tools/embed.html  local iframe harness that mimics itch.io
API.md          api reference (keep in sync with engine.js)
```

## Hard rules

1. **`game.js` touches nothing but `api`.** No `document`, `window`, `canvas`,
   `Image`, `Audio`, `fetch`, `setTimeout`, `localStorage`, no imports. Everything
   goes through the `api` object passed into `init/update/draw`. If a game needs
   something the api can't do, extend the api in `engine.js` and document it in
   API.md — never reach around it.
2. **Assets are declared, never loaded by the game.** `assets.js` lists every file
   with a short name. The engine preloads and fully decodes all of them before
   `init()` runs. `game.js` refers to assets by name string only.
3. **No allocation in `update`/`draw`.** No object/array literals, no closures, no
   `map/filter/forEach`, no string concat (except `print` args), no `try/catch` in
   the hot path. Preallocate in `init()`, reuse, pool.
4. **One canvas, one 2D context.** Never create a canvas per frame. Static
   backgrounds are pre-rendered once into an offscreen canvas in `init()`.
5. **Fixed 60 Hz update, one draw per frame.** `requestAnimationFrame` +
   accumulator, clamp the accumulator (max 5 steps) so a stalled tab can't spiral.
6. **Everything relative.** No leading `/`, no CDN, no external font (system stacks
   only — a webfont won't load reliably in the iframe), no network at runtime. The
   folder must work when dropped anywhere.
7. Keep `game.js` the only file the game author edits. Engine changes are separate.

## Engine architecture

- **Loading:** `fetch` each asset → images via `createImageBitmap` (already decoded,
  no first-draw hitch), audio via `AudioContext.decodeAudioData` into `AudioBuffer`.
  Show a progress bar. `init()` is called only after 100% of decoding is done.
- **Audio:** Web Audio only, never `<audio>` elements. Every sound — sfx *and*
  music — lives as a decoded `AudioBuffer`. Play = new `AudioBufferSourceNode` off
  the shared buffer, connected to a gain node (cheap, zero latency). Pause = record
  `ctx.currentTime - startTime`, `stop()` the node; resume = new node with that
  offset. This is what makes play/stop/resume instant. One `GainNode` bus for sfx,
  one for music, both into `destination`.
  The `AudioContext` starts suspended (browser autoplay policy) — `resume()` it on
  the first pointerdown/keydown from the start overlay, and again on
  `visibilitychange` when the tab returns.
- **Rendering:** fixed logical resolution (`SCREEN.w/h` from `assets.js`, default
  **640×360**). CSS `image-rendering: pixelated`, `imageSmoothingEnabled = false`,
  integer-scale to fit the container via a `ResizeObserver`, letterbox the rest.
  All coordinates the game sees are logical pixels.
  640×360 is the itch.io HTML5 default embed size and 16:9, so it fills the player
  frame with no letterbox and integer-doubles to 1280×720 and triples to 1920×1080
  in fullscreen. Other safe picks: 960×540, 800×600 (4:3), or 320×180 for a chunky
  pixel look — always set the same numbers in the itch project's embed options.
- **Text:** canvas `fillText` with system font stacks — no bitmap font sheet, no
  webfonts, no font asset. `ASSETS.text` supplies the default family/size/color;
  the api exposes them as mutable draw state. Text lands in the logical buffer and
  scales with everything else. It is the slowest thing the renderer does, so static
  labels get pre-rendered into the background canvas in `init()`.
- **Input:** listeners on the canvas/window, state stored in three `Uint8Array(9)`
  (down / pressed-this-frame / released-this-frame). Rebuilt at the end of each
  fixed update, so `btnp`/`btnr` are true for exactly one update step. Same pattern
  for the 3 mouse buttons. `preventDefault()` on arrows, space, enter and z/x/c/v.
- **Button indexes:** `0 ←  1 →  2 ↑  3 ↓  4 Z  5 X  6 C  7 V  8 Enter`. Button 8
  also has the named aliases `start`/`startp`/`startr`. Single player only —
  no player argument anywhere in the api.

## Performance budget

- 60 fps with no GC sawtooth in devtools ▸ Performance.
- Sfx audible within one frame of the call; no click/pop on stop.
- Total payload under ~10 MB (itch.io HTML5 limit is 1 GB, but load time matters).
- Prefer one packed spritesheet over many small pngs; `sspr` the regions.

## itch.io / embed requirements

The game runs inside a cross-origin `<iframe>`. Non-negotiable:

- `index.html` at the **root** of the zip.
- Never touch `window.parent`, `window.top`, or `document.referrer` — throws
  cross-origin.
- Keyboard events only arrive when the iframe has focus. The start overlay must
  `canvas.focus()` on click; also refocus on `pointerdown` anywhere.
- No persistence at all. `localStorage` can throw outright in a sandboxed iframe, so
  the api exposes no save/load — game state lives in memory for the session only.
- itch's fullscreen button resizes the iframe: handle resize via `ResizeObserver`,
  never cache the canvas rect.
- `contextmenu` prevented (right mouse button is button 2 in the api),
  `touch-action: none`, `user-select: none`, `<meta name="viewport">` set.
- Pause the loop and suspend audio on `visibilitychange`; clamp `dt` on return.

## Validating

```bash
npx --yes serve . -l 8000       # file:// breaks fetch — always test over http
# open http://localhost:8000/tools/embed.html
```

Node is only used to serve files during development — it is not a dependency of the
game and there is no `package.json`, no install step, nothing to build. The shipped
zip is exactly the files in the repo.

`tools/embed.html` loads the game in an iframe with
`sandbox="allow-scripts allow-same-origin allow-pointer-lock allow-fullscreen"`
and a resize control. **A change isn't done until it's been checked there**, not
just at the top level.

Checklist before shipping:

- [ ] Loads in `tools/embed.html`, no console errors or warnings
- [ ] Keyboard works after a single click; arrows don't scroll the page
- [ ] Audio starts on first click, survives tab-out and tab-back
- [ ] Resizing the iframe (and fullscreen) keeps the integer scale + letterbox
- [ ] `grep -nE '\b(document|window|fetch|Image|Audio|localStorage|setTimeout)\b' game.js`
      returns nothing
- [ ] Zip contains `index.html` at root, opens correctly from a fresh extract

## Conventions

- Plain classic `<script>` tags in `index.html` (engine first, then game). No ES
  modules, no bundler, no npm.
- `snake_case` for api functions (PICO-8 flavour), `camelCase` inside `engine.js`.
- Colors: palette index `0–15` or a `"#rrggbb"` string, both accepted everywhere.
- When the api changes, update **API.md in the same commit**.
