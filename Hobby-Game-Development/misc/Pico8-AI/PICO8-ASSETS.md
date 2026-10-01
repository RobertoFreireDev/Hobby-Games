# PICO8-ASSETS.md — Encoding of the .p8 asset sections

Every section is plain ASCII hex, lowercase, one record per line, no separators except
where noted, no trailing whitespace. Missing or short lines are read as zeros, and PICO-8
trims trailing all-zero lines when it saves — so a hand-written cart may legally be much
shorter than the maximums below.

## Section order

Sections must appear in this order (omit any you don't use):

```
pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
__gfx__
__label__
__gff__
__map__
__sfx__
__music__
```

---

## `__gfx__` — sprite sheet

- Up to **128 lines × 128 hex digits**. One digit = one pixel = one palette colour `0`–`f`.
- Line `y` is row `y` of the 128×128 sheet, written **left to right in pixel order** — the
  text looks like the picture.
- Sprite `n` (0–255) is the 8×8 block at `x = (n % 16) * 8`, `y = flr(n / 16) * 8`.
  So sprite `n` = characters `[x, x+8)` of lines `[y, y+8)`.
- Lines 0–63 hold sprites 0–127 (gfx pages 0–1); lines 64–127 hold sprites 128–255
  (pages 2–3), which **share memory with map rows 32–63** (see below).

Reverse lookup: the pixel at sheet coordinate `(sx, sy)` is character `sx` of line `sy`,
and belongs to sprite `flr(sy/8) * 16 + flr(sx/8)`.

## `__label__` — cart label screenshot

- Up to **128 lines × 128 hex digits**, identical encoding to `__gfx__`.
- Purely cosmetic (the image shown in the BBS / cart browser, captured with `ctrl-7`).
  Never accessible from code. Safe to omit or delete.

## `__gff__` — sprite flags

- **2 lines × 256 hex digits**. One sprite = **2 hex digits**, written as a normal byte
  (high nibble first). 128 sprites per line.
- Line 0 = sprites 0–127, line 1 = sprites 128–255.
- Sprite `n`'s byte is at character offset `(n % 128) * 2` of line `flr(n / 128)`.
- Bit `f` of the byte is flag `f` as seen by `fget(n, f)`: flag 0 = `0x01`, flag 1 = `0x02`,
  … flag 7 = `0x80`. So `03` means flags 0 and 1 are set.
- The same byte is the `layers` bitmask tested by `map(...)` and `tline(...)`.

## `__map__` — map data

- **Up to 32 lines × 256 hex digits** (not 64 — see the shared-memory note). One tile =
  **2 hex digits** = a sprite index `00`–`ff`, in normal byte order. 128 tiles per line.
- Line `y` is map row `y`; tile `(x, y)` is at character offset `x * 2` of line `y`.
- Tile value `00` is "empty" and is never drawn by `map()`.
- This section covers map rows **0–31 only** (RAM `0x2000`–`0x2fff`).

### Map rows 32–63 live inside `__gfx__`

Rows 32–63 of the map occupy the shared region at RAM `0x1000`–`0x1fff`, which is the
same memory as **`__gfx__` lines 64–127** (sprites 128–255). They are *not* written to
`__map__`. Use one or the other, never both.

Translating between the two views:

- One map row = 128 bytes; one gfx line = 128 pixels = 64 bytes. So map row `32 + r`
  spans **gfx lines `64 + 2r` and `65 + 2r`** (first 64 tiles, then the next 64).
- **Nibble order differs.** A gfx byte stores its *left* pixel in the *low* nibble, but
  `__gfx__` text is written in pixel order. So a tile byte `0x1a` appears in the
  `__gfx__` text as the swapped pair `a1`.

```
tile 0xHL  ->  gfx text "LH"      (swap the two hex digits)
gfx text "ab" -> tile 0xba
```

If you are generating a cart with a tall map, it is far simpler to keep the map at 32
rows and leave sprites 128–255 empty.

---

## `__sfx__` — sound effects

- Up to **64 lines**, one per SFX 0–63. Each line is exactly **168 hex characters**:

```
[editor_mode:2][speed:2][loop_start:2][loop_end:2] then 32 notes × 5 chars
        2      +    2   +      2      +     2      +        160          = 168
```

### Header (first 8 characters)

| Field | Chars | Meaning |
|---|---|---|
| `editor_mode` | 0–1 | Editor view only: `00` = pitch mode, `01` = tracker/note mode. No effect on playback. |
| `speed` | 2–3 | Ticks per note, `01`–`ff`. `01` is fastest. One tick ≈ 183 samples at 22050 Hz ≈ **1/120 s**, so a note lasts ≈ `speed/120` seconds (speed `10` = 16 → ~0.133 s/note → ~4.25 s for a full 32-note pattern). |
| `loop_start` | 4–5 | Note index to loop back to, `00`–`1f`. |
| `loop_end` | 6–7 | Note index to loop from. `loop_start == loop_end == 00` means no loop. If `loop_start > loop_end`, the SFX plays to `loop_end` then stops early. |

### Notes (32 × 5 characters)

Each note is `[pitch:2][waveform:1][volume:1][effect:1]`.

- **pitch** `00`–`3f` — semitones from `C-0` (≈65.4 Hz). `3f` = `D#-5`. Frequency ≈
  `65.4 * 2^(pitch/12)`.
- **waveform** `0`–`f`:
  `0` triangle, `1` tilted saw, `2` saw, `3` square, `4` pulse, `5` organ, `6` noise,
  `7` phaser. Values `8`–`f` mean **custom instrument**: SFX `0`–`7` used as the
  instrument (`8` → SFX 0, … `f` → SFX 7).
- **volume** `0`–`7`. `0` is silent — that is how you write a rest (`00000` is a clean
  empty note).
- **effect** `0`–`7`:
  `0` none, `1` slide, `2` vibrato, `3` drop, `4` fade in, `5` fade out,
  `6` arpeggio fast, `7` arpeggio slow.

Example — a single C-2 square-wave note at full volume, speed 16, then 31 rests:

```
__sfx__
011000001835000000000000000000000000000000000000...
```
(`01` mode, `10` speed=16, `00` loop start, `00` loop end, then note `18350` = pitch 0x18,
waveform 3, volume 5, effect 0.)

### RAM layout (for `peek`/`poke`)

At `0x3200`, each SFX is **68 bytes**: 64 bytes of notes (2 bytes/note, packed as
6 bits pitch, 3 bits waveform, 3 bits volume, 3 bits effect, 1 bit custom-instrument),
then `editor_mode`, `speed`, `loop_start`, `loop_end`. Note the header is at the **end**
in RAM but at the **front** in the text file.

## `__music__` — music patterns

- Up to **64 lines**, one per pattern 0–63. Each line is `2 hex digits`, a **space**, then
  `8 hex digits`:

```
__music__
00 01424344
01 05064344
```

- **Leading byte = flags**: bit 0 (`01`) = loop start, bit 1 (`02`) = loop end,
  bit 2 (`04`) = stop at end of this pattern. `00` = plain pattern.
- **8 digits = 4 channels × 2 hex digits**, channels 0–3 left to right.
  - `00`–`3f` = play that SFX on this channel.
  - Anything with bit 6 set (`>= 0x40`) = **channel unused**. PICO-8 conventionally writes
    `41`, `42`, `43`, `44` for channels 0–3, but any `4x` reads as "off".
- Patterns play in order from the one passed to `music(n)` and stop at a stop flag or at
  the first line that isn't present.
- In RAM at `0x3100` each pattern is 4 bytes; the flag bits are packed into **bit 7 of the
  first three channel bytes** (byte 0 → loop start, byte 1 → loop end, byte 2 → stop)
  rather than a separate byte.

---

## Practical notes when generating assets

- Get line lengths exactly right. A `__gfx__` line of 127 digits or a `__sfx__` line of
  167 will silently corrupt everything after it on that line. Have the generator **assert
  every width** (`__gfx__` 128, `__gff__` 256, `__map__` 256, `__sfx__` 168) — this is the
  single highest-value check you can automate.
- Prefer generating these sections programmatically over hand-typing long runs of digits.
  On this machine that means a **Node** script; Python is not installed. See
  [PICO8-TOOLING.md](PICO8-TOOLING.md).
- Author sprites and levels as **ASCII art in the script** (one char per pixel, one char per
  tile) and convert to hex at the end. It keeps the source readable, makes alignment
  mistakes visible, and lets you assert row widths. Building a level from fixed-width 16x16
  chunks guarantees columns line up.
- After writing a cart, sanity-check by loading it in PICO-8 rather than by re-reading the
  text — the engine is the ground truth. `pico8.exe -x cart.p8` does this headlessly and
  will surface a malformed section or a Lua syntax error immediately.
- Round-trip as well: parse the generated `.p8` back, re-render the map and sprites as
  ASCII, and compare to what you intended. Width asserts cannot catch a nibble-order or
  sprite-offset mistake; a visual diff can.
- `__gfx__` doubles as a data store: `sget`/`sset` and `memcpy` from `0x0000` let you pack
  tables, level data, or lookup tables into unused sprite rows.
- Sections you don't need should be omitted entirely, not left as pages of zeros.
