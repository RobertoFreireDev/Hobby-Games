-- stone logic
-- by roberto freire

-- one hue per face, picked to read both on a face-up stone's white top and
-- on the dark grey of one that is still buried
fc={12,11,14,9,8,2}
ndx={-1,1,0,0}
ndy={0,0,-1,1}
chk=0b0101101001011010
d25=0b1101011111010111
p25=0b0010100000101000
rvp={0,0b0001000100010001,chk,d25}
fnm={"dot","bamboo","wave","star","peak","cross"}
nlv=12
-- twelve fixed boards, hardest last. four digits per stone -
-- col row layer face - and the stones are listed in the order
-- that solves the board, so every level carries its own proof.
-- lws holds that board's laws, three digits each: kind, then the
-- face it names, then the second face or the layer.
lvl={}
lws={}
xo={} yo={}

function _init()
 palt(0,false)
 palt(14,true)
 cartdata("rf_stone_logic")
 unl=mid(1,dget(0),nlv) lsel=unl
 rd=1 st=0 tk=0 oh=0 xh=0 tut=0 mus=0
 shk=0 cmb=0 mis=0 el=0 lst=0 mf=0
 pk=false rvs=false pst=nil lnd=false rvl=false why=1
 ts={} prt={} laws={} oc={} twin={}
 mnu(2)
 music(0)
end

-->8
-- rules

function key(c,r,l) return l*100+r*10+c end

function occ(c,r,l)
 if c<0 or c>9 or r<0 or r>9 or l<1 or l>4 then return nil end
 return oc[key(c,r,l)]
end

-- a stone is buried while another stone sits in its cell one layer up, and
-- yours to take the moment that one leaves. no edge to find, no side to keep
-- clear: the layer above is the whole reach rule.
function refresh(q)
 for t in all(ts) do
  local h=occ(t.c,t.r,t.l-1)~=nil
  if t.hd and not h then
   t.fl=0
   if not q then t.rv=8 rvs=true end
  end
  t.hd=h
 end
 if rvs then sfx(5) rvs=false end
end

function anymove()
 local m={}
 for t in all(ts) do
  if not t.hd then
   if m[t.f] then return true end
   m[t.f]=true
  end
 end
 return false
end

-- a face is finished the moment one stack holds more than half of what is
-- left of it: two stones in one stack are never face up together, so they
-- can never be the pair. twin remembers them for the dead-end screen.
function dmd()
 twin={}
 for f=1,6 do
  local n,tot,mx={},0,0
  for t in all(ts) do
   if t.f==f then
    local k=t.c*10+t.r
    n[k]=(n[k] or 0)+1
    tot+=1
    if n[k]>mx then mx=n[k] end
   end
  end
  if mx*2>tot then
   for t in all(ts) do
    if t.f==f then add(twin,t) end
   end
  end
 end
 return #twin>0
end

-->8
-- tutorial

-- four hand-picked boards, one stone per 4 digits: col row layer face
tdat={}
-- the laws each lesson publishes, empty until they are needed
twl={"","","",""}
tmsg={
"take any stone that is face up\nand match two of a face.",
"a match uncovers what was\nunder it, one layer down.",
"a law names what is buried.\n\142 marks a \"?\" with a guess.",
"the tally counts buried stones\ntoo. it is half of every proof."}

function tstart(i)
 tut=i
 mnu(0)
 deal(tdat[i])
 mklaw(twl[i])
end

-- the mark each law kind wears, in the ribbon and everywhere else
lmk={"",">","x"}
lmc={0,11,8}
-- why the board died: nothing on show pairs, and whether a stack is to blame
dmsg={"dead end: nothing matches",
 "dead end: a face is buried"}
-- the example board the page shows when it is not opened from a game
lgd={{2,1,2},{3,3,3},{4,5,4}}

-- leaving the glyph page: back where we came from, or into level 1
function lgo()
 if pst then st=pst pst=nil else start(1) end
end

-->8
-- flow

-- wiping the ladder is not something to do by accident: the first pick only
-- arms it and keeps the menu open, the second one actually clears the save
function clr()
 if cfm then
  unl=1 lsel=1 dset(0,1)
  cfm=false
  menuitem(4,"clear progress",clr)
  sfx(7)
 else
  cfm=true
  menuitem(4,"sure? clear all",clr)
  sfx(2)
  return true
 end
