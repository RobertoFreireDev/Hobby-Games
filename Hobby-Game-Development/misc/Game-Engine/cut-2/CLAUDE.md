# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

cut-2 is a PICO-8-inspired fantasy console runtime. The C# / MonoGame host loads `main.lua` at startup and calls three Lua lifecycle hooks each frame (`_init`, `_update`, `_draw`). All game logic lives in Lua; the C# layer exists solely to expose the API and drive the game loop.

## Build & run

```sh
cd src
dotnet run
```

- Lua errors are caught and displayed on screen without crashing the host

## Project structure

```
src/
  main.lua            # Lua game script — entry point for game logic
  data.c2sfx          # SFX bank (256 slots, hex-encoded)
  data.c2sprt         # Sprite sheet (128×128 px, color indices as chars)
  cut2.cs             # MonoGame Game subclass — wires up the loop
  core/
    Lua/LuaBinding.cs # Registers all C#→Lua API bindings
    graphics/         # ColorPalette, Screen (letterboxing), Camera2D, PixelledSpriteBatch, Text
    sfx/              # SfxEngine (4-channel, 44100 Hz, PICO-8-compatible)
    input/            # ButtonInput (keyboard + gamepad), MouseInputBinding
    common/           # Constants, FileIO
    sprites/          # SpriteSheet (128×128, 16×16 tiles of 8px each)
```

## Lua API exposed to main.lua

**Lifecycle** (define these functions in main.lua):
- `_init()` — called once on load
- `_update()` — called every frame (60 fps fixed)
- `_draw()` — called every frame after update

**Input** (PICO-8-style button indices: 0=left 1=right 2=up 3=down 4=A 5=B 6=X 7=Y; add 8 for P2):
- `btn(n)` — held, `btnp(n)` — just pressed, `btnr(n)` — released
- `mousel()` / `mouselp()` / `mouselr()` — left mouse held/just-pressed/released
- `mouser()` / `mouserp()` / `mouserr()` — right mouse
- `mouseup()` / `mousedown()` — scroll wheel
- `mousexy()` — returns `{x, y}` table in virtual screen coordinates

**Graphics**:
- `print(msg, x, y, colorIndex)` — draw text at pixel coords
- `cam(x, y)` — set camera offset

**Color / palette**:
- `pal(id)` — switch active palette (0–7); each palette has 4 colors
- Color index `0` = transparent, `1`–`4` = palette colors, `-1` = white, `-2` = black

**SFX**:
- `sfx(n)` — play SFX slot n; `sfx(-1)` stops all; `sfx(n, channel, offset, length)` for fine control

## Key constants

| Constant | Value |
|---|---|
| Screen resolution | 320 × 180 |
| Sprite sheet | 128 × 128 px, 16 × 16 tiles of 8 px |
| SFX bank size | 256 slots |
| Audio channels | 4 |
| Palettes | 8 (each: 1 transparent + 4 colors) |

## Data files

`data.c2sfx` and `data.c2sprt` are loaded from the working directory at startup (same folder as the executable or `src/` when running with `dotnet run`). The Lua script `main.lua` is also loaded from the working directory. Changing any of these files requires a restart — there is no hot-reload.

## Adding new Lua API functions

1. Add a `public static` method to `LuaBinding.cs`
2. Register it in the `LuaBinding` constructor with `_lua.RegisterFunction("luaName", this, GetType().GetMethod(nameof(CSharpMethod)))`
3. The method signature must use types NLua can marshal (int, float, bool, string, LuaTable)