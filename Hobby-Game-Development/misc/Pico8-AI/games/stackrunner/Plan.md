# Stack Runner — grid puzzle cart

## Context

`game.p8` at the repo root is the bare 95-byte template (empty `__lua__`, `__label__`, `__sfx__`,
`__music__`; no `__gfx__`/`__gff__`/`__map__`). We are building a complete 16-level grid puzzle
game into it from scratch.

The hook: **you do not have free movement.** Every move is spent from a LIFO stack of movement
cards you pick up off the grid, and whatever you *don't* spend carries into the next level. That
turns each level into a resource-routing problem, and turns the whole 16-level run into one long
budget: overspending on level 4 can strand you on level 9. Rewind (unlimited step undo) and a
pause-menu "back a level" make that budget explorable rather than punishing — going back and
re-solving an earlier level differently changes the stack you arrive at the next one with.

Answers locked in during planning:
- **Goal:** each level has exactly one **stair** tile. Step on it to advance. The stair on level 16
  finishes the game.
- **Guards:** fully static hazards. No movement, no patrols. There is **one guard type** — the
  one that kills. A second, pushing guard existed until 2026-08-22 and was removed (TODO item 13)
  before the floors were rebuilt, so nothing in the level set is designed around it.
- **Rewind:** unlimited single-step undo, back to the level's start state.
- **Art:** chunky retro dungeon — stone walls, wood crates, warm palette.

## Rules (the authoritative spec for implementation)

**Board.** 10 wide x 9 tall, cells 12x12 px, origin (4,4). Bottom bar occupies y 112..127.
Cell `(cx,cy)` draws at `(4+cx*12, 4+cy*12)`.

**Stacks.** `mv` = movement stack, max 5. `it` = item stack, max 3. Both LIFO — you always spend
the **most recently collected** card. Top of stack is the rightmost HUD slot and is highlighted.
If a stack is full you cannot collect that pickup: you walk over it and it stays on the grid.

**Arrow press** pops the top of `mv` and moves that many steps in that direction:
`1`, `2`, `3`, or `m` (max — keep going until something stops you). The card is consumed only if
the player actually leaves the cell: if step one is blocked the card stays on the stack, no
snapshot is pushed, and `settle()` does not run — so a blocked press does not tick a bomb fuse or
give the guard a turn. A move that travels at least one square spends the card even if the rest
of the distance is blocked. With an empty `mv` an arrow raises the **stuck modal** instead (see below).

**Per-step resolution**, in order:
1. Target outside the board, a wall, a closed door, a guard, or a live bomb → the move stops here.
2. Target is a box → box moves only if the cell beyond it is empty floor. Otherwise the move stops.
3. Target is a pickup → player enters; collect it if the matching stack has room, else it stays.
4. Target is the stair → player enters, level complete, remaining steps discarded.
5. Open door / empty floor → player enters.

**After the whole movement finishes** (not per step), in this order:
1. **Bomb.** A planted bomb detonates on the movement *after* the one that planted it. It destroys
   boxes and guards in the four orthogonal neighbours. The player is immune.
2. **Stair check** — the stair beats the guard: landing on it wins the floor even from inside a
   guard's reach.
3. **Guard.** If the player is orthogonally adjacent to a guard, death → level restarts from its
   saved entry state.

**Walking.** A movement is resolved instantly in the model, then *played back*: the cells the
move traced are kept in `wx`/`wy` and the player slides along them at 3 frames a cell, cycling
two walk frames, before anything on the board reacts.
Pickups are collected **as the player passes over them**, one cell at a time, so the cards
appear in the HUD in step with the walk rather than all at once. Added 2026-08-21, TODO item 8.

**A pushed crate lags the player by one cell.** The push resolves in the model with the rest of the
move, but the crate is *drawn* at the cell it is leaving until the walk reaches the cell in front of
it, so the shove reads as the player pushing it rather than the crate sliding away on its own.
`step` now records the push as well as applying it: `pbx,pby` the crate's original cell, `pbs` the
walk segment that first shoves it, `pbn` how many shoves (a max-run card pushes the same crate
repeatedly), `pdx,pdy` the direction. At most one crate can move per movement -- the direction is
fixed for the whole run and the player ends up behind the crate again after each shove -- so one
record is enough. `boxlag()` turns it into a draw position (interpolated by `wf/wsp` on segment
`pbs+k`) plus the grid cell to leave blank while the animation runs; `pbn` resets in `domove` and
`loadlv`. The model, the snapshots and rewind are untouched. Added 2026-08-22, TODO item 14.

