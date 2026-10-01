// storygen.js -- MOONFALL story generator + offline validator (design doc §7.4)
//
// Builds 8 board layouts and 32 nights, proves each night is fair and solvable,
// and emits packed data strings for the cart plus a human-readable transcript.
//
//   node storygen.js            validate + report
//   node storygen.js --emit     also write moonfall-data.lua + SHIPPED.md
//
// Nothing here runs on the cart. The cart only reads the packed strings, so this
// script is the single authority on whether a night is fair -- there is no second
// implementation in Lua that could drift away from it.

'use strict';
const fs = require('fs');

// ---------------------------------------------------------------- constants

// landmark ids 1..11
const LM = ['', 'CHAPEL', 'MILL', 'INN', 'FORGE', 'GRAVEYARD', 'MANOR',
            'WATCHTOWER', 'WELL', 'MOUNTAIN', 'FOREST', 'LAKE'];
const SIGHT_BLOCK = [9, 10];       // §5.3: MOUNTAIN and FOREST block line of sight

// villager ids 1..8
const NAMES = ['', 'bela', 'mara', 'otto', 'vesna', 'dragan', 'luka', 'iris', 'stefan'];

const W = 6, H = 6, NC = W * H;

const PLACE = 0, WITNESS = 1, SIGN = 2, NONE = 3;   // clause types
const ADJ = 0, VIS = 1, FAR = 2, NEAR = 3;          // sign predicates

const B32 = '0123456789abcdefghijklmnopqrstuv';
const enc = n => B32[n];

const DAY_TICKS = 40, TALK_COST = 2;                // §4

// ---------------------------------------------------------------- rng

