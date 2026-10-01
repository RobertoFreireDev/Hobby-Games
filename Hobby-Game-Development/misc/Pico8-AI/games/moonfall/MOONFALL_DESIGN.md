# MOONFALL — Game Design Document

**Genre:** social-deduction logic puzzle
**Platform:** PICO-8 (single cart, `game.p8`)
**Working title:** MOONFALL
**Pitch:** Something fed at the well last night. You have one day to walk the village, hear
eight stories, and name the one that cannot be true — before the moon rises and it feeds again.

> This folder is the design archive for the game. Per `CLAUDE.md` the cart under construction
> always lives at the repo root as `game.p8`; it moves in here (with its `labelgen.p8` and
> generator scripts) once the game is finished.

---

## 1. Pillars

1. **Everyone tells the truth except one.** Innocents never lie, never misremember, never joke.
   The single liar is the whole game. Doubt is expensive; certainty is achievable.
2. **The map is evidence.** Statements are checked against the board you are standing on.
   "The mill wheel was right beside me" is a *falsifiable claim about the 6×6 grid*.
3. **Walking costs the truth.** Every tile you cross is a statement you will not hear.
   The route is the difficulty.
4. **Never all eight.** The day is deliberately too short. You accuse on incomplete evidence,
   and the design guarantees that incomplete evidence is still enough — if you gathered the
   *right* incomplete evidence.

### Difficulty split (from the brief)

| Share | Element | Delivered by |
|---|---|---|
| **20 %** | Luck | You can hear at most 6 of 8 villagers. Which ones carry the tell is unknown at the start. Mitigated: every story carries **two or three independent tells**, so several different subsets solve it. |
| **30 %** | Planning | Landmarks are impassable. Choosing to hear the priest first pushes the gravedigger 9 tiles away. Routing *is* the resource-management layer. |
| **50 %** | Deduction | Cross-referencing eight statements against each other and against the visible grid. |

---

## 2. Fiction & cast

Last night the beast took **old wilhelm the goatherd**. He was found at one landmark — the
**attack site** — and the whole village knows where. Whoever was *really* at the attack site is
the werewolf. Nobody will admit to having been there.

Eight villagers. Any one of them can be the wolf; the role never restricts it.

| # | Name | Role | Home landmark | Hue | Voice / speech habit |
|---|---|---|---|---|---|
| 1 | **bela** | priest | chapel | 7 white | formal, short sentences |
| 2 | **mara** | herbalist | forest | 3 green | precise about time and plants |
| 3 | **otto** | miller | mill | 4 brown | sleepy, complains about the wheel |
| 4 | **vesna** | innkeeper | inn | 9 orange | gossipy, names other people freely |
| 5 | **dragan** | blacksmith | forge | 8 red | blunt, one clause where possible |
| 6 | **luka** | gravedigger | graveyard | 5 grey | grim, morbid asides |
| 7 | **iris** | widow | manor | 2 purple | mournful, indirect |
| 8 | **stefan** | watchman | watchtower | 12 blue | reports like a log entry |

Names are kept to 4–6 characters: they appear inside dialogue, in the accusation list and in the
notebook, and short names save both pixels and tokens.

> **Write all dialogue in lowercase.** PICO-8's default font renders lowercase as the small-caps
> glyph set — the classic look — and uppercase as the taller alternate set. Uppercase is reserved
> for **LANDMARK NAMES** inside statements so the player's eye finds the evidence instantly.

### Landmarks (11)

| Kind | Landmarks |
|---|---|
| Buildings (8) | CHAPEL, MILL, INN, FORGE, GRAVEYARD, MANOR, WATCHTOWER, WELL |
| Nature (3) | MOUNTAIN, FOREST, LAKE |

All 11 are **impassable**. The three nature tiles additionally **block line of sight** (see §5.3).

---

## 3. Board

- **Grid:** 6 × 6 = 36 cells, 16 × 16 px each → 96 × 96 px.
- **Screen placement:** board at `(16, 6)`, leaving a 26 px HUD bar at `y = 102..127`.
- **Occupancy each night:** 11 landmarks + 8 villagers + 1 player token = 20 cells; 16 stay empty.
- **No `__map__` section.** The board is a 36-entry Lua array drawn with `spr()`. This keeps the
  bottom half of the sprite sheet (which shares memory with the map) free for intro artwork.

### Movement

- ⬅️➡️⬆️⬇️ move the player token one cell, orthogonally only.
- Landmarks block. Villagers do **not** block — you step onto their cell to speak to them. This
  also guarantees the walk graph can never be severed by where villagers stand.
- Walking into a landmark costs no time and plays the *bump* sfx.
- 🅾️ on a villager's cell opens the conversation. ❎ opens the notebook.

### Connectivity contract

The story generator must prove, by flood fill from the player's start cell, that **every
villager cell is reachable**. A layout that fails is discarded and re-rolled. This is checked
offline when the 32 seeds are chosen (§7.4), so the cart never needs the check at runtime.

