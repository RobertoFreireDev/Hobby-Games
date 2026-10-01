/* Stardust Run — the demo game.
 *
 * Touches nothing but the `api` object passed into init/update/draw.
 * Everything is allocated in init(); update/draw allocate nothing.
 */

/* ------------------------------------------------------------------ tuning -- */

var TILE = 16;                     // sprite sheet cell
var SP_SHIP = 0, SP_COIN = 1, SP_HEART = 3, SP_SPARK = 4;   // cell 2 is unused

var FIELD_TOP = 24;                // HUD strip height
var ACC = 0.55, FRIC = 0.86, MAXV = 3.4;
var INVULN = 96;
var PULSE_SPEED = 7, PULSE_MAX = 130, PULSE_BAND = 14;
var COIN_MAX = 10, FOE_MAX = 48, SPARK_MAX = 128;

/* ---- run stats ----
   ACC / MAXV / PULSE_MAX above are the *reference* ship, not the one that flies.
   A run starts deliberately under it — about half speed, under half the pulse
   reach — and is built back up (past it) one wave at a time by the upgrade picked
   between waves. Everything an upgrade touches lives here, and restart() is the
   only thing that resets it, so a run is the only place progress exists. */
var SPD_BASE = 0.4, SPD_STEP = 0.1;        // 30% slower still off the line, +10% a pick
var RANGE_BASE = 0.40, RANGE_STEP = 0.05;    // pulse reach cut a further 5%, +5% a pick
var LIVES_BASE = 2;                         // and the run opens on full health
var CHARGE_BASE = 2, CHARGE_CAP_BASE = 2;

/* Foes keep their own personal space: any two closer than this get pushed apart,
   so a squad spreads into a loose swarm around the player instead of stacking
   into one sprite. Two cells centre to centre — a whole empty enemy's worth of
   gap between neighbours, enough that the crowd stays countable at a glance. */
var FOE_SEP = TILE * 2, FOE_SEP2 = FOE_SEP * FOE_SEP;
var COINS_PER_CHARGE = 5;

/* Out of pulses, the hull drains its blue to light grey: colorless reads as
   "spent" at a glance, it can never be misread as an enemy (red) or a coin
   (yellow), and it stays bright enough that the ship is as easy to follow as
   ever. Topped up at the cap, the hull flashes to the same bright green as the
   upgrade-card glow, so "no need to chase coins right now" reads at a glance
   without checking the charge dots. Both recolored sheet cells are baked once
   in init. */
var SHIP_COL = 12, SHIP_EMPTY_COL = 6, SHIP_FULL_COL = 11;

/* Foes are the player's own hull in enemy colors — same silhouette, same nose,
   so a glance reads "another ship" and the only difference is the paint: hull
   red, outline dark red, thruster pink instead of the player's orange (orange
   sits too close to the coins to be scattered across a whole swarm). The white
   canopy glint is left alone — it is what makes the shape read as a ship at 16
   px, on either team. Baked once in init, one recolor, no extra png.

   Three teams share that same paint job, palette-shifted: standard red is the
   original foe at its original speed, a dark red runs 20% slower and a light
   red 10% slower — a darker or lighter hull is what tells a player which one
   is bearing down before the number matters. The 16-color PICO-8 palette has
   no dark/light red of its own, so those two teams recolor straight to hex. */
var FOE_FROM = [12, 1, 9], FOE_TO = [8, 2, 14];
var FOE_TO_DARK  = ["#6b0000", "#2a0000", "#8a1a1a"];
var FOE_TO_LIGHT = ["#ff8080", "#b33a3a", "#ffb3b3"];

var FOE_T_RED = 0, FOE_T_DARK = 1, FOE_T_LIGHT = 2, FOE_T_N = 3;
var FOE_SPRITE = ["foe", "foe_dark", "foe_light"];
var FOE_SPEED_MUL = [1, 0.6, 0.8];       // dark -20%, light -10%, red unchanged

/* From wave 6 the squad picks up +0.1 across the board, and another +0.1 from
   wave 10 — a flat bonus on top of each team's multiplier rather than baked
   into FOE_SPEED_MUL itself, so a restart always begins back at base speeds. */
function foeSpeedMul(t) {
  return FOE_SPEED_MUL[t] + (wave >= 10 ? 0.2 : wave >= 6 ? 0.1 : 0);
}

/* A wave is a long haul now — 50 s rather than 10 — because the wave turn is no
   longer a number ticking over, it is the upgrade menu and the one decision the
   run gives you. Cheap, frequent picks would make the choice noise. WAVE_FRAMES
   is just the starting clock (wave 1) — each wave after that trims 100 frames
   off the previous wave's timer, bottoming out at WAVE_FRAMES_MIN so late waves
   never rush the upgrade menu into a blink-and-miss choice. */
var WAVE_FRAMES = 3000;
var WAVE_FRAMES_MIN = 900;

/* Every wave opens with a squad rolling in from the edges — one more ship than
   the wave before it, until the pool would drown the player. The trickle spawner
   keeps running on top of it and tightens its own interval with the wave. Waves
   scale the fight mostly by numbers — a foe's chase speed only steps up twice,
   at wave 6 and wave 10, see foeSpeedMul above. */
var WAVE_BURST = 10, WAVE_BURST_MAX = 120;
var FOE_SPEED = 0.96;
var WIN_WAVE = 15;                 // reaching this wave is the whole campaign, run over
var PANEL_W = 260, PANEL_H = 104;
var PAUSE_PANEL_H = 130;           // paused panel is taller: two lines of options, not one

/* Title card — wider than the in-game panels because it carries the control
   legend as well as the name. Shown once, on the very first run of the session;
   dying and flying again goes straight back into the field. */
var TITLE_W = 380, TITLE_H = 190;

/* ---- upgrade menu ----
   Every wave turn stops the field and deals three cards. The six upgrades come in
   pairs — one that refills a meter completely, one that raises its ceiling — so a
   pick is always "now or later", and the icon carries the difference (a full row
   of dots/hearts vs. one ghost slot with a plus) before the label is read. */
var UP_PULSE = 0, UP_PULSE_MAX = 1, UP_SPEED = 2,
    UP_LIFE = 3, UP_LIFE_MAX = 4, UP_RANGE = 5, UP_N = 6;

var UP_NAME = ["FULL PULSE", "MAX PULSE +1", "SPEED +10%",
               "FULL LIFE", "MAX LIFE +1", "RANGE +5%"];
var UP_DESC = ["REFILL EVERY PULSE", "HOLD ONE MORE PULSE", "A FASTER HULL",
               "EVERY HEART BACK", "ONE MORE HEART SLOT", "A WIDER PULSE RING"];
var UP_ICON = ["ic0", "ic1", "ic2", "ic3", "ic4", "ic5"];   // baked in init

var ICON_SZ = 32;
var CARD_W = 132, CARD_H = 100, CARD_GAP = 14, CARD_Y = 52;
var MENU_PAD = 16;
var MENU_W = CARD_W * 3 + CARD_GAP * 2 + MENU_PAD * 2, MENU_H = CARD_Y + CARD_H + 30;
var MENU_X = 0, MENU_Y = 0;        // set in init, once W/H are known
// panels are 80% see-through so the ship and foes still read while a menu is
// up — shared by the upgrade, pause and game-over panels alike
var panelAlpha = { a: 0.2 };

var ST_PLAY = 0, ST_DEAD = 1, ST_PAUSE = 2, ST_INTRO = 3, ST_UPGRADE = 4, ST_RESUME = 5, ST_WIN = 6;
var RESUME_FRAMES = 30;              // 0.5s of breathing room after a card is picked

/* Three controls, nothing else: move, pulse, pause.
   keyboard  arrows = move, X = pulse, ENTER = pause
   touch     left half = analog stick, bottom-right X button = pulse, corner = pause */
var BT_FIRE = 5, BT_PAUSE = 8;

/* pause button (mobile only), tucked into the top-right corner of the HUD */
var PAUSE_W = 30, PAUSE_H = 18, PAUSE_HIT = 14;
var HUD_R = 0;                     // right-side HUD shift, to clear that button

/* fire button (mobile only): a fixed X in the bottom-right corner, sized for a
   thumb rather than a cursor */
var FIRE_W = 56, FIRE_H = 56, FIRE_HIT = 10;
var FIRE_MARGIN = 16;

/* analog stick — replaces the d-pad: a big fixed pad anchored to the bottom-left
   corner. A press anywhere in the left half claims it and the knob leans toward
   the thumb, capped at STK_R out from the fixed center — so there is nothing
   small to aim at and the base never drifts. */
var STK_R = 50;                    // how far the knob travels from the center
var STK_KNOB = 20;                 // knob radius
var STK_DEAD = 0.18;               // fraction of STK_R read as "centered"
var STK_HOME_X = 72;               // fixed center, from the left edge
var STK_HOME_DY = 72;              // ... measured up from the bottom edge