function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const pick = (rng, arr) => arr[Math.floor(rng() * arr.length)];
function shuffled(rng, arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ---------------------------------------------------------------- geometry

const cx = c => c % W;
const cy = c => Math.floor(c / W);
const cheb = (a, b) => Math.max(Math.abs(cx(a) - cx(b)), Math.abs(cy(a) - cy(b)));
const manh = (a, b) => Math.abs(cx(a) - cx(b)) + Math.abs(cy(a) - cy(b));

function makeGeo(lmCell) {
  const blockers = new Set(SIGHT_BLOCK.map(l => lmCell[l]));
  function visible(a, b) {
    if (a === b) return false;
    const ax = cx(a), ay = cy(a), bx = cx(b), by = cy(b);
    if (ax !== bx && ay !== by) return false;
    const dx = Math.sign(bx - ax), dy = Math.sign(by - ay);
    let x = ax + dx, y = ay + dy;
    while (x !== bx || y !== by) {
      if (blockers.has(y * W + x)) return false;
      x += dx; y += dy;
    }
    return true;
  }
  const adjacent = (a, b) => manh(a, b) === 1;
  // §5.3: a sighting is only possible within 2 cells, or along a clear line
  const canSee = (a, b) => a !== b && (cheb(a, b) <= 2 || visible(a, b));
  return { visible, adjacent, canSee };
}

// ---------------------------------------------------------------- layouts

// 11 impassable landmarks, 8 villager cells, 1 player start.
// §3 connectivity contract: the free cells must stay one connected region, so
// routing can never be severed by where the landmarks fell.
function buildLayout(seed) {
  const rng = mulberry32(seed);
  const cells = new Array(NC).fill(0);
  const order = shuffled(rng, [...Array(NC).keys()]);
  const lmCell = new Array(12).fill(-1);
  for (let l = 1; l <= 11; l++) { lmCell[l] = order[l - 1]; cells[order[l - 1]] = l; }

  const free = [];
  for (let i = 0; i < NC; i++) if (!cells[i]) free.push(i);
  const seen = new Set([free[0]]);
  const stack = [free[0]];
  while (stack.length) {
    const c = stack.pop();
    for (const n of nbrs(c)) if (!cells[n] && !seen.has(n)) { seen.add(n); stack.push(n); }
  }
  if (seen.size !== free.length) return null;

  // the clause generator needs geometric material to work with
  const geo = makeGeo(lmCell);
  let adjPairs = 0, visPairs = 0;
  for (let a = 1; a <= 11; a++) for (let b = a + 1; b <= 11; b++) {
    if (geo.adjacent(lmCell[a], lmCell[b])) adjPairs++;
    if (geo.visible(lmCell[a], lmCell[b])) visPairs++;
  }
  if (adjPairs < 3 || visPairs < 6) return null;

  // every landmark must be able to witness at least two others, or a villager
  // standing there could never speak a WITNESS clause at all
  for (let a = 1; a <= 11; a++) {
    let n = 0;
    for (let b = 1; b <= 11; b++) if (a !== b && geo.canSee(lmCell[a], lmCell[b])) n++;
    if (n < 2) return null;
  }

  const spots = shuffled(rng, free);
  const vcell = spots.slice(0, 8);
  const start = spots[8];
  let tot = 0, n = 0;
  for (let i = 0; i < 8; i++) for (let j = i + 1; j < 8; j++) { tot += manh(vcell[i], vcell[j]); n++; }
  if (tot / n < 3.2) return null;      // keep the eight spread across the board

  return { seed, cells, lmCell, vcell, start, geo, dist: allDistances(cells) };
}

function nbrs(c) {
  const x = cx(c), y = cy(c), o = [];
  if (x > 0) o.push(c - 1);
  if (x < W - 1) o.push(c + 1);
  if (y > 0) o.push(c - W);
  if (y < H - 1) o.push(c + W);
  return o;
}

// BFS over passable cells: landmarks block, villagers do not (§3)
function allDistances(cells) {
  const d = [];
  for (let s = 0; s < NC; s++) {
    const row = new Array(NC).fill(Infinity);
    if (cells[s]) { d.push(row); continue; }
    row[s] = 0;
    const q = [s];
    for (let h = 0; h < q.length; h++) {
      for (const n of nbrs(q[h])) {
        if (!cells[n] && row[n] === Infinity) { row[n] = row[q[h]] + 1; q.push(n); }
      }
    }
    d.push(row);
  }
  return d;
}

function chooseLayouts(count) {
  const out = [];
  for (let s = 1; out.length < count && s < 200000; s++) {
    const L = buildLayout(s);
    if (L) out.push(L);
  }
  if (out.length < count) throw new Error('not enough valid layouts');
  return out;
}

// ---------------------------------------------------------------- clause truth

// pos: villager id -> landmark id. True iff clause `c` spoken by `sp` holds.
function clauseTrue(c, sp, pos, L, attack) {
  const cell = l => L.lmCell[l];
  if (c.t === PLACE) return pos[sp] === c.a;
  if (c.t === WITNESS) {
    if (pos[c.a] !== c.b) return false;
    return L.geo.canSee(cell(pos[sp]), cell(c.b));
  }
  if (c.t === SIGN) {
    const p = cell(pos[sp]);
    if (c.a === ADJ) return L.geo.adjacent(p, cell(c.b));
    if (c.a === VIS) return L.geo.visible(p, cell(c.b));
    if (c.a === FAR) return cheb(p, cell(attack)) >= 3;
    return cheb(p, cell(attack)) <= 1;
  }
  return true;
}

// ---------------------------------------------------------------- the solver
//
// Given the villagers the player has HEARD, which of the eight could still be
// the wolf? Candidate w survives if SOME assignment of everyone's night position
// is consistent with every heard statement, under the game's two published rules:
//   - the wolf, and only the wolf, was at the attack site
//   - innocents never lie; the wolf's own words prove nothing either way
// Unheard villagers' positions stay unknown. That is what stops a frame
// (pattern C) collapsing into a one-conversation puzzle.

function candidates(story, heard) {
  const { L, attack, clauses, claim } = story;
  const out = [];
  for (let w = 1; w <= 8; w++) {
    const pos = new Array(9).fill(0);
    let bad = false;
    const assign = (v, l) => {
      if (pos[v] && pos[v] !== l) bad = true; else pos[v] = l;
    };
    assign(w, attack);
    for (const s of heard) if (s !== w) assign(s, claim[s]);

    // pin every subject named by a heard innocent, to a fixed point
    for (let pass = 0; pass < 3 && !bad; pass++) {
      for (const s of heard) {
        if (s === w) continue;                       // the wolf's words bind nothing
        for (const c of clauses[s]) if (c.t === WITNESS) assign(c.a, c.b);
      }
    }
    // only the wolf can have been at the attack site
    if (!bad) for (let v = 1; v <= 8; v++) if (v !== w && pos[v] === attack) bad = true;

    // now every heard innocent's every clause must actually hold
    if (!bad) for (const s of heard) {
      if (s === w) continue;
      for (const c of clauses[s]) {
        if (c.t === WITNESS && !pos[c.a]) { bad = true; break; }
        if (!clauseTrue(c, s, pos, L, attack)) { bad = true; break; }
      }
      if (bad) break;
    }
    if (!bad) out.push(w);
  }
  return out;
}

// The same question answered the slow, obvious way: actually search for a
// consistent set of night positions instead of propagating constraints.
// Villagers nobody mentions are left out of the search -- they appear in no
// constraint, and there is always a landmark left that is not the attack site.
// Used only by --selftest, to check the fast solver above.
function candidatesBrute(story, heard) {
  const { L, attack, clauses, claim } = story;
  const out = [];
  for (let w = 1; w <= 8; w++) {
    const base = { [w]: attack };
    for (const s of heard) if (s !== w) base[s] = claim[s];

    const vars = new Set();
    for (const s of heard) {
      if (s === w) continue;
      for (const c of clauses[s]) if (c.t === WITNESS && !(c.a in base)) vars.add(c.a);
    }
    const list = [...vars];

    const holds = pos => {
      for (let v = 1; v <= 8; v++) if (v !== w && pos[v] === attack) return false;
      for (const s of heard) {
        if (s === w) continue;
        for (const c of clauses[s]) {
          if (c.t === WITNESS && !pos[c.a]) return false;
          if (!clauseTrue(c, s, pos, L, attack)) return false;
        }
      }
      return true;
    };
    const search = (i, pos) => {
      if (i === list.length) return holds(pos);
      for (let l = 1; l <= 11; l++) {
        if (search(i + 1, { ...pos, [list[i]]: l })) return true;
      }
      return false;
    };
    if (search(0, base)) out.push(w);
  }
  return out;
}

// Only 255 non-empty subsets of eight villagers -- enumerate every one of them.
function analyse(story) {
  const solving = [];
  for (let mask = 1; mask < 256; mask++) {
    const heard = [];
    for (let v = 1; v <= 8; v++) if (mask & (1 << (v - 1))) heard.push(v);
    const cand = candidates(story, heard);
    if (cand.length === 1 && cand[0] === story.wolf) solving.push(heard);
  }
  if (!solving.length) return null;
  const seen = new Set(solving.map(s => s.join(',')));
  const minimal = solving.filter(s => {
    for (let i = 0; i < s.length; i++) {
      const sub = s.filter((_, j) => j !== i);
      if (sub.length && seen.has(sub.join(','))) return false;
    }
    return true;
  });
  const minSize = Math.min(...solving.map(s => s.length));
  return {
    solving, minimal, minSize,
    // independent tells: shortest distinct ways in (§5.5)
    tells: minimal.filter(s => s.length <= minSize + 1).length,
    small: solving.filter(s => s.length <= 4).length,
  };
}

// ---------------------------------------------------------------- routing

// Cheapest day that hears everyone in `set`: walking + 2 ticks per conversation.
function routeCost(L, set) {
  if (!set.length) return 0;
  let best = Infinity;
  const walk = (rest, at, acc) => {
    if (acc >= best) return;
    if (!rest.length) { best = acc; return; }
    for (let i = 0; i < rest.length; i++) {
      const n = L.vcell[rest[i] - 1];
      if (!isFinite(L.dist[at][n])) return;
      walk(rest.filter((_, j) => j !== i), n, acc + L.dist[at][n]);
    }
  };
  walk(set, L.start, 0);
  return best + TALK_COST * set.length;
}

// ---------------------------------------------------------------- generation

const otherLandmarks = exclude => {
  const o = [];
  for (let l = 1; l <= 11; l++) if (!exclude.includes(l)) o.push(l);
  return o;
};

// opts.depth        max clauses per villager (uniform, so terseness is never a tell)
// opts.extraVoucher a third independent way in, for the gentler nights
function buildStory(L, pattern, wolf, attack, seed, opts) {
  const { depth, extraVoucher } = opts;
  const rng = mulberry32(seed);
  const cell = l => L.lmCell[l];

  // --- ground truth (§5.1): the wolf was at the attack site; no innocent was
  const truth = new Array(9).fill(0);
  truth[wolf] = attack;
  const pool = shuffled(rng, otherLandmarks([attack]));
  let pi = 0;
  for (let v = 1; v <= 8; v++) if (v !== wolf) truth[v] = pool[pi++];

  // innocents claim the truth; the wolf claims a place nobody else occupied,
  // so no night ever hands the player a free duplicate-claim tell
  const claim = truth.slice();
  const vacant = otherLandmarks(truth.slice(1).filter(Boolean));
  if (!vacant.length) return null;
  claim[wolf] = pick(rng, vacant);
  if (claim[wolf] === attack) return null;

  const clauses = {};
  for (let v = 1; v <= 8; v++) clauses[v] = [{ t: PLACE, a: claim[v], b: 0 }];
  const innocents = [];
  for (let v = 1; v <= 8; v++) if (v !== wolf) innocents.push(v);
  const used = new Set();          // villagers already carrying a scripted clause

  const trueSigns = at => {
    const o = [];
    for (let l = 1; l <= 11; l++) {
      if (l === at) continue;
      if (L.geo.adjacent(cell(at), cell(l))) o.push({ t: SIGN, a: ADJ, b: l });
      if (L.geo.visible(cell(at), cell(l))) o.push({ t: SIGN, a: VIS, b: l });
    }
    if (cheb(cell(at), cell(attack)) >= 3) o.push({ t: SIGN, a: FAR, b: 0 });
    if (cheb(cell(at), cell(attack)) <= 1) o.push({ t: SIGN, a: NEAR, b: 0 });
    return o;
  };
  const falseSigns = at => {
    const o = [];
    for (let l = 1; l <= 11; l++) {
      if (l === at) continue;
      if (!L.geo.adjacent(cell(at), cell(l))) o.push({ t: SIGN, a: ADJ, b: l });
      if (!L.geo.visible(cell(at), cell(l))) o.push({ t: SIGN, a: VIS, b: l });
    }
    if (cheb(cell(at), cell(attack)) < 3) o.push({ t: SIGN, a: FAR, b: 0 });
    if (cheb(cell(at), cell(attack)) > 1) o.push({ t: SIGN, a: NEAR, b: 0 });
    return o;
  };

  // An honest accusation: v truthfully saw the wolf at the attack site, and a
  // third villager independently vouches for v. Two conversations, no wolf needed.
  function accusationPair(exclude) {
    const seers = innocents.filter(v =>
      !exclude.has(v) && L.geo.canSee(cell(truth[v]), cell(attack)));
    for (const b of shuffled(rng, seers)) {
      const vouch = innocents.filter(v =>
        v !== b && !exclude.has(v) && L.geo.canSee(cell(truth[v]), cell(truth[b])));
      if (vouch.length) return { accuser: b, voucher: pick(rng, vouch) };
    }
    return null;
  }
  function addAccusation(pair) {
    pair.ref = { t: WITNESS, a: wolf, b: attack };
    clauses[pair.accuser].push(pair.ref);
    clauses[pair.voucher].push({ t: WITNESS, a: pair.accuser, b: truth[pair.accuser] });
    used.add(pair.accuser); used.add(pair.voucher);
  }

  // --- the primary tell (§5.5)
  let tell = null;
  if (pattern === 'B') {
    // the wolf's own sensory detail is impossible from the place they claim
    const opts = falseSigns(claim[wolf]);
    if (!opts.length) return null;
    const c = pick(rng, opts);
    clauses[wolf].push(c);
    tell = { kind: "B", speaker: wolf, ref: c };
  } else if (pattern === 'D') {
    // the wolf reports a sighting they could not possibly have made from there
    const opts = innocents
      .filter(s => !L.geo.canSee(cell(claim[wolf]), cell(truth[s])))
      .map(s => ({ t: WITNESS, a: s, b: truth[s] }));
    if (!opts.length) return null;
    const c = pick(rng, opts);
    clauses[wolf].push(c);
    tell = { kind: "D", speaker: wolf, ref: c };
  } else if (pattern === 'A') {
    const p = accusationPair(used);
    if (!p) return null;
    addAccusation(p);
    tell = { kind: 'A', ...p, speaker: p.accuser, ref: p.ref };
  } else if (pattern === 'C') {
    // The frame: the wolf swears an innocent was at the attack site. That is the
    // only lie that makes the accused look guilty rather than merely mistaken --
    // it leaves exactly two suspects, and only a third villager can break the tie.
    if (!L.geo.canSee(cell(claim[wolf]), cell(attack))) return null;
    const targets = innocents.filter(x =>
      innocents.some(v => v !== x && L.geo.canSee(cell(truth[v]), cell(truth[x]))));
    if (!targets.length) return null;
    const x = pick(rng, targets);
    const vouch = innocents.filter(v => v !== x && L.geo.canSee(cell(truth[v]), cell(truth[x])));
    const y = pick(rng, vouch);
    const frame = { t: WITNESS, a: x, b: attack };
    clauses[wolf].push(frame);
    clauses[y].push({ t: WITNESS, a: x, b: truth[x] });
    used.add(x); used.add(y);
    tell = { kind: 'C', framed: x, voucher: y, speaker: wolf, ref: frame };
  }

  // --- the second independent tell. Always present: §1's luck pillar is only
  // fair because more than one subset of conversations cracks every night.
  const second = accusationPair(used);
  if (!second) return null;
  addAccusation(second);
  tell.second = second;

  // --- a third way in, on the gentler nights: another voucher for the primary
  // accuser, so a different pair of conversations also settles the tie
  if (extraVoucher && tell.accuser) {
    const more = innocents.filter(v =>
      v !== tell.accuser && !used.has(v) &&
      L.geo.canSee(cell(truth[v]), cell(truth[tell.accuser])));
    if (!more.length) return null;
    const v = pick(rng, more);
    clauses[v].push({ t: WITNESS, a: tell.accuser, b: truth[tell.accuser] });
    used.add(v);
  } else if (extraVoucher && tell.framed) {
    const more = innocents.filter(v =>
      v !== tell.framed && !used.has(v) &&
      L.geo.canSee(cell(truth[v]), cell(truth[tell.framed])));
    if (!more.length) return null;
    const v = pick(rng, more);
    clauses[v].push({ t: WITNESS, a: tell.framed, b: truth[tell.framed] });
    used.add(v);
  }

  // --- filler, so the tell is not conspicuous by being the only detail.
  // Nobody volunteers an unscripted sighting of the wolf: a truthful sighting of
  // the wolf is by definition an accusation, and would add an unplanned tell.
  const witnessOpts = v => innocents
    .filter(s => s !== v && s !== wolf && L.geo.canSee(cell(truth[v]), cell(truth[s])))
    .map(s => ({ t: WITNESS, a: s, b: truth[s] }));

  const padTo = (v, at, out) => {
    while (clauses[v].length < depth) {
      const o = [];
      if (!clauses[v].some(c => c.t === SIGN)) o.push(...trueSigns(at));
      if (!clauses[v].some(c => c.t === WITNESS)) o.push(...out(v));
      if (!o.length) break;
      clauses[v].push(pick(rng, o));
    }
  };
  for (const v of innocents) padTo(v, truth[v], witnessOpts);

  // The wolf's camouflage: details that do hold up at the place they claim, so
  // the wolf is never the one villager with less to say than everybody else.
  padTo(wolf, claim[wolf], () => innocents
    .filter(s => L.geo.canSee(cell(claim[wolf]), cell(truth[s])))
    .map(s => ({ t: WITNESS, a: s, b: truth[s] })));

  const story = { L, pattern, wolf, attack, truth, claim, clauses, tell, seed, depth };

  // --- hard checks (§7.4 steps 3-5). Any failure discards the story.
  // Everyone says exactly as much as everyone else: how much a villager
  // volunteers must never be evidence in itself.
  for (let v = 1; v <= 8; v++) if (clauses[v].length !== depth) return null;
  for (const v of innocents) {
    for (const c of clauses[v]) if (!clauseTrue(c, v, truth, L, attack)) return null;
  }
  if (clauseTrue(clauses[wolf][0], wolf, truth, L, attack)) return null;  // PLACE must be a lie

  const a = analyse(story);
  if (!a) return null;
  story.stats = a;
  if (a.minSize > 6) return null;

  const costs = a.minimal.map(s => routeCost(L, s)).filter(isFinite);
  if (!costs.length) return null;
  story.cost = Math.min(...costs);
  if (story.cost > DAY_TICKS) return null;      // the day must actually be winnable

  // how many innocents nobody vouches for -- the fair red herrings of §5.4
  story.herrings = innocents.filter(v =>
    !Object.values(clauses).some(cs => cs.some(c => c.t === WITNESS && c.a === v))).length;

  // Where the convicting sentence sits, so the verdict screen can point at it.
  // §8.8: a deduction game that hides its solution teaches nothing.
  story.tellV = tell.speaker;
  story.tellC = clauses[tell.speaker].indexOf(tell.ref);
  if (story.tellC < 0) return null;
  return story;
}

// ---------------------------------------------------------------- campaign
//
// §7.2 targets. The validator is the authority: minimum-conversation counts are
// whatever the inference rules actually permit, and SHIPPED.md records them.
// Difficulty is carried by the two levers that do work -- how many independent
// tells a night has, and how expensive its cheapest solving route is.

const CAMPAIGN = [
  [1, 'B', 'otto', 'MILL', 3], [1, 'A', 'vesna', 'INN', 3],
  [2, 'B', 'luka', 'LAKE', 3], [2, 'D', 'stefan', 'WATCHTOWER', 3],
  [3, 'A', 'mara', 'FOREST', 3], [3, 'C', 'bela', 'CHAPEL', 3],
  [2, 'A', 'luka', 'WELL', 3], [4, 'B', 'dragan', 'FORGE', 3],
  [4, 'D', 'iris', 'MANOR', 2], [1, 'C', 'stefan', 'GRAVEYARD', 2],
  [5, 'A', 'otto', 'WELL', 2], [5, 'B', 'vesna', 'MOUNTAIN', 2],
  [3, 'D', 'dragan', 'LAKE', 2], [6, 'C', 'mara', 'INN', 2],
  [6, 'A', 'bela', 'FOREST', 2], [4, 'C', 'luka', 'CHAPEL', 2],
  [7, 'B', 'iris', 'GRAVEYARD', 2], [7, 'A', 'stefan', 'MILL', 2],
  [5, 'D', 'bela', 'MANOR', 2], [8, 'C', 'otto', 'WATCHTOWER', 2],
  [8, 'A', 'dragan', 'WELL', 2], [6, 'B', 'luka', 'MOUNTAIN', 2],
  [7, 'C', 'vesna', 'FORGE', 2], [1, 'D', 'mara', 'LAKE', 2],
  [8, 'B', 'bela', 'INN', 2], [2, 'C', 'iris', 'WELL', 2],
  [5, 'C', 'mara', 'GRAVEYARD', 2], [4, 'A', 'vesna', 'MOUNTAIN', 2],
  [3, 'B', 'stefan', 'CHAPEL', 2], [6, 'D', 'otto', 'WELL', 2],
  [8, 'D', 'luka', 'FOREST', 2], [7, 'A', 'dragan', 'MANOR', 2],
];

function generateCampaign(layouts) {
  const nights = [];
  CAMPAIGN.forEach((row, idx) => {
    const [li, pattern, wolfName, siteName, tells] = row;
    const night = idx + 1;
    const L = layouts[li - 1];
    const wolf = NAMES.indexOf(wolfName), attack = LM.indexOf(siteName);
    // The two levers that actually move difficulty: a third way in, and how much
    // each villager volunteers. Fewer optional clauses means less corroboration
    // on the board, so fewer four-conversation days happen to crack the night.
    const opts = { extraVoucher: tells >= 3, depth: tells >= 3 ? 3 : 2 };

    let best = null;
    for (let s = 1; s <= 900; s++) {
      const st = buildStory(L, pattern, wolf, attack, night * 100003 + s, opts);
      if (!st) continue;
      if (st.stats.tells < 2) continue;              // §1: never a single way in
      if (st.herrings < 2) continue;                 // §5.4 needs its red herrings
      const score = Math.abs(st.stats.tells - tells) * 6
                  + Math.abs(st.herrings - 2) * 2
                  - Math.min(st.cost, 20) * 0.1;     // prefer a route worth planning
      if (!best || score < best.score) best = { st, score };
      if (score <= -1.9) break;
    }
    if (!best) throw new Error('night ' + night + ': no valid story');
    best.st.night = night;
    best.st.layoutIndex = li;
    best.st.targetTells = tells;
    nights.push(best.st);
  });
  return nights;
}

// ---------------------------------------------------------------- prose
// Mirrors the cart's phrase bank exactly, so the transcript reads as the player
// will hear it and doubles as the regression fixture.

// A villager's voice has to survive being dropped at any of the eleven landmarks,
// so the verbs stay neutral and the character lives in the rhythm instead.
const PLACE_T = [
  'i was at the ^ all night. ',              // bela, priest -- formal, short
  'i was at the ^ from dusk to dawn. ',      // mara, herbalist -- precise about time
  'i was down at the ^, half asleep. ',      // otto, miller -- sleepy
  'oh, i was over at the ^ all evening. ',   // vesna, innkeeper -- gossipy
  'the ^. all night. ',                      // dragan, blacksmith -- one clause
  'i was out at the ^, where else. ',        // luka, gravedigger -- grim
  'i stayed near the ^, as i always do. ',   // iris, widow -- mournful
  'post: the ^, dusk to dawn. ',             // stefan, watchman -- log entry
];
const WIT_T = [
  '~ was at the ^. i saw them. ',
  'i passed ~ by the ^, near midnight. ',
  '~ went past the ^, i think. ',
  'and ~! over at the ^, plain as day. ',
  '~ was at the ^. ',
  '~ was by the ^. i saw that much. ',
  'poor ~ was out by the ^. ',
  'sighting: ~, at the ^. ',
];
// Four phrasings per predicate, chosen by speaker, so a night never prints the
// same sentence three times over.
const SIGN_T = [
  ['the ^ stood right beside me. ', 'i could have touched the ^. ',
   'the ^ was at my shoulder all night. ', 'i was near enough to hear the ^. '],
  ['i could see the ^ across the field. ', 'the ^ was in plain view. ',
   'nothing stood between me and the ^. ', 'i had a clear line to the ^. '],
  ['the scream came from far off. ', 'the cry was a long way away. ',
   'whatever screamed, it was distant. ', 'i heard it faint, from far off. '],
  ['the scream was close. i ran the other way. ', 'it screamed almost on top of me. ',
   'the cry was near. too near. ', 'i heard it close by, and hid. '],
];

function clauseText(c, sp) {
  if (c.t === PLACE) return PLACE_T[sp - 1].replace('^', LM[c.a]);
  if (c.t === WITNESS) return WIT_T[sp - 1].replace('~', NAMES[c.a]).replace('^', LM[c.b]);
  return SIGN_T[c.a][(sp - 1) % 4].replace('^', LM[c.b] || '');
}
const statementText = (story, v) => story.clauses[v].map(c => clauseText(c, v)).join('').trim();

// ---------------------------------------------------------------- packing

function packLayout(L) {
  const cells = L.cells.slice();
  L.vcell.forEach((c, i) => { cells[c] = 12 + i; });
  cells[L.start] = 20;
  return cells.map(enc).join('');
}

function packNight(n) {
  let s = enc(n.wolf) + enc(n.layoutIndex) + enc(n.attack) + enc(n.tellV) + enc(n.tellC);
  for (let v = 1; v <= 8; v++) {
    for (let i = 0; i < 3; i++) {
      const c = n.clauses[v][i];
      s += c ? enc(c.t) + enc(c.a) + enc(c.b) : enc(NONE) + '00';
    }
  }
  return s;
}

// ---------------------------------------------------------------- report

function asciiBoard(L) {
  const short = ['', 'CHA', 'MIL', 'INN', 'FRG', 'GRV', 'MAN', 'TWR', 'WEL', 'MTN', 'FOR', 'LAK'];
  const g = [];
  for (let y = 0; y < H; y++) {
    const row = [];
    for (let x = 0; x < W; x++) {
      const c = y * W + x;
      let s = ' .. ';
      if (L.cells[c]) s = short[L.cells[c]].padEnd(4);
      const vi = L.vcell.indexOf(c);
      if (vi >= 0) s = NAMES[vi + 1].slice(0, 4).padEnd(4);
      if (c === L.start) s = ' @@ ';
      row.push('[' + s + ']');
    }
    g.push('  r' + (y + 1) + ' ' + row.join(' '));
  }
  return g.join('\n') + '\n\n  @@ = player start   UPPERCASE = impassable landmark\n';
}

// Check the fast solver against the brute-force one on every subset of every
// night. If these two ever disagree, the whole fairness argument is void.
function selftest(nights) {
  let checked = 0, bad = 0;
  for (const n of nights) {
    for (let mask = 1; mask < 256; mask++) {
      const heard = [];
      for (let v = 1; v <= 8; v++) if (mask & (1 << (v - 1))) heard.push(v);
      const a = candidates(n, heard).join(',');
      const b = candidatesBrute(n, heard).join(',');
      checked++;
      if (a !== b) {
        bad++;
        if (bad <= 5) {
          console.log(`  night ${n.night} heard {${heard.map(v => NAMES[v])}}: ` +
            `fast [${a}] vs brute [${b}]`);
        }
      }
    }
  }
  console.log('selftest: ' + checked + ' subsets checked, ' + bad + ' disagreements');
  return bad === 0;
}

function main() {
  const layouts = chooseLayouts(8);
  const nights = generateCampaign(layouts);

  if (process.argv.includes('--selftest')) {
    process.exit(selftest(nights) ? 0 : 1);
  }

  let md = '# MOONFALL — shipped campaign\n\n';
  md += 'Generated and proved by `storygen.js`. Per design §7.2 the validator is the\n';
  md += 'authority; this is what actually shipped.\n\n';
  md += '**Minimum conversations is not a free parameter.** Under the Rule of Evidence\n';
  md += '(§5.4) only a contradiction or a board-impossible statement convicts, so a night\n';
  md += 'bottoms out at **1** conversation when the wolf incriminates themself (patterns\n';
  md += 'B, D) and at **2** when the tie between an accuser and the accused has to be\n';
  md += 'broken by a corroborator (patterns A, C). No arrangement of these clauses can\n';
  md += 'require 3+; difficulty is carried instead by how many independent tells a night\n';
  md += 'has and how expensive its cheapest solving route is.\n\n';

  md += '## Layouts\n\n';
  layouts.forEach((L, i) => {
    md += '### L' + (i + 1) + ' (seed ' + L.seed + ')\n\n```\n' + asciiBoard(L) + '```\n\n';
  });

  md += '## Nights\n\n';
  md += '| night | layout | pattern | wolf | attack site | tells | min talks | routes<=4 | red herrings | cheapest day |\n';
  md += '|---|---|---|---|---|---|---|---|---|---|\n';
  for (const n of nights) {
    md += `| ${n.night} | L${n.layoutIndex} | ${n.pattern} | ${NAMES[n.wolf]} | ${LM[n.attack]} ` +
      `| ${n.stats.tells} | ${n.stats.minSize} | ${n.stats.small} | ${n.herrings} | ${n.cost}/${DAY_TICKS} |\n`;
  }

  md += '\n## Transcripts\n\n';
  for (const n of nights) {
    md += `### Night ${n.night} — L${n.layoutIndex}, pattern ${n.pattern}, ` +
      `wolf **${NAMES[n.wolf]}**, attack site ${LM[n.attack]}\n\n`;
    md += '```\n' + asciiBoard(n.L) + '```\n\n';
    for (let v = 1; v <= 8; v++) {
      md += `- **${NAMES[v]}**${v === n.wolf ? ' *(wolf)*' : ''} — "${statementText(n, v)}"\n`;
    }
    md += '\nsolvable by: ' + n.stats.minimal
      .filter(s => s.length <= n.stats.minSize + 1).slice(0, 6)
      .map(s => '{' + s.map(v => NAMES[v]).join(', ') + '}').join(' · ') +
      `  (cheapest day ${n.cost} ticks)\n\n`;
  }

  const costs = nights.map(n => n.cost);
  console.log('layout seeds:  ' + layouts.map(L => L.seed).join(', '));
  console.log('nights:        ' + nights.length + '/32');
  console.log('min talks:     ' + nights.map(n => n.stats.minSize).join(' '));
  console.log('tells:         ' + nights.map(n => n.stats.tells).join(' '));
  console.log('red herrings:  ' + nights.map(n => n.herrings).join(' '));
  console.log('cheapest day:  ' + costs.join(' '));
  console.log('max cost:      ' + Math.max(...costs) + '/' + DAY_TICKS);

  if (process.argv.includes('--emit')) {
    const lay = layouts.map(packLayout).join('');
    const nig = nights.map(packNight).join('');
    fs.writeFileSync('moonfall-data.lua',
      '-- generated by storygen.js -- do not edit by hand\n' +
      'lay="' + lay + '"\nnig="' + nig + '"\n');
    fs.writeFileSync('SHIPPED.md', md);
    console.log('\nwrote moonfall-data.lua (' + (lay.length + nig.length) + ' data chars)');
    console.log('wrote SHIPPED.md');
  }
}

if (require.main === module) main();
module.exports = { chooseLayouts, buildStory, analyse, candidates, routeCost,
                  NAMES, LM, statementText, asciiBoard, packLayout, packNight, CAMPAIGN };
