// Splices a screen dump from run.log into game.p8 as __label__.
//   node label.js [shotname]      (default: intro)
// The dump is already 128 lines of 128 palette indices, which is exactly the
// __label__ encoding — no conversion needed beyond picking the right shot.
const fs = require("fs");
const path = require("path");

const want = process.argv[2] || "intro";
const log = fs.readFileSync(path.join(__dirname, "run.log"), "utf8").split(/\r?\n/);
let cur = null, rows = [];
for (const line of log) {
  const s = line.replace(/^INFO:\s*/, "");
  if (s.startsWith("shot ")) cur = s.split(" ")[1];
  else if (s.startsWith("px ") && cur === want && rows.length < 128) rows.push(s.slice(3));
}
if (rows.length !== 128) throw new Error("shot '" + want + "' had " + rows.length + " rows");
rows.forEach((r, i) => { if (r.length !== 128) throw new Error("label line " + i + " is " + r.length); });

const CART = path.join(__dirname, "..", "game.p8");
let cart = fs.readFileSync(CART, "utf8").replace(/\r\n/g, "\n");
const block = "__label__\n" + rows.join("\n") + "\n";
if (cart.includes("__label__\n")) {
  const i = cart.indexOf("__label__\n");
  const rest = cart.slice(i + 10);
  const nx = rest.search(/^__[a-z]+__$/m);
  cart = cart.slice(0, i) + block + (nx < 0 ? "" : rest.slice(nx));
} else {
  // __label__ must sit between __gfx__ and the next section
  const i = cart.search(/^__(gff|map|sfx|music)__$/m);
  cart = cart.slice(0, i) + block + cart.slice(i);
}
fs.writeFileSync(CART, cart);
console.log("label set from shot '" + want + "'");
