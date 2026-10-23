# Monster Survival — the big menu map

> Written 2026-10-22 as the design; **built the same day** (see the commits after it). Section 9 is the
> technical part. Where the build differs from this text: a trapped monster also shows (caught in vines) on
> the guarded challenge screens before it is freed; gates are opened by a single-target move aimed at them
> like at a monster (a gate is targeted when no monster is in reach); a straight obstacle edge can be walked
> half onto (half a tile), so islands one cell (16 px) off a shore are in reach of a 2-tile move.

## 1. In short

- The menu map grows from **1 screen to 7×7 screens** (1680 × 1120 px). Today's menu screen (cave, garden,
  signs) becomes the middle screen, the **Green Meadow**.
- **Monsters are no longer unlocked by classic wins.** Each one is trapped somewhere on the map, in a land
  guarded by monsters or blocked by an obstacle that only the monster freed just before can get past.
- **One at a time.** Every land's way in needs the previous monster's power, so only one new land is ever
  open. Everything else stays blocked.
- **Outside the Meadow your monster fights.** A, B and R fire its 3 moves, it has HP and it can faint: it then
  wakes up in the Meadow.
- **The camera never scrolls.** It shows one whole screen; when your monster walks off the edge, the next
  screen appears at once.
- **Wild monsters never leave their screen.**
- **WAVES needs all 9 monster types.** The grey sign counts down: `8 MONSTER TYPES LEFT` …
  `1 MONSTER TYPE LEFT`.

## 2. The map

### 2.1 Layout

Screens are named like a chessboard: column A–G, row 1–7. The Meadow is D4. Each land is one of the 9 run
worlds, so the map is a small version of them.

```
        A         B         C         D         E         F         G
   +---------+---------+---------+---------+---------+---------+---------+
 1 | STORM * | STORM   | LAGOON *| LAGOON  | SWAMP   | SWAMP   | SWAMP * |
   +---------+---------+---------+---------+---------+---------+---------+
 2 | STORM   | STORM   5 LAGOON  | LAGOON  6 SWAMP   | SWAMP   | SWAMP   |
   +---------+---------+---------+---------+---------+---------+---------+
 3 | STORM   | STORM   | LAGOON  | LAGOON  4 CRATER  | CRATER  | CRATER *|
   +---------+---------+---------+---------+---------+---------+---------+
 4 | CANYON  | CANYON  | CANYON  1 MEADOW  3 CRATER  | CRATER  | CRATER  |
   +---------+---------+---------+----2----+---------+---------+----7----+
 5 | CANYON *| CANYON  | CANYON  | JUNGLE  | JUNGLE  | SKY     | SKY     |
   +---------+---------+---------+---------+---------+---------+---------+
 6 | HOLLOW  | HOLLOW  | HOLLOW  8 JUNGLE  | JUNGLE  | SKY     | SKY     |
   +---------+---------+---------+---------+---------+---------+---------+
 7 | HOLLOW *| HOLLOW  | HOLLOW  | JUNGLE  | JUNGLE *| SKY *   | SKY     |
   +---------+---------+---------+---------+---------+---------+---------+
```

A number on a border is the way into land 1–8 (1 is an open path, 2–8 are gates). `*` marks the land's
challenge screen. Every other border between two lands is closed (cliff, deep water, lava, thick forest).
Inside a land, its 6 screens are joined by paths.

| Land | Screens | Way in | Challenge screen |
|---|---|---|---|
| 1 Boulder Canyon | A4 B4 C4 A5 B5 C5 | Meadow → C4 (west, open) | A5 |
| 2 Verdant Jungle | D5 E5 D6 E6 D7 E7 | Meadow → D5 (south) | E6 → E7 |
| 3 Ember Crater | E3 F3 G3 E4 F4 G4 | Meadow → E4 (east) | G3 |
| 4 Coral Lagoon | C1 D1 C2 D2 C3 D3 | Crater E3 → D3 | C1 |
| 5 Storm Plateau | A1 B1 A2 B2 A3 B3 | Lagoon C2 → B2 | A1 |
| 6 Miasma Swamp | E1 F1 G1 E2 F2 G2 | Lagoon D2 → E2 | G1 |
| 7 Sky Isle | F5 G5 F6 G6 F7 G7 | Crater G4 → G5 | F7 |
| 8 Haunted Hollow | A6 B6 C6 A7 B7 C7 | Jungle D6 → C6 | A7 |

