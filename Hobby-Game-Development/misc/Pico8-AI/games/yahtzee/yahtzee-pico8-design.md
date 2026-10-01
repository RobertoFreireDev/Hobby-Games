# YAHTZEE — PICO-8 Design & Technical Documentation

**Working title:** `HIGH ROLLER`
**Platform:** PICO-8 (0.2.7)
**Genre:** Turn-based dice / score-chase vs. CPU
**Session length:** ~4 minutes per full game (13 rounds)
**Pitch:** A one-screen, high-polish Yahtzee duel on a green casino felt. You and the house each fill the same 13 categories. Every input is one button away, every action is loud, and the machine never lets you wait.

---

## 1. Design pillars

1. **One screen, zero menus.** The table, both scores, and the dice all live on the same 128×128 frame. You never navigate away to see anything.
2. **Speed above all.** Worst case is 3 button presses per turn. Every animation is skippable by pressing any button. Juice never costs the player time.
3. **Maximum juice.** Every state change gets a sound, a movement, and a colour flash. Nothing appears or disappears instantly.
4. **Professional felt look.** Muted extended palette, ordered dithering, consistent 1px dark outlines, no gradients drawn with raw solid bands.
5. **The house has a face.** The CPU is a dealer character who reacts. It reads as an opponent, not as a number.

---

## 2. Rules

Standard American Yahtzee, 13 rounds, both players play every round.

### Upper section
| Category | Score |
|---|---|
| Ones | Sum of all 1s |
| Twos | Sum of all 2s |
| Threes | Sum of all 3s |
| Fours | Sum of all 4s |
| Fives | Sum of all 5s |
| Sixes | Sum of all 6s |
| **Bonus** | **+35 if upper subtotal ≥ 63** |

### Lower section
| Category | Condition | Score |
|---|---|---|
| Three of a kind | 3+ same face | Sum of all 5 dice |
| Four of a kind | 4+ same face | Sum of all 5 dice |
| Full house | 3 + 2 | 25 |
| Small straight | 4 consecutive | 30 |
| Large straight | 5 consecutive | 40 |
| Yahtzee | 5 same face | 50 |
| Chance | Always | Sum of all 5 dice |

### House rules (locked decisions)
- **Extra Yahtzees:** +100 bonus each, awarded immediately, only if the Yahtzee box already holds 50. Shown as a small `+100` chip flying into the total.
- **Joker rule:** simplified. A second Yahtzee may be scored in *any* open category; upper categories score their normal sum, lower categories score their fixed value. No forced-upper restriction. Chosen because the forced-upper rule is invisible to a casual player and would need explanation text the screen has no room for.
- **Zeroing out:** always allowed. Confirmation prompt only when scoring a 0 into a category that could still score later (`SURE? ❎/🅾️`). This is the single exception to the no-menus rule and it exists purely to prevent misclicks.
- Turn order alternates who goes first each round to keep the last-round advantage balanced.

---

## 3. Screen layout (128×128)

```
 y=0   ┌──────────────────────────────────────┐
       │ ♠ HIGH ROLLER      R 07/13    HI 284 │  header strip, 7px
 y=8   ├───────────────────┬──────────────────┤
       │ ONES     12   9   │ 3 KIND   21  --  │
       │ TWOS      6  10   │ 4 KIND   --  --  │
       │ THREES   --   9   │ F HOUSE  25  25  │  two 7-row panels
       │ FOURS    16  12   │ SM STR   --  30  │  row height 9px
       │ FIVES    --  15   │ LG STR   40  --  │
       │ SIXES    24  --   │ YAHTZEE  --  --  │
       │ BONUS    --  --   │ CHANCE   19  22  │
 y=77  ├───────────────────┴──────────────────┤
       │  YOU 163            DEALER 132       │  totals bar, 8px
 y=86  ├──────────────────────────────────────┤
       │   ▓▓  ▓▓  ▓▓  ▓▓  ▓▓                 │  5 dice, 16×16
       │   ▓▓  ▓▓  ▓▓  ▓▓  ▓▓                 │
       │   ══      ══                         │  hold clamps
 y=110 ├──────────────────────────────────────┤
       │ ❎ ROLL (2 LEFT)   🅾️ HOLD   ⬇️ SCORE │  context bar
 y=127 └──────────────────────────────────────┘
```

