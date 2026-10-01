-- quadris
-- by roberto freire

-- 4-sided tetris: pieces fall
-- inward from every edge and
-- you clear rings, not rows.

-->8
-- data & setup

-- 7 pieces, 9 chars each:
-- [boxsize][x0y0][x1y1][x2y2][x3y3]
-- i o t s z j l
pdat="401112131200100111310011121310200111300101121300011121320011121"

function _init()
 pd={}
 for i=1,7 do
  local s=sub(pdat,(i-1)*9+1,i*9)
  local c={}
  for j=0,3 do
   add(c,{tonum(sub(s,j*2+2,j*2+2)),tonum(sub(s,j*2+3,j*2+3))})
  end
  pd[i]={tonum(sub(s,1,1)),c}
 end
 -- i o t s z j l
 -- all bright: anything dark reads
 -- as background in the black well
 pcol=split"12,10,14,11,8,15,9"
 -- the landing pad is part of the
 -- cabinet, so it wears the bezel's
 -- greys rather than a piece colour.
 -- it sits in the middle of the black
 -- well, so it takes the light grey as
 -- its body and keeps the dark one for
 -- the shaded edge only
 cc=6
 -- red, blue and green have no twin of
 -- their own hue in the base 16, so
 -- three slots we draw nothing else in
 -- are swapped for secret colours:
 -- crimson, mid blue and lime
 pal(13,136,1)
 pal(1,140,1)
 pal(2,138,1)
 -- every block colour with the shade
 -- and the tint of its own hue, for
 -- the two bevelled edges. white or
 -- grey only where the palette has no
 -- lighter version of the hue at all
 dk={[7]=6,[8]=13,[9]=4,[10]=9,[11]=3,[12]=1,[14]=13,[15]=4}
 hl={[7]=7,[8]=14,[9]=10,[10]=7,[11]=2,[12]=7,[14]=15,[15]=7}
 -- button that moves the piece +u, per side
 ubt=split"1,3,0,2"
 menuitem(1,"restart",startgame)
 -- best score survives the cart
 cartdata("rfreire_quadris")
 hi=dget(0)
 st=0
 tk=0
end

function startgame()
 bd={}
 -- the solid centre: landing pad, never clears
 for y=12,15 do
  for x=12,15 do
   bd[x+y*28]=cc
  end
 end
 sc=0
 sd=3
 st=1
 dy=true
 pq={}
 for i=1,3 do
  add(pq,1+flr(rnd(7)))
 end
 music(0,0,7)
 spawn()
end

-- local (u,v) -> board (x,y).
-- v is depth from the spawn edge,
-- so gravity is always +v and the
-- dpad is always +-u.
function tob(u,v)
 if sd==0 then return u,v end
 if sd==1 then return 27-v,u end
 if sd==2 then return 27-u,27-v end
 return v,27-u
end

function sol(x,y)
 return x<0 or x>27 or y<0 or y>27 or bd[x+y*28]
end

function fits(u,v,cs)
 for c in all(cs) do
  local x,y=tob(u+c[1],v+c[2])
  if sol(x,y) then return false end
 end
 return true
end

function spawn()
 sd=(sd+1)%4
 pt=pq[1]
 deli(pq,1)
 add(pq,1+flr(rnd(7)))
 pn=pd[pt][1]
 pc=pd[pt][2]
 pu=14-flr(pn/2)
 pv=0
 ft=0
 ld=0
 lt=0
 st=1
 if fits(pu,pv,pc) then
  sfx(0,3)
 else
  gameover()
 end
end

function gameover()
 if sc>hi then
  hi=sc
  dset(0,hi)
 end
 st=2
 music(-1,300)
 sfx(3,3)
end

-->8
-- update

function _update()
 tk+=1
 if st==1 then
  updplay()
 elseif st==3 then
  -- rings blink white before they go
  flt+=1
  if flt>=18 then doclear() end
 elseif btnp(5) then
  startgame()
 end
end

