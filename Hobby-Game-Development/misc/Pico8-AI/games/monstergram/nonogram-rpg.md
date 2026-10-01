# Nonogram RPG — Design Document

PICO-8 dungeon crawler played as a nonogram. The clue numbers reveal where the
monsters are; everything else is safe ground, and a few safe tiles hide a sword.
Deduce, then choose the order you dig — because your sword breaks and you can
only carry one.

---

## 1. Core loop

1. A round is generated: a fresh 10×10 hidden field of **enemies**, **swords** and **empty** tiles, rolled from the same distribution every time (§8).
2. Clue numbers on the top and left borders describe **enemy runs only** (§3.2).
3. Player deduces which tiles are safe, flags the enemies, and reveals safe tiles.
4. A revealed sword is taken **only if it beats the one already held**.
5. Player may deliberately attack an enemy tile for XP, at the cost of hearts.
6. Round clears when **every non-enemy tile is revealed**. Next round, a new deal.
7. Run ends at 0 hearts.

---

## 2. Screen layout (128×128)

| Region | Pixels | Notes |
|---|---|---|
| Board | x 8–119, y 0–111 | 14×14 grid of 8×8 cells |
| Clue border | 3 cells thick, **top and left only** | corner (3×3) unused |
| Play field | x 36–115, y 28–107 | 10×10 tiles |
| Bottom bar | y 112–127 | 16 px tall, full width |

```
      +--- 3 cells ---+-------- 10 tiles --------+
      |   (corner)    |        top clues         |
      +---------------+--------------------------+
      |  left clues   |                          |
      |               |        PLAY FIELD        |
      |               |                          |
      +---------------+--------------------------+
      |  SWORD    HEARTS    XP BAR    ROUND      |
```

---

## 3. The clue system

### 3.1 What the numbers mean

Numbers count **runs of consecutive enemies** in that row or column. Items and
empty tiles are identical to the puzzle — both are "blank". This is the central
promise of the game: **the numbers never lie about danger**, so any tile you can
prove is blank is safe to step on. It just might be worthless.

### 3.2 One clue strip per axis

Clues appear on the **top and left only**, three cells deep, read toward the
field (run 1 outermost). There is no bottom or right strip.

An earlier version mirrored every clue onto the opposite border. On a line with
3 or fewer runs the two copies were *identical*, so the second one taught the
player nothing while costing 3 cells on each axis. Dropping it reclaims those
cells for play, taking the field from 8×8 (64 tiles) to **10×10 (100 tiles)** at
exactly the same screen size.

The catch is that three cells can no longer be topped up by a mirrored copy, so
a line with more than 3 runs would be **undescribable**. Generation therefore
treats it as a hard constraint: no line may exceed 3 runs, and no run may exceed
9 (§9). Every clue is stated in full, in one place, in one digit.

Empty lines show a single `0` in the cell nearest the field.

---

## 4. Tile contents

| Content | Frequency | Counted by clues? |
|---|---|---|
| Enemy (level 1–3) | 26–37% of field | Yes |
| Sword (power 1–3) | 5–8 tiles per round | No |
| Empty | everything else | No |

Roughly 1 blank in 9 holds a sword. Digging is mostly disappointing, which is
what makes an unbroken sword worth protecting.

---

## 5. The sword

The sword is the only item in the game, and the player holds **one at a time**.
The number printed on its icon is **W, its remaining life**; when W hits 0 the
sword shatters and the hand goes empty.

### 5.1 Power W (1–3)

- Cancels up to **W damage in a single fight**.
- After every fight, **W drops by 1**. At 0 the sword shatters.
- A W3 sword prevents at most 3 + 2 + 1 = 6 damage, but only if each fight is
  big enough to use its full power. Swinging a W3 sword at a level-1 enemy
  wastes 2 points forever.
- **Burst tool.** Save it for the level-3 monsters.

### 5.2 Picking one up

Revealing a sword tile takes the **better of the two**: a stronger sword replaces
the one in hand, a weaker one is left behind and the tile shows `kept N`. There
is no prompt and no choice — so an unopened blank next to a nearly-spent sword is
worth something, and one next to a fresh W3 is worth almost nothing.

### 5.3 Why breakability matters