---

## 4. Time

The day runs **08:00 → 18:00** in 15-minute ticks: **40 ticks**. Nightfall at 18:00 forces the
accusation.

| Action | Cost |
|---|---|
| Move one cell | 1 tick (15 min) |
| Speak to a villager | 2 ticks (30 min) |
| Walk into a landmark | 0 |
| Open the notebook | 0 |
| Accuse | ends the day |

**Budget maths.** The average shortest path between two villager cells on a board with 11
blockers is ≈ 4–5 tiles. Hearing *n* villagers costs `2n + walk`:

| Villagers heard | Talk cost | Typical walk | Total | Fits in 40? |
|---|---|---|---|---|
| 4 | 8 | ~15 | 23 | comfortably |
| 5 | 10 | ~20 | 30 | yes |
| 6 | 12 | ~25 | 37 | **only with a good route** |
| 7 | 14 | ~31 | 45 | no |
| 8 | 16 | ~36 | 52 | no |

Six is the skill ceiling, four to five is the honest average, eight is impossible. That is the
20 % luck / 30 % planning split expressed as a number.

**Tuning knobs, in the order to reach for them:** talk cost (2), day length (40), move cost (1).
Raising the talk cost punishes greed; lengthening the day weakens the planning pillar.

### Clock

Bottom-left of the HUD bar: an **8 × 8 analogue clock face**, drawn rather than blitted —

```lua
circ(cx,cy,3,6)                             -- rim
local a=tick/40                             -- fraction of the working day
line(cx,cy,cx+2.5*cos(a),cy+2.5*sin(a),7)   -- hand
```

One sprite slot saved, and the hand sweeps smoothly. Beside it: the digital time (`13:45`) and a
sun/moon pip that swaps at 16:00. Each new hour plays the *chime* sfx and, from 15:00, darkens
the display palette one step (§9.3).

---

## 5. The deduction system

This is the game. Everything else is a delivery mechanism for it.

### 5.1 Ground truth

At generation time each villager is assigned the landmark they **actually** occupied on the
attack night. The wolf's true place is the **attack site**; no innocent is ever placed there.

### 5.2 Statement grammar

Every villager speaks **one PLACE clause and zero to two optional clauses**:

| Clause | Grammar | Checked against |
|---|---|---|
| **PLACE** *(mandatory)* | "i was at the ⟨LANDMARK⟩ all night." | every other villager's WITNESS clauses |
| **WITNESS** *(optional)* | "i saw ⟨name⟩ by the ⟨LANDMARK⟩." | that person's own PLACE clause, **and** the board geometry |
| **SIGN** *(optional)* | a sensory detail implying a geometric fact | the board directly, from one conversation |

**Innocents' clauses are all true.** The wolf's PLACE clause is always false; the wolf's optional
clauses may be true (camouflage) or fabricated (a frame).

### 5.3 Geometry predicates

Distances are **Chebyshev** on the 6×6 grid: `d = max(abs(dx), abs(dy))`.

| Predicate | Definition | Typical phrasing |
|---|---|---|
| `ADJACENT(a,b)` | orthogonal neighbours: `abs(dx)+abs(dy) == 1` | "the ⟨X⟩ was right beside me" |
| `VISIBLE(a,b)` | same row or column, no MOUNTAIN or FOREST strictly between | "i could see the ⟨X⟩ across the field" |
| `FAR(a)` | `d(a, attack site) >= 3` | "the scream came from far off" |
| `NEAR(a)` | `d(a, attack site) <= 1` | "the scream was close — i ran the other way" |

A **WITNESS clause is only generatable** when `d(speaker, subject) <= 2` or `VISIBLE(speaker,
subject)`. This matters twice over: it keeps innocents' claims plausible, and it means a wolf who
fabricates a sighting from too far away has produced a claim the player can falsify with nothing
but the board in front of them.

### 5.4 The Rule of Evidence

Shown once in the tutorial and printed in the notebook, because a deduction game is only fair if
its inference rules are published:

> **Nobody is guilty for being unvouched-for.** Only two things convict: a statement that
> **contradicts** another, or a statement the **board proves impossible**. When two people
> contradict each other, the one with independent corroboration is innocent.

Several innocents are deliberately left uncorroborated in every story. They are the red herrings,
and this rule is what makes them fair red herrings rather than coin flips.

### 5.5 Tell patterns

Every story is built around one **primary tell** and carries **one or two secondary tells**, so
that more than one conversation subset can crack it.

