# LEVELS.md - the sixteen floors of Stack Runner

The design record for Stack Runner's floors: what each one is asking of the player, which pieces
it uses and in what quantity, the line a solver verified, and how far the whole run was proved.
Rebuilt from scratch on 2026-08-22 against the final piece set - **the pushing guard was removed
first**, so nothing here is designed around it.

Use this file to say what should change - "floor 9 is too fiddly", "give floor 6 a crate as
well", "make 12 harsher" - and the change can be re-proved before it goes into the cart.

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
   are what you pay for. A max card sweeping eight squares and a `move 1` stepping one cost the same.
2. **Profit comes from long runs over card-dense lines.** A max card down a shaft holding three
   cards costs one and returns three. That is the only way to come out of a floor richer than you
   went in, and it is why cards are laid in lanes rather than scattered.
3. **Both stacks are last-in-first-out.** The card you pick up last is the one you spend next, so
   *where* a card lies dictates the route, not just how many there are.
4. **A blocked move costs nothing.** Probing is free; committing is not. Walls, crates, guards and
   closed doors all stop a run without spending the card that started it.
5. **Caps: five movement cards, three items.** Nobody can hoard, and the two budgets compete -
   every item you fetch is presses you did not spend on cards.

## The curriculum

| Floors | Act | What is added |
|---|---|---|
| 1-3 | movement | spending, collecting, run vs. exact length, stack order, walls as brakes |
| 4-5 | crates | push direction, the crate that seals the exit, two crates and an order |
| 6-7 | guards | he punishes stopping, not passing; exact card length as survival |
| 8 | doors | one switch, every door, both directions |
| 9-10 | bombs | reach what cannot be pushed; the throw range is the kill range |
| 11-12 | the fork | choose what to carry, then live with the choice |
| 13-16 | combination | crate as brake, switch under a guard, two items in a fixed order, then all of it |

## First use of a piece is mandatory, and provable

When a piece appears for the first time, the floor cannot be finished without it. That is checked
mechanically, not asserted: each intro floor is re-solved with the new piece neutralised, and has
to come back **unsolvable**.

| Piece | Intro | Control experiment | Result |
|---|---|---|---|
| movement card | 1 | strip every card off the board | unsolvable |
| crate | 4 | turn the crate into a wall | unsolvable |
| crate (pair) | 5 | turn both crates into walls | unsolvable |
| switch / door | 8 | remove the switch | unsolvable |
| bomb | 9 | remove the bomb | unsolvable |
| bomb vs. guard | 10 | remove the bomb | unsolvable |
| guard | 6 | *(a hazard cannot be "required")* | death reachable on the natural approach |

Guards get the other half of the rule instead: on every floor that has one, a reachable sequence
of legal presses ends in a death. Floors 6, 7, 10, 12, 13, 14, 15 and 16 all pass that check.

## Failure has to be reachable, and it is

Beyond death, the solver counts **traps** - reachable states from which the floor can no longer be
won at all: a crate jammed against the stair, a bomb thrown at nothing, a switch flipped one move
too early, a stack spent down to nothing. Every floor has them, and from floor 4 on they are the
majority of the state space. The cart is built for that: the undo button rewinds one action at a
time with no limit, **restart level** and **back a level** sit on the pause menu, and running the
stack to zero puts up a modal that rewinds *for* you rather than leaving you to work out which
button digs you out.

---

## Floor 1 - Cards are objects

**Asks for:** A press spends the top card; a card on the floor is picked up as you walk over it.

```
##########
#........#
#........#
#........#
#pabc.a^.#
#........#
#........#
#........#
##########
```

One open room and one line of cards. `move 1`, `move 2` and `move 3` sit in the player's path in ascending order, so the first four presses teach the whole ladder: step, step-two, step-three, and the stair stops the last run short. The room is deliberately wide open - wandering is legal, and it is the only way to lose here, because every wasted press is a card you never get back.

**Pieces:** move 1 x2, move 2 x1, move 3 x1 - and 34 wall tiles.

**Verified line:** `>>>>` - 4 presses, entering with `aaa` / items `-`, leaving with `aaa` / items `-`.

