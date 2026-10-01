# Human art pipeline: GBC Pixel Editor → C assets

Read when: `resources/` holds exported art (anything besides `file.txt`), or the human says they drew sprites, maps or objects.

## 16. Overview

The human draws in `tools/gbc-pixel-editor.html` (a PICO-8 style sprite / map / object editor) and exports into `resources/`. The AI **does not draw** that art. It converts the files into `assets/*.c` and game code, exactly as drawn.

| File in `resources/` | What it holds | AI turns it into |
|---|---|---|
| `spritesheet.txt` | 8 palettes, then every used 8×8 tile: palette row, its flags (of 64), 8 rows of color indices | `PX(...)` rows and `RGB8(...)` palettes (source of truth) |
| `spritesheet.png` | The same sheet as an image (256×256) | Nothing. Open it with `Read` only to *see* the art. Never decode it |
| `maps/<name>.txt` | Only the grid of tile indices of one map | `ts_*.c` tileset + `map_<name>.c` |
| `objects.txt` | Objects → animations → collision box + frames (grids of tile indices) | `spr_*.c` sprites, `anim_def_t` lists, hitbox constants in `src/game/` |

`resources/` belongs to the human: the AI reads it and never edits it unless asked. It always has `file.txt` (format example) and `maps/file.txt`. The editor and the importer ignore both.

### 16.1 The editor (for the human)

Open `tools/gbc-pixel-editor.html` in a browser; it needs no install and no network. Work is autosaved in the browser; the trash button left of *Import* deletes that saved data (and the remembered `resources/` folder) and reloads the editor. Everything fits in the window without scrolling the page; the drawing canvas and the map view take the space left.