/* -------------------------------------------------------------------- state -- */

var W = 0, H = 0;
var state = ST_PLAY;

var px = 0, py = 0, pvx = 0, pvy = 0, pang = 0;
var lives = 3, score = 0, best = 0, wave = 1;
var invuln = 0, coinsGot = 0, charges = 2;

/* the run's build: what the upgrades have made of the reference ship */
var spdMul = SPD_BASE, rangeMul = RANGE_BASE;
var maxLives = LIVES_BASE, chargeCap = CHARGE_CAP_BASE;

/* upgrade menu: the three ids on offer, the highlighted one, and a short guard
   so the press that ended the wave can't also pick a card */
var upDeck, upPick, upSel = 0, upTimer = 0, resumeTimer = 0;
var upMx = 0, upMy = 0;            // last pointer position, to tell resting from moving
var icWhich = 0;                   // which icon prerender is baking

/* pause menu: CONTINUE (0) / RESTART (1), always opens on CONTINUE */
var PAUSE_CONTINUE = 0, PAUSE_RESTART = 1;
var pauseSel = PAUSE_CONTINUE;
var foeTimer = 0, coinTimer = 0, waveTimer = 0, waveShow = 0;
var pulseOn = 0, pulseR = 0;
var shake = 0;
var volume = 0.8, volShow = 0;
var deadTimer = 0, introTimer = 0;

/* pools — typed arrays so nothing is ever allocated mid-game */
var coinX, coinY, coinOn, coinPh;
var foeX, foeY, foeVx, foeVy, foeOn, foePh, foeAng, foeType;
var foeLive, foeN = 0;             // indexes of the foes still alive this step
var spX, spY, spVx, spVy, spLife, spMax, spRot, spSpin, spCol;

/* touch ui: the pause button and the fire button */
var touchUi = false;
var vPress;                        // virtual button presses fed by the touch ui
var pauseX = 0, pauseY = 0, pauseOn = 0, pauseHeld = 0;
var fireX = 0, fireY = 0, fireOn = 0, fireHeld = 0;

/* analog stick state */
var stkId = -1;                    // engine touch id steering it, -1 = released
var stkHx = 0, stkHy = 0;          // fixed center
var stkKx = 0, stkKy = 0;          // knob center
var stkAx = 0, stkAy = 0;          // axes, -1..1, dead zone removed
var seenId, seenN = 0;             // touch ids seen last frame — only claim new ones

/* preallocated call options */
var opt = { a: 1, rot: 0, fx: false, fy: false };
var padOpt = { a: 1 };             // touch ui blits translucent so the field shows through
var snd = { vol: 1, rate: 1, pan: 0, loop: false };
var mopt = { vol: 0.55, loop: true, fade: 1.2 };
/* every track is the same 8s loop rearranged, so swaps keep the playhead (sync)
   and only need a short crossfade to hide the change of texture */
var msync = { vol: 0.55, loop: true, fade: 0.4, sync: true };

/* ---------------------------------------------------------------------- init -- */

function init(api) {
  W = api.w();
  H = api.h();

  coinX = new Float32Array(COIN_MAX);
  coinY = new Float32Array(COIN_MAX);
  coinOn = new Uint8Array(COIN_MAX);
  coinPh = new Float32Array(COIN_MAX);

  foeX = new Float32Array(FOE_MAX);
  foeY = new Float32Array(FOE_MAX);
  foeVx = new Float32Array(FOE_MAX);
  foeVy = new Float32Array(FOE_MAX);
  foeOn = new Uint8Array(FOE_MAX);
  foePh = new Float32Array(FOE_MAX);
  foeAng = new Float32Array(FOE_MAX);
  foeType = new Uint8Array(FOE_MAX);
  foeLive = new Int32Array(FOE_MAX);

  spX = new Float32Array(SPARK_MAX);
  spY = new Float32Array(SPARK_MAX);
  spVx = new Float32Array(SPARK_MAX);
  spVy = new Float32Array(SPARK_MAX);
  spLife = new Float32Array(SPARK_MAX);
  spMax = new Float32Array(SPARK_MAX);
  spRot = new Float32Array(SPARK_MAX);
  spSpin = new Float32Array(SPARK_MAX);
  spCol = new Uint8Array(SPARK_MAX);

  upDeck = new Int32Array(UP_N);   // the eligible upgrades, reshuffled per wave
  upPick = new Int32Array(3);      // the three that made it onto the cards

  touchUi = api.mobile();
  HUD_R = touchUi ? 44 : 0;        // hearts step aside for the pause button
  vPress = new Uint8Array(9);
  seenId = new Int32Array(10);     // MAX_TOUCH in the engine

  MENU_X = (W - MENU_W) * 0.5;
  MENU_Y = (H - MENU_H) * 0.5;

  api.recolor("ship_empty", "sprites", SP_SHIP * TILE, 0, TILE, TILE,
    SHIP_COL, SHIP_EMPTY_COL);       // same ship, hull repainted, outline kept
  api.recolor("ship_full", "sprites", SP_SHIP * TILE, 0, TILE, TILE,
    SHIP_COL, SHIP_FULL_COL);        // ... and topped-up green
  api.recolor("foe", "sprites", SP_SHIP * TILE, 0, TILE, TILE,
    FOE_FROM, FOE_TO);               // ... and the same ship in enemy red
  api.recolor("foe_dark", "sprites", SP_SHIP * TILE, 0, TILE, TILE,
    FOE_FROM, FOE_TO_DARK);          // ... dark red, -20% speed
  api.recolor("foe_light", "sprites", SP_SHIP * TILE, 0, TILE, TILE,
    FOE_FROM, FOE_TO_LIGHT);         // ... light red, -10% speed

  bakeBackdrop(api);
  bakeTitle(api);
  bakeGameOver(api);
  bakeGameWin(api);
  bakePaused(api);
  bakeUpgrades(api);
  if (touchUi) setupTouch(api);

  api.font();
  api.text_color(7);
  api.music_vol(volume * 0.7);
  api.sfx_vol(volume);
  restart(api);

  /* The field is already set up behind the card, so the first press drops
     straight into it. The calm take of the theme plays under the title and the
     start swaps to the full one on the beat. */
  state = ST_INTRO;
  introTimer = 24;                   // ignore the press that dismissed the overlay
  api.music("theme_calm", mopt);
}

/* Static art is drawn once into offscreen canvases and blitted as a sprite —
   never re-rasterized per frame. */
function bakeBackdrop(api) {
  api.prerender("backdrop", W, H, paintBackdrop);
}

function paintBackdrop(api) {
  var i, x, y, r;
  api.srand(20260815);
  api.cls(0);

  // dithered nebula clouds, then stars on top
  nebula(api, 170, 215, 205, 1, 13, 0.9);
  nebula(api, 480, 130, 175, 1, 2, 0.75);
  nebula(api, 350, 300, 150, 13, 12, 0.3);
  nebula(api, 600, 300, 120, 2, 14, 0.25);

  // stars
  for (i = 0; i < 340; i++) {
    x = api.flr(api.rnd(W));
    y = FIELD_TOP + api.flr(api.rnd(H - FIELD_TOP));
    r = api.rnd(1);
    api.pset(x, y, r < 0.55 ? 5 : r < 0.85 ? 6 : 7);
  }
  for (i = 0; i < 14; i++) {                       // a few bright ones with flare
    x = api.flr(api.rnd(W));
    y = FIELD_TOP + api.flr(api.rnd(H - FIELD_TOP));
    api.pset(x, y, 7);
    api.pset(x - 1, y, 12);
    api.pset(x + 1, y, 12);
    api.pset(x, y - 1, 12);
    api.pset(x, y + 1, 12);
  }

  // HUD strip and its static labels
  api.rectfill(0, 0, W, FIELD_TOP, 0);
  api.rectfill(0, FIELD_TOP - 1, W, 1, 1);
  api.rectfill(0, FIELD_TOP - 2, W, 1, 13);
  api.font("ui-monospace, SFMono-Regular, Menlo, Consolas, monospace", 10);
  api.text_align("left", "middle");
  api.print("SCORE", 8, 12, 5);
  api.text_align("right", "middle");
  api.print("SHIPS", W - 76 - HUD_R, 12, 5);
  api.text_align("left", "top");
  api.font();
}

/* One soft cloud: radial falloff modulated by a few sine octaves, stippled.
   Only ever runs inside prerender, so the per-pixel cost is paid once. */