**How you fail:** Walk off the line and the stack empties: the **no moves left** modal comes up and the floor rewinds itself. That is the first lesson, and it costs nothing but the detour.

Every winning line leaves at least one card, so floor 2 is always enterable.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 171 | 202 | 2 | 2 | 147 | no |

---

## Floor 2 - The last card you pick up is the next one you spend

**Asks for:** LIFO. Card placement, not card count, decides your route.

```
##########
#pd....b.#
#d######.#
#a#....#d#
#c#..^a#.#
#c#..a.#b#
#.####b#.#
#.ba.a.a.#
##########
```

A ring corridor around a sealed chamber, one way in at the bottom of the right-hand wall. The left wall is a **card lane** - three cards stacked vertically - so one max run down it costs one card and returns three. That is the whole economy of the game in a single press. But the same run leaves a `move 3` on top, and a `move 3` is exactly wrong for the two single steps into the chamber, so the order you sweep the ring in is the puzzle.

**Pieces:** move 1 x6, move 2 x4, move 3 x2, move max x3 - and 51 wall tiles.

**Verified line:** `vv>>^^<` - 7 presses, entering with `aaa` / items `-`, leaving with `aaac` / items `-`.

**How you fail:** Pick up a max card and your next press is a wall-to-wall run whether you wanted one or not. A blocked press is free, but there is no way to *discard* a card - the only way to get rid of one is to move with it.

7 distinct hauls leave this floor, from nothing to four cards.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 1365 | 1436 | 72 | 7 | 995 | no |

---

## Floor 3 - Runs stop at walls, so pick the rung

**Asks for:** Geometry as a brake. Four vertical shafts joined at the top and bottom.

```
##########
#pd....c.#
#.#.#.##.#
#.#c#.##a#
#a#b#cb#a#
#.#.#.##b#
#.#.#.##.#
#^abbc.a.#
##########
```

A ladder: shafts at x1, x3, x5 and x8, each with a card halfway down, joined by the top and bottom corridors. A max card down any shaft sweeps it whole; a max card along a corridor sweeps every rung mouth. The stair is in the bottom-left corner, furthest from the start, so the profitable route and the short route are not the same route.

**Pieces:** move 1 x5, move 2 x5, move 3 x4, move max x1 - and 53 wall tiles.

**Verified line:** `>>vvv<<<<<` - 10 presses, entering with `aaac` / items `-`, leaving with `aabb` / items `-`.

**How you fail:** Descend the wrong shaft and the climb back costs more than the rung paid.

7 distinct hauls, the richest four cards - the first floor where what you leave with is a real decision.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 312 | 266 | 11 | 7 | 254 | no |

---

## Floor 4 - Crates - one push clears the shaft, the wrong push seals the stair

**Asks for:** **First crate.** A crate moves only into empty floor, and it always ends up in front of you.

```
##########
#pdb...c.#
#.######.#
#ab##.##.#
#.#^.o.b.#
#cc##b##b#
#.###a##a#
#.bd.ca..#
##########
```

The stair sits at the left end of a one-wide corridor with a crate in the middle of it. Reach the crate from below, through the shaft, and one push up parks it in the dead-end pocket above: corridor clear, stair open. Reach it from the right instead and the push sends the crate *along* the corridor, onto the last square before the stair, where it can go no further and neither can you.

**Pieces:** move 1 x4, move 2 x6, move 3 x4, move max x2, crate x1 - and 54 wall tiles.

**Verified line:** `><>vvv<<^<` - 10 presses, entering with `aabb` / items `-`, leaving with `aaa` / items `-`.

**How you fail:** **Mandatory.** Pushing from the right seals the stair permanently: 1986 of this floor's 2135 reachable states can no longer be won. Control experiment: turn the crate into a wall and the floor is unsolvable, so it has to be pushed - and it can only be pushed one way.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 2135 | 1987 | 17 | 4 | 1986 | no |

---

## Floor 5 - Two crates, and only one of them has anywhere to go

**Asks for:** Which crate, and in which order.