function updplay()
 local b=ubt[sd+1]
 if btnp(b) and fits(pu+1,pv,pc) then
  pu+=1
  ld=0
 end
 if btnp(b^^1) and fits(pu-1,pv,pc) then
  pu-=1
  ld=0
 end
 if btnp(5) then
  local nc={}
  for c in all(pc) do
   add(nc,{pn-1-c[2],c[1]})
  end
  if fits(pu,pv,nc) then
   pc=nc
   ld=0
  end
 end
 ft+=1
 if ft>=(btn(4) and 2 or 12) then
  ft=0
  if fits(pu,pv+1,pc) then
   pv+=1
   ld=0
   lt=0
  end
 end
 if fits(pu,pv+1,pc) then
  ld=0
 else
  ld+=1
  lt+=1
  if ld>=15 or lt>=30 then
   lock()
  end
 end
end

function lock()
 -- crossing the whole board and
 -- reaching the far edge is fatal
 local far=false
 for c in all(pc) do
  if pv+c[2]>=27 then far=true end
  local x,y=tob(pu+c[1],pv+c[2])
  bd[x+y*28]=pcol[pt]
 end
 sfx(1,3)
 dy=true
 ff=far
 fls=fullrings()
 if #fls>0 then
  st=3
  flt=0
  sfx(2,3)
 elseif far then
  gameover()
 else
  spawn()
 end
end

-- every cell of ring r, in order
function rcells(r)
 local t={}
 local a,b=r,27-r
 for i=a,b do
  add(t,{i,a})
  add(t,{i,b})
 end
 for j=a+1,b-1 do
  add(t,{a,j})
  add(t,{b,j})
 end
 return t
end

function fullrings()
 local fr={}
 for r=11,0,-1 do
  local f=true
  for c in all(rcells(r)) do
   if not bd[c[1]+c[2]*28] then f=false end
  end
  if f then add(fr,r) end
 end
 return fr
end

-- called once the blink has finished.
-- innermost first: each clear pulls
-- the rings outside it in by one, so
-- a later target sits k rings deeper
function doclear()
 local k=0
 for r in all(fls) do
  clearring(r+k)
  k+=1
  sc+=(108-8*r)*#fls
 end
 dy=true
 if ff then
  gameover()
 else
  spawn()
 end
end

function clearring(rr)
 for c in all(rcells(rr)) do
  bd[c[1]+c[2]*28]=nil
 end
 for r=rr-1,0,-1 do
  local tg={}
  for c in all(rcells(r)) do
   local i=c[1]+c[2]*28
   local v=bd[i]
   if v then
    local nx,ny=inward(c[1],c[2],r)
    add(tg,{nx+ny*28,v})
   end
   bd[i]=nil
  end
  -- ring r+1 was vacated last pass.
  -- 8 cells per ring have nowhere to
  -- land; first writer wins.
  for g in all(tg) do
   if not bd[g[1]] then bd[g[1]]=g[2] end
  end
 end
end

function inward(x,y,r)
 local nx,ny=x,y
 if y==r then ny=y+1 end
 if y==27-r then ny=y-1 end
 if x==r then nx=x+1 end
 if x==27-r then nx=x-1 end
 return mid(r+1,nx,26-r),mid(r+1,ny,26-r)
end

-->8
-- draw

function _draw()
 if st==0 then
  drintro()
  return
 end
 -- the settled board only changes on
 -- a lock, so draw it once and blit
 -- the saved image every other frame
 if dy then
  bake()
 else
  memcpy(0x6000,0x8000,0x2000)
 end
 if st==1 then drpiece() end
 if st==3 and flt\3%2==0 then drflash() end
 drbar()
 if st==2 then drover() end
end

-- outlined text: 8 offset passes in
-- o, then the real glyphs on top
function prt(s,x,y,c,o)
 o=o or 0
 for i=-1,1 do
  for j=-1,1 do
   print(s,x+i,y+j,o)
  end
 end
 print(s,x,y,c)
end

