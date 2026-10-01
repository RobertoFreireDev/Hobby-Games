// mkharness.js — writes _test.p8 = game.p8 with driver.lua appended to __lua__
const fs = require('fs');
const path = require('path');
const cart = fs.readFileSync(path.join(__dirname, 'game.p8'), 'utf8');
const i = cart.search(/^__(gfx|label|gff|map|sfx|music)__$/m);
const driver = fs.readFileSync(path.join(__dirname, 'driver.lua'), 'utf8');
fs.writeFileSync(path.join(__dirname, '_test.p8'), cart.slice(0, i) + driver + '\n' + cart.slice(i));