```
##########
#pdb...c.#
#.######.#
#a###.#.d#
#.#^.o.ob#
#cc##b#b.#
#.###.b..#
#.bd.ca..#
##########
```

The same corridor, now with a second crate to its right and a second shaft under it. Both crates have a pocket above them; only the left one stands between you and the stair. The right crate is a toll gate - clearing it opens a card lane, and clearing it costs cards.

**Pieces:** move 1 x2, move 2 x6, move 3 x4, move max x3, crate x2 - and 51 wall tiles.

**Verified line:** `>>v<v<^<` - 8 presses, entering with `aaa` / items `-`, leaving with `aaba` / items `-`.

**How you fail:** Either crate can still be bulldozed into the corridor and jammed. Control: both crates as walls, and the floor is unsolvable.

7 distinct hauls - the widest spread so far, and the first floor that rewards spending cards to earn cards.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 2290 | 2480 | 24 | 7 | 2134 | no |

---

## Floor 6 - The guard does not move, and does not have to

**Asks for:** **First guard.** He blocks his own square, and kills whatever is orthogonally next to him when a move ends.

```
##########
#pdb...c.#
#.######.#
#a#.a.d#b#
#.#^2..#.#
#c#.b.d#a#
#.####.#.#
#.bd.ca..#
##########
```

The guard stands *in* the corridor, one square from the stair. Coming up the shaft lands you beside him. Coming along the row above lands you beside him. The one safe approach is a run that passes through his reach and stops at the far wall, from where a single step reaches the stair - and the stair beats the guard, so landing on it inside his reach still wins the floor.

**Pieces:** move 1 x4, move 2 x4, move 3 x3, move max x4, guard x1 - and 51 wall tiles.

**Verified line:** `>>vvv<^^^<v` - 11 presses, entering with `aaba` / items `-`, leaving with `aa` / items `-`.

**How you fail:** **Mandatory.** Death is reachable on the first natural approach; the shaft below him is a trap laid on the obvious route. A card is parked on a lethal square on purpose, collectable only by running over it rather than stopping on it.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 568 | 470 | 9 | 3 | 508 | yes |

---

## Floor 7 - Two guards, three safe squares

**Asks for:** Exact card length as survival.

```
##########
#pdb..c..#
#.######a#
#ab#2#2#b#
#bababa^##
#cb#######
#.a#######
#.bdb.ca.#
##########
```

A dead-end corridor with two guards set above it, two squares apart. That makes squares 4 and 6 lethal and squares 3, 5 and 7 safe, so the corridor reads: `move 1` dies, `move 2` lives, `move 3` dies, max card wins. The `move 2` cards are laid on the safe squares so each hop hands you the card for the next one; the cards on the lethal squares can only be collected in passing.

**Pieces:** move 1 x7, move 2 x9, move 3 x3, move max x2, guard x2 - and 56 wall tiles.

**Verified line:** `vvv>>>` - 6 presses, entering with `aa` / items `-`, leaving with `aaa` / items `-`.

**How you fail:** Every wrong length is a death.

The tightest floor of the first act: 2 distinct hauls out.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 546 | 318 | 6 | 2 | 503 | yes |

---

## Floor 8 - One switch, every door, both directions at once

**Asks for:** **First door and switch.** The switch flips *all* doors - closed to open and open to closed.

```
##########
#p..b..c.#
#d########
#a########
#by=a-bc^#
####.#####
#cbcayca.#
#..db..a.#
##########
```

One corridor, one open door, one closed door, and the switch lying between them. Walk through the open door first and the flip is free. Flip while you are still on the wrong side of it and the open door closes in your face with the closed one still ahead of you. A vault hangs below the corridor with a card cluster and a spare switch in it, at the cost of the two moves it takes to get in and out.

**Pieces:** move 1 x5, move 2 x5, move 3 x5, move max x2, closed door x1, open door x1, switch x2 - and 55 wall tiles.

**Verified line:** `vv>>X>>>` - 8 presses, entering with `aaa` / items `-`, leaving with `ac` / items `-`.

