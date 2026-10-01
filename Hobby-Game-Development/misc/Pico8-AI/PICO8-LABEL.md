# PICO8-LABEL.md — Cover art for a cart label

The **label** is a 128x128 image stored in a cart's `__label__` section. It is the thumbnail
Splore and the BBS show for the game, and it is the picture baked into an exported
`.p8.png` cartridge. It is purely cosmetic: it costs **no tokens**, occupies **no RAM**, and
**cannot be read from code**. Deleting it breaks nothing.

This document is game-agnostic. Everything below works for any cart.

## The format

- `__label__` is **128 lines x 128 hex digits** — the exact same encoding as `__gfx__`.
  One digit = one pixel = one palette index `0`–`f`. Line `y` is row `y`, written left to
  right, so the text literally looks like the picture.
- Section order in a `.p8` is fixed. `__label__` goes after `__lua__`/`__gfx__` and before
  `__gff__`, `__map__`, `__sfx__`, `__music__`:

  ```
  __lua__  __gfx__  __label__  __gff__  __map__  __sfx__  __music__
  ```

  Omit sections you don't use, but never reorder the ones you keep.
- Every row must be exactly 128 lowercase hex characters. Short rows are read as zeros,
  which silently shifts your art. PICO-8 trims trailing all-zero rows when it re-saves the
  cart — harmless, and it means a saved cart may legally have fewer than 128 rows.

## Three ways to get one

1. **`ctrl-7` in the PICO-8 editor.** Run the game, reach the frame you want, press `ctrl-7`.
   It captures the current screen into `__label__`. Fine for a gameplay screenshot; useless
   for composed cover art, and it silently overwrites whatever was there.
2. **Draw it, dump it, splice it** — the pipeline below. Reproducible, reviewable, and the
   art is real PICO-8 output in the real palette, not hex you guessed at.
3. **Hand-write the hex.** Don't. 16,384 digits.

---

## The pipeline

The idea: a throwaway cart draws the cover art with ordinary PICO-8 drawing calls, reads its
own screen back with `pget`, and prints it as hex. A Node script splices that into the real
cart and renders a PNG so you can look at the art before committing it.

Drawing in PICO-8 rather than computing pixels in Node matters: you get the real palette,
the real clipping, and any drawing primitive you like (`circfill`, `sspr`, `fillp`, `print`).
The generator cart has **no token pressure** — it never ships — so write it as verbosely as
you want.

### 1. Write the generator cart

`labelgen.p8` in the carts folder. Structure:

```lua
pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
hx="0123456789abcdef"

-- ... helper functions ...

-- ... top-level drawing code: composes the
--     whole 128x128 image, back to front ...

-- dump the screen as __label__ rows
printh("@@begin")
for y=0,127 do
 local s=""
 for x=0,127 do
  s=s..sub(hx,pget(x,y)+1,pget(x,y)+1)
 end
 printh(s)
end
printh("@@end")
extcmd("shutdown")
```

Notes:

- **No `_init`/`_update`/`_draw`.** With no callbacks, PICO-8 runs the file top to bottom,
  which is exactly what a one-shot generator wants. Drawing writes straight to screen memory,
  so `pget` sees it without any `flip()`.
- The 16,384 `pget` calls blow the per-frame CPU budget. That is fine — nothing is being
  displayed, and there is no frame deadline to miss.
- The `@@begin`/`@@end` markers matter: **PICO-8's stdout ordering is not reliable** and its
  own `RUNNING:` banner interleaves with early output. Markers let the parser find the block
  regardless of where it lands.
- `extcmd("shutdown")` is mandatory, or the process hangs.
- `-->8` tab breaks cost nothing and keep helpers, font data and composition separate.

### 2. Run it headlessly

```bash
"/c/Program Files (x86)/PICO-8/pico8.exe" -x labelgen.p8 > dump.txt 2>&1
```

`printh` output arrives prefixed with `INFO: `; the parser strips that. Run under a
`timeout` so a stuck cart can't block.

### 3. Splice and preview

```bash
node label-tool.js dump.txt game.p8 preview.png 3
```

`label-tool.js` (in this repo) validates that it got exactly 128 rows of exactly 128 hex
digits, replaces any existing `__label__` in the cart, inserts it in the correct position,
and writes a scaled PNG. It is **idempotent** — re-run it as often as you like.

Pass `-` as the cart argument to preview without touching any cart.

### 4. Look at the preview, then iterate