| Pattern | Primary tell | How the player catches it |
|---|---|---|
| **A — CONTRADICTION** | An innocent's WITNESS places the wolf at the attack site (or anywhere but where the wolf claims). | Hear both. Break the tie with the innocent's own corroborator. |
| **B — GEOMETRY** | The wolf's SIGN clause is impossible from the landmark they claim. | Hear the wolf, look at the board. One conversation. |
| **C — FRAME** | The wolf fabricates a WITNESS against an innocent, who is corroborated by a third. | Two-against-one; the fabricator is the odd one out. |
| **D — IMPOSSIBLE SIGHTING** | The wolf claims a sighting from a landmark too far from the subject to see it. | Falsified by geometry alone — the subject's own account is not even needed. |

Patterns **B** and **D** are self-contained (one conversation, plus the board). Patterns **A** and
**C** need two or three. Mixing them across the campaign is what keeps a run from degenerating
into "always go talk to the gravedigger."

---

## 6. Worked example — Night 7

**Layout 2, pattern A. Attack site: the WELL.**

```
        c1       c2       c3       c4       c5       c6
  r1 [ MTN  ] [  ..  ] [ TWR  ] [ mara ] [ FOR  ] [  ..  ]
  r2 [  ..  ] [ stef ] [  ..  ] [  ..  ] [  ..  ] [ bela ]
  r3 [ iris ] [ MAN  ] [  @@  ] [  ..  ] [ CHA  ] [ FRG  ]
  r4 [  ..  ] [  ..  ] [  ..  ] [ WELL ] [  ..  ] [ drag ]
  r5 [ LAK  ] [ MILL ] [ otto ] [  ..  ] [ luka ] [  ..  ]
  r6 [  ..  ] [  ..  ] [  ..  ] [ INN  ] [ vesn ] [ GRV  ]

  @@ = player start          UPPERCASE = impassable landmark
```

### Ground truth (hidden from the player)

| Villager | Truly at | Claims |
|---|---|---|
| bela | CHAPEL | CHAPEL |
| mara | FOREST | FOREST |
| otto | MILL | MILL |
| vesna | INN | INN |
| dragan | FORGE | FORGE |
| iris | MANOR | MANOR |
| stefan | WATCHTOWER | WATCHTOWER |
| **luka** | **WELL** ← the wolf | GRAVEYARD |

### The eight statements

| Speaker | Statement | Clauses |
|---|---|---|
| stefan | "i kept the WATCHTOWER till dawn. i saw mara go into the FOREST." | PLACE + WITNESS(mara → forest) |
| mara | "i was in the FOREST cutting nightshade. the scream came from far off." | PLACE + SIGN(FAR) |
| bela | "i prayed in the CHAPEL. i saw luka near the WELL." | PLACE + WITNESS(luka → well) |
| dragan | "i never left the FORGE. the CHAPEL bell was right beside me — bela's candles burned all night." | PLACE + SIGN(ADJACENT chapel) + WITNESS(bela → chapel) |
| vesna | "i was pouring at the INN. otto walked home past the MILL." | PLACE + WITNESS(otto → mill) |
| otto | "i slept at the MILL. i heard the water all night." | PLACE + SIGN(ADJACENT lake) |
| iris | "i sat in the MANOR. stefan's lantern was up on the WATCHTOWER." | PLACE + WITNESS(stefan → watchtower) |
| **luka** | "i was digging at the GRAVEYARD. the scream came from far off." | PLACE *(false)* + SIGN(FAR) *(false)* |

### Verification pass

- `d(forest(5,1), well(4,4)) = max(1,3) = 3` → mara's FAR holds. ✔
- `ADJACENT(forge(6,3), chapel(5,3))` → dragan's SIGN holds. ✔
- `ADJACENT(mill(2,5), lake(1,5))` → otto's SIGN holds. ✔
- `d(watchtower(3,1), forest(5,1)) = 2` → stefan may witness mara. ✔
- `d(chapel(5,3), well(4,4)) = 1` → bela may witness luka. ✔
- `d(graveyard(6,6), well(4,4)) = max(2,2) = 2` → **luka's FAR is false.** ✘

### The deduction chain

1. **Primary (A).** bela puts luka at the WELL; luka claims the GRAVEYARD. One of them lies.
2. **Tie-break.** dragan independently corroborates bela at the CHAPEL. bela is vouched for;
   luka is not. → **luka**.
3. **Secondary (B), independent route.** Talk to luka alone and read the board: the GRAVEYARD is
   two cells from the WELL. "far off" requires three. His own sentence convicts him.
4. **Red herrings.** iris, vesna and dragan have nobody vouching for their PLACE. The Rule of
   Evidence (§5.4) says that is not guilt — and the board never contradicts them.

**Solvable by:** {bela, luka} · {bela, dragan} · {luka} alone · any superset. Four routes, so a
player who spent the day in the wrong quarter of the map still has a real chance.

---

## 7. The 32 stories

### 7.1 Structure

**8 board layouts × 4 tell patterns = 32 nights.** Reusing each layout four times is deliberate:
by the fourth visit the player knows the geography and can spend their whole attention on the
logic.

### 7.2 The campaign table