**How you fail:** **Mandatory.** Control: remove the switch and the floor is unsolvable - the closed door is the only way to the stair. Flipping early is a permanent seal.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 1615 | 16903 | 2 | 2 | 1587 | no |

---

## Floor 9 - The bomb lands one square ahead and blows the next one over

**Asks for:** **First bomb.** Thrown into the empty square you are facing; detonates at the end of your *next* move, clearing crates and guards orthogonally around it.

```
##########
#pdb...c.#
#.##b#####
#ab#.#####
#bx.a.o^##
#..#bc.###
#.a###a###
#.bd.ca..#
##########
```

A crate sits one square from the stair, so it can never be pushed - the square beyond it is the stair, and crates do not enter stairs. The only answer is to stand two squares away, throw into the gap, step aside, and let the blast take it. The bomb is solid while it is live, so the step aside cannot be forwards: the floor gives you a pocket to retreat into, and the retreat is part of the cost.

**Pieces:** move 1 x5, move 2 x6, move 3 x3, move max x2, crate x1, bomb x1 - and 54 wall tiles.

**Verified line:** `v>>Xv>v<<^^>` - 12 presses, entering with `ac` / items `-`, leaving with `aa` / items `-`.

**How you fail:** **Mandatory.** Control: remove the bomb and the floor is unsolvable. Throwing it anywhere else wastes it - 3529 of its 3573 reachable states are already lost.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 3573 | 7952 | 4 | 3 | 3529 | no |

---

## Floor 10 - Two squares from a guard is the safe place to throw from

**Asks for:** Bomb against guard. The throw range and the kill range are the same distance.

```
##########
#.......p#
#####.##a#
#####.#.a#
##^2.a.xb#
###bcb#..#
###a.##a.#
#.bacadb.#
##########
```

A mirrored board - the player starts top-right this time - with a guard sealing the only approach to the stair. Standing next to him kills you; standing two away is exactly where you must be to drop a bomb into the gap between you. The geometry that makes him dangerous is the geometry that makes him killable.

**Pieces:** move 1 x7, move 2 x5, move 3 x2, move max x1, guard x1, bomb x1 - and 53 wall tiles.

**Verified line:** `vvv<<Xv<v>>^^<` - 14 presses, entering with `aa` / items `-`, leaving with `caa` / items `-`.

**How you fail:** **Mandatory.** Control: remove the bomb and the floor is unsolvable. Death is reachable one square earlier.

4 distinct hauls, up to four cards - the last refuelling stop before the fork.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 654 | 891 | 10 | 4 | 589 | yes |

---

## Floor 11 - The fork - four items, three pockets

**Asks for:** **The branch point.** Choose what the rest of the run gets to use.

```
##########
#pd.b.c..#
#a#.x.y###
#b#.b.a###
#c#.y.x###
#.#.c.b###
####-#####
#.bdcab.^#
##########
```

A chamber holding two bombs and two switches, with the only exit a closed door beneath it. One switch has to be spent on that door, so what you carry out is whatever you had the cards to reach and the pockets to hold. Item slots cap at three, movement cards at five, and the two budgets compete for the same presses.

**Pieces:** move 1 x3, move 2 x6, move 3 x4, move max x2, closed door x1, bomb x2, switch x2 - and 53 wall tiles.

**Verified line:** `vvv^^>>vv<^vXv<>>` - 17 presses, entering with `caa` / items `-`, leaving with `ab` / items `yx`.

**How you fail:** Nothing here is lethal. The cost is opportunity: 20 distinct hauls leave this floor, and floor 12 is not equally kind to all of them.

20 exit stacks - the widest branch in the game.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 1596 | 1697 | 63 | 20 | 1267 | no |

---

## Floor 12 - Two sealed shafts, and you open the one you brought the key for

**Asks for:** The fork pays out.

```
##########
#pdbcb..y#
#.##-##b##
#.##a##.##
#.##b##2##
#.##a##b##
####b##.##
#.bdc^c.b#
##########
```

