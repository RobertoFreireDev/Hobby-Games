# PORTAL FLOW — cart notes

A pipe-connecting puzzle (Flow Free family) where some boards carry a **portal
pair**: a pipe that enters one portal comes out of the other, and both tiles are
consumed by that one pipe. The portal is never a shortcut — it is a constraint
that splits one path across two regions of the board. Sixteen hand-validated
levels, 4x4 up to 7x7. Everything lives in `game.p8` (`__lua__` plus generated
`__gfx__` / `__label__` / `__sfx__` / `__music__`).

Built from [DESIGN.md](DESIGN.md); the section numbers in the code comments
refer to it.

```
pico8.exe games/portalflow/game.p8            # play
node games/portalflow/levelgen.js             # author 16 levels -> levels.json  (slow, ~5 min)
node games/portalflow/levelgen.js verify      # re-prove the shipped levels.json
node games/portalflow/gen.js                  # regenerate sprites, sfx and music
node games/portalflow/gen.js preview          # the tiles and logo as ascii art
node games/portalflow/mk.js                   # splice code.lua + levels.json into game.p8
node games/portalflow/verify.js               # read the audio back out of the cart
node games/portalflow/verify.js 36            # dump one sfx slot note by note
node games/portalflow/mktest.js               # build test/smoke/shot/audio/perf .p8
pico8.exe -x games/portalflow/test.p8         # rules + portal edge cases (121 assertions)
pico8.exe -x games/portalflow/smoke.p8        # every level parses     (prints SMOKE bad=0)
pico8.exe -x games/portalflow/audio.p8        # sfx/music channel routing
pico8.exe -x games/portalflow/perf.p8         # draw throughput per scene
pico8.exe -x games/portalflow/shot.p8         # dump screens to shot.p8l
node shot2png.js games/portalflow/shot.p8l games/portalflow/shot.png
node games/portalflow/mutate.js               # break one rule at a time, prove the suite notices
```

`code.lua` is the source of truth for `__lua__` — edit it and run `mk.js`, not
the cart, unless you are working inside the PICO-8 editor (and then copy back).
`test.p8`, `smoke.p8`, `shot.p8`, `audio.p8`, `labelgen.p8`, `*.p8l`, `shot.png`
and `art.png` are build output.

`levelgen.js` is a random search, so a full re-run will **not** reproduce the
shipped boards — `levels.json` is the artifact. `levelgen.js verify` re-proves
whatever is in it.

## The rules

- Each colour's two **dots** must be joined by a **pipe**, moving orthogonally.
- A level is won when **every colour is connected** *and* **every tile is
  covered**. A fully connected board with one empty tile is not a win. This is
  the whole design, so the HUD says it twice: `4/6` colours joined, and a
  fill meter under the board. When you connect the last colour on a board that
  is not full, the meter shakes and the uncovered tiles pulse.
- Drawing over another pipe **truncates** it from the crossed tile onward
  (Flow Free rules — the older path gives way, the input is never blocked).
  Drawing over your own pipe truncates it the same way.
- Stepping back onto the tile you just left erases it.

### The portal

- Portals come in a pair, at most one pair per board, drawn as a white-on-indigo
  ring with an open mouth. They are never a flow colour and never carry a dot.
- Entering portal A teleports the head to portal B, consuming **both** tiles in
  one step. From B you may leave in any free direction — the exit is not locked
  to the entry direction, so the portal is a routing puzzle rather than a
  memorisation one (DESIGN.md §3.3).
- Because using the pair occupies both tiles, only one colour can hold it. A
  second pipe entering A is refused with a quiet thud and a cursor shake, never
  a broken pipe.
- Truncating the owning pipe anywhere before the portal frees **both** tiles
  instantly.
- Portal tiles count toward the "cover every tile" condition, so a level whose
  portal goes unused is not solved.

**Backing out of a portal.** The head sits on the exit tile, so no direction
points back at the tile it came from. Extension always wins; a press in the
reverse of the *entry* direction that could not extend pulls the head back out
of both tiles at once. Anything else — undo, or re-grabbing the dot — also
works.