The sword is a countdown. When it breaks, the only way to rearm is to reveal more
blank tiles — and only about 1 blank in 9 holds anything. So the player is
constantly pushed back into the puzzle, and constantly forced to answer: *do I
open safe ground now while I'm still armed, or save the unopened blanks as an
emergency supply for when my sword runs out?*

Opening the field too fast burns swords on nothing. Opening it too slowly leaves
you empty-handed against level-3 enemies. With no potion in the game, the only
healing is the level-up (§7), which makes that pressure one-directional: hearts
only come back by fighting.

---

## 6. Combat

Attacking is **always voluntary** — a round can be cleared without killing a
single enemy. Attacking is the only source of XP.

Reveal an enemy tile (deliberately or by mistake) and it resolves immediately:

```
raw damage      = enemy level (1, 2 or 3)
if holding sword:  damage = max(0, raw - W),  then W -= 1
hearts -= damage
xp     += enemy level
```

The enemy tile becomes a corpse tile: revealed, counted as cleared, no longer
part of any clue the player needs.

Accidentally revealing an enemy is punished by the same math — there is no extra
penalty for a wrong guess beyond the fight itself.

---

## 7. Hearts, XP and levelling

- Start: **level 1, 3/3 hearts**.
- XP gained = enemy level.
- On reaching the threshold, XP resets to 0, **max hearts +1**, and hearts are
  **fully restored**.

| Level | XP to next | Max hearts |
|---|---|---|
| 1 | 6 | 3 |
| 2 | 8 | 4 |
| 3 | 10 | 5 |
| 4 | 12 | 6 |
| 5 | 14 | 7 |
| 6+ | +2 each | +1 each (cap 8) |

The full heal on level-up is the **only** way to regain hearts, and so the main
reason to pick fights: a player at 1 heart with 5 XP banked has a real, tense
decision in front of them.

---

## 8. Rounds, not floors

There is no floor table and no depth curve. **Every round rolls a brand-new
dungeon from the same distribution**, and the roll is the game's entire luck
component (§12). A round is not "harder than the last one" — it is a different
hand dealt from the same deck.

Rolled fresh each round, on the 10×10 (100-tile) field:

| Rolled value | Range | Notes |
|---|---|---|
| Enemy count | 26–37 | 26–37% density |
| L3 share | 0 – 35% of the count | the teeth of the round |
| L2 share | 0 – 45% of the count | |
| L1 share | the remainder (≥20%) | |
| Swords | `(100 − enemies) ÷ 9`, min 5 | holds the 1-per-9-blanks ratio |
| Sword power W | 1–3 each, **first one always W3** | |

Both ends of every range are clamped, which is the point: the roll cannot hand
out a walkover (there are always ≥26 enemies and never more than 8 swords), and
it cannot strand the player either (a W3 sword is always somewhere in the field,
and L1 monsters are never fewer than a fifth of the count). Luck decides the
*shape* of the round — a swarm of L1 chaff, or a sparse field with a hard L3
core — never whether it can be won.

Round 2 is generated by exactly the same call as round 1. What actually escalates
across a run is the player: hearts are **not** restored between rounds and the
held sword is **kept**, so a run is a chain of independent puzzles played on a
carried-over body. Score += 100 per round cleared.

---

## 9. Level generation

1. Roll the enemy count and level mix for this round (§8).
2. **Place monsters in nests, not as singles.** Repeatedly drop a run of **2–3**
   monsters, horizontal or vertical, onto free tiles. A run is only kept if every
   row and column it touches still satisfies the clue constraint afterwards
   (≤ 3 runs, no run longer than 9); otherwise it is rolled back and re-rolled.
   This is what makes a single 3-cell clue strip sufficient.
3. Compute the 20 line clues (10 rows + 10 columns).
4. **Solvability check** — run a line solver: for every row and column, mark any
   tile that is enemy in all valid arrangements, or blank in all valid
   arrangements. Repeat until no new deductions. Count the tiles still
   undetermined; that count is the round's **luck budget spent on the board**.
5. Best-of-30: re-scatter until the undetermined count is **≤ 20 of 100** — the
   80/20 gate — keeping the best field seen and stopping on the first one that
   passes. Measured over 60 generated rounds: every one passed, average 4.6
   undetermined tiles, worst 20.