**Guard telegraph.** The kill is preceded by a one-second hold (30 frames) during which the whole
board freezes — every button is ignored — and the player sprite blinks white at 4Hz. You always
see the move that put you next to the guard land first, then the blink, and only then the
"caught!" modal. Added 2026-08-20, TODO item 3; simplified to a single guard 2026-08-22.

**Stuck.** An arrow pressed with an empty `mv` is a dead run: no card, so no way to reach a
card. Rather than leave the player to work out which of undo / restart / back-a-level gets them
out, the cart puts up a blocking "no moves left" modal and takes the only available step for them
when it is closed: rewind until there is a card to spend again, or, if the floor was entered with
none (empty history), drop back to the floor before and restore its entry stacks. The modal's
second line says which of the two it will do. Manual undo, restart and back-a-level all still
exist; they are just no longer the only way out.

**Only 🅾️ closes the stuck modal** — the same button that rewinds everywhere else, doing the same
thing it always does, just repeated until it has an effect. ❎ and the arrows are dead while the
modal is up, so there is no new button to learn and no second button to confuse it with. Added
2026-08-21, TODO item 11.

**Items (❎ pops the top of `it`).** *Bomb* — plants on the player's current cell; arms on the next
movement. *Switch* — toggles every closed door to open and every open door to closed.