## Controls

| Input | Action |
|---|---|
| d-pad | move the cursor; while grabbed, draw |
| ❎ | grab the dot or pipe under the cursor (sticky — tap again to release) |
| 🅾️ tap | undo the last completed colour |
| 🅾️ hold 1s | clear the board |
| mouse | press on a dot or pipe and drag (devkit mouse, optional) |
| pause menu | in a level: back to levels, music on/off, sfx on/off |
| pause menu | on the level select: clear progress, music on/off, sfx on/off |

The level select has no "back to levels" entry — it swaps that slot for
"clear progress", which wipes all 16 levels and best-move counts from cartdata
immediately and fades back to a fresh level select. Progress itself is written to
cartdata the moment a level is solved, so it survives quitting the cart.

## Level authoring

`levelgen.js` is both the generator and the validator from DESIGN.md §7.2.

**Generating.** Coverage is 100% *by construction*: it builds a random
hamiltonian path over the grid — backbite mixing, with the portal pair added to
the graph as one extra edge — and then cuts that path into k coloured segments.
A hamiltonian path is expensive and a cut-set is nearly free, so each path is
re-cut 40 times; that is what makes the (low) uniqueness yield workable.

**Validating.** `solve()` is an exhaustive DFS with four prunes:

1. every free tile needs two ways through it (a free portal tile counts its
   mandatory partner edge as one of the two)
2. free tiles are flooded into components, fusing the portal pair
3. each component must be enterable *and* exitable by one same unfinished flow,
   or it is stranded
4. each unfinished flow must still have a route to its twin

A board ships only if it has **exactly one** solution, and — on portal levels —
**zero** solutions once the portal pair is replaced by plain tiles. That second
run is what stops a portal from being decoration (§7.1 rule 5).

Difficulty is not something a random generator gives you for free, so each slot
samples many valid boards and keeps the one that best matches the §7 intent:
solver node count is the difficulty proxy, and `minlong`/`maxlong` bound the
headline pipe the level is supposed to be about. Boards are deduplicated across
the sixteen slots.

Levels 1 and 2 are the verbatim tutorials from DESIGN.md §6.1 and are exempt
from the uniqueness rule — a forgiving board is the right thing while the rules
are still being taught. Level 2 has three solutions and all of them need the
portal.

```
lv  size  cols  portal  sols  p-req  mindist  longest    nodes
 1  4x4     3       -     1      -       1        7       14
 2  4x4     2     yes     3    yes       1       14       32
 ...
16  7x7     7     yes     1    yes       3       18      529
```

## Art and audio

Sprites are generated, not hand-placed. Every pipe tile — straight, elbow, cap —
is the same solid: a fat stroke along a centreline, lit from the upper left and
shaded through a dithered 7/6/5 ramp. Authoring it as distance-to-a-polyline is
what makes the pieces join seamlessly, and it means one elbow and two caps cover
all ten glyphs (the rest are `spr` flips). The ramp is recoloured per flow with
`pal()`, so seven colours cost one set of tiles. Colour is never the only
channel: each dot carries a 5x5 glyph.

Two things about that shading are worth knowing, because both were visible bugs
before they were fixed:

- **The silhouette comes from the nearest segment; the lighting does not.**
  Taking the light from the nearest segment alone makes an elbow flip from
  "vertical pipe, shadow on the right" to "horizontal pipe, highlight on top"
  across the diagonal where *nearest* switches, and a hard seam runs through
  the bend. The offset directions are blended instead, weighted by how much
  *further* a segment is than the closest one (`exp(-4*(d-dmin))`) rather than
  by absolute distance — so a straight arm comes out bit-identical to the
  matching straight tile and only the corner blends. Rounding the centreline
  into an arc also fixes the seam, but it eats the straight run and the pipe
  then visibly kinks at the tile seam.