### Exact geometry

| Element | x | y | w | h |
|---|---|---|---|---|
| Header strip | 0 | 0 | 128 | 7 |
| Left panel | 1 | 9 | 61 | 66 |
| Right panel | 66 | 9 | 61 | 66 |
| Panel row *n* | panel.x | 11 + n*9 | 61 | 9 |
| — label | +2 | +2 | 30 | 5 |
| — YOU column | +34 | +2 | 12 | 5 |
| — CPU column | +48 | +2 | 12 | 5 |
| Totals bar | 1 | 77 | 126 | 8 |
| Die *n* | 16 + n*20 | 88 | 16 | 16 |
| Hold clamp *n* | 16 + n*20 | 105 | 16 | 3 |
| Context bar | 0 | 111 | 128 | 8 (scrolls, see §7) |

Two panels of exactly 7 rows is the reason the upper section carries `BONUS` as a visible row — it fills the seventh slot and stops the layout from being lopsided. Labels are capped at 7 characters (28px at 4px/char): `THREES`, `F HOUSE`, `YAHTZEE`, `CHANCE` are the longest.

---

## 4. Art direction

### 4.1 Palette

Runtime remap in `_init()`, applied once. Uses the extended palette so the felt reads as real cloth rather than PICO-8 default green.

| Slot | Remap | Hex | Role |
|---|---|---|---|
| 0 | 128 | `#291814` | outlines, all silhouettes |
| 1 | 131 | `#125359` | felt shadow / vignette |
| 2 | 133 | `#49333b` | drop shadows under dice & panels |
| 3 | — | `#008751` | **felt base** |
| 4 | 132 | `#742f29` | mahogany trim, table rail |
| 5 | 134 | `#a28879` | worn brass, dead text |
| 6 | — | `#c2c3c7` | dice body shade |
| 7 | — | `#fff1e8` | dice body, primary text |
| 8 | 136 | `#be1250` | dealer accent, danger, zeros |
| 9 | — | `#ffa300` | gold |
| 10 | 135 | `#f3ef7d` | gold highlight, score pops |
| 11 | 139 | `#00b543` | felt highlight |
| 12 | 140 | `#065ab5` | player accent |
| 13 | 141 | `#754665` | plum, deco ornament |
| 14 | 142 | `#ff6e59` | particles, warm sparks |
| 15 | 143 | `#ff9d81` | rim light |

```lua
function setpal()
 local p={128,131,133,3,132,134,6,7,136,9,135,139,140,141,142,143}
 for i=0,15 do pal(i,p[i+1],1) end
end
```

### 4.2 Dithering

All large fills are dithered with `fillp()`. Never a flat rectangle wider than 24px.

Bayer-ordered ramp, felt shadow (1) into felt base (3):

| Density | fillp pattern |
|---|---|
| 0% | `0b0000000000000000` |
| 12% | `0b1000000000000000` |
| 25% | `0b1000001000000010` |
| 37% | `0b1000010100100000` |
| 50% | `0b0101101001011010` |
| 62% | `0b0111101011011010` |
| 75% | `0b0111110101111101` |
| 87% | `0b0111111111011111` |
| 100% | `0b1111111111111111` |

Applied to:
- **Table vignette** — a 5-band dither ramp from the screen edges inward, 1→3. Baked once into a fullscreen draw, not per-frame maths.
- **Panel bodies** — 25% dither of 1 over 3, giving the score table a slightly darker cloth.
- **Dice shadows** — 50% checker of 2, offset +2,+2, never solid.
- **Transitions** — the wipe between states is the dither ramp animated 0%→100% over 12 frames (`§8.3`).
- **Disabled rows** — greyed with a 50% checker of colour 5 instead of a dimmer colour, keeping the pixel-art feel.

### 4.3 Style rules

