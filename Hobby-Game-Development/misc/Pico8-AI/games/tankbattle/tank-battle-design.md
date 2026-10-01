# TANK BATTLE — PICO-8 Design Doc

A single-screen tank shooter/puzzle in the spirit of the Brick Game handheld
"Tank Battle" (itself a stripped-down Battle City), rebuilt for PICO-8 with a
real palette, dithered art, and a juicy feedback layer.

The Brick Game original is pure reflex. This version keeps the silhouette and
the grid feel, but the *challenge* is positional: fixed wall layouts per level,
a small magazine, and ricochets off steel walls, so clearing a wave is about
choosing firing lanes and bank shots rather than twitch aim.

---

## 1. Technical frame

| Item | Budget |
|---|---|
| Resolution | 128×128, 16 colors (no secondary palette swaps except flash/damage) |
| Tile size | 8×8 (tank, enemy, wall, bullet all fit the grid) |
| Token target | ≤ 6000 of 8192 (leave headroom for level data + juice) |
| Sprite budget | 0–191 gameplay, 192–255 UI/font/logo |
| Map sheet | Rows 0–31 used for level layouts (packed, see §8) |
| SFX | 0–47 gameplay, 48–63 music patterns |
| Music | 3 tracks (intro, game, victory sting) |
| Persistence | `cartdata("rbt_tankbattle_1")` |

---

## 2. Screen layout

```
y=0   ┌──────────────────────────────┐
      │  playfield 14×13 cells       │   x = 8 .. 119
      │  (112 × 104 px)              │   y = 8 .. 111
y=112 ├──────────────────────────────┤
      │  HUD bar (16 px)             │
y=128 └──────────────────────────────┘
```

- Playfield origin: `PF_X = 8`, `PF_Y = 8`.
- Grid: `COLS = 14`, `ROWS = 13`. Cell → pixel: `x = PF_X + col*8`.
- A 4px dithered frame sits in the 8px margin around the playfield (see §9).

### HUD bar (y 112–127)

| Zone | x | Content |
|---|---|---|
| Left | 4–40 | `LV 07` + small tank pip per life remaining |
| Center | 44–84 | Kill quota as a segmented bar: filled blocks / total |
| Right | 88–124 | Ammo magazine: 4 shell icons, dim when spent |

The HUD never scrolls or reflows — only the values animate (§10).

---

## 3. Scene flow

```
        boot
         │
         ▼
   ┌───────────┐  start (❎/🅾️)   ┌───────────┐
   │   INTRO   │ ───────────────▶ │   GAME    │
   │           │ ◀─────────────── │           │
   └───────────┘  menu: "back"    └───────────┘
                                   │  quota met → level up (stays in GAME)
                                   │  lives = 0 → game over card → INTRO
```

Single `state` variable (`"intro"`, `"game"`), each with `_upd`/`_drw` pairs.
Transitions go through a 12-frame wipe (§10.7) so the switch is never a hard cut.

### 3.1 Intro scene

- Title logo (large dithered "TANK BATTLE" drawn from sprites, not `print`).
- `< LEVEL 07 >` selector: ⬅️/➡️ picks any level up to the highest reached.
  Left/right arrows pulse; locked levels are not shown at all.
- `START` button: a 3-state sprite (idle / hover-bounce / pressed) that
  squashes on press before the wipe.
- Idle attract animation: two small tanks patrol the bottom of the screen and
  occasionally fire a bullet that bounces off the frame.
- PICO-8 pause menu: `menuitem(1, "clear progress", ...)`.
  Requires a second confirm entry (`"sure? ok"`) so one stray press can't wipe
  a save. On confirm: `dset` all slots to 0, play `sfx_clear`, flash the screen.

### 3.2 Game scene

- Playfield + HUD only. No pause overlay of our own.
- PICO-8 pause menu: `menuitem(1, "back to intro", ...)` — returns immediately
  (current level progress is not saved mid-wave; the *highest level reached* is
  already persisted on level completion).

### 3.3 Persistence map

| Slot | Meaning |
|---|---|
| `dget(0)` | highest level unlocked (1..N) |
| `dget(1)` | best score |
| `dget(2)` | total enemies destroyed (lifetime, feeds a small intro stat) |

Written only on level complete and on game over.

---

## 4. Entities

### 4.1 Player tank