- **A portal tile draws a narrow tongue over its ring, not a cap under it.**
  The ring is as wide as the tile, so a full-width cap drawn underneath is
  entirely hidden by it and only a disconnected blob shows in the mouth — the
  portal reads as sitting on top of the pipe. A full-width stub drawn *over*
  the ring hides the ring's near side and reads as the pipe hooking over it.
  The tongue (tiles 12/13, about two thirds the pipe's width) threads between
  the two: the pipe necks down and is visibly pulled through into the hole.
  While a pair is held, the ring itself takes the owner's highlight colour.

Transparency is keyed to colour **14**, not 0, so colour 0 is free to outline
every sprite (`palt(0,false) palt(14,true)`).

`gen.js preview` dumps the tiles and the logo as ascii art; `shot.lua`'s last
frame draws them at 4x.

Audio is three arrangements — Satie-ish for the select screen, the BWV 846
broken-chord figure for levels 1-8, an A-minor piece for 9-16 — eight patterns
each, 32 slots at speed 28, about 60s before repeat. Channel 3 is permanently
free for sfx and no waveform 6 (noise) appears anywhere.

Two things worth knowing about the music data:

- **Sustains use the slide effect.** PICO-8 has no note length, so a held note
  repeats its pitch — but at the same volume with effect 1, which slides from
  the previous note and therefore *continues* it instead of re-attacking. A
  retriggered bass note four times a second turns a pad into a pulse.
- **sfx 1 and 2 are 32-step pitch ladders**, never played whole. The cart plays
  one note of them at a time with `sfx(1,3,#path,1)`, so a pipe rises a semitone
  per tile as you draw it (§10.1) — long pipes literally sing.

## Test suite

`test.lua` — 121 assertions against the cart's own functions, covering the parse,
grab/extend/retrace, every §3.4 portal edge case, self-crossing, truncation
freeing the pair, the loop-onto-your-own-start refusal, undo and hold-to-clear,
the save bitfield (including bit 15, which goes negative in 16:16 fixed point),
"connected but not full", and one full solve of level 2 driven through the real
`btnp` path.

`mutate.js` is the part that makes that number mean something: it breaks one
rule in `code.lua` at a time — the portal takes only one tile, ownership is
never recorded, coverage is dropped from the win check, truncation keeps the
crossed tile, the unlock gate ignores the previous level, and so on — rebuilds
the cart and asserts the suite fails. All 14 mutants are killed. A green suite
that no mutant can break is a hole, not a pass.

`perf.lua` times the draw. `stat(1)` reads 0 under `-x` — the frame timer is
never driven — so a harness built on it reports a comfortable "ok" from a null
reading and tests nothing; this one times batches of real `_draw` calls against
the wall clock (`stat(93..95)`) and refuses to pass if the clock did not move.
On this machine the worst case — 7x7, seven colours, every tile covered, 40
particles — runs at ~130 draws/sec, so a draw is about half a 60fps frame, and
the update loop (a couple of 49-cell passes) is negligible beside it. The
breakdown says the cost is the 49 per-tile sprite blits, not the background:
the vignette is under 0.6ms and skips the bands a board covers completely.

`smoke.lua` loads all 16 levels and checks the parse invariants. `audio.lua`
checks routing through `stat(16..19)`; headless PICO-8 never advances the audio
clock, so tempo and pattern order are checked offline by `verify.js` reading the
hex back out of the cart instead.

## Cover art

`labelgen.lua` is built against the **game's own `__gfx__`** (`mklabelgen.js`),
so the cover is the real tiles and the real logo rather than a redrawing of
them. It composes a 6x5 solved-board fragment with three pipes woven through it
and one red pipe crossing the whole picture through the portal pair, then dumps
the framebuffer as `__label__` hex.

The dithered thread between the two mouths is the one piece of poster licence —
it is not drawn in game, but it is what makes the mechanic legible at thumbnail
size.

```
node games/portalflow/mklabelgen.js
rm -f games/portalflow/lbl.p8l
pico8.exe -x games/portalflow/labelgen.p8
node label-tool.js games/portalflow/lbl.p8l games/portalflow/game.p8 games/portalflow/label.png 3
```

`printh` goes to a named file rather than stdout because PICO-8's own `RUNNING:`
banner interleaves with early output and would land inside the `@@begin`/`@@end`
block.