- Every sprite has a 1px colour-0 outline. No exceptions, including text (see §7.4).
- Chunky pixels: no anti-aliasing, no dither used *inside* a sprite smaller than 12×12 — it turns to noise at that scale.
- Light comes from the upper left. Every die gets a colour-7 rim on its top-left edge and a colour-6 shade on its bottom-right.
- Art-deco framing: fan corners, thin double rules, and a small spade/club/heart/diamond motif repeated in panel corners. It sells "casino" without a single photo-real element.

---

## 5. Spritesheet map (uses all 256 slots)

The game needs no map data, so the shared region (sprites 128–255) is free for art. Rows are 8-sprite... 16 sprites wide, `0x0` at top-left.

| Sprites | Pixel region | Contents |
|---|---|---|
| 0–23 | (0,0)–(95,15) | **Dice faces 1–6**, 16×16 each (2×2 slots) |
| 24–27 | (96,0)–(127,15) | Blank die, tumbling-blur die |
| 32–47 | (0,16)–(127,23) | Dice tumble frames A (motion-smear silhouettes) |
| 48–63 | (0,24)–(127,31) | Dice tumble frames B, landing squash frames |
| 64–79 | (0,32)–(127,39) | Title logo — `HIGH ROLLER` letterforms, 3 rows tall |
| 80–95 | (0,40)–(127,47) | Title logo, rows 2–3 + shine overlay strip |
| 96–111 | (0,48)–(127,55) | UI chrome: panel corners, rails, cursor arrow, hold clamps, chips |
| 112–127 | (0,56)–(127,63) | Icons: crown, trophy, dice pip cluster, arrows, ♠♥♦♣ |
| 128–143 | (0,64)–(127,71) | Particles: sparkles (4 frames), confetti (6 colours), coin spin (6) |
| 144–159 | (0,72)–(127,79) | Smoke puffs, impact rings, star burst, dust |
| 160–175 | (0,80)–(127,87) | Deco: art-deco fan corners, rules, felt seam texture tiles |
| 176–191 | (0,88)–(127,95) | Deco: rail wood tiles, card-back pattern, vignette corner masks |
| 192–207 | (0,96)–(127,103) | **Dealer portrait** 32×32, 4 expressions (neutral / smug / worried / stunned) |
| 208–223 | (0,104)–(127,111) | **Player portrait** 32×32, 4 expressions, same set |
| 224–239 | (0,112)–(127,119) | Big gold digits 0–9 (10×12) for the results screen |
| 240–255 | (0,120)–(127,127) | `YAHTZEE!` banner, `WIN` / `LOSE` word art, new-record ribbon |

> Sprite flags: bit 0 = "has transparency beyond colour 0", bit 1 = "particle, additive-ish flicker", bit 2 = "UI, never palette-shifted during flash effects".

---

## 6. Game states

```
BOOT ──▶ TITLE ──▶ GAME ──▶ RESULTS ──▶ TITLE
          │  ▲                  │
          ▼  └──────────────────┘
       ATTRACT (idle 20s: CPU plays itself behind the logo)
```

| State | Enter | Exit | Notes |
|---|---|---|---|
| `BOOT` | cart start | 60 frames | Logo sting, palette setup, `cartdata()` load |
| `TITLE` | — | ❎ | See §9 |
| `ATTRACT` | 20s idle on title | any button | Dimmed live game behind a 62% dither, no input |
| `GAME` | ❎ from title | round 13 scored | Sub-states below |
| `RESULTS` | game end | ❎ | Score tally, record check, portraits react |

### GAME sub-states

| Sub-state | Description |
|---|---|
| `ROUND_INTRO` | 20 frames. Round number slides in and out. Skippable. |
| `P_ROLL` | Player picks holds and rolls. Rolls left: 3 → 0. |
| `P_TABLE` | Cursor is on the score table, live previews shown. |
| `P_COMMIT` | Score flies from dice to the chosen row, counts up. |
| `CPU_THINK` | Dealer deliberates, 20–45 frames, portrait animates. |
| `CPU_ROLL` | Same visual language as the player's roll, no input. |
| `CPU_COMMIT` | Dealer's score lands. |
| `ROUND_END` | Totals recalculate, bonus check, lead indicator updates. |

