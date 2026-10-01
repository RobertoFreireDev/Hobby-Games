# PEG DUNGEON — design doc (v2)

PICO-8 puzzle/RPG. Peg solitaire where every peg is something in a dungeon: a monster,
a potion, a sword, or plain rubble. You never have to clear the whole board — you have
to clear it **in an order that kills every monster and keeps you alive**.

v2 locks in four rules: **swords break**, **monsters are rooted** (only non-enemy pegs
can move), **all enemy info is visible**, and **leftover pegs cost score**.

---

## 1. Fiction

The board is a dungeon floor seen from above. You are not a peg — you are the *hand of
the dungeon*. Monsters are rooted where they stand. What you actually move is the loose
material of the floor: stones, dropped flasks, dropped blades. You shove that material
through the monsters, and whatever it lands on resolves against your hero.

One board = one floor = one run attempt. Board is generated fresh every game.

---

## 2. Screen layout

PICO-8 is 128x128. Cells are 8x8, so a 14x14 grid is exactly 112x112 px.

```
  x: 0        8 ..................... 120      128
  y: 0  +-----+-----------------------+-----+
     2  |     |  BOARD 14x14 (112px)  |     |   <- 2px top margin
        |  8  |                       |  8  |      8px side margins
        |     |                       |     |
   114  +-----+-----------------------+-----+
        |        BOTTOM BAR (14px)          |
   128  +-----------------------------------+
```

- Board origin: `(8, 2)`. Cell `(cx,cy)` draws at `8+cx*8, 2+cy*8`.
- Bottom bar: `y = 114..127`, full width, filled with the dark bar colour.
- Sprites are drawn 8x8 with a 1px transparent border, so pegs read as separate discs
  with no gutter needed.

### Board shape

The full 14x14 (196 cells) is far too many pegs for solitaire. Each run carves a
**mask** inside the grid — only masked cells are playable. Target **55–85 playable
cells**. Mask families to roll from:

| Mask | Shape |
|---|---|
| CROSS | fat plus sign, English-solitaire style, scaled to 14x14 |
| DIAMOND | rhombus, corners cut |
| CAVERN | random blob grown from the centre (flood-grow N cells, then fill holes) |
| RING | donut with a solid centre island |
| TRIANGLE | pyramid resting on the bottom row |

Unmasked cells are drawn as dungeon floor/void (never as empty holes) so the player
can tell "not playable" from "empty and jumpable-into".

---

## 3. Core rules

Standard peg solitaire, orthogonal only, **with one restriction: monsters don't move.**

1. Pick a **carrier** peg — rubble, potion or sword. Enemy pegs cannot be selected.
2. Pick a direction (up/down/left/right).
3. The neighbouring cell must hold a peg **B** (any type, including an enemy); the cell
   beyond must be **empty and inside the mask**.
4. The carrier lands beyond, B is **removed from the board** — and B **resolves against
   you** (§4).

Types travel with the peg that moves; only the **jumped** peg triggers an effect. A
carrier stays a carrier forever, no matter how many times it moves. Diagonals never.

### What the rooted-monster rule actually does

- **Carriers are ammunition, and ammunition is finite.** Every time a carrier jumps
  another carrier, you gain an item but lose a mover. Every enemy you kill costs a
  positioning move you'll want later. Running out of reachable carriers next to a live
  monster is the main way runs end badly.
- **Chains matter.** One stone can walk through a whole row of monsters if the empty
  cells line up. Finding those chains is the skill ceiling.
- **Position beats stats.** A monster in a corner with no carrier that can ever reach
  it is unwinnable — so the generator must never create one (§6).

### Ending the run

| Outcome | Condition |
|---|---|
| **WIN** | Zero enemy pegs remain on the board, HP > 0 |
| **DEAD** | HP reaches 0 |
| **STUCK** | No legal jump exists (no carrier has a jump) and an enemy is alive |

You do **not** need to reduce the board to one peg — but leftovers cost you score (§12).

---

## 4. Peg types

| Type | Can move? | Sprite idea | On being jumped |
|---|---|---|---|
| **ENEMY** | never | horned skull / slime / wraith, 4 tiers | Fight it (§5) |
| **POTION** | yes | flask | Adds 1 potion to the belt (max 3) |
| **SWORD** | yes | blade | Equip / reinforce sword (§5) |
| **RUBBLE** | yes | small grey stone | Nothing — pure ammunition |