**Rewind (🅾️).** One press = undo exactly one state-changing action (a movement or an item use),
unlimited, down to the level's entry state. **At the entry state 🅾️ keeps going: with an empty
history it drops a floor** (restoring that floor's entry stacks), so one button walks the whole run
backwards and there is never a dead press. On floor 1 with nothing to rewind it still just buzzes.
A **light-grey ring** (`circ`, colour 6) is drawn on the cell the floor was entered on, under
everything else: standing on it is exactly the condition for 🅾️ dropping a floor, so the player
can see which of the two the button is about to do before pressing it. `spx,spy` are read from the
map's `p` tile in `loadlv`, so the ring survives restart and back-a-level the way the start
position does. Added 2026-08-22, TODO item 14. **Dropping a floor freezes the board for 15
frames** (`pz`, half a second at 30fps) and then latches on release, so a 🅾️ held or mashed a beat
too long cannot chain two or three floors down by accident. Added 2026-08-22, TODO item 15.

**Pause menu.** `menuitem(1,"back a level", ...)` sets a flag consumed in `_update`.

**Screens.** `mode` is 0 title, 1 playing, 2 win, 3 tutorial. The title screen offers ❎ play /
🅾️ how to play; the tutorial is one static page of rules and goes back to the title on either
button. Added 2026-08-21, TODO item 4.

**Music.** One calm dungeon loop, started once in `_init` with `music(0,0,7)` and never stopped --
it plays under the title, the tutorial, every floor and the win screen. The mask `7` reserves
channels 0-2 for the music and leaves channel 3 for `sfx`, so no sound effect ever punches a hole
in the loop. Added 2026-08-21, TODO item 7.

**Level entry save.** On entering level *n*, snapshot `(mv, it)` into `lvlsave[n]`. Restarting
level *n* or returning to it restores that snapshot exactly. Re-solving level *n* differently
overwrites `lvlsave[n+1]` the next time you enter *n+1*.

## Technical approach

**Levels in `__map__`, so they can be hand-edited.** (Originally 16 Lua string literals; moved to
the map sheet on 2026-08-20 — see TODO item 2 — because the levels need to be editable by hand in
PICO-8.) Each level occupies a 16x16 map block, 8 blocks per map row, two rows for 16 floors: that
matches one screen of the map editor. Only the top-left 10x9 of a block is played. Map tile 0 is
floor; every other tile is `47+n` indexing the `mchr` string (`#o-=^2abcdxyp`) for its cell char.
Sprites 48..60 hold 8x8 legend icons that exist only so those tiles are recognisable in the editor —
the board is still drawn with `sspr` from the 12x12 tiles and `map()` is never called. `loadlv`
only ever *reads* the map (`mget`) into the char grid, and turns `p` into `px,py` in that copy, so
the start position survives every restart / rewind / back-a-level. `__gff__` is not used.

**Cell legend** (the runtime grid is an array of single-char strings; comparisons are direct — the
map sheet stores the same legend as tile ids, see above):

```
.  empty floor      #  solid wall        o  box          p  player start
2  guard            -  door closed       =  door open
^  stair            *  live bomb (runtime only)
a  move 1   b  move 2   c  move 3   d  move max
x  bomb pickup      y  switch pickup
```

**Player sprites: three per facing, nine in all.** `psb={30,30,33,15}` maps a facing
(1 left, 2 right, 3 up, 4 down) to its idle tile; `+1` and `+2` are that facing's two walk
frames. Right reuses the left art through `sspr`'s `flip_x`, which is why `psb[1]==psb[2]` and
why `dtile` gained a fourth argument. Down keeps the original player tile 15 as its idle, so
15/16/17 sit together in the same tile row; side is 30/31/32 and up 33/34/35 in the (previously
empty) fourth tile row, `__gfx__` lines 36-47. The back view has no eyes -- a dark-gray hair
band sits where the eyes are on the front view -- and the walk frames bob the body up one pixel
so a step reads even when it is a single cell. Colours stay 0/5/6/7. Added 2026-08-21, TODO
item 8.

**The walk as a phase.** `domove` collects the path with `wadd()` and ends in `wgo(settle)`
instead of `settle()`; `wgo` stores the callback in `wcb` and sets `wi=1`. `_update` runs the
walk branch ahead of the enemy telegraph and returns early, so input, the pause-menu flags and
rewind are all locked out for its duration; each time `wi` advances it calls `pick(x,y)` for the
cell just reached, and on the last cell it zeroes `wi` and calls `wcb()`. `pick` therefore takes
coordinates now and `step()` no longer calls it. `_draw` lerps between `wx[wi]` and `wx[wi+1]`
by `wf/wsp` and picks the walk frame with `1+wi%2`; facing comes from `fx,fy`, so snapshots did
not change and rewind still steps back over a whole movement. `wi` resets in `loadlv`. The
bomb-landing preview is hidden while a walk is in flight.

**Tiles are 12x12, drawn with `sspr(sx,sy,12,12,dx,dy)`** — an exact 1:1 blit, no scaling. `map()`
and `spr()` are unused for the board. ~16 tile images pack into `__gfx__` lines 0–23 at a 12px
stride, 10 per row. The HUD reuses the pickup tiles directly as 12x12 stack icons. The
blinking "top of stack" highlight is a white (7) rect flush with the tile it frames —
`2+(#mv-1)*12`..`13+...` and `68+(#it-1)*12`..`79+...`, one px right of where it first sat, since a
12px tile drawn at `x` occupies `x..x+11`. Was yellow (10) and one px left; changed 2026-08-21,
TODO item 5, to hold the 0/5/6/7 UI palette.

**Red means guard, and nothing else.** The cart draws its UI from 0/5/6/7 only. The two red (8)
strokes that were left in the code -- the modal frame and the blinking bomb-landing preview --
became white (7) on 2026-08-21, TODO item 6, and on 2026-08-21, TODO item 9, the enemy tiles
claimed colour 8. Since 2026-08-22 there is only one of them: **the guard** (tile 7), solid red
with black eyes. The pusher's part-red figure (tile 6) is no longer referenced by `tix`, `mchr`
or the tutorial -- its art is left in the sheet, inert, rather than blanked, so the piece can be
brought back without redrawing it. Everything else in `__gfx__` is still 0/5/6/7.

**A shading pass over every 12x12 tile, and four slabs / four courses instead of one.** Added
2026-08-21, TODO item 10. All 32 tiles were redrawn against four rules, each of them a way of
spending 144 pixels well:

- *One light, from the top-left.* Lit edge 7 or 6, body 6, shadow 5, void 0, with the dark side
  always down-and-right. Deliberately **not** pillow shading — darkening every edge equally reads
  as inflated, not lit. The bomb is the clearest case: its terminator is a clean diagonal, shaded
  by `(x-2)+(y-4)>8`, with a single 7 glint up-left.
- *Selective outline, never a black ring.* Shapes are bounded by a darkened version of their own
  fill. A black ring would be invisible against the black floor anyway, and at this size it would
  eat a large fraction of the pixel budget.
- *A value budget on top of the palette.* Floor and wall never use 7. That reserves white for the
  player, the card pips, the stair's nearest tread and the item highlights, so the things you can
  act on are always the brightest things on screen — the same trick as "red means enemy", one
  level up in the ramp.
- *Clustered pixels, one highlight, regular stair-steps.* Diagonals step 2-2-1 (floor crack),
  2-1 (wall crack) or 2-2-2 (switch lever); irregular run lengths read as sloppy at 12x12 even
  when the silhouette is right. Dithering is confined to one floor slab and one wall course, a
  few rows deep — a whole sprite of it is noise, not texture.

Hue-shifted shading is the one standard technique left out: it needs colours outside the locked
0/5/6/7/8 set, so the greyscale ramp carries the volume on its own.

Four tiles that were reworked beyond re-shading: the **crate** inverted to a mid-tone face with a
dark X-brace behind a bright lit frame (a 6 brace on a 5 face was one step of contrast and read
as mud); the **stair** became four 2-row treads, one tone and one pixel narrower per step, so the
ramp reads as depth; the **grey guard** gained a plain grey shoulder line so its jaw stops bleeding
into the red chest; the **switch** traded a 3px knob blob for a 2px grip.

**Floor and wall variants, tiles 40-47.** Both come in four, picked per cell in the board draw
loop with `local v=(x*3+y*7+x*y+lv)%4` — deterministic, so a cell keeps its slab across frames,
rewinds and restarts and the board never shimmers; `lv` is in the hash so the same room shape
looks different on a later floor. `#` draws `44+v`, everything else draws `40+v` and then its
object tile on top. Tiles 0 and 1 stay as copies of floor A / wall A, since the title screen
borders and the sheet's first cells still reference them. Slabs are plain / cracked / rubble /
gravel-dither, all sharing one corner joint tick so the flagstone grid still reads, and all kept
very dark — the floor is background and everything actionable has to out-value it. The four wall
courses use **the identical brick bond**: same course height, same brick size, same mortar lines,
varying only in wear (clean, cracked, chipped, worn). An earlier draft varied the block geometry
too — big ashlar next to small cobble — and the ring read as four different materials rather than
one wall that had aged unevenly. The variants live in `__gfx__` lines 48-59, in the previously
empty fifth tile row; map rows 32-63 alias that region but the levels only use rows 0-31, so
nothing collides. Cost: +39 tokens.

**The stuck modal is a flag, not a mode.** `domove` sets `stuck=true` instead of flashing, so
the message no longer times out; `_update` gains a branch that returns early while `stuck` and
only reacts to 🅾️/❎, and `_draw` calls `stuckbox()` over the board. The branch sits *after*
`backreq`/`rstreq` so the pause menu still works with the modal up, and `loadlv` clears `stuck`
for the paths that reach it that way. Only `btnp(4)` is read there. Closing sets `lk=1` — the
same release latch the screens use — so a held 🅾️ cannot auto-repeat a second undo on top of the
rewind that closing already did. `unstick()` is the
whole recovery: `while #mv<1 and #hist>0 do undo() end`, then `backlv()` if it is still empty
(level 1 has no floor below, so it re-enters its own entry state). The loop, rather than a single
`undo()`, matters because the last snapshot can be an item use, which hands back a bomb but no
card. Added 2026-08-21, TODO item 11. Cost: ~90 tokens.

**Guard telegraph as a deferred settle.** `settle()` runs the bomb, then `endturn()`, which
checks the stair first and then looks for an adjacent guard; finding one it sets `ph=30` instead
of killing. `_update` counts `ph` down ahead of every other branch and returns early, so input,
the pause-menu flags and rewind are all locked out for the hold; at zero it calls `die()`.
`_draw` whites the player tile out on `ph%8<4` via `ppal(7)`, a per-index `pal` loop rather than
`pal()` so the cart's `palt` settings survive. `ph` resets in `loadlv`. The hold is not a snapshot
boundary: undo still steps back over the whole movement including the guard's response. Removing
the pusher on 2026-08-22 deleted `alert()`, `shove()`, `resolve()` and the `pend`/`pvx`/`pvy`
globals — about 550 bytes of Lua.

**Screen changes latch on button release.** Every mode switch sets `lk=1`, and the first branch of
`_update` swallows all input while `lk>0`, clearing it only once neither 🅾️ nor ❎ is held. Without
this, holding ❎ in the tutorial bounces to the title and then `btnp`'s auto-repeat (15 frames, then
every 4) immediately starts a run — and holding it into a run would fire `useit`. A frame-count
lockout is not enough: the repeat keeps firing for as long as the button is down, so the latch has
to wait for the release itself. The tutorial rows are two parallel data tables, `tut1` (tile index)
and `tut2` (`split` of the captions), next to `mchr`.