---

## 7. Controls & UX

### 7.1 Input map

| Sub-state | ⬅️➡️ | ⬆️⬇️ | 🅾️ (Z) | ❎ (X) |
|---|---|---|---|---|
| `P_ROLL` | move die cursor | ⬇️ → go to table | toggle hold | roll |
| `P_TABLE` | switch panel | move row | back to dice | score here |
| Anywhere | — | — | — | skip current animation |
| Title | — | — | toggle music | start |

Held ⬅️➡️ auto-repeats after 8 frames at 3-frame intervals. Cursor wraps.

### 7.2 The speed guarantees

- **Worst case per turn: 3 presses.** ❎ roll, ⬇️ to table, ❎ to score. That is a complete legal turn.
- **Typical turn: 6–8 presses.** Roll, a few holds, roll, ⬇️, a row move, score.
- **No animation blocks input.** Every juice effect is a timer that draws; the state machine advances the moment input arrives. Pressing ❎ during a roll snaps the dice to their final faces instantly.
- **Live previews.** In `P_TABLE`, every open row shows the score the current dice would earn, in colour 5. Zero-scoring rows show `0` in colour 8. The player never has to compute anything.
- **Best-move highlight.** On entering `P_TABLE`, the cursor starts on the highest-scoring open category and that row pulses gold for 30 frames. Accepting the suggestion is a single ❎.
- **Roll from anywhere.** ❎ in `P_TABLE` scores; but if the player has rolls left and presses 🅾️ then ❎, they are back rolling in two frames. No confirmation dialogs.
- **Auto-advance.** After `P_COMMIT`, the CPU turn begins on its own. The player is never asked to press a button to continue except on the results screen.

### 7.3 Hold interaction

Holding is the most-used action, so it is the cheapest one. The cursor sits under the dice as a gold chevron; 🅾️ toggles. A held die:
- drops 2px and gains a brass clamp sprite underneath,
- desaturates slightly (palette swap 7→6, 6→5),
- plays `sfx 2` (a short wooden clack, pitch varies with die index so a 5-die lockdown sounds like an arpeggio).

Unholding plays `sfx 3` and the die hops 3px.

### 7.4 Typography

All text is outlined. A single helper draws colour-0 at 8 surrounding offsets, then the fill colour on top — expensive at 9 draws per string, so it is used only for the header, totals, context bar and pop-ups. Table rows use a cheaper 2-offset shadow (down-right only).

---

## 8. Juice specification

Juice is the point of this build. Nothing changes state silently.

### 8.1 Dice

| Beat | Effect |
|---|---|
| Roll start | All unheld dice launch up with random `vy` −2.2…−3.4 and `vx` ±0.6. Rattle `sfx 0` loops. Screen shakes 1.5px for 4 frames. Dust puff sprites at the launch point. |
| Airborne | Faces cycle every 2 frames through tumble-blur sprites (32–63), not the real faces. Dithered shadow on the felt scales down as the die rises. |
| Landing | Staggered 3 frames apart per die. 3-frame squash (16×16 → 18×13 → 15×17 → 16×16). `sfx 1` with per-die pitch. Impact ring sprite, 4 frames. 1px shake per landing. |
| Settle | 6-frame overshoot wobble, ±1px rotation faked by 1px horizontal jitter. |
| Final die lands | Hand evaluates; if it beats the current best available category by 20+, a small gold sparkle burst fires from the dice row. |

### 8.2 Scoring

