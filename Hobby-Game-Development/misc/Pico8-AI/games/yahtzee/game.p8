pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- high roller
-- by roberto freire

dith={
 0b0000000000000000,
 0b1000000000000000,
 0b1000001000000010,
 0b1000010100100000,
 0b0101101001011010,
 0b0111101011011010,
 0b0111110101111101,
 0b0111111111011111,
 0b1111111111111111}

cn={"ones","twos","threes","fours","fives","sixes",
 "3 kind","4 kind","f house","sm str","lg str","yahtzee","chance"}

function _init()
 cartdata("rbt_hiroll1")
 if dget(6)!=1 then
  for i=0,7 do dset(i,0) end
  dset(5,5) dset(6,1)
 end
 flg=dget(5)
 mon=(flg&1)>0
 dif=mid(0,(flg>>2)&3,2)
 menuitem(1,"music",togmus)
 setpal()
 palt(0,false)
 palt(13,true)
 mkev()
 dice={}
 for i=1,5 do
  add(dice,{v=i,vy=0,vx=0,nv=i,sq=0,dl=0,hp=0,bo=i*8})
 end
 resetdice()
 ps={}
 pcap=52 slow=0
 tk=0 shk=0 fla=0 wip=0
 face=1 fext=0
 gost("title")
end

function resetdice()
 for i=1,5 do
  local d=dice[i]
  d.hx=16+(i-1)*20
  d.x=d.hx d.by=88 d.y=88
  d.fly=false d.h=false d.vy=0
 end
 rolling=false
end

function setpal()
 local p={128,131,133,3,132,134,6,7,136,9,135,139,140,141,142,143}
 for i=0,15 do pal(i,p[i+1],1) end
end

function gost(s)
 st=s
 wip=14
 ban=nil
 ps={}
 if s=="title" then
  tdt=0 tlogo=-30
  mplay(0)
 elseif s=="game" then
  newgame()
  mplay(8)
 elseif s=="res" then
  saverec()
  mplay(tot[1]>tot[2] and 24 or 28)
 end
end

function togmus()
 mon=not mon
 flg=mon and (flg|1) or (flg&~1)
 dset(5,flg)
 mplay(st=="game" and 8 or 0)
 sfx(22)
end

function setdif(d)
 dif=d
 flg=(flg&~12)|(d<<2)
 dset(5,flg)
end

function mplay(n)
 if mon then music(n) else music(-1) end
end

function anyp()
 return btnp(4) or btnp(5) or btnp(2) or btnp(3)
end

function shake(n)
 shk=max(shk,n)
end

function _update60()
 tk+=1
 if nag and nag>0 then nag-=1 end
 if stat(1)>0.85 then
  slow+=1
  if slow>30 then pcap=24 end
 else
  slow=0
 end
 if wip>0 then wip-=1 end
 if shk>0 then
  shk*=0.82
  if shk<0.25 then shk=0 end
 end
 if fla>0 then fla-=1 end
 if fext>0 then fext-=1 end
 updp()
 upban()
 if st=="title" then uptitle()
 elseif st=="game" then upgame()
 else upres() end
end

function _draw()
 cls(3)
 camera(rnd(shk)-shk/2,rnd(shk)-shk/2)
 felt()
 if st=="title" then dtitle()
 elseif st=="game" then dgame()
 else dres() end
 if fla>0 then
  fillp(dith[mid(1,fla,3)])
  rectfill(0,0,127,127,0xa3)
  fillp()
 end
 drawp()
 dban()
 camera()
 if wip>0 then
  fillp(dith[mid(1,10-wip,9)]|0b0000000000000000.1)
  rectfill(0,0,127,127,0)
  fillp()
 end
end

-- dithered felt with vignette
function felt()
 local b=flr(sin(tk/480)+1.5)
 for i=1,4 do
  fillp(dith[8-i+b])
  local m=(i-1)*5
  rectfill(m,m,127-m,127-m,0x13)
 end
 fillp()
end

-- text: 1px shadow
function pr(s,x,y,c)
 print(s,x+1,y+1,0)
 print(s,x,y,c)
 return x
end

-- text: full outline
function po(s,x,y,c)
 for i=-1,1 do
  for j=-1,1 do
   print(s,x+i,y+j,0)
  end
 end
 print(s,x,y,c)
end