**Going back a floor also costs a beat.** `backlv()` sets `pz=15`; the branch right after the `lk`
gate counts it down and returns early, so nothing on the board updates -- and at zero it sets
`lk=1` rather than simply resuming, handing the guard over to the release latch. That pairing is
the point: the freeze alone would not help a *held* 🅾️, because `btnp` keeps repeating for as long
as the button is down and would fire again the moment the count reached zero. Verified headlessly
with a driver that reproduces PICO-8’s own auto-repeat (edge, then every 4 frames after 15): from
floor 3, 🅾️ held for 200 frames now lands on floor 2 and stays there, while deliberate mashing
(press/release every other frame) still walks down a floor roughly every 18 frames. It applies to
every route down -- the `undo()`-with-empty-history drop, the pause-menu item and `unstick()` --
since they all funnel through `backlv()`. Rewinding *within* a floor is untouched. Added
2026-08-22, TODO item 15. Cost: ~20 tokens.

**Music: three channels of A-minor drone.** `__sfx__` 8-19 and `__music__` 0-3, all at speed
`0x20` (32 ticks/note, ~0.267 s/row) -- 32 rows ~ 8.5 s per pattern, ~34 s for the whole loop.
Deliberately slow: the player is meant to sit and think between moves. Four patterns carry eight
16-row chord blocks -- **Am F Dm E | Am C Dm E** -- over three channels: sfx 8-11 a held root
drone in octave 0 (triangle, vol 4, sounding 14 of every 16 rows so the chord breathes), sfx 12-15
a rising four-note arpeggio, one pluck per beat-pair (triangle, volume stepped 5-4-3-2 on a
*repeated* pitch, which decays without retriggering the note), sfx 16-19 a sparse organ lead in
octave 3 at vol 3. Channel 3 is written `44` (unused) in every pattern, so `sfx(n)` with the
default channel `-1` always lands there. Generated by a Node script, not hand-typed; nothing about
it is reachable from Lua beyond the single `music` call.

