# PICO8-TOOLING.md — This machine, and how to actually run a cart

## What is installed

| Thing | Status |
|---|---|
| PICO-8 | `C:\Program Files (x86)\PICO-8\pico8.exe` |
| Node | **v24.15.0** — use this for generator/verification scripts |
| Python | **not installed** (`python`, `py`, `python3` all fail) |
| Shell | PowerShell 5.1 primary; Git Bash also available |
| Carts dir | `C:\Users\rober\AppData\Roaming\pico-8\carts` (this repo) |
| Carts | Each game is `games/<name>/game.p8` — code lives in `__lua__`, no `#include` |

Write throwaway scripts in **JavaScript for Node**. Do not reach for Python.

> **Backslashes do not survive a heredoc through the Bash tool.** `\\2`
> written into a quoted `<<'EOF'` heredoc arrives as `\2`, which turns a JS
> template literal into an octal-escape syntax error and turns a search string
> for PICO-8's `\` integer divide into a string that matches nothing. Build the
> character with `String.fromCharCode(92)`, or write the script with the file
> tool instead of the shell. The cart is full of `\2`, so this comes up.

---

## Running a cart headlessly

This is the important one. You can execute a cart with no window and read its output:

```bash
"/c/Program Files (x86)/PICO-8/pico8.exe" -x cart.p8
```

- `printh(s)` is prefixed `INFO: ` and — verified on this install — arrives on **stderr**,
  not stdout. `2>&1` hides the difference in a shell, but a script that reads only
  `child_process` `stdout` sees nothing at all. **Read both streams.**
  `printh(s,"name")` writes to `name.p8l` in the cart's folder instead.
- `extcmd("shutdown")` ends the run and exits **0**. Without it the process hangs — always
  wire in a frame-count kill switch.
- Always run it under a timeout (`timeout 40 ...`) so a stuck cart can't block.
- **stdout ordering is not reliable.** PICO-8's own `RUNNING: cart.p8` banner interleaves
  with early `printh` output. Don't infer sequence from line order; print explicit counters.

`-x` loads and runs a real cartridge in the real engine, so it catches everything a
hand-written `.p8` can get wrong: a syntax error in the Lua, a malformed hex section, a
sprite flag that isn't where you thought. **A cart that has not been through `-x` is
unverified**, no matter how carefully the text was generated.

## The test-harness pattern

Build a temporary cart that is a copy of `game.p8` with a driver appended to the end of its
`__lua__` section. The copy carries the game and its assets automatically, since both live in
that one file; and because `reload()` reads from the **cart file on disk**, the harness must
sit in the carts folder next to the real one.

Splice the driver in just before the first asset-section marker:

```js
// mkharness.js — writes _test.p8 = game.p8 with driver.lua appended to __lua__
const fs = require('fs');
const cart = fs.readFileSync('game.p8', 'utf8');
const i = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
const driver = fs.readFileSync('driver.lua', 'utf8');
fs.writeFileSync('_test.p8', cart.slice(0, i) + driver + '\n' + cart.slice(i));
```

The driver replaces globals the game already defined, so it has to run **after** the game
code — which is exactly what appending to `__lua__` gives you:

```lua
-- deterministic synthetic input: override the real functions
sb=0 spb=0
function btn(b,pl)
 if b==nil then return sb end
 return (sb\(2^b))%2>=1
end
function btnp(b,pl)
 if b==nil then return sb end
 return ((sb\(2^b))%2>=1) and ((spb\(2^b))%2<1)
end

tf=0
_ru=_update
function _draw() end          -- skip rendering entirely
function _update()
 tf+=1
 sb = tf<40 and 2 or 2+32     -- hold right, then right+X
 _ru()
 spb=sb                       -- latch previous state for btnp
 if tf==150 then
  printh("APEX="..apex)
  extcmd("shutdown")
 end
end
```

Overriding `btn`/`btnp` as globals works because Lua resolves globals at call time — the
game code above picks up the fakes automatically. Delete the generated harness cart
afterwards; it is build output, not source.

### Four ways a harness quietly tests nothing

The first three were hit building the minimap pass, the fourth building the
wall-placement pass. None of them fails loudly.

**1. Stubbing `_update`/`_draw` steals the name from your own tests.** The
driver replaces both globals — that is the whole trick — so from that point on
`_draw()` inside a test calls the *stub*, and every `pget` reads a screen
nothing drew on. Capture first, then call the capture:

```lua
_ru = _update        -- must come BEFORE the override
_rd = _draw
function _draw() end
function _update() ... _rd() ... end   -- _rd, never _draw
```

A whole-screen check that comes back all-zero and "passes" a mutant is the
symptom.

