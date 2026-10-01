// builds _kt.p8 = game.p8 with driver.lua appended to its __lua__ section.
// the harness must live next to the cart it copies.
const fs = require("fs");
const path = require("path");
const dir = path.join(__dirname, "..");
const cart = fs.readFileSync(path.join(dir, "game.p8"), "utf8").replace(/\r\n/g, "\n");
const i = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
if (i < 0) throw new Error("no asset section to splice before");
const driver = fs.readFileSync(path.join(__dirname, "driver.lua"), "utf8").replace(/\r\n/g, "\n");
fs.writeFileSync(path.join(dir, "_kt.p8"), cart.slice(0, i) + driver + "\n" + cart.slice(i));
console.log("wrote _kt.p8");
