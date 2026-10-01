-->8
-- test driver (appended to __lua__ by verify.js; not part of the game)

-- capture the real callbacks BEFORE overriding them, or the tests end up
-- calling their own stubs and proving nothing
_rd=_draw
_ru=_update60

fails=0
checks=0
kchecks=0

-- Measure text rather than assuming 4px a character: LANDMARK names are drawn
-- in p8scii's uppercase set, and the dialogue panel is only 115px wide.
-- print() returns the rightmost x; drawing offscreen keeps it invisible.
function txtw(s) return print(s,0,-40,0) end

function ok(c,m)
 checks+=1
 if checks>=1000 then checks=0 kchecks+=1 end
 if not c then
  fails+=1
  if fails<=20 then printh("fail: "..m) end
 end
end

-- every night must decode into a well-formed, self-consistent story
function testdata()
 for n=1,32 do
  loadnight(n)
  local p="n"..n.." "
  ok(wolf>=1 and wolf<=8,p.."wolf "..wolf)
  ok(site>=1 and site<=11,p.."site "..site)
  ok(tellv>=1 and tellv<=8,p.."tellv")
  ok(stm[tellv] and stm[tellv][tellc]~=nil,p.."tell clause missing")

  local nl,nv,ns=0,0,0
  for i=0,35 do
   local c=cells[i]
   ok(c>=0 and c<=20,p.."cell value "..c)
   if c>=1 and c<=11 then nl+=1
   elseif c>=12 and c<=19 then nv+=1
   elseif c==20 then ns+=1 end
  end
  ok(nl==11,p.."landmarks "..nl)
  ok(nv==8,p.."villagers "..nv)
  ok(ns==1,p.."starts "..ns)
  for l=1,11 do ok(lmc[l]~=nil,p.."landmark "..l.." missing") end
  ok(cells[pcell]==20,p.."start cell")
  -- the player must not begin inside a wall
  ok(cells[pcell]<1 or cells[pcell]>11,p.."start is impassable")

  for v=1,8 do
   ok(#stm[v]>=2 and #stm[v]<=3,p.."v"..v.." has "..#stm[v].." clauses")
   ok(claim[v]>=1 and claim[v]<=11,p.."v"..v.." claim")
   ok(vcl[v]~=nil,p.."v"..v.." has no cell")
   local vc=cells[vcl[v]]
   ok(vc>=12 and vc<=19,p.."v"..v.." not on a villager cell")
   for ci=1,#stm[v] do
    local c=stm[v][ci]
    ok(c[1]>=0 and c[1]<=2,p.."clause type "..c[1])
    local s=ctext(v,c)
    ok(#s>4,p.."v"..v.." short text")
    for i=1,#s do
     local ch=sub(s,i,i)
     ok(ch~="~" and ch~="^",p.."unfilled placeholder: "..s)
    end
    for l in all(wrap(s,22)) do
     ok(#l<=22,p.."overlong line ("..#l.."): "..l)
     ok(txtw(l)<=115,p.."line too wide ("..txtw(l).."px): "..l)
    end
   end
  end

  -- the two rules the whole deduction rests on
  ok(claim[wolf]~=site,p.."the wolf claims the attack site")
  for v=1,8 do
   if v~=wolf then ok(claim[v]~=site,p.."innocent "..v.." claims the attack site") end
  end
 end
end

-- walking, talking, and the clock
function testboard()
 loadnight(7)
 ok(tk==0,"clock does not start at zero")
 local st=pcell
 -- walking into every wall must cost nothing
 for d=0,3 do
  local before=pcell
  local x,y=pcell%6,pcell\6
  if d==0 then x-=1 elseif d==1 then x+=1 elseif d==2 then y-=1 else y+=1 end
  local blocked = x<0 or x>5 or y<0 or y>5 or (cells[y*6+x]>=1 and cells[y*6+x]<=11)
  local t0=tk
  trymove(d)
  if blocked then
   ok(pcell==before,"moved into a wall")
   ok(tk==t0,"a blocked move cost time")
  else
   ok(pcell~=before,"a legal move did not happen")
   ok(tk==t0+1,"a move cost "..(tk-t0).." ticks")
  end
 end

 -- a conversation costs exactly two ticks, and only counts once
 loadnight(7)
 local t0=tk
 opendlg(3)
 ok(tk==t0+2,"a talk cost "..(tk-t0).." ticks")
 ok(heard[3],"talking did not mark the villager heard")
 ok(nheard==1,"heard count "..nheard)
 opendlg(3)
 ok(nheard==1,"re-hearing double counted")
 ok(tk==t0+4,"re-hearing was free")

 -- the clock must never run past nightfall
 loadnight(7)
 for i=1,200 do addtick(1) end
 ok(tk==40,"clock overran to "..tk)
 ok(clockstr()=="18:00","clock reads "..clockstr())
 loadnight(7)
 ok(clockstr()=="08:00","day starts at "..clockstr())
 addtick(23)
 ok(clockstr()=="13:45","23 ticks reads "..clockstr())

 -- every villager must be reachable, or the night is unwinnable
 loadnight(7)
 local seen={}
 local q={pcell}
 seen[pcell]=true
 local h=1
 while h<=#q do
  local c=q[h] h+=1
  local x,y=c%6,c\6
  for d=0,3 do
   local nx,ny=x,y
   if d==0 then nx-=1 elseif d==1 then nx+=1 elseif d==2 then ny-=1 else ny+=1 end
   if nx>=0 and nx<6 and ny>=0 and ny<6 then
    local n=ny*6+nx
    if not seen[n] and (cells[n]<1 or cells[n]>11) then
     seen[n]=true add(q,n)
    end
   end
  end
 end
 for v=1,8 do ok(seen[vcl[v]],"villager "..v.." is unreachable") end
end

-- Every tile the board draws must exist and have art in it. The sprite numbers
-- are spelled out rather than recomputed from lmspr(), so that a test cannot
-- quote the code back at itself and agree with whatever it believes.
function testsprites()
 local want=split"32,34,36,38,40,42,44,46,64,66,68"
 for l=1,11 do
  ok(lmspr(l)==want[l],"landmark "..l.." maps to sprite "..lmspr(l))
 end
 local function ink(n)
  local sx,sy=(n%16)*8,(n\16)*8
  local c=0
  for y=sy,sy+15 do
   for x=sx,sx+15 do
    if sget(x,y)~=0 then c+=1 end
   end
  end
  return c
 end
 -- board tiles are opaque and full-bleed; figures keep a transparent margin
 for l=1,11 do ok(ink(want[l])>120,"landmark "..l.." tile is blank ("..ink(want[l])..")") end
 -- The ground tile is deliberately not solid: a dotted black seam runs down its
 -- right edge and along its bottom, and that seam is the only thing that makes
 -- the 6x6 grid legible. Assert the art AND the seam, or a regression that ate
 -- one of them would still pass.
 ok(ink(70)>200,"the ground tile is blank ("..ink(70)..")")
 local seam=0
 for y=32,47 do
  if sget(63,y)==0 then seam+=1 end
 end
 ok(seam>=6,"the ground tile has lost its grid seam ("..seam..")")
 for v=1,8 do ok(ink((v-1)*2)>60,"villager "..v.." sprite is blank") end
 ok(ink(72)>60,"the player token is blank")
 ok(ink(74)>60,"the wolf sprite is blank")
end

-- the display ramp must stay inside the palette at every hour
function testramp()
 loadnight(1)
 for t=0,40 do
  tk=t
  setramp()
  local s=rmps[tk>=40 and 5 or tk>=38 and 4 or tk>=34 and 3 or tk>=28 and 2 or 1]
  ok(#s==16,"ramp string is "..#s.." long")
  for c=0,15 do
   local v=d32(s,c+1)
   ok(v>=0 and v<=15,"ramp maps to "..v)
  end
 end
 pal()
end

-- run every draw path once, so a nil in any screen surfaces here
function testdraw()
 loadnight(1)
 for i=1,560,40 do scr=0 it=i _rd() end
 scr=1 mi=1 _rd() mi=3 _rd()
 scr=2 for p=1,5 do hpage=p _rd() end
 scr=3 _rd()
 scr=4 tk=0 _rd()
 tk=30 _rd()
 tk=40 _rd()
 for v=1,8 do
  tk=0
  opendlg(v)
  _rd()
  while dtick\2<dtotal do dtick+=1 end
  _rd()
  for p=1,#stm[v] do
   setpage(p)
   -- assert the game's own wrapping, not a width the test picked itself
   ok(#dlines<=5,"dialog page needs "..#dlines.." lines")
   for l in all(dlines) do ok(#l<=22,"dialog line ("..#l.."): "..l) end
   _rd()
  end
 end
 -- the how-to legend: two text columns beside a 16px tile, so a name that
 -- grew would either collide with the next column or leave the screen
 ok(#htl==5,"how-to has "..#htl.." page titles")
 ok(#split(howd,"/",false)==2,"the rule of evidence is no longer two pages")
 ok(#natd==4,"the wild page needs 4 notes")
 for l=1,8 do
  ok(txtw(lmn[l])<=40,"legend building name too wide: "..lmn[l])
 end
 for l=9,11 do
  ok(25+txtw(lmn[l])<=127,"legend nature name overruns: "..lmn[l])
 end
 for i=1,4 do
  ok(25+txtw(natd[i])<=127,"legend note overruns: "..natd[i])
 end
 for v=1,8 do
  ok(txtw(nm[v])<=32,"legend villager name too wide: "..nm[v])
 end

 -- the notebook's widest possible row must stay inside its frame
 -- the page name must clear the position strip, which starts at 92
 for i=1,6 do
  ok(6+txtw(ntitle[i])<=90,"notebook page name overruns: "..ntitle[i])
 end
 -- the legend, now drawn inside the notebook frame as well as full screen
 for i=1,8 do
  local x=6+((i-1)%2)*62
  ok(x+19+txtw(lmn[i])<=123,"legend building name overruns frame: "..lmn[i])
  local xe=4+((i-1)%4)*30
  ok(xe+15-#nm[i]*2>=4,"legend villager name clips left: "..nm[i])
  ok(xe+15+#nm[i]*2<=123,"legend villager name overruns frame: "..nm[i])
 end
 for l=1,11 do
  ok(50+txtw(lmn[l])<=124,"notebook attack line overruns: "..lmn[l])
  -- page 1: name column must clear the location column, which must fit
  ok(54+txtw("@"..lmn[l])<=124,"claims location overruns: "..lmn[l])
  -- page 2: subject then @landmark
  ok(80+txtw("@"..lmn[l])<=124,"sightings landmark overruns: "..lmn[l])
 end
 ok(54+txtw("not heard yet")<=124,"claims blank overruns")
 ok(4+txtw("⬅️➡️ flip  ❎ back  🅾️ accuse")<=124,"notebook footer overruns")
 ok(4+txtw("⬆️⬇️ read  ⬅️➡️ flip  ❎ back")<=124,"details footer overruns")
 for v=1,8 do
  ok(14+txtw(nm[v])<=54,"claims name overruns: "..nm[v])
  ok(13+txtw(nm[v])<=38,"sightings speaker overruns: "..nm[v])
  ok(54+txtw(nm[v])<=78,"sightings subject overruns: "..nm[v])
  -- page 3 now holds the name alone, up to the villager pips at x=90
  ok(14+txtw(nm[v])<=88,"details speaker overruns: "..nm[v])
 end
 -- every night must fit its rows in the eight the notebook has
 for n=1,32 do
  loadnight(n)
  local w,g=0,0
  for v=1,8 do
   for q in all(stm[v]) do
    if q[1]==1 then w+=1 end
    if q[1]==2 then g+=1 end
   end
  end
  ok(w<=8,"n"..n.." sightings overflow: "..w)
  ok(g<=8,"n"..n.." details overflow: "..g)
  -- page 3 prints one villager's whole night as wrapped body text:
  -- every line inside the frame, and the block above the footer rule
  for v=1,8 do
   local t=""
   for q in all(stm[v]) do t=t..(t=="" and "" or " ")..ctext(v,q) end
   local ls=wrap(t,29)
   ok(#ls<=11,"n"..n.." details text too tall for "..nm[v]..": "..#ls)
   for l in all(ls) do
    ok(6+txtw(l)<=124,"details line overruns: "..l)
   end
  end
 end
 loadnight(1)
 for v=1,8 do heard[v]=true end
 nheard=8
 scr=6
 for p=1,6 do npage=p _rd() end
 scr=2
 for p=1,5 do hpage=p _rd() end
 scr=6 npage=1
 nheard=0 heard={} _rd() npage=1 _rd()
 loadnight(1)
 scr=7 ai=1 confirm=false _rd()
 ai=8 confirm=true _rd()
 tk=40 _rd()
 scr=8 it=100
 guilty=wolf _rd()
 guilty=(wolf%8)+1 _rd()
 pal()
end

tf=0
function _update60()
 tf+=1
 if tf==2 then
  testdata()
  testboard()
  testsprites()
  testramp()
  testdraw()
  printh("checks="..(kchecks*1000+checks).." fails="..fails)
  printh(fails==0 and "ALL PASS" or "FAILED")
  extcmd("shutdown")
 end
end
function _draw() end
