-- audio harness: what can actually be checked headlessly is *routing* —
-- stat(16..19) reports which sfx each channel was handed. Playback position
-- never advances under -x, so tempo and pattern order are checked offline by
-- verify.js instead.
--   node mktest.js audio && pico8 -x audio.p8
gi=_init
function _draw() end
function _update60() end
nok=0 nbad=0
function ok(c,m) nok+=1 if not c then nbad+=1 printh("FAIL "..m) end end

function _init()
 gi()
 nomu=0 nosf=0

 -- the three music tracks take channels 0-2 and never channel 3
 for t in all({0,8,16}) do
  music(-1) sfx(-1)
  mu(t)
  ok(stat(16)>=20,"track "..t.." ch0 idle, got "..stat(16))
  ok(stat(17)>=20 or stat(17)<0,"track "..t.." ch1, got "..stat(17))
  ok(stat(18)>=20,"track "..t.." ch2 idle, got "..stat(18))
  ok(stat(19)<0,"track "..t.." left channel 3 free, got "..stat(19))
 end

 -- the rapid gameplay sounds are pinned to channel 3 so they can never
 -- steal a music voice (10.1)
 for n in all({0,1,2}) do
  music(-1) sfx(-1)
  mu(8)
  sf(n,3,4)
  ok(stat(19)==n,"sfx "..n.." landed on channel 3, got "..stat(19))
  ok(stat(16)>=20,"music still holds channel 0, got "..stat(16))
 end

 -- the sfx toggle really silences
 sfx(-1) nosf=1
 sf(3,3)
 ok(stat(19)<0,"sfx off means silence, got "..stat(19))
 nosf=0

 -- and the music toggle stops the bed
 nomu=1 mu(8)
 ok(stat(16)<0,"music off stops channel 0, got "..stat(16))
 nomu=0

 -- the level->track mapping from 10.2
 music(-1) loadlv(1)
 ok(curmu==8,"levels 1-8 play track b, got "..curmu)
 loadlv(9)
 ok(curmu==16,"levels 9-16 play track c, got "..curmu)
 loadlv(16)
 ok(curmu==16,"level 16 stays on track c, got "..curmu)
 ensel()
 ok(curmu==0,"the select screen plays track a, got "..curmu)

 printh("AUDIO "..(nok-nbad).."/"..nok.." passed, "..nbad.." failed")
 extcmd("shutdown")
end
