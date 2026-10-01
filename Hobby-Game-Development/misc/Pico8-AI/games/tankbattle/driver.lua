-- driver.lua: appended to game.p8 by mkharness.js. synthetic input + invariants.
sb,spb=0,0
function btn(b,pl) if b==nil then return sb end return (sb\(2^b))%2>=1 end
function btnp(b,pl) if b==nil then return sb end return ((sb\(2^b))%2>=1) and ((spb\(2^b))%2<1) end
_ru,_rd=_update,_draw
fails,tf,phase=0,0,0
function ok(c,msg) if not c then fails+=1 printh("FAIL: "..msg.." @"..tf) end end
function _draw() end
srand(7)
-- stats
ric_seen,kill_seen,brick_seen,spawn_seen,hit_seen=false,0,false,false,false
levels_done={}
function _update()
 tf+=1 if tf==1 then for i=0,2 do dset(i,0) end sel=1 end
 sb=0
 if phase==0 then
  -- intro: press right twice (should not move past unlocked), then start
  if tf==5 then sb=2 end
  if tf==10 then sb=32 end
  if state=="game" and wipe==0 then phase=1 ok(lv==1,"start level 1") end
 elseif phase==1 then
  -- random-ish play: alternate facing/moving and fire often
  local c=tf%60
  if c<20 then sb=4 elseif c<30 then sb=1 elseif c<40 then sb=2 else sb=8 end
  if tf%7==0 then sb+=32 end
  if tf%97<3 then sb+=16 end
  -- force level progress: after 900 frames on a level, mark the quota met
  if tk_lv==nil then tk_lv=0 end
  tk_lv+=1
  if tk_lv>300 and lc==0 and go==0 and card==0 then kills=quota end
  if lc==-1 or (wipe>0 and lc<0) then levels_done[lv]=true tk_lv=0 lives=3 end
  if lv>=21 then phase=2 end
  if go>0 then lives=3 go=0 end -- keep playing through deaths
 end
 -- run one frame of the real game
 _ru()
 _rd()
 spb=sb
 -- invariants
 if state=="game" then
  for e in all(ens) do
   ok(e.cx>=0 and e.cy>=0 and e.cx+e.w<=cols and e.cy+e.w<=rows,"enemy in grid")
   for i=0,e.w-1 do for j=0,e.w-1 do
    ok(not fget(tile(e.cx+i,e.cy+j),0) or (e.w==2 and fget(tile(e.cx+i,e.cy+j),3)),"enemy on solid "..e.t)
   end end
   if e.fl>0 then hit_seen=true end
  end
  for b in all(buls) do if b.bnc>0 then ric_seen=true end end
  ok(#parts<=48,"particle cap")
  ok(ammo>=0 and ammo<=4,"ammo range")
  if #ens>0 then spawn_seen=true end
  kill_seen=max(kill_seen,kills)
  for x=0,cols-1 do for y=0,rows-1 do if tile(x,y)==17 then brick_seen=true end end end
 end
 if phase==2 or tf>9000 then
  local n=0 for i=1,20 do if levels_done[i] then n+=1 end end
  printh("levels played="..n.." kills_max="..kill_seen.." ric="..tostr(ric_seen).." brick="..tostr(brick_seen).." spawn="..tostr(spawn_seen).." hit="..tostr(hit_seen).." score="..score.." frames="..tf)
  ok(n==20,"all 20 levels reached")
  ok(brick_seen,"brick damage seen")
  ok(spawn_seen,"enemies spawned")
  ok(hit_seen,"enemy hit seen")
  printh("FAILS="..fails)
  extcmd("shutdown")
 end
end
