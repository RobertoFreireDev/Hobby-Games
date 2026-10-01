-- portal flow
-- by roberto freire

-- level rows: "." empty, 1-7 dot, "p" portal.
-- spliced in from levels.json by mk.js.
lv={}

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