Design targets. The generator/validator (§7.4) is the authority; any row it cannot satisfy is
re-rolled and this table updated to match what shipped.

| Night | Layout | Pattern | Wolf | Attack site | Tells | Min. talks |
|---|---|---|---|---|---|---|
| 1 | L1 | B | otto | MILL | 3 | 1 |
| 2 | L1 | A | vesna | INN | 3 | 2 |
| 3 | L2 | B | luka | LAKE | 3 | 1 |
| 4 | L2 | D | stefan | WATCHTOWER | 3 | 1 |
| 5 | L3 | A | mara | FOREST | 3 | 2 |
| 6 | L3 | C | bela | CHAPEL | 3 | 3 |
| 7 | L2 | A | luka | WELL | 3 | 2 |
| 8 | L4 | B | dragan | FORGE | 3 | 1 |
| 9 | L4 | D | iris | MANOR | 2 | 2 |
| 10 | L1 | C | stefan | GRAVEYARD | 2 | 3 |
| 11 | L5 | A | otto | WELL | 2 | 2 |
| 12 | L5 | B | vesna | MOUNTAIN | 2 | 2 |
| 13 | L3 | D | dragan | LAKE | 2 | 2 |
| 14 | L6 | C | mara | INN | 2 | 3 |
| 15 | L6 | A | bela | FOREST | 2 | 3 |
| 16 | L4 | C | luka | CHAPEL | 2 | 3 |
| 17 | L7 | B | iris | GRAVEYARD | 2 | 2 |
| 18 | L7 | A | stefan | MILL | 2 | 3 |
| 19 | L5 | D | bela | MANOR | 2 | 3 |
| 20 | L8 | C | otto | WATCHTOWER | 2 | 3 |
| 21 | L8 | A | dragan | WELL | 2 | 3 |
| 22 | L6 | B | luka | MOUNTAIN | 2 | 2 |
| 23 | L7 | C | vesna | FORGE | 2 | 4 |
| 24 | L1 | D | mara | LAKE | 2 | 3 |
| 25 | L8 | B | bela | INN | 2 | 3 |
| 26 | L2 | C | iris | WELL | 2 | 4 |
| 27 | L5 | C | mara | GRAVEYARD | 2 | 4 |
| 28 | L4 | A | vesna | MOUNTAIN | 2 | 4 |
| 29 | L3 | B | stefan | CHAPEL | 2 | 3 |
| 30 | L6 | D | otto | WELL | 2 | 4 |
| 31 | L8 | D | luka | FOREST | 2 | 4 |
| 32 | L7 | A | dragan | MANOR | 2 | 5 |

Difficulty rises by two levers only: **fewer independent tells** (3 → 2) and **more
conversations needed** (1 → 5). Nights 1–8 teach one pattern each; 9–24 mix them; 25–32 run at
the edge of the time budget.

### 7.3 Storage — do not store the text

Thirty-two stories × eight statements of prose is several thousand tokens. It will not fit in
8192. Two rules:

1. **Statements are assembled at runtime** from a phrase bank plus the story's structured data.
   Each clause is `(type, subject, landmark, predicate)`; the prose is built when the dialogue
   box opens.
2. **Stories are generated, not stored.** A story is a pure function of `srand(seed)`. The cart
   stores only 32 pre-validated seeds:

```lua
seeds=split"1174,2831,3042,5518,6203,7790,8117,9264,..."
```

Phrase banks are single strings run through `split()` at `_init` — one string literal is far
cheaper in tokens than a table of literals.

### 7.4 The offline validator

A Node script (`storygen.js`) mirrors the cart's generator and, for each candidate seed:

1. Builds the layout; flood-fills from the player start; **rejects** if any villager is unreachable.
2. Builds the night's ground truth and every statement.
3. **Rejects** if any innocent clause is false, or if the wolf's PLACE clause happens to be
   consistent with everything.
4. Enumerates all `C(8,k)` conversation subsets for `k = 1..6` and records which ones uniquely
   identify the wolf. **Rejects** unless a subset of size ≤ `min_talks` solves it *and* at least
   three distinct subsets of size ≤ 4 solve it.
5. Runs a shortest-path check that at least one solving subset is reachable inside 40 ticks.
6. Prints the accepted seed, the resulting layout/pattern/wolf, and a human-readable transcript.

Seeds are chosen so the accepted set matches the campaign table in §7.2. The script's transcript
output doubles as the regression fixture: re-run it after any change to the generator and diff.

---

## 8. Screens & state machine

```
  INTRO ──> MENU ──> BRIEF ──> BOARD <──> DIALOG
                                 |  \___> NOTEBOOK
                                 v
                              ACCUSE ──> VERDICT ──> (next night) BRIEF
```

### 8.1 Intro (Castlevania homage)

Non-interactive, ~10 s, skippable with any button.

1. Black. A full moon rises from the bottom of the screen, drawn as `circfill` in 7 with a 14
   halo, on a 1/13 vertical gradient sky.
