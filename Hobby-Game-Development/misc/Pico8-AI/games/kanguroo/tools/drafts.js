// TERRAIN ONLY — 8 rows x 8 chars, the interior of the 10x10 board.
// . sand   # rock   ~ water   o goal
//
// The lethal water border is added by deepen.js, so no level has a wall at the
// edge to bounce a jump off. Box and player starts are NOT authored here:
// deepen.js walks backwards from the solved state, which makes every level
// solvable by construction and makes the BFS layer a start is drawn from its
// exact optimal move count. `want` is the layer to draw from (0 = the deepest).
//
// Ordered by that optimal move count: 22 -> 112.
module.exports = [
// 1 — rock teeth in two offset rows: the only way onto an even column is to
// clip a tooth and shorten the jump to a single tile.
{ name: "comb", want: 0, rows: [
"........",
".#.#.#.#",
"........",
"...o.o..",
"........",
"#.#.#.#.",
"........",
"..o....."]},

// 2 — a solid wall with a single gap. every box has to be threaded through it,
// and the gap is one tile wide so the approach line is forced.
{ name: "one gate", want: 0, rows: [
"........",
"..o..o..",
"........",
"###.####",
"........",
"..o..o..",
"........",
"........"]},

// 3 — a water row with two land bridges. the player can leap the water
// anywhere; the boxes can only ever come across on the bridges.
{ name: "the bridges", want: 0, rows: [
"........",
"...o....",
"........",
"~~.~~~.~",
"........",
"..o..o..",
"........",
"........"]},

// 4 — staggered rock pairs. every row reverses which columns you can stop on.
{ name: "chicane", want: 0, rows: [
"........",
".##..##.",
"..o..o..",
".##..##.",
"........",
".##..##.",
"..o..o..",
".##..##."]},

// 5 — five boxes around a central rock block, water biting into all four
// corners so the outside lane is never quite safe.
{ name: "the long way home", want: 0, rows: [
"..~..~..",
".o....o.",
"........",
"~..##..~",
"...##...",
"........",
".o.o..o.",
"..~..~.."]},

// 6 — bare sand except for four rocks. they are the only fixed brakes on the
// board, so most of the routing has to be done against the boxes themselves.
{ name: "anvils", want: 0, rows: [
"...#....",
"..o.....",
"........",
"#.....#.",
"...o....",
"........",
".#....o.",
"...#...."]},

// 7 — lakes eat the top and bottom, leaving a wide waist. the goals sit on the
// four shores and every box has to be walked the long way round.
{ name: "four lakes", want: 0, rows: [
"..~~~~..",
"..~~~~..",
"o......o",
"........",
"........",
"o......o",
"..~~~~..",
"..~~~~.."]},

// 8 — no rocks at all. the boxes are the only things that can shorten a jump,
// so every box is both cargo and scaffolding.
{ name: "parity field", want: 0, rows: [
"........",
"..o.....",
"........",
".....o..",
"........",
"..o.....",
"........",
"........"]},

// 9 — a serpentine of rock walls: one lane in, one lane out, no room to turn.
{ name: "switchback", want: 0, rows: [
"........",
"..####..",
"o.......",
"....####",
"......o.",
"####....",
".o......",
"..####.."]},

// 10 — a vertical channel with a land bridge top and bottom. five boxes, two
// shores, and only two places a box can change sides.
{ name: "the channel", want: 0, rows: [
"........",
"..o.~..o",
"....~...",
"..o.~...",
"....~...",
"..o.~..o",
"....~...",
"........"]},

// 11 — scattered single water tiles. nothing blocks a jump, so nothing stops
// you landing in one either, and the safe stopping tiles keep shifting.
{ name: "stepping stones", want: 0, rows: [
"........",
".~.~.~..",
"........",
"..o..o..",
"..~.~.~.",
"........",
"....o...",
"........"]},

// 12 — four quadrants joined by two one-tile doorways: empty the wrong quadrant
// first and a box can never get back out of it.
{ name: "the cross", want: 0, rows: [
"........",
"........",
"..o#.o..",
"##.##.##",
"........",
"..o#.o..",
"........",
"........"]},

// 13 — a diagonal of water. every crossing is a different length, and the
// diagonal keeps taking away the tile you meant to land on.
{ name: "the slash", want: 0, rows: [
"..~.....",
"...~....",
"o...~...",
".....~..",
"..o...~.",
"...o...~",
"........",
"...o...."]},

// 14 — the rocks sit on the far shore of the lake. they shorten the jump that
// was going to clear the water, which drops you straight into it.
{ name: "far shore", want: 0, rows: [
"...o....",
"........",
"..#..o#.",
"~~~.~~~~",
"........",
"..o..o..",
"........",
"...o...."]},

// 15 — four goals in a row. filling one blocks the approach to the next, so the
// order is the whole puzzle.
{ name: "box train", want: 0, rows: [
"........",
"..oooo..",
"........",
"...##...",
"........",
"..#..#..",
"........",
"........"]},

// 16 — a walled corral with one mouth. five boxes have to go in, and the last
// one in must be the one nearest the door.
{ name: "the pen", want: 0, rows: [
"........",
"..#####.",
"..#o.o#.",
"..#...#.",
"..#ooo#.",
"......#.",
"........",
"........"]},
];