**Undo snapshots.** Before each state-changing action push `{g=<grid serialized to a 90-char
string>, px, py, mv=<copy>, it=<copy>, bomb=<state>}`. Serializing the grid to a string keeps
snapshots compact; deserialize on rewind. Nothing ever mutates map RAM, so no `reload()` and no
cart-ROM restore is needed.

**Code layout** follows PICO8-GAME-STRUCTURE.md's banner convention, split with `-->8` into
tabs: globals / screens / level+grid / movement+rules / draw / data. No entity-type table system —
static hazards and a 90-cell char grid make plain functions over the grid much cheaper than the
Celeste object model. First two lines are `-- stack runner` / `-- by roberto freire` for the label.

Estimated ~2500–3000 of the 8192 token budget.

## Files

| File | Change |
|---|---|
| [game.p8](game.p8) | The whole game. Insert `__gfx__` after `__lua__`; write `__lua__`. Keep `version 43` and CRLF. |
| [STACK-RUNNER.md](STACK-RUNNER.md) (archived here) | Game design doc — rules, legend, level-by-level notes, controls. |
| scratchpad `gen.js` | Node generator: ASCII-art tiles → `__gfx__`, ASCII level maps → `__map__` (plus the 8x8 editor legend sprites), splices both into `game.p8`. Asserts every `__gfx__` line is 128 chars and every `__map__` line 256, then round-trips the map back to level strings. Lives in the scratchpad, not the repo (per PICO8-TOOLING.md). Once a level has been hand-edited in PICO-8 the map is the source of truth — do not re-run `gen.js`, it would overwrite it. |
| scratchpad `genplayer.js` | Node generator for the nine player tiles: ASCII art -> `__gfx__` 12-23 / 36-47, with a guard that refuses to overwrite a non-empty pixel and a round-trip that re-renders every player tile out of the written cart. Scratchpad only. |
| scratchpad `tiles.js` + `patch.js` | Node generator for the tile art: 32 ASCII-art 12x12 tiles -> `__gfx__`, plus the two Lua edits that make the board pick a slab / course variant. It overwrites only the 12x12 rects it owns, so the 8x8 editor legend at sprites 48-61 survives, validates every tile at 12x12 and every written `__gfx__` line at 128 hex chars, trims trailing all-zero lines, and normalises CRLF (git autocrlf hands the cart back with it). Scratchpad only. |
| scratchpad `preview.js` / `zoom.js` | Render tiles.js to PNG as a magnified sheet and as a mock board, so the art can be judged before it goes near the cart. |
| scratchpad `driver_shot.lua` + `fb2png.js` | Dump the real framebuffer over `-x` and turn it into PNGs -- the only way to check the art as PICO-8 actually draws it. |
| scratchpad `genmusic.js` | Node generator for the soundtrack: chord blocks -> `__sfx__` 8-19 + `__music__` 0-3, spliced into `game.p8`. Asserts every sfx line is 168 chars, refuses to run twice (it bails if `__music__` is already present), and round-trips the written notes back to note names. Scratchpad only, like the other generators. |
| scratchpad `engine.js` + `solve.js` | The JavaScript mirror of the cart's rules, and the state-graph / simple-path / trap / exit-stack search over it. Scratchpad only. |
| scratchpad `levels.js` + `patch_assets.js` | The 16 floors as ASCII, and the generator that writes them into `__map__` (and shifted the 8x8 editor legend down one slot when the pusher left `mchr`). Round-trips the map back out of the cart and diffs it. |
| scratchpad `chainpath.js` / `trim.js` / `controls.js` / `report.js` | Chain search, the card-thinning pass, the mandatory-element control experiments, and the numbers that go into LEVELS.md. |
| scratchpad `mkdoc.js` | Writes `LEVELS.md` from `levels.js` + the solver output, so the boards, quantities and metrics in the doc cannot drift from the cart. |
| scratchpad `mkharness.js` | Verification harness, copied into the carts folder as `_test.p8` to run, then deleted. |

