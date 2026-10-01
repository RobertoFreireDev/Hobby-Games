# WebJsGameRunner

A tiny PICO-8-flavoured game runtime for the browser. Pure HTML + JS — no build
step, no dependencies, no npm. The repo *is* the shipped artifact: zip it, drop it
on itch.io, done.

Bundled with it is **Stardust Run**, a small arcade demo that exercises the whole
api surface.

```
index.html      shell: canvas, CSS, script tags, click-to-start overlay
engine.js       loader, api implementation, main loop   <- engine code only
assets.js       asset manifest (plain JS object)
game.js         init / update / draw                    <- game code only
assets/         img, sfx, music
tools/embed.html  local iframe harness that mimics itch.io
tools/music.js    re-renders the four music tracks (node, dev only)
tools/sfx.js      re-renders the five sfx (node, dev only)
API.md          full api reference
CLAUDE.md       architecture + house rules
```

## Run it

`file://` breaks `fetch`, so always serve over http:

```bash
npx --yes serve . -l 8000
# game:    http://localhost:8000/
# harness: http://localhost:8000/tools/embed.html   <- check changes here
```

Append `?mobile=1` (or `?mobile=0`) to force the touch layout on or off, which is
how you check the on-screen controls from a desktop browser. In the harness the
query string goes on the iframe's own url.

Node is only a static file server for development, plus the two asset generators
in `tools/`. It is not a dependency of the game and there is nothing to install or
build.

## What the engine gives you

- **Fixed 60 Hz update**, one draw per frame, accumulator clamped to 5 steps.
- **Fixed logical resolution** (640×360), integer-scaled and letterboxed into
  whatever box the page gives it, `image-rendering: pixelated` throughout.
- **Everything preloaded and decoded** before `init()` — images through
  `createImageBitmap`, audio into `AudioBuffer`s. No hitch on first use.
- **Web Audio only.** Sfx get 32 pooled voices with volume/rate/pan/loop; music is
  one track with fade, crossfade and sample-accurate pause/resume, plus `sync` —
  a swap that keeps the playhead, so tracks cut from one grid layer up mid-loop
  without dropping the beat.
- **Input** as three `Uint8Array`s: `btn` / `btnp` / `btnr` for 9 buttons
  (`0 ← 1 → 2 ↑ 3 ↓ 4 Z 5 X 6 C 7 V 8 Enter`, with `start` / `startp` / `startr` as
  aliases for 8), the same for 3 mouse buttons, plus wheel.
- **Touch** alongside it: up to 10 contacts a frame with stable per-finger ids, so
  one thumb can steer while another fires. `api.mobile()` answers the only question
  that matters — *should the game put its controls on the screen?*
- **Drawing** — sprites with flip/rotate/alpha, pixel-crisp shapes, `fillText`
  text with alignment, `camera`, `clip`, `prerender` for static art, and `recolor`
  to bake palette-swapped variants of a sheet cell in `init()` — team colors and
  state variants with no extra png and no per-frame cost.
- **iframe-safe**: no `window.parent`, no persistence, focus on click, pause and
  suspend audio on tab-out, `ResizeObserver` for itch's fullscreen button.

## Writing a game

Edit `game.js`. It defines three globals and touches nothing but `api`:

```js
function init(api)   { }   // once, after every asset is decoded
function update(api) { }   // fixed 60 Hz
function draw(api)   { }   // once per frame
```

Read **[API.md](./API.md)** first, and the house rules in
**[CLAUDE.md](./CLAUDE.md)** — the short version is: declare assets in
`assets.js`, allocate in `init()`, never allocate in `update`/`draw`, and never
reach around the api for a browser global.

## The demo

**Stardust Run** — fly the ship, grab coins, outrun the red fleet chasing you.

Three controls, that's the whole scheme.

| Keyboard | |
|---|---|
| arrows | thrust (hold left mouse to steer to the cursor) |
| X | pulse — clears foes in an expanding ring; one charge per 8 coins, 4 banked at most, 2 to start. Also restarts after a game over |
| Enter | pause / continue |
| wheel | volume |

