# MOONFALL — shipped campaign

Generated and proved by `storygen.js`. Per design §7.2 the validator is the
authority; this is what actually shipped.

**Minimum conversations is not a free parameter.** Under the Rule of Evidence
(§5.4) only a contradiction or a board-impossible statement convicts, so a night
bottoms out at **1** conversation when the wolf incriminates themself (patterns
B, D) and at **2** when the tie between an accuser and the accused has to be
broken by a corroborator (patterns A, C). No arrangement of these clauses can
require 3+; difficulty is carried instead by how many independent tells a night
has and how expensive its cheapest solving route is.

## Layouts

### L1 (seed 4)

```
  r1 [TWR ] [MIL ] [ .. ] [ .. ] [ .. ] [FOR ]
  r2 [INN ] [mara] [ .. ] [ .. ] [ @@ ] [ .. ]
  r3 [WEL ] [bela] [FRG ] [iris] [ .. ] [stef]
  r4 [ .. ] [ .. ] [drag] [MTN ] [ .. ] [CHA ]
  r5 [ .. ] [LAK ] [GRV ] [ .. ] [vesn] [MAN ]
  r6 [ .. ] [ .. ] [otto] [luka] [ .. ] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

### L2 (seed 9)

```
  r1 [FOR ] [WEL ] [bela] [ .. ] [ .. ] [INN ]
  r2 [stef] [ .. ] [ .. ] [ .. ] [TWR ] [CHA ]
  r3 [ .. ] [ .. ] [ @@ ] [ .. ] [MAN ] [ .. ]
  r4 [otto] [mara] [ .. ] [luka] [drag] [ .. ]
  r5 [FRG ] [ .. ] [ .. ] [ .. ] [GRV ] [vesn]
  r6 [ .. ] [ .. ] [LAK ] [MIL ] [MTN ] [iris]

  @@ = player start   UPPERCASE = impassable landmark
```

### L3 (seed 13)

```
  r1 [ .. ] [ .. ] [ .. ] [ .. ] [mara] [FRG ]
  r2 [luka] [iris] [ .. ] [ .. ] [ .. ] [vesn]
  r3 [ .. ] [LAK ] [WEL ] [ .. ] [GRV ] [ .. ]
  r4 [drag] [ .. ] [ .. ] [MAN ] [CHA ] [bela]
  r5 [INN ] [MTN ] [ .. ] [MIL ] [ .. ] [stef]
  r6 [FOR ] [ @@ ] [ .. ] [ .. ] [otto] [TWR ]

  @@ = player start   UPPERCASE = impassable landmark
```

### L4 (seed 21)

```
  r1 [ .. ] [ .. ] [stef] [ .. ] [drag] [WEL ]
  r2 [otto] [ .. ] [ .. ] [mara] [ .. ] [MAN ]
  r3 [ .. ] [LAK ] [iris] [ .. ] [INN ] [MIL ]
  r4 [GRV ] [ .. ] [ .. ] [CHA ] [ .. ] [ .. ]
  r5 [FOR ] [bela] [ .. ] [ .. ] [ @@ ] [TWR ]
  r6 [FRG ] [ .. ] [vesn] [MTN ] [luka] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

### L5 (seed 24)

```
  r1 [MIL ] [LAK ] [drag] [ .. ] [CHA ] [otto]
  r2 [GRV ] [ @@ ] [ .. ] [ .. ] [ .. ] [ .. ]
  r3 [ .. ] [ .. ] [ .. ] [WEL ] [ .. ] [vesn]
  r4 [ .. ] [MAN ] [bela] [ .. ] [FOR ] [FRG ]
  r5 [luka] [ .. ] [TWR ] [ .. ] [iris] [ .. ]
  r6 [INN ] [stef] [ .. ] [ .. ] [mara] [MTN ]

  @@ = player start   UPPERCASE = impassable landmark
```

### L6 (seed 31)

```
  r1 [ .. ] [ .. ] [iris] [MIL ] [otto] [FRG ]
  r2 [FOR ] [LAK ] [stef] [ .. ] [ .. ] [ .. ]
  r3 [drag] [vesn] [ .. ] [ .. ] [MAN ] [bela]
  r4 [luka] [ .. ] [MTN ] [ .. ] [ .. ] [mara]
  r5 [ @@ ] [ .. ] [TWR ] [ .. ] [GRV ] [ .. ]
  r6 [ .. ] [ .. ] [WEL ] [CHA ] [INN ] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

### L7 (seed 32)

```
  r1 [ .. ] [FRG ] [ .. ] [MIL ] [MTN ] [ @@ ]
  r2 [mara] [ .. ] [ .. ] [INN ] [otto] [ .. ]
  r3 [FOR ] [ .. ] [luka] [TWR ] [ .. ] [ .. ]
  r4 [ .. ] [ .. ] [CHA ] [ .. ] [drag] [ .. ]
  r5 [ .. ] [bela] [ .. ] [vesn] [ .. ] [GRV ]
  r6 [WEL ] [iris] [stef] [MAN ] [ .. ] [LAK ]

  @@ = player start   UPPERCASE = impassable landmark
```

### L8 (seed 39)

```
  r1 [ .. ] [bela] [ .. ] [TWR ] [INN ] [WEL ]
  r2 [ .. ] [luka] [ .. ] [ .. ] [otto] [vesn]
  r3 [drag] [ .. ] [ .. ] [FOR ] [MTN ] [ .. ]
  r4 [ .. ] [ @@ ] [ .. ] [ .. ] [ .. ] [stef]
  r5 [LAK ] [FRG ] [ .. ] [iris] [MIL ] [MAN ]
  r6 [CHA ] [ .. ] [ .. ] [mara] [ .. ] [GRV ]

  @@ = player start   UPPERCASE = impassable landmark