function nebula(api, cx, cy, r, ca, cb, density) {
  var x, y, dx, dy, d2, f, n, r2 = r * r;
  var x0 = api.max(0, api.flr(cx - r)), x1 = api.min(W, api.ceil(cx + r));
  var y0 = api.max(FIELD_TOP, api.flr(cy - r)), y1 = api.min(H, api.ceil(cy + r));
  for (y = y0; y < y1; y++) {
    dy = y - cy;
    for (x = x0; x < x1; x++) {
      dx = x - cx;
      d2 = dx * dx + dy * dy;
      if (d2 > r2) continue;
      f = 1 - api.sqrt(d2) / r;
      f *= f;
      n = 0.5 + 0.28 * api.sin(x * 0.031 + y * 0.017)
              + 0.16 * api.sin(x * 0.013 - y * 0.043)
              + 0.10 * api.sin((x + y) * 0.071);
      if (api.rnd(1) < f * n * density) api.pset(x, y, api.rnd(1) < 0.66 ? ca : cb);
    }
  }
}

/* Everything on the title card is fixed except the blinking start prompt, so the
   whole thing bakes into one blit and draw() only adds that one line of text. */
function bakeTitle(api) {
  api.prerender("title", TITLE_W, TITLE_H, paintTitle);
}

function paintTitle(api) {
  var cx = TITLE_W * 0.5, lx = cx - 12, rx = cx + 12;
  api.cls(0);
  api.rect(0, 0, TITLE_W, TITLE_H, 12);
  api.rect(1, 1, TITLE_W - 2, TITLE_H - 2, 1);

  // the two ships flanking the name say what the game is before a word is read
  api.sspr("sprites", SP_SHIP * TILE, 0, TILE, TILE, 44, 30, 24, 24);
  api.sspr("foe", 0, 0, TILE, TILE, TITLE_W - 68, 30, 24, 24);

  api.text_align("center", "middle");
  api.font("ui-monospace, SFMono-Regular, Menlo, Consolas, monospace", 28);
  api.print("STARDUST RUN", cx + 2, 44, 1);        // drop shadow, then the hull blue
  api.print("STARDUST RUN", cx, 42, 12);
  api.font("ui-monospace, SFMono-Regular, Menlo, Consolas, monospace", 10);
  api.print("COLLECT THE DUST — OUTRUN THE SWARM", cx, 64, 13);
  api.print("EVERY WAVE, PICK ONE UPGRADE", cx, 78, 10);
  api.rectfill(70, 90, TITLE_W - 140, 1, 1);

  // control legend: labels right-aligned into the gutter, keys left-aligned out of it
  api.text_align("right", "middle");
  api.print("MOVE", lx, 108, 7);
  api.print("PULSE", lx, 126, 7);
  api.print("PAUSE", lx, 144, 7);
  api.text_align("left", "middle");
  api.print(touchUi ? "LEFT THUMB" : "ARROWS", rx, 108, 7);
  api.print(touchUi ? "X BUTTON" : "X", rx, 126, 7);
  api.print(touchUi ? "CORNER BUTTON" : "ENTER", rx, 144, 7);

  api.text_align("left", "top");
  api.font();
}

function bakeGameOver(api) {
  api.prerender("gameover", PANEL_W, PANEL_H, paintGameOver);
}

function paintGameOver(api) {
  api.cls(0);
  api.rect(0, 0, PANEL_W, PANEL_H, 8);
  api.rect(1, 1, PANEL_W - 2, PANEL_H - 2, 2);
  api.text_align("center", "middle");
  api.font("ui-monospace, SFMono-Regular, Menlo, Consolas, monospace", 22);
  api.print("GAME OVER", PANEL_W * 0.5, 30, 7);
  api.font("ui-monospace, SFMono-Regular, Menlo, Consolas, monospace", 10);
  api.print(touchUi ? "TAP X TO TRY AGAIN" : "PRESS X TO TRY AGAIN", PANEL_W * 0.5, 92, 7);
  api.text_align("left", "top");
  api.font();
}

/* Same panel shape as GAME OVER, green instead of red — the run's other ending,
   reached by surviving to WIN_WAVE rather than running out of lives. */
function bakeGameWin(api) {
  api.prerender("gamewin", PANEL_W, PANEL_H, paintGameWin);
}

function paintGameWin(api) {
  api.cls(0);
  api.rect(0, 0, PANEL_W, PANEL_H, 11);
  api.rect(1, 1, PANEL_W - 2, PANEL_H - 2, 3);
  api.text_align("center", "middle");
  api.font("ui-monospace, SFMono-Regular, Menlo, Consolas, monospace", 22);
  api.print("YOU WIN", PANEL_W * 0.5, 30, 7);
  api.font("ui-monospace, SFMono-Regular, Menlo, Consolas, monospace", 10);
  api.print(touchUi ? "TAP X TO FLY AGAIN" : "PRESS X TO FLY AGAIN", PANEL_W * 0.5, 92, 7);
  api.text_align("left", "top");
  api.font();
}

function bakePaused(api) {
  api.prerender("paused", PANEL_W, PAUSE_PANEL_H, paintPaused);
}

function paintPaused(api) {
  api.cls(0);
  api.rect(0, 0, PANEL_W, PAUSE_PANEL_H, 12);
  api.rect(1, 1, PANEL_W - 2, PAUSE_PANEL_H - 2, 1);
  api.text_align("center", "middle");
  api.font("ui-monospace, SFMono-Regular, Menlo, Consolas, monospace", 22);
  api.print("PAUSED", PANEL_W * 0.5, 26, 7);
  // touch has no up/down, so it keeps its two direct one-tap shortcuts baked in;
  // keyboard/mouse gets a real CONTINUE/RESTART menu, drawn live in draw() so the
  // selected line can be highlighted
  if (touchUi) {
    api.font("ui-monospace, SFMono-Regular, Menlo, Consolas, monospace", 10);
    api.print("TAP THE CORNER TO CONTINUE", PANEL_W * 0.5, 98, 7);
    api.print("TAP X TO RESTART", PANEL_W * 0.5, 114, 7);
  }
  api.text_align("left", "top");
  api.font();
}

/* ----------------------------------------------------------- upgrade menu -- */

/* The frame and the two fixed lines bake once; only the wave number, the three
   cards and the highlight are drawn per frame. The icons bake once each into
   their own 32x32 image, so a card costs one blit and two prints. */
function bakeUpgrades(api) {
  api.prerender("upmenu", MENU_W, MENU_H, paintUpgradeFrame);
  for (var i = 0; i < UP_N; i++) {
    icWhich = i;                                   // prerender has no argument channel
    api.prerender(UP_ICON[i], ICON_SZ, ICON_SZ, paintIcon);
  }
}

function paintUpgradeFrame(api) {
  api.cls(0);
  api.rect(0, 0, MENU_W, MENU_H, 12);
  api.rect(1, 1, MENU_W - 2, MENU_H - 2, 1);
  api.text_align("center", "middle");
  api.font("ui-monospace, SFMono-Regular, Menlo, Consolas, monospace", 10);
  api.print("CHOOSE AN UPGRADE", MENU_W * 0.5, 38, 7);
  api.print(touchUi ? "TAP A CARD" : "ARROWS TO CHOOSE — X TO TAKE IT",
    MENU_W * 0.5, MENU_H - 16, 7);
  api.text_align("left", "top");
  api.font();
}

/* Six icons out of primitives and two sheet cells — no new png. Each one says
   which half of a pair it is: a full row of dots/hearts = refills what you have
   now, a ghost slot with a green plus = room for one more later. */
function paintIcon(api) {
  var i, k = icWhich;
  if (k === UP_PULSE) {                            // every dot in the bank lit at once
    for (i = 0; i < 4; i++) {
      api.circfill(5 + i * 7, 18, 4, 12);
      api.circ(5 + i * 7, 18, 4, 7);
    }
    api.circfill(4, 15, 2, 7);                     // one glint, so the row reads as charge
  } else if (k === UP_PULSE_MAX) {                 // three banked, a fourth slot opens
    for (i = 0; i < 3; i++) api.circfill(5 + i * 7, 22, 3, 12);
    api.circ(26, 22, 3, 11);
    plusGlyph(api, 26, 8, 5, 11);
  } else if (k === UP_SPEED) {                     // the ship itself, nose right, streaking
    api.line(0, 9, 9, 9, 13);
    api.line(1, 16, 8, 16, 12);
    api.line(0, 23, 9, 23, 13);
    opt.a = 1; opt.rot = 1.5708; opt.fx = false; opt.fy = false;
    api.sspr("sprites", SP_SHIP * TILE, 0, TILE, TILE, 10, 8, 22, 22, opt);
  } else if (k === UP_LIFE) {                      // every heart slot filled in, side by side
    for (i = 0; i < 3; i++) {
      api.sspr("sprites", SP_HEART * TILE, 0, TILE, TILE, i * 11, 10, 11, 11);
    }
  } else if (k === UP_LIFE_MAX) {                  // ... and a heart-shaped hole
    opt.a = 0.28; opt.rot = 0; opt.fx = false; opt.fy = false;
    api.sspr("sprites", SP_HEART * TILE, 0, TILE, TILE, 14, 13, 18, 18, opt);
    api.sspr("sprites", SP_HEART * TILE, 0, TILE, TILE, 1, 13, 18, 18);
    plusGlyph(api, 25, 6, 4, 11);
  } else {                                         // UP_RANGE: the ring, reaching out
    api.circ(16, 16, 15, 11);
    api.circ(16, 16, 8, 12);
    api.circfill(16, 16, 3, 7);
    api.line(22, 10, 26, 6, 11);
    api.line(10, 10, 6, 6, 11);
    api.line(22, 22, 26, 26, 11);
    api.line(10, 22, 6, 26, 11);
  }
}

