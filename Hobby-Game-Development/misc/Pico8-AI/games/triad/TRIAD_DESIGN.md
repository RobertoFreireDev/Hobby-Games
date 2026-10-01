# TRIAD — PICO-8 Design Document

Working title: **TRIAD** (3 letters + short, fits the cart label and the title screen at any size).

A score-attack trio-finder built on the SET matching rule, played on a 3×3 board with a
visible 3-card backlog. The board is small on purpose: with only 12 cards on screen the
cards can be big, detailed and heavily animated.

---

## 1. The two layers

The design deliberately separates two skills. They must both be present in every turn.

**Puzzle layer — "can I see a trio?"**
Pure perception. Scan 9 cards, find 3 whose four properties are each *all equal* or *all
different*. This is the moment-to-moment task and it is the same task every turn.

**Strategy layer — "which trio should I take?"**
The board usually offers more than one valid trio. The backlog is face-up, so the player
knows exactly which 3 cards will land in the holes. That makes the next board state
**fully deterministic**: for every available trio the player can compute, before
committing, the exact 9 cards that will exist afterwards. Choosing the trio that leaves
the richest board — and avoiding the trio that leaves a dead board — is the game.

The run ends when the board has no trio. Everything in the scoring rewards keeping the
board alive.

---

## 2. Card model

### 2.1 Properties

Four properties, three variations each → **81 unique cards** (full SET deck).

| Property | 0 | 1 | 2 |
|---|---|---|---|
| Number  | one shape | two shapes | three shapes |
| Shape   | oval | diamond | squiggle |
| Color   | red (`8`) | green (`11`) | purple (`13`) |
| Shading | solid | striped (dithered) | open (outline) |

> Palette note: `13` reads as a cool lavender against the white card face and stays
> distinct from `8` and `11`. If `13` tests too washed-out on hardware, fall back to `2`
> (dark purple). Do **not** use `12`/`14` — too close to green/red at 8×8.

### 2.2 Encoding

A card is a single integer `0..80`, base 3:

```lua
num  =  id      % 3
shp  = (id\3)   % 3
col  = (id\9)   % 3
shd  = (id\27)  % 3
```

### 2.3 The trio rule (implementation)

Three cards form a trio when, **for each property independently**, the three values are
all the same or all different. In base 3 that is exactly:

```lua
function is_trio(a,b,c)
  local d=1
  for i=1,4 do
    if ((a\d)%3 + (b\d)%3 + (c\d)%3) % 3 ~= 0 then return false end
    d*=3
  end
  return true
end
```

Sum ≡ 0 mod 3 catches both cases: all-same gives `3v`, all-different gives `0+1+2=3`.

### 2.4 The completion property

**Any two cards determine exactly one third card that completes a trio.**

```lua
function completer(a,b)
  local id,d=0,1
  for i=1,4 do
    id += ((6 - (a\d)%3 - (b\d)%3) % 3) * d
    d  *= 3
  end
  return id
end
```

This is the backbone of the whole generator (§5). Never brute-force search for a
completing card — compute it.

### 2.5 Counting trios on a board

`C(9,3) = 84` triples, 4 property checks each. Run it once per board change, never per
frame. Cache the result in `board_trios` (a list of index triples) — the HUD, the scoring
bonus and the game-over check all read from it.

---

## 3. Screen layout (128×128, exact)

```
 x:0                              89 90            127
 y:0  ┌───────────────────────────────────────────────┐
      │  HUD  (black, dithered bottom edge)  h=12     │
 12   ├──────────────────────────────┬────────────────┤
      │                              │                │
      │   BOARD PANEL                │  BACKLOG PANEL │
      │   dark green (3) +           │  black (0) +   │
      │   dithered speckle           │  dithered edge │
      │                              │                │
 127  └──────────────────────────────┴────────────────┘
```

**Card size: 26×34.** Big enough for three 16×8 shapes plus frame and bevel.

Board card origins (`x`): `3, 32, 61` — 26 wide, 3px gaps, 3px margins → 90 total.
Card origins (`y`), shared by board and backlog: `15, 53, 91` — 34 tall, 4px gaps.

Backlog card `x = 96` (26 wide inside the 38px panel, 6px margins). The backlog rows line
up exactly with the board rows, which makes the fly-in animation read as a straight
horizontal slide.