## Level progression (16)

**Rebuilt from scratch on 2026-08-22 (TODO item 12).** The full design record — every floor's
grid, the pieces and quantities, the verified line, the specific mistake each floor punishes and
the solver numbers behind all of it — is [LEVELS.md](LEVELS.md) in this folder. Summary:

1. Cards are objects. A press spends the top card, a card on the floor is picked up as you cross it.
2. LIFO: the last card you pick up is the next one you spend. Card lanes pay for the ring.
3. Runs stop at walls. A ladder of four shafts; which rung you take is the whole puzzle.
4. **Crate intro.** One push clears the shaft; the push from the other side seals the stair.
5. Two crates, one pocket each, and only one of them is between you and the stair.
6. **Guard intro.** He blocks his square and kills whatever stops beside him. Run past, do not stop.
7. Two guards, two squares apart: three safe cells, so card length is survival.
8. **Door and switch intro.** One switch, every door, both directions at once.
9. **Bomb intro.** A crate with the stair behind it cannot be pushed, only blown.
10. The same throw on a guard: the range you can throw from is the range that is safe.
11. **The fork.** Four items, three pockets, and the cards to reach them compete with the cards to leave with.
12. Two sealed shafts — a closed door and a guard — and you open the one you brought the key for.
13. A crate as a brake: push it into the corridor so the max run stops short of the guard.
14. The switch swings both ways, a guard holds the exit, and a crate is there to waste your time.
15. Bomb the guard first, keep the switch for the last door. One route, fixed order.
16. Finale: crate in, bomb past, switch out, two guards, and no other order finishes.

Design bar, enforced by the solver rather than asserted: **every floor has at least ten possible
paths and at least two distinct winning lines**; every floor that introduces a piece is
re-solved with that piece neutralised and has to come back **unsolvable**; every guard floor has
a reachable death; and every floor has reachable **trap** states it can no longer be won from.
Card counts were then thinned automatically — any card the floor still solves without, and still
leaves the same stack without, was deleted — bringing the average from ~19 to ~15 per floor.