### 2.2 One screen at a time

- The view always shows exactly one screen. When the middle of your monster crosses the edge, the next screen
  replaces it in one frame: no scrolling, no fade.
- A screen shake stays inside the screen, so the next screen never peeks in.
- Each screen is its own little world: what lives on it appears when you arrive and is gone when you leave.
  A challenge screen you leave before winning starts over next time (every guard back, full HP), so you can't
  wear the guards down by stepping in and out.

### 2.3 The Green Meadow (D4)

- It looks and works exactly as today: the cave in the rock wall (pick your monster), the garden, the CLASSIC /
  CLEAR SAVE / WAVES signs, the gold line at the bottom.
- New: three openings in the grass, west (Canyon), east (Crater) and south (Jungle). North is the mountain with
  the cave.
- No fighting here: A and B use the signs as today, R does nothing, and no wild monster ever comes in.
- Walking back into the Meadow refills your monster's HP.

## 3. Your monster on the map

- Always **level 7**, the level at which a run's monster has all 3 moves. No XP and no level-ups on the map.
- **HP** like a level-7 monster in a run: 108 (Furrbit 120); a shiny one 132 (Furrbit 149); **+5 per garden
  HP UP**.
- **Power**: normal, **plus the garden's POWER UPs** (+2/+1/+2/+1/+2 %), +20 % when shiny. Floor items, won
  items and waves cards belong to the runs: none of them work on the map.
- **Moves**: outside the Meadow, A/B/R fire moves 1/2/3, all three from the start. They start charging when
  your monster walks out of the cave (or when the map opens); the A/B/R charge circles at the bottom show them.
- Fights follow the run rules: the type chart, MISS, paralysis and poison, the walking dodge, Splashell's
  healing, Gustling's evasion, Furrbit's double hit, the low-HP beep, the hit flashes.
- **Fainting**: at 0 HP it blinks out, the screen fades and it wakes up in the Meadow with full HP. Nothing is
  lost: ways you opened stay open, and the challenge screen just starts over.
- Changing monster: only in the cave, as today.

## 4. Wild monsters on the map

- Only on challenge screens, and only while that land's monster is still trapped.
- They never leave their screen: they stop at its edge, even when pushed.
- Same mind as in the classic run: wander, `!` and a cry when they spot you, chase, attack, a level tag over
  the head colored by the type matchup. Each land sets how many come at you at once and how hard they hit
  (section 6).
- They give no XP and drop nothing.
- Once their land is freed they never come back.

## 5. Freeing a monster

- When the last guard faints (in the Jungle and the Sky Isle: when you reach the trapped monster), the world
  freezes for a moment, the trapped monster appears with a sparkle and its cry, the new-monster jingle plays and
  the middle of the screen shows **`EMBERPUP UNLOCKED!`** with `PICK IT IN THE CAVE` under it. It is saved at
  once.
- It stays there, happy, until you leave the screen. Come back and the screen is calm and empty; the land's
  obstacles are gone for good, so any monster can walk all of it.
- In the cave it is no longer a silhouette, and the campfire intro seats it at the fire.
- The order is the roster order the cave and the campfire already use: Furrbit → Emberpup → Splashell →
  Voltail → Sproutle → Venomole → Gustling → Wispook → Pebbulk.

## 6. The eight lands