end

-- pause menu by screen: 0 tutorial (nothing at all, the lesson is the
-- only thing to do), 1 board, 2 title
function mnu(g)
 menuitem(1) menuitem(2) menuitem(3) menuitem(4)
 cfm=false
 if g==1 then
  menuitem(1,"retry level",function() start(rd) end)
 elseif g==2 then
  menuitem(1,"how to play",function() st=4 end)
 end
 if g>0 then
  menuitem(3,"law glyphs",function() if st~=6 then pst=st st=6 end end)
 end
 -- only from the title, where there is a ladder to throw away
 if g==2 then menuitem(4,"clear progress",clr) end
end

function mklaw(w)
 laws={}
 for k=1,#w,3 do
  add(laws,{tonum(sub(w,k,k)),tonum(sub(w,k+1,k+1)),tonum(sub(w,k+2,k+2))})
 end
end

-- stand up a board string - four digits a stone - and hand the cursor to the
-- first stone that is already face up
function deal(d)
 ts={} oc={} prt={} twin={}
 local c0,c1,r0,r1=9,0,9,0
 for k=1,#d,4 do
  local t={c=tonum(sub(d,k,k)),r=tonum(sub(d,k+1,k+1)),
           l=tonum(sub(d,k+2,k+2)),f=tonum(sub(d,k+3,k+3)),
           ay=-140,vy=0,rv=0,fl=0}
  t.dly=((t.l-1)*6+t.r)*2
  add(ts,t)
  oc[key(t.c,t.r,t.l)]=t
  c0=min(c0,t.c) c1=max(c1,t.c)
  r0=min(r0,t.r) r1=max(r1,t.r)
 end
 -- one quadrant per layer - 1 top left, 2 top right, 3 bottom left, 4 bottom
 -- right - and the same cell lands on the same spot in all four, so a stack
 -- reads straight across the screen.
 local gw,gh=(c1-c0+1)*11-1,(r1-r0+1)*11-1
 for l=1,4 do
  xo[l]=((l-1)%2)*64+flr((64-gw)/2)-c0*11
  yo[l]=flr((l-1)/2)*50+6+flr((43-gh)/2)-r0*11
 end
 refresh(true)
 cur=nil
 for t in all(ts) do
  if not t.hd and (not cur or key(t.c,t.r,t.l)<key(cur.c,cur.r,cur.l)) then cur=t end
 end
 cx=tx(cur) cy=ty(cur) cvx=0 cvy=0
 sel=nil el=0 cmb=0 mis=0 lst=0 nst=#ts
 pk=false rvl=false st=2
 sfx(9)
end

-- one of the twelve fixed boards. nothing is generated and there is no
-- seed: the level is the puzzle. the laws were true when it was dealt and
-- they name every buried stone between them.
function start(n)
 rd=n tut=0
 mnu(1)
 deal(lvl[n])
 mklaw(lws[n])
 mus=0 music(0)
end

function tx(t) return t.c*11+xo[t.l]+5 end
function ty(t) return t.r*11+yo[t.l]+5 end

function near(a)
 local b,bd=nil,32000
 for t in all(ts) do
  local d=abs(tx(t)-tx(a))+abs(ty(t)-ty(a))
  if d<bd then bd=d b=t end
 end
 return b
end

-- the cursor visits buried stones too, so they can be marked - but while a
-- stone is held it only visits the ones it can pair with
function pick(t)
 if sel then return not t.hd and t.f==sel.f end
 return true
end

-- is there another stone face up carrying this face?
function pair(t)
 for o in all(ts) do
  if o~=t and not o.hd and o.f==t.f then return true end
 end
 return false
end