Target mix per board: **30% enemy, 10% potion, 12% sword, 48% rubble.** Rubble is the
plurality on purpose. With monsters rooted, rubble *is* the resource the puzzle is made
of, and a board short on it is a board that strangles itself.

### Enemy tiers

| Tier | POW | XP | Read |
|---|---|---|---|
| 1 | 1 | 1 | small, one colour |
| 2 | 2 | 3 | bigger silhouette |
| 3 | 3 | 5 | horned/crowned, accent colour |
| 4 (rare) | 5 | 9 | distinct sprite, only 0–2 per board |

### Full information, always

Every enemy shows its tier from turn one — no fog, no reveal mechanic, nothing hidden.
The nonogram RPG hides information because deduction is its subject; this game's
subject is **sequencing**, and sequencing only reads as skill when the player could
have seen the whole problem. A death here should always be provably the player's
routing mistake, never a surprise.

Corollary: the **peek** button (§7) is not a hint system, it's an accessibility feature.
Showing every legal jump gives away nothing the player couldn't compute by hand.

---

## 5. Combat, swords & progression

On jumping an enemy:

```
damage = max(0, POW - ATK)
HP -= damage
XP += enemy XP        (full XP even if damage is 0)
DUR -= 1              (every fight dulls the blade, even a clean block)
if DUR == 0 then sword shatters: ATK = 0
```

No dice, no randomness in resolution. The board is a solvable machine; the player
should be able to plan ten moves ahead exactly.

### The sword breaks

You carry one sword, described by two numbers:

| | |
|---|---|
| **ATK** | Damage reduction, 0–4 |
| **DUR** | Fights remaining before it shatters, 0–9 |

- Jumping a **sword peg**: `ATK = min(4, ATK+1)`, `DUR = min(9, DUR+3)`.
- Every enemy fight costs **1 DUR**, whether or not the sword absorbed anything.
- At `DUR = 0` the sword shatters and **ATK drops to 0**. Not a decay curve — a cliff.

The cliff is deliberate and it's fully telegraphed: DUR is on the bar the whole time,
so walking into a tier-4 with one durability left is a decision, not an accident. What
this buys the design is that **stats never stabilise**. A player who reaches ATK 4
still has to keep routing through sword pegs, which means still spending carriers,
which means the geometry stays under pressure until the last enemy dies. Without
breakage, the back half of a floor is a formality.

ATK caps at 4 and tier-4 POW is 5, so something always bites.

### Stats

| Stat | Start | Notes |
|---|---|---|
| HP | 6 | Max HP grows with level |
| ATK / DUR | 0 / 0 | Unarmed at floor 1 |
| Potions | 0 | Belt of 3 max |
| XP | 0 | Never spent, only accumulates |
| Level | 1 | |

### Levels

| Level | XP needed | Reward |
|---|---|---|
| 2 | 4 | +2 max HP, heal 2 |
| 3 | 10 | +2 max HP, heal 2 |
| 4 | 19 | +3 max HP, heal 3 |
| 5 | 32 | +3 max HP, heal 3 |
| 6+ | +18 each | +3 max HP, heal 3 |

Levelling is the reason to fight weak enemies **first** even when a strong one sits in
a convenient spot. Killing the tier-3s early is greedy and usually fatal.

### Potions

Potions are **banked, not instant**. Press ❎ any time to drink one:
`HP = min(HP + 4, maxHP)`. Overhealing is wasted, so drinking too early throws the
potion away and drinking too late kills you.

---

## 6. Board generation (guaranteed solvable)

Never generate a random board and hope. Generate **backwards**, so a valid solution is
constructed by definition — and with rooted monsters this is no longer just convenient,
it's the only sane way to avoid unreachable enemies.

**The inverse of a jump**: a peg at C moves back two cells to A, and a peg reappears at
B in between. Legal if A and B are both empty and both inside the mask.

### Steps

1. Roll a mask (§2). Count playable cells → `N`.
2. Place **1–3 seed pegs** near the centre. Board is otherwise empty.
3. Repeat `N - seeds` times (or until no inverse move exists): apply a random legal
   **inverse jump**. Each one adds exactly one peg. Track peg *identity* across moves.