function plusGlyph(api, x, y, r, c) {
  api.rectfill(x - 1, y - r, 3, r * 2 + 1, c);
  api.rectfill(x - r, y - 1, r * 2 + 1, 3, c);
}

/* --------------------------------------------------------------- touch ui -- */

/* Three things on screen, nothing more: a big fixed analog pad anchored to the
   bottom-left corner, a small pause button in the top-right corner, and a fixed
   X button in the bottom-right corner that fires the pulse. All three looks are
   baked in init and just blitted from then on. */
function setupTouch(api) {
  pauseX = W - PAUSE_W - 5;
  pauseY = 3;                                      // inside the HUD strip
  pauseOn = 0; api.prerender("pauseu", PAUSE_W, PAUSE_H, paintPause);
  pauseOn = 1; api.prerender("paused_btn", PAUSE_W, PAUSE_H, paintPause);

  fireX = W - FIRE_W - FIRE_MARGIN;
  fireY = H - FIRE_H - FIRE_MARGIN;
  fireOn = 0; api.prerender("fireu", FIRE_W, FIRE_H, paintFire);
  fireOn = 1; api.prerender("firep", FIRE_W, FIRE_H, paintFire);

  setupStick(api);
}

/* prerender gives no argument channel of its own — pauseOn carries which look
   is being baked. */
function paintPause(api) {
  var w = PAUSE_W, h = PAUSE_H;
  var fill = pauseOn ? 12 : 1, edge = pauseOn ? 7 : 13, ink = pauseOn ? 0 : 6;
  api.rectfill(1, 1, w - 2, h - 2, fill);
  api.rect(0, 0, w, h, edge);
  api.rectfill(w * 0.5 - 5, h * 0.5 - 5, 3, 10, ink);   // pause glyph
  api.rectfill(w * 0.5 + 2, h * 0.5 - 5, 3, 10, ink);
}

/* same trick as paintPause — fireOn carries which look is being baked. The X is
   a few offset diagonal lines rather than one, so the stroke reads at thumb size. */
function paintFire(api) {
  var w = FIRE_W, h = FIRE_H, m = 16;
  var fill = fireOn ? 12 : 1, edge = fireOn ? 7 : 13, ink = fireOn ? 0 : 6;
  api.rectfill(1, 1, w - 2, h - 2, fill);
  api.rect(0, 0, w, h, edge);
  api.line(m, m, w - m, h - m, ink);
  api.line(m + 1, m, w - m, h - m - 1, ink);
  api.line(m, m + 1, w - m - 1, h - m, ink);
  api.line(w - m, m, m, h - m, ink);
  api.line(w - m - 1, m, m, h - m - 1, ink);
  api.line(w - m, m + 1, m + 1, h - m, ink);
}

/* ------------------------------------------------------------- analog stick -- */

/* Ring + knob, baked once. The ring sits at a fixed spot in the bottom-left
   corner and never moves — only the knob leans toward the thumb. */
function setupStick(api) {
  var d = STK_R * 2, k = STK_KNOB * 2;
  stkHx = STK_HOME_X;
  stkHy = H - STK_HOME_DY;
  stkKx = stkHx;
  stkKy = stkHy;
  api.prerender("stkring", d, d, paintStickRing);
  api.prerender("stkknob", k, k, paintStickKnob);
}

function paintStickRing(api) {
  var d = STK_R * 2;
  api.ovalfill(0, 0, d, d, 1);
  api.oval(0, 0, d, d, 13);
  api.oval(8, 8, d - 16, d - 16, 0);               // inner shade, reads as a dish
}

function paintStickKnob(api) {
  var k = STK_KNOB * 2;
  api.ovalfill(0, 0, k, k, 12);
  api.oval(0, 0, k, k, 7);
}

/* The stick owns one finger, tracked by its engine touch id so a second finger
   on the fire button never steals it. A press inside the left half claims the
   stick; the knob leans from the fixed center toward the thumb, capped at STK_R
   out, so the base itself never moves and there is nothing to relocate.
   While paused or dead nothing steers, so a stray touch there can't be mistaken
   for a grab once play resumes. */
function pollStick(api, n) {
  var i, id, x, y, dx, dy, d, m, slot;

  slot = -1;
  if (state !== ST_PLAY) stkId = -1;
  if (stkId >= 0) {
    for (i = 0; i < n; i++) if (api.touch_id(i) === stkId) { slot = i; break; }
    if (slot < 0) stkId = -1;                      // that finger lifted
  }
  if (stkId < 0 && state === ST_PLAY) {
    for (i = 0; i < n; i++) {
      id = api.touch_id(i);
      if (touchSeen(id)) continue;                 // only a fresh press claims it
      x = api.touch_x(i);
      y = api.touch_y(i);
      if (x > W * 0.5 || y < FIELD_TOP) continue;  // left half, below the HUD
      stkId = id;
      slot = i;
      break;
    }
  }

  if (slot >= 0) {
    x = api.touch_x(slot);
    y = api.touch_y(slot);
    dx = x - stkHx;
    dy = y - stkHy;
    d = api.sqrt(dx * dx + dy * dy);
    if (d > STK_R) {                               // knob caps out at the ring edge
      dx = dx / d * STK_R;
      dy = dy / d * STK_R;
      d = STK_R;
    }
    stkKx = stkHx + dx;
    stkKy = stkHy + dy;
    m = d / STK_R;
    if (m > STK_DEAD) {
      m = (m - STK_DEAD) / (1 - STK_DEAD);         // dead zone, then full swing
      stkAx = dx / d * m;
      stkAy = dy / d * m;
    }
  } else {                                         // released: knob eases home
    stkKx += (stkHx - stkKx) * 0.4;
    stkKy += (stkHy - stkKy) * 0.4;
  }
}

function touchSeen(id) {
  for (var i = 0; i < seenN; i++) if (seenId[i] === id) return 1;
  return 0;
}

function drawStick(api) {
  // nothing on top of the title card or the upgrade cards
  if (!touchUi || state === ST_INTRO || state === ST_UPGRADE) return;
  padOpt.a = stkId >= 0 ? 0.5 : 0.28;
  api.spr("stkring", stkHx - STK_R, stkHy - STK_R, padOpt);
  padOpt.a = stkId >= 0 ? 0.9 : 0.5;
  api.spr("stkknob", stkKx - STK_KNOB, stkKy - STK_KNOB, padOpt);
}

/* Virtual buttons for this update step. A finger in the pause corner holds the
   pause button; a finger on the fixed X button fires the pulse, edge-triggered
   like the pause corner so a held thumb doesn't repeat-fire. Both are read on
   every finger independently of the stick, so steering with one thumb and
   firing with another (or the same thumb hopping between them) both work. */
function pollTouch(api) {
  var i, n, x, y, hit, fh;

  vPress[BT_FIRE] = 0;
  vPress[BT_PAUSE] = 0;
  stkAx = 0;
  stkAy = 0;
  if (!touchUi) return;

  n = api.touches();
  pollStick(api, n);

  hit = 0;
  fh = 0;
  for (i = 0; i < n; i++) {
    x = api.touch_x(i);
    y = api.touch_y(i);
    if (state !== ST_INTRO && state !== ST_UPGRADE &&   // corner is live only once it shows
        x >= pauseX - PAUSE_HIT && x <= pauseX + PAUSE_W + PAUSE_HIT &&
        y >= pauseY - PAUSE_HIT && y <= pauseY + PAUSE_H + PAUSE_HIT) {
      hit = 1;                                     // the corner never fires
      continue;
    }
    if (x >= fireX - FIRE_HIT && x <= fireX + FIRE_W + FIRE_HIT &&
        y >= fireY - FIRE_HIT && y <= fireY + FIRE_H + FIRE_HIT) {
      fh = 1;
    }
  }
  if (hit && !pauseHeld) vPress[BT_PAUSE] = 1;
  pauseHeld = hit;
  if (fh && !fireHeld) vPress[BT_FIRE] = 1;
  fireHeld = fh;

  seenN = n;                                       // remember this frame's fingers
  for (i = 0; i < n; i++) seenId[i] = api.touch_id(i);
}

function drawPause(api) {
  if (!touchUi || state === ST_INTRO || state === ST_UPGRADE) return;
  padOpt.a = pauseHeld ? 0.92 : 0.55;
  api.spr(pauseHeld ? "paused_btn" : "pauseu", pauseX, pauseY, padOpt);
}