| # | Land | Way in | You need | Challenge | Frees |
|---|---|---|---|---|---|
| 1 | Boulder Canyon | open path | Furrbit + 5 garden items | beat 4 Pebbulks: rock shrugs off Normal moves | Emberpup |
| 2 | Verdant Jungle | bramble wall: **fire** burns it | Emberpup | burn a second bramble wall, find the trapped Splashell | Splashell |
| 3 | Ember Crater | wall of flames: **water** puts it out | Splashell | beat 8 Emberpups: hit, back off, heal, Surf | Voltail |
| 4 | Coral Lagoon | storm crystal: **electricity** shatters it | Voltail | beat 5 Splashells on islands only long shots reach | Sproutle |
| 5 | Storm Plateau | ravine: a **grass** move grows a vine bridge | Sproutle | grow bridges between mesas, beat 4 Voltails | Venomole |
| 6 | Miasma Swamp | boulder: **poison** melts it | Venomole | beat 4 shell-armored Sproutles: blows do 1, poison still works | Gustling |
| 7 | Sky Isle | a wide hole: only a **flyer** crosses | Gustling | fly over a bigger hole to the pillar where Wispook is trapped | Wispook |
| 8 | Haunted Hollow | haunted hedge: only a **ghost** passes | Wispook | beat 3 Furrbits + 3 Venomoles in a hedge maze, striking from inside the hedges | Pebbulk |

**Garden items.** Each fight is tuned for a number of garden items, and the challenge screen's top line says
so when you walk in: `BRING 5 GARDEN ITEMS (YOU: 3)`. Targets: Canyon 5, Crater 6, Lagoon 6, Plateau 7,
Swamp 8, Hollow 10 (the Jungle and the Sky Isle are puzzles, with no fight). With the faster garden
(section 7.3), 5 items come after about 12 finished runs and all 10 after about 19.

**Starting numbers** (the fight bot tunes them, section 9.6):