function nav(d)
 local ox,oy=tx(cur),ty(cur)
 local b,bd=nil,32000
 for t in all(ts) do
  if pick(t) and t~=cur then
   local ax,ay=tx(t)-ox,ty(t)-oy
   local al=ax*ndx[d]+ay*ndy[d]
   local pe=ax*ndy[d]-ay*ndx[d]
   if al>0 then
    local q=al+abs(pe)*2.5
    if q<bd then bd=q b=t end
   end
  end
 end
 if not b then
  -- nothing that way: wrap to the far side
  local w=-32000
  for t in all(ts) do
   if pick(t) then
    local ax,ay=tx(t)-ox,ty(t)-oy
    local q=-(ax*ndx[d]+ay*ndy[d])-abs(ax*ndy[d]-ay*ndx[d])
    if q>w then w=q b=t end
   end
  end
 end
 if b and b~=cur then
  cur=b
  sfx(0,-1,cur.l-1,1)
 end
end

-- o on a buried stone steps its mark round the faces and back to none. a
-- buried stone wears dark grey and a face-up one white, so a mark is never
-- mistaken for the real thing.
function flag()
 if cur and cur.hd then
  cur.fl=(cur.fl+1)%7
  sfx(0,-1,cur.fl,1)
 elseif sel then
  sel=nil sfx(2)
 end
end

function press()
 if not cur then return end
 -- a buried stone gets the same refusal as any other stone that cannot be
 -- taken, but no miss against the clean-run bonus: it is a slip, not a plan
 if cur.hd then
  sfx(4) shk=3
  mf=8 ma=cur mb=cur
  return
 end
 if sel==cur then
  sel=nil sfx(2) return
 end
 if sel then
  mtch(sel,cur)
 elseif pair(cur) then
  sel=cur sfx(1)
 else
  sfx(4) shk=3 mis+=1
  mf=8 ma=cur mb=cur
 end
end

function mtch(a,b)
 local q={a,b}
 for i=1,2 do
  local t=q[i]
  oc[key(t.c,t.r,t.l)]=nil
  del(ts,t)
  burst(t)
 end
 sel=nil
 if el-lst<90 then cmb+=1 else cmb=1 end
 lst=el
 sfx(3,-1,min(cmb-1,4)*4,4)
 shk=2
 refresh()
 cur=near(b)
 if #ts<1 then
  if tut>0 then
   -- next lesson, then the law page and the first real round
   if tut<4 then tstart(tut+1) else tut=5 pst=nil st=6 end
   return
  end
  st=3
  scr=nst*100
  if mis<1 then scr+=500 end
  if rd>=unl and unl<nlv then unl=rd+1 dset(0,unl) end
  music(-1) sfx(6)
 elseif not anymove() then
  -- only when nothing left face up can pair. a board that can no longer be
  -- cleared is still played out: the player keeps every match they can see.
  if tut>0 then tstart(tut) return end
  dmd()
  why=#twin>0 and 2 or 1
  st=5 rvl=true sel=nil
  oh=0 xh=0 pk=false           -- nothing held over from the last frame
  music(-1) sfx(7)
 elseif tut<1 and #ts<9 and mus<2 then
  mus=2 music(2)
 end
end

function burst(t)
 for i=1,8 do
  local a=rnd(1)
  add(prt,{x=tx(t),y=ty(t),
   vx=cos(a)*rnd(2),vy=sin(a)*rnd(2)-1,
   t=12+rnd(8),c=10})
 end
end

function dust(t)
 for i=1,3 do
  add(prt,{x=tx(t)+rnd(8)-4,y=ty(t)+5,
   vx=rnd(1)-0.5,vy=-rnd(0.4),t=8,c=6})
 end
end

function play()
 -- nothing is live until the last stone is down: no cursor, no
 -- button, and the clock has not started
 if not lnd then return end
 el+=1
 -- one step a frame. a diagonal on the pad reports two directions at once,
 -- and running both used to walk the cursor out and straight back again.
 for b=0,3 do
  if btnp(b) then nav(b+1) break end
 end
 if btn(4) then
  oh+=1
 else
  if oh>0 and oh<12 then flag() end
  oh=0
 end
 if btn(5) then
  xh+=1
 else
  if xh>0 and xh<15 then press() end
  xh=0
 end
 pk=xh>=15
end