/* Unlike the pause button, the fire button stays up through the title card and
   the death and win panels too — it is also "start" and "fly again" there, and
   with a fixed button (not a double tap anywhere) a player needs it visible to
   find it. */
function drawFire(api) {
  if (!touchUi) return;
  padOpt.a = fireHeld ? 0.92 : 0.55;
  api.spr(fireHeld ? "firep" : "fireu", fireX, fireY, padOpt);
}

/* keyboard or touch, the game never asks which */
function press(api, i) { return api.btnp(i) || vPress[i] === 1; }

/* ---- music ----
   The score follows the ship's health, not the wave count: full hearts keep the
   base groove, and each lost heart pushes the tune to a faster arrangement so
   the music itself warns the player they're close to dying. Swapping is free —
   the tracks share one grid, so the engine keeps the playhead and the bar
   carries straight on. */
function trackFor(hp, hpMax) {
  var ratio = hp / hpMax;
  if (ratio <= 1 / 3) return "theme_rush";     // one hit from death
  if (ratio <= 2 / 3) return "theme_drive";
  return "theme";
}

function setTrack(api, name, fade) {
  if (api.music_playing() === name) return;
  msync.fade = fade;
  api.music(name, msync);
}

/* Leaving the title card. The field was already built in init, but rebuild it
   anyway so the coins the player watched bobbing aren't the ones they start on
   top of, and the invulnerability grace starts now rather than 40 s ago. */
function startRun(api) {
  restart(api);
  setTrack(api, "theme", 0.6);
  snd.vol = 0.7;
  snd.rate = 1;
  api.sfx("powerup", snd);
}

function restart(api) {
  var i;
  state = ST_PLAY;
  px = W * 0.5;
  py = (H + FIELD_TOP) * 0.5;
  pvx = 0; pvy = 0; pang = 0;
  spdMul = SPD_BASE;               // a run always starts from the same slow hull
  rangeMul = RANGE_BASE;
  maxLives = LIVES_BASE;
  chargeCap = CHARGE_CAP_BASE;
  lives = maxLives;                // ... and at full health
  score = 0;
  wave = 1;
  invuln = 60;
  coinsGot = 0;
  charges = CHARGE_BASE;
  upSel = 0;
  upTimer = 0;
  resumeTimer = 0;
  pauseSel = PAUSE_CONTINUE;
  foeTimer = 90;
  coinTimer = 0;
  waveTimer = WAVE_FRAMES;
  waveShow = 0;
  pulseOn = 0;
  pulseR = 0;
  shake = 0;
  deadTimer = 0;
  for (i = 0; i < COIN_MAX; i++) coinOn[i] = 0;
  for (i = 0; i < FOE_MAX; i++) foeOn[i] = 0;
  foeN = 0;
  for (i = 0; i < SPARK_MAX; i++) spLife[i] = 0;
  for (i = 0; i < 4; i++) spawnCoin(api);
}

/* -------------------------------------------------------------------- spawn -- */

function spawnCoin(api) {
  for (var i = 0; i < COIN_MAX; i++) {
    if (coinOn[i]) continue;
    coinOn[i] = 1;
    coinX[i] = 20 + api.rnd(W - 40);
    coinY[i] = FIELD_TOP + 20 + api.rnd(H - FIELD_TOP - 40);
    coinPh[i] = api.rnd(6.28);
    return;
  }
}

/* Now that a foe has a nose, it enters already pointed at the player and drifting
   in — spawning at a dead stop would leave the sprite facing an arbitrary way for
   the frames the chase lerp takes to build up speed.

   Each spawn rolls its own team, red/dark red/light red at equal odds, so a
   squad is always a mix rather than one uniform speed — the paint on each foe
   is the only warning of how fast it's closing. */
function spawnFoe(api) {
  var dx, dy, d, t, m;
  for (var i = 0; i < FOE_MAX; i++) {
    if (foeOn[i]) continue;
    foeOn[i] = 1;
    t = api.rndi(FOE_T_N);
    foeType[i] = t;
    m = foeSpeedMul(t);
    if (api.rnd(1) < 0.5) {
      foeX[i] = api.rnd(1) < 0.5 ? -TILE : W + TILE;
      foeY[i] = FIELD_TOP + api.rnd(H - FIELD_TOP);
    } else {
      foeX[i] = api.rnd(W);
      foeY[i] = api.rnd(1) < 0.5 ? FIELD_TOP - TILE : H + TILE;
    }
    dx = px - foeX[i];
    dy = py - foeY[i];
    d = api.sqrt(dx * dx + dy * dy);
    if (d < 0.001) { dx = 0; dy = 1; d = 1; }
    foeVx[i] = dx / d * 0.6 * m;
    foeVy[i] = dy / d * 0.6 * m;
    foeAng[i] = api.atan2(dy, dx) + 1.5708;
    foePh[i] = api.rnd(6.28);
    return;
  }
}

function spawnSparks(api, x, y, n, c, speed) {
  for (var k = 0; k < n; k++) {
    for (var i = 0; i < SPARK_MAX; i++) {
      if (spLife[i] > 0) continue;
      var a = api.rnd(6.2832);
      var v = speed * (0.35 + api.rnd(0.65));
      spX[i] = x;
      spY[i] = y;
      spVx[i] = api.cos(a) * v;
      spVy[i] = api.sin(a) * v;
      spMax[i] = 16 + api.rnd(18);
      spLife[i] = spMax[i];
      spRot[i] = api.rnd(6.2832);
      spSpin[i] = (api.rnd(0.4) - 0.2);
      spCol[i] = c;
      break;
    }
  }
}

/* ------------------------------------------------------------------- update -- */

