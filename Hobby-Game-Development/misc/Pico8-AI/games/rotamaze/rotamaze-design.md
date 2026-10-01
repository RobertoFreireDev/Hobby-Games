# ROTAMAZE — Design Document

*Working title. PICO-8 puzzle game. This document covers mechanics only — no code, no implementation.*

---

## 1. Concept

A maze game where the maze is not fixed. The player walks from a start tile to an exit tile, but every tile carries its own set of walls and the player can **rotate the tile it is facing** to reshape the path. Both walking and rotating are metered by separate, finite budgets. A rewind button lets the player undo any turn, so the game is a pure puzzle: there is no reflex element, only planning.

The tension is the split between two scarce resources. Movements buy distance, actions buy shape. Turning in place is free, so aiming a rotation never costs anything — every movement spent is a tile actually crossed, and every wall opened is paid for in actions alone.

**Core loop:** read the maze → find a route → spend movements/actions → hit a dead end → rewind → re-plan.

---

## 2. Board & screen

| Property | Value |
|---|---|
| Grid | 15 columns × 14 rows = 210 tiles |
| Tile size | 8 × 8 px |
| Board pixel size | 120 × 112 px |
| Board origin | (4, 4) |
| Board occupies | x 4–123, y 4–115 |
| Bottom bar | y 116–127 (12 px) |
| Screen | 128 × 128 (PICO-8 standard) |

The board has a 4 px margin on left, right and top. The bottom bar holds the two remaining-resource counters.

```
+----------------------------------+ y=0
|  (4px margin)                    |
|  +----------------------------+  | y=4
|  |                            |  |
|  |     15 x 14 tile board     |  |
|  |        120 x 112 px        |  |
|  |                            |  |
|  +----------------------------+  | y=115
|  MOV 24            ACT 06        | y=116..127
+----------------------------------+ y=127
```

The board is not scrollable and never moves. The whole maze is always visible — this is deliberate: the puzzle is about planning, so hiding information would only add busywork. The **exit tile is drawn from the first frame** and is never concealed. The player is never asked to search for the goal, only to work out how to reach it.

### Bottom bar

- **MOV** — movements remaining.
- **ACT** — rotate actions remaining.
- Nothing else is shown. No maze ID, no seed, no par, no timer. (See §9.)
- A counter at 0 is drawn in a warning color; the other counter stays neutral.

---

## 3. Tiles and walls

Every tile owns **its own four wall flags**: top, right, bottom, left. A tile can have 0 to 4 walls, so there are 16 possible tile states.

```
bit 0 (1) = TOP
bit 1 (2) = RIGHT
bit 2 (4) = BOTTOM
bit 3 (8) = LEFT
```

Walls belong to the tile, **not to the edge between two tiles**. Two neighboring tiles may disagree — tile A can have a right wall while tile B has no left wall. This is legal and intentional; it is what makes rotation meaningful. Traversal resolves the disagreement (see §5.1).

Visually a wall is a 1 px line drawn on the inside of the tile's edge. When two neighbors both carry the shared wall, the result reads as a 2 px thick wall — that is a useful visual cue: **thick wall = two walls to clear, thin wall = one rotation might be enough.**

### 3.1 Rotation

Rotation is always **clockwise**, one quarter turn per action:

```
TOP -> RIGHT -> BOTTOM -> LEFT -> TOP
```

As a bitmask: `new = ((w << 1) | (w >> 3)) & 0b1111`

Notes that follow from this:
- A tile with 0 walls or 4 walls is unaffected by rotation. It is dead weight and should be used sparingly by the generator.
- A tile with 2 opposite walls (`TOP|BOTTOM`, `LEFT|RIGHT`) has only 2 distinct states — one rotation flips it, a second restores it.
- Every other tile has 4 distinct states, so a full cycle costs 4 actions. Rotating "backwards" costs 3.

That last point is a core difficulty lever: there is no counter-clockwise, so undoing a wrong rotation in-game is expensive. Rewinding is the cheap way to fix a rotation mistake.

---

## 4. The player

The player has a position (col, row) and a **facing** — one of the four directions. Facing is drawn on the sprite (a small notch or eye) and matters for exactly one thing: **X rotates the tile the player is facing.**

- The player starts on the start tile with a fixed initial facing defined per maze.
- The player can **never rotate the tile it is standing on.** To change your own tile you must step off it and turn back toward it. This constraint is central to the puzzle design.