6. Place swords on random **non-enemy** tiles; the first one placed is always W3.

Step 2 is doing most of the work, and the run length is the whole lever.
Measured on this generator: scattering **single** monsters at random leaves a
board line-solvable only about 5% of the time — scattered singles produce
high-entropy `1 1 1 1` lines that pin down nothing. Runs of **1–3** raise that
to ~30% per attempt; runs of **2–3** raise it far enough that best-of-30 comes
back fully deducible on ~99% of rounds (109 of 110 measured), at a third of the
CPU cost. The rare miss is off by a handful of tiles, not a broken board.
Bigger clue numbers are also easier to read at 128 px.

An accepted ambiguous puzzle is not a failure state — the player can still clear
it by fighting through the ambiguous tiles — and at ~1 round in 100 it stays a
rarity rather than a habit.

---

## 10. Controls

| Input | Action |
|---|---|
| ⬅️ ➡️ ⬆️ ⬇️ | move cursor over the field |
| ⭕ | flag / unflag the tile as an enemy |
| ❎ | reveal the tile under the cursor |

Focus is always on the board. There is nothing to select in the bottom bar — the
sword is applied automatically in every fight — so ⭕ can be a plain press
instead of a hold, and the board cursor is the only cursor on screen.

- The cursor never enters the clue border; it wraps at the field edges.
- Flagged tiles cannot be revealed by ❎ — unflag first. This makes fast play
  safe.

---

## 11. Bottom bar

One slot — the **sword**. Empty, it draws as a dim outline rather than
disappearing, so the space always reads as "the thing you are missing".

```
[⚔3]   ♥♥♥♡♡   XP ▓▓▓░░░   F2
```

- Held sword: bright icon + its remaining W.
- Hearts: filled/empty pips, up to 8.
- XP: a thin bar that empties on level-up.
- Round number and score to the right.

Feedback: the number **flashes white** when a charge is spent, and the slot
**cracks and empties** on the frame the sword breaks. Breaking must be loud —
it is the event that sends the player back to digging.

---

## 12. Replayability — 20% luck / 80% strategy

This split is not a vibe; it is the number the generator is built around. Each
round is dealt fresh (§8), and the deal is allowed to decide at most a fifth of
the outcome.

**Luck (20%)** — two things, both bounded:

- **The roll.** Enemy count, tier mix, sword count and sword powers, and where
  the swords sit among the blanks. Every range is clamped at both ends (§8), so
  the roll changes the shape of the round, never its winnability.
- **The undecidable tiles.** At most **20 of the 100** tiles may resist pure
  line deduction — that is the literal 20%, enforced by the generator gate in
  §9.5, and in practice it averages ~5. Those are the only tiles a player can be
  forced to guess on.

**Strategy (80%)** — at least 80 tiles of every board are deducible with
certainty, and everything below is under the player's control:

- Reading the clues correctly instead of guessing.
- **Reveal order.** Which blank to open first is the whole game. Open blanks
  while armed and you waste the sword hiding under them; hoard them and you may
  be caught empty-handed.
- Spending charges on the right enemy level (W3 on an L3, never on an L1).
- Choosing which fights to take for XP, and when a level-up heal is worth the
  risk of reaching it — it is the only heal there is.

---

## 13. Art notes

- 8×8 tiles, chunky pixels, no anti-aliasing.
- Unrevealed tile: flat dark slab with a 1 px highlight.
- Revealed blank: recessed floor, one shade darker.
- Enemy sprites: three silhouettes, distinguished by shape and by a level pip,
  not by colour alone.
- Reserve one bright accent colour for **danger and interaction only** — the
  cursor, flags, and damage flashes.
- Clue digits: drawn in a lighter shade than the field so the border reads as a
  frame, not as playable space. Values are 1–9, always one digit, so they need no
  kerning. A line whose monsters are all accounted for dims its whole clue.

---

## 14. Game states

`title → generate_round → play → (fight resolve) → round_clear → generate_round`
with `play → game_over → title` on 0 hearts.

Game over screen: rounds survived, level, enemies defeated, final score
(`rounds × 100 + xp + kills × 5`).