function _update()
 tk+=1
 shk*=0.75
 if mf>0 then mf-=1 end
 -- sparkle cascade over a cleared board
 if st==3 and tk%3==0 then
  add(prt,{x=rnd(128),y=10+rnd(90),vx=0,vy=-0.25,t=16,c=10})
 end
 for i=#prt,1,-1 do
  local p=prt[i]
  p.x+=p.vx p.y+=p.vy p.vy+=0.15 p.t-=1
  if p.t<0 then deli(prt,i) end
 end
 lnd=true
 for t in all(ts) do
  if t.dly>0 then
   t.dly-=1 lnd=false
  elseif t.ay<0 then
   t.vy+=1.4 t.ay+=t.vy
   if t.ay>=0 then t.ay=0 t.vy=0 dust(t) end
   lnd=false
  end
  if t.rv>0 then t.rv-=1 end
 end
 if cur then
  cvx+=(tx(cur)-cx)*0.5 cvx*=0.55 cx+=cvx
  cvy+=(ty(cur)-cy)*0.5 cvy*=0.55 cy+=cvy
 end
 if st==2 then
  play()
 elseif st==0 then
  -- every level cleared stays unlocked, so a wall can be left and come back to
  if btnp(0) and lsel>1 then lsel-=1 sfx(0) end
  if btnp(1) and lsel<unl then lsel+=1 sfx(0) end
  if btnp(5) then start(lsel) end
  if btnp(4) then tstart(1) end
 elseif st==4 then
  if btnp(5) or btnp(4) then st=0 mnu(2) end
 elseif st==6 then
  if btnp(5) or btnp(4) then lgo() end
 elseif st==3 then
  if btnp(5) then
   if rd<nlv then start(rd+1) else lsel=unl st=0 mnu(2) music(0) end
  end
 elseif st==5 then
  -- every stone is turned face up here, buried ones on their grey, so the
  -- board can be read back against the laws that named them
  if btnp(5) then start(rd) end
  if btnp(4) then lsel=unl st=0 mnu(2) music(0) end
 end
end

-->8
-- draw

function dfill(x0,y0,x1,y1,p,c)
 fillp(p)
 rectfill(x0,y0,x1,y1,c)
 fillp()
end

-- lamp over the table: dithered rings from indigo out to dark blue
function bg()
 rectfill(0,0,127,127,0)
 fillp(p25) ovalfill(-26,-34,154,150,0x10)
 fillp(chk) ovalfill(-12,-22,140,138,0x10)
 fillp(d25) ovalfill(2,-10,126,126,0x10)
 fillp() ovalfill(16,2,112,114,1)
 fillp(chk) ovalfill(26,12,102,104,0x21)
 fillp(d25) ovalfill(36,20,92,96,0xd2)
 fillp() ovalfill(46,30,82,86,13)
end

-- the four layers, side by side: 1 top left, 2 top right, 3 bottom left,
-- 4 bottom right. a stone and the one it covers sit in the same spot of
-- neighbouring panels.
function pane()
 rectfill(0,0,127,127,0)
 for l=1,4 do
  local x,y=((l-1)%2)*64,flr((l-1)/2)*50
  dfill(x+1,y+5,x+62,y+49,p25,0xd1)
  rect(x+1,y+5,x+62,y+49,5)
  print("layer "..l,x+3,y,6)
 end
end

-- one 10x10 stone: white while its face is up, dark grey while it is buried
function tile(x,y,g,c,hd)
 rectfill(x+1,y+1,x+10,y+10,0)
 rectfill(x,y,x+9,y+9,hd and 5 or 7)
 pal(0,c)
 spr(g,x+1,y+1)
 pal(0,0)
end

function dstone(t)
 if t.dly>0 then return end
 local x,y=tx(t)-5,ty(t)-5+t.ay
 if t==sel then y-=1 sx=x sy=y end
 -- buried: the player's mark if it carries one, a red ? if not. on a dead
 -- board every stone shows its real face, grey or not.
 local g,c=t.f,fc[t.f]
 if t.hd and not rvl then
  if t.fl>0 then g,c=t.fl,fc[t.fl] else g,c=8,8 end
 end
 tile(x,y,g,c,t.hd)
 if t.rv>0 then
  dfill(x,y,x+9,y+9,rvp[ceil((9-t.rv)/2)]+0.5,7)
 end
 -- peek marks what the cursor can take: pairs on show, or, with a
 -- stone held, only its partners
 if pk and not t.hd and t~=sel and pick(t) and pair(t) and tk%8<4 then
  rect(x-1,y-1,x+10,y+10,10)
 end
