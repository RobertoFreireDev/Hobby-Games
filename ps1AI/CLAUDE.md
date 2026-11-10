# CLAUDE.md — PlayStation 1 games in C++, built only with Claude Code

This repository makes PlayStation 1 (PS1/PSX) games **entirely through Claude Code**.
The human never opens an IDE, image editor, sprite tool or sound editor. Claude writes
every file (code, graphics, sound, levels, CD layout), builds it, runs it in the
**PCSX-Redux** emulator on Windows, checks screenshots and logs, and iterates.
The human plays the game in the emulator and gives feedback.

---

## 0. Golden rules

1. **C++20 only** (no C files except when an SDK example is copied verbatim). Use the SDK's
   C API from C++.
2. **Free and open-source tools only**: PSn00bSDK (SDK + GCC + mkpsxiso), CMake,
   Ninja (bundled with the SDK), PCSX-Redux (with its bundled **OpenBIOS** — never ask for
   or use a Sony BIOS dump), Windows PowerShell. No Sony Psy-Q, no paid tools.
3. **No editors, no binary assets drawn by hand.** Every asset is text in the repo:
   ASCII-art sprites, hex palettes, tile maps as strings, note tables for music,
   vertex arrays for 3D. Assets are converted at boot or at compile time (section 11).
4. **Never say "it works" without evidence.** After each change: build → run
   `tools/test.ps1` → read the TTY log and **look at the PNG screenshots** with the Read tool.
5. Keep each game self-contained in `games/<name>/`; shared code lives in `engine/`.
6. Small, verifiable steps. Build after every meaningful edit; fix every warning in our
   own code (warnings coming from SDK headers can be ignored).
7. Update `games/<name>/GAME.md` (design, controls, status, test recipe) at the end of
   every session that changes the game.

---

## 1. Toolchain (all free)

| Tool | Version | License | Role |
|---|---|---|---|
| PSn00bSDK | v0.24 (`PSn00bSDK-0.24-win32.zip`) | MPL-2.0 | libs, headers, GCC 12.3 `mipsel-none-elf`, `elf2x`, `mkpsxiso`, `ninja.exe` |
| CMake | ≥ 3.21 (4.x works) | BSD-3 | build system (`psn00bsdk_add_executable`, `psn00bsdk_add_cd_image`) |
| PCSX-Redux | latest dev build (Windows x64) | MIT | emulator + debugger + web API; falls back to bundled `openbios.bin` when no BIOS is set |
| PowerShell 5.1+ | built into Windows | — | build/run/test scripts |

Outputs per game: `build/<name>/game.exe` (PS-EXE, fastest to test), `game.elf`, `game.map`,
`game.bin` + `game.cue` (bootable CD image).

Installed on this machine (2026-11-09): PSn00bSDK 0.24, CMake 4.4.4, Ninja 1.11.1,
PCSX-Redux dev build 793 (`30681.20261109.13`).

---

## 2. One-time setup on Windows (human does this once, or Claude does it with permission)

1. **CMake**: `winget install Kitware.CMake` (or the installer from cmake.org).
2. **PSn00bSDK**: download
   `https://github.com/Lameguy64/PSn00bSDK/releases/download/v0.24/PSn00bSDK-0.24-win32.zip`,
   extract and rename the folder to `C:\psx\PSn00bSDK` (short path, no spaces).
3. **PCSX-Redux**: download the "Windows Intel 64-bits" build from the PCSX-Redux GitHub
   README (`https://github.com/grumpycoders/pcsx-redux`, section "Where?") and extract to
   `C:\psx\pcsx-redux`. The download page is a JavaScript app; to fetch it from a script,
   read the newest build id from
   `https://distrib.app/storage/manifests/pcsx-redux/dev-win-x64/manifest.json`, then
   `manifest-<id>.json` in the same folder gives `path` (zip, relative to `https://distrib.app`)
   and `hashes.sha1`. If it complains about a missing runtime, install the
   Microsoft Visual C++ x64 redistributable (free). The first launch is slow and shows a
   one-time "Update configuration" dialog; settings live in `%APPDATA%\pcsx-redux\pcsx.json`.
   Default keyboard mapping for pad 1: arrows = D-pad, X = ✕, D = ○, Z = □, S = △,
   Enter = START, Backspace = SELECT, Q/R = L1/R1, A/F = L2/R2.