- Occupies exactly one cell; has a facing (`0=up,1=right,2=down,3=left`).
- **Movement is grid-stepped with a tween**: pressing a direction while facing
  it starts a 6-frame slide to the next cell. Pressing a *different* direction
  only rotates (2 frames) — rotation costs a beat, which is the core of the
  positional pressure.
- Cannot enter: brick, steel, water, enemy cell, or off-grid.
- 3 lives. On hit: 90-frame respawn with invulnerability blink at the spawn
  cell (bottom-center).

### 4.2 Enemy tanks

Spawn at the top row, advance downward, fire on a timer.

| Type | Sprite | Speed | HP | Behaviour |
|---|---|---|---|---|
| Grunt | 32 | 10f/cell | 1 | Walks down, turns at walls, fires every ~90f |
| Runner | 34 | 6f/cell | 1 | Faster, never fires, tries to ram/reach the bottom |
| Gunner | 36 | 14f/cell | 1 | Slow, fires every ~45f, aligns to the player's column |
| Armor | 38 | 12f/cell | 3 | Brick-colored plating; each hit dithers the plating away |
| Boss | 40 (16×16) | 16f/cell | 8 | End of every 5th level; fires 3-shot spreads, destroys brick it touches |

Simple AI: pick a legal direction, prefer the one that reduces distance to the
player, 25% chance of a random choice (keeps it readable but not robotic).

### 4.3 Projectiles

- 2×2 pixel bullets, free-moving in pixel space (not grid-locked), 4 px/frame
  for the player, 2–3 px/frame for enemies.
- Max 1 player bullet on screen unless the level grants a second.
- Player bullets **ricochet off steel** up to 2 times; enemy bullets do not.
  Ricochet leaves a 6-frame spark and a rising pitch on the ping SFX.
- Bullet vs bullet: both are destroyed, small white flash.

### 4.4 Tiles

| Tile | Sprite | Blocks tank | Blocks bullet | Notes |
|---|---|---|---|---|
| Empty | 0 | no | no | dithered floor, 2 variants |
| Brick | 16 | yes | yes | destroyed in 2 hits, crumble animation |
| Steel | 18 | yes | ricochets | never destroyed (boss shots pass? no — bounce) |
| Water | 20 | yes | no | shots fly over; 2-frame shimmer |
| Bush | 22 | no | no | drawn *over* tanks, hides them |
| Spawner | 24 | no | no | top-row marker, pulses before a spawn |

---

## 5. Core rules

1. **Objective**: destroy the level's kill quota without losing all lives.
2. **Quota** scales: `quota = 8 + level*2`, capped at 40. Boss levels need the
   boss plus half the usual quota.
3. **Magazine**: 4 shells. Each shot consumes one; they refill one shell every
   30 frames while not firing. Running dry is the punishment for spraying and
   the reason bank shots matter.
4. **Concurrency**: at most `min(2 + level\2, 5)` enemies alive at once.
   A new one spawns 45 frames after a kill, at a spawner cell, with a 30-frame
   telegraph (pulsing cell + warning blip).
5. **Losing a life**: hit by a bullet, rammed by a Runner, or a Runner reaches
   the bottom row.
6. **Level complete** → quota met → all remaining enemies freeze and explode in
   sequence, score tally flies into the HUD, `dset(0, max(dget(0), level+1))`,
   then the next layout wipes in.

### Scoring

| Event | Points |
|---|---|
| Grunt / Gunner | 100 |
| Runner | 150 |
| Armor | 250 |
| Boss | 1000 |
| Ricochet kill | ×2 multiplier on that kill |
| Level clear | 50 × remaining lives × level |

Ricochet doubling is the explicit nudge toward playing it as a puzzle.

---

## 6. Controls

| Input | Action |
|---|---|
| ⬅️➡️⬆️⬇️ | Rotate if not facing that way, else step one cell |
| ❎ | Fire |
| 🅾️ | Hold to strafe — move without rotating (2 cells max per press, small cooldown) |
| Pause menu | Back to intro (game) / clear progress (intro) |

---

## 7. Level progression

- **20 hand-authored levels**, then an endless mode reusing layouts with
  higher quotas and faster enemies.
- Levels 1–3: open field, Grunts only, teach movement/firing/magazine.
- Levels 4–6: brick mazes — teaches destructible cover.
- Levels 7–9: introduce steel + the ricochet multiplier (a level built around a
  corridor the player can only clear with a bank shot).
