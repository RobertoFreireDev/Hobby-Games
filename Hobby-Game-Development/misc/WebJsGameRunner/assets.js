// Asset manifest — the only way a file enters the game.
// The engine fetches and fully decodes everything listed here before init() runs;
// game.js refers to each asset by its key, never by path.
const ASSETS = {
  // logical resolution + clear color (itch.io's default HTML5 embed size)
  screen: { w: 640, h: 360, bg: 0 },

  // null = built-in PICO-8 16, or supply your own ["#000000", ...]
  palette: null,

  images: {
    sprites: "assets/img/sprites.png",   // packed 16x16 sheet: ship coin enemy heart spark
  },

  sfx: {
    jump:    "assets/sfx/jump.wav",
    coin:    "assets/sfx/coin.wav",
    hit:     "assets/sfx/hit.wav",
    powerup: "assets/sfx/powerup.wav",
    charge:  "assets/sfx/charge.wav",    // a pulse charge banked (tools/sfx.js)
  },

  // four takes on one 8s loop — same tempo, key and chords at every instant, so
  // api.music(name, {sync:true}) swaps between them without losing the beat
  music: {
    theme_calm:  "assets/music/theme_calm.wav",    // menu / game over
    theme:       "assets/music/theme.wav",         // waves 1-2
    theme_drive: "assets/music/theme_drive.wav",   // waves 3-5, adds an arpeggio
    theme_rush:  "assets/music/theme_rush.wav",    // wave 6+, 16ths and a harmony
  },

  // default print style
  text: {
    family: "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",
    size: 10,
    color: 7,
  },
};