-- every block is bevelled the same
-- way: lit along the top and left,
-- shaded in its own darker hue along
-- the bottom and right
function bev(px,py,w,c,l,d)
 rectfill(px,py,px+w-1,py+w-1,c)
 line(px,py,px+w-2,py,l)
 line(px,py,px,py+w-2,l)
 line(px+w-1,py,px+w-1,py+w-1,d)
 line(px,py+w-1,px+w-2,py+w-1,d)
end

function blk(x,y,c)
 bev(8+x*4,5+y*4,4,c,hl[c],dk[c])
end

-- same idea at any size, with a black
-- outline so it pops off the intro
function bblk(px,py,s,c)
 px=flr(px) py=flr(py)
 rect(px-1,py-1,px+s,py+s,0)
 bev(px,py,s,c,hl[c],dk[c])
end

-- the pad is one slab, not 16 blocks,
-- bevelled in the bezel's own greys so
-- it reads as a piece of the cabinet
function drcore()
 bev(56,53,16,cc,7,5)
end

-- raised outer edge, then a recessed
-- lip around the well: 5px of margin
-- up top, 11px of bezel below. the lip
-- is the lighter grey, so the well edge
-- never sinks into the black inside
function frame()
 rectfill(0,0,127,127,5)
 rect(0,0,127,127,7)
 line(127,1,127,127,6)
 line(1,127,127,127,6)
 rect(7,4,120,117,cc)
 rectfill(8,5,119,116,0)
end

function bake()
 frame()
 for y=0,27 do
  for x=0,27 do
   local c=bd[x+y*28]
   if c and c!=cc then blk(x,y,c) end
  end
 end
 drcore()
 memcpy(0x8000,0x6000,0x2000)
 dy=false
end

function drpiece()
 for c in all(pc) do
  local x,y=tob(pu+c[1],pv+c[2])
  blk(x,y,pcol[pt])
 end
end

-- only the ring itself flashes, not
-- the pieces hanging off it
function drflash()
 for r in all(fls) do
  for c in all(rcells(r)) do
   blk(c[1],c[2],7)
  end
 end
end

-- score left, best score beside it,
-- next 3 right, all at 2px per block
-- so it fits in the bottom bezel
function drbar()
 prt(sc,3,120,7)
 -- right-aligned so a growing score
 -- never pushes it into the previews
 local h="hi "..hi
 prt(h,88-#h*4,120,10)
 for i=1,3 do
  local t=pq[i]
  local cs=pd[t][2]
  local mnx,mny,mxx,mxy=9,9,0,0
  for c in all(cs) do
   mnx=min(mnx,c[1]) mxx=max(mxx,c[1])
   mny=min(mny,c[2]) mxy=max(mxy,c[2])
  end
  local ox=84+i*10+(8-(mxx-mnx+1)*2)\2-mnx*2
  local oy=120+(6-(mxy-mny+1)*2)\2-mny*2
  for p=0,1 do
   for c in all(cs) do
    local px,py=ox+c[1]*2,oy+c[2]*2
    if p==0 then
     rectfill(px-1,py-1,px+2,py+2,dk[pcol[t]])
    else
     rectfill(px,py,px+1,py+1,pcol[t])
     pset(px,py,hl[pcol[t]])
    end
   end
  end
 end
end

function drintro()
 cls(0)
 for i=0,13 do
  local a=i/14+tk/300
  local r=40+sin(tk/90+i/14)*5
  bblk(64+cos(a)*r-3,64+sin(a)*r-3,6,pcol[i%7+1])
 end
 prt("\^w\^tquadris",36,46,10)
 prt("blocks fall from all sides",13,66,6)
 prt("clear a full ring to score",13,74,6)
 if tk%32<20 then
  prt("❎ to start",42,92,7)
 end
end

function drover()
 rectfill(25,46,102,78,0)
 rect(25,46,102,78,13)
 rect(26,47,101,77,8)
 prt("game over",46,53,8)
 local s="score "..sc
 prt(s,64-#s*2,63,10)
 if tk%32<20 then
  prt("❎ retry",48,71,7)
 end
end
