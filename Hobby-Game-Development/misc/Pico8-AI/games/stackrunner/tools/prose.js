const B='`';
const F=B+B+B;
module.exports={
head:`# LEVELS.md - the sixteen floors of Stack Runner

The design record for Stack Runner's floors: what each one is asking of the player, which pieces
it uses and in what quantity, the line a solver verified, and how far the whole run was proved.
Rebuilt from scratch on 2026-08-23 against three complaints about the previous set, all three of
which were measured before anything was changed.

## What was wrong with the old floors

**1. You could drill your way through.** Almost every verified line held a long run of the same
key - the player pressed one direction three, four, five times and the floor opened. The lines
that shipped read like this:

${F}
floor  3   >>vvv<<<<<
floor  6   >>vvv<^^^<v
floor  8   vv>>X>>>
floor 10   vvv<<Xv<v>>^^<
${F}

A run like ${B}<<<<<${B} is five separate decisions that all resolve to "press left again". It is
possible to clear a floor that way without ever understanding what the cards did, which is the
opposite of what a card-economy puzzle is for. Eleven of the sixteen shipped lines contained a run
of three or more.

**2. There was no room to be wrong.** The solver counts *trap states* - reachable positions from
which the floor can no longer be won. On the old set that number ran from 73% to 100% of the
reachable state space, and on nine floors it was above 90%. In practice the second or third press
had already decided the floor; everything after it was either the one line or a rewind.

**3. There was no single run through the game.** The floors were meant to chain - what you leave
one floor with is what you enter the next with - but the exit hauls were loose enough that
**894 different combinations** of floor solutions completed the game. The macro puzzle, choosing
what to carry, had no answer to find.

## What the rebuild targets, and how each is checked

| Goal | Rule | How it is proved |
|---|---|---|
| No drilling | No winning line near the short line may press one key 3 times in a row | every such line is enumerated and its longest run measured |
| Room to be wrong | A majority of the states you can blunder into early are still winnable | alive-state fraction inside the length of a winning line |
| More than one answer | At least 2 genuinely different routes win each floor - different squares, not just a different card order | routes counted by the sequence of cells they walk |
| One answer to the *game* | Exactly 1 combination of floor solutions completes all 16 floors | depth-first search over (floor, movement stack, item stack) |

The first rule is structural rather than lucky. Two things make long runs impossible instead of
merely unlikely: **no open straight is longer than four squares**, and the card mix leans on 2s
and 3s rather than 1s. Three presses in one direction with 2-step cards needs six squares of clear
floor, and there is nowhere on any floor to find them. A max card cannot help either - it runs
until it is blocked, so the next press in the same direction is a blocked move, which costs
nothing and changes nothing.

The fourth rule is the one that shapes the run. Each floor ends with several possible hauls, and
each floor is built so that **only one of its predecessor's hauls can win it and everything after
it**. The other exits are legal, playable, and dead: you finish the floor and the run stops later.
That is what makes the macro layer a puzzle - and why **back a level** is on the pause menu.

## The pieces

| Piece | What it does |
|---|---|
| move 1 / move 2 / move 3 | move exactly 1, 2 or 3 squares |
| move max | move until something stops you |
| crate | moves one square, and only into **empty floor** |
| door | closed blocks the square; a switch flips **every** door on the floor |
| switch (item) | flips all doors, both directions at once |
| bomb (item) | thrown one square ahead, detonates at the end of your **next** move, clears crates and guards orthogonally around it |
| guard | static: blocks its square, kills anything that **ends a move** orthogonally next to it |
| stair | landing on it wins the floor, even from inside a guard's reach |

## The five rules the layouts are built on

1. **Every move costs exactly one card, whatever its length.** Distance is nearly free; *turns*
   are what you pay for.
2. **Profit comes from picking up more than you spend.** Cards lie in short clusters rather than
   long lanes now - a lane is a straight line, and straight lines are what let you drill.
3. **Both stacks are last-in-first-out.** The card you pick up last is the one you spend next, so
   *where* a card lies dictates the route, not just how many there are.
4. **A blocked move costs nothing.** Probing is free; committing is not.
5. **Caps: five movement cards, three items.** Nobody can hoard, and the two budgets compete.

## The curriculum

| Floors | Act | What is added |
|---|---|---|
| 1-3 | movement | spending, collecting, stack order, walls as brakes |
| 4-5 | crates | push direction, one crate that gates the route, then two |
| 6-7 | guards | he punishes stopping, not passing; exact card length as survival |
| 8 | doors | one switch, every door, both directions |
| 9-10 | bombs | reach what cannot be pushed; the throw range is the kill range |
| 11-12 | the fork | choose what to carry, then live with the choice |
| 13-16 | combination | crate as brake, switch under a guard, two items in order, then all of it |

## First use of a piece is mandatory, and provable

When a piece appears for the first time, the floor cannot be finished without it. That is checked
mechanically: each intro floor is re-solved with the new piece neutralised, and has to come back
**unsolvable**. The result is printed under every floor that introduces something.

Guards get the other half of the rule instead - a hazard cannot be "required" - so on every floor
that has one, a reachable sequence of legal presses ends in a death. That is the "death reachable"
column.

## Spare items, on purpose

Every floor that needs a switch or a bomb carries a **spare**. Flipping the doors one move early,
or throwing a bomb at nothing, used to end the run outright; now it costs you the walk to fetch
the second one. This is the single biggest reason the trap numbers came down.

---
`,
tail:`## Verification

Everything above was produced by a model of the cart's rules written straight from ${B}game.p8${B} -
${B}step${B}, ${B}domove${B}, ${B}useit${B}, ${B}settle${B}, ${B}endturn${B}, ${B}boom${B} and the walk-order pickups - and then
checked against the cart itself. The model is in ${B}tools/rules.js${B}; it was validated by replaying
the *previous* level set's sixteen verified lines and reproducing every exit stack exactly.

**1. Per floor.** From the stack the floor is actually entered with, the solver builds the whole
reachable state graph (grid, position, facing, both stacks, bomb fuse) and reports the numbers in
each floor's table: distinct wins, distinct hauls out, how many of those hauls can carry the run
onward, how many reachable states are already lost, and whether a death is reachable.

**2. No drilling.** Every winning line within two presses of the shortest is enumerated and its
longest single-key run measured. The target is 2. The verified line for each floor reports its own
figure.

**3. Mandatory first use.** The control experiments, printed per floor.

**4. Full-chain winnability and uniqueness.** A depth-first search over
*(floor, movement stack, item stack)*, taking each floor's real exit hauls as the next floor's
entry stacks, counts how many complete runs exist through all sixteen floors.

**5. The cart replays it.** The sixteen lines are appended to ${B}game.p8${B} as a driver that
overrides the ${B}btnp${B} global and feeds one press per idle frame, and the real cart is run
headlessly (${B}pico8.exe -x${B}). It walks from the title screen to the win screen and prints the
stack at every floor entry, which has to match the model exactly.

## The tools

Everything used to build and check this set lives in ${B}tools/${B}:

| File | What it is |
|---|---|
| ${B}rules.js${B} | the cart's rules as a pure function - the model everything else runs on |
| ${B}analyze.js${B} | full reachable-state analysis of one floor from one entry stack |
| ${B}search.js${B} | scoring a candidate floor: routes, repetition, freedom, hauls |
| ${B}gen.js${B} | the level generator - lattice skeletons, role-placed pieces, card fill |
| ${B}floorcfg.js${B} | per-floor targets: pieces, lengths, what must be mandatory |
| ${B}build16b.js${B} | builds the whole chain, forbidding every haul but one at each step |
| ${B}chain.js${B} | counts complete runs through all sixteen floors |
| ${B}verify16.js${B} | the report above, plus ${B}chain.json${B} for the cart harness |
| ${B}harness.js${B} | writes ${B}_test.p8${B}: the real cart with a scripted-input driver |
| ${B}mapio.js${B} / ${B}apply.js${B} | read and write the ${B}__map__${B} section |
| ${B}gendoc.js${B} / ${B}prose.js${B} | regenerate this file from the level set and the stats |

To change a floor, edit its entry in ${B}floorcfg.js${B} and re-run ${B}build16b.js${B}, then
${B}verify16.js${B}, then ${B}apply.js${B}, then the harness. The numbers in this file come from
${B}stats.json${B} - regenerate it with ${B}gendoc.js${B} rather than editing tables by hand.
`,
floors:require('./prose-floors')
};
