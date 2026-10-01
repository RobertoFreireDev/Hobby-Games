// Splices tools/levels.js into the cart's __lua__ level table, between the
// -- <levels> / -- </levels> markers. Touches nothing else — art, sfx and music
// stay exactly as they are (that is gen.js's job).
const fs = require("fs");
const path = require("path");
const { levels } = require("./levels.js");

const CART = path.join(__dirname, "..", "game.p8");
let cart = fs.readFileSync(CART, "utf8").replace(/\r\n/g, "\n");

const lua = "lvls={\n" + levels.map((s, i) => {
  const rows = [];
  for (let y = 0; y < 10; y++) rows.push('"' + s.slice(y * 10, y * 10 + 10) + '"');
  return "-- " + (i + 1) + "\n" + rows.join("..\n");
}).join(",\n") + "}\n";

const li = cart.indexOf("-- <levels>");
const lj = cart.indexOf("-- </levels>");
if (li < 0 || lj < 0) throw new Error("level markers missing in game.p8");
cart = cart.slice(0, li) + "-- <levels>\n" + lua + cart.slice(lj);
fs.writeFileSync(CART, cart);
console.log("injected " + levels.length + " levels into " + CART);