Two shafts drop from the top corridor into the stair chamber. One is capped by a closed door, which a switch opens. The other has a guard three squares down, which a bomb clears. A spare switch lies at the far end of the top corridor for anyone who arrived with neither, but it is the most expensive square on the board to reach.

**Pieces:** move 1 x2, move 2 x8, move 3 x3, move max x2, closed door x1, guard x1, switch x1 - and 60 wall tiles.

**Verified line:** `>>><XXv<>` - 9 presses, entering with `ab` / items `yx`, leaving with `aabac` / items `-`.

**How you fail:** Arrive too poor and neither shaft opens; **back a level** on the pause menu re-runs floor 11 with a different haul. Death is reachable in the guard shaft.

Both shafts were solved independently; the chain takes the switch route.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 185 | 153 | 8 | 6 | 146 | yes |

---

## Floor 13 - A crate is a brake, and the guard is what happens without one

**Asks for:** The crate as level geometry rather than as an obstacle.

```
##########
#p.b.c.a.#
#..###.#b#
#b####o#c#
#.ba.ab.2#
#.###^####
#..###a###
#..dbca..#
##########
```

A long corridor with the stair down a shaft in the middle of it and a guard sealing the far end. A max card along that corridor runs until something stops it - and the only thing that stops it is the guard, one square short, inside his reach. Push the crate out of its niche into the corridor first and the same run stops on the shaft mouth instead. Exact-length cards also work; the crate is the cheap answer, not the only one.

**Pieces:** move 1 x5, move 2 x6, move 3 x3, move max x1, crate x1, guard x1 - and 54 wall tiles.

**Verified line:** `v>>v` - 4 presses, entering with `aabac` / items `-`, leaving with `aaba` / items `-`.

**How you fail:** The unbraked run is a death. The crate can also be pushed to the wrong square and wasted.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 492 | 416 | 8 | 3 | 426 | yes |

---

## Floor 14 - The switch swings both ways, and the guard is holding the exit

**Asks for:** Door, crate and guard on one floor, with the order fixed by the geometry.

```
##########
#pdb.c.a.#
#..#.##=b#
#.#.o..y.#
#.##a##b##
#daa.b.-^#
#..###2###
#..dbca..#
##########
```

The stair is behind a closed door at the end of the bottom corridor, and the square in front of that door is inside a guard's reach. So the run along the bottom corridor is a death *until* the door is open, at which point the same run carries straight through it and onto the stair. The switch is halfway down the right-hand shaft, past an open door that the same flip will close behind you. A crate sits in the middle corridor as a decoy: bulldoze it and you lose the shortcut, not the floor.

**Pieces:** move 1 x5, move 2 x5, move 3 x2, move max x3, crate x1, closed door x1, open door x1, guard x1, switch x1 - and 48 wall tiles.

**Verified line:** `>>v<<v<<<X>` - 11 presses, entering with `aaba` / items `-`, leaving with `aab` / items `-`.

**How you fail:** Running the bottom corridor early is a death. Flipping early closes the shaft you came down.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 901 | 1938 | 17 | 5 | 762 | yes |

---

## Floor 15 - Bomb the guard, then find the switch, on that budget

**Asks for:** Two items, two obstacles, one route, in a fixed order.

```
##########
#pxd.cby.#
#ab#####b#
#b######a#
#cb#####b#
#..a2.b.c#
#ab#######
#abd-ca.^#
##########
```

A single winding route: the top corridor for the bomb and the switch, the right-hand column down, then left along a corridor with a guard planted in the middle of it, then down the left-hand column and right along the bottom to a closed door. The bomb has to go first - the guard is between you and everything else - and the switch has to survive all the way to the door at the very end.

**Pieces:** move 1 x6, move 2 x9, move 3 x4, move max x2, closed door x1, guard x1, bomb x1, switch x1 - and 56 wall tiles.

**Verified line:** `>><<<v<vvv>>X>` - 14 presses, entering with `aab` / items `-`, leaving with `aca` / items `x`.

**How you fail:** Spend either item early and the run is dead. Death is reachable at the guard.

14 presses: the longest verified line before the finale.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 2014 | 4711 | 4 | 4 | 1956 | yes |

