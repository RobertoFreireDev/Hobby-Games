# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Mono8 is a PICO-8 style game engine: a 256×144, 32-color game engine with built-in
sprite, map, SFX and music editors. A game's logic is written in **Lua** (in the `__lua__` section of
`data.mono8`), which [src/game/LuaGame.cs](src/game/LuaGame.cs) runs via an embedded MoonSharp
interpreter, exposing the PICO-8-style API as globals and calling `_init`/`_update`/`_draw`.

The defining structural fact of this repo: **one engine, two heads.** The entire engine and
editor suite lives in [`src/`](src/) as plain `.cs` files. The `web/` project does **not** have
its own copy — it globs the same `..\src\**\*.cs` sources and compiles them against a different
graphics framework.

| Folder | Head | Framework | Entry point |
|---|---|---|---|
| [`src/`](src/) | Desktop | MonoGame.Framework.DesktopGL (.NET 8) | [src/Program.cs](src/Program.cs) → `new Mono8Game().Run()` |
| [`web/`](web/) | Browser | [KNI](https://github.com/kniEngine/kni) BlazorGL (WASM) | [web/Program.cs](web/Program.cs) + [web/Pages/Index.razor.cs](web/Pages/Index.razor.cs) |

KNI (nkast's fork) re-implements the `Microsoft.Xna.Framework.*` namespaces, so the shared engine
code compiles unchanged against either framework. Browser-only divergences are guarded by the
`BLAZORGL` compile define (set in [web/web.csproj](web/web.csproj), never in `src`).

## Commands

```
# Run the web build (restores KNI packages on first build — slow; serves at http://localhost:5259)
dotnet run --project web

# Build / run the desktop head
dotnet build src/mono8.csproj
dotnet run --project src/mono8.csproj

# Publish desktop single-file executables
dotnet publish src/mono8.csproj -c Release -r win-x64   --self-contained true -p:PublishSingleFile=true
dotnet publish src/mono8.csproj -c Release -r linux-arm64 --self-contained true -p:PublishSingleFile=true
```

There is no test suite and no linter configured. Verify changes by building both heads and running
the app.

**When editing shared engine code in `src/`, both heads are affected — build `web/` too, since it
compiles the same files against KNI and its narrower browser surface can break what desktop won't.**

## Architecture

### Game loop and orchestration

- [src/Mono8Game.cs](src/Mono8Game.cs) is the MonoGame/KNI `Game`. It targets 30 FPS, renders the
  scene into a **fixed 256×144 `RenderTarget2D`**, then blits that target (aspect-fit, letterboxed)
  to the real backbuffer. Sizing the target explicitly is deliberate: on the browser the full-canvas
  backbuffer would otherwise make the target canvas-sized and misalign both the render and the
  mouse→virtual-pixel mapping.
- [src/Mono8API.cs](src/Mono8API.cs) (`Mono8API : IEditorAPI`) is the heart. It owns the singleton
  sheets (`SpriteSheet`, `MapSheet`, `SfxSheet`, `MusicSheet`, `AutotileSheet`), the `SfxEngine`, the
  editor registry and the running game, and implements the **entire PICO-8-style API** (`spr`, `map`,
  `sfx`, `btn`, math, etc.). `Load()`/`Save()` read and write the `data.*` files through `FileIO`.
- [src/game/LuaGame.cs](src/game/LuaGame.cs) hosts the user's Lua game (MoonSharp). `Ctrl+R` runs it (`_playingGame`),
  `Esc` returns to the editor. Exceptions in game/editor code are caught by
  [ErrorHandler](src/core/common/ErrorHandler.cs) and drawn on screen rather than crashing the process.

### Editors

Editors implement [IEditor](src/editor/IEditor.cs) (`Init`/`Update`/`Draw`/`Exit`) and are registered
in `Mono8API`'s constructor into an [EditorRegistry](src/editor/EditorRegistry.cs) that lazily
`Init`s the active one and switches between Sprite / Map / Sfx / Music. UI is drawn immediate-mode
via [PixelledSpriteBatch](src/core/graphics/PixelledSpriteBatch.cs) and [Text](src/core/graphics/Text.cs).
The [EditorMenuBar](src/editor/EditorMenuBar.cs) also carries two far-left **Save/Load buttons** that
export/import the whole `data.mono8` cartridge through a host file dialog: they call
`Mono8API.ExportCart()`/`ImportCart()`, which delegate to the `Action` hooks on
[CartIO](src/core/common/CartIO.cs) (mirroring `FileIO.OnWrite`). Those hooks stay null on desktop
(so the buttons are no-ops there) and are wired to browser download / file-picker dialogs by the web head.

### Layout of `src/core/`

`common` (Constants, FileIO, SaveData, ErrorHandler, math helpers) · `graphics` (Screen, Camera2D,
ColorPalette, PixelledSpriteBatch, Text, Menu) · `input` (per-device readers + `InputStateManager`,
surfaced through the `btn`/`mouse*` API) · `sprites`, `maps`, `sfx`, `icons` (the **Sheet** classes —
the only parsers; they load/serialize `data.*` and hand snapshots to the engine).

### Data files

Everything authored in the editors is plain text under [src/data/](src/data/). The whole cartridge
is a single sectioned file, `data.mono8`, whose sections are introduced by `__{ext}__` header lines
(PICO-8 style): `__lua__` (game source), `__gfx__`, `__gff__`, `__atl__`, `__map__`, `__sfx__`, `__music__`. `Mono8API.Save()`
rewrites it in one `FileIO.Write`. [DataFile](src/core/common/DataFile.cs) parses/builds that format;
`Mono8API.Load()/Save()` hand each section to its sheet. Two streams stay separate files: `data.icons`
(built-in, read-only) and `data.save` (rewritten by `dset`). Access always goes through
[FileIO](src/core/common/FileIO.cs), which resolves paths against `Directory.GetCurrentDirectory()/data`.

### How the web head bridges to the browser

`src` assumes a synchronous filesystem and a desktop window; the `web` head supplies both:

- **Filesystem:** the `data.*` files are embedded as resources in [web/web.csproj](web/web.csproj) and
  seeded into the WASM in-memory MEMFS on boot ([Index.razor.cs](web/Pages/Index.razor.cs) `SeedData`).
  Because MEMFS is wiped on reload, `FileIO.OnWrite` mirrors every write to `localStorage`, and a saved
  file wins over the embedded default on reseed — so editor changes survive reloads.
- **Game loop:** JS `requestAnimationFrame` calls back into `[JSInvokable] TickDotNet`, which
  constructs `Mono8Game` on the first tick and drives `Tick()` thereafter.
- **Audio:** the engine's sample rate is matched to the browser `AudioContext`
  ([AudioSettings.SampleRate](src/core/sfx/AudioSettings.cs)), and [index.html](web/wwwroot/index.html)
  wraps the `AudioContext` constructor to resume every context KNI creates on the first user gesture
  (browsers start them suspended).
- **Resize / letterbox:** a JS `resize` listener resizes the canvas backbuffer and calls
  `[JSInvokable] OnCanvasResized` → `Mono8Game.RecomputeScreen` → [Screen.cs](src/core/graphics/Screen.cs).
  The browser uses a single float aspect-fit scale (not desktop's whole-multiple integer scaling).
- [index.html](web/wwwroot/index.html) also suppresses the right-click menu, prevents `Arrow`/`Space`/
  wheel from scrolling an itch.io iframe, and `preventDefault`s `Ctrl+S` (so the browser's save-page
  dialog can't pop over the canvas) / `Ctrl+R`.
- **Cart Save/Load:** `CartIO.OnExport`/`OnImport` are wired ([Index.razor.cs](web/Pages/Index.razor.cs))
  to a browser "save as" download and a file picker, so the menu-bar buttons export/import `data.mono8`.
- **Lua code editor:** the engine's bitmap-font renderer can't comfortably edit the whole `__lua__`
  section, so the web head overlays an [Ace](web/wwwroot/lib/ace/) editor on the (frozen) KNI canvas.
  `Tab` opens it and `Shift+Tab` commits and returns; while open, `TickDotNet` skips `_game.Tick()` (via
  `[JSInvokable] SetAceOpen`) so keystrokes don't leak into the engine's window-wide keyboard shortcuts.
  It reads/writes the same `Mono8API.LuaSheet` the editors use through `[JSInvokable] GetLuaCode`/
  `CommitLuaCode`, so a commit is picked up by the next `Ctrl+R` or menu-bar Save. Ace is vendored offline and
  themed with the DepartureMono pixel font and the PICO-8 palette to match the engine.

## Conventions

- Namespaces mirror folders (`mono8.core.graphics`, `mono8.editor`, …) and common ones are pulled in
  via [src/GlobalUsings.cs](src/GlobalUsings.cs), so most engine files carry no `using` lines. The web
  head disables `ImplicitUsings` and does **not** share `GlobalUsings.cs`, so files it adds may need
  explicit `using`s.
- Both project files set `<Nullable>annotations</Nullable>` (annotations honored, warnings off).
- Guard any browser-incompatible desktop code with `#if !BLAZORGL` (see `Alt+F4`/`F2` handling in
  [Mono8Game.cs](src/Mono8Game.cs)). Keep new engine features running under both heads.
- The full engine/editor/API reference (every API function, all editor hotkeys, the autotile system)
  lives in [src/README.md](src/README.md); web-specific notes and the porting TODO are in the root
  [README.md](README.md).
```