| Land | Guards | Level | HP | Attack at once | Notes |
|---|---|---|---|---|---|
| Canyon | 4 Pebbulk | 6 | 50 | 2 | Rock Throw every 4 s; Harden every 20 s (Furrbit's blows do 1 for 3 s) |
| Crater | 8 Emberpup | 5 | 130 | 3 | Ember every 4 s; chase at 0.45 px/tick, a bit slower than Splashell walks (0.5); give up beyond 6 tiles |
| Lagoon | 5 Splashell | 6 | 70 | 3 | Water Gun (2 tiles) every 4 s; heal 2 HP/s; islands 9–32 px off the shore |
| Plateau | 4 Voltail | 6 | 50 | 2 | Thunder Shock (5 tiles) every 4 s; grass takes ×0.75 from electricity |
| Swamp | 4 Sproutle | 5 | 30 | 2 | armor: every blow does 1; Vine Whip every 5 s; chase at 0.6 px/tick, Venomole walks at 1.0 |
| Hollow | 3 Furrbit + 3 Venomole | 7 | 45 | 3 | 1-tile moves only; can't pass hedges; ghost takes ×0.75 from Normal and Poison |

**Tuned numbers (built, 2026-10-22).** The fight bot (session 926dd548 scratchpad `t/test_fight.py`: it keeps
its move's range, strafes for the walking dodge, kites guards it outranges, backs off to heal as Splashell,
never leaves the screen; 2 minutes per fight) found the starting numbers far too hard everywhere but the
Canyon (too easy there). What the game uses now, and how the bot fared (needed monster at its item target, a
wrong one with the same items):

| Land | Guards | Level | HP | Attack at once | Every | Needed monster | Wrong monster |
|---|---|---|---|---|---|---|---|
| Canyon | 4 Pebbulk | 8 | 100 | 2 | 4 s (Harden 20 s) | Furrbit: no items 1/8, 5 HP UP 6/10, 5 POWER UP 2/10 | — |
| Crater | 8 Emberpup | 5 | 50 | 2 | 4 s | Splashell 7/8 | Emberpup 0/6, Furrbit 0/6 |
| Lagoon | 5 Splashell | 5 | 110 | 2 | 5 s | Voltail 8/8 | Splashell 0/6, Emberpup 0/6 (no finish in 2 min) |
| Plateau | 4 Voltail | 3 | 20 | 1 | 8 s | Sproutle 4/8 (no losses; 4 not done in 2 min) | Voltail 0/6 (can't reach the far mesa) |
| Swamp | 4 Sproutle (armor) | 5 | 18 | 2 | 5 s | Venomole 8/8 | Sproutle 0/6 |
| Hollow | 3 Furrbit + 3 Venomole | 7 | 30 | 2 | 4 s | Wispook 8/8 | Gustling 0/6 |

Known gaps against section 9.6's targets: in the Canyon 5 POWER UPs (+8 % power) help far less than 5 HP UPs
(+25 HP), so the all-POWER mix wins ~20 %, not 60 %; on the Plateau the bot is slow to grow and cross the
bridges, so half its fights end at the 2-minute limit (it never lost one); the Lagoon's Splashell can't win in
2 minutes but heals so well it might outlast the guards in a much longer fight.

### 6.1 Boulder Canyon → Emberpup

Screens: C4 Canyon Mouth (the trail leaves the Meadow between red rock walls) → B4 The Gorge → A4 Dry
Riverbed → **A5 Pebbulk Quarry**; side areas B5 Boulder Field and C5 Lookout Ledge.

- The Quarry is a rocky bowl with 4 Pebbulks. Rock takes ×0.75 from Normal moves and hits Furrbit normally, and
  they Harden now and then. Emberpup, trapped behind them, can't fight back: rock beats fire.
- What wins it: Furrbit's double hit, Quick Attack's dash, Growl's paralysis to stop them, walking to dodge, and
  garden items.
- Tuning target: with no garden item Furrbit almost always loses; with 5 items, whatever the mix of HP UP and
  POWER UP, a good player wins. 5 items only add +25 HP or +8 % power, so 3–4 items may sometimes be enough:
  the line is soft by nature (items keep their normal boosts, as decided).
- Freed: Emberpup appears in the middle of the Quarry.

### 6.2 Verdant Jungle → Splashell

Screens: D5 Bramble Gate → E5 Fern Hollow → E6 Bramble Thicket → **E7 The Clearing**; side areas D6 Giant
Roots (the haunted hedge to the Hollow is on its west edge) and D7 Waterfall Pool.

- Way in: a **bramble wall** right past the Meadow's south opening (top of D5). A fire move that touches it
  burns it: Ember (the flame on the tile in front) is the easy one, and Fire Spin and Flamethrower work too.
  It flares, crackles and is gone **for good** (saved). Any other move only makes a dull thud.
- Inside: in E6 a second bramble wall closes the way to E7. Burn it, step into the Clearing, and Splashell is
  there, caught in vines. Walk up to it and it is freed. (The E6 bramble grows back each time you enter E6,
  until Splashell is freed.)
- No guards: this land is the fire puzzle.

### 6.3 Ember Crater → Voltail

Screens: E4 Flame Gate → F4 Ash Slope → G4 Crater Rim (the Sky Isle's hole begins at its south edge) →
**G3 Crater Floor**; E3 Obsidian Path (the storm crystal to the Lagoon is on its west edge) and the side area
F3 Lava Falls.

- Way in: a **wall of flames** past the Meadow's east opening (left side of E4). A water move douses it: a puff
  of steam, and it is gone for good.
- The Crater Floor: 8 Emberpups around their fire pits, 3 coming at you at once. Water hits fire ×1.5 and fire
  hits water ×0.75, but there are many of them.
- What wins it: Splashell's healing (2 HP a second). Hit with Water Gun or Bubble Beam, then back off: the
  Emberpups chase a little slower than Splashell walks and give up once you are 6 tiles away. Heal, go again.
  Surf (every 60 s) hits all of them at once.
- Freed: Voltail appears on the crater floor.

### 6.4 Coral Lagoon → Sproutle

Screens: D3 Crystal Shore (the mountain behind the Meadow at its south) → D2 Sandbar (the boulder to the Swamp
on its east edge) → C2 Mangroves (the ravine to the Plateau on its west edge) → **C1 The Reef**; side areas
C3 Tide Pools and D1 Coral Beach.

- Way in: a pale **storm crystal** blocks the Crater's west path (E3 → D3). An electric move shatters it, for
  good.
- The Reef: open water with small islands. 5 Splashells sit on them and can't leave (the water is solid).
  They heal 2 HP a second, and their Water Gun only reaches 2 tiles.
- What wins it: range. Voltail's Thunder Shock and Spark reach 5 tiles and Thunderbolt 10, and electric hits
  water ×1.5, which beats their healing. Shorter moves can't reach them, and Flamethrower or Surf come too
  rarely to out-damage the healing. A few islands lie close enough for their Water Gun to reach the shore:
  pick your spot.
- Freed: Sproutle appears on the shore.

### 6.5 Storm Plateau → Venomole

Screens: B2 Ravine Gate → A2 Crystal Ridge → **A1 High Mesas**; side areas B1 Wind Steps, A3 Thunder Field
and B3 Fallen Spires.

- Way in: a **ravine** cuts the Lagoon's west path (C2 → B2). A sprout grows on its edge: a grass move on it
  grows a vine bridge across, for good.
- The High Mesas: flat-topped rocks separated by ravines, with 4 Voltails on them shooting Thunder Shock
  (5 tiles) across the gaps. Sprouts on the ravine edges grow bridges to each mesa; they come back each time
  you enter, until Venomole is freed.
- What wins it: grass takes electricity ×0.75, Solar Beam (6 tiles) reaches across a ravine, and only a grass
  move builds the bridges to the far mesas.
- Freed: Venomole appears on the middle mesa.

### 6.6 Miasma Swamp → Gustling

Screens: E2 Melted Pass → F2 Sludge Pools → G2 Toadstool Bank → **G1 Sunken Bog**; side areas E1 Dead Reeds
and F1 Mist Hollow.

- Way in: a **boulder** blocks the Lagoon's east path (D2 → E2). A poison move melts it (Acid's puddle is the
  easy one): it hisses away, for good.
- The Sunken Bog: 4 Sproutles with thick turtle shells: **every blow does 1 damage**. Poison and toxic still
  hurt them as usual.
- What wins it: Poison Sting (poisons half the time), Toxic (its cloud badly poisons half the monsters in it:
  1, 2, 3… a second for 8 s), and Venomole's speed. Poison them and keep away while it works: they walk at
  0.6 px/tick, Venomole at 1.0.
- Freed: Gustling appears in the bog.

### 6.7 Sky Isle → Wispook

Screens: G5 Sky Gap → G6 Cloud Steps → F6 Windy Bluff → **F7 The Pillar**; side areas F5 Eagle Rock and
G7 Cloud Edge.

- Way in: past the Crater's south edge (G4 → G5) the ground ends in a **wide hole** across the whole path.
  Walking monsters can't step into it; **Gustling flies over** it, since it is always flying.
- The Pillar: a bigger hole fills the screen, and Wispook is trapped on a rock pillar in its middle. Fly there
  and touch it: freed.
- Once Wispook is freed, log bridges span both holes, so every monster can walk the Sky Isle.

### 6.8 Haunted Hollow → Pebbulk

Screens: C6 Hedge Gate → B6 Grave Row → A6 Bent Trees → **A7 Hedge Maze**; side areas B7 Lantern Path and
C7 Old Ruins.

- Way in: a **haunted hedge** blocks the Jungle's west path (D6 → C6). It is solid for every monster except
  Wispook, who floats through it.
- The Hedge Maze: its walls are haunted hedges. 3 Furrbits and 3 Venomoles walk the corridors; they can't pass
  the hedges, and their moves only reach 1 tile. Ghost takes ×0.75 from Normal and Poison.
- What wins it: float into a hedge, out of their reach, and strike from inside it with Night Shade (a 3-tile
  beam); Phase shoves a crowd away. Moves are never blocked by hedges.
- Freed: Pebbulk appears in the middle of the maze. The entrance hedge withers; the maze stays (any monster
  can walk its corridors).

## 7. Changes elsewhere

### 7.1 Classic runs

- A win no longer unlocks a monster: the victory screen loses its `NEW MONSTER:` line, and its jingle plays for
  a new best time only.
- Everything else stays: best times, the 3 won items, the shiny seed (still only for a species you have
  unlocked), the garden seed.

### 7.2 Waves mode

- Opens when all 9 monster types are unlocked (today: when all 9 monsters have won a classic run).
- While it is locked, the grey WAVES sign's head label says `WAVES` and the bottom gold line says
  `8 MONSTER TYPES LEFT` … `1 MONSTER TYPE LEFT`. The words go on the bottom line (where the best times
  already show) because a head label holds at most 15 letters and the sign stands near the right edge.

### 7.3 Garden

- Back to one growth step per finished run (won or lost): seed to item in 5 finished runs. 5 items after about
  12 finished runs, all 10 after about 19 (today: about 52 and 79). Everything else is unchanged.

### 7.4 Clear save

- It also closes every opened way: the bramble, flames, crystal, vine bridge and boulder come back. Its list
  becomes `UNLOCKED MONSTERS, PATHS`, `BEST TIMES`, … (WAVES now follows the unlocked monsters).

### 7.5 Unchanged

- The cave picker, the campfire intro, the shiny rules, best times, the 3 won items, floor items, and how
  both run modes play.

### 7.6 Old saves

- Monsters already unlocked stay unlocked, and their lands count as freed (calm, ways open). For example a save
  with 4 unlocked monsters has the Canyon, the Jungle and the Crater freed, and the Lagoon comes next.

## 8. On screen

### 8.1 In the Meadow

- Today's menu HUD (the gold line at the bottom), plus the WAVES count.

### 8.2 Outside the Meadow (a new map HUD)

- Bottom left: A, B and R with their charge circles, as in a run. Bottom right: the HP bar and `LV7`. No panel,
  so the whole screen stays in view.
- Top middle, in gold letters: the land's name for 3 s when you walk into it (`EMBER CRATER`); what a gate needs
  while you stand by it (`ONLY FIRE CAN BURN THIS`); a challenge's item target when you walk in.
- Middle: the unlock banner.

### 8.3 Sound

- The menu song everywhere; the run song on a challenge screen while its guards are out; the new-monster jingle
  and the freed monster's cry at the unlock.
- New short sounds: burn, douse, shatter, grow, melt, and a dull thud when the wrong move hits a gate.

## 9. How it will be built (for the AI)

### 9.1 Engine and format changes (they need your OK; this doc asks for it)

All are opt-in: a scene without the new camera mode, and every node without the new fields, behaves exactly
as today, so both run modes stay as they are.

1. **Screens camera.** The scene's `camera` gets `mode: "screens"`: the view is the 240×160 cell holding the
   followed actor's middle, and it jumps to the next cell when that middle crosses an edge. `camera.screen_var`
   gets the screen number (row × 7 + column; D4 = 24) and `camera.on_screen` (actions) runs after every change
   and on load. A shake stays inside the cell. The jump is a full redraw of the 3 layers (`bg.c` already redraws
   everything when the view moves more than 4 tiles); if it doesn't fit in VBlank, that one frame is blanked.
   Files: `src/engine/camera.c`, `scene.c`, `bg.c`.
2. **Rooms.** In screens mode codegen tags each instance with the screen it stands in. Only the current
   screen's instances exist: on a change the old screen's actors are removed (the player, the HUD and the
   tilemaps stay), the new screen's instances are placed, and anything spawned at runtime belongs to the screen
   it appears in. Particles, ground zones and floating words are cleared. OBJ VRAM and OBJ palette banks are
   handed out again (as a scene load does, the player's sheet, shiny copy and the sprite fonts first), so each
   screen has the 16 OBJ palettes to itself. Files: `scene.c`, `data.h`, `tools/codegen.py`.
3. **Tiles with their own palette.** Today one layer uses one 16-color palette: too few colors for 9 lands on
   one map. A tileset may list `palettes` and each tile may pick one (`palette: <index>`); `bg.c` gives each a BG
   bank and adds it to the cell when drawing. Cells stay one byte, so physics doesn't change.
4. **`move_switch` (new behavior).** Something a move of the right type changes. When the effect of a player's
   move of one of its `types` touches it (the same 2-px picture test as a move hitting a monster; a zone each
   time it would hurt), it counts a hit; after `hits` hits it runs `on_open` as itself (its after-picture, its
   gate variable, save, destroy itself). Any other type runs `on_wrong` (the thud). Hook in
   `src/behaviors/moves.c`.
5. **`appear_if` (new behavior).** When it appears it checks one variable (`var`, `op`, `value` or `from`) and
   removes itself unseen if the check fails. Everything that depends on progress uses it: gates
   (`gate_k == 0`), after-pictures, guards (`unlocked == k`), trapped monsters, hint zones, the two WAVES signs.
6. **`monster.armor` (new param, default 0).** Every blow it takes does that much less damage, at least 1;
   poison and toxic as usual: a Harden that never ends, without the flicker. `monster.c`.
7. **`move_buttons.enable_var` (new param).** The buttons fire only while that variable isn't 0: 0 in the
   Meadow, so A and B pick signs. `move_buttons.c`.
8. **Wild monsters kept in their screen.** In screens mode, each tick `monster.c` puts a wild monster's hitbox
   back inside the screen it appeared in (after walking, knockback, dashes or Phase).

No new `*.iwram.c` code: IWRAM had about 16 bytes above `build.py`'s 2 KB stack minimum at the last count
(2026-10-21). Every new piece of state goes in `EWRAM_BSS` and every new function stays in Thumb (ROM).

### 9.2 Data (no engine change)

- **Who blocks whom.** The 9 species bodies' `collides_with` gain `prop` (all), `platform` (all but Gustling)
  and `npc` (all but Wispook). Gates are solid props; holes are invisible solid `platform` actors over hole
  tiles; haunted hedges are solid `npc` actors. These bodies are shared with the runs, where no prop, platform
  or npc actor is solid: an old-vs-new replay hash of both modes proves nothing changes there.
- **Variables.** New: `map_hp`, `map_hp_max` (initial 0, so the run's start-of-run HP bonus never fires on the
  map; the map's own setup writes the full value when the map opens, when a monster walks out of the cave and
  after a faint), `map_level` (7), `map_moves`, `screen`, `land`, `land_sign`, `hint`, `banner`, `garden_owned`
  (HP UPs + POWER UPs owned), and the persistent `gate_2` … `gate_6`. Changed: `unlocked` (now raised by the
  map), `new_mon` (the monster just freed, for the banner), `kills` (reset on every screen). Removed: `cleared`,
  `scan`.
- **New nodes.** `hud_map`; `enm_land_pebbulk`, `_emberpup`, `_splashell`, `_voltail`, `_sproutle`, `_furrbit`,
  `_venomole` (each land's guards share one node whose `on_death` checks `kills` against the land's count, then
  sets `unlocked` and saves first, and only then plays the show); `prop_bramble`, `prop_flames`, `prop_crystal`,
  `prop_sprout`, `prop_vine_bridge`, `prop_boulder`, `prop_log_bridge`; `prop_freed_<species>` ×8 (props with the
  species' body, so moves can't hit them); `plat_hole_*` in a few sizes; `npc_hedge` and `npc_hedge_wall_*`;
  `trg_hint`, `trg_freed`; the big map's tilemaps, tilesets and palettes; particles and sounds for the gates;
  catalog entries for `appear_if` and `move_switch`.
- **Changed nodes.** `scn_menu` (big map, screens camera, rooms, `on_screen`, garden pace, gate migration for
  old saves: `gate_k = 1` when `unlocked > k`), `plr_menu` (monster with HP, level 7, garden power, shiny bonuses,
  `move_buttons`, `camera_target`, faint), `hud_menu` (WAVES count), `trg_sign_locked`, `menu_clear_save`,
  `scn_victory`, `hud_victory`, the 9 species bodies, `nodes.json`. Replaced: `map_menu_wall` and
  `map_menu_field` (their art moves into the big map at D4, untouched).

### 9.3 Art budget

- The map is 210 × 140 tiles on 3 layers: 1 = collision (and the Meadow's rock wall, as today), 2 = ground,
  3 = tree and cliff tops drawn over the monsters. Each layer holds at most 255 different tiles for all 49
  screens, so the lands are built from shared tiles (no big painted pictures). The Meadow, copied as it is,
  takes 130 of layer 1's tiles (its rock wall) and 53 of layer 2's (its grass and garden bed).
- BG palettes: the map's tiles share about 11 palettes by material; the UI keeps the rest of the 16, and the
  validator counts them.
- Sprites: each screen stays within 16 OBJ palettes and the OBJ VRAM budget, since rooms hand them out again.
- BG tiles can't change while playing, so everything that disappears is a sprite: gates, bridges, freed
  monsters, the entrance hedge. Holes, ravines, water and the maze walls are drawn on the BG, with invisible
  blockers.
- A generator script (in the session scratchpad, never the repo) paints the 49 screens from per-land tiles and
  a layout per screen. The Meadow comes from the current nodes, unchanged.

### 9.4 The four mirrors

CLAUDE.md (§6.1b scene camera and tileset palettes, §7.1 behaviors, §8 rooms), `tools/validate.py`,
`tools/codegen.py` and `visualizer/visualizer.html` change together.

- Validator: a screens-mode map is a whole number of screens; every actor and trigger instance lies inside one
  screen; OBJ palettes and VRAM are counted per screen; `appear_if`, `move_switch` and `armor` params are checked.
- Visualizer: the scene preview shows the 7×7 map with the screen grid, screen and land names, and a "progress"
  selector (1–9 unlocked, gates open or closed) that shows what appears at each stage; the new behaviors read in
  plain words ("burns when a FIRE move touches it").

### 9.5 Build order

1. Engine: screens camera, rooms, tile palettes, the small params and behaviors, tested on a placeholder 7×7 map.
2. The Meadow moved to D4 of the big map, with the map HUD, moves, HP, fainting, garden pace, WAVES label,
   victory change and clear save. Playable with empty lands.
3. Lands 1 → 8, one at a time: gate, challenge screen, guards, freed monster, each tuned with the fight bot.
4. Art pass on all 49 screens, with screenshots of every screen for your review.
5. Docs: `monster-survival.md` (menu, unlocks, garden pace, map), CLAUDE.md, the nodes' notes.

### 9.6 Tests (`tools/emutest.py`, Python only)

- Screens: the view is exactly one screen and switches at the edge; HUD and moves turn on and off at the
  Meadow; a shake never shows the next screen.
- Rooms: guards appear and vanish with their screen; leaving resets them; nothing spawned stays behind.
- Wild monsters stay inside their screen, even pushed by Phase at the edge.
- Every gate opens with the right type (and saves) and with no other type; holes stop everyone but Gustling;
  hedges stop everyone but Wispook.
- Unlock: last guard → banner, `unlocked` + 1, saved; the freed monster leaves with the screen; coming back,
  the screen is calm.
- Fainting → the Meadow with full HP; opened gates stay open.
- WAVES label for 1–8 unlocked and open at 9; a classic win unlocks nothing; clear save closes the gates.
- Tuning: the fight bot plays each challenge many times per item count. Targets: Canyon with 0 items ≤ 10 %
  wins, with 5 items (worst mix) ≥ 60 %; every other fight with the needed monster and its item target ≥ 70 %,
  with any other unlocked monster ≤ 10 %.
- Regression: old-vs-new replay hash of the classic and waves runs (shared bodies and engine); worst-frame
  cycles on the busiest challenge (the Crater's 8 Emberpups); the stack check.

## 10. Known limits

- **The 5-item line is soft.** 5 items add only +25 HP or +8 % power, so the Canyon is tuned for "none: you
  lose; 5: you win with good play", and 3–4 items will sometimes be enough.
- **Tiles.** 49 screens must fit in about 765 different tiles (3 layers × 255), so the lands reuse tiles a lot.
- **Sprites per screen.** A busy challenge screen (8 guards, their tags, move effects) comes close to the 16
  OBJ palettes; the validator checks each screen.
- **IWRAM is full.** All new code goes in ROM and all new state in EWRAM; nothing new may be moved to IWRAM.
- **Size.** This is a large job (engine, 49 screens of art, 8 lands), built in the phases of section 9.5.