4. **Environment variables** (PowerShell). The scripts load these from the user registry
   themselves (`Import-ToolEnv` in `tools/common.ps1`), so a terminal opened before they were
   set still works.

```powershell
[Environment]::SetEnvironmentVariable('PSN00BSDK_LIBS', 'C:\psx\PSn00bSDK\lib\libpsn00b', 'User')
[Environment]::SetEnvironmentVariable('PCSX_REDUX', 'C:\psx\pcsx-redux\pcsx-redux.exe', 'User')
$p = [Environment]::GetEnvironmentVariable('Path', 'User')
[Environment]::SetEnvironmentVariable('Path', "$p;C:\psx\PSn00bSDK\bin", 'User')
```

5. Verify: `mipsel-none-elf-gcc --version` (GCC 12.3.0), `cmake --version`, `ninja --version`,
   `Test-Path $env:PCSX_REDUX`.

SDK reference material on disk (read these instead of guessing APIs):
- Headers: `C:\psx\PSn00bSDK\include\libpsn00b\` (`psxgpu.h`, `psxgte.h`, `inline_c.h`,
  `psxspu.h`, `psxpad.h`, `psxapi.h`, `psxcd.h`, `hwregs_c.h`)
- Examples: `C:\psx\PSn00bSDK\share\psn00bsdk\examples\` (`beginner/hellocpp`,
  `graphics/balls`, `graphics/gte`, `graphics/fpscam`, `io/pads`, `sound/vagsample`, `cdrom/cdbrowse`)
- Docs: `C:\psx\PSn00bSDK\share\psn00bsdk\doc\` (`cmake_reference.md`, `dev_notes.md`, `known_bugs.md`)
- SDK CMake logic: `C:\psx\PSn00bSDK\lib\libpsn00b\cmake\internal_setup.cmake`

---

## 3. Repository layout

```
/
├── CLAUDE.md
├── .gitignore              # build/
├── tools/
│   ├── common.ps1          # shared helpers: env import, space-free repo path, Stop-Redux
│   ├── build.ps1           # configure + build one game (exe + CD image)
│   ├── run.ps1             # build, then open the game in PCSX-Redux for the human
│   ├── test.ps1            # build, run, inject input, save screenshots + TTY log, close
│   ├── new-game.ps1        # copy games/_template to games/<name>
│   └── autoplay.lua        # PCSX-Redux script used by test.ps1
├── engine/                 # shared C++: gfx, gte3d, input, audio, log, fixed-point, util
├── games/
│   ├── _template/          # minimal game every new game starts from
│   │   ├── CMakeLists.txt
│   │   ├── iso.xml
│   │   ├── system.cnf
│   │   ├── GAME.md
│   │   └── src/main.cpp
│   ├── demo/               # 3D playground: engine showcase + toolchain test (see its GAME.md)
│   └── <name>/             # same shape; src/assets/*.hpp hold text assets
└── build/<name>/           # generated, never edited by hand
```

**Path workaround.** This repo lives under a path with spaces and a non-ASCII character
(`...\OneDrive\Área de Trabalho\...`). The SDK's post-build step (`nm ... >game.map` inside
nested `cmd /C`, `internal_setup.cmake`) breaks on spaces, and PCSX-Redux hangs before
the BIOS runs when `-dofile` gets a non-ASCII path. So `Get-RepoRoot` in `tools/common.ps1`
creates and uses a junction `C:\psx\work\ps1AI` → the repo. All tool paths go through it
(`C:\psx\work\ps1AI\build\<name>\...`); files still physically land in the repo's
`build/<name>/`. Never pass `$PSScriptRoot`-based paths to the SDK tools or the emulator.

---

## 4. Bootstrap (done 2026-11-09)

The toolchain, `tools/`, `engine/`, `games/_template/` and `games/demo/` exist and their
tests pass (from the EXE and from the CD image). If anything is missing on a new machine,
redo section 2, then re-verify:
- 2D: `tools/test.ps1 -Game _template -Inputs "70:RIGHT:60,100:CROSS:10" -Shots "60,150"`
  (expect `BOOT OK` and `CROSS frame=100 x=198` in tty.log, hero centred at frame 60 and 90 px
  further right at frame 150); delete `build/_template` afterwards.
- 3D: the recipes in `games/demo/GAME.md` (boot, camera, stairs, `-Iso -Config Release`).

If the first shot looks like a blank or BIOS screen, move shots later (e.g. `"120,210"`).
The files on disk are the truth; sections 5, 9 and 10 only point at them.

---

## 5. Build, run, test

Call the scripts from Claude Code (any shell) like this:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build.ps1 -Game <name> [-Config Release]
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run.ps1   -Game <name> [-Iso] [-Config Release]
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1  -Game <name> -Inputs "<spec>" -Shots "<frames>" [-Seconds N] [-Iso] [-Config Release]
powershell -NoProfile -ExecutionPolicy Bypass -File tools/new-game.ps1 -Name <name>
```