end

function board()
 sx=nil
 for t in all(ts) do dstone(t) end
 -- selection and cursor sit on top of every stone, dark side first
 -- so they keep their edge against a white stone
 if sx then
  rect(sx-1,sy-1,sx+10,sy+10,0)
  rect(sx,sy,sx+9,sy+9,10)
 end
 if st==2 and cur and lnd then
  if sel and sel~=cur then
   for i=0,1,0.07 do
    local px,py=cx+(tx(sel)-cx)*i,cy+(ty(sel)-cy)*i
    pset(px+1,py+1,0)
    pset(px,py,7)
   end
  end
  local x,y=cx-6,cy-6-(cur==sel and 1 or 0)
  local c=tk%16<8 and 10 or 9
  for i=0,1 do
   for j=0,1 do
    local px,py=x+i*11,y+j*11
    local ex,ey=(1-i*2)*3,(1-j*2)*3
    line(px+1,py+1,px+ex+1,py+1,0)
    line(px+1,py+1,px+1,py+ey+1,0)
    line(px,py,px+ex,py,c)
    line(px,py,px,py+ey,c)
   end
  end
 end
 -- rejected pair: red rim for a few frames
 if mf>0 then
  for t in all({ma,mb}) do
   rect(tx(t)-6,ty(t)-6,tx(t)+5,ty(t)+5,8)
  end
 end
 -- the stones that killed the board: one face, stacked on itself
 if st==5 and tk%16<11 then
  for t in all(twin) do
   rect(tx(t)-7,ty(t)-7,tx(t)+6,ty(t)+6,8)
  end
 end
 for p in all(prt) do
  pset(p.x,p.y,p.t>10 and 7 or (p.t<4 and 5 or p.c))
 end
end

-- an 8x8 face on a white tile: the size the ribbon and the law pages use
function icon(f,x,y)
 rectfill(x,y,x+7,y+7,7)
 pal(0,fc[f])
 spr(f,x,y)
 pal(0,0)
end

-- ui text is outlined in black, so it holds on a white stone or a
-- dark backdrop without a panel behind it
function shad(s,x,y,c)
 for i=-1,1 do
  for j=-1,1 do
   print(s,x+i,y+j,0)
  end
 end
 print(s,x,y,c)
end

-- the laws in a row: face, mark, face - or face and a layer
function lawbar(x,y)
 for w in all(laws) do
  icon(w[2],x,y)
  if w[1]<4 then
   shad(lmk[w[1]],x+9,y+1,lmc[w[1]])
   icon(w[3],x+14,y)
   x+=25
  else
   shad("-"..w[3],x+9,y+1,7)
   x+=21
  end
 end
end

function hud()
 rectfill(0,101,127,127,0)
 line(0,101,127,101,13)
 if st==5 then
  shad(dmsg[why],2,103,8)
  lawbar(2,110)
  shad("\151 retry",2,120,7)
  shad("\142 title",64,120,6)
  return
 end
 if tut>0 then
  shad(tmsg[tut],2,103,7)
  if #laws>0 then lawbar(2,117) end
  shad(tut.."/4",110,118,13)
  return
 end
 -- the tally: how many of each face are still on the table, buried
 -- ones included. it is the other half of every deduction.
 local n={0,0,0,0,0,0}
 for t in all(ts) do n[t.f]+=1 end
 local x=2
 for f=1,6 do
  if n[f]>0 then
   icon(f,x,103)
   shad(n[f],x+9,104,7)
   x+=14
  end
 end
 shad("lv"..rd,108,104,13)
 lawbar(2,114)
end

function lawname(w)
 local k=w[1]
 if k==2 then return "bond","every "..fnm[w[2]].." touches a "..fnm[w[3]] end
 if k==3 then
  if w[2]==w[3] then return "taboo","no two "..fnm[w[2]].."s touch" end
  return "taboo","no "..fnm[w[2]].." touches a "..fnm[w[3]]
 end
 return "depth","no "..fnm[w[2]].." on layer "..w[3]