| Beat | Effect |
|---|---|
| Row selected | Row background flashes to colour 10 for 2 frames, then dithers back over 8. `sfx 5`. |
| Score travel | The number lifts off the dice row and arcs to the table cell over 14 frames, trailing 4 sparkle sprites. |
| Count-up | The cell number ticks from 0 to its value over 12 frames with easing, `sfx 7` every tick, pitch rising. |
| Total update | Totals bar number counts up simultaneously. If the player takes the lead, the `YOU` label pops to 1.5× (drawn as a scaled sprite word) and a chip stack sound plays. |
| Upper bonus earned | Full stop. 45 frames. `BONUS` row explodes into 12 confetti particles, `+35` banner drops, `sfx 8` fanfare, screen flashes to a 25% dither of colour 10. Skippable. |
| Yahtzee | 90 frames. Screen shake 3px, palette inverts for 2 frames, `YAHTZEE!` banner sprite slams in from the top with a 4-frame overshoot, 40 confetti particles, `sfx 11` + `sfx 12` chained, music ducks to 30% for the duration. |
| Zero scored | Row shakes horizontally ±2px for 6 frames, cell drawn in colour 8, dull `sfx 6`, dealer portrait switches to smug for 30 frames. |

### 8.3 Transitions

Dither wipe, 12 frames, using the §4.2 ramp animated top-to-bottom as a moving 24px-tall band. Used between `TITLE→GAME`, `GAME→RESULTS`, and round boundaries (shortened to 6 frames).

### 8.4 Ambient life

Even when nothing is happening the screen breathes:
- Felt vignette shifts one dither step over a 4-second sine.
- Two portraits idle-blink on independent 3–6s timers.
- A slow specular sweep travels across the title logo every 5 seconds.
- The context bar text scrolls if it exceeds 128px, otherwise gently pulses colour 5→7 every 90 frames.
- Held dice have a 1px "settled" bob every 40 frames, offset per die.

### 8.5 Particle system

One flat pool of 48 particles, struct-of-arrays for token economy: `x,y,vx,vy,life,spr,g`. Types: sparkle (no gravity, 8-frame life), confetti (gravity 0.12, tumbles through 6 sprite frames, 60-frame life), dust (no gravity, fades via sprite frames), coin (gravity 0.2, bounces once off y=120).

---

## 9. Intro screen

```
        ✦          ✦
    ┌───────────────────┐
    │   H I G H         │   logo sprites 64–95, drops in from
    │       R O L L E R │   above with a 4-frame overshoot
    └───────────────────┘
         ⚀ ⚄ ⚂            three dice idly tumble, one every 2s

         ❎ PLAY
         🅾️ MUSIC: ON

      BEST 284   WON 7/19
```

- Background: dithered green felt vignette, plus four art-deco fan corners (sprites 160–175) and a slow parallax of 3 faint chip silhouettes drifting right at 0.15 px/frame.
- **Entry:** logo drops (18 frames), a shockwave ring expands from it, three dice tumble in and land on 6-6-6 with `sfx 21`, then the menu fades up via a 4-step dither.
- **Idle:** every 2 seconds one of the three display dice re-rolls itself with the full landing juice. The `❎ PLAY` prompt pulses 7↔10.
- **Record line:** if `BEST` was set in the last session, it draws in gold with a small ribbon sprite and one sparkle per second.
- **Attract mode:** after 20 seconds, the title dims behind a 62% dither and a full CPU-vs-CPU game plays out at 2× animation speed behind it. Any button returns to the title instantly.

---

## 10. Audio

Casino swing over classical bones — the bass line and brush pattern are lounge/casino; the melodic material is Baroque-flavoured counterpoint. It should sound like a harpsichord got a job in a card room.

> **Source note:** write original melodies *in the style of* the Baroque/Classical repertoire, or arrange works that are unambiguously public domain (Bach, Handel, Vivaldi, Mozart). Do not transcribe a modern recording or arrangement.

### 10.1 SFX allocation (0–23)

| # | Sound | Notes |
|---|---|---|
| 0 | Dice rattle | looping, plays while airborne |
| 1 | Die land | pitch varies ±3 semitones by die index |
| 2 | Hold clack | pitch rises with die index |
| 3 | Unhold | |
| 4 | Cursor move | very short, 4 ticks |
| 5 | Confirm | |
| 6 | Invalid / zero | |
| 7 | Score tick | pitch rises across the count-up |
| 8 | Upper bonus fanfare | |
| 9 | Small win chime | ≤ 20 pts |
| 10 | Big win chime | > 20 pts |
| 11 | Yahtzee fanfare A | |
| 12 | Yahtzee fanfare B | chained after A |
| 13 | Chip stack | lead change |
| 14 | Panel slide | |
| 15 | Dealer thinking | low hum, loops |
| 16 | Dealer scores | |
| 17 | Round whoosh | |
| 18 | Game over — lose | |
| 19 | Game over — win | |
| 20 | New record | |
| 21 | Title sting | |
| 22 | Menu blip | |
| 23 | Final-round tension | one-shot on round 13 |

