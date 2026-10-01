# MOONFALL

A social-deduction logic puzzle for PICO-8. Something fed at the well last night. You have
one day to walk the village, hear as many of the eight villagers as the clock allows, and
name the one whose story cannot be true.

Built from [MOONFALL_DESIGN.md](MOONFALL_DESIGN.md). This file records how it was built and
where the implementation departs from the design — the design document is unchanged.

## Files

| File | What it is |
|---|---|
| `game.p8` | the cart. Lua in `__lua__`, everything else generated |
| `storygen.js` | story generator **and** offline validator. The authority on fairness |
| `SHIPPED.md` | what the validator actually accepted: layouts, 32 nights, full transcripts |
| `moonfall-data.lua` | packed story data, spliced into the cart by `build.js` |
| `gen-sprites.js` | sprite sheet: ASCII materials, shaded by rule (design §9.2) |
| `sheet-preview.js` | renders the sheet, the hued villagers and a mock board to PNG |
| `audiogen.js` | 24 sound effects and the five music states |
| `build.js` | splices data + assets into `game.p8` |
| `labelgen.p8` | draws the cart label, dumps it as hex |
| `driver.lua` / `verify.js` | the test suite, run inside real PICO-8 |
| `mutate.js` | breaks the cart ten ways and proves the suite catches each |
| `tokens.js` | approximates the PICO-8 token count |

## Building

```bash
node storygen.js --emit      # regenerate + revalidate the 32 nights
node storygen.js --selftest  # cross-check the solver against brute force
node build.js                # splice data, sprites and audio into game.p8
node verify.js               # run the cart in real PICO-8
node mutate.js               # prove the tests can fail
node tokens.js               # check the 8192-token budget
```

## What is actually proved

- **Every night is solvable, fairly.** `storygen.js` enumerates all 255 subsets of the eight
  villagers and records which ones identify the wolf uniquely. A night ships only if every
  innocent's every clause is true, the wolf's PLACE clause is false, at least two independent
  subsets solve it, at least two innocents are left deliberately uncorroborated, and the
  cheapest solving day fits inside the 40-tick clock.
- **The solver is right.** `--selftest` re-answers the same question by searching for a
  consistent assignment of night positions rather than by propagating constraints, across all
  8,160 night/subset pairs. The two agree everywhere.
- **The cart runs.** `verify.js` executes it inside real PICO-8: ~27,600 assertions over all
  32 nights' decoded data, movement, clock, reachability, sprite mapping, the palette ramp,
  and every draw path on every screen.
- **The tests can fail.** `mutate.js` breaks the cart ten ways — one break per copy — and
  every one is caught. A test suite that has never failed proves nothing; the sprite-mapping
  assertions exist because a mutant survived without them.

Regenerating the label:

```bash
"/c/Program Files (x86)/PICO-8/pico8.exe" -x labelgen.p8 > label-dump.txt 2>&1
node ../../label-tool.js label-dump.txt game.p8 label-preview.png 3
```

## Where this departs from the design

### 1. Stories are stored, not generated at runtime

§7.3 rules out storing the stories, on the grounds that 32 nights of prose will not fit in
8192 tokens. That is true of *prose*, but PICO-8 charges **one token per string literal
regardless of length**. The 32 nights pack into 2,464 characters of structured data and the
8 layouts into 288 more — two string literals, two tokens.

So the cart stores the data and `storygen.js` stays entirely offline. This deletes build
step 4 (porting the generator to Lua and diffing transcripts against Node) and with it the
whole class of bug where the two implementations drift apart. The validator is the only
implementation of the rules that exists.

Token cost came out at **~3,235 of 8,192** against the design's ~8,150 estimate.

### 2. A night cannot require more than two conversations

§7.2's campaign table asks for minimum-conversation counts rising 1 → 5. Measured
exhaustively over all 255 subsets of the eight villagers, that is not reachable — not
because of the generator, but because of the Rule of Evidence itself (§5.4). Only two things
convict, and each bottoms out fast:

- **A statement the board proves impossible** (patterns B, D) is false under *every*
  hypothesis about who the wolf is, so it eliminates all seven innocents at once. One
  conversation.
- **A contradiction** (patterns A, C) leaves exactly two suspects — the accuser and the
  accused — and one corroborating sighting settles it. Two conversations.