- `-Inputs`: comma list of `frame:BUTTON[:holdFrames]`. Buttons: `UP DOWN LEFT RIGHT CROSS
  CIRCLE SQUARE TRIANGLE START SELECT L1 L2 R1 R2`. Frames count VBlanks (60/s) from the
  moment the game starts. Example: `"30:START,90:RIGHT:45,140:CROSS:8"`.
- `-Shots`: comma list of frames (≥ 60) to capture (`frame_00090.png` …); the emulator
  pauses on each, the script saves the PNG through the web API, then resumes.
- Results land in `build/<name>/test/`: `tty.log` (all `dbg::log`/`printf` output, plus one
  `Received web api request` line per poll; search the whole log, not only the printed tail)
  and PNGs. **Always open the PNGs with the Read tool and describe what you see.**
- `test.ps1 -Iso` boots `game.cue` through the BIOS and `SYSTEM.CNF` instead of loading the
  EXE. Frame numbers then include ~10 s of BIOS/CD boot, so use late shots (e.g. `"900"`) and
  check the log for `boot file : cdrom:\GAME.EXE;1` and `BOOT OK`.
- `test.ps1` starts the emulator **minimized** so it does not steal focus from the human
  (and their keystrokes cannot reach pad 1). `run.ps1` opens a normal window.
