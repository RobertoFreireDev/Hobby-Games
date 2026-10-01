// Rough PICO-8 token estimate for the cart's __lua__ section.
// PICO-8 counts each name / number / string / operator / keyword as one token;
// commas, dots, 'local', 'end' and comments are free. Close enough to tell how
// much of the 8192 budget is left — the editor is the authority.
const fs = require("fs");
const path = require("path");
const cart = fs.readFileSync(path.join(__dirname, "..", "game.p8"), "utf8").replace(/\r\n/g, "\n");
let lua = cart.split("__lua__\n")[1].split(/\n__[a-z]+__\n/)[0];
lua = lua.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

let n = 0;
const re = /"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|\b\d+(?:\.\d+)?\b|0x[0-9a-f]+|[A-Za-z_][A-Za-z_0-9]*|\.\.=|\.\.|[-+*/%^<>=~!#\\]=?|[(){}\[\];:]|==|!=/g;
const free = new Set(["local", "end", "then", "do"]);
let m;
while ((m = re.exec(lua))) {
  const t = m[0];
  if (t === "," || t === "." || t === ")" || t === "}" || t === "]" || t === ";") continue;
  if (free.has(t)) continue;
  n++;
}
console.log("approx tokens: " + n + " / 8192  (" + Math.round(n / 81.92) + "%)");