4. Reverse the recorded sequence → a **guaranteed forward solution**, with the mover
   and the captured peg known at every step.
5. **Flag every peg that ever acts as a mover** in that solution. Those pegs must end up
   as rubble/potion/sword. The rest — pegs that are created and only ever captured —
   are the **enemy candidate pool**.
6. **Assign types along the solution order**, simulating the player as you go:
   - Walk the forward solution steps `1..K`, maintaining simulated HP/ATK/DUR/XP/level.
   - Movers get carrier types. Bias early captures toward swords and tier-1 enemies,
     later captures toward higher tiers.
   - Before committing an enemy, check `HP - max(0, POW - ATK) > 1` **and** `DUR > 0`
     if the sword is doing the work. If it fails, downgrade the tier or make it a potion.
   - Because the sword breaks, the simulation must place sword pegs on a schedule —
     roughly one per 3 fights — or the guaranteed solution stops being survivable
     halfway through.
   - Stop adding enemies at the target count; fill the remainder with rubble.
7. **Survivors of the canonical solve must never be enemies** — otherwise the guaranteed
   solution doesn't satisfy the win condition.
8. Store the canonical solution for a solvability assertion and for the win-screen
   "optimal leftovers" figure. The player will almost always find a different route.

### Generator bias that matters now

Prefer inverse moves whose **moving peg has already been flagged as a mover**. Re-using
a small set of carriers keeps the enemy candidate pool large, and it produces exactly
the board texture the fiction wants: a few stones that have travelled a long way, and a
lot of monsters that never budged.

### Difficulty knobs

- Mask size (cell count).
- Enemy percentage and tier ceiling.
- Simulated-HP safety margin in step 6 — a tight margin makes brutal boards.
- **Sword spacing** — the strongest knob in v2. One sword per 3 fights is comfortable;
  one per 5 means most of the floor is fought bare-handed.
- Carrier density — fewer carriers means fewer alternate routes and much harder puzzles.
- Seed count — more seeds means more leftovers allowed, which is *easier* to survive
  and *worse* for score.

---

## 7. Controls

| Input | Board mode |
|---|---|
| ⬅️➡️⬆️⬇️ | Move cursor (skips unmasked cells) |
| 🅾️ | Select the carrier under the cursor / deselect |
| ⬅️➡️⬆️⬇️ *(while selected)* | Execute the jump in that direction |
| ❎ | Drink a potion |
| 🅾️ held | Peek: highlight every legal jump on the board |

Selecting an enemy is refused with a short buzz and a 4-frame shake on that sprite —
the refusal should teach the rooted rule in the first ten seconds without a tutorial.
When a carrier is selected, its legal landing cells pulse. Illegal direction = buzz, no
state change, no penalty.

**Undo**: hold ❎ + 🅾️ to rewind one move, unlimited. Peg solitaire without undo is
misery; the puzzle should punish bad *plans*, not bad *fingers*. Undo count is shown on
the win screen and can optionally shave score.

---

## 8. Bottom bar (14px)

Single row, left to right, 8x8 icons with a small number beside each:

```
[sword]2·5  [flask]x2  [heart]6/10  [xp]17 Lv3  [skull]5
```

| Slot | Shows |
|---|---|
| Sword | `ATK·DUR`. DUR digit turns red at 1, and the blade sprite shows a chip at ≤2 |
| Flask | Potions in belt, drawn as up to 3 pips |
| Heart | `HP / maxHP` — flashes red for 20 frames when hit |
| XP | Raw XP, plus a 1px progress sliver to next level |
| Lv | Level number |
| Skull | **Enemies still alive** — the actual win counter, the number the player watches |

The bar is read-only; no cursor ever enters it. Everything on it is a consequence of
board decisions.

---

## 9. Feedback & juice

- Jumping peg **arcs** over the victim across ~8 frames instead of teleporting.
- Victim flashes white then dissolves (2-frame particle puff).
- Damage: screen shakes 2px, heart flashes, a small `-2` floats up from the bar.
- Zero-damage kill: sword icon glints, no shake — sells the power spike.
- **Sword shatter**: hard freeze for 12 frames, blade sprite splits into two shards,
  descending sfx. This event must land harder than a level-up.