- `run.ps1` and `test.ps1` close any running PCSX-Redux **before** building (an emulator
  running the CD image keeps `game.bin` open and mkpsxiso fails with "Cannot open or create
  output image file").
- Debug builds (`-Og`, asserts on) are the default; use `-Config Release` (`-O2`,
  `NDEBUG`) to check performance. Engine sources (`engine/*.cpp`) are compiled with `-O2` in
  every configuration (game `CMakeLists.txt`), so Debug only slows down game code.
- `run.ps1` is for the human: it leaves the emulator open. `-Iso` boots the CD image
  instead of the EXE (do this before calling a game "done").

Script sources (read them before changing behaviour):
- `tools/common.ps1`: `Import-ToolEnv` (loads `PSN00BSDK_LIBS`, `PCSX_REDUX`, `Path` from the
  registry when missing), `Get-RepoRoot` (junction workaround, section 3), `Stop-Redux`.
- `tools/build.ps1`: CMake configure with `$PSN00BSDK_LIBS/cmake/sdk.cmake` + Ninja build;
  silences CMake author warnings from the SDK (`-Wno-author` on CMake 4, `-Wno-dev` on 3.x).
- `tools/run.ps1`: stop emulator → build → `pcsx-redux -run -fastboot -loadexe|-iso`.
- `tools/test.ps1`: stop emulator → build → launch with `-webserver -logfile -dofile autoplay.lua
  -exec <config>` → wait for each shot pause → `GET /api/v1/screen/still` → resume → close;
  exits 2 if the log contains `assert(`.
- `tools/autoplay.lua`: counts VBlanks from `ExecutionFlow::ShellReached` (fallback: 600
  VBlanks), holds scripted buttons with `pad.setOverride`, pauses on shot frames.
- `tools/new-game.ps1`: copies `games/_template` to `games/<name>`.

---

## 6. The loop for every change

1. Read `games/<name>/GAME.md` and the files you will touch.
2. Make one focused change.
3. `build.ps1` → zero errors, zero new warnings.
4. `test.ps1` with inputs that exercise the change and 1–4 shots. Read `tty.log`
   and every PNG. Compare with what you expected; if wrong, fix and repeat.
5. Every few features: `-Config Release` build and an `-Iso` boot check (`test.ps1 -Iso`).
6. Update `GAME.md` (status + the exact test command that proves the feature).

Log useful state with `dbg::log` (`engine/log.hpp`, same format as `printf`) at events
(level start, score change), never every frame. Plain `printf` costs ~2.6 scanlines per
character (a 60-character line is a quarter of a frame) and makes the game stutter.

---

## 7. C++ on the PS1 — rules

The SDK compiles C++ with `-fno-exceptions -fno-rtti -fno-threadsafe-statics
-fno-use-cxa-atexit -march=r3000 -mabi=32` (see `lib/libpsn00b/cmake/flags.cmake`). Our
games add `-Wall -Wextra -Wno-unused-parameter -fno-strict-aliasing` (the last one because
`psxgpu.h` macros write primitive headers through `P_TAG*` casts; at `-O2` that type punning
warns and may be reordered).

**Allowed:** classes, templates, `constexpr`/`consteval`, lambdas (no `std::function`),
`enum class`, namespaces, virtual functions, `new`/`delete` (SDK `malloc` heap), placement new.

**Headers you may use:** SDK-provided `<cassert> <cctype> <cstdint> <cstdio> <cstdlib>
<cstring>`, and the GCC 12.3 freestanding set shipped with the SDK: `<cstddef> <climits>
<cfloat> <cstdarg> <limits> <type_traits> <new> <initializer_list> <bit> <concepts>
<compare> <source_location> <atomic> <version>`, plus all SDK `psx*.h` headers.

**Forbidden:** exceptions, `dynamic_cast`/`typeid`, `<iostream>`, `<string>`, `<vector>`,
`<array>`, `<utility>`, `<map>`, `<memory>`, `<functional>`, `<algorithm>` and any other
hosted STL header, `<cmath>`, `float`/`double` in per-frame code (no FPU: everything is
slow soft-float). There is no `std::move`/`std::forward`/`std::swap`/`std::min`: use
`engine/util.hpp` (`util::min/max/clamp/abs/move/swap/angleDiff`) and add new ones there
(e.g. `FixedVector`). Mark tiny helpers `always_inline` like those: at `-Og` every call costs.

**Patterns:**
- Fixed-point 20.12 everywhere (`ONE = 4096`), see `engine/fixed.hpp`. Angles for
  `isin/icos`: 4096 = 360° (`hisin/hicos`: 131072 = 360°).
- Fixed-capacity containers (`FixedVector<T, N>`, pools, ring buffers) written in `engine/`.
  Allocate at load time, not per frame.
- Global objects must **not** touch hardware in constructors (they run before `main`).
  Initialise hardware in `init()` functions called from `main` in this order:
  `gfx::init` → `input::init` → `audio::init` → `gte3d::init` (3D games) → game.
- Large buffers are `static` (the stack sits at the top of the 2 MB RAM and is small in practice).
- Buffers handed to DMA (`LoadImage`, `SpuWrite`) must be 4-byte aligned (`alignas(4)` / `uint32_t[]`).
- Fixed timestep: one update per `VSync` (60 Hz NTSC). If a frame is too slow, profile
  before optimising.
- Deterministic randomness with `Rng` (xorshift) seeded from a frame counter at "press START".

---

## 8. Hardware cheat sheet

| Part | Facts that matter |
|---|---|
| CPU | MIPS R3000A 33.87 MHz, no FPU, 4 KB I-cache, 1 KB scratchpad at `0x1F800000` |
| RAM | 2 MB (`0x80000000`–`0x801FFFFF`); EXE loads at `0x80010000` |
| GTE | fixed-point 3D coprocessor: rotate/translate/project 3 vertices per op |
| GPU | 1 MB VRAM = 1024×512 16-bit pixels; 2D only (no Z-buffer: ordering table) |
| Textures | 4-bit (16-color CLUT), 8-bit (256-color CLUT) or 15-bit; texture page = 256×256 texels at x multiple of 64, y = 0 or 256 |
| Colors | 15-bit `0bSBBBBBGGGGGRRRRR`; `0x0000` is transparent in textures; `0x8000` = opaque black |
| Video | 320×240 NTSC 60 Hz (this project's default) |
| SPU | 24 ADPCM voices, 512 KB sound RAM, 44.1 kHz, max pitch 4× |
| CD | 2× speed (~300 KB/s), files in ISO9660 8.3 names |
| Pads | 2 ports, digital pad: D-pad, ✕○□△, L1 L2 R1 R2, START, SELECT |

### VRAM map used by `engine/gfx`
```
x:0          320                                    960   1024
y:0   +-------+----------------------------------------+-----+
      | FB 0  | texture pages for sprites (x=320..959, |font |
      |320x240| 10 pages of 256x256 4bpp texels per row)|(SDK)|
y:240 +-------+                                        |     |
      | FB 1  |                                        |     |
y:480 +-------+  second row of pages starts at y=256   |     |
      | CLUTs |                                        |     |
y:512 +-------+----------------------------------------+-----+
```
CLUTs are 16×1 entries packed in `x=0..319, y=480..511` (640 palettes).

---

## 9. Engine

Extend the engine instead of putting hardware code in games. Add new modules (tilemap,
text, scene, music, save) as needed. Current modules:

- `engine/gfx.hpp` / `gfx.cpp`: double-buffered 320×240 NTSC display (FB 0 at y=0,
  FB 1 at y=240, dithering on), `BUF_LEN = 49152` primitive bytes per buffer (asserts on
  overflow), SDK debug font at x=960. Ordering table of `OT_LEN = 16 + OT_3D` slots: 2D layers
  `z = 0..7` in front, the 3D band (`OT_3D = 1024` depth slots, `slot3D(depth)`) in the middle,
  2D layers `z = 8..15` behind (`slot2D(z)`); 2D-only games see the same 16 layers as before.
  API: `init(r,g,b)`, `flip()` (DrawSync + VSync + swap + clear OT), `uploadSprite(rows, w, h,
  palette16)` → `Texture` (ASCII art → 4bpp texture + CLUT, shelf-packed into pages x=320..959;
  `w` multiple of 8, ≤ 248), `sprite(tex, x, y, z)` (SPRT + DR_TPAGE), `rect(x, y, w, h, r, g,
  b, z)` (TILE), `vgradient(x, y, w, h, top rgb, bottom rgb, z)` (POLY_G4), `text(x, y, s, z)`
  (FntSort), `rgb15(r, g, b)`, `primBytes()`. Raw primitives for engine modules (inline):
  `T* p = gfx::next<T>()`, fill it, `gfx::commit(p, slot)`; never committed = never drawn.
- `engine/gte3d.hpp` / `gte3d.cpp`: flat-lit 3D on the GTE (see the demo). World axes follow
  the GTE: X right, **Y down** (floor y = 0, height h is y = −h), Z forward; angles 4096 = 360°.
  `init()` (after `gfx::init`; FOV `SCREEN_DIST = 200`), `setLight(dir, rgb, ambient)`,
  `lookAt(eye, target)` once per frame, `drawMesh(mesh, pos, rot, palette)`, `drawBox(world
  AABB, color)`, `setFloor` + `drawFloor(a, b, fog, fogStart)` (checkerboard at y = 0, drawn
  in the back slot: valid while the camera stays above it), `drawShadow(x, y, z, r, slot)`
  (half-transparent disc), `toCamera`, `slotAt`, `facesDrawn()`. Meshes are built at load time
  into caller-owned `alignas(4)` arrays with `addBox` / `addSphere` (windings fixed automatically;
  ≤ 64 vertices per mesh). Faces with a vertex nearer than `NEAR = 40` or farther than
  `FAR = 4000` are dropped (no clipping on PS1); per-vertex outcodes reject off-screen faces.
- `engine/input.hpp` / `input.cpp`: BIOS pad driver (`InitPAD`/`StartPAD`, 34-byte static
  buffers). API: `init()`, `update()` once per frame, `held/pressed/released(port, PAD_xxx)`,
  `connected(port)` (digital, analog stick or DualShock).
- `engine/audio.hpp` / `audio.cpp`: procedural synth, no sample files. At `init()` it writes
  one looping ADPCM period (28 samples) per waveform `SQUARE TRIANGLE SAW PULSE25` plus 32
  blocks of `NOISE` into SPU RAM at 0x1010. API: `play(voice, wave, hz, vol)` (loops until
  `stop`; for `NOISE`, `hz` is the sample rate), `stop(voice)`, `sfx(voice, wave, hz, hzStep,
  frames, vol)` (one-shot with a per-frame pitch sweep; needs `update()` once per frame). Key
  on/off is written directly to `SPU_KEY_ON/OFF` (the SDK's `SpuSetKey` macro triggers
  `-Wvolatile` in C++20).
- `engine/fixed.hpp`: `fx` 20.12 fixed point (`+ - * /`, `* int`, `/ int`, comparisons,
  `toInt`, `fromInt`, `fromRaw`), `consteval` literals `1.5_fx` / `152_fx` (no soft-float in
  the game), `Vec3` (`+ - * dot`), all force-inlined; and `Rng` (xorshift32 with `next()` /
  `range(lo, hi)`).
- `engine/log.hpp` / `log.cpp`: `dbg::log(fmt, ...)`: printf-style, written to PCSX-Redux's
  debug port (0x1F802080, one store per character, ~20× cheaper than `printf`); falls back to
  `printf` when the port is absent. Output goes to the same tty.log.
- `engine/util.hpp`: `min/max/clamp/abs/move/swap`, `angleDiff(a, b)` (signed, 4096 = 360°).

---

## 10. Game template

`games/_template/` is copied by `new-game.ps1`; every game has the same shape:
- `CMakeLists.txt`: C++20, globs `src/*.cpp` + `engine/*.cpp` (engine files always `-O2`),
  `psn00bsdk_add_executable(game GPREL ...)`, warning/aliasing flags from section 7,
  `psn00bsdk_add_cd_image(iso game iso.xml ...)`. Embed a binary only if ever needed:
  `psn00bsdk_target_incbin(game PRIVATE sym path)`.
- `system.cnf`: `BOOT=cdrom:\GAME.EXE;1`, `TCB=4`, `EVENT=10`, `STACK=801FFFF0`.
- `iso.xml`: mkpsxiso project with `SYSTEM.CNF` + `GAME.EXE` (+ a commented example for
  extra data files). `volume` must be uppercase letters/digits/underscore (≤ 32 chars). File
  names are 8.3, uppercase; the root holds at most 30 entries. CD audio is not used: music is
  synthesized.
- `GAME.md`: headings Concept / Controls / Screens / Status / Test recipes / Known issues.
- `src/main.cpp`: the demo (16×16 hero moved with the D-pad, ✕ beeps and logs
  `CROSS frame=…`); replace it with the new game's code.

---

## 11. Assets without an editor

All assets are C++ source in `games/<name>/src/assets/*.hpp` (or `engine/` if shared).

- **Sprites**: ASCII art, one char per pixel, hex digit = palette index, `.` = transparent.
  Width multiple of 8 (pad with `.`). One `uint16_t[16]` palette per sprite or per family.
  Animation = array of frames with the same size. Design at real size: a 320×240 screen
  fits a 16×16 character comfortably; keep sprites ≤ 64×64.
- **Sprite sheets**: upload each frame with `uploadSprite` at load time (the allocator packs
  them); store the returned `gfx::Texture`s in arrays.
- **Palettes**: write colors with `gfx::rgb15(r, g, b)`; index 0 is reserved (transparent);
  use `| 0x8000` for pure black that must stay opaque. Keep a limited, consistent palette.
- **Tiles & maps**: 8×8 or 16×16 tiles as ASCII art; levels as `const char*` rows where each
  char is a tile id (`#` wall, `.` empty, `@` player start…). Render only visible tiles.
- **Fonts**: `gfx::text` (SDK debug font, `FntSort`) for debug and simple HUDs; for a styled
  font, define 8×8 glyphs as ASCII art and draw them with `sprite`.
- **Sound effects**: `audio::sfx(voice, wave, hz, hzStep, frames, vol)` (pitch sweeps for
  lasers/jumps, `NOISE` for hits); collect a game's effects in `src/sounds.hpp`.
- **Music**: per-channel note arrays (`{note, frames}`), a tiny sequencer stepped once per
  frame, MIDI note → Hz table written as a `constexpr` integer array (A4 = 440).
- **3D models**: describe them as data in `src/assets/*.hpp` (boxes with colors, sphere
  parameters, level boxes) and build `gte3d::Mesh`es at load time with `addBox`/`addSphere`;
  per-face palette indices, palettes as `CVECTOR` arrays (see `games/demo/src/assets/models.hpp`).
- **Large data**: prefer generating content procedurally at boot. Only if EXE + data no
  longer fit in 2 MB RAM: keep the source data as text, add a PowerShell generator in
  `tools/` that writes `.bin` files into the build folder, list them in `iso.xml`, and load
  per level with `CdInit` / `CdSearchFile` / `CdRead` (see `examples/cdrom/cdbrowse`).

Before drawing a sprite, describe it in words in a comment (what it is, size, palette), so
future edits keep it consistent.

---

## 12. Graphics recipes

- **Frame structure**: `input::update()` + `audio::update()` → update game state → queue
  primitives → `gfx::flip()`.
- **Depth**: lower OT index = drawn later = in front. Convention: 0 HUD/text, 2–6 sprites,
  8–12 world/background, 15 far background. 3D (`gte3d`) is sorted between layers 7 and 8:
  HUD and sprites cover it, 2D backgrounds (sky) stay behind it.
- **Primitives** (from `psxgpu.h`, always call the `setXxx()` init macro first):
  `TILE` (solid rect), `SPRT` (texture 1:1), `POLY_F3/F4` (flat), `POLY_G3/G4` (gouraud),
  `POLY_FT4` (textured quad: scaling, flipping via swapped UVs), `LINE_F2`, `DR_TPAGE`.
  Need a new primitive type in a game? Add a helper to `engine/gfx` using the same `alloc<T>(z)`.
- **Transparency**: `setSemiTrans(p, 1)` + the tpage `abr` mode (0 = 50/50, 1 = add,
  2 = subtract, 3 = add 25 %).
- **Scrolling**: keep camera position in `fx`, subtract it when drawing; cull off-screen.
- **3D (GTE)**: use `engine/gte3d` (camera, meshes, boxes, floor, shadows); `games/demo` is
  the reference (camera orbit/follow, physics, blob shadows). Underneath: per object
  `RotMatrix` + `TransMatrix` + `CompMatrixLV(view)` → `gte_SetRotMatrix/TransMatrix`; all
  vertices through `gte_rtpt` once, outcodes per vertex, then per face: reject → back-face
  test → average z → primitive. New 3D features (textured faces, Gouraud) go into `gte3d`.
- **Budget**: the demo draws ~300–420 flat polygons (incl. a 16×16 floor) at 60 fps in
  ~200 of 263 scanlines (Debug). Drop to 30 fps (two `VSync`s) before cutting gameplay.

---

## 13. Input recipes

- Pads use bit masks from `psxpad.h`: `PAD_UP PAD_DOWN PAD_LEFT PAD_RIGHT PAD_CROSS
  PAD_CIRCLE PAD_SQUARE PAD_TRIANGLE PAD_START PAD_SELECT PAD_L1 PAD_L2 PAD_R1 PAD_R2`.
- Use `pressed` for one-shot actions (jump, menu select), `held` for movement.
- Pause on `START`, show "PRESS START" on the title screen; handle a missing pad
  (`input::connected(0)` false → show "CONNECT CONTROLLER").
- Analog sticks: extend `input` using `PADTYPE`'s analog fields when `type == 0x7`.

---

## 14. Debugging

1. **TTY log**: `dbg::log` (and `printf`, slow) go to the emulator log → `build/<name>/test/tty.log`.
2. **Asserts**: debug builds print `file:line: assert(expr)` and hang; `test.ps1` exits with
   code 2 when it sees one.
3. **Crash address → source line**:
   `mipsel-none-elf-addr2line -e build/<name>/game.elf -f -C 0x80012345`.
   Symbols are also listed in `build/<name>/game.map`.
4. **Black screen checklist**: `SetDispMask(1)` called? `flip()` each frame? primitive buffer
   overflow (assert)? init order correct? Was `BOOT OK` printed?
5. **VRAM problems**: ask the human to open PCSX-Redux's VRAM viewer (Debug menu), or check
   the allocator asserts; textures must stay out of the framebuffer area (x 0–319, y 0–479)
   and the font area (x ≥ 960).
6. **Performance**: `VSync(1)` returns scanlines since the last VBlank (263 = one NTSC
   frame): read it around a section to time it (the demo logs `lines=<physics>+<render>` in
   its STATE line); `VSync(-1)` is the VBlank counter (fps). Check Release first.
7. The human can always press keys in PCSX-Redux (`run.ps1`) and report what they see;
   ask precise questions ("does the hero stop at the right wall?").
8. **"Emulator web API unreachable"** with a log that stops at `OpenBIOS detected`: the
   emulator hung before running the BIOS, which happened when a path given to it contained
   non-ASCII characters (section 3). Probe by hand: launch with `-webserver` and poll
   `GET /api/v1/execution-flow`.
9. **Unexplained movement/presses** (seen even in `test.ps1` runs with the minimized
   window): suspect real keyboard input first (the window takes focus; arrow keys = D-pad,
   X/Z/S/D = face buttons). Log every press (the demo logs `PRESS <button> frame=`) and compare
   with the script before suspecting the game; rerun if they differ.

---

## 15. Pitfalls (check before debugging further)

- Sprite width not a multiple of 8, or DMA buffer not 4-byte aligned → garbled texture.
- CLUT index 0 must be `0x0000`; pure black pixels need `0x8000` or they disappear.
- `POLY_FT4` UV of 256 wraps to 0 (u, v are `uint8_t`) → keep textures off the page's last row/column.
- Pad buffers must stay alive (static) — the BIOS writes to them every VBlank.
- Pad button bits are active-low in `PADTYPE::btn` (the engine inverts them).
- Forgetting `DrawSync(0)` before reusing a buffer passed to `LoadImage`.
- Hardware access in global constructors → freeze before `main`.
- `float`, `double`, 64-bit division in inner loops → huge slowdown.
- Including `<vector>`, `<string>`, `<iostream>`, `<cmath>` → compile/link errors (freestanding toolchain).
- Too many primitives → `BUF_LEN` assert; raise it or draw less.
- `system.cnf` must point at `cdrom:\GAME.EXE;1` and `iso.xml` must contain `GAME.EXE`.
- Changing `gfx::SCREEN_*` requires matching framebuffer/VRAM layout changes.
- Paths with spaces or non-ASCII characters break the SDK post-build step and hang
  PCSX-Redux → always build paths from `Get-RepoRoot` (`C:\psx\work\ps1AI`), never from
  `$PSScriptRoot` (section 3).
- SDK macros that assign to volatile registers in a comma expression (`SpuSetKey`) →
  `-Wvolatile` in C++20; write the registers as separate statements.
- A running emulator with the CD image open locks `game.bin` → the build fails in mkpsxiso;
  the scripts close PCSX-Redux first, do the same in any ad-hoc command.
- After a build-path change, delete `build/<name>` (CMake refuses a cache made for another
  source path).
- SDK GTE load macros (`gte_ldv*`, `gte_ldrgb`, `gte_Set*Matrix`) take pointers but do not
  tell the compiler they read memory: at `-O2` stores to a local `MATRIX` were dropped (wrong
  colors in Release only). Put `__asm__ volatile("" ::: "memory")` before loading fresh data.
- `lwc2`/`swc2` (GTE loads/stores) and word reads of `DVECTOR`s fault on addresses that are
  not 4-byte aligned: `SVECTOR`/`DVECTOR` arrays used with the GTE need `alignas(4)`.
- `psxgpu.h` defines macros with common names (`nextPrim`, `addPrim`, `setXY0`, ...): do not
  name functions like them.
- `int32_t` is `long` on this target: `util::min(int32_t, int)` cannot deduce `T` → `util::min<int>`.
- `printf` in the game loop drops frames (~2.6 scanlines per character) → `dbg::log`.

---

## 16. Working with the human

- The human only uses Claude Code and the emulator. Never ask them to edit files, open an
  IDE, draw images or record sounds.
- Before big features, propose a short plan (screens, controls, data structures) and
  confirm the game design; for small changes just do them.
- After each session: list what changed, the test command used, and which screenshots
  prove it; then ask them to play with `tools/run.ps1 -Game <name>`.

---

## 17. References

- PSn00bSDK: https://github.com/Lameguy64/PSn00bSDK (docs in `doc/`, examples in `examples/`)
- PCSX-Redux: https://github.com/grumpycoders/pcsx-redux — CLI flags:
  https://pcsx-redux.consoledev.net/cli_flags/ ; web API on `-webserver` (port 8080):
  `GET /api/v1/execution-flow`, `POST /api/v1/execution-flow?function=pause|resume`,
  `GET /api/v1/screen/still` (PNG), `GET /api/v1/gpu/vram/raw`
- PCSX-Redux dev builds (JSON): https://distrib.app/storage/manifests/pcsx-redux/dev-win-x64/manifest.json
- PS1 hardware reference (nocash PSX-SPX): https://psx-spx.consoledev.net/
- mkpsxiso (CD images): bundled with PSn00bSDK