end

-- one law per row: the ribbon mark, the law's name, the sentence
function lrows(L,y)
 for w in all(L) do
  icon(w[2],6,y)
  if w[1]<4 then
   shad(lmk[w[1]],15,y+1,lmc[w[1]])
   icon(w[3],20,y)
  else
   shad("-"..w[3],15,y+1,7)
  end
  local a,b=lawname(w)
  shad(a,36,y+1,10)
  shad(b,6,y+10,7)
  y+=18
 end
end

function box(x0,y0,x1,y1)
 dfill(x0+3,y0+3,x1+3,y1+3,chk+0.5,0)
 rectfill(x0,y0,x1,y1,0)
 rect(x0,y0,x1,y1,6)
 rect(x0+1,y0+1,x1-1,y1-1,5)
end

function lawpanel()
 box(2,10,125,98)
 shad("laws of this board",30,15,10)
 lrows(laws,26)
 shad("stones touch when one rests on",6,84,6)
 shad("the other, or side by side.",6,91,6)
 line(4,82,123,82,5)
end

function stamp(a,b,c)
 box(14,40,113,80)
 shad(a,64-#a*2,47,10)
 shad(b,64-#b*2,58,7)
 shad(c,64-#c*2,69,6)
end

function title()
 bg()
 for i=1,6 do
  tile(13+(i-1)*17,20,i,fc[i])
 end
 tile(56,34,8,8,true)
 shad("\^w\^tstone",44,50,7)
 shad("\^w\^tlogic",44,66,10)
 shad("a deduction solitaire",22,84,6)
 -- levels unlock as they fall, so a wall can be walked away from.
 -- the two arrow glyphs draw 8px where # counts 4, hence the -4
 local s,x="level 1 of "..nlv,0
 if unl>1 then s="\139 level "..lsel.." of "..nlv.." \145" x=-4 end
 shad(s,64-#s*2+x,96,7)
 shad("\151 start",48,108,7)
 shad("\142 tutorial",42,118,6)
end

function help()
 bg()
 box(1,1,126,126)
 shad("how to play",40,4,10)
 shad("\151 back",96,4,5)
 line(4,13,123,13,5)
 shad("take any stone that is face",5,17,7)
 shad("up and match it to another",5,24,7)
 shad("of the same face.",5,31,7)
 shad("the four panels are the four",5,41,6)
 shad("layers: 1 top left, 4 bottom",5,48,6)
 shad("right. a grey \"?\" is buried",5,55,6)
 shad("under the stone in the same",5,62,6)
 shad("cell one panel back.",5,69,6)
 shad("the laws and the tally name",5,79,8)
 shad("every \"?\" between them. work",5,86,8)
 shad("them out before you lift a",5,93,8)
 shad("stone: one order clears it.",5,100,8)
 line(4,109,123,109,5)
 shad("\142 mark a \"?\"    hold laws",5,113,6)
 shad("\151 pick         hold peek",5,120,6)
end

-- opened from a board it reads that board; anywhere else it teaches
-- the notation on a made-up one
function legend()
 bg()
 local g=pst and tut<1 and #laws>0
 local l=g and laws or lgd
 box(2,12,125,123)
 shad(g and "laws of this board" or "the laws",6,15,10)
 if not pst then shad("5/5",112,15,13) end
 lrows(l,28)
 shad("stones touch when one rests",6,86,7)
 shad("on the other, or when they",6,93,7)
 shad("sit side by side on a layer.",6,100,7)
 shad(g and "true when dealt" or "yours will name",6,112,13)
 shad("\151 "..(pst and "back" or "play"),92,112,6)
end

function _draw()
 cls()
 if st==0 then
  title()
  return
 end
 if st==6 then
  legend()
  return
 end
 if st==4 then
  help()
  return
 end
 camera(rnd(shk)-shk/2,rnd(shk)-shk/2)
 pane()
 board()
 hud()
 if oh>=12 then lawpanel() end
 if st==3 then
  if rd<nlv then
   stamp("level "..rd.." cleared","score "..scr,"\151 next level")
  else
   stamp("all twelve cleared","score "..scr,"\151 title")
  end
 end
 camera()
end