- Level up: brief full-board colour ramp via `pal`, ascending sfx.
- Last enemy dies: everything freezes ~30 frames, remaining pegs fade, WIN card.
- Stuck detection runs after every move; if no carrier has a legal jump and enemies
  remain, the surviving enemies pulse red before the DEAD END card.

## 10. Art direction

- Chunky, high-contrast, no anti-aliasing, no gradients.
- Palette: dark base (0/1/5) for floor and void, warm off-white (7/6) for pegs and UI,
  red (8) reserved **only** for danger and damage, green (11) for potions, light grey
  (13/6) for swords, gold (9/10) for XP and level-up flashes.
- **Enemies read as rooted**: give every enemy sprite a 1px base shadow/root pixel row
  that carriers don't have. Movable vs. rooted must be legible without selecting.
- Enemy tiers differ by silhouette, not just colour, so tier is legible at 8x8.
- Empty masked cells: a 2x2 dark dot in the centre. Unmasked: solid void, no dot.

## 11. Audio

`sfx`: cursor move (very quiet), select, refused-selection buzz, jump-arc, hit-taken,
no-damage clang, sword shatter, potion drink, sword pickup, level up, win fanfare,
death sting. One low ambient `music` pattern on the board, silence on the end cards.

---

## 12. Score & floors

```
TITLE  ->  GENERATE  ->  PLAY  ->  WIN card  -> next floor (harder knobs) -> GENERATE
                          |
                          +-----> DEAD / DEAD END card -> TITLE
```

Floors escalate: floor `n` raises enemy percentage and tier ceiling, widens sword
spacing, and shrinks the generator's safety margin. Stats, sword and potions **carry
over between floors** — that's the RPG spine.

### Scoring

| | |
|---|---|
| Floor cleared | +100 each |
| XP earned | +5 each |
| **Leftover peg** | **−4 each** |
| Down to 3 or fewer pegs | +50 **CLEAN SWEEP** |
| Down to 1 peg | +150 **PERFECT** |
| Unused potion in belt | +10 (banked value, not wasted) |

Surviving is the win condition; **emptying the board is the mastery condition**. A
player who only wants to live leaves twenty stones on the floor and clears it. A player
chasing PERFECT has to keep jumping after the last monster dies, with no HP pressure
left — just pure solitaire endgame, where a single badly-spent carrier twenty moves ago
is what strands the final three pegs. That's the second skill curve, and it costs
almost nothing to implement: the win check already knows how many pegs remain.

Show the canonical solution's leftover count on the win card as a par score.

---

## 13. Build order

1. Grid, mask, cursor, drawing. No types — plain pegs, plain solitaire.
2. Jump validation + execution + undo stack.
3. Reverse generator (steps 1–4) with identity tracking. Verify boards are always
   solvable by auto-replaying the stored solution.
4. Peg types, the carrier/rooted restriction, combat, sword durability, bottom bar.
5. Type assignment with simulation (steps 5–7). Tune sword spacing until boards feel
   fair-but-tight.
6. Win/lose/stuck states, floors, score.
7. Juice, art, audio.

### Token watch (8192 cap)

The generator is the expensive part — the inverse-move search and the assignment
simulation share almost all their logic with the forward move code, so write
`can_jump(x,y,dx,dy)` and `do_jump()` once and drive both directions off the same
functions. The carrier restriction is a single extra clause in `can_jump`, and the
stuck-check is `can_jump` swept over the board, so it costs nothing extra. Store the
board as a flat 196-entry table with `0` = void, `1` = empty, and peg records as small
tables `{t,p}`. Masks should be **generated**, not stored as literal data.

---

## 14. Still open

- Should a **potion or sword peg lose its item** if it's used as a carrier too often?
  (Currently no — a sword peg you shove around ten times still gives a full sword when
  finally jumped. Simple, but it means the smart play is always "move the item pegs,
  capture them last", which may flatten routing.)
- Should tier-4 enemies be **boss pegs** occupying 2x2 cells, requiring two separate
  jumps to remove? Strong set-piece, but it breaks the uniform grid logic everywhere.
- Does the sword shatter mid-floor need a **mercy rule** on floor 1 — e.g. floor 1
  guarantees a sword peg within reach when DUR hits 1 — so new players learn the cliff
  instead of dying to it?