2. A castle-and-village silhouette in colour 0 scrolls in from the right — parallax, with a
   nearer treeline moving at 2× — clearing the moon at frame 90.
3. A bat crosses the moon. Wolf-howl sfx.
4. The title **MOONFALL** drops in letter by letter, colour 8 with a 2 drop-shadow, over the
   moon. Subtitle "one of them is lying" fades in beneath.
5. Music: the intro theme, ending on an unresolved chord that carries into the menu.

### 8.2 Menu

Bordered panel over the intro's final frame: **PLAY** · **HOW TO PLAY** · **CLEAR PROGRESS**,
`>` cursor, ⬆️⬇️ to move, 🅾️ to pick. Under the panel: `night n / 32`, so PLAY shows what it will
resume. `menuitem()` also registers a pause-menu **clear save** entry.

### 8.3 Brief

The night report, before the day starts: "wilhelm was found at the WELL. he was cold before the
bell." The board fades in behind it. 🅾️ to begin — **the clock does not run until it is
dismissed**, so reading the board is free.

### 8.4 Board

Movement, clock, HUD. The HUD bar shows: clock face + digital time, count of villagers heard
(`3/8`), and a ❎ notebook prompt. Villagers already spoken to are drawn with a dim outline
(state via outline colour — §9.1).

### 8.5 Dialog

- **Portrait**: the villager's 16 × 16 board sprite blitted at 2× with `sspr(...,32,32)` — no
  separate portrait art, which saves 32 sprite slots and keeps board and portrait identical, so
  the player never has to learn two visual vocabularies.
- **Placement**: portrait top-right at `(88, 8)` inside a double border (outer 0, inner 5, a 7
  highlight along the top-left edge, a 6 pip at each corner) with the name plate beneath it.
- **Text**: panel from `(4, 46)` to `(124, 98)`, background 0 at 50 % dither over the board,
  bordered in 5. Word-wrapped, up to 5 lines of 22 characters, revealed at **one character per
  2 frames**.
- **Typewriter sfx**: a 2-frame blip every third revealed character, pitched by speaker (each
  villager owns a fixed base note — that is the "voice"). Skipped for spaces and punctuation.
- 🅾️ once fills the page instantly; 🅾️ again advances. Clause boundaries are page breaks.
- On close, every clause is written to the notebook automatically. **The player never has to take
  notes on paper.**

### 8.6 Notebook (❎, free)

Six pages, ⬅️➡️ flips and wraps: three of the night's records, then the three legend pages
the tutorial shows — **the village**, **the wild**, **the eight** — drawn by the same
`legend(p, y0)` the how-to screen uses. A legend the player can only reach from the title screen
is a legend they will not reach at 17:00, which is precisely when they are looking at the word
MANOR and cannot picture the tile. Six text tabs do not fit in 128px, so the page name sits at
the left and a strip of six pips at the right carries the position and the count.

The three pages share one grammar so a row never has to be decoded twice: a hue pip identifies
the speaker, `@LANDMARK` always means *where somebody was*, and dim text is context while bright
text is the thing being asserted. Rows are zebra-banded in colour 1 — eight rows of 4px text is
otherwise a single block, and colour 1 is one of the few that survives the nightfall ramp which
darkens this screen along with the rest of the game.

- **Page 1 — claims.** All eight villagers, always — not just the ones heard. Heard rows carry a
  filled pip, the name in 7, and `@LANDMARK`. Unheard rows carry an empty pip and *not heard yet*
  in 5. The blanks are the plan for the rest of the night, so the page doubles as a route sheet.
- **Page 2 — sightings.** `bela saw dragan @FOREST`. A claim that clashes with a stored PLACE is
  drawn in red **but is never labelled a lie** — the player still has to decide which side of the
  clash is lying.
- **Page 3 — details.** One villager at a time, read in full. `⬆️⬇️` walks only the
  villagers already heard — an empty entry is not worth a keypress. The
  header carries the hue swatch and the name, with a row of eight pips on the right: the one
  being read sits in a light surround, the rest are grey if heard and **indigo, and shorter**, if
  not (the nightfall ramp flattens 5 and 13 onto the same blue, so the height carries the tell
  after dusk). The pips double as the
  route sheet for the rest of the night. Beneath it, every statement that villager made — PLACE, WITNESS and
  SIGN alike — concatenated in the exact wording they used and wrapped as one body of text. No
  summary, no shorthand: the phrasing *is* the evidence, and the summary rows lost it.
- **Nothing on page 3 is verified by the notebook.** A SIGN is exactly the clause the board can
  disprove, and pattern B's whole tell *is* a false SIGN — auto-flagging would hand over the wolf.
  Walking out and looking is the game.
- **The attack site** sits under the button prompts, below the frame, on every page. It is the one
  fact every page is read against, and it is stated once rather than competing with the rows.