function update(api) {
  var i, dx, dy, d, sp, fs, fspeed;

  pollTouch(api);                                  // must run even while paused

  // enter (or the corner button) pauses: the whole sim freezes. Touch has no
  // up/down, so it keeps its direct one-tap shortcuts: the corner always
  // continues, X always restarts. Keyboard/mouse gets a real menu — up/down
  // between CONTINUE and RESTART, X or Enter confirms whichever is lit, same
  // dual-confirm habit as the upgrade cards.
  if (state === ST_PAUSE) {
    if (touchUi) {
      if (press(api, BT_PAUSE)) {
        state = ST_PLAY;
        api.music_resume();
      } else if (press(api, BT_FIRE)) {
        api.music_resume();                     // pick the frozen track back up ...
        restart(api);
        setTrack(api, trackFor(lives, maxLives), 0.35); // ... then crossfade to the base tune
      }
      return;
    }
    if (api.btnp(2) && pauseSel !== PAUSE_CONTINUE) selectPause(api, PAUSE_CONTINUE);
    if (api.btnp(3) && pauseSel !== PAUSE_RESTART) selectPause(api, PAUSE_RESTART);
    if (press(api, BT_FIRE) || press(api, BT_PAUSE)) {
      if (pauseSel === PAUSE_CONTINUE) {
        state = ST_PLAY;
        api.music_resume();
      } else {
        api.music_resume();
        restart(api);
        setTrack(api, trackFor(lives, maxLives), 0.35);
      }
    }
    return;
  }
  if (state === ST_PLAY && press(api, BT_PAUSE)) {
    state = ST_PAUSE;
    pauseSel = PAUSE_CONTINUE;               // always opens on CONTINUE
    api.music_pause();
    api.sfx_stop();
    return;
  }

  // scroll wheel = master volume
  var wh = api.mwheel();
  if (wh !== 0) {
    volume = api.mid(0, volume - (wh > 0 ? 0.1 : -0.1), 1);
    api.sfx_vol(volume);
    api.music_vol(volume * 0.7);
    volShow = 90;
  }
  if (volShow > 0) volShow--;

  updateSparks(api);

  if (shake > 0) shake--;

  /* title card: nothing simulates, the coins just keep bobbing behind it */
  if (state === ST_INTRO) {
    if (introTimer > 0) introTimer--;
    for (i = 0; i < COIN_MAX; i++) if (coinOn[i]) coinPh[i] += 0.09;
    // X is what the card asks for, but ENTER is the other key a player reaches
    // for on a title screen and it has nothing to pause yet
    if (introTimer === 0 && (press(api, BT_FIRE) || api.btnp(BT_PAUSE))) startRun(api);
    return;
  }

  /* upgrade menu: same deal — the field is frozen mid-wave behind the cards */
  if (state === ST_UPGRADE) {
    updateUpgrades(api);
    return;
  }

  /* resume cooldown: the card is picked and the menu is gone, but the field
     holds still for half a second more before the squad is let loose — a beat
     to read the new build and find the ship again before it has to dodge */
  if (state === ST_RESUME) {
    if (resumeTimer > 0) resumeTimer--;
    if (resumeTimer === 0) state = ST_PLAY;
    return;
  }

  if (state === ST_DEAD || state === ST_WIN) {
    if (deadTimer > 0) deadTimer--;
    if (deadTimer === 0 && press(api, BT_FIRE)) {
      restart(api);
      setTrack(api, trackFor(lives, maxLives), 0.35); // full hearts, straight back to base
    }
    return;
  }

  /* ---- player ---- */
  var ax = 0, ay = 0;
  if (api.btn(0)) ax -= 1;
  if (api.btn(1)) ax += 1;
  if (api.btn(2)) ay -= 1;
  if (api.btn(3)) ay += 1;
  ax += stkAx;                                     // analog: a half tilt = half thrust
  ay += stkAy;

  // no mouse steering on touch: the steering thumb is also "the mouse", and the
  // ship would be dragged wherever it lands
  if (!touchUi && api.mbtn(0) && api.mouse_over()) {   // hold the mouse to steer
    dx = api.mx() - px;
    dy = api.my() - py;
    d = api.sqrt(dx * dx + dy * dy);
    if (d > 4) { ax += dx / d; ay += dy / d; }
  }

  d = api.sqrt(ax * ax + ay * ay);
  if (d > 1) { ax /= d; ay /= d; }
  // thrust and top speed scale together, so a SPEED pick makes the ship quicker
  // rather than just letting it coast further
  pvx += ax * ACC * spdMul;
  pvy += ay * ACC * spdMul;
  pvx *= FRIC;
  pvy *= FRIC;

  var maxv = MAXV * spdMul;
  sp = api.sqrt(pvx * pvx + pvy * pvy);
  if (sp > maxv) { pvx = pvx / sp * maxv; pvy = pvy / sp * maxv; }

  px += pvx;
  py += pvy;
  if (px < 8) { px = 8; pvx = -pvx * 0.4; }
  if (px > W - 8) { px = W - 8; pvx = -pvx * 0.4; }
  if (py < FIELD_TOP + 8) { py = FIELD_TOP + 8; pvy = -pvy * 0.4; }
  if (py > H - 8) { py = H - 8; pvy = -pvy * 0.4; }
  if (sp > 0.35) pang = api.atan2(pvy, pvx) + 1.5708;

  if (invuln > 0) invuln--;

  // engine trail
  if (sp > 1.2 && api.frame() % 3 === 0) {
    spawnSparks(api, px - pvx * 2, py - pvy * 2, 1, 9, 0.5);
  }

  /* ---- pulse ---- */
  if (press(api, BT_FIRE) && pulseOn === 0 && charges > 0) {
    charges--;
    pulseOn = 1;
    pulseR = 8;
    snd.vol = 0.8;
    snd.rate = 1;
    api.sfx("powerup", snd);
    spawnSparks(api, px, py, 6, 12, 1.4);
  }
  // the ring expands at a matching fraction of the reference speed, so a short
  // pulse and a long one last the same number of frames and read the same
  if (pulseOn === 1) {
    pulseR += PULSE_SPEED * rangeMul;
    if (pulseR > PULSE_MAX * rangeMul) { pulseOn = 0; pulseR = 0; }
  }

  /* ---- coins ---- */
  coinTimer--;
  if (coinTimer <= 0) {
    spawnCoin(api);
    coinTimer = 70 + api.rndi(90);
  }
  for (i = 0; i < COIN_MAX; i++) {
    if (!coinOn[i]) continue;
    coinPh[i] += 0.09;
    dx = coinX[i] - px;
    dy = coinY[i] - py;
    if (dx * dx + dy * dy < 144) {
      coinOn[i] = 0;
      score += 10 * wave;
      coinsGot++;
      spawnSparks(api, coinX[i], coinY[i], 7, 10, 1.5);
      snd.vol = 0.55;
      snd.rate = 0.95 + api.rnd(0.15);
      api.sfx("coin", snd);
      if (coinsGot % COINS_PER_CHARGE === 0 && charges < chargeCap) {
        charges++;
        snd.vol = 0.6;                             // banked a pulse: its own chime,
        snd.rate = 1;                              // never the sound of firing one
        api.sfx("charge", snd);
      }
    }
  }

  /* ---- waves and foes ---- */
  waveTimer--;
  if (waveTimer <= 0) {
    waveTimer = api.max(WAVE_FRAMES_MIN, WAVE_FRAMES - 100 * wave);
    wave++;
    if (wave >= WIN_WAVE) {
      winGame(api);
      return;
    }
    openUpgrades(api);                            // the squad waits behind the menu
    return;
  }
  if (waveShow > 0) waveShow--;
  foeTimer--;
  if (foeTimer <= 0) {
    spawnFoe(api);
    foeTimer = api.max(24, 108 - wave * 9) + api.rndi(30);
  }

  foeN = 0;
  for (i = 0; i < FOE_MAX; i++) {
    if (!foeOn[i]) continue;
    foePh[i] += 0.14;
    dx = px - foeX[i];
    dy = py - foeY[i];
    d = api.sqrt(dx * dx + dy * dy);
    if (d > 0.001) {
      fspeed = FOE_SPEED * foeSpeedMul(foeType[i]);     // team sets the pace; wave 6 and 10 kick it up
      foeVx[i] = api.lerp(foeVx[i], dx / d * fspeed, 0.045);
      foeVy[i] = api.lerp(foeVy[i], dy / d * fspeed, 0.045);
    }
    foeX[i] += foeVx[i];
    foeY[i] += foeVy[i];

    // nose follows the course, same rule as the ship — held while barely moving
    fs = foeVx[i] * foeVx[i] + foeVy[i] * foeVy[i];
    if (fs > 0.1225) foeAng[i] = api.atan2(foeVy[i], foeVx[i]) + 1.5708;

    if (pulseOn === 1) {                            // pulse ring shreds foes
      var pd = api.dist(px, py, foeX[i], foeY[i]);
      if (pd < pulseR + PULSE_BAND && pd > pulseR - PULSE_BAND * 3) {
        killFoe(api, i);
        continue;
      }
    }

    if (invuln === 0 && d < 13) {
      hitPlayer(api, i);
      continue;
    }

    foeLive[foeN++] = i;                            // survived the step: it can be pushed
  }

  separateFoes(api);
}

/* Nobody steers around anybody — every foe still flies straight at the player.
   Afterwards, each pair that ended up inside FOE_SEP is fixed twice over:

     position — shoved apart along the line between them, half the overlap each,
                which is what actually guarantees the sprites don't stack;
     velocity — the part of their closing speed that points along that same line
                is cancelled, so a foe that has run into the crowd stops driving
                into it and only its sideways motion survives.

   The velocity half is what keeps this quiet. Position pushes alone leave the
   back of a pile ramming forward every step and the solver undoing it every
   step: the pack visibly buzzes (~1.8 px/foe/step of pure jitter) and the ones
   in the middle still get squeezed together. Cancelling the closing speed drops
   that to ~0.2 px and holds the pack within a pixel of the full FOE_SEP even
   with the whole pool sitting on one point, so a single pass per step is enough.
   Foes only ever spread sideways, never away from the player: sideways motion is
   untouched and the chase lerp re-aims them every step, so the crowd wraps round
   the ship instead of being held off by it.

   Cost: the pass walks only the live foes and the pool caps at FOE_MAX (48), so
   the pair loop peaks near a thousand squared-distance tests — about 6 us a step,
   measured; less than clearing and refilling the uniform grid that would replace
   it, and most tests bail on the compare before the sqrt. */
function separateFoes(api) {
  var i, j, a, b, dx, dy, d2, d, nx, ny, push, closing;
  for (i = 0; i < foeN; i++) {
    a = foeLive[i];
    for (j = i + 1; j < foeN; j++) {
      b = foeLive[j];
      dx = foeX[b] - foeX[a];
      dy = foeY[b] - foeY[a];
      d2 = dx * dx + dy * dy;
      if (d2 >= FOE_SEP2) continue;
      if (d2 < 0.0001) {                            // exactly stacked: pick a side
        nx = (a & 1) ? 1 : -1;
        ny = (a & 2) ? 1 : -1;
        push = 0.5;
      } else {
        d = api.sqrt(d2);
        nx = dx / d;
        ny = dy / d;
        push = (FOE_SEP - d) * 0.5;                 // half the overlap, per side
        closing = (foeVx[b] - foeVx[a]) * nx + (foeVy[b] - foeVy[a]) * ny;
        if (closing < 0) {                          // still driving into each other
          closing *= 0.5;
          foeVx[a] += nx * closing; foeVy[a] += ny * closing;
          foeVx[b] -= nx * closing; foeVy[b] -= ny * closing;
        }
      }
      foeX[a] -= nx * push; foeY[a] -= ny * push;
      foeX[b] += nx * push; foeY[b] += ny * push;
    }
  }
}

/* --------------------------------------------------------------- upgrades -- */

