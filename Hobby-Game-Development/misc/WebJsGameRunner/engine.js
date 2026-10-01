/* WebJsGameRunner — engine.
 *
 * Loader, api implementation, fixed-60Hz main loop. Game code lives in game.js
 * and only ever sees the `api` object built near the bottom of this file.
 * Keep API.md in sync with any change to the api surface.
 */
(function () {
"use strict";

/* Flip to false when shipping: api.log / api.assert become no-ops. */
var DEBUG = false;

/* ------------------------------------------------------------------ config -- */

var CFG    = (typeof ASSETS !== "undefined" && ASSETS) || {};
var SCREEN = CFG.screen || {};
var LW     = SCREEN.w | 0 || 640;          // logical width
var LH     = SCREEN.h | 0 || 360;          // logical height
var BG     = SCREEN.bg !== undefined ? SCREEN.bg : 0;
var STEP   = 1 / 60;                       // fixed update step, seconds
var MAX_STEPS = 5;                         // accumulator clamp
var VOICES = 32;                           // concurrent sfx

var PICO8 = [
  "#000000", "#1d2b53", "#7e2553", "#008751", "#ab5236", "#5f574f", "#c2c3c7", "#fff1e8",
  "#ff004d", "#ffa300", "#ffec27", "#00e436", "#29adff", "#83769c", "#ff77a8", "#ffccaa"
];
var PAL = CFG.palette && CFG.palette.length ? CFG.palette : PICO8;

var TEXT      = CFG.text || {};
var FONT_FAM  = TEXT.family || "monospace";
var FONT_SIZE = TEXT.size || 8;
var TEXT_COL  = TEXT.color !== undefined ? TEXT.color : 7;

/* ------------------------------------------------------------------ device -- */

/* Touch-primary device? The game uses it to swap in on-screen controls.
   `?mobile=1` / `?mobile=0` in the url forces it either way, for testing. */
function detectMobile() {
  var q = /[?&]mobile=([01])/.exec(location.search || "");
  if (q) return q[1] === "1";
  if (!((navigator.maxTouchPoints | 0) > 0 || "ontouchstart" in window)) return false;
  if (!window.matchMedia) return /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent || "");
  // a touchscreen laptop also has a mouse: fine pointer + hover means desktop
  if (window.matchMedia("(any-hover: hover)").matches &&
      window.matchMedia("(any-pointer: fine)").matches) return false;
  return window.matchMedia("(pointer: coarse)").matches;
}

var isMobile = detectMobile();

/* --------------------------------------------------------------------- dom -- */

var wrap    = document.getElementById("wrap");
var canvas  = document.getElementById("screen");
var elLoad  = document.getElementById("load");
var elBar   = elLoad ? elLoad.querySelector("i") : null;
var elStart = document.getElementById("start");
var elFail  = document.getElementById("fail");

canvas.width = LW;
canvas.height = LH;

/* The one and only 2D context. `ctx` is swapped to an offscreen canvas for the
   duration of api.prerender, which is why every primitive reads it lazily. */
var screenCtx = canvas.getContext("2d", { alpha: false });
var ctx = screenCtx;
screenCtx.imageSmoothingEnabled = false;
screenCtx.save();                          // base state; api.clip restores to it

/* ------------------------------------------------------------------ colors -- */

function col(c, fallback) {
  if (c === undefined || c === null) c = fallback;
  if (typeof c === "string") return c;
  var i = (c | 0) % PAL.length;
  if (i < 0) i += PAL.length;
  return PAL[i];
}

/* "#rgb" / "#rrggbb" / palette index -> 0xrrggbb, or -1 if it isn't a hex color.
   Only used by api.recolor, which needs the channels rather than a css string. */
function rgb24(c) {
  var s = col(c, 0);
  if (s.charAt(0) !== "#") return -1;
  if (s.length === 4) {
    s = "#" + s.charAt(1) + s.charAt(1) + s.charAt(2) + s.charAt(2) + s.charAt(3) + s.charAt(3);
  }
  if (s.length !== 7) return -1;
  var v = parseInt(s.slice(1), 16);
  return v === v ? v : -1;                 // NaN check without isNaN
}

/* ------------------------------------------------------------------ loading -- */

var images  = Object.create(null);   // name -> ImageBitmap | HTMLCanvasElement
var sounds  = Object.create(null);   // name -> AudioBuffer
var rawAudio = [];                   // [name, ArrayBuffer, url] until the first gesture
var warned  = Object.create(null);

function warnMissing(kind, name) {
  var k = kind + ":" + name;
  if (warned[k]) return;
  warned[k] = true;
  if (DEBUG) console.warn("[engine] unknown " + kind + ' "' + name + '"');
}

function get(url) {
  return fetch(url).then(function (r) {
    if (!r.ok) throw new Error(url + " — HTTP " + r.status);
    return r;
  }, function (e) {
    throw new Error(url + " — " + e.message);
  });
}

function loadImage(name, url) {
  return get(url).then(function (r) {
    return r.blob();
  }).then(function (blob) {
    return createImageBitmap(blob);      // fully decoded here: no first-draw hitch
  }).then(function (bmp) {
    images[name] = bmp;
  });
}

function loadAudio(name, url) {
  // Bytes now, decode after the first user gesture (the AudioContext only exists
  // from then on, so creating it here would trip the autoplay warning).
  return get(url).then(function (r) {
    return r.arrayBuffer();
  }).then(function (ab) {
    rawAudio.push(name, ab, url);
  });
}

function loadAll(onProgress) {
  var jobs = [];
  var imgs = CFG.images || {}, s = CFG.sfx || {}, m = CFG.music || {}, k;
  for (k in imgs) jobs.push(loadImage(k, imgs[k]));
  for (k in s)    jobs.push(loadAudio(k, s[k]));
  for (k in m)    jobs.push(loadAudio(k, m[k]));

  var done = 0, total = jobs.length;
  onProgress(total ? 0 : 1);
  for (var i = 0; i < jobs.length; i++) {
    jobs[i] = jobs[i].then(function () { onProgress(++done / total); });
  }
  return Promise.all(jobs);
}

/* ------------------------------------------------------------------- audio -- */

var actx = null, sfxBus = null, musBus = null, audioOk = false;

function initAudio() {
  var AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return false;
  try {
    actx = new AC();
  } catch (e) {
    if (DEBUG) console.warn("[engine] no audio: " + e.message);
    return false;
  }
  sfxBus = actx.createGain();
  musBus = actx.createGain();
  sfxBus.connect(actx.destination);
  musBus.connect(actx.destination);
  audioOk = true;
  initVoices();
  return true;
}

function decodeOne(ab) {
  return new Promise(function (res, rej) {
    // Safari only supports the callback form.
    var p = actx.decodeAudioData(ab, res, rej);
    if (p && p.then) p.then(res, rej);
  });
}

function decodeAllAudio() {
  if (!audioOk || !rawAudio.length) { rawAudio.length = 0; return Promise.resolve(); }
  var jobs = [];
  for (var i = 0; i < rawAudio.length; i += 3) {
    jobs.push((function (name, ab, url) {
      return decodeOne(ab).then(function (buf) {
        sounds[name] = buf;
      }, function (e) {
        throw new Error(url + " — could not decode (" + (e && e.message ? e.message : e) + ")");
      });
    })(rawAudio[i], rawAudio[i + 1], rawAudio[i + 2]));
  }
  return Promise.all(jobs).then(function () { rawAudio.length = 0; });
}

/* --------------------------------------------------------------------- sfx -- */

function Voice(slot) {
  this.slot = slot;
  this.gen = 0;
  this.gain = actx.createGain();
  this.panner = actx.createStereoPanner ? actx.createStereoPanner() : null;
  if (this.panner) { this.gain.connect(this.panner); this.panner.connect(sfxBus); }
  else this.gain.connect(sfxBus);

  this.src = null;
  this.buf = null;
  this.rate = 1;
  this.loop = false;
  this.startedAt = 0;
  this.offset = 0;
  this.active = false;
  this.paused = false;
  this.freeAt = 0;
  this.seq = 0;

  var self = this;
  this.onended = function (e) {                 // one closure per voice, not per play
    if (self.src === e.target) { self.active = false; self.paused = false; self.src = null; }
  };
}

var voices = null, voiceSeq = 0;

function initVoices() {
  voices = new Array(VOICES);
  for (var i = 0; i < VOICES; i++) voices[i] = new Voice(i);
}

function hardStop(v) {
  if (v.src) {
    v.src.onended = null;
    try { v.src.stop(); } catch (e) { /* not started / already stopped */ }
    v.src = null;
  }
  v.active = false;
  v.paused = false;
}

function pickVoice() {
  var now = actx.currentTime, i, v, oldest = null;
  for (i = 0; i < VOICES; i++) {
    v = voices[i];
    if (!v.active && now >= v.freeAt) return v;
  }
  for (i = 0; i < VOICES; i++) {                // all busy: recycle the oldest
    v = voices[i];
    if (!oldest || v.seq < oldest.seq) oldest = v;
  }
  hardStop(oldest);
  return oldest;
}

function voiceOf(id) {
  if (typeof id !== "number" || id < 0 || !voices) return null;
  var v = voices[id % VOICES];
  return v && v.gen === ((id / VOICES) | 0) ? v : null;
}

function startVoice(v, offset) {
  var src = actx.createBufferSource();
  src.buffer = v.buf;
  src.loop = v.loop;
  src.playbackRate.value = v.rate;
  src.connect(v.gain);
  src.onended = v.onended;
  src.start(0, offset);
  v.src = src;
  v.startedAt = actx.currentTime;
  v.active = true;
  v.paused = false;
}

function stopVoice(v) {
  if (!v.src) { hardStop(v); return; }
  var now = actx.currentTime, g = v.gain.gain, src = v.src;
  g.cancelScheduledValues(now);
  g.setValueAtTime(g.value, now);
  g.linearRampToValueAtTime(0, now + 0.012);    // short ramp: no click on stop
  src.onended = null;
  try { src.stop(now + 0.02); } catch (e) { /* already stopped */ }
  v.src = null;
  v.active = false;
  v.paused = false;
  v.freeAt = now + 0.03;                        // hold the slot until the ramp ends
}

function elapsedOf(v) {
  var e = v.offset + (actx.currentTime - v.startedAt) * v.rate;
  var d = v.buf ? v.buf.duration : 0;
  if (v.loop && d > 0) e %= d;
  return e;
}

/* ------------------------------------------------------------------- music -- */

var mus = {
  name: null, src: null, gain: null, buf: null,
  vol: 1, loop: true, startedAt: 0, offset: 0, paused: false
};

function musStop(fade) {
  if (!mus.gain) { mus.name = null; return; }
  var now = actx.currentTime, g = mus.gain, src = mus.src;
  var t = fade > 0 ? fade : 0.02;
  g.gain.cancelScheduledValues(now);
  g.gain.setValueAtTime(g.gain.value, now);
  g.gain.linearRampToValueAtTime(0, now + t);
  if (src) {
    src.onended = null;
    try { src.stop(now + t + 0.02); } catch (e) { /* already stopped */ }
  }
  setTimeout(function () { try { g.disconnect(); } catch (e) {} }, (t + 0.15) * 1000);
  mus.src = null;
  mus.gain = null;
  mus.buf = null;
  mus.name = null;
  mus.paused = false;
}

function musStart(offset, fade) {
  var now = actx.currentTime;
  var src = actx.createBufferSource();
  src.buffer = mus.buf;
  src.loop = mus.loop;
  src.connect(mus.gain);
  src.onended = function () { if (mus.src === src && !mus.paused) mus.name = null; };
  src.start(0, offset);
  mus.src = src;
  mus.startedAt = now;
  mus.paused = false;
  mus.gain.gain.cancelScheduledValues(now);
  if (fade > 0) {
    mus.gain.gain.setValueAtTime(0, now);
    mus.gain.gain.linearRampToValueAtTime(mus.vol, now + fade);
  } else {
    mus.gain.gain.setValueAtTime(mus.vol, now);
  }
}

/* ------------------------------------------------------------------- input -- */

var BTNS = 9;                                   // 0..7 + 8 = start/enter

var KEYCODE = {
  ArrowLeft: 0, ArrowRight: 1, ArrowUp: 2, ArrowDown: 3,
  KeyZ: 4, KeyX: 5, KeyC: 6, KeyV: 7, Enter: 8, NumpadEnter: 8
};
var KEYNAME = {                                 // fallback when e.code is missing
  arrowleft: 0, arrowright: 1, arrowup: 2, arrowdown: 3,
  z: 4, x: 5, c: 6, v: 7, enter: 8
};
var SWALLOW = {
  ArrowLeft: 1, ArrowRight: 1, ArrowUp: 1, ArrowDown: 1,
  Space: 1, KeyZ: 1, KeyX: 1, KeyC: 1, KeyV: 1, Enter: 1, NumpadEnter: 1
};

var bHeld = new Uint8Array(BTNS);  // live physical state
/* bDownE/bUpE are *counts* of down/up transitions queued since the last one
   was drained, not a single sticky bit. A fixed update step can only ever
   report one press, so if the page's frame rate drops (CPU spike, GC pause,
   a busy wave-turn frame) enough that two real key taps land between two
   consecutive steps, a plain 0/1 flag can only remember the more recent one
   — the other tap is gone for good, which reads to a player as "I pressed
   fire and nothing happened". Draining one count per step instead means a
   pile-up of real presses is spread across the next several steps as soon as
   the sim catches up, rather than being silently collapsed into one. */
var bDownE = new Uint8Array(BTNS);
var bUpE = new Uint8Array(BTNS);
var bDown = new Uint8Array(BTNS);  // what btn/btnp/btnr report this update
var bPress = new Uint8Array(BTNS);
var bRel = new Uint8Array(BTNS);

var mHeld = new Uint8Array(3), mDownE = new Uint8Array(3), mUpE = new Uint8Array(3); // also counts, same reason
var mDown = new Uint8Array(3), mPress = new Uint8Array(3), mRel = new Uint8Array(3);
var mouseX = LW >> 1, mouseY = LH >> 1, mouseIn = false;
var wheelAcc = 0, wheelNow = 0;

/* Touch points. The mouse api only ever tracks one pointer; on-screen controls
   need several at once (steer + fire), so live touches get their own slots and
   are compacted into a snapshot once per update. */
var MAX_TOUCH = 10;
var tId = new Int32Array(MAX_TOUCH);                     // live pointerId, -1 = free
var tLX = new Float32Array(MAX_TOUCH), tLY = new Float32Array(MAX_TOUCH);
var tX = new Float32Array(MAX_TOUCH), tY = new Float32Array(MAX_TOUCH);
var tSId = new Int32Array(MAX_TOUCH);                    // id of each snapshot slot
var tN = 0;                                              // touches in the snapshot
tId.fill(-1);

function touchSlot(id) {
  for (var i = 0; i < MAX_TOUCH; i++) if (tId[i] === id) return i;
  return -1;
}

function touchDown(e) {
  var i = touchSlot(e.pointerId);
  if (i < 0) i = touchSlot(-1);
  if (i < 0) return;                                     // more fingers than slots
  tId[i] = e.pointerId;
  tLX[i] = lx;
  tLY[i] = ly;
}

function touchMove(e) {
  var i = touchSlot(e.pointerId);
  if (i < 0) return;
  tLX[i] = lx;
  tLY[i] = ly;
}

function touchUp(e) {
  var i = touchSlot(e.pointerId);
  if (i >= 0) tId[i] = -1;
}

function clearTouches() { tId.fill(-1); }

function btnIndex(e) {
  var i = KEYCODE[e.code];
  if (i === undefined && e.key) i = KEYNAME[String(e.key).toLowerCase()];
  return i === undefined ? -1 : i;
}

function onKeyDown(e) {
  if (SWALLOW[e.code]) e.preventDefault();
  var i = btnIndex(e);
  if (i < 0 || e.repeat) return;
  bHeld[i] = 1;
  if (bDownE[i] < 255) bDownE[i]++;                // queue the edge, don't just flag it
}

function onKeyUp(e) {
  if (SWALLOW[e.code]) e.preventDefault();
  var i = btnIndex(e);
  if (i < 0) return;
  bHeld[i] = 0;
  if (bUpE[i] < 255) bUpE[i]++;
}

function clearHeld() {                          // blur / tab-out: no stuck keys
  var i;
  for (i = 0; i < BTNS; i++) { if (bHeld[i] && bUpE[i] < 255) bUpE[i]++; bHeld[i] = 0; }
  for (i = 0; i < 3; i++) { if (mHeld[i] && mUpE[i] < 255) mUpE[i]++; mHeld[i] = 0; }
  clearTouches();
}

function resetInput() {                         // hard wipe, edges included
  bHeld.fill(0); bDownE.fill(0); bUpE.fill(0);
  bDown.fill(0); bPress.fill(0); bRel.fill(0);
  mHeld.fill(0); mDownE.fill(0); mUpE.fill(0);
  mDown.fill(0); mPress.fill(0); mRel.fill(0);
  clearTouches();
  tN = 0;
  wheelAcc = 0; wheelNow = 0;
}

var lx = 0, ly = 0;                             // scratch for toLogical

function toLogical(e) {
  // never cache the rect: itch's fullscreen button resizes the iframe under us
  var r = canvas.getBoundingClientRect();
  if (r.width <= 0 || r.height <= 0) return false;
  var x = (e.clientX - r.left) * (LW / r.width);
  var y = (e.clientY - r.top) * (LH / r.height);
  lx = x < 0 ? 0 : x > LW - 1 ? LW - 1 : x;
  ly = y < 0 ? 0 : y > LH - 1 ? LH - 1 : y;
  return true;
}

function updateMouse(e) {
  if (!toLogical(e)) return;
  mouseX = lx;
  mouseY = ly;
}

function sampleInput() {
  var i;
  tN = 0;
  for (i = 0; i < MAX_TOUCH; i++) {
    if (tId[i] < 0) continue;
    tX[tN] = tLX[i];
    tY[tN] = tLY[i];
    tSId[tN] = tId[i];
    tN++;
  }
  // drain at most one queued edge per button per step — any extra queued
  // presses stay banked in bDownE/bUpE for the *next* step to drain, instead
  // of every pending count being flattened into "happened at least once" and
  // then wiped by endInput() regardless of how many taps it actually stood for
  for (i = 0; i < BTNS; i++) {
    if (bDownE[i] > 0) { bPress[i] = 1; bDownE[i]--; } else bPress[i] = 0;
    if (bUpE[i] > 0) { bRel[i] = 1; bUpE[i]--; } else bRel[i] = 0;
    bDown[i] = bHeld[i] | bPress[i];
  }
  for (i = 0; i < 3; i++) {
    if (mDownE[i] > 0) { mPress[i] = 1; mDownE[i]--; } else mPress[i] = 0;
    if (mUpE[i] > 0) { mRel[i] = 1; mUpE[i]--; } else mRel[i] = 0;
    mDown[i] = mHeld[i] | mPress[i];
  }
  wheelNow = wheelAcc;
}

function endInput() {
  // bDownE/bUpE/mDownE/mUpE are no longer cleared here: sampleInput() above
  // already drained exactly the one edge this step reports, one count at a
  // time, and whatever's left over is next step's to drain.
  wheelAcc = 0;
}

/* ------------------------------------------------------------------- scale -- */

function rescale() {
  var cw = wrap.clientWidth, ch = wrap.clientHeight;
  if (cw <= 0 || ch <= 0) return;
  var s = Math.min(cw / LW, ch / LH);
  s = s >= 1 ? Math.floor(s) : s;                // integer scale whenever it fits
  canvas.style.width = (LW * s) + "px";
  canvas.style.height = (LH * s) + "px";
}

/* -------------------------------------------------------------- draw state -- */

var camX = 0, camY = 0;
var fontFam = FONT_FAM, fontSize = FONT_SIZE, fontStr = FONT_SIZE + "px " + FONT_FAM;
var lineH = FONT_SIZE, textCol = TEXT_COL, alignH = "left", alignV = "top";

function baselineFor(v) {
  return v === "middle" ? "middle" : v === "bottom" ? "bottom" : "top";
}

function syncTextState() {                       // after any save/restore of ctx
  ctx.font = fontStr;
  ctx.textAlign = alignH;
  ctx.textBaseline = baselineFor(alignV);
  ctx.imageSmoothingEnabled = false;
}

function applyFont() {
  fontStr = fontSize + "px " + fontFam;
  ctx.font = fontStr;
  var m = ctx.measureText("Mg");
  lineH = (m.fontBoundingBoxAscent !== undefined && m.fontBoundingBoxDescent !== undefined)
    ? Math.ceil(m.fontBoundingBoxAscent + m.fontBoundingBoxDescent)
    : Math.ceil(fontSize * 1.25);
}

/* -------------------------------------------------------------- primitives -- */

function pset(x, y, c) {
  ctx.fillStyle = col(c, textCol);
  ctx.fillRect(Math.floor(x - camX), Math.floor(y - camY), 1, 1);
}

function line(x0, y0, x1, y1, c) {               // Bresenham: crisp at any angle
  ctx.fillStyle = col(c, textCol);
  var ax = Math.floor(x0 - camX), ay = Math.floor(y0 - camY);
  var bx = Math.floor(x1 - camX), by = Math.floor(y1 - camY);
  var dx = Math.abs(bx - ax), dy = -Math.abs(by - ay);
  var sx = ax < bx ? 1 : -1, sy = ay < by ? 1 : -1;
  var err = dx + dy, e2;
  for (;;) {
    ctx.fillRect(ax, ay, 1, 1);
    if (ax === bx && ay === by) break;
    e2 = err * 2;
    if (e2 >= dy) { err += dy; ax += sx; }
    if (e2 <= dx) { err += dx; ay += sy; }
  }
}

function rectfill(x, y, w, h, c) {
  ctx.fillStyle = col(c, textCol);
  ctx.fillRect(Math.floor(x - camX), Math.floor(y - camY), Math.round(w), Math.round(h));
}

function rect(x, y, w, h, c) {
  var X = Math.floor(x - camX), Y = Math.floor(y - camY);
  var W = Math.round(w), H = Math.round(h);
  if (W <= 0 || H <= 0) return;
  ctx.fillStyle = col(c, textCol);
  ctx.fillRect(X, Y, W, 1);
  if (H > 1) ctx.fillRect(X, Y + H - 1, W, 1);
  if (H > 2) {
    ctx.fillRect(X, Y + 1, 1, H - 2);
    if (W > 1) ctx.fillRect(X + W - 1, Y + 1, 1, H - 2);
  }
}

/* Ellipse inscribed in the box, scanline filled (one fillRect per row).
   `hollow` subtracts the ellipse one pixel smaller to leave a 1px outline. */
function ellipse(x, y, w, h, c, hollow) {
  if (w <= 0 || h <= 0) return;
  var X = x - camX, Y = y - camY;
  var rx = w / 2, ry = h / 2, cx = X + rx, cy = Y + ry;
  var irx = rx - 1, iry = ry - 1;
  var y0 = Math.floor(Y), y1 = Math.ceil(Y + h), py, dy, hw, ox0, ox1, idy, ihw, ix0, ix1;
  ctx.fillStyle = col(c, textCol);
  for (py = y0; py < y1; py++) {
    dy = (py + 0.5 - cy) / ry;
    if (dy < -1 || dy > 1) continue;
    hw = rx * Math.sqrt(1 - dy * dy);
    ox0 = Math.round(cx - hw);
    ox1 = Math.round(cx + hw);
    if (ox1 <= ox0) ox1 = ox0 + 1;
    if (!hollow || irx <= 0 || iry <= 0) { ctx.fillRect(ox0, py, ox1 - ox0, 1); continue; }
    idy = (py + 0.5 - cy) / iry;
    if (idy < -1 || idy > 1) { ctx.fillRect(ox0, py, ox1 - ox0, 1); continue; }
    ihw = irx * Math.sqrt(1 - idy * idy);
    ix0 = Math.round(cx - ihw);
    ix1 = Math.round(cx + ihw);
    if (ix0 <= ox0 && ix1 >= ox1) { ctx.fillRect(ox0, py, ox1 - ox0, 1); continue; }
    if (ix0 > ox0) ctx.fillRect(ox0, py, ix0 - ox0, 1);
    if (ox1 > ix1) ctx.fillRect(ix1, py, ox1 - ix1, 1);
  }
}

function blit(img, sx, sy, sw, sh, dx, dy, dw, dh, o) {
  dx -= camX; dy -= camY;
  var a = 1, rot = 0, fx = false, fy = false;
  if (o) {
    if (o.a !== undefined) a = o.a;
    if (o.rot) rot = o.rot;
    fx = !!o.fx; fy = !!o.fy;
  }
  if (a <= 0) return;
  if (a !== 1) ctx.globalAlpha = a;
  if (rot !== 0 || fx || fy) {
    var hw = dw / 2, hh = dh / 2;
    ctx.translate(dx + hw, dy + hh);
    if (rot !== 0) ctx.rotate(rot);
    if (fx || fy) ctx.scale(fx ? -1 : 1, fy ? -1 : 1);
    ctx.drawImage(img, sx, sy, sw, sh, -hw, -hh, dw, dh);
    ctx.setTransform(1, 0, 0, 1, 0, 0);
  } else {
    ctx.drawImage(img, sx, sy, sw, sh, dx, dy, dw, dh);
  }
  if (a !== 1) ctx.globalAlpha = 1;
}

/* --------------------------------------------------------------------- rng -- */

var rndState = (Math.random() * 0xffffffff) >>> 0 || 1;

function rnd32() {                               // xorshift32, allocation free
  var x = rndState;
  x ^= x << 13; x >>>= 0;
  x ^= x >>> 17;
  x ^= x << 5;  x >>>= 0;
  rndState = x;
  return x / 4294967296;
}

/* --------------------------------------------------------------------- api -- */

var updates = 0, fpsVal = 0;

var api = {
  /* system */
  w: function () { return LW; },
  h: function () { return LH; },
  dt: function () { return STEP; },
  time: function () { return updates * STEP; },
  frame: function () { return updates; },
  fps: function () { return fpsVal; },
  mobile: function () { return isMobile; },

  /* clearing and framing */
  cls: function (c) {
    ctx.fillStyle = col(c, BG);
    ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
  },
  camera: function (x, y) {
    camX = x === undefined ? 0 : Math.round(x);
    camY = y === undefined ? 0 : Math.round(y);
  },
  clip: function (x, y, w, h) {
    ctx.restore();                               // drop the previous clip
    ctx.save();
    syncTextState();
    if (x === undefined) return;
    ctx.beginPath();
    ctx.rect(Math.floor(x), Math.floor(y), Math.round(w), Math.round(h));
    ctx.clip();
  },

  /* sprites */
  spr: function (name, x, y, o) {
    var img = images[name];
    if (!img) { warnMissing("image", name); return; }
    blit(img, 0, 0, img.width, img.height, x, y, img.width, img.height, o);
  },
  sspr: function (name, sx, sy, sw, sh, dx, dy, dw, dh, o) {
    var img = images[name];
    if (!img) { warnMissing("image", name); return; }
    if (dw === undefined || dw === null) dw = sw;
    if (dh === undefined || dh === null) dh = sh;
    blit(img, sx, sy, sw, sh, dx, dy, dw, dh, o);
  },
  recolor: function (name, src, sx, sy, sw, sh, from, to) {
    var img = images[src];
    if (!img) { warnMissing("image", src); return name; }
    var f = Array.isArray(from) ? from : [from];
    var t = Array.isArray(to) ? to : [to];
    var n = f.length, k, v;
    var fr = new Uint8Array(n), fg = new Uint8Array(n), fb = new Uint8Array(n);
    var tr = new Uint8Array(n), tg = new Uint8Array(n), tb = new Uint8Array(n);
    for (k = 0; k < n; k++) {
      v = rgb24(f[k]);
      if (v < 0) { if (DEBUG) console.warn("[engine] recolor: bad color", f[k]); return name; }
      fr[k] = v >> 16; fg[k] = (v >> 8) & 255; fb[k] = v & 255;
      v = rgb24(t[k % t.length]);
      if (v < 0) { if (DEBUG) console.warn("[engine] recolor: bad color", t[k % t.length]); return name; }
      tr[k] = v >> 16; tg[k] = (v >> 8) & 255; tb[k] = v & 255;
    }

    var c = document.createElement("canvas");
    c.width = Math.max(1, sw | 0);
    c.height = Math.max(1, sh | 0);
    var g = c.getContext("2d", { willReadFrequently: true });
    g.imageSmoothingEnabled = false;
    g.drawImage(img, sx, sy, sw, sh, 0, 0, c.width, c.height);

    var dat = g.getImageData(0, 0, c.width, c.height);
    var d = dat.data, i, dr, dg, db;
    for (i = 0; i < d.length; i += 4) {
      if (d[i + 3] === 0) continue;                // leave fully transparent pixels
      for (k = 0; k < n; k++) {
        dr = d[i] - fr[k]; if (dr < 0) dr = -dr; if (dr > 8) continue;
        dg = d[i + 1] - fg[k]; if (dg < 0) dg = -dg; if (dg > 8) continue;
        db = d[i + 2] - fb[k]; if (db < 0) db = -db; if (db > 8) continue;
        d[i] = tr[k]; d[i + 1] = tg[k]; d[i + 2] = tb[k];
        break;                                     // first match wins
      }
    }
    g.putImageData(dat, 0, 0);
    images[name] = c;
    return name;
  },
  prerender: function (name, w, h, fn) {
    var c = document.createElement("canvas");
    c.width = Math.max(1, w | 0);
    c.height = Math.max(1, h | 0);
    var prevCtx = ctx, prevX = camX, prevY = camY;
    ctx = c.getContext("2d");
    camX = 0; camY = 0;
    ctx.save();                                  // base state for api.clip
    syncTextState();
    try {
      fn(api);
    } finally {
      ctx = prevCtx;
      camX = prevX;
      camY = prevY;
      syncTextState();      // fn may have left align/font set on the offscreen ctx
    }
    images[name] = c;
    return name;
  },

  /* shapes */
  pset: pset,
  line: line,
  rect: rect,
  rectfill: rectfill,
  circ: function (x, y, r, c) { ellipse(x - r, y - r, r + r, r + r, c, true); },
  circfill: function (x, y, r, c) { ellipse(x - r, y - r, r + r, r + r, c, false); },
  oval: function (x, y, w, h, c) { ellipse(x, y, w, h, c, true); },
  ovalfill: function (x, y, w, h, c) { ellipse(x, y, w, h, c, false); },

  /* text */
  print: function (s, x, y, c, size) {
    var swap = size !== undefined && size !== fontSize;
    ctx.font = swap ? size + "px " + fontFam : fontStr;
    ctx.fillStyle = col(c, textCol);
    ctx.fillText(s, Math.round(x - camX), Math.round(y - camY));
    if (swap) ctx.font = fontStr;
  },
  font: function (family, size) {
    if (family === undefined && size === undefined) {
      fontFam = FONT_FAM;
      fontSize = FONT_SIZE;
    } else {
      if (family !== undefined) fontFam = family;
      if (size !== undefined) fontSize = size;
    }
    applyFont();
  },
  text_color: function (c) { textCol = c; },
  text_align: function (hAlign, vAlign) {
    alignH = hAlign || "left";
    alignV = vAlign || "top";
    ctx.textAlign = alignH;
    ctx.textBaseline = baselineFor(alignV);
  },
  text_width: function (s) {
    ctx.font = fontStr;
    return ctx.measureText(s).width;
  },
  text_height: function () { return lineH; },

  /* sfx */
  sfx: function (name, o) {
    if (!audioOk) return -1;
    var buf = sounds[name];
    if (!buf) { warnMissing("sfx", name); return -1; }

    var v = pickVoice();
    v.gen = (v.gen + 1) & 0xffff;
    v.buf = buf;
    v.rate = o && o.rate !== undefined ? o.rate : 1;
    v.loop = !!(o && o.loop);
    v.offset = 0;
    v.seq = ++voiceSeq;

    var now = actx.currentTime, g = v.gain.gain;
    g.cancelScheduledValues(now);
    g.setValueAtTime(o && o.vol !== undefined ? o.vol : 1, now);
    if (v.panner) v.panner.pan.value = o && o.pan !== undefined ? o.pan : 0;

    startVoice(v, 0);
    return v.gen * VOICES + v.slot;
  },
  sfx_stop: function (id) {
    if (!audioOk) return;
    if (id === undefined) {
      for (var i = 0; i < VOICES; i++) stopVoice(voices[i]);
      return;
    }
    var v = voiceOf(id);
    if (v) stopVoice(v);
  },
  sfx_pause: function (id) {
    if (!audioOk) return;
    var v = voiceOf(id);
    if (!v || !v.active || v.paused || !v.src) return;
    v.offset = elapsedOf(v);
    v.src.onended = null;
    try { v.src.stop(); } catch (e) { /* already stopped */ }
    v.src = null;
    v.paused = true;
  },
  sfx_resume: function (id) {
    if (!audioOk) return;
    var v = voiceOf(id);
    if (!v || !v.paused) return;
    startVoice(v, v.offset);
  },
  sfx_playing: function (id) {
    if (!audioOk) return false;
    var v = voiceOf(id);
    return !!v && v.active && !v.paused;
  },
  sfx_vol: function (v) { if (audioOk) sfxBus.gain.value = v < 0 ? 0 : v; },

  /* music */
  music: function (name, o) {
    if (!audioOk) return;
    var buf = sounds[name];
    if (!buf) { warnMissing("music", name); return; }
    var fade = o && o.fade ? o.fade : 0;

    /* sync: keep the playhead where it is instead of restarting at 0. Tracks cut
       from the same grid (same length, tempo and chords) then swap mid-loop
       without losing the beat — an arrangement change, not a new song. */
    var at = 0, held = false;
    if (o && o.sync && mus.buf && buf.duration > 0) {
      at = mus.paused ? mus.offset : mus.offset + (actx.currentTime - mus.startedAt);
      at %= buf.duration;
      held = mus.paused;                         // swapped while paused: stay paused
    }

    if (mus.gain) musStop(fade);                 // crossfade when fading, else cut
    mus.buf = buf;
    mus.name = name;
    mus.vol = o && o.vol !== undefined ? o.vol : 1;
    mus.loop = !(o && o.loop === false);
    mus.offset = at;
    mus.gain = actx.createGain();
    mus.gain.gain.value = 0;
    mus.gain.connect(musBus);
    if (held) { mus.paused = true; return; }     // music_resume() picks it up there
    musStart(at, fade);
  },
  music_stop: function (fade) { if (audioOk) musStop(fade); },
  music_pause: function () {
    if (!audioOk || !mus.src || mus.paused) return;
    var e = mus.offset + (actx.currentTime - mus.startedAt);
    if (mus.loop && mus.buf.duration > 0) e %= mus.buf.duration;
    mus.offset = e;
    mus.src.onended = null;
    try { mus.src.stop(); } catch (err) { /* already stopped */ }
    mus.src = null;
    mus.paused = true;
  },
  music_resume: function () {
    if (!audioOk || !mus.paused || !mus.buf) return;
    musStart(mus.offset, 0);
  },
  music_playing: function () { return mus.name; },
  music_vol: function (v) { if (audioOk) musBus.gain.value = v < 0 ? 0 : v; },

  /* input */
  btn: function (i) { return bDown[i] === 1; },
  btnp: function (i) { return bPress[i] === 1; },
  btnr: function (i) { return bRel[i] === 1; },
  start: function () { return bDown[8] === 1; },      // button 8, Enter
  startp: function () { return bPress[8] === 1; },
  startr: function () { return bRel[8] === 1; },
  mx: function () { return mouseX; },
  my: function () { return mouseY; },
  mbtn: function (b) { return mDown[b] === 1; },
  mbtnp: function (b) { return mPress[b] === 1; },
  mbtnr: function (b) { return mRel[b] === 1; },
  mwheel: function () { return wheelNow; },
  mouse_over: function () { return mouseIn; },
  touches: function () { return tN; },
  touch_x: function (i) { return i >= 0 && i < tN ? tX[i] : -1; },
  touch_y: function (i) { return i >= 0 && i < tN ? tY[i] : -1; },
  touch_id: function (i) { return i >= 0 && i < tN ? tSId[i] : -1; },

  /* math */
  flr: Math.floor,
  ceil: Math.ceil,
  round: Math.round,
  abs: Math.abs,
  sgn: function (x) { return x < 0 ? -1 : 1; },
  sqrt: Math.sqrt,
  min: Math.min,
  max: Math.max,
  mid: function (a, b, c) {
    return a > b ? (a < c ? a : b > c ? b : c) : (b < c ? b : a > c ? a : c);
  },
  sin: Math.sin,
  cos: Math.cos,
  atan2: Math.atan2,
  lerp: function (a, b, t) { return a + (b - a) * t; },
  rnd: function (n) { return rnd32() * (n === undefined ? 1 : n); },
  rndi: function (n) { return Math.floor(rnd32() * n); },
  srand: function (seed) { rndState = (seed >>> 0) || 1; },
  dist: function (x0, y0, x1, y1) { return Math.hypot(x1 - x0, y1 - y0); },
  overlap: function (x0, y0, w0, h0, x1, y1, w1, h1) {
    return x0 < x1 + w1 && x1 < x0 + w0 && y0 < y1 + h1 && y1 < y0 + h0;
  },

  /* debug */
  log: function () { if (DEBUG) console.log.apply(console, arguments); },
  assert: function (cond, msg) {
    if (DEBUG && !cond) throw new Error("assert: " + (msg || "failed"));
  }
};
Object.freeze(api);

/* -------------------------------------------------------------------- loop -- */

var gInit = null, gUpdate = null, gDraw = null;
var raf = 0, running = false, started = false;
var lastTime = 0, acc = 0, fpsFrames = 0, fpsSince = 0;

function frame(now) {
  raf = requestAnimationFrame(frame);

  var ms = now - lastTime;
  lastTime = now;
  if (ms < 0) ms = 0;
  if (ms > 250) ms = 250;                        // returning tab: clamp dt
  acc += ms / 1000;

  var steps = 0;
  while (acc >= STEP && steps < MAX_STEPS) {
    sampleInput();
    if (gUpdate) gUpdate(api);
    endInput();
    acc -= STEP;
    steps++;
    updates++;
  }
  if (steps === MAX_STEPS) acc = 0;              // a stalled tab can't spiral

  ctx.setTransform(1, 0, 0, 1, 0, 0);
  gDraw(api);

  fpsFrames++;
  if (now - fpsSince >= 500) {
    fpsVal = Math.round(fpsFrames * 1000 / (now - fpsSince));
    fpsFrames = 0;
    fpsSince = now;
  }
}

function startLoop() {
  if (running) return;
  running = true;
  lastTime = performance.now();
  fpsSince = lastTime;
  fpsFrames = 0;
  acc = 0;
  raf = requestAnimationFrame(frame);
}

function stopLoop() {
  if (!running) return;
  running = false;
  cancelAnimationFrame(raf);
  raf = 0;
}

/* -------------------------------------------------------------------- boot -- */

function fail(msg) {
  stopLoop();
  if (elLoad) elLoad.hidden = true;
  if (elStart) elStart.hidden = true;
  if (elFail) {
    elFail.hidden = false;
    elFail.textContent = msg;
  }
  console.error("[engine] " + msg);
}

function bindEvents() {
  window.addEventListener("keydown", onKeyDown, { passive: false });
  window.addEventListener("keyup", onKeyUp, { passive: false });
  window.addEventListener("blur", clearHeld);

  canvas.addEventListener("contextmenu", function (e) { e.preventDefault(); });
  canvas.addEventListener("pointerdown", function (e) {
    canvas.focus();                              // keyboard only reaches a focused iframe
    updateMouse(e);
    if (e.pointerType === "touch") touchDown(e);
    if (e.button >= 0 && e.button < 3) { mHeld[e.button] = 1; if (mDownE[e.button] < 255) mDownE[e.button]++; }
    e.preventDefault();
  });
  window.addEventListener("pointerup", function (e) {
    updateMouse(e);
    if (e.pointerType === "touch") touchUp(e);
    if (e.button >= 0 && e.button < 3) { mHeld[e.button] = 0; if (mUpE[e.button] < 255) mUpE[e.button]++; }
  });
  window.addEventListener("pointercancel", function (e) {
    if (e.pointerType === "touch") touchUp(e);
    clearHeld();
  });
  canvas.addEventListener("pointermove", function (e) {
    updateMouse(e);
    if (e.pointerType === "touch") touchMove(e);  // implicit capture: still ours off-canvas
  });
  canvas.addEventListener("pointerenter", function (e) { mouseIn = true; updateMouse(e); });
  canvas.addEventListener("pointerleave", function () { mouseIn = false; });
  canvas.addEventListener("wheel", function (e) {
    wheelAcc += e.deltaY;
    e.preventDefault();
  }, { passive: false });

  document.addEventListener("visibilitychange", function () {
    if (!started) return;
    if (document.hidden) {
      stopLoop();
      clearHeld();
      if (audioOk) actx.suspend();
    } else {
      if (audioOk) actx.resume();
      startLoop();
    }
  });

  if (window.ResizeObserver) new ResizeObserver(rescale).observe(wrap);
  else window.addEventListener("resize", rescale);
}

function run() {
  applyFont();
  syncTextState();
  started = true;
  resetInput();          // the key that dismissed the overlay must not reach update()
  try {
    if (gInit) gInit(api);
  } catch (e) {
    fail("init() threw:\n" + (e && e.stack ? e.stack : e));
    return;
  }
  startLoop();
}

function begin() {
  if (elStart) elStart.hidden = true;
  canvas.focus();
  // Created inside the gesture, so the context starts running and the browser
  // never logs an autoplay warning. resume() covers the stricter policies.
  if (initAudio() && actx.state !== "running") actx.resume();
  decodeAllAudio().then(run, function (e) {
    fail("failed to decode " + (e && e.message ? e.message : e));
  });
}

function waitForGesture() {
  if (elStart) elStart.hidden = false;
  function go(e) {
    if (e.type === "keydown" && !(e.code === "Space" || e.code === "Enter" || btnIndex(e) >= 0)) return;
    window.removeEventListener("pointerdown", go, true);
    window.removeEventListener("keydown", go, true);
    begin();
  }
  window.addEventListener("pointerdown", go, true);
  window.addEventListener("keydown", go, true);
}

function boot() {
  gInit = typeof window.init === "function" ? window.init : null;
  gUpdate = typeof window.update === "function" ? window.update : null;
  gDraw = typeof window.draw === "function" ? window.draw : null;
  if (!gDraw) { fail("game.js must define draw(api)"); return; }

  if (isMobile) document.documentElement.className += " touch";   // overlay copy
  rescale();
  bindEvents();

  loadAll(function (p) {
    if (elBar) elBar.style.width = Math.round(p * 100) + "%";
  }).then(function () {
    if (elLoad) elLoad.hidden = true;
    waitForGesture();
  }, function (e) {
    fail("failed to load " + (e && e.message ? e.message : e) +
      "\n\nassets must be served over http — file:// blocks fetch.");
  });
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", boot);
} else {
  boot();
}

})();