- Every page holds eight rows, which is the most any night can generate of either kind; the driver
  asserts that over all 32 nights, and renders each page through the engine to a png.

### 8.7 Accuse

Reachable any time from the notebook, and forced at 18:00. Portrait carousel of all eight; ⬅️➡️ to
select, 🅾️ to accuse, ❎ to back out (only before 18:00). One confirmation beat: "name them before
the moon?"

### 8.8 Verdict

- **Correct** — the accused transforms, the village takes them, the moon sets. Win sting. Night
  marked solved in `cartdata`, advance.
- **Wrong** — night falls, the screen darkens to the night palette, the howl, a blood-red flash on
  the accused's cell; then the wolf's identity is revealed **with the statement that gave them
  away highlighted**. Always show the tell: a deduction game that hides its solution teaches
  nothing.
- Either way: 🅾️ to continue, ❎ to retry the same night.

---

## 9. Art direction

The reference is 16-bit Castlevania — *Super Castlevania IV*, *Rondo of Blood* — not the 8-bit
games. What separates the two is not resolution: it is that every surface in the 16-bit games
is **lit**. Stone is sculpted, moonlight is cold, windows are warm, and shapes have volume
instead of a flat fill inside a black outline.

Four laws carry the whole look, and every one of them is enforced by the generator rather than
left to the drawing hand — which is what keeps twenty-two hand-drawn tiles looking like one
artist made them.

1. **One light, and it never moves.** The moon is up and to the left. Top and left faces are
   lit, bottom and right faces turn away, cast shadows fall down-and-right. Nothing on the
   board is lit from anywhere else, ever.
2. **No flat fills.** Every surface belongs to a *material*, and every material is a
   three-step ramp. A flat fill reads as a sticker; a ramp reads as a solid with a light on it.
3. **Warm colour is light, never a surface.** 9 and 10 belong to windows, the forge mouth, the
   watchtower brazier and the player's lantern. Timber is brown, thatch is brown, earth is
   brown. The moment a wall is painted orange, the lit window in it stops reading as lit.
4. **Black is silhouette and shadow, not linework.** Interior edges — a roof meeting a wall —
   are drawn in the material's own shadow step. Colour 0 appears in exactly three places: the
   outline around a figure, where it carries state; the contact shadow under a solid; and an
   opening that is genuinely a hole (a doorway, the mouth of the WELL).

| Use | Colours |
|---|---|
| Night ground, stone in shadow | 1 dark_blue, 13 indigo, 2 dark_purple |
| Stone, iron, slate | 6 light_gray, 5 dark_gray, 0 black |
| Wood, earth, thatch | 4 brown, 2 dark_purple, 9 orange *(lit edges only)* |
| Lamplight, windows, moon, the lantern | 10 yellow, 9 orange, 7 white, 14 pink |
| Foliage, water | 11 green, 3 dark_green, 12 blue |
| Blood, danger, accusation | 8 red |

### 9.1 Sprite rules

- **One hue per character.** Each villager owns a cloak colour (§2). It is the only saturated
  area on the sprite; everything else is stone, shadow and skin. The player reads the board by
  hue, not by silhouette detail at 16 px.
- **The cloak is a ramp, not a colour.** Law 2 applies to people too, so a villager's cloak is
  three tones, not one. The sheet paints every cloak in **placeholder indices** — 11 highlight,
  12 mid, 13 shadow — and the cart resolves them per speaker with a single `pal()` group. The
  stated hue in §2 is the **mid** tone, because that is also what the notebook prints its pips
  in.

  | Villager | Highlight | Hue (mid) | Shadow |
  |---|---|---|---|
  | bela | 7 white | **7 white** | 5 dark_gray |
  | mara | 11 green | **3 dark_green** | 1 dark_blue |
  | otto | 9 orange | **4 brown** | 2 dark_purple |
  | vesna | 10 yellow | **9 orange** | 4 brown |
  | dragan | 14 pink | **8 red** | 2 dark_purple |
  | luka | 6 light_gray | **5 dark_gray** | 1 dark_blue |
  | iris | 13 indigo | **2 dark_purple** | 1 dark_blue |
  | stefan | 6 light_gray | **12 blue** | 1 dark_blue |

- **State lives in the outline, not the fill.** A fourth placeholder, index 3, is the figure's
  outline: 0 unvisited, 5 already heard, 8 currently accused. Same sprite, one more `pal()`.
- **Figures may not contain black.** They are blitted with 0 transparent, so a literal 0 in a
  figure is a hole, not a shadow. Figure shadows bottom out at 1 or 2, and the black rim comes
  from the outline placeholder. The generator rejects a figure tile that produces 3, 11, 12 or
  13 by any route other than cloak-or-outline — otherwise a villager's hue would leak into
  their face and change with the speaker.
