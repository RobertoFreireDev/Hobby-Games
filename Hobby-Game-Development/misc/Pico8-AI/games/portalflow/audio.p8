pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- portal flow
-- by roberto freire

-- level rows: "." empty, 1-7 dot, "p" portal.
-- spliced in from levels.json by mk.js.
lv={
 {"1...","23.1",".3.2","...."},
 {"1..p","2...","2...","p..1"},
 {".....",".1...",".....",".23..","21..3"},
 {"1....","...p.",".p.21","....3","3...2"},
 {".24.3",".3..4","...p.","2p...","1...1"},
 {"43..1.","....2.",".4....",".2....",".3..1.","......"},
 {"34....","...2..","p3.1..",".2....",".4....","..1..p"},
 {"54p...","..5.2.",".1..1.","...p.2",".....3",".43..."},
 {"32p6.4",".....5","..1...",".2....",".1...p",".34.56"},
 {".......",".5412..",".......",".......","4.231..","3......","......5"},
 {"......3",".p....4",".......","..1..3.","....p25",".12....","...45.."},
 {"....15.",".p..26.",".......",".......","..p...5","3...164","2.34..."},
 {".3...p5",".4....4","32.....","...6...","21.....",".p...1.","56....."},
 {"3p54..3","2....p4","..65...",".....1.","..7....","....761","......2"},
 {"43....3","......2","....7..","4..p...","5..1...",".6..7..",".5p.612"},
 {".......",".p.23.2",".7..p.1",".6.....","...734.","....5..","56..4.1"}}

-- flow ramps: highlight, body, shadow. the pipe art is authored once in
-- 7/6/5 and recoloured through these at draw time.
rmp={{14,8,2},{7,12,1},{10,11,3},{7,10,9},{10,9,4},{15,14,2},{7,6,5}}
dx={0,1,0,-1} dy={-1,0,1,0}
bd={4,2,1,3}                -- btn 0..3 -> dir 1=n 2=e 3=s 4=w
-- fade ramp: set bits are transparent, so fewer bits = more black
fdp={0b1111111111111111,0b1111010111110101,0b1010010110100101,0b1010000010100000,0}

function _init()
 poke(0x5f2d,1)
 cartdata("rbt_portalflow_1")
 cl=dget(0) bm={}
 for i=1,16 do bm[i]=dget(i) end
 nomu=dget(17) nosf=dget(18)
 ps={} tk=0 trn=0 shk=0 csh=0 msk=0 pop=0 popn=1 oh=0 md=false
 curmu=-1 msc=1
 for i=1,16 do
  if unl(i) and not cld(i) then msc=i break end
 end
 st=1 menu() ensel()
end

function cld(n) return (cl>>(n-1))&1==1 end
function unl(n) return n==1 or cld(n-1) end

function sf(n,c,o)
 if nosf!=0 then return end
 -- sfx 1/2 are 32-note ladders: a long pipe sings its way up (10.1)
 if o then sfx(n,c,min(o,31),1) else sfx(n,c) end
end
function mu(n)
 curmu=n
 if nomu==0 then music(n,900,0b0111) else music(-1) end
end

function go(s) nst=s trn=20 end

function _update60()
 tk+=1
 upfx()
 if shk>0 then shk-=1 end
 if csh>0 then csh-=1 end
 if msk>0 then msk-=1 end
 if pop>0 then pop-=1 end
 if trn>0 then
  trn-=1
  if trn==10 then
   st=nst
   menu()
   if st==1 then ensel() else loadlv(msc) end
  end
  return
 end
 if st==1 then upsel() elseif st==2 then upgame() else upwin() end
end

function _draw()
 if st==1 then drsel() else drgame() end
 if trn>0 then
  local a=trn>10 and 20-trn or trn
  local k=mid(1,1+a\2,5)
  if k>1 then fillp(fdp[k]+0.5) rectfill(0,0,127,127,0) fillp() end
 end
end

function menu()
 if st==1 then
  -- the level select has no "back"; wiping is only reachable from here
  menuitem(1,"clear progress",function() wipep() go(1) end)
 else
  menuitem(1,"back to levels",function() go(1) end)
 end
 menuitem(2,"music: "..(nomu==0 and "on" or "off"),function()
  nomu=1-nomu dset(17,nomu) mu(curmu) menu() return true end)
 menuitem(3,"sfx: "..(nosf==0 and "on" or "off"),function()
  nosf=1-nosf dset(18,nosf) menu() return true end)
end

-->8
-- board & path logic

function ix(x,y) return x+y*bw+1 end
function cxy(i) i-=1 return i%bw,i\bw end

function loadlv(n)
 lvn=n
 local g=lv[n]
 bw=#g[1] bh=#g
 ox=64-bw*8 oy=64-bh*8
 ck={} cd={} co={} fl={} ps={} hs={}
 nf=0 pa=0 pb=0 pw=0 mv=0 gr=0 lf=1 oh=0 wt=0 warn=false
 ncon=0 nfil=0
 for y=0,bh-1 do
  local r=g[y+1]
  for x=0,bw-1 do
   local c,i=sub(r,x+1,x+1),ix(x,y)
   ck[i]=0 cd[i]=0 co[i]=0
   if c=="p" then
    ck[i]=2
    if pa==0 then pa=i else pb=i end
   elseif c!="." then
    local k=tonum(c)
    ck[i]=1 cd[i]=k
    if k>nf then nf=k end
    if fl[k] then fl[k].b=i else fl[k]={a=i,b=i,p={},dn=false} end
   end
  end
 end
 cx,cy=cxy(fl[1].a)
 dcx,dcy=cx,cy
 local t=n<9 and 8 or 16
 if curmu!=t then mu(t) end
end

-- drop path entries j..end, freeing their tiles
function cut(f,j)
 local q=fl[f].p
 for m=#q,j,-1 do
  local c=q[m]
  co[c]=0
  if ck[c]==2 then pw=0 end
  deli(q,m)
 end
 fl[f].dn=false fl[f].pl=nil
 del(hs,f)
end
function wipe(f) cut(f,1) end
function pidx(f,i)
 local q=fl[f].p
 for j=1,#q do if q[j]==i then return j end end
end

function bad() sf(9) csh=4 end

-- grab whatever is under the cursor: a dot starts that colour over, a pipe
-- body is truncated there and drawing continues from that tile.
function grabat(i)
 if cd[i]!=0 then
  local f=cd[i]
  wipe(f)
  add(fl[f].p,i) co[i]=f
  gr=f lf=f
  sf(3) fx(i,rmp[f][1],5)
 elseif co[i]!=0 and ck[i]!=2 then
  local f=co[i]
  cut(f,pidx(f,i)+1)
  gr=f lf=f
  sf(3)
 else
  bad()
 end
end