Render at scale 3 to judge detail and at scale 1 to judge whether it still reads as a
thumbnail. Most fixes are legibility fixes, and they only show up at 1x.

### 5. Verify the cart

A malformed hex section is a load error, so the cart must go through `-x`:

```bash
"/c/Program Files (x86)/PICO-8/pico8.exe" -x verify.p8
```

Build `verify.p8` by copying the real cart and appending a frame-count kill switch to the end
of its `__lua__` section (see [PICO8-TOOLING.md](PICO8-TOOLING.md)). That proves the label
parses without breaking the game.

For proof that PICO-8 actually *reads* the label rather than merely tolerating it, export a
cartridge image and open it:

```bash
"/c/Program Files (x86)/PICO-8/pico8.exe" game.p8 -export "game.p8.png"
```

The label is what you see inside the cart window.

---

## Designing for 128x128

The label is viewed at 128 pixels, often smaller. Compose for the thumbnail first.

**Layout.** Reserve roughly the top 20–25 rows for the title and give the rest to a single
subject. A solid caption band across the bottom ~12 rows is optional: it buys you legible
text, but it costs a tenth of the canvas and boxes the art in, so leave it out when the
scene reads better running edge to edge. Silhouette is what survives at thumbnail size, so
make the subject's outline distinctive before adding any interior detail.

**Titles.** PICO-8's built-in `print` font is 4px tall and vanishes at thumbnail size. Draw
the title as a block font instead: a 3x5 cell grid per letter, each cell rendered as a 4x4
block, gives a 12x20 chunky letterform — about 90px for a seven-letter word.

Two things make or break its legibility:

- **Emboss the letter's outer contour, not every cell.** Lighting each 4x4 cell individually
  turns a vertical stroke into a ladder of stripes and fills in the counters (the holes in
  `a`, `d`, `o`, `q`). Only light an edge when the neighbouring cell in that direction is
  empty:

  ```lua
  if not gat(g,rx,ry-1) then hl(x,x+3,y,light) end       -- top
  if not gat(g,rx-1,ry) then line(x,y,x,y+3,light) end   -- left
  if not gat(g,rx,ry+1) then hl(x,x+3,y+3,dark) end      -- bottom
  if not gat(g,rx+1,ry) then line(x+3,y,x+3,y+3,dark) end
  ```

- **Outline it against a busy background.** Draw the whole word in flat black at every offset
  in a 5x5 neighbourhood, then once more offset down-right as a drop shadow, then draw the
  real letters on top. Two pixels of black is enough to lift a title off a star field.

Leave 2px between glyph cells so the black outlines form a visible gap; at 1px the letters
fuse.

**Colour.** The 16-colour palette has few usable pairs, so plan them. Ramps that work:
`8→9→10` (red to gold, ideal for a logo gradient), `1→13→7` (night to highlight),
`4→15→7` (stone), `3→11` and `1→12` (foliage / sky shading). Keep adjacent large shapes on
different hues; two neighbouring shapes in the same family read as one blob at 1x.

**Gradients.** There is no alpha, so dither. An ordered 4x4 Bayer matrix gives a clean,
period-correct ramp:

```lua
bay={0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5}
function dith(x,y,t) -- t=0 never, t=1 always
 return t*16>bay[(y%4)*4+(x%4)+1]
end
```

Use it for vertical gradients (`t` from the row) and radial glows (`t` from distance). Layer
a second dithered pass over the first for a two-stage ramp.

**Small text.** Plain `print` is legible inside a solid band, where the contrast is total,
and almost nowhere else — over artwork it disappears. Budget 4px per ASCII character; button
glyphs draw 8px wide despite counting as one character to `#`.

---

## Gotchas

- **`ctrl-7` overwrites `__label__` silently.** If you open the cart in the editor after
  generating art, don't press it.
- **Re-saving in the PICO-8 editor rewrites the whole file.** Trailing zero rows get trimmed
  and formatting normalises. The label survives; regenerate if anything looks off.
- **There is no transparency.** `pget` returns whatever colour is on screen, so every label
  pixel is opaque. Fill the background explicitly — unset pixels are black, not empty.
- **The label is not the cart title.** PICO-8 takes the game name and author from the first
  two comment lines of the code (`-- game name`, `-- by author`) when building a `.p8.png`.
  Keep those correct regardless of what the art says.
- **Keep the generator cart.** It is the source of the art; the hex is a build artifact.
  Editing 16,384 hex digits by hand to make a small change is not a thing you want to do.