### Faced-tile highlight

The tile the player is currently facing is drawn with a faint highlight — a dim 1 px outline or a slightly lifted background, never bright enough to compete with the walls. It confirms exactly what ❎ will rotate.

Every tile in the game is rotatable, so this marker carries no information about the maze; it only reflects the player's own facing. Since turning is free (§5), the player will re-aim constantly, and without this cue it is easy to lose track of which of the four neighbors is armed. If the faced tile is off-grid, no highlight is drawn — which doubles as the signal that ❎ will do nothing.

### Board edges

The grid boundary is a hard limit. There is no wrap-around and no tile beyond row/column limits. Moving off-grid is blocked; rotating an off-grid tile is invalid (see §6).

---

## 5. Controls

| Input | Effect | Cost |
|---|---|---|
| Arrow (path clear) | Step one tile in that direction, facing updates to that direction | 1 MOV |
| Arrow (path blocked, not already facing it) | Player does not move, facing changes to that direction | **0** |
| Arrow (path blocked, already facing it) | Nothing happens | 0 |
| ❎ / X | Rotate the faced tile 90° clockwise | 1 ACT |
| 🅾️ / O | Rewind one turn | 0, refunds |

There is no separate "turn" button. **Turning is what a failed move does, and it is free.** Bumping into a wall is how you aim, and it never costs anything.

The consequence is worth stating plainly: **from any tile, the player can rotate all four neighbors for 4 ACT and 0 MOV.** Aiming is not a resource. MOV measures distance travelled and nothing else — one movement, one tile crossed. This makes the two counters cleanly separable, which in turn makes the budgets in §6 mean something precise.

### 5.1 Movement resolution

Pressing an arrow toward direction `D`, from tile `A` to neighbor tile `B`:

1. If `B` is off-grid → **blocked**.
2. If `A` has a wall on side `D` → **blocked**.
3. If `B` has a wall on side `opposite(D)` → **blocked**.
4. Otherwise → **move**.

Either tile's wall stops the move. A one-sided wall blocks travel in both directions — there are no one-way passages.

**On move:** position becomes `B`, facing becomes `D`, MOV − 1.
**On blocked:** if facing ≠ `D`, facing becomes `D` and **no counter changes**. If facing is already `D`, the input is ignored entirely. Either way a blocked press is free — the player can spin in place as long as they like.

### Blocked-move feedback

A blocked press must never read as a dropped input. On every blocked arrow:

- the player sprite lurches ~2 px toward `D` and springs back over 3–4 frames
- a short, dry thud sfx plays (low pitch, no reverb — it should sound like *stop*, not like *error*)
- the wall that did the blocking flashes for 2 frames, so the player can see **which** of the two tiles carries it

That last cue matters more than it sounds. Since a wall may live on the player's own tile, on the neighbor, or on both, the flash tells the player whether rotating the faced tile can possibly help — or whether they are looking at their own tile's wall and need to walk around and come back at it (§5.2).

### 5.2 Rotation resolution

Pressing X:

1. Let `T` be the neighbor tile in the player's facing direction.
2. If `T` is off-grid → input ignored, ACT unchanged.
3. If ACT = 0 → input ignored.
4. Otherwise rotate `T` clockwise, ACT − 1.

**A wall between the player and `T` does not prevent rotation.** You can always reach through and turn the tile you are facing. This is the key affordance: you bump a wall (1 MOV) to face it, then rotate the tile behind it (1 ACT) until the wall swings out of the way.

Note the asymmetry: rotating `T` moves `T`'s wall away, but if the wall between you and `T` also exists on **your** tile, rotating `T` is not enough — you have to leave, turn around, and rotate your own former tile from the other side. Thick walls are expensive.

### 5.3 The "bump to aim" pattern

The most common idiom in the game:

```
1. Press arrow toward the blocked direction   -> free, now facing it
2. Press X (possibly several times)           -> 1 ACT each, wall swings away
3. Press the same arrow again                 -> 1 MOV, step through
```

Minimum cost to open and cross a single thin wall: **1 MOV + 1 ACT** (if one rotation clears it) — worst case **1 MOV + 3 ACT**. The movement is only ever the step itself.

The same pattern with no intent to move — turning toward a tile purely to reshape it and then turning away again — is entirely free apart from the rotations. Reshaping the maze around yourself costs ACT only.