```

## Nights

| night | layout | pattern | wolf | attack site | tells | min talks | routes<=4 | red herrings | cheapest day |
|---|---|---|---|---|---|---|---|---|---|
| 1 | L1 | B | otto | MILL | 3 | 1 | 91 | 2 | 8/40 |
| 2 | L1 | A | vesna | INN | 4 | 2 | 65 | 2 | 14/40 |
| 3 | L2 | B | luka | LAKE | 3 | 1 | 91 | 2 | 4/40 |
| 4 | L2 | D | stefan | WATCHTOWER | 3 | 1 | 91 | 2 | 5/40 |
| 5 | L3 | A | mara | FOREST | 4 | 2 | 65 | 2 | 16/40 |
| 6 | L3 | C | bela | CHAPEL | 4 | 2 | 65 | 2 | 16/40 |
| 7 | L2 | A | luka | WELL | 4 | 2 | 65 | 2 | 11/40 |
| 8 | L4 | B | dragan | FORGE | 3 | 1 | 91 | 2 | 10/40 |
| 9 | L4 | D | iris | MANOR | 2 | 1 | 80 | 2 | 6/40 |
| 10 | L1 | C | stefan | GRAVEYARD | 3 | 2 | 54 | 2 | 12/40 |
| 11 | L5 | A | otto | WELL | 3 | 2 | 54 | 2 | 13/40 |
| 12 | L5 | B | vesna | MOUNTAIN | 2 | 1 | 80 | 2 | 7/40 |
| 13 | L3 | D | dragan | LAKE | 2 | 1 | 80 | 2 | 7/40 |
| 14 | L6 | C | mara | INN | 3 | 2 | 54 | 2 | 13/40 |
| 15 | L6 | A | bela | FOREST | 3 | 2 | 54 | 2 | 10/40 |
| 16 | L4 | C | luka | CHAPEL | 3 | 2 | 54 | 2 | 12/40 |
| 17 | L7 | B | iris | GRAVEYARD | 2 | 1 | 80 | 2 | 11/40 |
| 18 | L7 | A | stefan | MILL | 3 | 2 | 54 | 2 | 15/40 |
| 19 | L5 | D | bela | MANOR | 2 | 1 | 80 | 2 | 5/40 |
| 20 | L8 | C | otto | WATCHTOWER | 3 | 2 | 54 | 2 | 11/40 |
| 21 | L8 | A | dragan | WELL | 3 | 2 | 54 | 2 | 11/40 |
| 22 | L6 | B | luka | MOUNTAIN | 2 | 1 | 80 | 2 | 3/40 |
| 23 | L7 | C | vesna | FORGE | 3 | 2 | 54 | 2 | 13/40 |
| 24 | L1 | D | mara | LAKE | 2 | 1 | 80 | 2 | 5/40 |
| 25 | L8 | B | bela | INN | 2 | 1 | 80 | 2 | 5/40 |
| 26 | L2 | C | iris | WELL | 3 | 2 | 54 | 2 | 10/40 |
| 27 | L5 | C | mara | GRAVEYARD | 3 | 2 | 54 | 2 | 19/40 |
| 28 | L4 | A | vesna | MOUNTAIN | 3 | 2 | 54 | 2 | 13/40 |
| 29 | L3 | B | stefan | CHAPEL | 2 | 1 | 80 | 2 | 7/40 |
| 30 | L6 | D | otto | WELL | 2 | 1 | 80 | 2 | 10/40 |
| 31 | L8 | D | luka | FOREST | 2 | 1 | 80 | 2 | 4/40 |
| 32 | L7 | A | dragan | MANOR | 3 | 2 | 54 | 2 | 17/40 |

## Transcripts

### Night 1 — L1, pattern B, wolf **otto**, attack site MILL

```
  r1 [TWR ] [MIL ] [ .. ] [ .. ] [ .. ] [FOR ]
  r2 [INN ] [mara] [ .. ] [ .. ] [ @@ ] [ .. ]
  r3 [WEL ] [bela] [FRG ] [iris] [ .. ] [stef]
  r4 [ .. ] [ .. ] [drag] [MTN ] [ .. ] [CHA ]
  r5 [ .. ] [LAK ] [GRV ] [ .. ] [vesn] [MAN ]
  r6 [ .. ] [ .. ] [otto] [luka] [ .. ] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the MANOR all night. dragan was at the FOREST. i saw them. the scream came from far off."
- **mara** — "i was at the GRAVEYARD from dusk to dawn. i passed stefan by the LAKE, near midnight. the FORGE was in plain view."
- **otto** *(wolf)* — "i was down at the INN, half asleep. the MOUNTAIN was at my shoulder all night. luka went past the WELL, i think."
- **vesna** — "oh, i was over at the WATCHTOWER all evening. i had a clear line to the FOREST. and dragan! over at the FOREST, plain as day."
- **dragan** — "the FOREST. all night. the scream came from far off. vesna was at the WATCHTOWER."
- **luka** — "i was out at the WELL, where else. i could have touched the INN. iris was by the FORGE. i saw that much."
- **iris** — "i stayed near the FORGE, as i always do. poor stefan was out by the LAKE. nothing stood between me and the WELL."
- **stefan** — "post: the LAKE, dusk to dawn. sighting: otto, at the MILL. i had a clear line to the GRAVEYARD."

solvable by: {otto} · {mara, stefan} · {iris, stefan}  (cheapest day 8 ticks)

### Night 2 — L1, pattern A, wolf **vesna**, attack site INN

```
  r1 [TWR ] [MIL ] [ .. ] [ .. ] [ .. ] [FOR ]
  r2 [INN ] [mara] [ .. ] [ .. ] [ @@ ] [ .. ]
  r3 [WEL ] [bela] [FRG ] [iris] [ .. ] [stef]
  r4 [ .. ] [ .. ] [drag] [MTN ] [ .. ] [CHA ]
  r5 [ .. ] [LAK ] [GRV ] [ .. ] [vesn] [MAN ]
  r6 [ .. ] [ .. ] [otto] [luka] [ .. ] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the FORGE all night. luka was at the WELL. i saw them. i could see the WELL across the field."
- **mara** — "i was at the GRAVEYARD from dusk to dawn. i passed luka by the WELL, near midnight. i could have touched the LAKE."
- **otto** — "i was down at the MANOR, half asleep. the CHAPEL was at my shoulder all night. stefan went past the FOREST, i think."
- **vesna** *(wolf)* — "oh, i was over at the MOUNTAIN all evening. i had a clear line to the CHAPEL. and iris! over at the CHAPEL, plain as day."
- **dragan** — "the MILL. all night. vesna was at the INN. i could see the WATCHTOWER across the field."
- **luka** — "i was out at the WELL, where else. vesna was by the INN. i saw that much. the WATCHTOWER was in plain view."
- **iris** — "i stayed near the CHAPEL, as i always do. poor otto was out by the MANOR. the MANOR was at my shoulder all night."
- **stefan** — "post: the FOREST, dusk to dawn. sighting: dragan, at the MILL. i had a clear line to the CHAPEL."

solvable by: {bela, luka} · {mara, luka} · {dragan, luka} · {dragan, stefan}  (cheapest day 14 ticks)

### Night 3 — L2, pattern B, wolf **luka**, attack site LAKE

```
  r1 [FOR ] [WEL ] [bela] [ .. ] [ .. ] [INN ]
  r2 [stef] [ .. ] [ .. ] [ .. ] [TWR ] [CHA ]
  r3 [ .. ] [ .. ] [ @@ ] [ .. ] [MAN ] [ .. ]
  r4 [otto] [mara] [ .. ] [luka] [drag] [ .. ]
  r5 [FRG ] [ .. ] [ .. ] [ .. ] [GRV ] [vesn]
  r6 [ .. ] [ .. ] [LAK ] [MIL ] [MTN ] [iris]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the CHAPEL all night. the INN stood right beside me. mara was at the WATCHTOWER. i saw them."
- **mara** — "i was at the WATCHTOWER from dusk to dawn. i passed dragan by the MOUNTAIN, near midnight. i could have touched the CHAPEL."
- **otto** — "i was down at the FORGE, half asleep. nothing stood between me and the FOREST. vesna went past the FOREST, i think."
- **vesna** — "oh, i was over at the FOREST all evening. and otto! over at the FORGE, plain as day. i had a clear line to the WELL."
- **dragan** — "the MOUNTAIN. all night. luka was at the LAKE. i could see the MILL across the field."
- **luka** *(wolf)* — "i was out at the MANOR, where else. the WELL was in plain view. dragan was by the MOUNTAIN. i saw that much."
- **iris** — "i stayed near the MILL, as i always do. the MOUNTAIN was at my shoulder all night. poor dragan was out by the MOUNTAIN."
- **stefan** — "post: the INN, dusk to dawn. i had a clear line to the WELL. sighting: bela, at the CHAPEL."

solvable by: {mara, dragan} · {luka} · {dragan, iris}  (cheapest day 4 ticks)

### Night 4 — L2, pattern D, wolf **stefan**, attack site WATCHTOWER