/* Deal three of the six, at random and never the same one twice on one menu.
   An upgrade that would do nothing this instant — a pulse when the bank is full,
   a heart when nothing is missing — is left out of the deck rather than dealt as
   a dud card, which still leaves at least four to draw from. */
function openUpgrades(api) {
  var i, j, n = 0, t;

  for (i = 0; i < UP_N; i++) {
    if (i === UP_PULSE && charges >= chargeCap) continue;
    if (i === UP_LIFE && lives >= maxLives) continue;
    upDeck[n++] = i;
  }
  for (i = 0; i < 3; i++) {                        // partial Fisher-Yates: 3 draws
    j = i + api.rndi(n - i);
    t = upDeck[i]; upDeck[i] = upDeck[j]; upDeck[j] = t;
    upPick[i] = upDeck[i];
  }

  state = ST_UPGRADE;
  upSel = 1;                                       // start on the middle card
  upMx = api.mx();                                 // ... whatever the cursor is over
  upMy = api.my();
  upTimer = 12;                                    // swallow the press that got here
  snd.vol = 0.6;
  snd.rate = 0.7;
  api.sfx("powerup", snd);
}

function updateUpgrades(api) {
  var i, h;

  for (i = 0; i < COIN_MAX; i++) if (coinOn[i]) coinPh[i] += 0.09;   // keep bobbing
  if (upTimer > 0) { upTimer--; return; }

  if (api.btnp(0)) moveSel(api, -1);
  if (api.btnp(1)) moveSel(api, 1);

  /* pointer (and a finger, which the engine reports as the mouse too): hovering
     highlights a card, a click takes it — no travel to a confirm button. Only a
     pointer that has *moved* claims the highlight: a cursor left sitting on a
     card would otherwise drag the selection back every frame and the arrow keys
     could never leave it. */
  h = cardAt(api.mx(), api.my());
  if (!touchUi && api.mouse_over() && (api.mx() !== upMx || api.my() !== upMy)) {
    upMx = api.mx();
    upMy = api.my();
    if (h >= 0 && h !== upSel) moveSel(api, 0, h);
  }
  if (api.mbtnp(0) && h >= 0) {
    upSel = h;
    takeUpgrade(api);
    return;
  }

  if (press(api, BT_FIRE) || api.btnp(BT_PAUSE)) takeUpgrade(api);
}

function moveSel(api, step, to) {
  upSel = to === undefined ? (upSel + step + 3) % 3 : to;
  snd.vol = 0.3;
  snd.rate = 1.5;
  api.sfx("coin", snd);
}

/* One row of the pause menu: plain white text, or — for the selected row — the
   same lit box the upgrade cards use, so the two menus read as one language. */
function drawPauseRow(api, cx, y, label, sel) {
  if (sel) {
    api.rectfill(cx - 74, y - 8, 148, 16, 1);
    api.rect(cx - 74, y - 8, 148, 16, 12);
  }
  api.print(label, cx, y, 7, 10);
}

function selectPause(api, to) {
  pauseSel = to;
  snd.vol = 0.3;
  snd.rate = 1.5;
  api.sfx("coin", snd);
}

function cardAt(x, y) {
  var i, cx, cy = MENU_Y + CARD_Y;
  if (y < cy || y > cy + CARD_H) return -1;
  for (i = 0; i < 3; i++) {
    cx = MENU_X + MENU_PAD + i * (CARD_W + CARD_GAP);
    if (x >= cx && x <= cx + CARD_W) return i;
  }
  return -1;
}

/* Apply the card, then let the wave in: the squad only rolls on once the choice
   is made, and a moment of grace covers whatever drifted onto the ship while the
   menu was up. */
function takeUpgrade(api) {
  var i, n, id = upPick[upSel];

  if (id === UP_PULSE) charges = chargeCap;
  else if (id === UP_PULSE_MAX) { chargeCap++; charges++; }
  else if (id === UP_SPEED) spdMul += SPD_STEP;
  else if (id === UP_LIFE) lives = maxLives;
  else if (id === UP_LIFE_MAX) { maxLives++; lives++; }
  else rangeMul += RANGE_STEP;

  state = ST_RESUME;                 // a beat of stillness before the squad lets loose
  resumeTimer = RESUME_FRAMES;
  waveShow = 90;
  invuln = api.max(invuln, 60);
  snd.vol = 0.7;
  snd.rate = 1;
  api.sfx("charge", snd);
  spawnSparks(api, px, py, 10, 11, 1.6);

  n = api.min(WAVE_BURST_MAX, WAVE_BURST + (wave - 1) * 5);
  for (i = 0; i < n; i++) spawnFoe(api);
  setTrack(api, trackFor(lives, maxLives), 0.4);   // a FULL LIFE pick drops it back down
}

function killFoe(api, i) {
  foeOn[i] = 0;
  score += 25;
  spawnSparks(api, foeX[i], foeY[i], 10, 8, 2.2);
  snd.vol = 0.45;
  snd.rate = 1.3 + api.rnd(0.2);
  api.sfx("hit", snd);
}

function hitPlayer(api, i) {
  foeOn[i] = 0;
  lives--;
  invuln = INVULN;
  shake = 22;
  spawnSparks(api, px, py, 22, 8, 3);
  snd.vol = 0.9;
  snd.rate = 0.9;
  api.sfx("hit", snd);
  pvx *= -0.6;
  pvy *= -0.6;
  if (lives <= 0) {
    lives = 0;
    state = ST_DEAD;
    deadTimer = 40;
    if (score > best) best = score;
    setTrack(api, "theme_calm", 0.9);             // same tune, all the pressure gone
    spawnSparks(api, px, py, 40, 9, 4);
  } else {
    setTrack(api, trackFor(lives, maxLives), 0.4); // fewer hearts, faster tune
  }
}

/* The other ending: the squad survived all the way to WIN_WAVE. Mirrors
   hitPlayer's death branch — same button-swallow beat, same calm tune, just a
   green burst instead of a red one. Whatever squad is still on screen goes out
   with it: every live foe pops in the same burst killFoe uses, so the field
   reads as a clean sweep rather than the survivors just freezing in place. */
function winGame(api) {
  var i;
  for (i = 0; i < FOE_MAX; i++) {
    if (!foeOn[i]) continue;
    foeOn[i] = 0;
    spawnSparks(api, foeX[i], foeY[i], 10, 8, 2.2);
  }
  state = ST_WIN;
  deadTimer = 40;
  if (score > best) best = score;
  setTrack(api, "theme_calm", 0.9);
  spawnSparks(api, px, py, 40, 11, 4);
}

function updateSparks(api) {
  for (var i = 0; i < SPARK_MAX; i++) {
    if (spLife[i] <= 0) continue;
    spX[i] += spVx[i];
    spY[i] += spVy[i];
    spVx[i] *= 0.93;
    spVy[i] *= 0.93;
    spRot[i] += spSpin[i];
    spLife[i]--;
  }
}

/* --------------------------------------------------------------------- draw -- */