---

## 6. Resources

Two independent counters, both fixed at maze start:

- **MOV (movements)** — decremented once per tile actually entered. Blocked presses and facing changes are free.
- **ACT (actions)** — decremented by every accepted rotation.

They never convert into each other. Running out of ACT does not end the game; running out of MOV effectively does (see §8).

Because MOV is now exactly "tiles crossed", the budget is legible: `MOV_budget` is the length of the route in tiles, plus slack. A player who counts squares on screen can count their own budget, which is good — the difficulty should come from *finding* the route, not from mis-predicting what an input costs.

Typical ranges for the shipped pool:

| | Range |
|---|---|
| MOV budget | 18 – 40 |
| ACT budget | 3 – 12 |
| Slack over optimal | 0 – 3 on each counter |

These MOV figures are lower than a route's raw input count would suggest, since re-aiming presses no longer register. Budget against tiles entered.

---

## 7. Rewind (🅾️)

Rewind steps the entire game state back one turn. It is the player's main tool and should feel free and instant.

**A rewind restores:**
- player position
- player facing
- the rotated tile's previous wall state (if the turn was a rotation)
- MOV and ACT counters (full refund of that turn's cost)

**Rules:**
- Rewind itself costs nothing. It is not metered and never appears on the HUD.
- Rewind is available in every state, including after MOV hits 0.
- There is no redo. Once you rewind and act differently, the old branch is gone.
- Inputs that cost nothing create no history entry and cannot be rewound individually. This includes **free facing changes**: a blocked press that only reorients the player is not pushed to the buffer.

**Why free turns stay out of the history.** Facing is state, so at first glance a free turn looks rewindable. But free turns are unbounded — a player can spin in place a thousand times — and pushing them would blow any fixed buffer and make 🅾️ feel broken, since the player would have to press it repeatedly just to walk back one tile. Instead, each real entry already stores the facing the player had before that turn, so a rewind restores facing correctly along with everything else. Any re-aiming the player wants afterwards is free to redo. Nothing is lost.

**History depth:** the buffer must be at least `max(MOV_budget) + max(ACT_budget)` entries, so the player can always rewind all the way back to the first move of the maze. With the ranges in §6, a 64-entry buffer is enough; 96 gives comfortable headroom. Never silently drop the oldest entry — if the buffer is sized correctly this can never happen.

**Entry contents (delta, not snapshot):** turn type, previous player position, previous facing, and — for rotations only — the rotated tile index plus its previous wall value. Board snapshots are unnecessary because a turn only ever changes one tile.

**Restart:** holding 🅾️ for ~1 second rewinds continuously to the start of the maze. This doubles as "restart current maze" and needs no separate button. The pause menu carries "new maze" and "restart".

---

## 8. Win and loss

**Win:** the player's position becomes the exit tile. Reaching it is enough — no extra confirm press, no "exit the maze" step. Whatever MOV/ACT remain is irrelevant; there is no score.

**Out of movements:** when MOV reaches 0 and the player is not on the exit, the game enters a **stuck state**:
- movement and ❎ are dead — with no movements left, no rotation can change the outcome
- free turning still responds, so the player is never left with a frozen sprite
- 🅾️ still works
- the bottom bar shows the stuck message

The player is never force-failed. They rewind out of it or restart. Because rewind refunds, a stuck state is always recoverable — the "loss" is only ever the player's decision to give up.

**Out of actions (ACT = 0):** not a loss condition on its own. The player may well finish with rotations to spare, or may be stuck without any — in which case running the MOV counter down to 0 gets them to the stuck state above.

---

## 9. Maze pool — 64 mazes

Each new game selects one of **64 mazes**, invisibly. A maze bundles:

| Field | Notes |
|---|---|
| Wall layout | 210 tiles × 4 bits |
| Start position | col, row |
| Start facing | one of 4 |
| Exit position | col, row |
| MOV budget | integer |
| ACT budget | integer |

**Selection is hidden.** No maze number, no name, no seed, no "par" is ever displayed. The player has no way to tell one maze from another except by playing it, and no way to know whether the budget is generous or exact. This is the point: the player cannot calibrate expectations from the UI and has to read the board.

**Selection uses a shuffled bag.** Shuffle all 64 indices, deal them one at a time, reshuffle when exhausted. This prevents the same maze appearing twice in a short session, which a plain random pick would do noticeably often. The bag position is not persisted between cart launches.

### 9.1 Storage

Storing 64 raw layouts costs 64 × 210 nibbles = 6,720 bytes, which is tight against PICO-8's budget once sprites and code are accounted for.

**Recommended approach: 64 baked seeds.** Each maze is stored as a seed plus its two budgets — roughly 4 bytes each, 256 bytes total. The cart regenerates the layout deterministically from the seed at maze start. This requires that the in-cart generator be bit-for-bit deterministic and never change after the seeds are chosen — any tweak to the generator invalidates all 64 curated seeds and their verified budgets.

**Fallback: packed layouts.** Two tiles per byte in the map region, 15×14 blocks. Safer against generator drift, heavier on memory. Choose this if the generator turns out to be hard to keep stable.

---

## 10. Building the 64 mazes

Do this **offline**, outside the cart. The cart ships only verified results.

### 10.1 Generate backwards from a solution

Random maze generation plus a solver is expensive and mostly produces boring or unsolvable boards. Generating from a known solution is better on both counts:

1. Pick start and exit far apart (Manhattan distance ≥ 16 suggested).
2. Trace an intended solution path: a sequence of steps, with planned rotation points where the path deliberately passes through a wall that must be rotated away.
3. Carve that path — set the wall flags along it so it is traversable exactly as planned, with the rotation points still closed.
4. Fill the remaining tiles with walls: dead ends, decoy corridors, loops.
5. Compute the intended cost: `MOV = steps`, `ACT = rotations`. Facing changes are free and do not enter the calculation.

### 10.2 Verify with a solver

Every candidate must be run through an exhaustive solver before shipping. Free turning simplifies this considerably: since facing costs nothing to change, **facing can be dropped from the search state entirely**. From any position the solver treats "rotate neighbor N/E/S/W" as four available actions at 1 ACT each, with no aiming cost to model. The state is therefore just `(col, row, board)`, and because only rotated tiles differ from the initial board, a transposition table keyed on `(position, rotated-tile deltas)` stays small. IDA* bounded by the MOV/ACT budgets is adequate at these depths.

This is a real win — the pre-change state space was 4× larger and the extra dimension carried no puzzle meaning.

The solver produces `(MOV_optimal, ACT_optimal)` — the Pareto-optimal pairs, since a maze can often trade movements for rotations. Reject candidates where:

- no solution exists within any reasonable budget
- the optimal route uses **zero rotations** — that is just a maze, not this game
- the optimal route is significantly cheaper than the intended path (the generator left an unintended shortcut)
- fewer than ~3 distinct near-optimal routes exist (single-solution mazes feel like guessing)

### 10.3 Set the budgets

Set `MOV_budget = MOV_optimal + slack_m` and `ACT_budget = ACT_optimal + slack_a`, with slack from the §6 table. Slack 0 on both counters means the player must find *the* optimal solution — reserve that for a handful of mazes at the top of the pool.

Set budgets against the **cheapest** solution on each axis independently, not against a single chosen route. If the maze can be solved with 30 MOV / 8 ACT or with 38 MOV / 4 ACT, budgeting 31 MOV / 5 ACT forbids both. Verify the final budget pair admits at least one real solution.

---

## 11. Difficulty design

The brief calls for challenging. The levers, roughly in order of usefulness:

**Tight budgets.** The single strongest lever. Slack 0–1 forces near-optimal play and makes the rewind button the primary interface.

**Detour length.** With turning free, MOV is pure distance, so the only way to make movement expensive is to make the correct route physically long. Force the player away from the straight line: a wall that can only be opened from its far side turns a 3-tile hop into a 12-tile loop. Distance is now the honest lever it wasn't before.

> Removing the turn tax cost the design one difficulty lever — twisty corridors are no longer self-taxing, and a zigzag now costs exactly its tile count. Compensate on the two axes that remain: tighter MOV slack (0–1 across most of the pool) and heavier use of the rotation traps below. The pool distribution at the end of this section already assumes this.

**ACT scarcity.** Since aiming is free, rotations are gated *only* by the ACT counter — a player standing in one spot can freely rotate all four neighbors. ACT budgets therefore need to be tighter than they would otherwise be, or the player can brute-force local geometry by cycling neighbors until something opens. Budget ACT close to optimal (slack 0–1) on anything above the warm-up tier.

**Rotation traps.** Design tiles whose rotation opens the way forward but closes the way back, or closes a passage needed later. Since rotation is clockwise-only, a wrong rotation costs 3 more actions to undo in-game.

**The self-tile rule.** Place the critical wall on the tile the player is standing on. It cannot be rotated from there. The player must step away, turn around, and rotate it from the other side — often several movements of detour.

**Thick vs thin walls.** A shared wall (both tiles carry it) needs two separate rotations from two different positions. Using these as the final gate before the exit makes for good climaxes.

**Decoys.** Corridors that look like the obvious route but dead-end after 6–8 tiles. The MOV cost of exploring them is the punishment; rewind is the escape. These teach players to plan before moving.

**Rotation-only reachability.** Regions of the maze that are sealed off entirely at start and only become reachable after a specific rotation. Good for hiding the true route in plain sight.

Suggested pool distribution across the 64:

| Tier | Count | Character |
|---|---|---|
| Warm-up | 8 | 1–2 rotations, generous slack (2–3) |
| Standard | 32 | 3–6 rotations, slack 1–2 |
| Hard | 16 | 6–9 rotations, slack 0–1, traps |
| Brutal | 8 | 8–12 rotations, slack 0, self-tile and thick-wall gates |

Because selection is hidden and random, the player cannot tell which tier they drew. A brutal maze after a warm-up feels like a wall — that is acceptable, since restart is one held button away and the next maze is a different draw.

---

## 12. Edge cases

| Situation | Resolution |
|---|---|
| Arrow toward a blocked direction | Turn only, 0 cost, no history entry |
| Arrow toward off-grid, not already facing that way | Turn only, 0 cost, no history entry |
| Arrow toward off-grid, already facing that way | Ignored, 0 cost |
| X while facing off-grid | Ignored, 0 cost, no history entry, no faced-tile highlight drawn |
| X with ACT = 0 | Ignored, 0 cost |
| X on a 0-wall or 4-wall tile | Allowed, costs 1 ACT, board unchanged — still creates a history entry |
| Arrow with MOV = 0, blocked direction | Turn is still free and still permitted, but pointless — the stuck state below applies |
| Arrow with MOV = 0, clear direction | Ignored, game is in stuck state |
| 🅾️ with empty history | Ignored |
| Player standing on exit at maze start | Invalid maze, must be rejected at generation |
| Start tile fully enclosed (4 walls, all neighbors sealed) | Legal only if a rotation can open it; solver catches the rest |
| Rotation that seals the player in completely | Legal and intended — that is a trap, and rewind is the answer |

Note the 0-wall/4-wall row: charging for a no-op rotation is correct. The player chose to spend it, and refunding would leak information about the tile's state.

---

## 13. Resolved decisions

All five previously open questions are now settled and folded into the sections above. Recorded here so the reasoning survives.

1. **Rewind is free and unlimited.** No REW counter. The puzzle is already gated by MOV and ACT; metering the undo would turn planning into a resource to hoard and make the game hostile to experimentation. §7.
2. **Turning while blocked costs nothing.** *Changed from the original spec.* A blocked press reorients the player and charges no movement. MOV now means "tiles entered" and nothing else. Consequences: the bump-to-aim idiom costs 1 MOV instead of 2 (§5.3), MOV budgets drop to the 18–40 band (§6), free turns stay out of the rewind buffer (§7), the offline solver drops facing from its state (§10.2), and the turn-tax difficulty lever is gone and must be replaced by longer detours and tighter ACT (§11).
3. **The exit is always visible.** Drawn from the first frame. Hiding it would add exploration pressure that fights the plan-first design — the player should be able to solve the whole maze in their head before pressing anything. §2.
4. **The faced tile is highlighted.** A faint outline, never bright enough to compete with the walls. Especially necessary now that re-aiming is free and constant. §4.
5. **Blocked moves get a bump animation and sfx**, plus a 2-frame flash on the blocking wall so the player can tell whose wall it is. §5.1.

### Still worth watching in playtest

Not open questions, but the places where decision 2 is most likely to show its cost:

- **Do MOV budgets still bite?** Free turning made movement cheaper across the board. If mazes solve with movements to spare, cut slack to 0 before touching anything else.
- **Can players brute-force with rotations?** Standing in one spot cycling all four neighbors is now free apart from ACT. If this trivializes mazes, tighten ACT budgets rather than re-introducing a turn cost.
