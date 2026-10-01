# PICO-8 Memory Map

All addresses are byte addresses. `peek/poke` (1 byte), `peek2/poke2` (2 bytes, signed 16-bit),
`peek4/poke4` (4 bytes = one 16:16 fixed-point number). Multi-byte values are little-endian.
`memcpy(dst,src,len)`, `memset(dst,val,len)`, `reload(dst,src,len,[cart])` (from cart ROM),
`cstore(dst,src,len,[cart])` (to cart ROM).

## Base RAM

| Address | Size | Contents |
|---|---|---|
| `0x0000` | 0x1000 | Sprite sheet, sprites 0–127 (top half) |
| `0x1000` | 0x1000 | Sprite sheet 128–255 **/ shared with** map rows 32–63 |
| `0x2000` | 0x1000 | Map, rows 0–31 (128 tiles wide, 1 byte per tile) |
| `0x3000` | 0x0100 | Sprite flags, 1 byte per sprite (bit n = flag n) |
| `0x3100` | 0x0100 | Music, 64 patterns × 4 bytes |
| `0x3200` | 0x1100 | SFX, 64 sfx × 68 bytes |
| `0x4300` | 0x1300 | General use / user data (free scratch, survives `reload`) |
| `0x5600` | 0x0800 | Custom font (0.2.2+); otherwise general use |
| `0x5e00` | 0x0100 | Persistent cart data — `cartdata()`/`dget`/`dset`, 64 × 4 bytes |
| `0x5f00` | 0x0040 | **Draw state** |
| `0x5f40` | 0x0040 | **Hardware state** |
| `0x5f80` | 0x0080 | GPIO pins |
| `0x6000` | 0x2000 | Screen (128×128, 4bpp) |
| `0x8000` | 0x8000 | Extended user RAM (0.2.4+) — not saved in the cart |

**Pixel layout** (sprite sheet and screen alike): 2 pixels per byte, 64 bytes per row.
The **low nibble is the left pixel**. Screen pixel (x,y) → `0x6000 + y*64 + x\2`.

## Draw state — `0x5f00`–`0x5f3f`

| Address | Size | Register |
|---|---|---|
| `0x5f00` | 16 | Draw palette (`pal(c0,c1,0)`). Low nibble = target colour, bit `0x10` = transparent (`palt`) |
| `0x5f10` | 16 | Screen/display palette (`pal(c0,c1,1)`) — remaps colours at scan-out |
| `0x5f20` | 4 | Clip rect: x0, y0, x1, y1 (`clip`) |
| `0x5f25` | 1 | Pen colour (`color`). High nibble is the secondary colour used by `fillp` |
| `0x5f26` | 2 | Text cursor x, y (`cursor`, advanced by `print`) |
| `0x5f28` | 4 | Camera offset: x (2 bytes signed), y (2 bytes signed) (`camera`) |
| `0x5f2c` | 1 | Screen mode (see below) |
| `0x5f2d` | 1 | Devkit input: `1` enable mouse/keyboard, `+2` lock pointer, `+4` hide cursor |
| `0x5f2e` | 1 | `1` = keep palettes across cart reboot / load |
| `0x5f30` | 1 | Set to `1` to block the pause menu opening this frame |
| `0x5f31` | 3 | Fill pattern (`fillp`): 2 bytes of 4×4 bitmask + transparency byte at `0x5f33` |
| `0x5f34` | 1 | Fill-pattern flags — bit `0x1` = also apply the pattern to sprite draws |
| `0x5f38` | 4 | `tline` texture wrap: width mask, height mask, x offset, y offset |

Undocumented/reserved: `0x5f24`, `0x5f2f`, `0x5f35`–`0x5f37`, `0x5f3c`–`0x5f3f`.
`cls()` resets only the clip rect and text cursor; palettes, camera and fill pattern persist.

**Screen modes (`0x5f2c`):** `0` normal · `1` 64×128 stretched · `2` 128×64 stretched · `3` 64×64 ·
`5/6/7` horizontal/vertical/both mirroring · `129/130/131` horizontal/vertical/both flip ·
`133/134/135` rotate 90°/180°/270°.

## Hardware state — `0x5f40`–`0x5f7f`

| Address | Size | Register |
|---|---|---|
| `0x5f40` | 1 | Per-channel half-speed bitmask (bit 0 = channel 0) |
| `0x5f41` | 1 | Per-channel reverb bitmask |
| `0x5f42` | 1 | Per-channel distortion bitmask |
| `0x5f43` | 1 | Per-channel low-pass filter bitmask |
| `0x5f44` | 4 | RNG state — `poke4` to seed deterministically, `peek4` to save/restore |
| `0x5f4c` | 8 | Button state, one byte per player 0–7. Poking it drives `btn()` **but not `btnp()`** — see gotchas |
| `0x5f5c` | 1 | `btnp` auto-repeat delay in frames (default 15; `255` = disable repeat) |
| `0x5f5d` | 1 | `btnp` auto-repeat interval in frames (default 4) |
| `0x5f5e` | 1 | Colour bitplane mask: high nibble = write mask, low nibble = read mask |
| `0x5f5f` | 1 | `0x10` enables the 16-byte hardware colour table below |
| `0x5f60` | 16 | Hardware colour table — per-pattern colour substitution when `0x5f5f` is set |

`0x5f70`–`0x5f7f` is reserved. Hardware state is **not** reset between carts unless you clear it.

## GFX / MAP / SCREEN remapping (0.2.4+)

These four bytes hold *page numbers* (the high byte of an address), so `0x60` means `0x6000`.
They redirect where the drawing hardware reads and writes:

| Address | Default | Meaning |
|---|---|---|
| `0x5f54` | `0x00` | Sprite-sheet source for `spr`/`sspr`/`map`/`sget`/`tline` |
| `0x5f55` | `0x60` | Screen destination for every draw call |
| `0x5f56` | `0x20` | Map source for `map`/`mget`/`mset`/`tline` |
| `0x5f57` | `0x80` | Map width in tiles (`0` means 256) |

Useful combinations:
- `poke(0x5f55,0x00)` — draw into the sprite sheet instead of the screen (render-to-texture).
- `poke(0x5f54,0x60)` — use the screen as the sprite sheet (feedback / blur effects).
- `poke(0x5f54,0x80) poke(0x5f55,0x80)` — an off-screen buffer in extended RAM at `0x8000`.
- `poke(0x5f56,0x80) poke(0x5f57,0x40)` — a 64-wide map living in extended RAM.

Always restore the defaults when finished, or later draws land in the wrong place.

## Gotchas
- **`poke(0x5f4c,…)` does not fully simulate input.** Verified: after `poke(0x5f4c,34)`,
  `btn(1)` and `btn(5)` return true and `btn()` returns `34` — but `btnp()` still returns
  false forever, because it edge-detects against real hardware input rather than this
  register. Anything gated on `btnp` (jumps, menu confirms) will never fire. To script input
  for a test, override the `btn`/`btnp` globals in Lua instead — see
  [PICO8-TOOLING.md](PICO8-TOOLING.md).
- `0x1000`–`0x1fff` is shared: sprites 128–255 **and** map rows 32–63 are the same bytes.
- Extended RAM (`0x8000`+) is runtime-only — it is never saved to the cart and starts zeroed.
- `cstore`/`reload` operate on the *cart file*, not RAM, and are limited to 64 calls per cycle.
- `memcpy` between overlapping regions is safe (it behaves like `memmove`).
- Persistent data at `0x5e00` only survives if `cartdata("unique_id")` was called first.
