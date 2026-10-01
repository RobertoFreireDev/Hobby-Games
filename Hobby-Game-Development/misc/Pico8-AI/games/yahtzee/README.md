# HIGH ROLLER — build notes

Yahtzee duel against the house, built from [yahtzee-pico8-design.md](yahtzee-pico8-design.md).

| File | What it is |
|---|---|
| `game.p8` | the cart — code in `__lua__`, all assets generated |
| `gen.js` | asset generator: sprites, SFX, music. Rewrites `__gfx__`/`__sfx__`/`__music__`, preserves `__lua__` and `__label__` |

```bash
node games/yahtzee/gen.js                                    # regenerate assets
"/c/Program Files (x86)/PICO-8/pico8.exe" -x games/yahtzee/game.p8   # headless run
node tok.js games/yahtzee/game.p8                            # ~5250 / 8192 tokens
```

Editing order matters: `gen.js` reads the cart and writes it back, so `load game.p8` in
PICO-8 after running it, and `save` in PICO-8 before running it again.

## Controls

| Where | Keys |
|---|---|
| Title | ❎ play · 🅾️ music · ⬆️⬇️ difficulty (after your first finished game) |
| Rolling | ⬅️➡️ pick a die · 🅾️ hold · ❎ roll · ⬇️ go to the score table |
| Score table | ⬆️⬇️ row · ⬅️➡️ panel · ❎ score here · 🅾️ back to the dice |

The cursor only stops on categories you can still score — filled rows are skipped when
moving and when switching panels, and their labels dim. A panel with nothing left open
refuses the switch instead of parking the cursor on a spent row.
| Anywhere | any button skips the current animation |

A turn is three presses at worst: ❎ roll, ⬇️, ❎. ⬇️ works mid-roll — it snaps the dice
down and takes you to the table. Before the turn's first roll there is no hand yet, so
the dice are drawn blank, the table shows no previews, and 🅾️ hold and ⬇️ score both
refuse with a hint rather than acting on the previous player's dice.

## Implemented

Full 13-category Yahtzee, both players every round, alternating who leads. Upper bonus at
63, extra-Yahtzee +100 (only when the box holds 50), simplified joker rule, zero-score
confirmation. Live previews and a best-move cursor. Monte-Carlo house AI (32 hold masks ×
6/12/26 samples by difficulty) run in a coroutine that yields once per mask, so its
thinking time *is* its compute time. Dice physics with bounce, squash and stagger,
particles, screen shake, count-ups, dither wipes, celebration banners. Title with attract
mode (the house plays itself after 15s idle), results screen, `cartdata` records.

Deferred from the design doc: dealer voice lines, statistics page, best-of-three, daily
seed, music ducking during celebrations. The dealer is a 16×16 portrait with four
expressions rather than 32×32, because the one-screen layout has no room for a bigger one.

## Sprite sheet

Colour 13 is the transparency key (`palt(13,true)`, `palt(0,false)`), so colour 0 is free
to outline every sprite.

| y | Contents |
|---|---|
| 0–15 | dice faces 1–6 (16×16), two tumble-blur frames |
| 16–23 | clamp, cursor, sparkle ×4, confetti ×3, dust, coin, ♠♥♦♣ |
| 24–31 | deco corner, impact rings, star, crown, ribbon, chip, arrow, mini dealer faces ×4 |
| 32–47 | dealer portraits 16×16 ×4 (neutral / smug / worried / stunned) |
| 48–63 | `HIGH ROLLER` logo |
| 64–95 | `YAHTZEE!` banner, `WIN` / `LOSE` / `TIE` word art |

## Audio

No noise waveform anywhere in the music — the swing pulse is a pitched off-beat comp on a
triangle. Noise is only used by dice sounds. SFX 0–22 are effects; 24–49 are music
instruments. Patterns: 0–1 title, 8–11 main loop, 20–21 last hand (round 12+), 24–25 win,
28–29 lose.

## Testing

Harnesses live in the scratch dir, not the repo. They append a driver to `__lua__` and
run the cart under `-x`; `_draw` never runs on its own there, so drivers capture it
(`_rd=_draw`) and call it explicitly before dumping `0x6000` to a `.p8l`, which
`shot2png.js` turns into a contact sheet.

- 36 rules assertions covering the QA checklist, all four mutants tried were caught
- full-game bot run: 12000 frames of button mashing, no desync, peak `stat(1)` 0.49
- 4 CPU-vs-CPU games average 193 per player

## Publishing

Not exported. In PICO-8: `load games/yahtzee/game.p8`, then `export highroller.p8.png`
and move it to `publish/` (see `notes.txt`).
