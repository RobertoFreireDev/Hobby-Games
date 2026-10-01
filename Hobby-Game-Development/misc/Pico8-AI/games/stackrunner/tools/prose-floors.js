// hand-written per-floor prose. everything numeric around it is generated.
module.exports=[
{title:"Cards are objects",
 asks:"A press spends the top card; a card on the floor is picked up as you walk over it.",
 body:"One room broken into bays by single pillars, with the stair diagonally opposite the start.\nNothing here can kill you and nothing can be permanently spoiled - the only way to lose is to\nspend the stack walking the wrong way, and there are enough cards lying about that even that\ntakes some doing. Every short route turns at least twice, because no straight stretch of floor is\nlonger than four squares: a 2-card and a 3-card cannot be lined up into a drill.",
 fail:"Walk the stack down to nothing and the **no moves left** modal comes up and rewinds the floor\nfor you. That is the first lesson, and it costs nothing but the detour."},

{title:"The last card you pick up is the next one you spend",
 asks:"LIFO. Card placement, not card count, decides your route.",
 body:"The pillars form loops around a shared middle, so most wrong turns lead back to where you were\nrather than into a dead end. What the loops do not fix is the order of your stack: sweep a cluster\nof 2s on the way past and your next press is a 2, whether or not that is what the next gap wanted.\nThe cheap route and the route that leaves you rich are not the same route.",
 fail:"There is no way to discard a card. The only way to get rid of one is to move with it, so a\nbadly-timed pickup costs you the press that spends it again."},

{title:"Runs stop at walls, so pick the rung",
 asks:"The max card. It runs until something stops it, which is the cheapest way to cross a floor and\nthe least controllable.",
 body:"The first floor with **move max** on it. One max card can cross the whole room for the price of a\nsingle press - and it will not stop where you wanted unless a wall is standing there. The pillars\nare the brakes, and choosing which gap to enter a run from is the puzzle. A second max press in the\nsame direction is always a blocked move: free, and completely useless.",
 fail:"Start a max run down the wrong lane and you arrive somewhere cheap and useless, with the card\nalready gone."},

{title:"The crate is in the junction, and it only opens one way",
 asks:"**First crate.** A crate moves one square, only into empty floor, and always ends up in front of\nyou.",
 body:"The stair sits behind a squeeze that a single crate is standing in. Cards do not count as empty\nfloor, so most of the squares around the crate will not take it - the push that works is the one\naimed at bare floor, and finding it means walking round to the right side rather than shoving from\nwherever you happen to arrive.",
 fail:"Push from the wrong side and the crate goes somewhere it cannot come back from. The rewind\nbutton is one press; it is meant to be used here."},

{title:"Two crates, and only one of them is in your way",
 asks:"Which crate, and in which order.",
 body:"A second crate joins the first. Only one of them stands between you and the stair; the other is a\ntoll gate on a cluster of cards, and clearing it costs presses you may want later. Both can be\njammed against a wall, and one of them can be jammed across the route you still need.",
 fail:"Spend your presses on the wrong crate and you arrive at the right one without the budget to use\nwhat is behind it."},

{title:"The guard does not move, and does not have to",
 asks:"**First guard.** He blocks his own square, and kills whatever is orthogonally beside him when a\nmove *ends*.",
 body:"Passing through his reach is free; stopping in it is fatal. That turns every card into a\nstatement about distance - the same route is safe with a 3 and lethal with a 2 - and it is why a\ncard is parked inside his reach, collectable only in passing. The stair beats the guard, so landing\non it from inside his reach still wins the floor.",
 fail:"**A death is reachable on the natural approach.** Walk at him with the wrong card on top and the\nboard freezes, the player blinks, and you watch it happen."},

{title:"Two guards, and the gap between them",
 asks:"Exact card length as survival.",
 body:"Two guards set apart turn a stretch of floor into an alternating pattern of lethal and safe\nsquares. The corridor now reads as a sequence: this length lives, that length dies. The cards you\nneed are on the floor in the right order, if you take them in the right order.",
 fail:"Every wrong length is a death, and the ones that look shortest are usually the wrong length."},

{title:"One switch, every door, both directions at once",
 asks:"**First door and switch.** The switch flips *all* doors - closed to open and open to closed.",
 body:"One closed door stands between you and the stair, one open door is somewhere you still want to\nwalk through, and the flip does both at the same time. Walk through the open one first and the flip\nis free; flip while you are on the wrong side of it and you have swapped which half of the floor\nyou are locked into. There is a **second switch** on the board on purpose: flipping early costs you\nthe walk to fetch it, not the run.",
 fail:"The flip is the whole floor. Everything else here is just distance."},

{title:"The crate that cannot be pushed",
 asks:"**First bomb.** Thrown into the empty square you are facing; it detonates at the end of your\n*next* move and clears crates and guards orthogonally around it.",
 body:"A crate sits where nothing can shift it - the squares behind it are not empty floor, so no push is\nlegal from any side. The only answer is the bomb: stand where the throw lands on it, throw, and then\nmove, because the fuse only burns when you do. The live bomb is solid while it sits there, so the\nmove that sets it off cannot be forwards. A second bomb lies elsewhere on the floor for anyone who\nthrows the first one at nothing.",
 fail:"A bomb thrown at empty floor is simply gone. That is what the spare is for."},

{title:"Two squares from a guard is the safe place to throw from",
 asks:"Bomb against guard. The throw range and the kill range are the same distance.",
 body:"A guard seals the only approach to the stair. Standing next to him kills you; standing two away is\nexactly where you have to be to drop a bomb into the gap between you. The geometry that makes him\ndangerous is the geometry that makes him killable - and the retreat afterwards is part of the cost,\nbecause the fuse burns on your next move whether you like where it takes you or not.",
 fail:"**Death is reachable one square early.** Approach with a card that ends beside him instead of two\naway and the floor is over."},

{title:"The fork - two bombs, two switches, and only three pockets",
 asks:"**The branch point.** Choose what the rest of the run gets to use.",
 body:"Four items on one floor and room to carry three, with the only way out through a closed door that\none of the switches has to open. Whatever you carry out is whatever you had the presses to reach and\nthe pockets to hold, and the movement stack is competing for those same presses. This is the widest\nchoice in the game.",
 fail:"Nothing here is lethal. The cost is opportunity - and the floors after this one are not equally\nkind to every haul that leaves it."},

{title:"The door you brought the key for",
 asks:"The fork pays out.",
 body:"A closed door caps the way down to the stair chamber and a guard stands in the room beyond it. A\nswitch opens the door; a bomb removes the guard; there is a spare of each on the floor for anyone\nwho arrived with neither, at the price of the walk to reach it. What you spent on floor 11 decides\nwhether this floor is a corridor or an errand.",
 fail:"Arrive too poor and the errand costs more presses than you brought. **Back a level** on the pause\nmenu re-runs floor 11 and hands back its entry stack."},

{title:"A crate is a brake, and the guard is what happens without one",
 asks:"The crate as level geometry rather than as an obstacle.",
 body:"A max card down the open lane runs until something stops it, and the only thing standing in that\nlane is the guard. Put the crate in the way first and the same run stops short of him instead.\nExact-length cards also work - the crate is the cheap answer, not the only one.",
 fail:"The unbraked run is a death. The crate can also be pushed to a square where it brakes nothing."},

{title:"Door, crate and guard, in the order the geometry fixes",
 asks:"Three pieces on one floor, with the order decided by where they sit.",
 body:"The stair is behind a closed door, the square in front of that door is inside a guard's reach, and\nthe switch is on the far side of an open door that the same flip will close behind you. So the flip\nhas a right moment and two wrong ones, and the crate in the middle of the floor is a decoy: bulldoze\nit and you lose a shortcut, not the floor. A spare switch covers the wrong moment.",
 fail:"Flip early and you shut the way you came. Run the last corridor before the door is open and the\nguard has you."},

{title:"Bomb the guard, then find the switch, on that budget",
 asks:"Two items, one route, in a fixed order.",
 body:"A guard seals the only way through, and the door beyond him wants a switch that is on the far side\nof him. So the bomb goes first - there is no reaching anything else until he is gone - and the switch\nhas to survive the rest of the walk. Both items have a spare, and both spares are expensive.",
 fail:"Spend either item early and the rest of the floor is a walk with nothing to spend. Death is\nreachable at the guard."},

{title:"Everything, in a forced order",
 asks:"Crate, guard, bomb, switch and doors on one board.",
 body:"The way in is a crate that can only be pushed one way. Past it, a guard sits between you and the\nswitch, two squares from the one place you can throw a bomb from. A second guard watches the far\nroute with a card parked inside his reach as bait. Crate, then bomb, then switch: no other order\nfinishes, and the run ends here.",
 fail:"Two guards, a jammable crate, and two items that can each be spent on nothing."},
];