-- returns true when the board changed
function ext(d)
 local f=gr
 local q=fl[f].p
 local hd=q[#q]
 local x,y=cxy(hd)
 x+=dx[d] y+=dy[d]
 if x<0 or y<0 or x>=bw or y>=bh then return end
 local i=ix(x,y)

 -- retrace: stepping back onto the tile you just left erases it
 if #q>1 and q[#q-1]==i then
  cut(f,#q) mv+=1 sf(2,3,#q-1) fx(hd,6,2)
  cx,cy=cxy(q[#q]) return true
 end

 local o=co[i]
 if ck[i]==2 then
  -- portal: one pipe owns both tiles, entry is refused while it is held
  if o!=0 then return end
  local t=i==pa and pb or pa
  add(q,i) co[i]=f
  add(q,t) co[t]=f
  pw=f mv+=1
  sf(7,3) fx(i,7,8) fx(t,rmp[f][1],8)
  cx,cy=cxy(t) return true
 end
 if cd[i]!=0 then
  if cd[i]!=f or i==q[1] then return end
  add(q,i) co[i]=f
  -- pl runs a light pulse from the start dot to the twin (9)
  fl[f].dn=true fl[f].pl=0 add(hs,f) gr=0
  mv+=1 sf(5) fx(i,rmp[f][1],10) fx(q[1],rmp[f][1],10)
  cx,cy=x,y return true
 end
 if o!=0 then
  -- flow free rules: the older path gives way from the crossed tile on.
  -- the lost tail flashes white as it goes, so you can see exactly what
  -- you cost yourself rather than just noticing a pipe got shorter.
  local j=pidx(o,i)
  if o!=f then
   local q2=fl[o].p
   for m=j,#q2 do fx(q2[m],7,2) end
   sf(6)
  end
  cut(o,j)
 end
 add(q,i) co[i]=f
 mv+=1 sf(1,3,#q-1)
 cx,cy=x,y return true
end

-- the head sits on the exit portal, so no direction points back at the tile
-- it came from. extension wins; a press in the reverse of the entry
-- direction that could not extend pulls the head out of both tiles at once.
function pback(d)
 local q=fl[gr].p
 if #q>2 and ck[q[#q]]==2 and ck[q[#q-1]]==2 then
  local px,py=cxy(q[#q-1])
  local ax,ay=cxy(q[#q-2])
  if ax-px==dx[d] and ay-py==dy[d] then
   fx(q[#q],6,3) fx(q[#q-1],6,3)
   cut(gr,#q-1) sf(8,3) mv+=1
   cx,cy=ax,ay
   return true
  end
 end
end

function upgame()
 -- o: tap undoes the last completed colour, hold clears the board
 if btn(4) then
  oh+=1
  if oh==60 then
   for f=1,nf do
    if #fl[f].p>0 then fx(fl[f].p[1],rmp[f][1],6) end
    wipe(f)
   end
   gr=0 sf(13) shk=6 oh=999
  end
 else
  if oh>0 and oh<60 then
   local f=hs[#hs] or lf
   local q=fl[f].p
   if #q>0 then
    fx(q[#q],rmp[f][1],6) wipe(f) sf(12)
    if gr==f then gr=0 end
   end
  end
  oh=0
 end

 if btnp(5) then
  if gr!=0 then gr=0 sf(4) else grabat(ix(cx,cy)) end
 end

 for b=0,3 do
  if btnp(b) then
   local d=bd[b+1]
   if gr!=0 then
    if not ext(d) and not pback(d) then bad() end
   else
    cx=mid(0,cx+dx[d],bw-1) cy=mid(0,cy+dy[d],bh-1)
    sf(0,3)
   end
  end
 end

 mouse()
 dcx+=(cx-dcx)/3 dcy+=(cy-dcy)/3
 for f=1,nf do
  local q=fl[f]
  if q.pl then
   q.pl+=1
   if q.pl>#q.p+4 then q.pl=nil end
  end
 end

 -- connected colours and covered tiles: the two halves of the win condition
 ncon=0 nfil=0
 for f=1,nf do if fl[f].dn then ncon+=1 end end
 for i=1,bw*bh do if co[i]!=0 then nfil+=1 end end
 if ncon==nf then
  if nfil==bw*bh then
   st=3 wt=0 gr=0 sf(11)
   if bm[lvn]==0 or mv<bm[lvn] then bm[lvn]=mv dset(lvn,mv) end
   cl|=1<<(lvn-1) dset(0,cl)
  elseif not warn then
   -- every colour joined but tiles left over: point at the problem
   warn=true msk=40 sf(10)
  end
 else
  warn=false
 end
end

function mouse()
 if stat(34)&1==0 then md=false return end
 local tx,ty=(stat(32)-ox)\16,(stat(33)-oy)\16
 if tx<0 or ty<0 or tx>=bw or ty>=bh then return end
 if not md then
  md=true cx,cy=tx,ty gr=0 grabat(ix(tx,ty))
 elseif gr!=0 and tk%3==0 and (tx!=cx or ty!=cy) then
  local d
  if abs(tx-cx)>abs(ty-cy) then d=tx>cx and 2 or 4
  else d=ty>cy and 3 or 1 end
  ext(d)
 end
end

function upwin()
 wt+=1
 if wt==10 then
  for j=1,24 do
   add(ps,{x=ox+rnd(bw*16),y=oy+bh*16-4,vx=rnd(2)-1,vy=-rnd(2)-1,
           c=rmp[1+j%nf][1],l=50+rnd(20)})
  end
 end
 if wt>=80 then pop=30 popn=lvn go(1) end
end

-->8
-- drawing

function pcol(c)
 local r=rmp[c]
 pal(7,r[1]) pal(6,r[2]) pal(5,r[3])
 palt(0,false) palt(14,true)
end
function pdef() pal() palt(0,false) palt(14,true) end

function pr(s,x,y,c)
 for i=1,4 do print(s,x+dx[i],y+dy[i],1) end
 print(s,x,y,c or 7)
end

-- dithered indigo vignette, darkest at the corners. hx0..hy1 is an optional
-- rect about to be painted over it: a 7x7 board hides the two inner bands
-- completely, and they are the most expensive thing on the frame.
function bgv(hx0,hy0,hx1,hy1)
 cls(1)
 for i=1,3 do
  local a,b=20-i*6,107+i*6
  if not (hx0 and hx0<=a and hy0<=a and hx1>=b and hy1>=b) then
   fillp(fdp[5-i]+0.5)
   rectfill(a,a,b,b,13)
  end
 end
 fillp()
end

function fx(i,c,n)
 local x,y=cxy(i)
 for j=1,n or 4 do
  add(ps,{x=ox+x*16+8,y=oy+y*16+8,vx=rnd(2)-1,vy=rnd(2)-1.4,c=c,l=10+rnd(10)})
 end
end
function upfx()
 for p in all(ps) do
  p.x+=p.vx p.y+=p.vy p.vy+=0.06 p.l-=1
  if p.l<0 then del(ps,p) end
 end
end
function drfx()
 for p in all(ps) do pset(p.x,p.y,p.c) end
end

-- bit for the step i->o, 0 when they are not neighbours (a portal jump)
function adjm(i,o)
 if not o then return 0 end
 local x,y=cxy(i)
 local u,v=cxy(o)
 if u==x then
  if v==y-1 then return 1 end
  if v==y+1 then return 4 end
 elseif v==y then
  if u==x+1 then return 2 end
  if u==x-1 then return 8 end
 end
 return 0
end

-- m: 1=n 2=e 4=s 8=w, indexing the sprite for that shape. the light is fixed
-- at the upper left, so a flipped sprite would carry its highlight to the
-- wrong side: every orientation has its own tile and nothing is ever flipped.
pms={8,100,6,98,2,46,0,10,44,4,0,96}
function pipe(m,x,y)
 local s=pms[m]
 if s and s>0 then spr(s,x,y,2,2) end
end

-- the short stub for a portal tile: same idea, tiles 12/13/27/28
sms={40,104,0,102,0,0,0,42}
function stub(m,x,y)
 local s=sms[m]
 if s and s>0 then spr(s,x,y,2,2) end
end

function drgame()
 local w,h=bw*16,bh*16
 -- a 7x7 board leaves 8px of margin, and a fat frame plus an outlined line of
 -- text does not fit in it, so the biggest boards get a thin frame instead
 local fr=bh>6 and 1 or 3
 bgv(ox-fr,oy-fr,ox+w+fr,oy+h+fr)
 rectfill(ox-fr+1,oy-fr+1,ox+w+fr,oy+h+fr,0)
 rectfill(ox-fr,oy-fr,ox+w+fr-1,oy+h+fr-1,13)
 if fr>1 then
  rect(ox-fr,oy-fr,ox+w+fr-1,oy+h+fr-1,1)
  rect(ox-1,oy-1,ox+w,oy+h,6)
 end

 pdef()
 for i=1,bw*bh do
  spr(0,ox+(i-1)%bw*16,oy+(i-1)\bw*16,2,2)
 end
 -- uncovered tiles pulse when the board is connected but not full
 if msk>0 and msk%8<4 then
  for i=1,bw*bh do
   if co[i]==0 then
    local x,y=ox+(i-1)%bw*16,oy+(i-1)\bw*16
    rect(x+4,y+4,x+11,y+11,6)
   end
  end
 end

 for f=1,nf do
  local q=fl[f].p
  pcol(f)
  local pl=fl[f].pl
  for j=1,#q do
   local x,y=cxy(q[j])
   local br
   if st==3 then
    -- win flash: a highlight wave rolls down the diagonals, 3 frames a step
    local dg=(x+y)*3
    br=wt>dg and wt<dg+14
   elseif pl then
    -- connect pulse: light runs the length of the pipe, dot to dot
    br=j<=pl and j>pl-4
   end
   if br!=nil then pal(6,br and rmp[f][1] or rmp[f][2]) end
   -- a portal tile draws its own stub, over the ring, further down
   if ck[q[j]]!=2 then
    pipe(adjm(q[j],q[j-1])|adjm(q[j],q[j+1]),ox+x*16,oy+y*16)
   end
  end
 end
 pdef()

 for i=1,bw*bh do
  if ck[i]==1 then
   local c=cd[i]
   local x,y=ox+(i-1)%bw*16,oy+(i-1)\bw*16
   pcol(c)
   spr(fl[c].dn and 14 or 12,x,y,2,2)
   pdef()
   spr(63+c,x+4,y+4)
   if not fl[c].dn then
    circ(x+8,y+8,7.5+sin(tk/48+i/7),rmp[c][1])
   end
  end
 end

 -- portals: the pipe cap is drawn under the ring so it reads as entering
 if pa!=0 then
  local fr=(tk\(pw!=0 and 5 or 8))%4
  if pw==0 then
   for i=pa,pb,pb-pa do
    local x,y=ox+(i-1)%bw*16,oy+(i-1)\bw*16
    circfill(x+8,y+8,4,0)
    fillp(0b0101101001011010) circfill(x+8,y+8,3,12) fillp()
    spr(32+fr*2,x,y,2,2)
   end
  else
   -- owned: the ring takes the owner's highlight, and the stub is drawn on
   -- top of it, so the pipe runs into the mouth instead of disappearing
   -- behind a ring that covers the whole tile
   local q=fl[pw].p
   pcol(pw)
   for j=1,#q do
    local c=q[j]
    if ck[c]==2 then
     local x,y=ox+(c-1)%bw*16,oy+(c-1)\bw*16
     spr(32+fr*2,x,y,2,2)
     stub(adjm(c,q[j-1])|adjm(c,q[j+1]),x,y)
    end
   end
   pdef()
  end
 end

 drcur()
 drfx()
 camera()
 drhud()
end

function drcur()
 if st!=2 then return end
 local sx,sy=0,0
 if csh>0 then sx=rnd(2)-1 sy=rnd(2)-1 end
 local x,y=ox+dcx*16+sx,oy+dcy*16+sy+(sin(tk/30)<0 and 1 or 0)
 pal(7,gr!=0 and rmp[gr][1] or 7) palt(0,false) palt(14,true)
 for i=0,3 do spr(72,x+i%2*8,y+i\2*8,1,1,i%2==1,i>1) end
 pdef()
end

function drhud()
 local w,fr=bw*16,bh>6 and 1 or 3
 local hy=oy-fr-6
 pr("lv "..lvn,ox,hy)
 local s=ncon.."/"..nf
 pr(s,ox+w-#s*4,hy)
 -- the fill meter is where "all connected" and "solved" come apart
 local my=oy+bh*16+fr+2
 if msk>0 then my+=sin(tk/2) end
 rectfill(ox,my,ox+w-1,my,5)
 if nfil>0 then
  rectfill(ox,my,ox+w*nfil/(bw*bh)-1,my,msk>0 and 8 or 11)
 end
 if bh<7 then pr("🅾️ undo  ❎ draw",34,120) end
end

-->8
-- level select

function ensel()
 if cld(msc) and msc<16 and unl(msc+1) then msc+=1 end
 oh=0
 if curmu!=0 then mu(0) end
end

function wipep()
 cl=0 dset(0,0)
 for i=1,16 do bm[i]=0 dset(i,0) end
 msc=1 sf(13) shk=8
end

function crd(n) return 13+(n-1)%6*17,44+(n-1)\6*20 end

function upsel()
 for b=0,3 do
  if btnp(b) then
   local n=msc
   if b==0 then n=(msc+14)%16+1
   elseif b==1 then n=msc%16+1
   elseif b==2 then n=msc-6
   else n=msc+6 end
   if n>=1 and n<=16 and n!=msc then msc=n sf(14) end
  end
 end
 if btnp(5) then
  if unl(msc) then sf(15) go(2) else bad() end
 end
end

function drsel()
 bgv()
 if shk>0 then camera(rnd(2)-1,rnd(2)-1) end
 pdef()
 sspr(0,64,112,16,8,6+(sin(tk/90)<0 and 0 or 1))

 for n=1,16 do
  local x,y=crd(n)
  if cld(n) then
   local c=rmp[1+(n-1)%7]
   rrectfill(x,y,16,16,3,c[3])
   rrectfill(x,y,16,15,3,c[2])
   spr(73,x+8,y+1)
   pr(""..bm[n],x+2,y+8)
  elseif unl(n) then
   rrectfill(x,y,16,16,3,1)
   rrect(x,y,16,16,3,13)
   local s=""..n
   pr(s,x+8-#s*2,y+5)
  else
   fillp(0b1010010110100101)
   rrectfill(x,y,16,16,3,0x01)
   fillp()
   spr(74,x+4,y+4)
  end
  if n==popn and pop>0 then circ(x+8,y+8,(30-pop)/2,10) end
 end

 -- cursor: brackets round the highlighted card
 local x,y=crd(msc)
 local o=sin(tk/40)<0 and 0 or 1
 rrect(x-2-o,y-2-o,20+o*2,20+o*2,4,7)

 local g=lv[msc]
 local pt=false
 for r in all(g) do if r!=nil and pidxs(r) then pt=true end end
 local s="lv "..msc.."  "..#g[1].."x"..#g.."  "..(pt and "1 portal" or "no portal")
 pr(s,64-#s*2,104)
 if cld(msc) then
  s="best "..bm[msc].." moves   ❎ replay"
  pr(s,64-#s*2-4,112)
 elseif unl(msc) then
  pr("❎ play",50,112)
 else
  pr("clear lv "..(msc-1).." to unlock",64-#("clear lv "..(msc-1).." to unlock")*2,112)
 end
 camera()
end

function pidxs(r)
 for i=1,#r do if sub(r,i,i)=="p" then return true end end
end
-->8
-- audio harness

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

__gfx__
d11111111111111deee0767666650eeeeeeeeeeeeeeeeeeeeee0767666650eeeeee0767666650eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
1111111111111111eee0776666550eeeeeeeeeeeeeeeeeeeeee0776666550eeeeee0776666550eeeeeeeeeeeeeeeeeeeeeeee000000eeeeeeeeee000000eeeee
1111111111111111eee0767666650eeeeeeeeeeeeeeeeeeeeee0767666650eeeeee0767666650eeeeeeeeeeeeeeeeeeeeee0067676600eeeeee0077777700eee
111d1111111d1111eee0776666550eee0000000000000000eee0776666550000eee0776666550eee000000000000eeeeee007777676600eeee007777666700ee
1111111111111111eee0767666650eee7777777777777777eee0767666667777eee0767666650eee7777777777700eeeee077777766660eeee077777766570ee
1111111111111111eee0776666550eee6767676767676767eee0776666676767eee0776666550eee67676767676600eee06777776766550ee07777776766570e
1111111111111111eee0767666650eee7676767676767676eee0767666767676eee0767666650eee76767676766660eee07777767666650ee07777777665570e
1111111111111111eee0776666550eee6666666666666666eee0776666666666eee0776666550eee66666666666650eee06777676666550ee07777776666570e
1111111111111111eee0767666650eee6666666666666666eee0766666666666eee0767666650eee66666666666550eee07676766665550ee07676766665570e
1111111111111111eee0776666550eee6666666666666666eee0666656666666eee0776666550eee66666666665550eee06767666656550ee07667666655570e
1111111111111111eee0767666650eee6565656565656565eee0066565656565eee0766665550eee65656565655500eee06666666565550ee07666666555570e
111d1111111d1111eee0776666550eee5555555555555555eeee005555555555eee0066655500eee5555555555500eeeee066666565550eeee075656555570ee
1111111111111111eee0767666650eee0000000000000000eeeee00000000000eeee00655500eeee000000000000eeeeee006565555500eeee007555555700ee
1111111111111111eee0776666550eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000eeeeeeeeeeeeeeeeeeeeeeee0055555500eeeeee0077777700eee
1111111111111111eee0767666650eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000eeeeeeeeee000000eeeee
d11111111111111deee0776666550eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee0000eeeeeeeeeeee0000eeeeeeeeeeee0000eeeeeeeeeeee0000eeeeeeeeeee676666eeeeeeeeeeeeeeeeeeeeeeee0767666650eeeeeeeeeeeeeeeeeee
eeee0dd7d7d0eeeeeeee07ddddd0eeeeeeee0dddddd0eeeeeeee0dddd7d0eeeeeeeee766665eeeeeeeeeeeeeeeeeeeeeeee0776666550eeeeeeeeeeeeeeeeeee
ee00dd7777dd00eeee007777dddd00eeee007ddddddd00eeee00dddd777d00eeeeeee676666eeeeeeeeeeeeeeeeeeeeeeee0767666650eeeeeeeeeeeeeeeeeee
ee0dddd00dddd0eeee0d77700dddd0eeee0777d00d7770eeee0dddd00777d0eeeeeee766665eeeeeeeeeeeeeeeeeeeee0000776666550eeeeeeee00000000000
e0ddd0eeee0ddd0ee0ddd0eeee0d7d0ee07770eeee077d0ee077d0eeee0ddd0eeeeee676666eeeeeeeeeeeeeeeeeeeee7777767666650eeeeeee007777777777
eddd0eeeeee0dddeeddd0eeeeee077deedd70eeeeee07ddee7770eeeeee0dddeeeeee766665eeeee676767670eeeeeee6767676666550eeeeee0077767676767
0d7deeeeeeeed7700dddeeeeeeee77700dddeeeeeeeeddd00d77eeeeeeeeddd0eeeee676666eeeee7676767660eeeeee7676767666650eeeeee0777676767676
0770eeeeeeee07d00dd0eeeeeeee07d00dd0eeeeeeee0dd00d70eeeeeeee0dd0eeeee766665eeeee6666666666eeeeee6666666666550eeeeee0776666666666
0d70eeeeeeee07700d70eeeeeeee0dd00dd0eeeeeeee0dd00dd0eeeeeeee07d0eeeee066650eeeee6666666665eeeeee6666666665550eeeeee0767666666666
077deeeeeeeed7d00777eeeeeeeeddd00dddeeeeeeeeddd00dddeeeeeeee77d0eeeeee0650eeeeee6666666650eeeeee6666666655550eeeeee0776666666666
eddd0eeeeee0dddeed770eeeeee0dddeedd70eeeeee07ddeeddd0eeeeee0777eeeeeeeeeeeeeeeee656565650eeeeeee6565656555500eeeeee0767666656565
e0ddd0eeee0ddd0ee0d7d0eeee0ddd0ee0d770eeee07770ee0ddd0eeee0d770eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee555555555500eeeeeee0776666555555
ee0dddd00dddd0eeee0dddd00777d0eeee0777d00d7770eeee0d77700dddd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000eeeeeeee0767666650000
ee00dd7777dd00eeee00dddd777700eeee00ddddddd700eeee00d777dddd00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0776666550eee
eeee0d7d7dd0eeeeeeee0ddddd70eeeeeeee0dddddd0eeeeeeee0d7dddd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0767666650eee
eeeeee0000eeeeeeeeeeee0000eeeeeeeeeeee0000eeeeeeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0776666550eee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777eeeeeaaeeeeee6666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee70000eeeeeaaeeeee65ee56eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeee000eeee0eee0eee00000eeeeeeeeeeeeeeeeeeeee0eeeeeeeeeee70eeeeeeaa77aaaee65ee56eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee000eeee0eee0eeee0e0eeeeeeeeeeee0eee0eeeee0eeeeee000eeeeeeeeee70eeeeeeea777aee6666666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee000eeee0eee0eeeee0eeeee00000eeee0e0eeeee000eeee00000eeeeeeeee70eeeeeeeea7aeee6577756eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee000eeee0eee0eeee0e0eeeeeeeeeeeeee0eeeee00000eeee000eeeeeeeeeeeeeeeeeeeaaeaaee6570756eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeee000eeee0eee0eee00000eeeeeeeeeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeaeeeaee6577756eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee66666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeee000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00000000000eeeeeeeee00777700eeeeeeee000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
777777777600eeeeeee0077776600eeeeee0077777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
6767676766600eeeeee0777766660eeeee00777767676767eeeeeeeeeeeeeeeeeeeeeee077676767eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
7676767666650eeeeee0777666650eeeee07777676767676eeeeee0770eeeeeeeeeeee0776767676eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
6666666666550eeeeee0776666550eeeee07776666666666eeeee077660eeeeeeeeeee7766666666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
6666666665650eeeeee0767666650eeeee07766666666666eeeee776666eeeeeeeeeee7666666666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
6666666666550eeeeee0776666550eeeee07666666666666eeeee766665eeeeeeeeeee0666666666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
6565667666650eeeeee0767666650eeeee00666565656565eeeee676666eeeeeeeeeeee065656565eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
5555676666550eeeeee0776666550eeeeee0065555555555eeeee766665eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000767666650eeeeee0767666650eeeeeee000000000000eeeee676666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0776666550eeeeee0776666550eeeeeeeeeeeeeeeeeeeeeeee766665eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0767666650eeeeee0767666650eeeeeeeeeeeeeeeeeeeeeeee676666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0776666550eeeeee0776666550eeeeeeeeeeeeeeeeeeeeeeee766665eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
1111111111e111111111111111111111111111111e1111111e1111eeeeeeeeeeeee11111111111111eeeeeee1111111111111eeeee1111eeeeeeeeeeeeeeeeee
177777777111777777711777777771177777777711177777111771eeeeeeeeeeeee17777777771771eeeeee11777777711771eeeee1771eeeeeeeeeeeeeeeeee
177777777117711111771771111177177777777711771117711771eeeeeeeeeeeee17777777771771eeeeee17711111771771eeeee1771eeeeeeeeeeeeeeeeee
17711111771771ddd1771771ddd177111177711117711d11771771deeeeeeeeeeee17711111111771deeeee1771ddd1771771deeee1771deeeeeeeeeeeeeeeee
17711111771771dee17717711111771de17771dd17711111771771deeeeeeeeeeee17711111111771deeeee1771dee1771771d111e1771deeeeeeeeeeeeeeeee
17777777711771dee17717777777711de17771de17777777771771deeeeeeeeeeee17777777711771deeeee1771dee1771771117111771deeeeeeeeeeeeeeeee
17777777711771dee1771771777111dde17771de17777777771771deeeeeeeeeeee17777777711771deeeee1771dee1771771177711771deeeeeeeeeeeeeeeee
17711111111771dee1771771177711dee17771de17711111771771deeeeeeeeeeee17711111111771deeeee1771dee1771771771771771deeeeeeeeeeeeeeeee
1771dddddd1771dee17717711177711ee17771de1771ddd17717711111111eeeeee1771dddddd17711111111771dee1771771771771771deeeeeeeeeeeeeeeee
1771deeeee17711111771771d117771ee17771de1771dee17717777777771eeeeee1771deeeee177777777717711111771777771777771deeeeeeeeeeeeeeeee
1771deeeee11777777711771de11771ee17771de1771dee17717777777771eeeeee1771deeeee177777777711777777711177711177711deeeeeeeeeeeeeeeee
1111deeeeee1111111111111dee1111de11111de1111dee11111111111111deeeee1111deeeee11111111111111111111d11111d11111ddeeeeeeeeeeeeeeeee
eeeddeeeeeeeeedddddddeeddeeeeeddeeeedddeeeeddeeeeeddedddddddddeeeeeeeeddeeeeeeeedddddddddeedddddddeeedddeeedddeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d1d1d1177777777111777777711777777771177777777711177777111771d1d1d1d1d1d1d177777777717711d1d1d117777777117711d1d11771d1d1d1d111
111111111777777771177111117717711111771777777777117711177117711d1d1d1d1d1d117777777771771d1d1d117711111771771d1d1d17711d11111111
11d1d1d117711111771771ddd1771771ddd177111177711117711d11771771d1d1d1d1d1d1d17711111111771dd1d1d1771ddd1771771dd1d11771d1d1d1d111
1111111117711111771771dd117717711111771d117771dd17711111771771dd1d1d1d1d1d117711111111771d1d1d11771d1d1771771d111d1771dd11111111
11d1d1d117777777711771d1d17717777777711dd17771d117777777771771d1d1d1d1d1d1d17777777711771dd1d1d1771dd11771771117111771d1d1d1d111
1111111117777777711771dd11771771777111dd117771dd17777777771771dd1d1d1d1d1d117777777711771d1d1d11771d1d1771771177711771dd11111111
11d1d1d117711111111771d1d1771771177711d1d17771d117711111771771d1d1d1d1d1d1d17711111111771dd1d1d1771dd11771771771771771d1d1d1d111
111111111771dddddd1771dd117717711177711d117771dd1771ddd17717711111111d1d1d11771dddddd17711111111771d1d1771771771771771dd11111111
11d1d1d11771d1dddd17711111771771d117771dd17771dd1771ddd17717777777771dddddd1771dddddd177777777717711111771777771777771d1d1d1d111
111111111771dd1d1d11777777711771dd11771d117771dd1771dd117717777777771d1d1d11771d1d1d1177777777711777777711177711177711dd11111111
11d1d1d11111d1ddddd1111111111111ddd1111dd11111dd1111ddd11111111111111dddddd1111dddddd11111111111111111111d11111d11111dd1d1d1d111
111111111d1ddd1d1d1d1ddddddddd1ddd1d1ddd1d1ddddd1d1ddd1d1ddd1ddddddddd1d1d1d1ddd1d1d1d1ddddddddddd1ddddddd1d1ddd1d1ddd1d11111111
11d1d1d1d1d1d1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d1d1d1d1d111
111111111d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d11111111
11d1d1d1d1d1d1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d1d1d1d1d111
111111111d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d11111111
11d1d1d1d1d1d1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d1d1d1d1d111
111111111d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d11111111
11d1d1d1d1d1d1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d1d1d1d1d111
111111111d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d11111111
11d1d1d1d1d1d1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d1d1d1d1d111
111111111d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d11111111
11d1d1d1d1d1d1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d1d1d1d1d111
111111111d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d11111111
11d1d1d1d1d1d1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d1d1d1d1d111
111111111d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d11111111
11d1d1d1d1d1d1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d1d1d1d1d111
111111111d1d111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1d11111111
11d1d1d1d1d11dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d1d1d1d1d111
111111111d1d1dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11d1d11111111
11d1d1d1d1d11dd66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666dd1d1d1d1d1d111
111111111d1d1dd6d11111111111111dd11111111111111dd11111111111111dd11111111111111dd11111111111111dd11111111111111d6dd11d1d11111111
11d1d1d1d1d11dd61111100000011111111111111111111111111111111111111111111111111111111111111111111111111111111111116dd1d1d1d1d1d111
111111111d1d1dd611100aaaaaa00111111111111111111111111111111111111111111111111111111111111111111111111111111111116dd11d1d11111111
11d1d1d1d1d11dd61100aaaabbba0000000000000000000000000000000000000000000000000000000000000000000000000000000d11116dd1d1d1d1d1d111
111111111d1d1dd6110aaaaaabb3a0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa33333333330011116dd11d1d11111111
11d1d1d1d1d11dd610aaaaaababb3a0bbabababababababababababababababababababababababababababababababa3b3b3b3b3bb001116dd1d1d1d1d1d111
111111111d1d1dd610aaaa0aab033a0aababababababababababababababababababababababababababababababababbbbbbbbbbbbb01116dd11d1d11111111
11d1d1d1d1d11dd610aaaaa0b0bb3a0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbba01116dd1d1d1d1d1d111
111111111d1d1dd610ababab0bb33a0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaa01116dd11d1d11111111
11d1d1d1d1d11dd610abbab0b0333a0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabababbbaba01116dd1d1d1d1d1d111
111111111d1d1dd610abbb0bb3033a0bb3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3ababa3bbbbaa01116dd11d1d11111111
11d1d1d1d1d11dd6110a3b3b3333a0333333333333333333333333333333333333333333333333333333333333333333aaaa3bbbbaba01116dd1d1d1d1d1d111
111111111d1d1dd61100a333333a00000000000000000000000000000000000000000000000000000000000000000000000033bbbbaa01116dd11d1d11111111
11d1d1d1d1d11dd611100aaaaaa001111111111111111111111111111111111111111111111111ccccccccccccccccccccc03bbbbaba01116dd1d1d1d1d1d111
111111111d1d1dd61111100000011111111111111111111111111111111111111111111111111c1c1c1c1c1c1ccc1c1c1c1033bbbbaa01116dd11d1d11111111
11d1d1d1d1d11dd6d11111111111111dd11111111111111dd11111111111111dd11111111111ccccccccccccccccccccccc03bbbbaba011d6dd1d1d1d1d1d111
111111111d1d1dd6d11111111111111dd11111111111111dd11111111111111dd1111111111c1c17dc1c1c00001c1c1cdc10ababbbb3011d6dd11d1d11111111
11d1d1d1d1d11dd611111000000111111111111111111111111111111111111111111111111ccccccccc0dd7d7d0ccccccc0aabbbb3301116dd1d1d1d1d1d111
111111111d1d1dd611100eeeeee001111111111111111111111111111111111111111111111c1c1c1c00dd7777dd001c1c10ababbbb301116dd11d1d11111111
11d1d1d1d1d11dd61100eeee888e0000000000000000000000000000000000000000000000000000000dddd00dddd0ccccc0aabbbb3301116dd1d1d1d1d1d111
111111111d1d1dd6110eeeeee882e0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0ddd0eeee0ddd0c1c10ababbbb301116dd11d1d11111111
11d1d1d1d1d11dd610eeeeee8e882e088e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8ddd0e8e8e80dddc7cc0aabbbb3301116dd1d1d1d1d1d111
111111111d1d1dd610eeeeeee8822e0ee8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e80d7de8e8e888d7701c10ababbbb301116dd11d1d11111111
11d1d1d1d1d11dd610eeeee000882e0888888888888888888888888888888888888888888888888807708888888807d0ccc0aabbbb3301116dd1d1d1d1d1d111
111111111d1d1dd610e8e8e000822e088888888888888888888888888888888888888888888888880d708888888207701c10ababbbb301116dd11d1d11111111
11d1d1d1d1d11dd610e88e8000222e08888888888888888888888888888888888888888888888888077d88cc7822d7d0ccc0aabbbb3301116dd1d1d1d1d1d111
111111111d1d1dd610e8888882222e0882828282828282828282828282828282828282828282828c8ddd0c878220dddc1c10ababbbb301116dd11d1d11111111
11d1d1d1d1d11dd6110e28282222e02222222222222222222222222222222222222222222222222220ddd022220ddd0cccc0aabbbb3301116dd1d1d1d1d1d111
111111111d1d1dd61100e222222e0000000000000000000000000000000000000000000000000000000dddd00dddd01c1c10ababbbb301116dd11d1d11111111
11d1d1d1d1d11dd611100eeeeee00111111111111111111111111111111111111111111111cccccccc00dd7777dd00ccccc0aabbbb3301116dd1d1d1d1d1d111
111111111d1d1dd611111000000111111111111111111111111111111111111111111111111c1c1c171c0d7d7dd01c1c1c10ababbbb301116dd11d1d11111111
11d1d1d1d1d11dd6d11111111111111dd11111111111111dd11111111111111dd1111111111cccc7cccccc0000ccccccccc0aabbbb33011d6dd1d1d1d1d1d111
111111111d1d1dd6d11111111111111dd11111111111111dd11111111111111dd1111111111c171cdc1c1c1c1c1c1c1cdc10ababbbb3011d6dd11d1d11111111
11d1d1d1d1d11dd61111100000011111111111111111111111111111111111111111111111cc7cccccccc7ccccccccccccc0a000000301116dd1d1d1d1d1d111
111111111d1d1dd6111007777770011111111111111111111111111111111111111111111c171c1c1c1c1c1c1c1c1c1c1c100aaaaaa001116dd11d1d11111111
11d1d1d1d1d11dd611007777ccc70011111d1111111d1111111d1111111d1111111d111cc71d11cccccccccccccccccccc00aaaabbba00116dd1d1d1d1d1d111
111111111d1d1dd6110777777cc1701111111111111111111111111111111111111111171111111c1c1c1c1c1c1c1c1c1c0aaaaaabb3a0116dd11d1d11111111
11d1d1d1d1d11dd610777777c7cc1701111111111111111111111111111111111111cc7111111111ccccccccccccccccc0aaaaaababb3a016dd1d1d1d1d1d111
111111111d1d1dd61077777000c1170111111111111111111111111111111111111c171111111111111c1c1c1c1c1c1110aaaa0aab033a016dd11d1d11111111
11d1d1d1d1d11dd610777707cc0c1701111111111111111111111111111111111cc711111111111111111ccccccc111110aaaaa0b0bb3a016dd1d1d1d1d1d111
111111111d1d1dd6107c7c0ccc011701111111111111111111111111111111111711111111111111111111111111111110ababab0bb33a016dd11d1d11111111
11d1d1d1d1d11dd6107cc70ccc01170111111ccccccc111111111111111111cc7111111111111111111111111111111110abbab0b0333a016dd1d1d1d1d1d111
111111111d1d1dd6107cccc000111701111c1c1c1c1c1c111111111111111c171111111111111111111111111111111110abbb0bb3033a016dd11d1d11111111
11d1d1d1d1d11dd611071c1c11117011ccccccccccccccccc11d1111111cc711111d1111111d1111111d1111111d1111110a3b3b3333a0116dd1d1d1d1d1d111
111111111d1d1dd6110071111117001c1c1c1c1c1c1c1c1c1c11111111171111111111111111111111111111111111111100a333333a00116dd11d1d11111111
11d1d1d1d1d11dd611100777777001ccccccccccccccccccccc11111cc7111111111111111111111111111111111111111100aaaaaa001116dd1d1d1d1d1d111
111111111d1d1dd61110700000010c1c1c1c1c1c1ccc1c1c1c1c111c171111111111111111111111111111111111111111111000000111116dd11d1d11111111
11d1d1d1d1d11dd6d1107c7cccc10cccccccccccccccccccccccccc71111111dd11111111111111dd11111111111111dd11111111111111d6dd1d1d1d1d1d111
111111111d1d1dd6d1107c7cccc10c17dc1c1c00001c1c1cdc1c17111111111dd11111111111111dd11111111111111dd11111111111111d6dd11d1d11111111
11d1d1d1d1d11dd6111077cccc110ccccccc0dd7d7d0cccccccc7c11111111111111111111111111111111111111111111111111111111116dd1d1d1d1d1d111
111111111d1d1dd611107c7cccc10c1c1c00dd7777dd001c1c171c11111111111111111111111111111111111111111111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6111077cccc110ccccc0dddd00dddd00cc700000000000000000000000000000000000000000d1111111d1111111d11116dd1d1d1d1d1d111
111111111d1d1dd611107c7cccc10c1c10ddd0eeee0ddd07eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee222222222200111111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6111077cccc110ccccddd08e8e8e0ddd87e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e282828282880011111111111111111116dd1d1d1d1d1d111
111111111d1d1dd611107c7cccc10c1c0d7d888e8e8cd770e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8888888888888011111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6111077cccc110ccc077088888cc707d08888888888888888888888888888888888888888888e011111111111111111116dd1d1d1d1d1d111
111111111d1d1dd611107c7cccc10c1c0d70288887880770888888888888888888888888888888888888888888ee011111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6111077cccc110ccc077d22887888d7d0888888888888888888888888888888888e8e8e888e8e011111111111111111116dd1d1d1d1d1d111
111111111d1d1dd611107c7cccc10c1c1ddd02282820ddd882828282828282828282828282828282e8e8e28888ee011111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6111077cccc110cccc0ddd022220ddd0222222222222222222222222222222222eeee28888e8e0111111d1111111d11116dd1d1d1d1d1d111
111111111d1d1dd611107c7cccc10c1c1c0dddd00dddd000000000000000000000000000000000000000228888ee011111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6111077cccc110ccccc00dd7777dd00ccccccccc1111111111111111111111111111028888e8e011111111111111111116dd1d1d1d1d1d111
111111111d1d1dd611107c7cccc10c1c1c1c0d7d7dd01c1c1c1c1c111111111111111111111111111110228888ee011111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6d11077cccc110ccccccccc0000cccccccccccc111111111dd11111111111111dd11028888e8e011dd11111111111111d6dd1d1d1d1d1d111
111111111d1d1dd6d1107c7cccc10c1cdc1c1c1c1c1c1c1cdc1c1c111111111dd11111111111111dd110e8e88882011dd11111111111111d6dd11d1d11111111
11d1d1d1d1d11dd6111077cccc110cccccccc7ccccccccccccccc1111111111111111000000111111110e0000002011111111111111111116dd1d1d1d1d1d111
111111111d1d1dd611107c7cccc10c1c1c1c1c1c1c1c1c1c1c1c111111111111111007777770011111100eeeeee0011111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6111077cccc1100000000000000000000000000000000000000007777ccc700111100eeee888e0011111d1111111d11116dd1d1d1d1d1d111
111111111d1d1dd611107c7cccc1777777777777777777777777777777777777770777777cc17011110eeeeee882e01111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6111077cccc17c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c0777777c7cc170110eeeeee8e882e0111111111111111116dd1d1d1d1d1d111
111111111d1d1dd611107c7ccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7077777000c1170110eeeeeee8822e0111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6111077ccccccccccccccccccccccccccccccccccccccccccc0777707cc0c170110eeeee000882e0111111111111111116dd1d1d1d1d1d111
111111111d1d1dd611107cccccccccccccccccccccccccccccccccccccccccccc07c7c0ccc01170110e8e8e000822e0111111111111111116dd11d1d11111111
11d1d1d1d1d11dd61110ccccccccccccccccccccccccccccccccccccccccccccc07cc70ccc01170110e88e8000222e0111111111111111116dd1d1d1d1d1d111
111111111d1d1dd611100cc1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c07cccc00011170110e8888882222e0111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6111d0011111111111111111111111111111111111111111111071c1c11117011110e28282222e011111d1111111d11116dd1d1d1d1d1d111
111111111d1d1dd611111000000000000000000000000000000000000000000000007111111700111100e222222e001111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6111111111111111111111111111111111111111111111111111007777770011111100eeeeee0011111111111111111116dd1d1d1d1d1d111
111111111d1d1dd61111111111111111111111111111111111111111111111111111100000011111111110000001111111111111111111116dd11d1d11111111
11d1d1d1d1d11dd6d11111111111111dd11111111111111dd11111111111111dd11111111111111dd11111111111111dd11111111111111d6dd1d1d1d1d1d111
111111111d1d1dd66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666dd11d1d11111111
11d1d1d1d1d11dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1d1d1d1d1d111
1111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1111111111111
11d1d1d1d1d111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1d1d1d1d111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
__sfx__
010600003412500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a000018135191351a1351b1351c1351d1351e1351f135201352113522135231352413525135261352713528135291352a1352b1352c1352d1352e1352f1353013531135321353313534135351353613537135
010a000018025190251a0251b0251c0251d0251e0251f025200252102522025230252402525025260252702528025290252a0252b0252c0252d0252e0252f0253002531025320253302534025350253602537025
010800002b34530335000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900001f03500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0108000024140281402b1450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00002603021035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01070000185411f541265412d53200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700002d541265411f5411853200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001002500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002953500000235350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b00002b1402d1402f1403215030155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700002d33426335000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000302432b243262331f23318225000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600003012500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000245402b545000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800002b54024545000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0105000034140391403b1450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900003b54500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500002d32526315000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011c0000130401304113041130411304113041130411304113040130411304113041130411304113041130410e0400e0410e0410e0410e0410e0410e0410e0410e0400e0410e0410e0410e0410e0410e0410e041
011c0000100401004110041100411004110041100411004110040100411004110041100411004110041100410c0400c0410c0410c0410c0410c0410c0410c0410c0400c0410c0410c0410c0410c0410c0410c041
011c0000150401504115041150411504115041150411504115040150411504115041150411504115041150410e0400e0410e0410e0410e0410e0410e0410e0410e0400e0410e0410e0410e0410e0410e0410e041
011c00001304013041130411304113041130411304113041130401304113041130411304113041130411304113040130411304113041130411304113041130411304013041130411304113041130411304113041
011c0000000000000023530235312353123531265302653126531265312a5302a5312a5312a5312653026531000000000021530215312153121531265302653126531265312a5302a5312a5312a5312653026531
011c000000000000001f5301f5311f5311f5312353023531235312353126530265312653126531235302353100000000001f5301f5311f5311f53124530245312453124531285302853128531285312453024531
011c0000000000000024530245312453124531285302853128531285312d5302d5312d5312d5312853028531000000000021530215312153121531265302653126531265312a5302a5312a5312a5312653026531
011c0000000000000023530235312353123531265302653126531265312b5302b5312b5312b5312653026531000000000023530235312353123531265302653126531265312b5302b5312b5312b5312353023531
011c00000000000000000000000026140261412614126141261412614126141261412314023141231412314121140211412114121141211412114121141211411e1401e1411e1411e1411e1411e1411e1411e141
011c00000000000000000000000028140281412814128141281412814128141281412614026141261412614123140231412314123141231412314123141231412414024141241412414124141241412414124141
011c0000000000000000000000002b1402b1412b1412b141261402614126141261412314023141231412314121140211412114121141231402314123141231412114021141211412114121141211412114121141
011c00000000000000000000000024140241412414124141241412414124141241412114021141211412114123140231412314123141231412314123141231412114021141211412114121141211412114121141
011c000000000000000000000000000000000000000000002614026141261412614126141261412614126141000000000000000000001e1401e1411e1411e1411e1411e1411e1411e14121140211412114121141
011c0000000000000000000000002b1402b1412b1412b1412b1412b1412b1412b1412814028141281412814100000000000000000000261402614126141261412614126141261412614124140241412414124141
011c00000000000000000000000028140281412814128141261402614126141261412414024141241412414123140231412314123141231412314123141231412114021141211412114121141211412114121141
011c0000000000000000000000002314023141231412314123141231412314123141261402614126141261411f1401f1411f1411f1411f1411f1411f1411f1411f1411f1411f1411f1411f1411f1411f1411f141
011c0000181401c1401f14024140281401f1402414028140181401c1401f14024140281401f1402414028140181401a140211402614029140211402614029140181401a140211402614029140211402614029140
011c0000171401a1401f14026140291401f1402614029140171401a1401f14026140291401f1402614029140181401c1401f14024140281401f1402414028140181401c1401f14024140281401f1402414028140
011c0000181401c14021140281402d14021140281402d140181401c14021140281402d14021140281402d140181401a1401e14021140261401e1402114026140181401a1401e14021140261401e1402114026140
011c0000171401a1401f140261402b1401f140261402b140171401a1401f140261402b1401f140261402b14017140181401c1401f140241401c1401f1402414017140181401c1401f140241401c1401f14024140
011c0000181401c1401f14024140281401f14024140281400000000000000000000000000000000000000000181401a1402114026140291402114026140291400000000000000000000000000000000000000000
011c0000171401a1401f14026140291401f14026140291400000000000000000000000000000000000000000181401c1401f14024140281401f14024140281400000000000000000000000000000000000000000
011c0000181401c14021140281402d14021140281402d1400000000000000000000000000000000000000000181401a1401e14021140261401e14021140261400000000000000000000000000000000000000000
011c0000171401a1401f140261402b1401f140261402b140000000000000000000000000000000000000000017140181401c1401f140241401c1401f140241400000000000000000000000000000000000000000
011c00000c0400c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0400c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c041
011c00000b0400b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410c0400c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c041
011c00000b0400b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0400b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b0410b041
011c0000070400704107041070410704107041070410704107041070410704107041070410704107041070410c0400c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c0410c041
011c00000000000000000000000000000000000000000000285302853128531285312853128531285312853100000000000000000000000000000000000000002953029531295312953129531295312953129531
011c00000000000000000000000000000000000000000000265302653126531265312653126531265312653100000000000000000000000000000000000000002853028531285312853128531285312853128531
011c0000000000000000000000002d1402d1412d1412d1412d1412d1412c1402c1412c1412c1412c1412c1412f1402f1412f1412f1412f1412f1412d1402d1412d1412d1412d1412d1412d1412d1412d1412d141
011c00000000000000000000000028140281412814128141281412814129140291412914129141291412914128140281412814128141281412814128141281412814128141281412814128141281412814128141
011c0000000000000000000000003014030141301413014130141301412f1402f1412f1412f1412f1412f1412d1402d1412d1412d1412d1412d1412c1402c1412c1412c1412c1412c1412c1412c1412c1412c141
011c0000000000000000000000002d1402d1412d1412d1412d1412d1412d1412d1412d1412d1412d1412d14128140281412814128141281412814128141281412814128141281412814128141281412814128141
011c0000000000000000000000003214032141321413214132141321413014030141301413014130141301412f1402f1412f1412f1412f1412f1412d1402d1412d1412d1412d1412d1412d1412d1412d1412d141
011c00000000000000000000000029140291412914129141291412914128140281412814128141281412814126140261412614126141261412614124140241412414124141241412414124141241412414124141
011c0000000000000000000000002f1402f1412f1412f1412f1412f1412f1412f141301403014130141301412f1402f1412f1412f1412f1412f1412c1402c1412c1412c1412c1412c1412c1412c1412c1412c141
011c0000000000000000000000002d1402d1412d1412d1412d1412d1412d1412d1412d1412d1412d1412d14121140211412114121141211412114121141211412114121141211412114121141211412114121141
011c00000904009041090410904109041090410904109041100401004110041100411004110041100411004104040040410404104041040410404104041040410b0400b0410b0410b0410b0410b0410b0410b041
011c0000090400904109041090410904109041090410904110040100411004110041100411004110041100410e0400e0410e0410e0410e0410e0410e0410e0411504015041150411504115041150411504115041
011c000005040050410504105041050410504105041050410c0400c0410c0410c0410c0410c0410c0410c04104040040410404104041040410404104041040410b0400b0410b0410b0410b0410b0410b0410b041
011c00000000000000000000000024530245312453124531285302853128531285312d5302d5312d5312d5310000000000000000000023530235312353123531285302853128531285312c5302c5312c5312c531
011c00000000000000000000000026530265312653126531295302953129531295312d5302d5312d5312d5310000000000000000000024530245312453124531285302853128531285312d5302d5312d5312d531
011c00000000000000000000000024530245312453124531295302953129531295312d5302d5312d5312d5310000000000000000000023530235312353123531285302853128531285312c5302c5312c5312c531
__music__
01 14181c44
00 15191d44
00 141a1e44
00 161b1f44
00 14182044
00 15432144
00 161a2244
02 171b2344
01 2c432444
00 2d302544
00 2c432644
00 2e312744
00 2c302844
00 2d432944
00 2c312a44
02 2f432b44
01 3a433244
00 3b3d3344
00 3a433444
00 3c3e3544
00 3b3f3644
00 3a433744
00 3c3d3844
02 3a433944