- **One body, eight heads.** At 16 px the read is hue plus the shape on top of the head, not
  tailoring: a mitre, a headscarf, a flat cap, pinned hair, a headband, a wide brim, a veil, a
  helmet. Distinguishing them by tailoring at this size does not work: at 16 px the cut of a
  sleeve is two pixels, and two pixels is not a character.
- **Nothing spills outside its 16 × 16 cell.** No overhanging hats, no shadows crossing into a
  neighbouring tile. Buildings included — a roof that oversteps its cell makes the grid
  unreadable, and this grid is the evidence.

### 9.2 Materials and the shader

Art is authored as **materials, not colours**: one character per pixel naming what the surface
is made of. A shader in `gen-sprites.js` then assigns the colour from the material's ramp
according to which way that pixel faces.

| Material | Lit | Flat | Turned away | Used for |
|---|---|---|---|---|
| stone | 6 | 5 | 1 | chapel, manor, watchtower, forge, well, headstones |
| slate roof | 13 | 2 | 0 | chapel, manor, well |
| timber | 4 | 2 | 1 | mill, inn, well posts, tree trunks |
| thatch | 9 | 4 | 2 | mill, inn |
| iron | 6 | 5 | 0 | mill wheel, crosses, chimney caps |
| earth | 4 | 2 | 1 | the graveyard's turned soil |
| foliage | 11 | 3 | 1 | forest |
| water | 12 | 12 | 1 | lake |
| rock | 6 | 5 | 1 | mountain |
| snow | 7 | 6 | 13 | mountain cap |
| linen | 7 | 6 | 5 | bela's mitre |
| dark cloth | 5 | 1 | 1 | hats, hoods, the player's coat |
| skin | 15 | 15 | 4 | faces |
| **cloak** | **11** | **12** | **13** | placeholders — see §9.1 |

**The shading rule.** For a pixel of material *m*:

- neighbour above **or** to the left is not *m* → it faces the moon → **lit**
- neighbour below **or** to the right is not *m* → it turns away → **shadow**
- otherwise → **flat**
- one pixel further in from a shadow edge, on a checkerboard → **shadow** as well. That dither
  is the fourth tone a 16-colour palette does not have, and it is the single most 16-bit thing
  in the pipeline.

Two consequences are worth knowing before drawing anything. An opening punched in a wall gets
a dark lintel above it and a bright sill below it for free. And a stack of tiers — a spruce, a
mansard roof, a flared tower base — separates itself into steps without a line being drawn.
Where the rule is not enough, a per-tile overlay nudges single pixels one step lighter or
darker: the mountain's ridge, the crease down a cloak, the seam of a sleeve, the dither across
the lake. That overlay is for *creases inside a surface*, which the rule cannot see, and for
nothing else.

**Two finishing passes.**

- **Lamplight.** Stone and timber orthogonally touching a lit window step one tone warmer
  (1→5, 5→9, 4→9, 2→4, 6→7). Castlevania is cold stone with warm light bleeding out of it;
  light that does not touch anything is just a yellow rectangle. This is also the reason the
  forge's mouth can stay small — the pass throws it across the whole facade.
- **Contact shadow.** Ground one pixel down-and-right of any solid takes 0, two pixels away on
  a dither. Nothing is allowed to float.

**The ground carries the grid.** Landmark tiles do not sit on a coloured backing: their
background pixels sample the ground tile at the same coordinate, so the seam between a
landmark and the cell it stands in is invisible. What *is* visible is a dotted black seam down
the right edge and along the bottom of the ground tile — which draws the 6 × 6 grid without
drawing a grid over the art. §3 says the board is evidence; evidence has to be legible, and a
player counting Chebyshev distance needs to see the cells.

### 9.3 Day → night palette ramp

The whole screen darkens as the clock runs, using the **display** palette (`pal(c,c2,1)`), so
nothing in the draw code changes:

| From | Ramp |
|---|---|
| 08:00 | identity — full daylight |
| 15:00 | 7→6, 6→5, 9→4, 15→4, 11→3 |
| 16:30 | + 6→13, 4→2, 3→1, 12→1 |
| 17:30 | + 13→1, 5→1, 2→0, 10→9 |
| 18:00 | night: everything to 0/1/2; only 8 and 7 survive |

Four loops over a packed string. Dread is a lighting change, not a text warning.

Because the ramp runs on the display palette and the cloak ramp runs on the draw palette, the
two compose without either knowing about the other: a villager's three tones darken along with
everything else, and by 18:00 the only saturated thing left on the board is blood.

### 9.4 Sprite sheet budget

A 16 × 16 entity occupies four slots (`n, n+1, n+16, n+17`); eight of them fill exactly two
sprite rows.

| Rows | Slots | Contents |
|---|---|---|
| 0–1 | 0–31 | 8 villagers — one body, eight heads |
| 2–3 | 32–63 | 8 buildings |
| 4–5 | 64–95 | mountain, forest, lake, ground, player, wolf, + 10 spare |
| 6–15 | 96–255 | unused |