There is no third structure. A chain of corroborators does not extend the count, because
hearing the corroborator directly is always also a solution. The only thing that *would*
need more conversations is convicting the wolf by elimination — and §5.4 explicitly forbids
that ("nobody is guilty for being unvouched-for"), which is what keeps the red herrings fair.

Difficulty is therefore carried by the levers that do move, both of them named in the design:

- **independent tells** (§1, §5.5): how many distinct pairs of conversations crack the night.
  Nights 1–8 have 3–4; later nights have 2. Never 1 — that would make the luck pillar unfair.
- **clause depth**: three clauses per villager early, two later. Less corroboration on the
  board means fewer four-conversation days happen to stumble onto the answer.

`SHIPPED.md` records the measured numbers per night, as §7.2 asks.

### 3. Pattern C frames the victim at the attack site

As written, "the wolf fabricates a WITNESS against an innocent" collapses into pattern A: any
fabricated location is refuted by the victim's own claim, leaving a plain two-way
contradiction. The frame only works if the wolf swears the victim was **at the attack site** —
that is the one lie that makes the accused look guilty rather than merely mistaken, and it is
what leaves two suspects for a third villager to separate. Which also makes A and C mirror
images: an accusation you hear may be the truth (A) or the wolf's frame (C), and only
corroboration tells you which.

### 4. Line of sight

§2 says all three nature tiles block sight; §5.3's `VISIBLE` predicate says MOUNTAIN or
FOREST. The implementation follows §5.3, and the how-to-play screen states the rule, since
the player has to reason with it.

### 5. Smaller departures

- **Villager sprites** share one body with eight headwear variants. §9.1 now specifies this,
  along with the three-tone cloak ramp and the four placeholder indices the cart resolves.
- **Music** uses two patterns per state rather than four (§10.1) — same five states, same
  single motif, half the SFX slots.
- **Dialogue panel** starts at `(4, 50)`, not `(4, 46)` (§8.5): at 46 its top border ran
  into the bottom of the portrait box, which ends at `y = 49`. The panel keeps its height by
  extending to `y = 102`.
- **How-to-play** is five pages: two of rules — the Rule of Evidence does not fit on one
  screen at 4px — and three of legend (§6 below).

### 6. The how-to screen carries a legend

The design never says how the player learns which 16 px tile is the FORGE and which is the
MANOR. On the board that does not matter much — you walk into things — but the notebook
prints **names**, and a deduction the player cannot picture is a deduction they will not
make. So HOW TO PLAY runs five pages instead of two:

| Page | Title | What it shows |
|---|---|---|
| 1–2 | the rule of evidence | the Rule of Evidence, unchanged (§5.4) |
| 3 | the village | the eight buildings, drawn as tiles, each named |
| 4 | the wild | MOUNTAIN, FOREST, LAKE — with which of them stop sight (§5.3) — and the player token |
| 5 | the eight | the eight villagers in their own cloak hues (§9.1), each named |

⬅️➡️ wraps around; 🅾️ or ❎ returns to the menu.

The legend is drawn from the same data and the same sprites the board uses — `lmn`, `nm`,
`lmspr()`, `vpal()`, and `lmtile()`, which lays a landmark over the ground tile exactly as
`dwboard()` does. Nothing here is a second copy of the art or of the names, so a rename or a
sprite move cannot make the legend lie. Page 4 is also where the line-of-sight departure in
§4 above is stated tile by tile rather than as a sentence.

The driver renders all five pages and asserts every name fits its column: the building
names sit beside a 16 px tile in two columns 62 px apart, so WATCHTOWER at 40 px is the
widest name the layout can take.

**The notebook carries the same three legend pages.** A legend reachable only from the title
screen is a legend the player will not reach at 17:00 with four villagers left to hear — and
17:00 is exactly when they are staring at the word MANOR trying to remember which tile that
was. So ❎ now opens six pages, not three: the three records, then the village, the wild and
the eight. `legend(p, y0)` draws them, called from `dwhow()` at `y0 = 18` full-screen and from
`dwnote()` at `y0 = 14` inside the notebook frame; there is one copy of the layout, not two.
Fitting inside the frame cost the villager grid 2 px of column pitch — 32 px put "stefan" in
the last column over the border at x = 126 — so both screens now use 30 px columns. The driver
renders all six notebook pages and all five how-to pages every run.

## Not done

The **playtest gate** in §12 — a new player should solve Night 1 unaided and fail a late
night at least once — needs a human. Everything the validator can prove about fairness is
proved; whether the tells read at the right volume is not something a test can answer.