### 10.2 Music (sfx 24–63, patterns 0–31)

| Patterns | Track | Description |
|---|---|---|
| 0–7 | **Overture** (title) | Free-time harpsichord arpeggio, then a walking upright bass enters and the two lock into swing. Loops. |
| 8–19 | **Green Felt** (main) | 12-pattern loop. Ch0 walking bass, ch1 brush-kit percussion, ch2 Alberti-bass harpsichord figure, ch3 lead melody that drops out for 4 patterns to leave breathing room. |
| 20–23 | **Last Hand** | Enters automatically on round 12. Same bass, minor-mode lead, a ticking hi-hat 16th, tempo +8%. |
| 24–27 | **Payout** (win) | Bright Handel-style fanfare resolving into the Green Felt bass line. |
| 28–31 | **House Wins** (lose) | Same fanfare in minor, slower, ending unresolved. |

Music ducks to 30% volume during Yahtzee and bonus celebrations (re-issue `music()` with lowered per-channel volumes, or simply `music(-1)` and restart on the same pattern for the cheap version).

Music toggle persists to `cartdata`. When off, SFX remain on.

---

## 11. CPU opponent

### 11.1 Algorithm

Monte-Carlo hold-mask search. Turn-based, so it can afford real compute if spread across frames.

```
for each of the 32 hold masks:
  for i = 1..N samples:
    simulate the remaining rolls
    score = max over open categories of (points + positional bonus)
    accumulate
choose the mask with the best mean
```