-- centred outlined text, g = wide glyphs
function poc(s,y,c,g)
 local x=64-flr((#s*4+(g or 0)*4)/2)
 po(s,x,y,c)
 return x
end

-- right aligned to x
function prr(s,x,y,c)
 s=""..s
 pr(s,x-#s*4,y,c)
end
-->8
-- dice

function faces()
 local f={}
 for i=1,5 do f[i]=dice[i].v end
 return f
end

-- false if every die is held, so nothing would roll
function roll()
 local n=0
 for d in all(dice) do
  if not d.h then n+=1 end
 end
 if n==0 then return false end
 rl-=1
 shake(2)
 sfx(0,3)
 for i=1,5 do
  local d=dice[i]
  if not d.h then
   d.fly=true
   d.dl=(i-1)*2
   d.vy=-3-rnd(0.6)
   d.vx=rnd(1.2)-0.6
   d.y=d.by
   d.x=d.hx
   d.nv=1+flr(rnd(6))
   puff(d.x+8,d.by+14)
  end
 end
 rolling=true
 return true
end

function snap()
 for d in all(dice) do
  if d.fly then
   d.fly=false d.v=d.nv
   d.x=d.hx d.y=d.by d.vy=0 d.sq=3
  end
 end
 rolling=false
 sfx(0,-2)
 sfx(1)
end

function updice()
 local any=false
 for i=1,5 do
  local d=dice[i]
  if d.fly then
   any=true
   if d.dl>0 then
    d.dl-=1
   else
    d.vy+=0.3
    d.y+=d.vy
    d.x+=d.vx
    if d.y>=d.by then
     d.y=d.by
     d.v=d.nv
     d.sq=4
     sfx(1)
     ring(d.x+8,d.by+13)
     if d.vy>1.1 then
      d.vy=-d.vy*0.34
      d.vx*=0.5
      shake(1)
     else
      d.fly=false d.vy=0 d.x=d.hx
     end
    end
   end
  end
  if d.sq>0 then d.sq-=1 end
  if d.hp>0 then d.hp-=1 end
 end
 if rolling and not any then
  rolling=false
  sfx(0,-2)
 end
end

function dicerow()
 for i=1,5 do
  local d=dice[i]
  local y=d.y+(d.h and 2 or 0)-d.hp*0.5
  if not d.fly and d.h then
   y+=sin((tk+d.bo)/80)*0.6
  end
  -- shadow
  local h=mid(0,(d.by-d.y)/20,1)
  fillp(dith[5])
  ovalfill(d.x+1+h*3,d.by+12+h,d.x+14-h*3,d.by+16,0x23)
  fillp()
  -- body
  local sx=(d.v-1)*16
  if d.fly or rl==3 then sx=96+(flr(tk/2)%2)*16 end
  local w,h2=16,16
  if d.sq>0 then
   w=16+d.sq
   h2=16-d.sq
   y+=d.sq
  end
  if d.h then
   pal(7,6) pal(6,5) pal(15,5)
  end
  sspr(sx,0,16,16,d.x+(16-w)/2,y,w,h2)
  if d.h then
   pal(7,7) pal(6,6) pal(15,15)
   spr(32,d.x,d.by+15,2,1)
  end
 end
end

function dcursor()
 if ph=="roll" and not rolling then
  spr(34,dice[hcur].hx+4,104+sin(tk/24))
 end
end
-->8
-- scoring

function cnt(f)
 local c={0,0,0,0,0,0}
 local s=0
 for i=1,5 do
  local v=f[i]
  c[v]+=1
  s+=v
 end
 return c,s
end

function nk(c,n)
 for i=1,6 do
  if c[i]>=n then return true end
 end
 return false
end

function strk(c,n)
 local r=0
 for i=1,6 do
  if c[i]>0 then
   r+=1
   if r>=n then return true end
  else
   r=0
  end
 end
 return false
end

function mkev()
 ev={}
 for i=1,6 do
  ev[i]=function(c,s) return c[i]*i end
 end
 ev[7]=function(c,s) return nk(c,3) and s or 0 end
 ev[8]=function(c,s) return nk(c,4) and s or 0 end
 ev[9]=function(c,s)
  if nk(c,5) then return 25 end
  local a,b=false,false
  for i=1,6 do
   if c[i]>=3 and not a then
    a=true
   elseif c[i]>=2 then
    b=true
   end
  end
  return (a and b) and 25 or 0
 end
 ev[10]=function(c,s) return strk(c,4) and 30 or 0 end
 ev[11]=function(c,s) return strk(c,5) and 40 or 0 end
 ev[12]=function(c,s) return nk(c,5) and 50 or 0 end
 ev[13]=function(c,s) return s end
end

-- value of category i for player p with hand f
function pv(p,i,f)
 local c,s=cnt(f)
 if i>8 and i<12 and nk(c,5) and sc[p][12] then
  return i==9 and 25 or i==10 and 30 or 40
 end
 return ev[i](c,s)
end

function opencount(p)
 local n=0
 for i=1,13 do
  if not sc[p][i] then n+=1 end
 end
 return n
end

-- best open category for p with the dice on the table
function bestcat(p,w)
 local f,b,bi=faces(),-1,0
 for i=1,13 do
  if not sc[p][i] then
   local v=pv(p,i,f)
   if w and v>0 then v+=wt(i) end
   if v>b then b=v bi=i end
  end
 end
 if b<=0 then
  for i in all({1,2,3,10,9,11,4,8,7,5,6,12,13}) do
   if not sc[p][i] then return i end
  end
 end
 return bi
end

function recalc()
 local ld=tot[1]-tot[2]
 for p=1,2 do
  local u=0
  for i=1,6 do u+=sc[p][i] or 0 end
  local t=u+yzb[p]
  if u>=63 then
   t+=35
   if not bon[p] then
    bon[p]=true
    bonusfx(p)
   end
  end
  for i=7,13 do t+=sc[p][i] or 0 end
  upp[p]=u
  tot[p]=t
 end
 if ld<=0 and tot[1]-tot[2]>0 then
  sfx(13)
  for i=1,6 do spark(18+rnd(30),71) end
 end
end

function commit(p,i)
 local f=faces()
 local c,s=cnt(f)
 local v=pv(p,i,f)
 if nk(c,5) then
  if sc[p][12]==50 then
   yzb[p]+=100
   pop("+100",48,64,10)
   sfx(11)
   conf3(30)
  end
  if p==1 then yzl+=1 end
 end
 sc[p][i]=v
 cp=p ccat=i cval=v cnow=0
 ph="com" pht=0
 if v==0 then
  sfx(6)
  shake(2)
  if p==1 then setface(2,50) else setface(3,50) end
 else
  sfx(v>20 and 10 or 9)
 end
 if i==12 and v==50 then yahoo(p) end
end

function upcom()
 pht+=1
 if anyp() then
  pht=max(pht,27)
  celeb=0
 end
 if pht>14 and pht<=26 then
  cnow=ceil(cval*(pht-14)/12)
  if pht%2==0 then sfx(7) end
 end
 if pht>=32 and celeb<=0 then
  cnow=cval
  endturn()
 end
end
-->8
-- game flow

function newgame()
 hcur=1 rl=3
 resetdice()
 sc={{},{}}
 tot={0,0} dis={0,0} upp={0,0}
 yzb={0,0} bon={false,false}
 yzl=0 celeb=0 conf=false
 rnum=1 first=1
 newrec=false
 startround()
end

function startround()
 seq=first==1 and {1,2} or {2,1}
 ti=1
 ph="intro" pht=34
 sfx(17)
 if rnum==12 then mplay(20) end
end

function startturn()
 tp=seq[ti]
 rl=3
 hcur=1
 conf=false
 nag=0
 for d in all(dice) do d.h=false end
 if tp==1 then
  ph="roll"
 else
  ph="cpu"
  co=cocreate(cputurn)
 end
end

function endturn()
 recalc()
 ti+=1
 if ti>2 then
  rnum+=1
  first=3-first
  if rnum>13 then
   gost("res")
   return
  end
  startround()
 else
  startturn()
 end
end

function upgame()
 updice()
 upgame2()
end

function upgame2()
 if celeb>0 then celeb-=1 end
 if ph=="intro" then
  pht-=1
  if pht<=0 or anyp() then startturn() end
 elseif ph=="roll" then
  uproll()
 elseif ph=="tbl" then
  uptbl()
 elseif ph=="com" then
  upcom()
 elseif ph=="cpu" then
  if costatus(co)!="dead" then
   coresume(co)
  else
   ph="com"
  end
 end
end

function uproll()
 if rolling then
  if anyp() then snap() end
  if not btnp(3) then return end
 end
 if rl<=0 then
  totbl()
  return
 end
 if btnp(0) then hcur=(hcur+3)%5+1 sfx(4) end
 if btnp(1) then hcur=hcur%5+1 sfx(4) end
 if btnp(4) then
  if rl>=3 then
   sfx(6)
   nag=40 nagm="roll the dice first"
  else
   local d=dice[hcur]
   d.h=not d.h
   if d.h then
    sfx(2)
   else
    sfx(3)
    d.hp=8
   end
  end
 end
 if btnp(5) then
  if not roll() then
   sfx(6)
   nag=40 nagm="unhold a die to roll"
  end
 elseif btnp(3) then
  if rl<3 then
   totbl()
  else
   sfx(6)
   nag=40 nagm="roll the dice first"
  end
 end
end

function totbl()
 ph="tbl"
 cr=bestcat(1)
 pulse=34
 conf=false
 sfx(14)
end

-- first open row in panel p, stepping d from row r (wraps inside the panel)
function findrow(p,r,d)
 local n=p==1 and 6 or 7
 for k=1,n do
  r+=d
  if r<1 then r=n elseif r>n then r=1 end
  if not sc[1][p==1 and r or r+6] then return r end
 end
end

function uptbl()
 if pulse>0 then pulse-=1 end
 if conf then
  if btnp(5) then
   conf=false
   commit(1,cr)
  elseif btnp(4) then
   conf=false
   sfx(3)
  end
  return
 end
 local p=cr<=6 and 1 or 2
 local r=cr<=6 and cr or cr-6
 local mv=0
 if btnp(2) then mv=-1 end
 if btnp(3) then mv=1 end
 if mv!=0 then
  local nr=findrow(p,r,mv)
  if nr then r=nr sfx(4) end
  pulse=0
 end
 if btnp(0) or btnp(1) then
  local q=3-p
  local nr=findrow(q,min(r,q==1 and 6 or 7)-1,1)
  if nr then
   p=q r=nr
   sfx(4)
  else
   sfx(6)
  end
  pulse=0
 end
 cr=p==1 and r or r+6
 if btnp(4) and rl>0 then
  ph="roll"
  sfx(3)
  return
 end
 if btnp(5) then
  if sc[1][cr] then
   sfx(6)
   return
  end
  if pv(1,cr,faces())==0 and opencount(1)>1 then
   conf=true
   sfx(6)
   return
  end
  commit(1,cr)
 end
end
-->8
-- the house

function wt(i)
 if i<7 then
  return upp[tp]<63 and 8 or 0
 elseif i==12 then
  return 15
 elseif i==13 then
  return opencount(tp)>1 and -10 or 0
 end
 return 0
end

-- best achievable weighted value of a hand
function hv(g)
 local c,s=cnt(g)
 local b=0
 for i=1,13 do
  if not sc[tp][i] then
   local v=ev[i](c,s)
   if v>0 then v+=wt(i) end
   if v>b then b=v end
  end
 end
 return b
end

function simul(f,m,n)
 local tt=0
 for k=1,n do
  local g,g2={},{}
  for i=1,5 do
   g[i]=(m>>(i-1))&1==1 and f[i] or 1+flr(rnd(6))
   g2[i]=(m>>(i-1))&1==1 and f[i] or 1+flr(rnd(6))
  end
  local v=hv(g)
  if rl>1 then v=max(v,hv(g2)) end
  tt+=v
 end
 return tt/n
end

-- monte-carlo hold mask search, yields once per mask
function think()
 local f=faces()
 local b,bm=-1,31
 for m=0,31 do
  local v=simul(f,m,({6,12,26})[dif+1])
  if v>b then b=v bm=m end
  yield()
 end
 return bm
end

function cwait(n)
 for i=1,n do yield() end
end

function cputurn()
 cwait(16)
 while rl>0 do
  if not roll() then break end
  while rolling do yield() end
  cwait(10)
  if rl>0 then
   local m=think()
   for i=1,5 do
    if (m>>(i-1))&1==1 then
     dice[i].h=true
     sfx(2)
     cwait(4)
    end
   end
   cwait(10)
  end
 end
 cwait(14)
 sfx(16)
 commit(tp,bestcat(tp,true))
end

function setface(f,n)
 face=f fext=n
end

function dface()
 if fext>0 then return face end
 local d=tot[2]-tot[1]
 if d>25 then return 2 end
 if d<-25 then return 3 end
 return 1
end
-->8
-- ui

function dgame()
 hdr()
 panel(1)
 panel(66)
 totals()
 dicerow()
 if ph=="cpu" then
  sspr((dface()-1)*16,32,16,16,111,88+sin(tk/40))
 end
 ctx()
 dcursor()
 if ph=="com" and pht<=14 then flynum() end
 if ph=="intro" then
  local x=34
  if pht>24 then x-=(pht-24)*12
  elseif pht<8 then x+=(8-pht)*14 end
  fillp(dith[7])
  rrectfill(x-6,52,58,15,3,0x41)
  fillp()
  po("round "..rnum,x,56,10)
 end
end

function hdr()
 fillp(dith[7])
 rectfill(0,0,127,7,0x41)
 fillp()
 spr(44,1,0)
 pr("high roller",10,1,10)
 pr("r"..rnum.."/13",58,1,7)
 prr("hi"..dget(0),126,1,5)
end

function cellx(i,p)
 return (i<=6 and 1 or 66)+(p==1 and 44 or 58)
end

function celly(i)
 return 4+(i<=6 and i or i-6)*9
end

function panel(px)
 fillp(dith[3])
 rectfill(px,9,px+60,75,0x13)
 fillp()
 rect(px,9,px+60,75,4)
 for r=1,7 do
  local i=px==1 and r or r+6
  local y=2+r*9
  if px==1 and r==7 then
   -- bonus row
   pr("bonus",px+3,y+2,5)
   for p=1,2 do
    local x=cellx(1,p)
    if upp[p]>=63 then
     prr("35",x,y+2,10)
    else
     prr(upp[p],x,y+2,5)
    end
   end
  else
   local sel=ph=="tbl" and cr==i
   if sel then
    fillp(pulse>0 and dith[7] or dith[5])
    rectfill(px+1,y,px+59,y+8,0xa3)
    fillp()
   end
   pr(cn[i],px+3,y+2,sel and 7 or sc[1][i] and 5 or 6)
   for p=1,2 do
    local v=sc[p][i]
    local x=cellx(i,p)
    if v then
     if ph=="com" and cp==p and ccat==i and pht<32 then
      v=cnow
     end
     prr(v,x,y+2,v==0 and 8 or 7)
    elseif p==1 and rl<3 and (ph=="tbl" or ph=="roll") and not rolling then
     local q=pv(1,i,faces())
     prr(q,x,y+2,q==0 and 8 or sel and 10 or 5)
    else
     prr("-",x,y+2,5)
    end
   end
  end
 end
end

function totals()
 fillp(dith[6])
 rectfill(1,77,126,85,0x41)
 fillp()
 for p=1,2 do
  if dis[p]<tot[p] then dis[p]+=ceil((tot[p]-dis[p])/8) end
  if dis[p]>tot[p] then dis[p]=tot[p] end
 end
 pr("you",4,79,12)
 pr(dis[1],20,79,10)
 pr("house",56,79,8)
 pr(dis[2],80,79,10)
 spr(58+dface()-1,117,78)
 if tot[1]>tot[2] then
  spr(54,44,78)
 elseif tot[2]>tot[1] then
  spr(54,104,78)
 end
end

function ctx()
 fillp(dith[7])
 rectfill(0,111,127,119,0x41)
 fillp()
 local s="the house is thinking"
 if conf then
  s="score 0 here? ❎yes 🅾️no"
 elseif ph=="roll" then
  s="❎roll("..rl..") 🅾️hold ⬇️score"
  if rl==3 then s="❎ roll the dice to start" end
 elseif ph=="tbl" then
  s="❎score 🅾️dice ⬆️⬇️pick"
 elseif ph=="com" then
  s=cn[ccat].." "..cval
 elseif ph=="intro" then
  s="round "..rnum.." of 13"
 end
 local c=conf and 8 or (tk%180<90 and 7 or 6)
 if nag and nag>0 then
  s=nagm
  c=8
 end
 pr(s,3,113,c)
end

-- score arcing from the dice to its cell
function flynum()
 local t=pht/14
 local x=64+(cellx(ccat,cp)-8-64)*t
 local y=86+(celly(ccat)+2-86)*t-sin(t*0.5)*22
 po(cval,x,y,10)
 if pht%3==0 then
  spark(x+2,y+2)
 end
end
-->8
-- fx

function par(x,y,vx,vy,g,s,n,l,a,c)
 if #ps>pcap then deli(ps,1) end
 add(ps,{x=x,y=y,vx=vx,vy=vy,g=g,s=s,n=n,l=l,ml=l,a=a,c=c,o=flr(rnd(3))})
end

function spark(x,y)
 par(x,y,rnd(1)-0.5,rnd(1)-0.5,0,35,4,10,1)
end

function ring(x,y)
 par(x-4,y-4,0,0,0,50,3,7,1)
end

function puff(x,y)
 par(x-4+rnd(6),y-4,rnd(1)-0.5,-0.2,0,42,1,8,1)
end

function conf3(n)
 for i=1,n do
  par(60+rnd(12),50,rnd(3)-1.5,-rnd(2.4)-0.6,0.12,39,3,60,0,
   ({8,9,10,11,12,15})[1+flr(rnd(6))])
 end
end

function updp()
 for p in all(ps) do
  p.x+=p.vx
  p.y+=p.vy
  p.vy+=p.g
  p.l-=1
  if p.l<=0 then del(ps,p) end
 end
end

function drawp()
 for p in all(ps) do
  local f=p.a==1 and flr((1-p.l/p.ml)*p.n) or (flr(tk/4)+p.o)%p.n
  if p.c then pal(7,p.c) end
  spr(p.s+min(f,p.n-1),p.x,p.y)
  if p.c then pal(7,7) end
 end
end

function pop(s,x,y,c)
 ban={s=s,x=x,y=y,c=c,t=40,b=true}
end

function yahoo(p)
 celeb=90
 fla=8
 shake(3)
 ban={s="yahtzee",x=20,y=48,c=10,t=90,big=true}
 conf3(40)
 sfx(11)
 setface(p==1 and 4 or 2,90)
 if p==1 then yzl+=1 end
end

function bonusfx(p)
 celeb=max(celeb,40)
 fla=3
 conf3(14)
 sfx(8)
 ban={s="+35 bonus",x=32,y=52,c=10,t=45}
end

function upban()
 if ban then
  ban.t-=1
  if ban.b then ban.y-=0.4 end
  if ban.t<=0 then ban=nil end
 end
end

function dban()
 if not ban then return end
 if ban.big then
  local y=min(30,-20+(90-ban.t)*4)
  sspr(0,64,88,16,20,y)
 else
  po(ban.s,ban.x,ban.y,ban.c)
 end
end
-->8
-- title & results

function uptitle()
 tlogo=min(tlogo+3,26)
 tdt+=1
 if tdt>110 then
  tdt=0
  local d=dice[1+flr(rnd(3))]
  d.fly=true d.dl=0 d.vy=-2.6 d.vx=rnd(1)-0.5
  d.nv=1+flr(rnd(6))
  rolling=true
 end
 updice()
 if btnp(4) then togmus() end
 if dget(1)>0 and (btnp(2) or btnp(3)) then
  setdif((dif+(btnp(3) and 1 or 2))%3)
  sfx(4)
 end
 if btnp(5) then
  sfx(21)
  gost("game")
 end
end

function dtitle()
 sspr(0,48,121,16,4,tlogo)
 -- shine, masked to logo pixels
 local sw=flr((tk/2)%300-40)
 for v=0,15 do
  local y=tlogo+v
  for i=0,5 do
   local x=sw+flr(i/2)*3+i%2-v
   local u=x-4
   if u>=0 and u<121 and (x+y)%2==0 then
    local g=sget(u,48+v)
    if g>0 and g!=13 then pset(x,y,7) end
   end
  end
 end
 for i=1,3 do
  local d=dice[i]
  local x=32+(i-1)*22
  d.hx=x d.by=62
  if not d.fly then d.x=x d.y=62 end
 end
 for i=1,3 do
  local d=dice[i]
  local sx=d.fly and 96+(flr(tk/2)%2)*16 or (d.v-1)*16
  fillp(dith[5])
  ovalfill(d.x+1,76,d.x+14,80,0x23)
  fillp()
  sspr(sx,0,16,16,d.x,d.y)
 end
 poc("❎ play",88,tk%40<20 and 10 or 7,1)
 poc("🅾️ music "..(mon and "on" or "off"),98,7,1)
 if dget(1)>0 then
  poc("⬆️⬇️ house: "..({"easy","normal","hard"})[dif+1],108,6,2)
 end
 if dget(0)>0 then
  local b="best "..dget(0).."  won "..dget(2).."/"..dget(1)
  local x=69-flr((#b*4+10)/2)
  po(b,x,118,9)
  spr(55,x-10,117)
  if tk%30==0 then spark(x-6+rnd(50),117) end
 end
end

function saverec()
 dset(1,dget(1)+1)
 if tot[1]>tot[2] then dset(2,dget(2)+1) end
 if tot[1]>dget(0) then
  dset(0,tot[1])
  newrec=true
 end
 dset(3,dget(3)+yzl)
 if upp[1]>dget(7) then dset(7,upp[1]) end
 if tot[1]-tot[2]>dget(4) then dset(4,tot[1]-tot[2]) end
 rest=0
 if newrec then
  conf3(20)
  sfx(20)
 else
  sfx(tot[1]>tot[2] and 19 or 18)
 end
end

function upres()
 rest+=1
 if rest%40==0 and newrec then
  spark(40+rnd(48),34)
 end
 if rest>60 and btnp(5) then
  gost("title")
 end
end

function dres()
 fillp(dith[3])
 rectfill(8,16,119,111,0x13)
 fillp()
 rect(8,16,119,111,4)
 local w=tot[1]>tot[2]
 if tot[1]==tot[2] then
  sspr(88,80,33,16,48,24)
 elseif w then
  sspr(0,80,33,16,48,24)
 else
  sspr(40,80,44,16,42,24)
 end
 sspr(w and 32 or 16,32,16,16,48,40,32,32)
 po("you",24,68,12)
 po(tot[1],24,78,10)
 po("house",76,68,8)
 po(tot[2],76,78,10)
 if newrec then
  spr(55,20,90)
  po("new record!",30,91,9)
 end
 if rest>60 then
  po("❎ play again",30,102,tk%40<20 and 10 or 7)
 end
end
__gfx__
ddd0000000000dddddd0000000000dddddd0000000000dddddd0000000000dddddd0000000000dddddd0000000000dddddd0000000000dddddd0000000000ddd
dd066666666660dddd066666666660dddd066666666660dddd066666666660dddd066666666660dddd066666666660dddd066666666660dddd066666666660dd
d06667777777770dd06667777777770dd06667777777770dd06667777777770dd06667777777770dd06000777700070dd06667777777770dd06666666666660d
06667777777777700660007777777770066000777777777006600077770007700660007777000770066000777700077006666677776667700666667777777770
06677777777777700660007777777770066000777777777006600077770007700660007777000770066000777700077006666666666666600666667777777770
06777000007777700670007777777770067000777777777006700077770007700670007777000770067777777777777006766677776667700666666666666660
0677708e807777700677777777777770067777000777777006777777777777700677770007777770067000777700077006777766677777700677777777777770
06777088807777700677777777777770067777000777777006777777777777700677770007777770067000777700077006666666666666600677777777777770
06777088807777700677777777777770067777000777777006777777777777700677770007777770067000777700077006577566577577700656656656656660
06777000007777700677777777777770067777777777777006777777777777700677777777777770067777777777777006777777777777700677777777777770
06777777777777700677777777000770067777777700077006700077770007700670007777000770067000777700077006666666666666600677777777666770
06777777777777700677777777000770067777777700077006700077770007700670007777000770067000777700077006766677776667700666666666666660
06777777777777f006777777770007f006777777770007f006700077770007f006700077770007f006700077770007f006766677776667f006777777776667f0
d077777777777f0dd077777777777f0dd077777777777f0dd077777777777f0dd077777777777f0dd077777777777f0dd066666666666f0dd077777777777f0d
dd0777777777f0dddd0777777777f0dddd0777777777f0dddd0777777777f0dddd0777777777f0dddd0777777777f0dddd0777777777f0dddd0666666666f0dd
ddd0000000000dddddd0000000000dddddd0000000000dddddd0000000000dddddd0000000000dddddd0000000000dddddd0000000000dddddd0000000000ddd
ddddddddddddddddddd00dddddddddddddddddddddd0dddddd0d0ddddddddddddddddddddddddddddddddddddd000dddddd00dddd00dd00dddd00dddddd00ddd
dd0dddddddddd0dddd0aa0ddddddddddddd0dddddd0a0dddd0a0a0dddd0000ddddd00ddddd000ddddd000dddd0a9a0dddd0000dd0880880ddd0880dddd0000dd
d090dddddddd090dd0a99a0dddd0dddddd070dddd0aaa0dddd0a0dddd077770ddd0770ddd07770ddd06660dd0a9990ddd000000d08888880d088880dd00d00dd
d095dddddddd590d0a9009a0dd070dddd07a70dd0aa7aa0d0a0a0a0dd077770ddd0770dddd000ddd060660dd0a9990dd0000000008888880088888800000000d
00999999999999000a90d09addd0dddddd070dddd0aaa0dddd0a0ddddd0000ddddd00dddddddddddd06660dd0a9990dd00000000d088880dd088880dd00000dd
0555555555555550d00ddd00ddddddddddd0dddddd0a0dddd0a0a0dddddddddddddddddddddddddddd000dddd09990dddd0000dddd0880dddd0880dddd000ddd
0444444444444440ddddddddddddddddddddddddddd0dddddd0d0ddddddddddddddddddddddddddddddddddddd000dddddd00dddddd00dddddd00ddddd000ddd
d00000000000000ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
4444444444444444ddddddddd000000dd0d00d0dddd0dddddddddddddd000ddddd0000dddddddddddd000ddddd000ddddd000ddddd000ddddddddddddddddddd
4999944444444444dd0000dd07dddd700dddddd0dd0a0ddd0d0d0d0dd09990ddd077770ddd000dddd04440ddd04440ddd04440ddd04440dddddddddddddddddd
4944994444444444d077770d0dddddd0dddddddd0d0a0d0d0a0a0a0d0a9a90dd07888870d07770ddd00000ddd00000ddd00000ddd00000dddddddddddddddddd
4949449444444444d07dd70d0dddddd0ddddddddd0aaa0dd0aaaaa0dd09990dd07888870d07770dd0ffff0dd0ffff0dd0ffff0dd0ffff0dddddddddddddddddd
4494444944444444d07dd70d0dddddd0dddddddddd0a0ddd0a9a9a0dd00000dd078888700077700d0f0f00dd0f0f00dd0f00f0dd0f0f0f0ddddddddddddddddd
4444444494444444d077770d0dddddd0ddddddddd0a0a0dd0999990dd08d80dd07888870d07770dd0ffff0dd0ffff0dd0f0f00dd0fffff0ddddddddddddddddd
4444444449444444dd0000dd07dddd700dddddd0d0ddd0dd0000000dd08d80ddd077770ddd070ddd0f000f0d0f00ff0d0f000f0d0f0000fddddddddddddddddd
4444444444944444ddddddddd000000dd0d00d0ddddddddddddddddddd0dd0dddd0000ddddd0ddddd00000ddd00000ddd00000ddd00000dddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddd000000dddddddddd000000dddddddddd000000dddddddddd000000ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddd04444440dddddddd04444440dddddddd04444440dddddddd04444440dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddd04444440dddddddd04444440dddddddd04444440dddddddd04444440dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dd044444444440dddd044444444440dddd044444444440dddd044444444440dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dd088888888800dddd088888888800dddd088888888800dddd088888888800dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dd000000000000dddd000000000000dddd000000000000dddd000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddd0ffffff0dddddddd0ffffff0dddddddd00fffff00ddddddd7777f7777ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddd0ffffffff0dddddd0000ff0000dddddd0ffffffff0dddddd07007f7007ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddd0f00ff00f0dddddd0f00ff00f0dddddd0ffffffffcdddddd07007f7007ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddd0f00ff00f0dddddd0ffffffff0dddddd0f00ff00fcdddddd07777f7777ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddd0ffffffff0dddddd0fff000ff0dddddd0f00ff00f0dddddd0ffffffff0ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddd0f0000f0dddddddd0f0ffff0dddddddd0ffffff0dddddddd0f0000f0dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddd000000dddddddddd000000dddddddddd000000dddddddddd008800ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddd0880dddddddddddd0880ddddddddddd00880dddddddddddd0000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddd000000dddddddddd000000dddddddddd000000dddddddddd000000ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000dddd000000000000000d00000000d0000dddd0000dddddddddd0000000000ddd00000000d0000ddddddd0000ddddddd000000000000000000000dddddddd
0770dddd077077777777770d07777770d0770dddd0770dddddddddd0777777770ddd07777770d0770ddddddd0770ddddddd077777777770777777770dddddddd
0aa0dddd0aa0aaaaaaaaaa000aaaaaa000aa0dddd0aa0dddddddddd0aaaaaaaa00000aaaaaa000aa0ddddddd0aa0ddddddd0aaaaaaaaaa0aaaaaaaa000dddddd
0aa0dddd0aa00000aa00000aa000000aa0aa0dddd0aa0dddddddddd0aa000000aa0aa000000aa0aa0ddddddd0aa0ddddddd0aa000000000aa000000aa0dddddd
0aa0dddd0aa0ddd0aa0ddd0aa0dddd0aa0aa0dddd0aa0dddddddddd0aa0dddd0aa0aa0dddd0aa0aa0ddddddd0aa0ddddddd0aa0ddddddd0aa0dddd0aa0dddddd
0990dddd0990ddd0990ddd0990dddd0000990dddd0990dddddddddd0990dddd0990990dddd0990990ddddddd0990ddddddd0990ddddddd0990dddd0990dddddd
099000000990ddd0990ddd0990dd00000099000000990dddddddddd099000000990990dddd0990990ddddddd0990ddddddd0990000000d099000000990dddddd
099999999990ddd0990ddd0990dd09999099999999990dddddddddd099999999000990dddd0990990ddddddd0990ddddddd0999999990d099999999000dddddd
099999999990ddd0990ddd0990dd09999099999999990dddddddddd0999999990d0990dddd0990990ddddddd0990ddddddd0999999990d0999999990dddddddd
099000000990ddd0990ddd0990dd00099099000000990dddddddddd0990000990d0990dddd0990990ddddddd0990ddddddd0990000000d0990000990dddddddd
0440dddd0440ddd0440ddd0440dddd0440440dddd0440dddddddddd0440dd044000440dddd0440440ddddddd0440ddddddd0440ddddddd0440dd044000dddddd
0440dddd0440ddd0440ddd0440dddd0440440dddd0440dddddddddd0440dd000440440dddd0440440ddddddd0440ddddddd0440ddddddd0440dd000440dddddd
0440dddd04400000440000044000000440440dddd0440dddddddddd0440dddd044044000000440440000000004400000000044000000000440dddd0440dddddd
0440dddd04404444444444000444444000440dddd0440dddddddddd0440dddd044000444444000444444444404444444444044444444440440dddd0440dddddd
0440dddd044044444444440d04444440d0440dddd0440dddddddddd0440dddd0440d04444440d0444444444404444444444044444444440440dddd0440dddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000dddd0000d00000000d0000dddd000000000000000000000000000000000000000000000000ddd0000ddddddddddddddddddddddddddddddddddddddddddd
0770dddd0770d07777770d0770dddd077077777777770777777777707777777777077777777770ddd0770ddddddddddddddddddddddddddddddddddddddddddd
0ff0dddd0ff000ffffff000ff0dddd0ff0ffffffffff0ffffffffff0ffffffffff0ffffffffff0ddd0ff0ddddddddddddddddddddddddddddddddddddddddddd
0ff0dddd0ff0ff000000ff0ff0dddd0ff00000ff0000000000000ff0ff000000000ff000000000ddd0ff0ddddddddddddddddddddddddddddddddddddddddddd
0ee000000ee0ee0dddd0ee0ee0dddd0ee0ddd0ee0ddddddddd000ee0ee0ddddddd0ee0ddddddddddd0ee0ddddddddddddddddddddddddddddddddddddddddddd
000ee00ee000ee0dddd0ee0ee0dddd0ee0ddd0ee0ddddddddd0ee000ee0ddddddd0ee0ddddddddddd0ee0ddddddddddddddddddddddddddddddddddddddddddd
dd08800880d08800000088088000000880ddd0880ddddddd000880d0880000000d0880000000ddddd0880ddddddddddddddddddddddddddddddddddddddddddd
dd00088000d08888888888088888888880ddd0880ddddddd088000d0888888880d0888888880ddddd0880ddddddddddddddddddddddddddddddddddddddddddd
dddd0880ddd08888888888088888888880ddd0880ddddd000880ddd0888888880d0888888880ddddd0880ddddddddddddddddddddddddddddddddddddddddddd
dddd0880ddd08800000088088000000880ddd0880ddddd088000ddd0880000000d0880000000ddddd0880ddddddddddddddddddddddddddddddddddddddddddd
dddd0220ddd0220dddd0220220dddd0220ddd0220ddd000220ddddd0220ddddddd0220ddddddddddd0220ddddddddddddddddddddddddddddddddddddddddddd
dddd0220ddd0220dddd0220220dddd0220ddd0220ddd022000ddddd0220ddddddd0220ddddddddddd0000ddddddddddddddddddddddddddddddddddddddddddd
dddd0220ddd0220dddd0220220dddd0220ddd0220ddd0220000000002200000000022000000000ddd0000ddddddddddddddddddddddddddddddddddddddddddd
dddd0220ddd0220dddd0220220dddd0220ddd0220ddd0222222222202222222222022222222220ddd0220ddddddddddddddddddddddddddddddddddddddddddd
dddd0220ddd0220dddd0220220dddd0220ddd0220ddd0222222222202222222222022222222220ddd0220ddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000dddd000000000000000000dddd0000dddddd0000ddddddddd00000000ddd000000000000000000000ddd0000000000000000000000000000000000dddddd
0770dddd077077777777770770dddd0770dddddd0770ddddddddd07777770ddd077777777077777777770ddd0777777777707777777777077777777770dddddd
0aa0dddd0aa0aaaaaaaaaa0aa000dd0aa0dddddd0ff0ddddddd000ffffff00000ffffffff0ffffffffff0ddd0aaaaaaaaaa0aaaaaaaaaa0aaaaaaaaaa0dddddd
0aa0dddd0aa00000aa00000aaaa0dd0aa0dddddd0ff0ddddddd0ff000000ff0ff000000000ff000000000ddd00000aa000000000aa00000aa000000000dddddd
0aa0dddd0aa0ddd0aa0ddd0aaaa0dd0aa0dddddd0ee0ddddddd0ee0dddd0ee0ee0ddddddd0ee0ddddddddddddddd0aa0ddddddd0aa0ddd0aa0dddddddddddddd
0990dddd0990ddd0990ddd099990dd0990dddddd0ee0ddddddd0ee0dddd0ee0ee0ddddddd0ee0ddddddddddddddd0990ddddddd0990ddd0990dddddddddddddd
099000000990ddd0990ddd099990000990dddddd0880ddddddd0880dddd0880880000000d0880000000ddddddddd0990ddddddd0990ddd0990000000dddddddd
099009900990ddd0990ddd099009900990dddddd0880ddddddd0880dddd0880008888880d0888888880ddddddddd0990ddddddd0990ddd0999999990dddddddd
099009900990ddd0990ddd099009900990dddddd0880ddddddd0880dddd0880d0888888000888888880ddddddddd0990ddddddd0990ddd0999999990dddddddd
099009900990ddd0990ddd099000099990dddddd0880ddddddd0880dddd0880d0000000880880000000ddddddddd0990ddddddd0990ddd0990000000dddddddd
044004400440ddd0440ddd0440dd044440dddddd0220ddddddd0220dddd0220ddddddd0220220ddddddddddddddd0440ddddddd0440ddd0440dddddddddddddd
044440044440ddd0440ddd0440dd044440dddddd0220ddddddd0220dddd0220ddddddd0220220ddddddddddddddd0440ddddddd0440ddd0440dddddddddddddd
04444004444000004400000440dd044440dddddd022000000000220000002200000000022022000000000ddddddd0440ddd00000440000044000000000dddddd
04400000044044444444440440dd000440dddddd022222222220002222220002222222200022222222220ddddddd0440ddd04444444444044444444440dddddd
0440dddd044044444444440440dddd0440dddddd022222222220d02222220d0222222220d022222222220ddddddd0440ddd04444444444044444444440dddddd
b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333
333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b
13b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b3
3b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b33
b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333
333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b
31b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b1
3b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b333b333b331b333b313b333b133b33
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
__label__
44444444444444443111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131114444444444444444
49999444444444441111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111114444444444499994
49449944444444441131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111314444444444994494
49494494444444441111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111114444444449449494
44944449444444443111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131114444444494444944
44444444944444441131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111314444444944444444
44444444494444443111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131114444449444444444
44444444449444441131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111314444494444444444
31113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111
11111131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311111
11311111313111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131111131111131
11111131111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
31113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111
11111131111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
11311111313111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131111131111131
11111131111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
31113111311131113131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313111311131113111
11111131111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
11311111313111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131111131111131
11111131111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
31113111311131113131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313111311131113111
11111131111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
11311111313111313131313131313131313131303131313131313131313131313131313131313131313131313131313131313131313131313131111131111131
111111311113131313131313131313131313130a0313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
31113111311131113131313131313131313130aaa031313131313131313131313131313131313131313131313131313131313131313131313111311131113111
1111113111131313131313131313131313130aa7aa03131313131313131313131313131313131313131313131313131313131313131313131313133111311111
11311111313111313131313131313131313130aaa031313131313131313131313131313101313131303131313131313131313131313131313131111131111131
111100001113000000000000000300000000100a03131000031013131310000000000310700000000a0003131313000013131310000000000000000000001111
311107703111077077777777770107777770307001313077010701313130777777770107a7077770aaa001313131077031313130777777777707777777703111
11110aa011130aa0aaaaaaaaaa000aaaaaa000aa031310aa031013131310aaaaaaaa000070aaaa0aa7aa031313130aa013131310aaaaaaaaaa0aaaaaaaa00111
11310aa031310aa00000aa00000aa000000aa0aa013130aa013131313130aa000000aa0a00000000aaa0013131310aa031313130aa000000000aa000000aa131
11110aa011130aa01310aa03130aa013130aa0aa031310aa031313131310aa031310aa0aa013130a0a0a031313130aa013131310aa031313130aa031110aa111
31110990311109903130990131099031310000990131309901313131313099013130990990313109909901313131099031313130990131313109901131099111
11110990000009901310990313009013000000990000009903131313131099000000990990131309909903131313099013131310990000000309900000099111
113109999999999031309901310a0a01099990999999999901313131313099999999000990313109909901313131099031313130999999990109999999900131
1111099999999990131099031300a013099990999999999903131313131099999999030990131309909903131313099013131310999999990309999999901111
31110990000009903130990130a0a0a0000990990000009901313131313099000099010990313109909901313131099031313130990000000109900009903111
1111044011130440131044031300a013130440440313104403131313131044031044000440131304404403131310a04013131310440313131304403104400111
113104403131044031304401310a0a0131044044013130440131313131304401300044044031310440440131310aaa0031313130440131313104401100044131
111104401113044000004400000040000004404403131044031313131310440313104404400000044044000000aa7aa000000000440000000004403111044111
3111044031110440444444444400044444400044013130440131313131304401313044000444444000444444440aaa0444444440444444444404401131044111
11110440111304404444444444030444444010440313104403131313131044031310440304444440104444444440a04444444440444444444404403111044111
11311111313111313131313131313131313131313131313031313131313131313131013131313131313131313131013131313131313131313131111131111131
11111131111313131313131313131313131313131313130703131313131313131310a01313131313131313131313131313131313131313131313133111311111
3111311131113111313131313131313131313131313131303131313131313131310aaa0131313131313131313131313131313131313131313111311131113111
111111311113131313131313131313131313131313131313131313131313131310aa7aa013131313131313131303131313131313131313131313133111311111
1131111131311131313131313131313131313131313131313131313131313131310aaa0131313131313131313070313131313131313131313131111131111131
11111131111313131313131313131313131313131313131313131313131313131310a01313131313131313131303131313131313131313131313133111311111
31113111311131113131313131313131313131313131313131313131313131313131013131313131313131313131313131313131313131313111311131113111
11111131111313131313131313131313131313131313131313131313131313131313131010131313131313131313131313131313131313131313133111311111
11311111313111313131313131313131313131313131313131313131313131313131310a0a013131313131313131313131313131313131313131111131111131
111111311113131313131313131313030313131313131313131313131313131313131310a0131313131313131313131313101013131313131313133111311111
311131113111311131313131313130a0a0313131313131313131313131313131313130a0a0a031313131313131313131310a0a01313131313111311131113111
1111113111131313131313131313130a0313131313131313131313131313131310131310a013131313131313131313131310a013131313131313133111311111
11311111313111313131313131310a0a0a0131313131313131313131313131310a01310a0a013131313131313131313130a0a0a0313131313131111131111131
1111113111131313131313131313130a03131313131313131313130313131310aaa013101013131313131313131313131310a013131313131313133111311111
311131113111311131313131313130a0a031313131313131313130703131310aa7aa0131070131313131313131313131310a0a01313131313111311131113111
111111311113131313131313131313030313131313131313131307a703131310aaa0131310131313101313131313131313101013131313131313133111311111
11311111313111313131313131313131313131313131313131313070313131310a013131313131310a0131313131313131313131313131313131111131111131
11111131111313131313131313131313131313131313131313131303131313131010131313131310aaa013131313131313130313131313131313133111311111
31113111311131113131313131313131313131313131313131313070313131310a0001313131310aa7aa01313131313131307031313131313111311131113111
11111131111313131313131313131313131313131313131313131303131313131007031313131310aaa01313131313131307a703131313131313133111311111
1131111131311131313131313131313131300000000001313131313130000000a0a0a031313131300a0000000131313131307031313131313131111131111131
111111311113131313131313131313131306666666666013131313130666666660a0131313131306606666666013131313130313131313131313133111311111
31113111311131113131313131313131306000777700070131313130666777770a0a013131313060007777000701313131313131313131313111311131113111
11111131111313131313131313131313066000777700077013131306600077770000701313130660007777000770131313131313131313131313133111311111
11311111313111313131313131313131066000777700077031313106600077770007703131310660007777000770313131313131313131313131111131111131
11111131111313131313131313131313067777777777777013131306700077770007701313130677777777777770131313131313131313131313133111311111
31113111311131113131313131313131067000777700077031313006777700077777703131310670007777000770313131313131313131313111311131113111
11111131111313131313131313131313067000777700077013130706777700077777701313130670007777000770131313131313131313131313133111311111
11311111313111313131313131313131067000777700077031307a70777700077777703131310670007777000770313131313131313131313131111131111131
11111131111313131313131313131313067777777777777013130706777777777777701313130677777777777770131313131313131313131313133111311111
31113111311131113131313131313131067000777700077031313006700077770007703131010670007777000770313131313131313131313111311131113111
11111131111313131313131313131313067000777700077013131306700077770007701310a00670007777000770131313131313131313131313133111311111
1131111131311131313131313131313106700077770007f031313106700077770007f0310aaa06700077770007f0313131313131313131313131111131111131
111111311113131313131313131313131077777777777f031313131077777777777f0310aa7aa077777077777f03131313131313131313131313133111311111
31113111311131113131313131313131310777770707f031313130300777777777f031310aaa0107770a0777f031313131313131313131313111311131113111
1111113111131313131313131313131313200000a0a0031313130a0a000000000003131310a0132000aaa0000313131313131313131313131313133111311111
11311111313111313131313131313131323232320a023231313130a03232323232323131310132320aa7aa023231313131313131313131313131111131111131
111111311113131313131313131313131323230a0a0a03131310a0a000232323232313131313132320aaa0232313131313131313131313131313133111311111
31113111311131113131313131313131313132320a023131313130a0a03232323231313131313131320a02323131313131313131313131313111311131113111
1111113111131313131313131313131313131310a0a0131313130a0aaa0313131013131313131313131013131313131313131313131313131313133111311111
113111113131113131313131313131313131313101013131313130aa7aa031310701313131313131313131313131313131313131313130313131111131111131
1111113111131313131313131313131313131313131313131313130aaa0313131013131313131313131313131313131313131313131307031313133111311111
31113111311131113131313131313131313131313131313131313130a0313131313131313131313131313131313131313131313131307a703111311131113111
11111131111313131313131313131313131313131313131313131313031313131313131313131313131313131313131313131313131307031313133111311111
11311111313111313131313131313131313131313131313131313131313131313131313101313131313131313131313131313131313130313131111131111131
11111131111313131313131313131313131313131300000003131000000010000000001070131313131313131313131313131313131313131313133111311111
311131113111311131313131313131313131313130077777003130777070307770707007a7013131313131313131313131313131313131313111311131113111
11111131111313131313131313131313131313131077070770131070707010707070701070131313131313131313131313131313131313131313133111311111
11311111313111313131313131313131313131313077707070313077707030777077703101313131313131313131313131313131313131313131111131111131
11111131111313131313131313131313131313131077070a0a031070007000707000701313131313131313131313131313131313131313031313133111311111
311131113111311131313131313131313131313130077770a0313070307770707077703131313131313131313131313131313131313130703111311131113111
1111113111131313131313131313131313131313130000a0a0a01000100000000000001313031313131313131313131313131313131313031313133111311111
113111113131113131313131313131313131313131313130a0313131313131313131313130a03131313131313131313131313131313131313131111131111131
11111131111313131313131313131313131313131313130a0a03131313131313131313130aaa0313131313131313131313131313131313131313133111311111
311131113111311131313131313131313131313131313130303131313131313131313130aa7aa031313131313131313131313131313131313111311131113111
1111113111131313131313131313131313000000031310000000000000000000001313000aaa0313131313131313131313131313131313131313133111311111
11311111313111313131313131313131300777770031307770707007707770077031300770a00031313131313131313131313131313131313131111131111131
11111131111313131313131313131313107700077013107770707070000700700013107070007013131313131313131313130313131313131313133111311111
3111311131113111313131313131313130770707703130707070707770070070313130707070703131313131313131313100a031313131313111311131113111
1111113111131313131313131313131310770007701307007070700070070070001310707070701313131313131313131070aa03131313131313133111311111
113111113131113131313131313031313007777700307a7070077077007770077031307700707031313131313131313107a70aa0313131313131111131111131
111111311113131313131313130a031313000000031307000000000000000000001310000000001313131313131313131070aa03131313131313133111311111
31113111311131113131313130aaa03131313131313130313131313131313131313131313131313131313131313131313100a031313131313111311131113111
1111113111131313131313130aa7aa03131313131313131313131313131313131313131313131313131313131313131313130313131313131313133111311111
11311111313111313131313130aaa031313131313131313131313131313131313131313131313131313131313131313131313131313131313131111131111131
111111311113131313131313130a0313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
31113111311131113131313131303131313131313131313131313131313131313131313131313131313131313131313131313131313131313111311131113111
11111131111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
11311111313111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131111131111131
11111131111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
31113111311131113131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313111311131113111
11111131111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
11311111313111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131111131111131
11111131111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
31113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111
11111131111313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313133111311111
11311111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131111131
11111131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311111
44444444449444443111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131114444494444444444
44444444494444441131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111314444449444444444
44444444944444443111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131114444444944444444
44944449444444441111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111114444444494444944
49494494444444443111311131113111311131113111311131113111311131113111311131113111311131113111311131113111311131114444444449449494
49449944444444441111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111114444444444994494
49999444444444441131113111311131113111311131113111311131113111311131113111311131113111311131113111311131113111314444444444499994
44444444444444441111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111114444444444444444

__sfx__
0103000a186301d62022620196301e620236201a6301f620246201b63020620256200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001f653186330c6230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000246401f620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001f63024625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200003033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400003055037550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001c25318243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200003443000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0106000024560285602b5603056034570305650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500002b55030555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500003056034560375650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000024560285602b5603056034570375703c57500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800003047630466304550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300003063032630346200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000247312b725000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01050000285502d555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400003064520635106250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00002d55029550285502156500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00003056034560375603c57500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000304603446037460394603c475000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00002456624566305750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002d33000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400002d4302d4302d4302d43024430244302443024430284302843028430284302b4302b4302b4302b43000000000002643026430294302943029430294302d4302d4302d4302d43029430294302943029430
011400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0114000029430294302943029430244302443024430000002d4302d4302d4302d4302d4302d4302d4302d430284302843028430284302c4302c4302c4302c4302f4302f4302f4302f43026430264302643026430
011400001125011250112501125011250112501125011250182501825018250182501525015250152501525010250102501025010250172501725017250172501425014250142501425017250172501725017250
01120000152501525015250152501025010250102501025018250182501825018250102501025010250102501a2501a2501a2501a2501a2501a2501a2501a2501525015250152501525011250112501125011250
0112000013250132501325013250172501725017250172501a2501a2501a2501a2501125011250112501125018250182501825018250132501325013250132501725017250172501725013250132501325013250
011200001125011250112501125011250112501125011250182501825018250182501525015250152501525010250102501025010250172501725017250172501425014250142501425017250172501725017250
01120000152501525015250152501025010250102501025013250132501325013250102501025010250102501025010250102501025014250142501425014250172501725017250172501a2501a2501a2501a250
011200002d4302d4302d43000000284302843028430000002443024430244300000028430284302843000000264302643026430264302d4302d4302d430000002943029430294302943029430294302943029430
011200002b4302b4302b4302b430264302643026430000002f4302f4302f4302f4302f4302f4302f4302f43000000000002443024430284302843028430284302b4302b4302b4302b43028430284302843028430
01120000000000000029430294302d4302d4302d4302d430244302443024430244302d4302d4302d4302d430284302843028430284302c4302c4302c4302c4302f4302f4302f4302f43026430264302643026430
011200002d4302d4302d4302d43024430244302443024430284302843028430284302b4302b4302b4302b430284302843028430000002f4302f4302f430000002c4302c4302c430000002f4302f4302f43000000
0112000021020000000000000000000000000000000000001c0200000018020000000000000000000000000000000000001d02000000000000000000000000001a02000000000000000021020000000000000000
0112000000000000002302000000000000000000000000001f0200000000000000001a02000000000000000018020000000000000000000000000000000000001f020000001c0200000000000000000000000000
011200001d02000000000000000000000000000000000000180200000021020000000000000000000000000000000000002002000000000000000000000000001c02000000000000000023020000000000000000
011200000000000000180200000000000000000000000000210200000000000000001c0200000000000000001c02000000230200000000000000000000000000200200000000000000001a020000000000000000
011200003454034540345403454034540345403454034540305403054030540305403254032540325403254035540355403554035540355403554035540355403454034540345403454032540325403254032540
0112000032540325403254032540345403454032540325402f5402f5402f5402f5402f5402f5402f5402f54030540305403054030540305403054034540345403754037540375403754037540375403754037540
01120000000000000000000000002d5402d5402d5402d54030540305403054030540305403054030540305402f5402f5402f5402f5402c5402c5402c5402c5403454034540345403454034540345400000000000
011200003454034540345403454034540345403254032540305403054030540305402f5402f5402f5402f5402d5402d5402d5402d5402d5402d5402d5402d5402f5402f5402f5402f54034540345403454034540
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000030560305603056030560345603456037560375603c5603c5603c5603c5603c5603c5603c5603c5603b5603b5603b5603b560375603756037560375603456034560345603456037560375603756037560
0110000018250182501825018250102501025010250102501325013250132501325017250172501725017250132501325013250132501a2501a2501a2501a250172501725017250172501a2501a2501a2501a250
011200002d5502d5502d5502d55034550345503455034550305503055030550305502d5502d5502d5502d5502c5502c5502c5502c550285502855028550285502d5502d5502d5502d5502d5502d5502d5502d550
011200001525015250152501525010250102501025010250182501825018250182501025010250102501025010250102501025010250102501025010250102501725017250172501725014250142501425014250
0112000028030280302803028030240302403024030240302d0302d0302d0302d0302d0302d0302d0302d03026030260302603026030260302603026030260302d0302d0302d0302d03024030240302403024030
0112000000000000002f0302f0302f0302f0302b0302b0302b0302b030260302603026030260302603026030280302803028030280302b0302b0302b0302b0302f0302f0302f0302f0302b0302b0302b0302b030
01120000290302903029030290302903029030290302903024030240302403024030280302803028030280302f0302f0302f0302f0302c0302c0302c0302c0302803028030280302803028030280302803028030
0112000024030240302403024030280302803028030280302b0302b0302b0302b0302803028030280302803000000000002c0302c0302c0302c030280302803028030280302f0302f0302f0302f0302f0302f030
011200003954039540395403954039540395403954039540375403754037540375403454034540345403454035540355403554035540355403554035540355403554035540355403554032540325403254032540
011200003254032540325403254032540325403254032540000000000000000000002f5402f5402f5402f54030540305403054030540305403054030540305403454034540345403454034540345403454034540
011200003054030540305403054030540305402d5402d54035540355403554035540355403554035540355402f5402f5402f5402f5402f5402f5402f5402f5402c5402c5402c5402c54034540345403454034540
0112000034540345403454034540305403054030540305402f5402f5402f5402f5402f5402f5402f5402f5402c5402c5402c5402c5402c5402c5402c5402c5402d5402d5402d5402d5402d5402d5402d5402d540
011200002d4502d4502d4502d45030450304503045030450344503445034450344503445034450324503245032450324503245032450354503545035450354503945039450394503945039450394503945039450
011200003745037450374503745037450374503745037450324503245032450324502f4502f4502f4502f45030450304503045030450344503445034450344503745037450374503745037450374503745037450
011200002d4502d4502d4502d4503545035450354503545035450354503545035450344503445034450344502c4502c4502c4502c4502f4502f4502f4502f4503445034450344503445034450344503445034450
011200002d4502d4502f4502f450304503045030450304503445034450344503445034450344503445034450324503245032450324502f4502f4502f4502f4502c4502c4502c4502c4502d4502d4502d4502d450
0114000000000000000000000000000000000000000000002d5402d5402d5402d5403054030540305403054032540325403254032540325403254032540325403554035540355403554035540355403554035540
01140000305403054030540305402d5402d5402d5402d54029540295402954029540295402954029540295402f5402f5402f5402f5402f5402f5402f5402f5403454034540345403454034540345403454034540
__music__
01 19183e41
02 1b1a3f41
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 1c202428
00 1d212529
00 1e22262a
00 1f23272b
00 1c324136
00 1d334137
00 1e342638
02 1f352739
00 41424344
00 41424344
00 41424344
00 41424344
01 1c20243a
00 1d21253b
00 1e22263c
02 1f23273d
00 2f2e4141
04 2f2e4141
00 41424344
00 41424344
00 31304141
04 31304141