| Touch | |
|---|---|
| bottom-left pad | analog stick — fixed in the corner, the knob leans toward the thumb |
| bottom-right X | pulse (and start / restart) |
| top-right button | pause / continue |

Every 10 seconds the wave counter ticks up and a fresh squad rolls in from the
edges, one ship bigger than the last (capped at 12), on top of the trickle that
never stops. Foes shove each other apart so a squad spreads into a countable
swarm instead of stacking into a single sprite.

The HUD is the ship itself: it flies blue while you hold a pulse charge and drains
to light grey when you're out — colorless reads as *spent* at a glance and can
never be misread as an enemy (red) or a coin (yellow).

Its assets are generated, not hand-drawn: an 80×16 spritesheet, five sfx, and one
8-second music loop in four arrangements — calm, base, drive, rush — ~1.4 MB
total. The four tracks share a grid (120 BPM, A minor, same chord under every
beat), so the score thickens as the waves stack up and thins out again on the game
over screen without ever restarting the song. `node tools/music.js` and
`node tools/sfx.js` re-render them.

The sheet's own enemy cell goes unused: both the foe and the spent-hull ship are
`api.recolor` swaps of the player cell, baked once in `init()`. Same silhouette,
different paint — which is exactly why a foe reads as *another ship* rather than a
blob.

## Packaging for itch.io

The repo is the artifact — there is no build. Packaging is "put the right five
things in a zip".

### 1. What goes in

| In the zip | Left out |
|---|---|
| `index.html` ← **must be at the root** | `tools/` |
| `engine.js` | `API.md`, `CLAUDE.md`, `README.md` |
| `assets.js` | `.git/` |
| `game.js` | |
| `assets/` (the whole folder) | |

The dev-only files are harmless but pointless upload weight. `index.html` at the
top level of the zip is the one hard requirement — itch serves whatever
`index.html` it finds at the root, and a wrapping folder means it finds nothing.

### 2. Before you zip

- Check `DEBUG` is still `false` at the top of [engine.js:11](engine.js#L11) — it
  gates `api.log`, `api.assert` and the loader's console warnings. It ships `false`;
  flip it back if you turned it on.
- Turn off any debug overlay the game leaves bound (the demo has none).
- Check the total size. Under ~10 MB keeps the load fast; itch's limit is 1 GB but
  players give up long before that.

### 3. Make the zip

Windows Explorer: select the five entries → right-click → *Send to ▸ Compressed
(zipped) folder*. Selecting the files (not the parent folder) is what keeps
`index.html` at the root.

From a shell, `tar` on Windows 10+ writes a correct zip:

```bash
tar -a -c -f stardust-run.zip index.html engine.js assets.js game.js assets
```

Avoid PowerShell 5's `Compress-Archive` — it writes `\` path separators, which
some unzippers (itch's included, historically) mis-read as literal filenames.

### 4. Verify the zip, not the repo

Extract it somewhere fresh and serve *that* folder — this catches a missing asset
or a stray absolute path that the working tree hides:

```bash
cd /path/to/fresh-extract
npx --yes serve . -l 8001
# open http://localhost:8001/
```

Then re-run the checklist at the bottom of [CLAUDE.md](./CLAUDE.md) against it:
loads with no console errors, keyboard works after one click, audio survives a
tab-out, resizing keeps the integer scale and letterbox.

### 5. Upload

On the itch project page:

| Setting | Value |
|---|---|
| Kind of project | **HTML** |
| Upload | the zip, ticked *This file will be played in the browser* |
| Viewport dimensions | **640 × 360** — must match `screen` in [assets.js:6](assets.js#L6) |
| Fullscreen button | on (the engine handles the resize via `ResizeObserver`) |
| Mobile friendly | on — the engine has touch input and the demo has a full touch layout |
| Automatically start on page load | off; the click-to-start overlay is what unlocks audio |

If you change the logical resolution in `assets.js`, change the viewport
dimensions to the same numbers. A mismatch makes itch letterbox on top of the
engine's own letterboxing.

### Updating a published game

Upload the new zip and delete the old one from the same project page — the URL
and page stay put. Browsers cache aggressively inside the iframe, so hard-reload
(Ctrl+F5) when checking a fresh upload.