## Verification

1. **Every change:** `timeout 40 "/c/Program Files (x86)/PICO-8/pico8.exe" -x game.p8; echo "EXIT=$?"`
   — the pass condition is **no runtime error on stdout**. The cart itself never calls
   `extcmd("shutdown")`, so it sits on the title screen and the run ends at the timeout with
   `EXIT=124`; only a harness build exits 0. A Lua error prints and exits well before 40s.
2. **Generator round-trip:** after `node gen.js`, re-parse `game.p8`, re-render `__gfx__` as ASCII
   and each level string as a grid, and diff against the generator's source art. Width asserts
   alone cannot catch a sprite-offset bug.
3. **Screen harness.** A driver overriding the `btn`/`btnp` globals with a `bhold` "held button"
   model — `btn` true every frame it is down, `btnp` true on frame 1 then every 4 frames after 15,
   matching the real auto-repeat — and `printh`ing `mode` after each press. Pass condition: 🅾️ on
   the title reaches mode 3; ❎ **held for 50 frames** in the tutorial ends at mode 0, not mode 1;
   ❎ held on the title starts exactly one run with `#mv` and `#it` untouched. The tap-only version
   of this harness passes even with a broken latch — the hold is the whole test. A second pass
   calls `print(s,x,-20)` on every title/tutorial string and asserts the returned rightmost x is
   ≤128, which is the only reliable width check given ❎/🅾️ count as 1 char but draw 8px.
4. **Walk harness.** A driver appended to `__lua__` overrides `btnp`, wraps `settle`/`endturn`
   with counters and builds synthetic boards. Confirms: a 3-step move animates over exactly 9
   frames with `settle` firing once at the end; a blocked move starts no walk and spends no
   card; each facing resolves to the right tile triple with flip only on right; three pickups laid in a
   row enter the stacks on frames 105/108/111, one per cell, and leave the grid one at a time;
   and a direction pressed mid-walk is ignored. `_draw` is deliberately *not* stubbed, so the
   run also proves `sspr` accepts the fractional destination and the flip argument.
5. **Guard-phase harness.** A driver appended to `__lua__` overrides `btnp`, builds a synthetic
   10x9 board with a guard two cells to the player's right, and `printh`s `px,py,ph,#mv` around
   each phase. Confirms: the move lands adjacent *before* the hold; an arrow press during the
   hold changes nothing but the countdown; the kill fires exactly on the 30th frame; a move with
   no guard and a move blocked *by* a guard never arm the hold.
6. **Stuck harness.** A driver appended to `__lua__` overrides `btn`/`btnp` and builds a bare
   synthetic board. Sixteen assertions, all passing: a move that empties the stack does not arm
   the modal; the *next* arrow does, without moving the player or pushing a snapshot; arrows and
   ❎ are inert while it is up (checked on all three exit paths, including ❎ over an item stack
   that still has a bomb in it); 🅾️ closes it and hands the card back; a run whose last action
   was an item use rewinds past it to reach a card; an empty history drops a floor and restores
   that floor's entry stack; a move blocked by a wall while cards remain still just buzzes; and
   🅾️ with cards left is still a plain one-step undo.
7. **Solvability harness — the important one.** A JavaScript model of `step` / `domove` /
   `useit` / `settle` / `endturn` / `boom` and the walk-order pickups searches each floor's whole
   reachable state graph from the stack that actually arrives at it, then a depth-first search
   over *(floor, movement stack, item stack)* chains the floors together using each floor's real
   exit stacks as the next floor's entry stacks. That produced a concrete **157-press run
   through all sixteen floors**. `mkharness.js` then builds `_test.p8` = `game.p8` with a driver
   appended to `__lua__` that overrides the **globals** `btn`/`btnp` (PICO8-TOOLING.md confirms
   `poke(0x5f4c,...)` does *not* drive `btnp` on this install) and feeds one press per idle
   frame. Pass condition, met: the cart walks from the title screen to the win screen and prints
   both stacks at every floor entry, all sixteen matching the model exactly. This is what proves
   the carry-over budget is satisfiable in the shipping cart and not just in the model.