- **N by difficulty:** Easy 12, Normal 40, Hard 90 samples per mask.
- **Frame budget:** the search is a coroutine yielding every 64 simulated hands, spread over 20–45 frames — exactly the length of the `CPU_THINK` animation, so the thinking time *is* the compute time. No stalls.
- **Positional bonus:** upper-section scores get +8 weight while the upper subtotal is short of 63 and the remaining upper boxes could still reach it; Yahtzee gets +15 weight while open; Chance gets −10 while any other box is open (it's the fallback).

### 11.2 Personality

The dealer is not just a number. Portrait expression is driven by lead margin and the last event:

| Condition | Expression | Extra |
|---|---|---|
| Leading by 25+ | smug | occasional single raised eyebrow frame |
| Within 25 | neutral | idle blink |
| Trailing by 25+ | worried | 1px nervous jitter every 90 frames |
| Player scores a Yahtzee | stunned | 60 frames, then worried |
| Dealer scores a Yahtzee | smug | tips an invisible hat, 40 frames |
| Dealer forced to zero | worried | small puff of smoke sprite |

Difficulty is offered on the title screen only after the first completed game (keeps first-run friction at zero). Default Normal.

---

## 12. Persistence

```lua
cartdata("rbt_highroller_1")
```

| dget index | Meaning |
|---|---|
| 0 | Best player total ever |
| 1 | Games played |
| 2 | Games won |
| 3 | Lifetime Yahtzee count |
| 4 | Best win margin |
| 5 | Flags bitfield — bit0 music on, bit1 intro seen, bits2-3 difficulty |
| 6 | Save version stamp (`1`) |
| 7 | Best single-game upper subtotal |

Version stamp is checked at boot; a mismatch wipes slots 0–7 and rewrites, so a later layout change can't surface garbage records. Writes happen once, at `RESULTS` entry — never per-frame.

New record handling: if `total > dget(0)`, the results screen holds for an extra 60 frames, the ribbon sprite drops in, `sfx 20` plays, and the number counts up in gold with a sparkle per digit.

---

## 13. Code structure

| Tab | Contents | Est. tokens |
|---|---|---|
| 0 | `_init/_update60/_draw`, state machine, transitions | 550 |
| 1 | Dice: roll, physics, hold, tumble animation | 700 |
| 2 | Scoring: 13 category evaluators, previews, totals, bonus | 900 |
| 3 | CPU: mask search, coroutine budget, personality | 800 |
| 4 | UI draw: table, panels, dice row, header, context bar, text helpers | 1100 |
| 5 | FX: particles, shake, flashes, dither ramps, banners | 850 |
| 6 | Audio: sfx wrapper with pitch/priority, music director | 350 |
| 7 | Title, attract, results, cartdata | 700 |
| | **Total** | **~5950 / 8192** |

Roughly 2200 tokens of headroom. Spend it on juice, not features.

### Token discipline
- Category evaluators live in one table of functions indexed 1–13; scoring, previewing and the CPU all call the same 13 closures. This is the single biggest saving in the cart.
- Particles are 7 parallel arrays, not 48 tables.
- Dither ramps are a flat table of 9 constants; no runtime pattern generation.
- The outline-text helper is used sparingly — it costs tokens once and CPU forever.

---

## 14. Performance

Target `_update60`. Danger points:

| Risk | Mitigation |
|---|---|
| 48 particles × outlined sprites | particles use `spr()` with no outline pass |
| Fullscreen dithered vignette every frame | draw once to a static pattern; only re-issue `fillp` when the band index changes |
| Outlined text at 9 draws/string | capped at 6 outlined strings on screen at once |
| CPU search | coroutine-yielded, hard cap of 4000 simulated hands per turn |
| Yahtzee celebration | particle spawn capped at 40; if the pool is full, oldest are recycled |

Fallback: if `stat(1)` exceeds 0.85 for 30 consecutive frames, halve the particle cap for the rest of the session.

---

## 15. Build order

1. **Playable core** — dice roll, holds, 13 scoring functions, table draw, hot-seat two-player. No art, no sound. *This must be fun to press before anything else happens.*
2. **CPU** — mask search, difficulty, no personality yet.
3. **Layout lock** — final geometry, live previews, best-move highlight, context bar. Playtest the 3-press turn.
4. **Art pass** — palette, dice sprites, dithered felt, panels, portraits.
5. **Juice pass** — dice physics, count-ups, flashes, particles, screen shake, transitions.
6. **Audio pass** — SFX first (they teach the timing), then the two music tracks.
7. **Title, attract, results, persistence.**
8. **Polish** — spritesheet fill (deco, banners, word art), edge cases, performance guard.

---

## 16. QA checklist

- [ ] Every category scores correctly, including 4-of-a-kind counting all five dice.
- [ ] Small straight detects 1234, 2345, 3456 with a duplicate present (e.g. 1-2-3-4-4).
- [ ] Upper bonus fires at exactly 63, not 62.
- [ ] Second Yahtzee awards +100 only when the Yahtzee box holds 50, not when it holds 0.
- [ ] Zeroing the Yahtzee box then rolling a Yahtzee awards no bonus.
- [ ] Every animation is skippable and skipping leaves state correct.
- [ ] Mashing ❎ through a full game never desyncs the state machine.
- [ ] Holding all 5 dice and rolling is a legal no-op that still consumes a roll and plays sound.
- [ ] Round 13 ends the game even if the last score is 0.
- [ ] Tie game shows a distinct result, not a win.
- [ ] `cartdata` survives a cart reload; a version bump wipes cleanly.
- [ ] Music toggle persists and silences music only.
- [ ] Attract mode exits on any button within 1 frame.
- [ ] `stat(1)` stays under 0.9 during a Yahtzee celebration with 5 dice landing.

---

## 17. Stretch goals

Only after everything above ships.

- **Best-of-three match** with a chip-stack meta screen between games.
- **Dealer voices** — 6 short `sfx` grunts tied to the expression system.
- **Statistics screen** on the title, second page: lifetime Yahtzees, average score, category hit rates.
- **Daily seed** — a fixed dice sequence for the day so scores are comparable.