Committed: 76 of 256 slots, three tile rows of art. Portraits cost nothing extra — the dialogue
box blits the villager's board sprite at 2× with `sspr` (§8.5), so board and portrait can never
disagree and the player never has to learn two visual vocabularies.

## 10. Audio

### 10.1 Music

Four day states, crossfaded with `music(n, 800)` at the clock thresholds — same key, same tempo
family, so transitions read as one piece decaying rather than four separate tracks.

| Patterns | State | Time | Character |
|---|---|---|---|
| 0–3 | **morning** | 08:00 | slow, major-ish, harp arpeggio + soft bass. Safe. |
| 4–7 | **afternoon** | 13:00 | same motif, minor third substituted; a low pulse enters. |
| 8–11 | **dusk** | 16:00 | tempo −10 %, tritone in the bass, arpeggio thins to single notes. |
| 12–15 | **nightfall** | 17:30 | dissonant, fast pulse, the motif inverted. Castlevania. |
| 16–19 | intro theme | — | the motif stated cleanly, ending unresolved |
| 20–21 | victory | — | the motif resolved at last, major |
| 22–23 | defeat | — | the motif collapsing, no resolution |

The whole soundtrack is **one melodic motif in five states**. Cheap in patterns, and it makes the
clock audible: the player hears the day rotting.

### 10.2 SFX

| # | Sound | Trigger |
|---|---|---|
| 0 | step | movement, alternating two pitches for a footfall pair |
| 1 | bump | walking into a landmark |
| 2 | talk open | dialogue box opening |
| 3 | talk close | dialogue box closing |
| 4–11 | voice blip | per-character typewriter tick, one fixed pitch each |
| 12 | page turn | notebook flip / dialogue page advance |
| 13 | menu move | cursor |
| 14 | menu confirm | selection |
| 15 | menu back | cancel |
| 16 | hour chime | every in-game hour; pitch drops as dusk approaches |
| 17 | clue logged | a clause written into the notebook |
| 18 | contradiction | first time the notebook detects a clash |
| 19 | accuse | naming a villager |
| 20 | howl | wrong accusation / intro |
| 21 | transform | the wolf revealed |
| 22 | win sting | correct accusation |
| 23 | lose sting | night falls on a wrong name |

Rule: **every input makes a sound** — movement, cancel and menu navigation included. Silence on
input reads as a dropped frame.

---

## 11. Token budget

8192 is the wall. Estimated allocation:

| System | Tokens |
|---|---|
| State machine, `_update60` / `_draw`, screen dispatch | 600 |
| Board render + palette ramp | 700 |
| Movement, landmark collision, talk trigger | 400 |
| Story generator (layout, ground truth, clause selection) | 1400 |
| Statement assembly from phrase banks | 1200 |
| Dialogue box, word wrap, typewriter | 800 |
| Notebook | 700 |
| HUD + clock | 400 |
| Accuse + verdict | 500 |
| Intro + menu + tutorial | 900 |
| Audio hooks + palette tables | 250 |
| Data (names, roles, landmarks, phrases, seeds) | 300 |
| **Total** | **~8150** |

That is uncomfortably tight. Cut candidates, in order: notebook page 2 becomes a plain list
(−250); intro parallax layer dropped (−150); phrase bank shrunk to one phrasing per clause type
(−400). Do **not** cut the validator's guarantees to save tokens — it runs offline and costs the
cart nothing.

Split `__lua__` with `-->8` into `main / board / story / dialog / data`. Free, and it keeps the
generator away from the render code.

---

## 12. Build order

1. **Cart skeleton** — title comments, state machine, empty screens. Verify with
   `pico8.exe -x game.p8`.
2. **Board + movement + clock.** Placeholder 16 × 16 blocks in flat colours. The time budget of
   §4 is validated *here*, by walking the board, before any art exists.
3. **`storygen.js`** — the offline generator and validator, complete with subset enumeration.
   Confirm 32 seeds satisfy §7.2. **This is the riskiest part of the project; do it third, not
   last.**
4. **Port the generator to Lua** and verify it reproduces the Node transcripts exactly for all 32
   seeds (`printh` both, diff).
5. **Dialogue box** — word wrap, typewriter, portrait border.
6. **Notebook, accuse, verdict.** The game is now playable and complete in placeholder art.
7. **Sprites** — villagers, buildings, nature, via `gen-sprites.js`.
8. **Audio** — sfx first (they carry the feel), then the four music states, via `audiogen.js`.
9. **Intro scene, menu, tutorial.**
10. **`labelgen.p8`** → cart label; export `moonfall.p8.png` into `publish/`.

**Playtest gate after step 6:** a player who has never seen the game should solve Night 1 without
being told the Rule of Evidence, and should fail Night 25 at least once. If they solve everything,
the tells are too loud; if they never catch a wolf, the SIGN clauses are too subtle.