- Level 10: first Boss.
- Levels 11–19: mixed enemy types, water lanes, bush ambushes.
- Level 20: Boss + Armor escort.

---

## 8. Level data

Layouts live on the **map sheet**, one level per 14×13 block, 8 blocks per map
row band. Tile ids map directly to the table in §4.4, so `mget` is the level
reader and no decompression code is needed.

Per-level metadata is a single packed string, one entry per level:

```
"quota,enemy_mask,spawn_rate,speed_mod,bullets"
```

Parsed once at level load into a table. Keeps tokens low and tuning fast.

---

## 9. Art direction

### Palette

Base 16, used deliberately:

- **Playfield floor**: dark blue (1) + dark grey (5) dithered 50%, so the field
  reads as textured metal rather than flat black.
- **Frame/margin**: dark grey (5) → black (0) dither gradient, 3 bands.
- **Player tank**: light green (11) body, dark green (3) treads, white (7) pip
  flashing on the rear (the Brick Game tell).
- **Enemies**: grunt orange (9), runner pink (14), gunner light blue (12),
  armor brown (4) plating over red (8).
- **Brick**: brown (4) + orange (9) dither. **Steel**: grey (6) + light grey
  (13) with a 25% highlight dither. **Water**: blue (12) + dark blue (1).
- **Danger red (8)** is reserved: enemy bullets, boss telegraphs, low lives.

### Dithering rules

- Use `fillp` for all large fills (floor, frame, HUD backing, title panel).
- Sprite-level dithering is hand-drawn checker on the *edges* of shapes only —
  brick faces, steel highlights, explosion fringes, boss plating.
- Never dither a 1px line; outlines stay solid so silhouettes stay crisp.
- Every text string gets a black 4-direction outline (`print` 5× offset, or a
  helper `oprint(s,x,y,c)`).

### Spritesheet plan

| Range | Content |
|---|---|
| 0–15 | Floor variants, shadow, empty |
| 16–31 | Tiles: brick (intact/cracked), steel, water (2f), bush, spawner (2f) |
| 32–47 | Enemy tanks, 4 facings × 2 tread frames, per type |
| 48–63 | Player tank, 4 facings × 2 tread frames, + invuln variant |
| 64–79 | Bullets, sparks, ricochet flash, muzzle flash (3f) |
| 80–111 | Explosions: small (5f), large (6f), boss (8f, 16×16) |
| 112–127 | Brick crumble (3f), water splash, bush rustle |
| 128–159 | Boss tank (16×16, 4 facings) |
| 160–191 | HUD: shell icon, life pip, quota block, arrows, button states |
| 192–255 | Title logo pieces, big digits, medal/stat icons |

The doc's rule of thumb: **if something can be a sprite, it is a sprite.**
No `rectfill` placeholders in shipped art except dithered background fills.

---

## 10. Juice catalogue

Every interaction below has *both* an animation and an SFX. This table is the
acceptance checklist.

| # | Interaction | Animation | SFX |
|---|---|---|---|
| 1 | Rotate | 2-frame tread scuff + 1px body kick | `sfx 0` soft click |
| 2 | Step | 6-frame slide, tread cycle, dust puff at the rear | `sfx 1` short tick |
| 3 | Fire | Muzzle flash 3f, tank recoils 1px, 1-frame screen nudge | `sfx 2` |
| 4 | Empty magazine | Magazine icons shake, tank body jitters | `sfx 3` dry clunk |
| 5 | Shell reloaded | Shell icon pops in with a 2-frame scale-up | `sfx 4` blip |
| 6 | Bullet hits brick | Crumble 3f + 4 debris particles | `sfx 5` |
| 7 | Bullet hits steel | Spark burst, bullet reverses, 2px flash | `sfx 6` rising ping |
| 8 | Ricochet kill | Explosion tinted white 2f, "×2" popup rises | `sfx 7` chime |
| 9 | Enemy destroyed | 5-frame explosion, 6 particles, cell flashes | `sfx 8` |
| 10 | Armor plating hit | Plating dithers away one band, tank flashes white | `sfx 9` |
| 11 | Enemy spawn telegraph | Spawner cell pulses 30f, ring expands | `sfx 10` warning blip |
| 12 | Player hit | Screen shake 8f, palette flashes red 2f, tank bursts | `sfx 11` |
| 13 | Life lost (HUD) | Life pip shatters, HUD shakes | `sfx 12` |
| 14 | Quota tick | Quota block fills with a 3-frame pop, HUD bounces 1px | `sfx 13` |
| 15 | Level complete | Enemies explode in sequence, score digits fly to HUD | `sfx 14` + sting |
| 16 | Boss appears | 20f zoom-in card, playfield dims, boss treads shake screen | `sfx 15` |
| 17 | Boss defeated | 8-frame 16×16 explosion, 12f white flash, slow-mo 30f | `sfx 16` |
| 18 | Menu move (intro) | Arrow pulses, level number slides in from the side | `sfx 17` |
| 19 | Start pressed | Button squashes 3f, then wipe | `sfx 18` |
| 20 | Progress cleared | Screen inverts 2f, intro stats reset counting down | `sfx 19` |