```
  r1 [FOR ] [WEL ] [bela] [ .. ] [ .. ] [INN ]
  r2 [stef] [ .. ] [ .. ] [ .. ] [TWR ] [CHA ]
  r3 [ .. ] [ .. ] [ @@ ] [ .. ] [MAN ] [ .. ]
  r4 [otto] [mara] [ .. ] [luka] [drag] [ .. ]
  r5 [FRG ] [ .. ] [ .. ] [ .. ] [GRV ] [vesn]
  r6 [ .. ] [ .. ] [LAK ] [MIL ] [MTN ] [iris]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the CHAPEL all night. the WATCHTOWER stood right beside me. vesna was at the INN. i saw them."
- **mara** — "i was at the MANOR from dusk to dawn. i passed iris by the MOUNTAIN, near midnight. the GRAVEYARD was in plain view."
- **otto** — "i was down at the FORGE, half asleep. whatever screamed, it was distant. dragan went past the FOREST, i think."
- **vesna** — "oh, i was over at the INN all evening. and bela! over at the CHAPEL, plain as day. i had a clear line to the WELL."
- **dragan** — "the FOREST. all night. i could see the INN across the field. otto was at the FORGE."
- **luka** — "i was out at the MILL, where else. the LAKE was in plain view. iris was by the MOUNTAIN. i saw that much."
- **iris** — "i stayed near the MOUNTAIN, as i always do. poor stefan was out by the WATCHTOWER. nothing stood between me and the LAKE."
- **stefan** *(wolf)* — "post: the GRAVEYARD, dusk to dawn. sighting: bela, at the CHAPEL. i had a clear line to the MANOR."

solvable by: {mara, iris} · {luka, iris} · {stefan}  (cheapest day 5 ticks)

### Night 5 — L3, pattern A, wolf **mara**, attack site FOREST

```
  r1 [ .. ] [ .. ] [ .. ] [ .. ] [mara] [FRG ]
  r2 [luka] [iris] [ .. ] [ .. ] [ .. ] [vesn]
  r3 [ .. ] [LAK ] [WEL ] [ .. ] [GRV ] [ .. ]
  r4 [drag] [ .. ] [ .. ] [MAN ] [CHA ] [bela]
  r5 [INN ] [MTN ] [ .. ] [MIL ] [ .. ] [stef]
  r6 [FOR ] [ @@ ] [ .. ] [ .. ] [otto] [TWR ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the LAKE all night. dragan was at the INN. i saw them. the scream came from far off."
- **mara** *(wolf)* — "i was at the WELL from dusk to dawn. i passed otto by the MILL, near midnight. i could have touched the LAKE."
- **otto** — "i was down at the MILL, half asleep. iris went past the MANOR, i think. nothing stood between me and the MANOR."
- **vesna** — "oh, i was over at the GRAVEYARD all evening. and luka! over at the FORGE, plain as day. i had a clear line to the CHAPEL."
- **dragan** — "the INN. all night. mara was at the FOREST. the scream was close. i ran the other way."
- **luka** — "i was out at the FORGE, where else. stefan was by the WATCHTOWER. i saw that much. the cry was a long way away."
- **iris** — "i stayed near the MANOR, as i always do. poor stefan was out by the WATCHTOWER. the MILL was at my shoulder all night."
- **stefan** — "post: the WATCHTOWER, dusk to dawn. sighting: mara, at the FOREST. i heard it faint, from far off."

solvable by: {bela, dragan} · {dragan, stefan} · {luka, stefan} · {iris, stefan}  (cheapest day 16 ticks)

### Night 6 — L3, pattern C, wolf **bela**, attack site CHAPEL

```
  r1 [ .. ] [ .. ] [ .. ] [ .. ] [mara] [FRG ]
  r2 [luka] [iris] [ .. ] [ .. ] [ .. ] [vesn]
  r3 [ .. ] [LAK ] [WEL ] [ .. ] [GRV ] [ .. ]
  r4 [drag] [ .. ] [ .. ] [MAN ] [CHA ] [bela]
  r5 [INN ] [MTN ] [ .. ] [MIL ] [ .. ] [stef]
  r6 [FOR ] [ @@ ] [ .. ] [ .. ] [otto] [TWR ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** *(wolf)* — "i was at the MILL all night. otto was at the CHAPEL. i saw them. i could see the MANOR across the field."
- **mara** — "i was at the WATCHTOWER from dusk to dawn. the FOREST was in plain view. i passed luka by the FOREST, near midnight."
- **otto** — "i was down at the INN, half asleep. nothing stood between me and the FOREST. stefan went past the MOUNTAIN, i think."
- **vesna** — "oh, i was over at the FORGE all evening. and dragan! over at the GRAVEYARD, plain as day. i had a clear line to the WATCHTOWER."
- **dragan** — "the GRAVEYARD. all night. bela was at the CHAPEL. i could see the LAKE across the field."
- **luka** — "i was out at the FOREST, where else. otto was by the INN. i saw that much. the cry was a long way away."
- **iris** — "i stayed near the WELL, as i always do. poor otto was out by the INN. nothing stood between me and the GRAVEYARD."
- **stefan** — "post: the MOUNTAIN, dusk to dawn. i had a clear line to the MILL. sighting: iris, at the WELL."

solvable by: {bela, dragan} · {vesna, dragan} · {bela, luka} · {bela, iris}  (cheapest day 16 ticks)

### Night 7 — L2, pattern A, wolf **luka**, attack site WELL

```
  r1 [FOR ] [WEL ] [bela] [ .. ] [ .. ] [INN ]
  r2 [stef] [ .. ] [ .. ] [ .. ] [TWR ] [CHA ]
  r3 [ .. ] [ .. ] [ @@ ] [ .. ] [MAN ] [ .. ]
  r4 [otto] [mara] [ .. ] [luka] [drag] [ .. ]
  r5 [FRG ] [ .. ] [ .. ] [ .. ] [GRV ] [vesn]
  r6 [ .. ] [ .. ] [LAK ] [MIL ] [MTN ] [iris]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the INN all night. luka was at the WELL. i saw them. i could see the FOREST across the field."
- **mara** — "i was at the FORGE from dusk to dawn. i passed vesna by the FOREST, near midnight. the GRAVEYARD was in plain view."
- **otto** — "i was down at the MANOR, half asleep. bela went past the INN, i think. whatever screamed, it was distant."
- **vesna** — "oh, i was over at the FOREST all evening. and luka! over at the WELL, plain as day. i had a clear line to the WELL."
- **dragan** — "the CHAPEL. all night. bela was at the INN. the INN stood right beside me."
- **luka** *(wolf)* — "i was out at the GRAVEYARD, where else. the MANOR was in plain view. mara was by the FORGE. i saw that much."
- **iris** — "i stayed near the MOUNTAIN, as i always do. poor stefan was out by the LAKE. the GRAVEYARD was at my shoulder all night."
- **stefan** — "post: the LAKE, dusk to dawn. i had a clear line to the MILL. sighting: iris, at the MOUNTAIN."

solvable by: {bela, otto} · {bela, vesna} · {mara, vesna} · {bela, dragan}  (cheapest day 11 ticks)

### Night 8 — L4, pattern B, wolf **dragan**, attack site FORGE

```
  r1 [ .. ] [ .. ] [stef] [ .. ] [drag] [WEL ]
  r2 [otto] [ .. ] [ .. ] [mara] [ .. ] [MAN ]
  r3 [ .. ] [LAK ] [iris] [ .. ] [INN ] [MIL ]
  r4 [GRV ] [ .. ] [ .. ] [CHA ] [ .. ] [ .. ]
  r5 [FOR ] [bela] [ .. ] [ .. ] [ @@ ] [TWR ]
  r6 [FRG ] [ .. ] [vesn] [MTN ] [luka] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the FOREST all night. dragan was at the FORGE. i saw them. i could see the FORGE across the field."
- **mara** — "i was at the WELL from dusk to dawn. i passed stefan by the WATCHTOWER, near midnight. the cry was a long way away."
- **otto** — "i was down at the GRAVEYARD, half asleep. bela went past the FOREST, i think. nothing stood between me and the FOREST."
- **vesna** — "oh, i was over at the LAKE all evening. and otto! over at the GRAVEYARD, plain as day. i had a clear line to the INN."
- **dragan** *(wolf)* — "the INN. all night. the scream was close. i ran the other way. iris was at the MILL."
- **luka** — "i was out at the MANOR, where else. stefan was by the WATCHTOWER. i saw that much. i could have touched the WELL."
- **iris** — "i stayed near the MILL, as i always do. whatever screamed, it was distant. poor luka was out by the MANOR."
- **stefan** — "post: the WATCHTOWER, dusk to dawn. sighting: bela, at the FOREST. i had a clear line to the MILL."

solvable by: {bela, otto} · {dragan} · {bela, stefan}  (cheapest day 10 ticks)

### Night 9 — L4, pattern D, wolf **iris**, attack site MANOR

```
  r1 [ .. ] [ .. ] [stef] [ .. ] [drag] [WEL ]
  r2 [otto] [ .. ] [ .. ] [mara] [ .. ] [MAN ]
  r3 [ .. ] [LAK ] [iris] [ .. ] [INN ] [MIL ]
  r4 [GRV ] [ .. ] [ .. ] [CHA ] [ .. ] [ .. ]
  r5 [FOR ] [bela] [ .. ] [ .. ] [ @@ ] [TWR ]
  r6 [FRG ] [ .. ] [vesn] [MTN ] [luka] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the FORGE all night. the FOREST stood right beside me."
- **mara** — "i was at the GRAVEYARD from dusk to dawn. i passed luka by the CHAPEL, near midnight."
- **otto** — "i was down at the WELL, half asleep. iris went past the MANOR, i think."
- **vesna** — "oh, i was over at the FOREST all evening. and dragan! over at the WATCHTOWER, plain as day."
- **dragan** — "the WATCHTOWER. all night. otto was at the WELL."
- **luka** — "i was out at the CHAPEL, where else. mara was by the GRAVEYARD. i saw that much."
- **iris** *(wolf)* — "i stayed near the INN, as i always do. poor vesna was out by the FOREST."
- **stefan** — "post: the MOUNTAIN, dusk to dawn. i had a clear line to the FORGE."

solvable by: {otto, dragan} · {iris}  (cheapest day 6 ticks)

### Night 10 — L1, pattern C, wolf **stefan**, attack site GRAVEYARD

```
  r1 [TWR ] [MIL ] [ .. ] [ .. ] [ .. ] [FOR ]
  r2 [INN ] [mara] [ .. ] [ .. ] [ @@ ] [ .. ]
  r3 [WEL ] [bela] [FRG ] [iris] [ .. ] [stef]
  r4 [ .. ] [ .. ] [drag] [MTN ] [ .. ] [CHA ]
  r5 [ .. ] [LAK ] [GRV ] [ .. ] [vesn] [MAN ]
  r6 [ .. ] [ .. ] [otto] [luka] [ .. ] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the FORGE all night. stefan was at the GRAVEYARD. i saw them."
- **mara** — "i was at the WELL from dusk to dawn. i passed luka by the INN, near midnight."
- **otto** — "i was down at the MILL, half asleep. bela went past the FORGE, i think."
- **vesna** — "oh, i was over at the CHAPEL all evening. and iris! over at the FOREST, plain as day."
- **dragan** — "the LAKE. all night. mara was at the WELL."
- **luka** — "i was out at the INN, where else. the WATCHTOWER was in plain view."
- **iris** — "i stayed near the FOREST, as i always do. poor otto was out by the MILL."
- **stefan** *(wolf)* — "post: the MOUNTAIN, dusk to dawn. sighting: mara, at the GRAVEYARD."

solvable by: {bela, otto} · {bela, stefan} · {dragan, stefan}  (cheapest day 12 ticks)

### Night 11 — L5, pattern A, wolf **otto**, attack site WELL

```
  r1 [MIL ] [LAK ] [drag] [ .. ] [CHA ] [otto]
  r2 [GRV ] [ @@ ] [ .. ] [ .. ] [ .. ] [ .. ]
  r3 [ .. ] [ .. ] [ .. ] [WEL ] [ .. ] [vesn]
  r4 [ .. ] [MAN ] [bela] [ .. ] [FOR ] [FRG ]
  r5 [luka] [ .. ] [TWR ] [ .. ] [iris] [ .. ]
  r6 [INN ] [stef] [ .. ] [ .. ] [mara] [MTN ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the MOUNTAIN all night. stefan was at the INN. i saw them."
- **mara** — "i was at the FOREST from dusk to dawn. i passed luka by the WATCHTOWER, near midnight."
- **otto** *(wolf)* — "i was down at the CHAPEL, half asleep. mara went past the FOREST, i think."
- **vesna** — "oh, i was over at the MANOR all evening. and otto! over at the WELL, plain as day."
- **dragan** — "the FORGE. all night. bela was at the MOUNTAIN."
- **luka** — "i was out at the WATCHTOWER, where else. otto was by the WELL. i saw that much."
- **iris** — "i stayed near the MILL, as i always do. poor stefan was out by the INN."
- **stefan** — "post: the INN, dusk to dawn. sighting: vesna, at the MANOR."

solvable by: {mara, luka} · {vesna, luka} · {vesna, stefan}  (cheapest day 13 ticks)

### Night 12 — L5, pattern B, wolf **vesna**, attack site MOUNTAIN

```
  r1 [MIL ] [LAK ] [drag] [ .. ] [CHA ] [otto]
  r2 [GRV ] [ @@ ] [ .. ] [ .. ] [ .. ] [ .. ]
  r3 [ .. ] [ .. ] [ .. ] [WEL ] [ .. ] [vesn]
  r4 [ .. ] [MAN ] [bela] [ .. ] [FOR ] [FRG ]
  r5 [luka] [ .. ] [TWR ] [ .. ] [iris] [ .. ]
  r6 [INN ] [stef] [ .. ] [ .. ] [mara] [MTN ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the WELL all night. otto was at the FORGE. i saw them."
- **mara** — "i was at the LAKE from dusk to dawn. i passed stefan by the CHAPEL, near midnight."
- **otto** — "i was down at the FORGE, half asleep. vesna went past the MOUNTAIN, i think."
- **vesna** *(wolf)* — "oh, i was over at the MILL all evening. i had a clear line to the WATCHTOWER."
- **dragan** — "the INN. all night. luka was at the MANOR."
- **luka** — "i was out at the MANOR, where else. iris was by the WATCHTOWER. i saw that much."
- **iris** — "i stayed near the WATCHTOWER, as i always do. poor bela was out by the WELL."
- **stefan** — "post: the CHAPEL, dusk to dawn. i had a clear line to the MILL."

solvable by: {bela, otto} · {vesna}  (cheapest day 7 ticks)

### Night 13 — L3, pattern D, wolf **dragan**, attack site LAKE

```
  r1 [ .. ] [ .. ] [ .. ] [ .. ] [mara] [FRG ]
  r2 [luka] [iris] [ .. ] [ .. ] [ .. ] [vesn]
  r3 [ .. ] [LAK ] [WEL ] [ .. ] [GRV ] [ .. ]
  r4 [drag] [ .. ] [ .. ] [MAN ] [CHA ] [bela]
  r5 [INN ] [MTN ] [ .. ] [MIL ] [ .. ] [stef]
  r6 [FOR ] [ @@ ] [ .. ] [ .. ] [otto] [TWR ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the CHAPEL all night. i could see the GRAVEYARD across the field."
- **mara** — "i was at the GRAVEYARD from dusk to dawn. the WELL was in plain view."
- **otto** — "i was down at the MANOR, half asleep. dragan went past the LAKE, i think."
- **vesna** — "oh, i was over at the WELL all evening. and otto! over at the MANOR, plain as day."
- **dragan** *(wolf)* — "the INN. all night. luka was at the FORGE."
- **luka** — "i was out at the FORGE, where else. mara was by the GRAVEYARD. i saw that much."
- **iris** — "i stayed near the WATCHTOWER, as i always do. poor stefan was out by the MILL."
- **stefan** — "post: the MILL, dusk to dawn. sighting: vesna, at the WELL."

solvable by: {otto, vesna} · {dragan}  (cheapest day 7 ticks)

### Night 14 — L6, pattern C, wolf **mara**, attack site INN

```
  r1 [ .. ] [ .. ] [iris] [MIL ] [otto] [FRG ]
  r2 [FOR ] [LAK ] [stef] [ .. ] [ .. ] [ .. ]
  r3 [drag] [vesn] [ .. ] [ .. ] [MAN ] [bela]
  r4 [luka] [ .. ] [MTN ] [ .. ] [ .. ] [mara]
  r5 [ @@ ] [ .. ] [TWR ] [ .. ] [GRV ] [ .. ]
  r6 [ .. ] [ .. ] [WEL ] [CHA ] [INN ] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the CHAPEL all night. mara was at the INN. i saw them."
- **mara** *(wolf)* — "i was at the WELL from dusk to dawn. i passed dragan by the INN, near midnight."
- **otto** — "i was down at the MOUNTAIN, half asleep. bela went past the CHAPEL, i think."
- **vesna** — "oh, i was over at the GRAVEYARD all evening. and luka! over at the MANOR, plain as day."
- **dragan** — "the LAKE. all night. otto was at the MOUNTAIN."
- **luka** — "i was out at the MANOR, where else. vesna was by the GRAVEYARD. i saw that much."
- **iris** — "i stayed near the FORGE, as i always do. whatever screamed, it was distant."
- **stefan** — "post: the FOREST, dusk to dawn. sighting: dragan, at the LAKE."

solvable by: {bela, mara} · {bela, otto} · {mara, stefan}  (cheapest day 13 ticks)

### Night 15 — L6, pattern A, wolf **bela**, attack site FOREST

```
  r1 [ .. ] [ .. ] [iris] [MIL ] [otto] [FRG ]
  r2 [FOR ] [LAK ] [stef] [ .. ] [ .. ] [ .. ]
  r3 [drag] [vesn] [ .. ] [ .. ] [MAN ] [bela]
  r4 [luka] [ .. ] [MTN ] [ .. ] [ .. ] [mara]
  r5 [ @@ ] [ .. ] [TWR ] [ .. ] [GRV ] [ .. ]
  r6 [ .. ] [ .. ] [WEL ] [CHA ] [INN ] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** *(wolf)* — "i was at the WATCHTOWER all night. vesna was at the WELL. i saw them."
- **mara** — "i was at the CHAPEL from dusk to dawn. i could have touched the INN."
- **otto** — "i was down at the MOUNTAIN, half asleep. bela went past the FOREST, i think."
- **vesna** — "oh, i was over at the WELL all evening. and otto! over at the MOUNTAIN, plain as day."
- **dragan** — "the LAKE. all night. bela was at the FOREST."
- **luka** — "i was out at the FORGE, where else. iris was by the MILL. i saw that much."
- **iris** — "i stayed near the MILL, as i always do. poor dragan was out by the LAKE."
- **stefan** — "post: the GRAVEYARD, dusk to dawn. sighting: mara, at the CHAPEL."

solvable by: {otto, vesna} · {otto, dragan} · {dragan, iris}  (cheapest day 10 ticks)

### Night 16 — L4, pattern C, wolf **luka**, attack site CHAPEL

```
  r1 [ .. ] [ .. ] [stef] [ .. ] [drag] [WEL ]
  r2 [otto] [ .. ] [ .. ] [mara] [ .. ] [MAN ]
  r3 [ .. ] [LAK ] [iris] [ .. ] [INN ] [MIL ]
  r4 [GRV ] [ .. ] [ .. ] [CHA ] [ .. ] [ .. ]
  r5 [FOR ] [bela] [ .. ] [ .. ] [ @@ ] [TWR ]
  r6 [FRG ] [ .. ] [vesn] [MTN ] [luka] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the FORGE all night. dragan was at the MOUNTAIN. i saw them."
- **mara** — "i was at the INN from dusk to dawn. i passed vesna by the LAKE, near midnight."
- **otto** — "i was down at the GRAVEYARD, half asleep. bela went past the FORGE, i think."
- **vesna** — "oh, i was over at the LAKE all evening. and mara! over at the INN, plain as day."
- **dragan** — "the MOUNTAIN. all night. luka was at the CHAPEL."
- **luka** *(wolf)* — "i was out at the MILL, where else. vesna was by the CHAPEL. i saw that much."
- **iris** — "i stayed near the WELL, as i always do. poor stefan was out by the WATCHTOWER."
- **stefan** — "post: the WATCHTOWER, dusk to dawn. i had a clear line to the MANOR."

solvable by: {bela, dragan} · {mara, luka} · {dragan, luka}  (cheapest day 12 ticks)

### Night 17 — L7, pattern B, wolf **iris**, attack site GRAVEYARD

```
  r1 [ .. ] [FRG ] [ .. ] [MIL ] [MTN ] [ @@ ]
  r2 [mara] [ .. ] [ .. ] [INN ] [otto] [ .. ]
  r3 [FOR ] [ .. ] [luka] [TWR ] [ .. ] [ .. ]
  r4 [ .. ] [ .. ] [CHA ] [ .. ] [drag] [ .. ]
  r5 [ .. ] [bela] [ .. ] [vesn] [ .. ] [GRV ]
  r6 [WEL ] [iris] [stef] [MAN ] [ .. ] [LAK ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the MOUNTAIN all night. mara was at the FORGE. i saw them."
- **mara** — "i was at the FORGE from dusk to dawn. i passed vesna by the INN, near midnight."
- **otto** — "i was down at the WATCHTOWER, half asleep. dragan went past the CHAPEL, i think."
- **vesna** — "oh, i was over at the INN all evening. i had a clear line to the MILL."
- **dragan** — "the CHAPEL. all night. stefan was at the WELL."
- **luka** — "i was out at the LAKE, where else. iris was by the GRAVEYARD. i saw that much."
- **iris** *(wolf)* — "i stayed near the MANOR, as i always do. nothing stood between me and the MOUNTAIN."
- **stefan** — "post: the WELL, dusk to dawn. sighting: luka, at the LAKE."

solvable by: {iris} · {luka, stefan}  (cheapest day 11 ticks)

### Night 18 — L7, pattern A, wolf **stefan**, attack site MILL

```
  r1 [ .. ] [FRG ] [ .. ] [MIL ] [MTN ] [ @@ ]
  r2 [mara] [ .. ] [ .. ] [INN ] [otto] [ .. ]
  r3 [FOR ] [ .. ] [luka] [TWR ] [ .. ] [ .. ]
  r4 [ .. ] [ .. ] [CHA ] [ .. ] [drag] [ .. ]
  r5 [ .. ] [bela] [ .. ] [vesn] [ .. ] [GRV ]
  r6 [WEL ] [iris] [stef] [MAN ] [ .. ] [LAK ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the MANOR all night. mara was at the WATCHTOWER. i saw them."
- **mara** — "i was at the WATCHTOWER from dusk to dawn. i passed stefan by the MILL, near midnight."
- **otto** — "i was down at the FOREST, half asleep. dragan went past the FORGE, i think."
- **vesna** — "oh, i was over at the INN all evening. and stefan! over at the MILL, plain as day."
- **dragan** — "the FORGE. all night. luka was at the MOUNTAIN."
- **luka** — "i was out at the MOUNTAIN, where else. vesna was by the INN. i saw that much."
- **iris** — "i stayed near the LAKE, as i always do. poor bela was out by the MANOR."
- **stefan** *(wolf)* — "post: the WELL, dusk to dawn. i had a clear line to the FOREST."

solvable by: {bela, mara} · {mara, vesna} · {vesna, luka}  (cheapest day 15 ticks)

### Night 19 — L5, pattern D, wolf **bela**, attack site MANOR

```
  r1 [MIL ] [LAK ] [drag] [ .. ] [CHA ] [otto]
  r2 [GRV ] [ @@ ] [ .. ] [ .. ] [ .. ] [ .. ]
  r3 [ .. ] [ .. ] [ .. ] [WEL ] [ .. ] [vesn]
  r4 [ .. ] [MAN ] [bela] [ .. ] [FOR ] [FRG ]
  r5 [luka] [ .. ] [TWR ] [ .. ] [iris] [ .. ]
  r6 [INN ] [stef] [ .. ] [ .. ] [mara] [MTN ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** *(wolf)* — "i was at the INN all night. otto was at the FOREST. i saw them."
- **mara** — "i was at the WELL from dusk to dawn. i passed luka by the CHAPEL, near midnight."
- **otto** — "i was down at the FOREST, half asleep. stefan went past the WATCHTOWER, i think."
- **vesna** — "oh, i was over at the FORGE all evening. and otto! over at the FOREST, plain as day."
- **dragan** — "the GRAVEYARD. all night. the MILL stood right beside me."
- **luka** — "i was out at the CHAPEL, where else. iris was by the MILL. i saw that much."
- **iris** — "i stayed near the MILL, as i always do. poor dragan was out by the GRAVEYARD."
- **stefan** — "post: the WATCHTOWER, dusk to dawn. sighting: bela, at the MANOR."

solvable by: {bela} · {otto, stefan}  (cheapest day 5 ticks)

### Night 20 — L8, pattern C, wolf **otto**, attack site WATCHTOWER

```
  r1 [ .. ] [bela] [ .. ] [TWR ] [INN ] [WEL ]
  r2 [ .. ] [luka] [ .. ] [ .. ] [otto] [vesn]
  r3 [drag] [ .. ] [ .. ] [FOR ] [MTN ] [ .. ]
  r4 [ .. ] [ @@ ] [ .. ] [ .. ] [ .. ] [stef]
  r5 [LAK ] [FRG ] [ .. ] [iris] [MIL ] [MAN ]
  r6 [CHA ] [ .. ] [ .. ] [mara] [ .. ] [GRV ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the FORGE all night. mara was at the FOREST. i saw them."
- **mara** — "i was at the FOREST from dusk to dawn. i passed otto by the WATCHTOWER, near midnight."
- **otto** *(wolf)* — "i was down at the WELL, half asleep. vesna went past the WATCHTOWER, i think."
- **vesna** — "oh, i was over at the MANOR all evening. and bela! over at the FORGE, plain as day."
- **dragan** — "the GRAVEYARD. all night. vesna was at the MANOR."
- **luka** — "i was out at the LAKE, where else. iris was by the MILL. i saw that much."
- **iris** — "i stayed near the MILL, as i always do. the MANOR was at my shoulder all night."
- **stefan** — "post: the CHAPEL, dusk to dawn. sighting: luka, at the LAKE."

solvable by: {bela, mara} · {mara, otto} · {otto, dragan}  (cheapest day 11 ticks)

### Night 21 — L8, pattern A, wolf **dragan**, attack site WELL

```
  r1 [ .. ] [bela] [ .. ] [TWR ] [INN ] [WEL ]
  r2 [ .. ] [luka] [ .. ] [ .. ] [otto] [vesn]
  r3 [drag] [ .. ] [ .. ] [FOR ] [MTN ] [ .. ]
  r4 [ .. ] [ @@ ] [ .. ] [ .. ] [ .. ] [stef]
  r5 [LAK ] [FRG ] [ .. ] [iris] [MIL ] [MAN ]
  r6 [CHA ] [ .. ] [ .. ] [mara] [ .. ] [GRV ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the MILL all night. otto was at the FOREST. i saw them."
- **mara** — "i was at the MANOR from dusk to dawn. i passed dragan by the WELL, near midnight."
- **otto** — "i was down at the FOREST, half asleep. dragan went past the WELL, i think."
- **vesna** — "oh, i was over at the CHAPEL all evening. i was near enough to hear the LAKE."
- **dragan** *(wolf)* — "the FORGE. all night. bela was at the MILL."
- **luka** — "i was out at the LAKE, where else. mara was by the MANOR. i saw that much."
- **iris** — "i stayed near the WATCHTOWER, as i always do. poor stefan was out by the INN."
- **stefan** — "post: the INN, dusk to dawn. sighting: iris, at the WATCHTOWER."

solvable by: {bela, otto} · {mara, otto} · {mara, luka}  (cheapest day 11 ticks)

### Night 22 — L6, pattern B, wolf **luka**, attack site MOUNTAIN

```
  r1 [ .. ] [ .. ] [iris] [MIL ] [otto] [FRG ]
  r2 [FOR ] [LAK ] [stef] [ .. ] [ .. ] [ .. ]
  r3 [drag] [vesn] [ .. ] [ .. ] [MAN ] [bela]
  r4 [luka] [ .. ] [MTN ] [ .. ] [ .. ] [mara]
  r5 [ @@ ] [ .. ] [TWR ] [ .. ] [GRV ] [ .. ]
  r6 [ .. ] [ .. ] [WEL ] [CHA ] [INN ] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the CHAPEL all night. iris was at the GRAVEYARD. i saw them."
- **mara** — "i was at the MILL from dusk to dawn. i passed otto by the FORGE, near midnight."
- **otto** — "i was down at the FORGE, half asleep. mara went past the MILL, i think."
- **vesna** — "oh, i was over at the LAKE all evening. and dragan! over at the FOREST, plain as day."
- **dragan** — "the FOREST. all night. luka was at the MOUNTAIN."
- **luka** *(wolf)* — "i was out at the WATCHTOWER, where else. i could have touched the GRAVEYARD."
- **iris** — "i stayed near the GRAVEYARD, as i always do. poor bela was out by the CHAPEL."
- **stefan** — "post: the WELL, dusk to dawn. i was near enough to hear the WATCHTOWER."

solvable by: {vesna, dragan} · {luka}  (cheapest day 3 ticks)

### Night 23 — L7, pattern C, wolf **vesna**, attack site FORGE

```
  r1 [ .. ] [FRG ] [ .. ] [MIL ] [MTN ] [ @@ ]
  r2 [mara] [ .. ] [ .. ] [INN ] [otto] [ .. ]
  r3 [FOR ] [ .. ] [luka] [TWR ] [ .. ] [ .. ]
  r4 [ .. ] [ .. ] [CHA ] [ .. ] [drag] [ .. ]
  r5 [ .. ] [bela] [ .. ] [vesn] [ .. ] [GRV ]
  r6 [WEL ] [iris] [stef] [MAN ] [ .. ] [LAK ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the MANOR all night. mara was at the LAKE. i saw them."
- **mara** — "i was at the LAKE from dusk to dawn. i passed stefan by the GRAVEYARD, near midnight."
- **otto** — "i was down at the WELL, half asleep. iris went past the FOREST, i think."
- **vesna** *(wolf)* — "oh, i was over at the WATCHTOWER all evening. and dragan! over at the FORGE, plain as day."
- **dragan** — "the MOUNTAIN. all night. i could see the FORGE across the field."
- **luka** — "i was out at the MILL, where else. dragan was by the MOUNTAIN. i saw that much."
- **iris** — "i stayed near the FOREST, as i always do. poor vesna was out by the FORGE."
- **stefan** — "post: the GRAVEYARD, dusk to dawn. sighting: bela, at the MANOR."

solvable by: {vesna, luka} · {otto, iris} · {vesna, iris}  (cheapest day 13 ticks)

### Night 24 — L1, pattern D, wolf **mara**, attack site LAKE

```
  r1 [TWR ] [MIL ] [ .. ] [ .. ] [ .. ] [FOR ]
  r2 [INN ] [mara] [ .. ] [ .. ] [ @@ ] [ .. ]
  r3 [WEL ] [bela] [FRG ] [iris] [ .. ] [stef]
  r4 [ .. ] [ .. ] [drag] [MTN ] [ .. ] [CHA ]
  r5 [ .. ] [LAK ] [GRV ] [ .. ] [vesn] [MAN ]
  r6 [ .. ] [ .. ] [otto] [luka] [ .. ] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the MOUNTAIN all night. iris was at the GRAVEYARD. i saw them."
- **mara** *(wolf)* — "i was at the MANOR from dusk to dawn. i passed stefan by the WATCHTOWER, near midnight."
- **otto** — "i was down at the CHAPEL, half asleep. nothing stood between me and the MANOR."
- **vesna** — "oh, i was over at the FOREST all evening. and otto! over at the CHAPEL, plain as day."
- **dragan** — "the INN. all night. luka was at the MILL."
- **luka** — "i was out at the MILL, where else. mara was by the LAKE. i saw that much."
- **iris** — "i stayed near the GRAVEYARD, as i always do. nothing stood between me and the MANOR."
- **stefan** — "post: the WATCHTOWER, dusk to dawn. sighting: dragan, at the INN."

solvable by: {mara} · {dragan, luka}  (cheapest day 5 ticks)

### Night 25 — L8, pattern B, wolf **bela**, attack site INN

```
  r1 [ .. ] [bela] [ .. ] [TWR ] [INN ] [WEL ]
  r2 [ .. ] [luka] [ .. ] [ .. ] [otto] [vesn]
  r3 [drag] [ .. ] [ .. ] [FOR ] [MTN ] [ .. ]
  r4 [ .. ] [ @@ ] [ .. ] [ .. ] [ .. ] [stef]
  r5 [LAK ] [FRG ] [ .. ] [iris] [MIL ] [MAN ]
  r6 [CHA ] [ .. ] [ .. ] [mara] [ .. ] [GRV ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** *(wolf)* — "i was at the MOUNTAIN all night. the WATCHTOWER stood right beside me."
- **mara** — "i was at the GRAVEYARD from dusk to dawn. i passed stefan by the WELL, near midnight."
- **otto** — "i was down at the CHAPEL, half asleep. luka went past the LAKE, i think."
- **vesna** — "oh, i was over at the MILL all evening. and dragan! over at the FOREST, plain as day."
- **dragan** — "the FOREST. all night. vesna was at the MILL."
- **luka** — "i was out at the LAKE, where else. the FORGE was in plain view."
- **iris** — "i stayed near the MANOR, as i always do. poor mara was out by the GRAVEYARD."
- **stefan** — "post: the WELL, dusk to dawn. sighting: bela, at the INN."

solvable by: {bela} · {mara, stefan}  (cheapest day 5 ticks)

### Night 26 — L2, pattern C, wolf **iris**, attack site WELL

```
  r1 [FOR ] [WEL ] [bela] [ .. ] [ .. ] [INN ]
  r2 [stef] [ .. ] [ .. ] [ .. ] [TWR ] [CHA ]
  r3 [ .. ] [ .. ] [ @@ ] [ .. ] [MAN ] [ .. ]
  r4 [otto] [mara] [ .. ] [luka] [drag] [ .. ]
  r5 [FRG ] [ .. ] [ .. ] [ .. ] [GRV ] [vesn]
  r6 [ .. ] [ .. ] [LAK ] [MIL ] [MTN ] [iris]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the MANOR all night. otto was at the WATCHTOWER. i saw them."
- **mara** — "i was at the GRAVEYARD from dusk to dawn. the cry was a long way away."
- **otto** — "i was down at the WATCHTOWER, half asleep. bela went past the MANOR, i think."
- **vesna** — "oh, i was over at the MOUNTAIN all evening. and dragan! over at the LAKE, plain as day."
- **dragan** — "the LAKE. all night. vesna was at the MOUNTAIN."
- **luka** — "i was out at the FORGE, where else. stefan was by the FOREST. i saw that much."
- **iris** *(wolf)* — "i stayed near the INN, as i always do. poor vesna was out by the WELL."
- **stefan** — "post: the FOREST, dusk to dawn. sighting: iris, at the WELL."

solvable by: {dragan, iris} · {luka, stefan} · {iris, stefan}  (cheapest day 10 ticks)

### Night 27 — L5, pattern C, wolf **mara**, attack site GRAVEYARD

```
  r1 [MIL ] [LAK ] [drag] [ .. ] [CHA ] [otto]
  r2 [GRV ] [ @@ ] [ .. ] [ .. ] [ .. ] [ .. ]
  r3 [ .. ] [ .. ] [ .. ] [WEL ] [ .. ] [vesn]
  r4 [ .. ] [MAN ] [bela] [ .. ] [FOR ] [FRG ]
  r5 [luka] [ .. ] [TWR ] [ .. ] [iris] [ .. ]
  r6 [INN ] [stef] [ .. ] [ .. ] [mara] [MTN ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the MOUNTAIN all night. i could see the FORGE across the field."
- **mara** *(wolf)* — "i was at the LAKE from dusk to dawn. i passed luka by the GRAVEYARD, near midnight."
- **otto** — "i was down at the INN, half asleep. luka went past the WATCHTOWER, i think."
- **vesna** — "oh, i was over at the MANOR all evening. and mara! over at the GRAVEYARD, plain as day."
- **dragan** — "the WELL. all night. iris was at the CHAPEL."
- **luka** — "i was out at the WATCHTOWER, where else. otto was by the INN. i saw that much."
- **iris** — "i stayed near the CHAPEL, as i always do. poor dragan was out by the WELL."
- **stefan** — "post: the FOREST, dusk to dawn. sighting: vesna, at the MANOR."

solvable by: {mara, otto} · {mara, vesna} · {vesna, stefan}  (cheapest day 19 ticks)

### Night 28 — L4, pattern A, wolf **vesna**, attack site MOUNTAIN

```
  r1 [ .. ] [ .. ] [stef] [ .. ] [drag] [WEL ]
  r2 [otto] [ .. ] [ .. ] [mara] [ .. ] [MAN ]
  r3 [ .. ] [LAK ] [iris] [ .. ] [INN ] [MIL ]
  r4 [GRV ] [ .. ] [ .. ] [CHA ] [ .. ] [ .. ]
  r5 [FOR ] [bela] [ .. ] [ .. ] [ @@ ] [TWR ]
  r6 [FRG ] [ .. ] [vesn] [MTN ] [luka] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the MANOR all night. otto was at the CHAPEL. i saw them."
- **mara** — "i was at the INN from dusk to dawn. i passed dragan by the MILL, near midnight."
- **otto** — "i was down at the CHAPEL, half asleep. vesna went past the MOUNTAIN, i think."
- **vesna** *(wolf)* — "oh, i was over at the GRAVEYARD all evening. and stefan! over at the FORGE, plain as day."
- **dragan** — "the MILL. all night. luka was at the WATCHTOWER."
- **luka** — "i was out at the WATCHTOWER, where else. vesna was by the MOUNTAIN. i saw that much."
- **iris** — "i stayed near the WELL, as i always do. poor bela was out by the MANOR."
- **stefan** — "post: the FORGE, dusk to dawn. i was near enough to hear the FOREST."

solvable by: {bela, otto} · {otto, luka} · {dragan, luka}  (cheapest day 13 ticks)

### Night 29 — L3, pattern B, wolf **stefan**, attack site CHAPEL

```
  r1 [ .. ] [ .. ] [ .. ] [ .. ] [mara] [FRG ]
  r2 [luka] [iris] [ .. ] [ .. ] [ .. ] [vesn]
  r3 [ .. ] [LAK ] [WEL ] [ .. ] [GRV ] [ .. ]
  r4 [drag] [ .. ] [ .. ] [MAN ] [CHA ] [bela]
  r5 [INN ] [MTN ] [ .. ] [MIL ] [ .. ] [stef]
  r6 [FOR ] [ @@ ] [ .. ] [ .. ] [otto] [TWR ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the GRAVEYARD all night. stefan was at the CHAPEL. i saw them."
- **mara** — "i was at the WATCHTOWER from dusk to dawn. i passed vesna by the MILL, near midnight."
- **otto** — "i was down at the FOREST, half asleep. mara went past the WATCHTOWER, i think."
- **vesna** — "oh, i was over at the MILL all evening. and mara! over at the WATCHTOWER, plain as day."
- **dragan** — "the MANOR. all night. bela was at the GRAVEYARD."
- **luka** — "i was out at the MOUNTAIN, where else. iris was by the WELL. i saw that much."
- **iris** — "i stayed near the WELL, as i always do. poor luka was out by the MOUNTAIN."
- **stefan** *(wolf)* — "post: the LAKE, dusk to dawn. i was near enough to hear the FOREST."

solvable by: {bela, dragan} · {stefan}  (cheapest day 7 ticks)

### Night 30 — L6, pattern D, wolf **otto**, attack site WELL

```
  r1 [ .. ] [ .. ] [iris] [MIL ] [otto] [FRG ]
  r2 [FOR ] [LAK ] [stef] [ .. ] [ .. ] [ .. ]
  r3 [drag] [vesn] [ .. ] [ .. ] [MAN ] [bela]
  r4 [luka] [ .. ] [MTN ] [ .. ] [ .. ] [mara]
  r5 [ @@ ] [ .. ] [TWR ] [ .. ] [GRV ] [ .. ]
  r6 [ .. ] [ .. ] [WEL ] [CHA ] [INN ] [ .. ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the GRAVEYARD all night. i could see the WATCHTOWER across the field."
- **mara** — "i was at the FOREST from dusk to dawn. i passed dragan by the LAKE, near midnight."
- **otto** *(wolf)* — "i was down at the MANOR, half asleep. dragan went past the LAKE, i think."
- **vesna** — "oh, i was over at the MOUNTAIN all evening. and otto! over at the WELL, plain as day."
- **dragan** — "the LAKE. all night. mara was at the FOREST."
- **luka** — "i was out at the MILL, where else. stefan was by the FORGE. i saw that much."
- **iris** — "i stayed near the WATCHTOWER, as i always do. poor vesna was out by the MOUNTAIN."
- **stefan** — "post: the FORGE, dusk to dawn. sighting: luka, at the MILL."

solvable by: {otto} · {vesna, iris}  (cheapest day 10 ticks)

### Night 31 — L8, pattern D, wolf **luka**, attack site FOREST

```
  r1 [ .. ] [bela] [ .. ] [TWR ] [INN ] [WEL ]
  r2 [ .. ] [luka] [ .. ] [ .. ] [otto] [vesn]
  r3 [drag] [ .. ] [ .. ] [FOR ] [MTN ] [ .. ]
  r4 [ .. ] [ @@ ] [ .. ] [ .. ] [ .. ] [stef]
  r5 [LAK ] [FRG ] [ .. ] [iris] [MIL ] [MAN ]
  r6 [CHA ] [ .. ] [ .. ] [mara] [ .. ] [GRV ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the WATCHTOWER all night. stefan was at the MOUNTAIN. i saw them."
- **mara** — "i was at the WELL from dusk to dawn. i passed bela by the WATCHTOWER, near midnight."
- **otto** — "i was down at the CHAPEL, half asleep. whatever screamed, it was distant."
- **vesna** — "oh, i was over at the GRAVEYARD all evening. and dragan! over at the MILL, plain as day."
- **dragan** — "the MILL. all night. luka was at the FOREST."
- **luka** *(wolf)* — "i was out at the MANOR, where else. otto was by the CHAPEL. i saw that much."
- **iris** — "i stayed near the LAKE, as i always do. poor otto was out by the CHAPEL."
- **stefan** — "post: the MOUNTAIN, dusk to dawn. sighting: mara, at the WELL."

solvable by: {vesna, dragan} · {luka}  (cheapest day 4 ticks)

### Night 32 — L7, pattern A, wolf **dragan**, attack site MANOR

```
  r1 [ .. ] [FRG ] [ .. ] [MIL ] [MTN ] [ @@ ]
  r2 [mara] [ .. ] [ .. ] [INN ] [otto] [ .. ]
  r3 [FOR ] [ .. ] [luka] [TWR ] [ .. ] [ .. ]
  r4 [ .. ] [ .. ] [CHA ] [ .. ] [drag] [ .. ]
  r5 [ .. ] [bela] [ .. ] [vesn] [ .. ] [GRV ]
  r6 [WEL ] [iris] [stef] [MAN ] [ .. ] [LAK ]

  @@ = player start   UPPERCASE = impassable landmark
```

- **bela** — "i was at the MOUNTAIN all night. mara was at the FORGE. i saw them."
- **mara** — "i was at the FORGE from dusk to dawn. i passed iris by the INN, near midnight."
- **otto** — "i was down at the GRAVEYARD, half asleep. vesna went past the LAKE, i think."
- **vesna** — "oh, i was over at the LAKE all evening. i was near enough to hear the GRAVEYARD."
- **dragan** *(wolf)* — "the WATCHTOWER. all night. bela was at the MOUNTAIN."
- **luka** — "i was out at the CHAPEL, where else. dragan was by the MANOR. i saw that much."
- **iris** — "i stayed near the INN, as i always do. poor dragan was out by the MANOR."
- **stefan** — "post: the FOREST, dusk to dawn. sighting: luka, at the CHAPEL."

solvable by: {mara, iris} · {luka, iris} · {luka, stefan}  (cheapest day 17 ticks)