8. **Music harness.** Headless `-x` does not advance the mixer -- `stat(54)` stays on pattern 0
   for the whole run and a fired sfx never clears -- so playback *progression* cannot be tested
   this way, and the loop is a manual listen in PICO-8. What is checkable, and was checked:
   `stat(46..49)` reports sfx 8/12/16 on channels 0/1/2 with channel 3 idle, and `sfx(0)` lands on
   channel 3 without displacing any of them; and `peek`ing the parsed data at `0x3100` returns
   `88 0c 10 44 / 09 0d 11 44 / 0a 0e 12 44 / 0b 8f 13 44` -- loop-start packed into bit 7 of
   pattern 0's first byte, loop-end into bit 7 of pattern 3's second -- with
   `peek(0x3200+n*68+65)==32` for all twelve music sfx.
9. **Manual pass in PICO-8** for feel and HUD legibility; check the token counter in the editor
   against 8192.
10. Delete `_test.p8` and any generated harness afterwards — build output, not source.

## Assumptions (flag if wrong)

- The run starts with three `a` cards (was two until 2026-08-22 — floor 1 needs three).
- Full movement stack ⇒ pickup is not collected and remains on the grid.
- Boxes push only into empty floor (not onto open doors, stairs, or pickups).
- Enemy resolution happens once after the full movement, not after each step.
- The bomb never harms the player.
- Rewind and restart both cost nothing; there is no move/score/par tracking.

## Cover art

`__label__` (the Splore/BBS thumbnail and the picture baked into `stackrunner.p8.png`) is
generated by [labelgen.p8](labelgen.p8) (archived here) — never hand-edited hex. The cover was rebuilt from
scratch on 2026-08-22 (TODO item 15) and the rules changed with it:

- **Nothing is drawn from the sprite sheet.** The old cover blitted the game's own 12x12 tiles, so
  the runner on it was a 12x12 sprite scaled up and the whole thing had to be regenerated every
  time the sheet changed. Every pixel is now a plain PICO-8 primitive, which is also the only way
  to draw a figure bigger than a tile.
- **The runner is the subject, at ~62px — roughly six and a half heads.** He is built form by
  form (cloak, far arm, rear leg, lead leg, torso, hood, near arm), each one laid down as a flat
  stencil in colour 12 and immediately replaced by `shade()`, which marches up-left and
  down-right through the stencil to find the lit edge and the shadow edge. A form laid over an
  earlier one bites a black contour out of it first — without that, the far arm merges into the
  cloak's rim light and stops reading as an arm.
- **One torch is the only light.** The backdrop (brick wall, arch, flagstones) is drawn flat and
  then relit by `relight()`, a dithered per-pixel pass that steps values up near the sconce and
  down away from it, so everything falls off together. The sconce and its flame go on *after* that
  pass, at full value — a light source dimmed by its own falloff looks wrong. `sin` runs backwards
  in PICO-8, which is why the flame's width term is negated.
- **Palette 0/5/6/7, enforced.** The generator sweeps the screen before dumping and reports
  `offpalette=`, which must be 0. Red (8) belongs to the guard and the guard is not on the cover.
- Composition: block-font logo across the top 47 rows, torch on the left wall, the runner striding
  right through the middle, and the arch with its stair — the goal of every floor — on the right.

The art also lives in `labelgen.p8`'s **own `__gfx__`**, which is a 128x128 sheet: exactly the
size of the label. Open `labelgen.p8` in PICO-8 and the whole cover is there in the sprite editor
to repaint by hand. `sheet=true` (the default) makes the dump `memcpy(0x6000,0x0,0x2000)` the
sheet over whatever the code composed, so hand edits reach the label untouched; `sheet=false`
recomposes from code instead, and the new dump then has to be written back into `__gfx__` to keep
the two in step. This is the one place a sprite sheet is edited by hand — the game's own sheet
is not touched by any of it.

```
"/c/Program Files (x86)/PICO-8/pico8.exe" -x labelgen.p8 > dump.txt
node label-tool.js dump.txt game.p8 preview.png 3
"/c/Program Files (x86)/PICO-8/pico8.exe" game.p8 -export "stackrunner.p8.png"
```

The third line re-bakes the cartridge image, which carries its own copy of the label. Verified
2026-08-22: `offpalette=0`, the sheet round-trip is pixel-identical to the composed art, and
`_test.p8` (game.p8 + a 200-frame driver) boots and runs with the new label spliced in.