- **Chromium/Chrome/Edge**: *Export → Save to resources/ folder* writes directly into the folder you pick (pick the repo's `resources/` once). `Ctrl+S` exports.
- **Firefox**: the export downloads the files. Move `spritesheet.png`, `spritesheet.txt` and `objects.txt` into `resources/`, and the map files into `resources/maps/`.
- *Import → Open resources folder…* loads everything back. Dropping files on the page imports them too.

| Area | What it does |
|---|---|
| Header | Left: Sprite / Map / Objects editors. Right: Import, Export |
| Spritesheet (bottom, all editors) | 256×256 px = 32×32 tiles (2× PICO-8), shown as bands of 8 tile rows side by side: as many as the window is wide, with page tabs for the rest (none when everything fits). Click or drag to select tiles. Sprite editor: what you edit. Map editor: the brush. Object editor: the source of new frames |
| Footer | Hover or click anything to see its label, shortcut, pixel/tile/cell position, palette, flags |
| Sprite editor | Edit area of 8, 16, 32 or 64 px. Tools: pencil `B`, fill `G`, line `L`, rect `R`, filled rect `Shift+R`, circle `O`, filled circle `Shift+O`, select `S`, color picker `I` (or right-click). Actions: copy/cut/place (`Ctrl+C/X/V`), clear `Del`, flip `H`/`V`, rotate `T`, translate with the arrows, undo/redo `Ctrl+Z/Y`, previous/next tile `Q`/`W`, edit-area size `-`/`=`. 64 flag toggles for the selected tiles (section 16.2), color-coded by group; hover one to see what it does. Right-click a free flag (31–63) to give it a name (up to 6 characters: `A-Z`, `0-9`, `_`, starting with a letter, e.g. `ICE`, `LADDER`) and one of 16 colors (the first five are the fixed groups' colors); *Clear* removes both. 8 palette rows × 4 colors, editable (snapped to the GBC's 15-bit colors) |
| Map editor | Several named maps, each with its own size (up to 256×128). Tools: pencil `B` (stamps the sheet selection), erase `E`, fill `G`, select `S` (copy, cut, delete, paste), tile picker `I` (or right-click), pan `P` (or Space/middle drag, arrows, wheel). `Ctrl+wheel` zooms. Yellow dashed lines mark every 20×18 screen |
| Object editor | Create, rename, duplicate, reorder and delete objects and their animations. Each animation: name, description, size in tiles, speed, loop, collision box (type it or drag on the preview), frames (select tiles on the sheet → *Add frame*). The preview plays the animation. Red dots mark missing fields. `objects.txt` is not exported until every field is filled |

**One palette per tile.** Each 8×8 tile uses one of the 8 palette rows, which is how the GBC works. Drawing with a color from another row moves the whole tile to that row.

**Importing or pasting images.** Import any image, or paste one with `Ctrl+V` (copied from the OS, a website, another program). The editor detects the pixel scale (for example a 4× zoomed screenshot) so one art pixel becomes one sheet pixel. It can shrink images bigger than the sheet. It then either remaps the colors to the current palettes or generates new palettes from the image (into the palette rows you choose), one row per tile. Transparent pixels become color 0. Pasted images float over the spritesheet: move them and click to drop (tile-aligned; `Shift` for pixel positions).

Transparency is not edited in the editor. For a sprite, color 0 of its palette row *is* the transparent color (section 16.5).

### 16.2 `spritesheet.txt`

```
# gbc-pixel-editor spritesheet v2
# ... (comment lines: ignore)

palette 0: 224,232,192 136,168,80 56,104,48 16,40,24
palette 1: 192,224,240 104,160,216 40,96,168 16,40,88
...
palette 7: 24,24,40 8,8,16 112,136,208 240,240,224

flag 40 ICE blue
flag 41 LADDER yellow

tile 0037 row 1 col 5 pal 2 flags SOLID ONEWAY_U ICE 45
01233210
12222221
...                (8 rows of 8 digits)
```
- **Tile index** = `row * 32 + col`, 0–1023, always written with 4 digits. Maps and objects refer to tiles by this index.
- **Palettes**: 8 rows of 4 colors as `R,G,B` 0–255, already multiples of 8, so `RGB8(r,g,b)` reproduces them exactly.
- **Tiles**: only tiles with a pixel ≠ 0, a flag or a palette ≠ 0 are listed. A missing tile is all color 0, palette 0, no flags (`flags -`).
- **Pixel rows** are the `PX` rows: `01233210` → `PX(0,1,2,3,3,2,1,0)`.
- **Flag names**: `flag N NAME color` lines (only when the human named some) name free flags 31–63. The name is the human's hint for what the flag means (`ICE` = slippery floor, `LADDER` = climbable); confirm the details with the human if the name alone leaves the behavior unclear. The color is only for the editor.
- **Flags**: the flags that are on, separated by spaces, or `-` for none. Flags 0–30 are written by their fixed name, named flags 31–63 by the human's name, unnamed ones by number. **The engine knows none of them**: they tell the AI what the human wants each tile to do. When converting, turn only the flags the game uses into the cheapest byte-sized form (section 16.6, step 3):

| Flag | Name in the file | Meaning | Becomes |
|---|---|---|---|
| 0 | `SOLID` | Blocks movement | legend `coll` `COLL_SOLID` |
| 1 | `HAZARD` | Hurts | a tag bit (`TAG_HAZARD`), tested with `body_touch_tags` |
| 2–5 | `ONEWAY_R` `ONEWAY_L` `ONEWAY_U` `ONEWAY_D` | Passable moving right / left / up / down only; blocks the way back. `ONEWAY_U` = jump-through platform | `coll` `COLL_RIGHT` / `COLL_LEFT` / `COLL_TOP` / `COLL_BOTTOM` |
| 6–13 | `SPAWN0` … `SPAWN7` | Spawn markers. What spawns is agreed with the human (`GAME.md`) | nothing: game code finds the map character on load |
| 14–21 | `TRIGGER0` … `TRIGGER7` | Touch triggers (door, sign, switch). What they do is agreed with the human (`GAME.md`) | a tag bit |
| 22–25 | `LEAVE0` … `LEAVE3` | Leave the scene. The destination scene (and its ENTER*n*) is agreed with the human (`GAME.md`) | a tag bit |
| 26–29 | `ENTER0` … `ENTER3` | Where the player appears when arriving, and from which scene, agreed with the human (`GAME.md`) | nothing: found by map character on arrival |
| 30 | `OVER` | BG tile drawn over sprites | `MAP_OVER` in the legend's `pal` |
| 31–63 | the human's name (`ICE`), or `31` … `63` when unnamed | Free, game-defined. The name (or the human) says what flag *X* means | a tag bit if game code tests it while playing, else the map character |

  Older exports (`spritesheet v1`) wrote 16 binary digits (flag 15 … flag 0). The editor still imports them and moves the old flags: 0 SOLID, 1 HAZARD, 2 ONEWAY → `ONEWAY_U`, 3 TRIGGER → `TRIGGER0`, 4 SPAWN → `SPAWN0`, 7 OVER → `OVER`, 5, 6 and 8–15 → 31, 32 and 33–40. Its autosave is upgraded the same way. If `resources/` still holds a v1 file, ask the human to re-export it.

### 16.3 `maps/<name>.txt`

Only the grid: `h` lines of `w` cells separated by one space. A cell is a 4-digit tile index or `----` (empty). The file name is the map name (`maps/level1.txt` → `map_level1`).
```
0001 0001 0001 0001 0001 ...
0001 ---- ---- 0037 0038 ...
```

### 16.4 `objects.txt`

```
# gbc-pixel-editor objects v1
# ... (comment lines: ignore)

object player
description The hero. Walks, jumps, and dies on spikes.

  animation walk
  description Walk cycle facing right; flip for left.
  size 2x2
  collision 3 2 10 14
  speed 8
  loop yes
  frame
    0004 0005
    0036 0037
  frame
    0006 0007
    0038 0039

end
```
- `size WxH` = frame size in tiles (1–8 each). `collision x y w h` = hitbox in pixels from the frame's top-left.
- `speed` = game frames (1/60 s) per animation frame, the engine's `anim_def_t.speed`. `loop yes|no`.
- Each `frame` has `H` rows of `W` tile indices; `----` = empty (transparent) tile.
- Indentation is cosmetic. Every object ends with `end`. Names use letters, digits and `_`.

### 16.5 Converting tiles and palettes

- A tile's 8 digit rows become 8 `PX(...)` rows, in order. Comment every converted tile with its sheet index: `/* 3: sheet 0037, grass top */`.
- Palette row *N* becomes `const palette_color_t pal_<name>[4] = { RGB8(r,g,b), ... };` with the four values as written.
- **Sprites**: color 0 of the row is transparent in the game (whatever color the editor shows); 1–3 are visible.
- **BG tiles**: all 4 colors are visible; color 0 is usually the background.
- A `----` cell and a missing tile are all color 0: an empty BG tile, or a transparent sprite tile.

### 16.6 Converting maps (tileset + map)

For each map, or each group of maps that should share one tileset (levels of the same world; decide in `GAME.md`):

1. **Tiles**: collect the distinct sheet tiles used (ignore `----`). At most **128** per scene. Number them 0, 1, 2… in order of first appearance and write `ts_<name>.c`. If two tiles are mirror images, you may keep one and flip it with `MAP_FLIPX`/`MAP_FLIPY` in the legend's `pal`.
2. **Palettes**: collect the distinct palette rows of those tiles and give them BG slots 0, 1, 2… (at most **7**; slot 7 is the UI). The tileset's `pals` array lists them in slot order.
3. **Legend**: one character per distinct sheet tile *and* set of flags the game uses: `{ ch, tileset index, BG slot of its row (| MAP_OVER), coll, tag }`, converted with the table in 16.2. E.g. `SOLID ONEWAY_U` → coll `COLL_SOLID | COLL_TOP`; `OVER` → pal `2 | MAP_OVER`; `HAZARD TRIGGER1` → tag `TAG_HAZARD | TAG_SWITCH`. Tag bits are the game's own: at most 8, defined as `#define TAG_<NAME> 0x..` in `assets/assets.h`, given only to flags that game code tests while playing (touch, step on). Several flags can share one bit when the game treats them alike; a flag the game never tests gets nothing. A tile whose flags matter always gets its own character, so markers (SPAWN*n*, ENTER*n*) and rare flags can be found by character instead. Pick readable characters: `.` for the most common background, `#` for solid ground, letters for spawn markers. Avoid `"` and `\`.
4. **Empty cells** (`----`): add one all-color-0 tile (palette slot 0) and a legend character for it, usually `' '`, unless `GAME.md` names a background tile for them.
5. **Rows**: write each map row as a string of legend characters, exactly `w` characters, with the column ruler comment from section 6.5 ([graphics.md](graphics.md)).
6. **Spawn and enter markers**: a `SPAWN`*n* or `ENTER`*n* tile is still drawn as itself. If the human drew a marker tile only to show where something starts, draw it in the game as the surrounding background tile. Ask if unsure.
7. **Flags that need the human**: `SPAWN`*n*, `TRIGGER`*n*, `LEAVE`*n*, `ENTER`*n* and flags 31–63 mean what the human says (a named flag 31–63 already hints it: `flag 40 ICE`). Read `GAME.md` → *Tile flags*. If a used flag has no entry there, ask the human what it should do (for LEAVE: which scene and which ENTER it leads to), write the answer there, then implement it in game code: `body_touch_tags` for tag bits, `map_find` (or one scan on load) for markers, `map_char` for flags checked by character (engine-api.md 7.6).
8. **Limits**: the engine supports 20–200 tiles per axis. The screen is 20×18. Report maps outside that range instead of silently cropping or padding.

### 16.7 Converting objects (sprites + animations)

1. **Sprite data**: for each object, list the distinct frame grids of all its animations, in order of first use. Frames with the same size go into one `spr_<object>.c` (`sprite_def_t` w, h = the size in tiles, frames = distinct grids, tiles row-major per frame). Animations of another size get their own `spr_<object>_<anim>.c`.
2. **Palette**: a GBC sprite has one OBJ palette. All tiles of a frame should use one palette row. The editor warns when they don't. If they don't, tell the human; the alternative is overlaying a second sprite per extra row, which costs sprites per scanline. Choose `pal_slot` from the palette plan in `GAME.md`.
3. **Animations**: `static const uint8_t <object>_<anim>_frames[] = { … };` holds indices into that sprite's frames, then `static const anim_def_t anim_<object>_<anim> = { frames, count, speed, loop ? 1 : 0 };`.
4. **Collision box**: the entity's `body_t` gets `w = collision w`, `h = collision h`. Draw the sprite at `body.x - collision x`, `body.y - collision y`. Keep the offsets as `#define`s next to the entity code (`PLAYER_COL_X 3`). If animations have different boxes, keep the bottom edge fixed when switching so the entity doesn't sink or float.
5. **Descriptions** are the human's design intent for behavior. Follow them in game code and copy the key points into `GAME.md`.
6. **Budget**: sprite tiles per scene = sum of `w * h * frames` of the loaded sprites, at most 128. Also check at most 10 sprite tiles per scanline.

### 16.8 Rules

- **Convert exactly.** Never redraw, recolor, crop or "improve" the human's art. When something breaks a hardware limit (section 4 of CLAUDE.md), stop and tell the human which limit, by how much, and the options.
- **Regenerate, don't patch.** After a new export, rebuild the affected `.c` files completely from `resources/`.
- Bulk conversion may use a throwaway Node script in a temp folder (CLAUDE.md rule 1). Never commit it, and the build never depends on it.
- Record in `GAME.md` → *Art source*: which maps and objects became which assets, which tiles share a tileset. Flag meanings, and what each became (`coll`, `MAP_OVER`, `TAG_*` or map character), go in *Tile flags*.
- Art not in `resources/` (font, UI) is still drawn by the AI under section 8 ([graphics.md](graphics.md)).