Supporting systems:

- **Screen shake**: single `shake` scalar, decays 0.85/frame, applied via
  `camera(rnd(shake)-shake/2, ...)`.
- **Hitstop**: 2-frame freeze on kills, 6 on boss kill.
- **Particles**: one flat table, max 48, each `{x,y,dx,dy,life,col}`.
- **Popups**: floating score numbers, rise 12px over 24f, fade via color ramp.
- **Transition wipe**: 12-frame dithered horizontal wipe using `fillp` bands.

---

## 11. Audio

### Music — cheerful, relaxing 80s action, **no noise channel**

- Instruments limited to **0 (triangle), 1 (tilted saw), 4 (pulse), 5 (organ),
  7 (phaser)**. Waveform 6 (noise) is **banned from every music pattern** —
  percussion is faked with short low-pitch triangle blips and organ stabs.
- **Track 0 — Intro** (8 patterns, ~24s loop): mid-tempo ~100 BPM, major key
  (C major), warm organ pad + a simple pulse melody. Friendly, not urgent.
- **Track 1 — Game** (12 patterns, ~40s loop): ~120 BPM, same key family, adds
  a walking bass on triangle and an arpeggiated pulse. Written as A-B-A-C so it
  doesn't feel like a 4-bar loop. Keeps a bright, non-threatening tone even
  during combat — the "relaxing action" brief.
- **Track 2 — Boss** (4 patterns): same melody transposed down a third, faster,
  phaser lead. Still no noise.
- **Stings**: level complete (4 ascending organ chords), game over (3 descending
  triangle notes, soft — no harsh buzz).

Noise (waveform 6) *is* allowed in SFX — explosions, steel sparks — just never
inside a music pattern, so the soundtrack stays clean under gameplay.

### SFX design notes

- Keep all gameplay SFX ≤ 12 frames of ticks so rapid fire never queues up.
- Reserve **channel 3** for music bass; play one-shots on channels 0–2 with
  explicit channel numbers on the loudest events (player hit, boss) so they
  can't be drowned out.

---

## 12. Implementation roadmap

1. **Skeleton** — state machine, scene switching, wipe, cartdata, menuitems.
2. **Grid + player** — tween movement, rotation cost, collision, strafe.
3. **Bullets** — firing, magazine, brick destruction, steel ricochet.
4. **Enemies** — spawner, 4 types, simple AI, quota tracking.
5. **HUD** — lives, quota bar, magazine, score.
6. **Level loop** — map-sheet loading, metadata string, completion/unlock.
7. **Boss** — 16×16 entity, spread fire, intro/defeat cards.
8. **Art pass** — full spritesheet, dither fills, outlined text.
9. **Juice pass** — work the §10 table top to bottom, nothing skipped.
10. **Audio pass** — tracks 0–2, 20 SFX, mixing check.
11. **Intro polish** — logo, attract mode, level selector, clear-progress flow.
12. **Balance** — quota curve, speeds, magazine refill rate across 20 levels.

---

## 13. Open questions

- **"Puzzle" weight**: this doc leans arcade-with-positional-pressure (fixed
  layouts, magazine, ricochet multiplier). If you want it to be a *true* puzzle,
  the likely change is per-level **limited total ammo** with a deterministic
  (non-random) enemy AI, so every level has an exact solution. That's a
  different game feel — worth deciding before step 4.
- Should destroyed brick regenerate between waves within a level?
- Does the player's base need defending (Battle City's eagle), or is survival
  the only fail condition? Currently: survival only.
- Endless mode after level 20, or loop back to 1 with a "mastery" star?