### 3.1 HUD (y 0..11)

- Left: `SCORE` + current score, counting up with a tween (never snaps).
- Right: `MAX` + best score.
- Center: chain badge `x2`, `x3`… only while a chain is live; pops in with a scale bounce.
- All HUD text uses the outline helper (§7.1). Bottom edge of the bar is a 2-row dither
  fade into the panels, not a hard line.

### 3.2 Card face anatomy

```
26×34 card
├ 1px outer outline (dark, dithered at the 4 corners)
├ 1px inner bevel highlight (top+left lighter, bottom+right darker)
├ face: white (7) with a sparse dither of (6) for paper texture
└ 3 shape slots, 24px tall region starting at y+4:
    slot 0: y+4   slot 1: y+13   slot 2: y+22   (8px tall, 1px gap)
    shape 16×8, centered → x+5
```

- 1 shape → slot 1 only.
- 2 shapes → slots 0 and 2.
- 3 shapes → all slots.

**Sprites:** 9 shape sprites (3 shapes × 3 shadings) at 16×8 = 2 tiles each → 18 tiles
total. Draw them in white/black and recolor at draw time with `pal()`. Do **not** bake the
9 colors — that would be 54 sprites for no reason.

---

## 4. Turn loop

1. **PLAY** — cursor moves over the 3×3 board. `X` selects/deselects a card. `O` clears
   the selection. Backlog cards are not selectable.
2. On the 3rd selection the trio is evaluated immediately.
   - **Invalid** → shake, buzz, penalty, selection clears, back to PLAY.
   - **Valid** → **RESOLVE**.
3. **RESOLVE** — score is computed and awarded, the 3 cards burst out, the 3 holes are
   left empty for ~6 frames.
4. **REFILL** — the 3 backlog cards fly left into the holes (staggered). The board is
   rescanned.
5. **RESTOCK** — a new backlog of 3 is generated (§5.2) and dealt in from the right edge.
6. If the new board has **0 trios** → **GAMEOVER**. Otherwise → PLAY.

Holes keep their grid position — cards never re-flow. The backlog fills holes in
reading order (top-left first).

---

## 5. Generation

### 5.1 Opening board — always exactly 2 trios

Requirement: the first board contains **two distinct trios that share no cards** (6
distinct cards involved). Two disjoint trios guarantee that whichever one the player takes
first, the other is still intact — a fair, teaching opening.

Algorithm:

1. Pick trio A: draw 2 random cards from the deck, compute `completer`, take it.
2. Pick trio B the same way from the remaining deck; reject if it shares a card with A.
3. Fill the remaining 3 slots with random deck cards.
4. Recount trios on the full 9. If the count ≠ 2, replace the 3 filler cards and retry
   (the filler cards are what accidentally create trio #3).
5. Shuffle the 9 slot positions so the two trios are not visually adjacent.
6. Cap at ~40 attempts; on failure accept a board with ≥2 trios.

### 5.2 Backlog generation — the 50% rule

Rolled once, every time a new backlog is created:

- **50% — "loaded" backlog:** the 3 backlog cards themselves form a valid trio.
  This *guarantees* a trio on the board after the next refill, no matter which 3 cards the
  player removes. This is the correct way to hit "50% chance of a new trio" — trying to
  predict which board cards will survive is impossible, but a self-contained trio always
  survives.
  Build it with the completion property: draw 2 from the deck, compute the third, retry if
  the third is not available.
- **50% — "raw" backlog:** 3 random cards drawn from the deck, rejected if they happen to
  form a trio among themselves. No guarantee either way — a trio may or may not exist after
  the refill, which is exactly the pressure the strategy layer needs.

The coin flip is **not** hidden from a careful player: a loaded backlog is visibly a trio
on the right panel. That is a feature. Reading the backlog is part of the skill, and it
tells the player how much risk their choice carries this turn.

### 5.3 Deck management

- Maintain a shuffled bag of the 81 cards; draw from the front.
- When fewer than 12 remain, shuffle the discard pile back in (never mid-generation).
- Both generators may need to reject-and-redraw; always redraw from the bag, never
  fabricate an id outside it, or duplicates will appear on screen.

---

## 6. Scoring

The scoring exists to make the strategy layer pay. Points come from *what you leave
behind*, not just from what you take.

| Source | Value |
|---|---|
| Base trio | **100** |
| Difficulty bonus | **+25** per property that is *all different* (0–4 → +0…+100) |
| Board bonus | **+50** per trio on the board *after* the refill, beyond the first |
| Chain multiplier | ×1, ×1.5, ×2, ×2.5, ×3 (caps at ×3) |
| Invalid selection | **−25**, chain resets to ×1 |

**Chain:** increases by one step each time a match leaves the refilled board with **2 or
more trios**. Resets to ×1 on an invalid selection, or on a match that leaves exactly 1
trio. So the chain is a direct reward for playing the look-ahead well.

Final score formula per match:

```
(100 + difficulty_bonus + board_bonus) * chain_multiplier
```

**MAX score** is the persistent all-time best (`cartdata` slot 0). The moment the current
score passes it mid-run, the MAX field switches to a flashing "NEW RECORD" treatment and
stays live for the rest of the run.

Optional stretch: also persist longest chain and total trios found.

---

## 7. Art direction

Three rules, applied everywhere, no exceptions.

### 7.1 Outlined text

Every string on screen is drawn with a 1px dark outline. One helper, used for 100% of
`print` calls:

```lua
function oprint(s,x,y,c,o)
  o=o or 0
  for i=-1,1 do for j=-1,1 do
    if i~=0 or j~=0 then print(s,x+i,y+j,o) end
  end end
  print(s,x,y,c)
end
```

Score numbers additionally get a 1px drop shadow offset (0,2) in a darker tone so they sit
above the HUD bar.

### 7.2 Dithering on edges

`fillp` is the primary texture tool. Dithering appears at every boundary, never as a flat
gradient:

- Board panel: dark green `3` base, sparse `1` speckle dither, denser toward the panel
  edges so the play field feels vignetted.
- Backlog panel: black `0` with a 3-band dither fade (`5`→`1`→`0`) along its left edge, so
  the two panels blend instead of butting up.
- HUD: 2-row dither fade at the bottom.
- Cards: the 4 corner pixels of the outline are dithered, which visually rounds them
  without wasting a sprite.
- Striped shading: `fillp(0b0101101001011010)` with the card color over white.

### 7.3 Big, detailed cards

At 26×34 with only 12 on screen, spend the pixels:

- outer outline + inner bevel (two-tone) so cards look physical,
- paper-texture dither on the face,
- a 1px drop shadow under every card (offset 1,2) — this is what sells the lift on select,
- selected cards raise 2px and gain a bright animated outline that cycles `7`/`10`,
- empty holes are drawn as a dashed dark rectangle on the green, not as nothing.

---

## 8. Juice — every interaction gets feedback

Nothing in this game should happen silently. Frame counts assume 30fps.

| Event | Visual | Audio |
|---|---|---|
| Cursor move | cursor frame eases 4f into the new cell, slight overshoot | `sfx 0` short tick, pitch varies by column |
| Select card | card lifts 2px over 3f, outline ignites, small dust puff | `sfx 1/2/3` — the 1st, 2nd and 3rd selection play the three notes of a rising arpeggio |
| Deselect | card drops 2f, outline fades | `sfx 4` descending tick |
| Invalid trio | 8f horizontal shake of all 3 cards + full-screen red `pal` flash for 2f + `-25` popup falls and fades | `sfx 5` buzz |
| Valid trio | 3f white `pal` flash → 6f pulsing hold → 16 particles burst in the trio's colors → cards spin-shrink out over 8f (`sspr` scale down) | `sfx 6` chord resolution |
| Score award | score popup rises 20px over 20f while fading; HUD number tweens up | `sfx 10` ticking while the number climbs |
| Chain up | badge scale-bounces, brief screen zoom-punch (1px `camera` push) | `sfx 11`, pitch rises one step per chain level |
| Backlog → board | 3 cards slide left, ease-out over 10f, staggered 3f apart, 2f squash on landing, dust puff | `sfx 7` whoosh + `sfx 8` thud per card |
| New backlog deal | cards slide in from off the right edge over 8f, staggered | `sfx 9` per card |
| Board has ≥2 trios after refill | short sparkle on the panel border | subtle sparkle in `sfx 11` |
| New record | MAX field flashes, confetti particles from the HUD | `sfx 12` fanfare (once per run) |
| Game over | board desaturates via `pal`, cards fall off the bottom staggered, final score slams in | `sfx 13` |

**Screen shake** is a single global `(shx,shy)` applied through `camera()`, driven by a
decaying trauma value. Match = small, invalid = medium, new record = large.

**Particles**: one flat array, `{x,y,dx,dy,life,col}`, capped at ~48. Reused for dust,
bursts and confetti. Do not write three particle systems.

---

## 9. State machine

```
BOOT → TITLE → DEAL_IN → PLAY ⇄ SELECT
                            ↓ (valid)
                         RESOLVE → REFILL → RESTOCK → PLAY
                            ↓ (no trio after refill)
                         GAMEOVER → TITLE
```

Animation states (`DEAL_IN`, `RESOLVE`, `REFILL`, `RESTOCK`, `GAMEOVER`) block input and
advance on a frame counter. Never let the player select during an animation — it is the
main source of state bugs in this kind of game.

---

## 10. Data structures

```lua
board   = {}          -- 9 entries: card id, or nil while a hole is open
backlog = {}          -- 3 entries: card id
deck    = {}          -- shuffled bag of remaining ids
discard = {}
sel     = {}          -- up to 3 board indices
cursor  = 1           -- 1..9
score, maxscore, chain = 0, 0, 1
board_trios = {}      -- list of {i,j,k}, recomputed on every board change

-- per-card render state, indexed 1..9 (and 1..3 for backlog)
anim = { {x=,y=,lift=,scale=,spin=,alpha=}, ... }
```

Cards are drawn from `anim` positions, never from grid math directly. That way the same
draw function handles the resting state, the lift, the fly-in and the spin-out.

---

## 11. Controls

| Input | Action |
|---|---|
| ⬅️➡️⬆️⬇️ | move cursor on the 3×3 board (wraps) |
| ❎ | select / deselect card under cursor |
| 🅾️ | clear all selections |
| ❎ on title | start run |
| 🅾️ held 1s on game over | reset MAX score (with confirm) |

Mouse is optional and cheap to add (`stat(32/33/34)`) — hit-test the 9 card rects. Keep
keyboard as the reference input.

---

## 12. Token budget (8192 total)

| System | Estimate |
|---|---|
| Card model, trio check, generators | 700 |
| Board/backlog state + turn loop | 900 |
| Scoring + persistence | 350 |
| Card rendering (frame, bevel, dither, shapes) | 900 |
| Animation/tween system | 800 |
| Particles + screen shake | 450 |
| HUD + outlined text | 400 |
| Panels + backgrounds | 300 |
| Title / game over screens | 450 |
| SFX triggers + music hooks | 250 |
| **Total** | **~5500** |

Leaves ~2600 tokens of headroom for polish. The card renderer and the animation system are
the two places that will bloat; write both once, generically, and share them between board
and backlog.

---

## 13. Build order

1. Card encoding + `is_trio` + `completer`, verified in the console against known cases.
2. Static 9+3 layout with real card art, no interaction. Get the art right first — it
   determines everything else.
3. Cursor + selection + valid/invalid resolution, instant, no animation.
4. Opening-board generator (exactly 2 disjoint trios) + backlog 50% generator.
5. Scoring, chain, persistence, game-over detection.
6. Animation system, then juice pass: one event at a time, top to bottom through §8.
7. Title screen, game over screen, music.

---

## 14. NO TO ALL THESE QUESTIONS BELOW

- **Dead board rescue:** currently a dead board is game over. Alternative: allow one
  "reshuffle" per run that costs 200 points and swaps 3 board cards. Test whether it makes
  runs too long.
- **Hint assist:** optional toggle that outlines one card belonging to a valid trio. Off by
  default; would need to zero out the board bonus while active.
- **Timer variant:** a per-turn timer adds pressure but fights the look-ahead layer. Keep
  it out of v1.
- **Loaded-backlog tell:** should a loaded backlog get a subtle visual marker, or should
  spotting it be entirely on the player? Recommendation: no marker — spotting it *is* the
  skill.