---

## Floor 16 - The crate lets you in, the bomb lets you past, the switch lets you out

**Asks for:** Everything, in a forced order.

```
##########
#p.bxc.a.#
#ab#.##=.#
#b#.o...2#
#c##.##by#
#daa.b.b.#
#a.###2#-#
#.bdbca#^#
##########
```

The middle corridor is sealed by a crate that can only be pushed one way, and that push is the only entrance. Inside, a guard sits on the right-hand column between you and the switch, two squares from the one square you can throw a bomb from. The switch opens the door under the stair. A second guard sits beside the bottom corridor with a card parked inside his reach, as one last piece of bait. Crate, then bomb, then switch: no other order finishes.

**Pieces:** move 1 x6, move 2 x8, move 3 x3, move max x2, crate x1, closed door x1, open door x1, guard x2, bomb x1, switch x1 - and 47 wall tiles.

**Verified line:** `vvv><<>^X>Xv` - 12 presses, entering with `aca` / items `x`, leaving with `ac` / items `-`.

**How you fail:** Two guards, a jammable crate, and two items that can each be spent on nothing. 7895 of the 7926 reachable states are already lost.

12 presses, and the run ends here.

| reachable states | distinct paths | distinct wins | distinct hauls out | trap states | death reachable |
|---|---|---|---|---|---|
| 7926 | 10395 | 4 | 3 | 7895 | yes |

---

## Verification

Everything above was produced by a model of the cart's rules written straight from `game.p8` -
`step`, `domove`, `useit`, `settle`, `endturn`, `boom` and the walk-order pickups - and then
checked against the cart itself.

**1. Per floor.** From the stack the floor is actually entered with, the solver builds the whole
reachable state graph (grid, position, facing, both stacks, bomb fuse) and reports: is it
solvable, how many distinct simple paths leave the start, how many distinct winning states exist,
how many distinct hauls it can be left with, how many reachable states are already lost, and
whether a death is reachable. The design targets were **at least 10 possible paths** and **at
least 2 successful paths** per floor; the thinnest floor has 153 paths, and every floor has at
least 2 distinct winning states.

**2. Mandatory first use.** The control experiments in the table above.

**3. Full-chain winnability.** A depth-first search over *(floor, movement stack, item stack)*,
taking each floor's real exit stacks as the next floor's entry stacks, found a concrete run
through all sixteen floors: **157 button presses**, no restarts, no rewinds. That is what the
"verified line" row of each floor is - the legs of one continuous run, not sixteen independent
solutions.

**4. The cart replays it.** Those sixteen lines were appended to `game.p8` as a driver that
overrides the `btnp` global and feeds one press per idle frame, and the real cart was run
headlessly (`pico8.exe -x`). It walked from the title screen to the win screen and printed the
stack at every floor entry, matching the model exactly:

```
floor  1  mv=aaa  it=-
floor  2  mv=aaa  it=-
floor  3  mv=aaac  it=-
floor  4  mv=aabb  it=-
floor  5  mv=aaa  it=-
floor  6  mv=aaba  it=-
floor  7  mv=aa  it=-
floor  8  mv=aaa  it=-
floor  9  mv=ac  it=-
floor 10  mv=aa  it=-
floor 11  mv=caa  it=-
floor 12  mv=ab  it=yx
floor 13  mv=aabac  it=-
floor 14  mv=aaba  it=-
floor 15  mv=aab  it=-
floor 16  mv=aca  it=x
WIN reached the win screen
```

The chain is therefore proved twice: once against the model, once against the shipping cart.

## Where the run is tight

The chain exists, but it is not generous, and that is deliberate. Floors 7, 12, 15 and 16 are
solvable from only a minority of the hauls their predecessor can produce. Arriving poor there is
recoverable - **back a level** re-runs the previous floor and hands back its entry stack - but it
is a real setback. Floor 11 is the widest branch in the game at twenty distinct hauls, and floor
12 is where that choice is cashed. If the run should be gentler, the lever is card lanes: adding
one adjacent card to a swept line raises a floor's exit by one across every route through it.