function draw(api) {
  var i, t, s, x, y;

  api.camera();
  api.spr("backdrop", 0, 0);

  if (shake > 0) api.camera(api.rnd(shake * 0.4) - shake * 0.2, api.rnd(shake * 0.4) - shake * 0.2);
  api.clip(0, FIELD_TOP, W, H - FIELD_TOP);

  /* coins */
  for (i = 0; i < COIN_MAX; i++) {
    if (!coinOn[i]) continue;
    t = api.sin(coinPh[i]);                        // plain blit: no opts, fastest path
    api.sspr("sprites", SP_COIN * TILE, 0, TILE, TILE,
      coinX[i] - 8 + t * 0.5, coinY[i] - 8 + t * 1.5, TILE, TILE);
  }

  /* foes — the ship's own hull in enemy paint, nose on the course, rolling as it
     chases. The team (red / dark red / light red) is the sprite lookup, set once
     at spawn — no per-frame branching. */
  for (i = 0; i < FOE_MAX; i++) {
    if (!foeOn[i]) continue;
    opt.a = 1;
    opt.rot = foeAng[i] + api.sin(foePh[i]) * 0.12;
    opt.fx = false;
    api.spr(FOE_SPRITE[foeType[i]], foeX[i] - 8, foeY[i] - 8, opt);
  }

  /* sparks */
  for (i = 0; i < SPARK_MAX; i++) {
    if (spLife[i] <= 0) continue;
    t = spLife[i] / spMax[i];
    s = 4 + t * 8;
    opt.a = t;
    opt.rot = spRot[i];
    opt.fx = false;
    api.sspr("sprites", SP_SPARK * TILE, 0, TILE, TILE,
      spX[i] - s * 0.5, spY[i] - s * 0.5, s, s, opt);
  }

  /* pulse ring */
  if (pulseOn === 1) {
    t = 1 - pulseR / (PULSE_MAX * rangeMul);
    api.circ(px, py, pulseR, 12);
    api.circ(px, py, pulseR - 2, t > 0.4 ? 7 : 12);
    api.circ(px, py, pulseR * 0.72, 1);
  }

  /* ship — grey hull while there is no pulse to fire, green once charges are
     capped out (nothing more to gain from chasing coins right now). Hidden on
     death (it's destroyed), but kept on screen — steady, no invuln blink —
     through the win panel: the run ended with the ship still flying. */
  if (state !== ST_DEAD &&
      (state === ST_PAUSE || state === ST_INTRO || state === ST_UPGRADE || state === ST_WIN ||
       invuln === 0 || api.frame() % 8 < 5)) {
    opt.a = 1;
    opt.rot = pang;
    opt.fx = false;
    if (charges <= 0) {
      api.spr("ship_empty", px - 8, py - 8, opt);
    } else if (charges >= chargeCap) {
      api.spr("ship_full", px - 8, py - 8, opt);
    } else {
      api.sspr("sprites", SP_SHIP * TILE, 0, TILE, TILE, px - 8, py - 8, TILE, TILE, opt);
    }
  }

  /* mouse reticle */
  if (!touchUi && api.mouse_over() && state === ST_PLAY) {
    x = api.flr(api.mx());
    y = api.flr(api.my());
    t = api.mbtn(0) ? 10 : 5;
    api.line(x - 5, y, x - 2, y, t);
    api.line(x + 2, y, x + 5, y, t);
    api.line(x, y - 5, x, y - 2, t);
    api.line(x, y + 2, x, y + 5, t);
  }

  api.clip();
  api.camera();

  if (state === ST_INTRO) {
    // the strip's SCORE/SHIPS labels are baked into the backdrop: black them out
    // so the title card gets the whole screen, and keep the divider rules
    api.rectfill(0, 0, W, FIELD_TOP - 2, 0);
    y = (H - TITLE_H) * 0.5;
    api.spr("title", (W - TITLE_W) * 0.5, y);
    api.text_align("center", "middle");
    if (introTimer === 0 && api.frame() % 40 < 26) {
      api.print(touchUi ? "TAP X TO START" : "PRESS X TO START",
        W * 0.5, y + TITLE_H - 28, 10, 12);
    }
    api.text_align("left", "top");
  } else {
    drawHud(api);
  }

  if (state === ST_DEAD) {
    y = (H - PANEL_H) * 0.5;
    api.spr("gameover", (W - PANEL_W) * 0.5, y, panelAlpha);
    api.text_align("center", "middle");
    api.print("SCORE " + score, W * 0.5, y + 58, 10, 14);
    api.print("BEST " + best, W * 0.5, y + 76, 7, 10);
    api.text_align("left", "top");
  } else if (state === ST_WIN) {
    y = (H - PANEL_H) * 0.5;
    api.spr("gamewin", (W - PANEL_W) * 0.5, y, panelAlpha);
    api.text_align("center", "middle");
    api.print("SCORE " + score, W * 0.5, y + 58, 10, 14);
    api.print("BEST " + best, W * 0.5, y + 76, 7, 10);
    api.text_align("left", "top");
  } else if (state === ST_PAUSE) {
    y = (H - PAUSE_PANEL_H) * 0.5;
    api.spr("paused", (W - PANEL_W) * 0.5, y, panelAlpha);
    api.text_align("center", "middle");
    api.print("SCORE " + score, W * 0.5, y + 54, 10, 14);
    api.print("WAVE " + wave, W * 0.5, y + 72, 7, 10);
    // touch keeps its baked one-tap hints; keyboard/mouse gets the live menu,
    // the selected row boxed like an upgrade card so the highlight can move
    if (!touchUi) {
      drawPauseRow(api, W * 0.5, y + 98, "CONTINUE", pauseSel === PAUSE_CONTINUE);
      drawPauseRow(api, W * 0.5, y + 114, "RESTART", pauseSel === PAUSE_RESTART);
    }
    api.text_align("left", "top");
  } else if (state === ST_UPGRADE) {
    drawUpgrades(api);
  }

  drawStick(api);                                  // always last: on top of the panels
  drawPause(api);
  drawFire(api);
}

/* The cards. Frame and both fixed lines come off one blit; the wave number, the
   three icons and their labels are the only per-frame text. */
function drawUpgrades(api) {
  var i, id, x, y = MENU_Y + CARD_Y, sel;

  api.spr("upmenu", MENU_X, MENU_Y, panelAlpha);
  api.text_align("center", "middle");
  api.print("WAVE " + wave, MENU_X + MENU_W * 0.5, MENU_Y + 20, 12, 20);

  for (i = 0; i < 3; i++) {
    id = upPick[i];
    x = MENU_X + MENU_PAD + i * (CARD_W + CARD_GAP);
    sel = i === upSel;
    if (sel) {                                     // the pick lights up, twice framed
      api.rectfill(x, y, CARD_W, CARD_H, 1);
      api.rect(x, y, CARD_W, CARD_H, 7);
      api.rect(x + 1, y + 1, CARD_W - 2, CARD_H - 2, 12);
    } else {
      api.rect(x, y, CARD_W, CARD_H, 5);
    }
    api.spr(UP_ICON[id], x + (CARD_W - ICON_SZ) * 0.5, y + 12);
    api.print(UP_NAME[id], x + CARD_W * 0.5, y + 62, 7, 12);
    api.print(UP_DESC[id], x + CARD_W * 0.5, y + 82, sel ? 12 : 7, 8);
  }
  api.text_align("left", "top");
}

function drawHud(api) {
  var i, x, hw, hstep, hx, winC = state === ST_WIN;

  // win/complete: the SCORE/SHIPS labels are baked into the backdrop in a dim
  // grey (they're meant to recede during play) — on the win panel every label
  // reads white instead, printed fresh over the baked ones at the same spot.
  if (winC) {
    api.text_align("left", "middle");
    api.print("SCORE", 8, 12, 7);
    api.text_align("right", "middle");
    api.print("SHIPS", W - 76 - HUD_R, 12, 7);
  }

  api.text_align("left", "middle");
  api.print(pad6(score), 52, 12, 7, 12);

  api.text_align("right", "middle");
  // blinks for a moment when the wave turns over, so the incoming squad is read
  api.print("WAVE " + wave, W - 150 - HUD_R, 12,
    waveShow > 0 && api.frame() % 12 < 6 ? 8 : 12, 10);
  api.text_align("left", "top");

  /* Hearts: every slot the run has bought, the empty ones ghosted rather than
     dropped, so a MAX LIFE pick shows up the instant it is taken. They share a
     fixed 66 px gutter and shrink to fit it, so the row can never run into the
     SHIPS label or off the edge however long the run gets. */
  hstep = api.min(20, 66 / maxLives);
  hw = api.min(TILE, hstep - 3);
  hx = W - 6 - HUD_R - maxLives * hstep;
  for (i = 0; i < maxLives; i++) {
    x = hx + i * hstep;
    if (i < lives) {
      api.sspr("sprites", SP_HEART * TILE, 0, TILE, TILE, x, 12 - hw * 0.5, hw, hw);
    } else {
      opt.a = 0.22;
      opt.rot = 0;
      opt.fx = false;
      api.sspr("sprites", SP_HEART * TILE, 0, TILE, TILE, x, 12 - hw * 0.5, hw, hw, opt);
    }
  }

  /* pulse charges — same idea, tighter dots once the bank outgrows its space */
  hstep = chargeCap > 8 ? 8 : 12;
  for (i = 0; i < chargeCap; i++) {
    x = 152 + i * hstep;
    if (i < charges) api.circfill(x, 12, hstep > 8 ? 4 : 3, 12);
    else api.circ(x, 12, hstep > 8 ? 4 : 3, 1);
  }
  api.text_align("left", "middle");
  // label wears the hull's own two colors — blue with a pulse banked, grey without —
  // so the HUD and the ship always read as one state; on the win panel it's just
  // white like the rest of that text, not a state to read anymore
  api.print("X", 138, 12, winC ? 7 : (charges > 0 ? SHIP_COL : SHIP_EMPTY_COL), 10);
  api.text_align("left", "top");

  /* volume, shown for a moment after the wheel moves */
  if (volShow > 0) {
    api.rectfill(W * 0.5 - 40, H - 26, 80, 12, 0);
    api.rect(W * 0.5 - 40, H - 26, 80, 12, 5);
    api.rectfill(W * 0.5 - 37, H - 23, 74 * volume, 6, 12);
    api.text_align("center", "bottom");
    api.print("VOLUME", W * 0.5, H - 28, 6, 8);
    api.text_align("left", "top");
  }
}

function pad6(n) {
  return n < 10 ? "00000" + n
    : n < 100 ? "0000" + n
    : n < 1000 ? "000" + n
    : n < 10000 ? "00" + n
    : n < 100000 ? "0" + n
    : "" + n;
}