**2. PICO-8 numbers stop at 32767, and an assertion counter is a number.**
A pixel sweep runs to six figures easily, and `checks` wraps to negative
without a word. Count in thousands:

```lua
checks += 1
if checks >= 1000 then checks = 0 kchecks += 1 end
```

**3. Two inverse controls cancel in the same frame.** The mutant that restored
this game's O/X view toggle passed a test that held both buttons: forward then
back is a no-op, so `view` ended the frame where it started. Drive one input
per run, and prove the test can fail — a **mutation pass** is the only thing
that catches a test like this. Break the feature on purpose, one break per
copy of the cart, and assert every copy fails. A mutant that passes is not a
lucky mutant; it is a hole in the suite.

**4. An assertion written against a constant moves when the constant does.**
The mutant that widened this game's wall spacing flipped `min_wall_dist` from
2 to 1 — and passed, because the test said:

```lua
ok(cheb(a.x, a.y, b.x, b.y) >= min_wall_dist, "walls too close")
```

The assertion read the same global the mutation had just edited, so it moved
with it and agreed with whatever the cart believed. **Assert the number, not
the name it is stored under** — `>= 2`, spelled out, even though every other
instinct says not to hardcode it. A test's job is to disagree with the code,
which it cannot do while it is quoting the code back. This is invisible to
review and invisible to a passing run; only the mutation pass finds it, and
only if the mutant edits the constant rather than the logic.

### Do not poke `0x5f4c` to simulate input

Verified on this install: `poke(0x5f4c,34)` makes `btn(1)` and `btn(5)` return true and
`btn()` return `34` — but **`btnp()` never fires from poked state**, because it edge-detects
against real hardware input. A jump wired to `btnp` simply never triggers, while movement
wired to `btn` works fine. The result is a harness that half-works and lies to you — a
poked-input jump test reports an apex of 0.35px and looks like a physics bug.

### Headless `-x` does not advance the audio clock

Verified on this install: under `-x` the mixer is never driven, so playback position
never moves. A 1.4 s SFX still reports `stat(23) == 0` (note index) five seconds after it
started, and `stat(24)` (music pattern) sits on the pattern you passed to `music()` forever —
an eight-pattern loop never reaches pattern 1, let alone wraps.

What you **can** verify headlessly:

- `stat(16..19)` — which SFX each channel was *handed*. Enough to prove routing: that the
  bed took channels 0-2, that gameplay sounds land on the channel you reserved, and that a
  step plays the slot its state should map to.
- The SFX data itself, by peeking `0x3200 + 68*n` — 64 note bytes then mode/speed/loop.
  Assert slots are non-empty and that volume nibbles stay under whatever cap the design calls
  for. `(peek(0x3200+68*n+2*i+1) >> 1) & 0x7` is note `i`'s volume.

What you cannot: tempo, pattern order, loop flags, or anything that depends on time passing.
Check those by parsing the generated text back out and rendering it as a table — pitch names,
waveform, volume, effect per slot — and reading it against what you meant to write.

## Verifying assets

Generate every hex section from a script — never hand-type long runs of digits — and have
the script **assert the line widths** (`__gfx__` 128, `__map__` 256, `__gff__` 256, `__sfx__`
168). A single short line silently corrupts everything after it. See
[PICO8-ASSETS.md](PICO8-ASSETS.md) for the layouts.

Then round-trip: parse the generated `.p8` back, re-render the map as ASCII and the sprites
as a pixel grid, and eyeball that against what you intended. This catches nibble-order and
offset mistakes that a width assert cannot.

## Token count

There is no runtime stat for tokens; `stat(0)` is memory, not tokens. The exact count is only
visible in the PICO-8 editor's code view, so check there before shipping.

For a running estimate while you work, `node tok.js <cart.p8>` lexes the `__lua__` section and
reports an approximate count against the 8192 limit. It is a good-enough budget signal — it
applies PICO-8's rules (comments, whitespace, `,` `.` `local` `end` and closing brackets are
free; a string is one token) but it is not the editor's own counter. Treat a number close to
the limit as "go look in the editor", not as a pass.

## Recipes

```bash
# smoke-test that a cart loads, runs and exits cleanly
timeout 30 "/c/Program Files (x86)/PICO-8/pico8.exe" -x cart.p8; echo "EXIT=$?"

# regenerate assets, then verify in the real engine
node gen.js && timeout 40 "/c/Program Files (x86)/PICO-8/pico8.exe" -x _test.p8
```

Keep generators and harness builders in a scratch directory, not in the repo, unless they
are meant to be re-run. What belongs in the repo is `game.p8`, the archived carts under
`games/`, and the docs.
