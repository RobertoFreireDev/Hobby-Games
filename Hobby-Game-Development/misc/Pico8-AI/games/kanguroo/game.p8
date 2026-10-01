pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- kanguroo
-- by roberto freire

-- <levels>
lvls={
-- 1: hop 2 tiles, water sinks you, push one crate
"~~~~~~~~~~"..
"~~~~~~~~~~"..
"~~~~~~~~~~"..
"~........~"..
"~........~"..
"~...b.op.~"..
"~........~"..
"~~~~~~~~~~"..
"~~~~~~~~~~"..
"~~~~~~~~~~",
-- 2: a wall 2 away shortens the hop to 1
"~~~~~~~~~~"..
"~~~~~~~~~~"..
"~......p.~"..
"~........~"..
"~####....~"..
"~.bo.....~"..
"~........~"..
"~........~"..
"~~~~~~~~~~"..
"~~~~~~~~~~",
-- 3: a crate shortens the hop too
"~~~~~~~~~~"..
"~~~~~~~~~~"..
"~......p.~"..
"~........~"..
"~B.......~"..
"~.bo.....~"..
"~........~"..
"~........~"..
"~~~~~~~~~~"..
"~~~~~~~~~~",
-- 4
"~~~~~~~~~~"..
"~........~"..
"~.#.#.#.#~"..
"~........~"..
"~...o.o..~"..
"~........~"..
"~#.#.#.#.~"..
"~.p.b.b..~"..
"~..o...b.~"..
"~~~~~~~~~~",
-- 5
"~~~~~~~~~~"..
"~........~"..
"~pbo.bo..~"..
"~........~"..
"~###.####~"..
"~........~"..
"~..o..o..~"..
"~.b...b..~"..
"~........~"..
"~~~~~~~~~~",
-- 6
"~~~~~~~~~~"..
"~........~"..
"~...ob...~"..
"~..b...b.~"..
"~~~.~~~p~~"..
"~........~"..
"~..o..o..~"..
"~........~"..
"~........~"..
"~~~~~~~~~~",
-- 7
"~~~~~~~~~~"..
"~........~"..
"~.##..##.~"..
"~.bo..ob.~"..
"~.##..##.~"..
"~.p......~"..
"~.##..##.~"..
"~.bo..ob.~"..
"~.##..##.~"..
"~~~~~~~~~~",
-- 8
"~~~~~~~~~~"..
"~..~..~..~"..
"~.o.pb.o.~"..
"~....b...~"..
"~~b.##..~~"..
"~..b##.b.~"..
"~........~"..
"~.o.o..o.~"..
"~..~..~..~"..
"~~~~~~~~~~",
-- 9
"~~~~~~~~~~"..
"~...#....~"..
"~..o...b.~"..
"~........~"..
"~#b....#.~"..
"~...o....~"..
"~.b......~"..
"~p#....o.~"..
"~...#....~"..
"~~~~~~~~~~",
-- 10
"~~~~~~~~~~"..
"~..~~~~..~"..
"~p.~~~~..~"..
"~o.b.b..o~"..
"~......b.~"..
"~........~"..
"~o.....bo~"..
"~..~~~~..~"..
"~..~~~~..~"..
"~~~~~~~~~~",
-- 11
"~~~~~~~~~~"..
"~........~"..
"~..o.....~"..
"~......b.~"..
"~.....o..~"..
"~......b.~"..
"~..o.....~"..
"~p.....b.~"..
"~........~"..
"~~~~~~~~~~",
-- 12
"~~~~~~~~~~"..
"~........~"..
"~.b####..~"..
"~o.......~"..
"~b...####~"..
"~......o.~"..
"~####..b.~"..
"~.o......~"..
"~.p####..~"..
"~~~~~~~~~~",
-- 13
"~~~~~~~~~~"..
"~........~"..
"~..o.~.bo~"..
"~....~...~"..
"~..o.~...~"..
"~..b.~...~"..
"~.bo.~..o~"..
"~p.b.~.b.~"..
"~........~"..
"~~~~~~~~~~",
-- 14
"~~~~~~~~~~"..
"~........~"..
"~.~.~.~b.~"..
"~........~"..
"~..o..o..~"..
"~.b~.~.~.~"..
"~........~"..
"~....ob..~"..
"~p.......~"..
"~~~~~~~~~~",
-- 15
"~~~~~~~~~~"..
"~........~"..
"~..b.....~"..
"~.bo#.op.~"..
"~##.##.##~"..
"~..b.....~"..
"~..o#.o..~"..
"~.b......~"..
"~........~"..
"~~~~~~~~~~",
-- 16
"~~~~~~~~~~"..
"~..~.....~"..
"~...~....~"..
"~o...~...~"..
"~.....~..~"..
"~..o.p.~.~"..
"~...o...~~"..
"~..b.bbb.~"..
"~...o....~"..
"~~~~~~~~~~",
-- 17
"~~~~~~~~~~"..
"~...o..p.~"..
"~.b.b.b..~"..
"~..#.bo#.~"..
"~~~~.~~~~~"..
"~....b...~"..
"~..o..o..~"..
"~........~"..
"~...o....~"..
"~~~~~~~~~~",
-- 18
"~~~~~~~~~~"..
"~p.......~"..
"~.boooo..~"..
"~........~"..
"~.bb##...~"..
"~........~"..
"~..#..#..~"..
"~......b.~"..
"~........~"..
"~~~~~~~~~~",
-- 19
"~~~~~~~~~~"..
"~......p.~"..
"~.b#####.~"..
"~..#o.o#.~"..
"~.b#...#.~"..
"~..#ooo#.~"..
"~.bbb..#.~"..
"~........~"..
"~........~"..
"~~~~~~~~~~"}
-- </levels>

dxs={-1,1,0,0}
dys={0,0,-1,1}

function _init()
 cartdata("kanguroo_rf")
 pt={}
 sc="intro"
 tk=0
 lv=1
 -- open the picker on the first level still to clear
 cd=0
 while cd<#lvls-1 and dget(cd)==1 do cd+=1 end
 music(0)
 intromenu()
end

function _update60()
 tk+=1
 upt()
 if bk then
  bk=nil
  music(0)
  intromenu()
 end
 if sc=="intro" then
  upintro()
 elseif sc=="tut" then
  if btnp(4) or btnp(5) then
   bleep(18)
   sc="intro"
  end
 else
  upgame()
 end
end

function _draw()
 if sc=="intro" then
  dwintro()
 elseif sc=="tut" then
  dwtut()
 else
  dwgame()
 end
end

-- two variants per interaction so repeats don't sound
-- mechanical. channels 0-1 belong to the music bed, so
-- game sound always goes to 2 (and 3 for impacts, which
-- overlap the hop that caused them).
function bleep(n,c)
 sfx(n+flr(rnd(2)),c or 2)
end

-- 12x12 tile blit
function dt(id,x,y,fx)
 sspr(id%10*12,id\10*12,12,12,x,y,12,12,fx)
end

-- deterministic sand decoration.
-- 0 means plain sand: the caller skips it, so most
-- tiles cost no draw call at all. orange is kept out
-- of the desert so it only ever means box or goal.
function dec(x,y)
 local r=(x*7+y*11)%13
 if r==0 then return 2 end
 if r==5 then return 9 end
 return 0
end

function arc(p,h)
 return -sin(p*0.5)*h
end

-->8
-- particles

function upt()
 for p in all(pt) do
  p.x+=p.vx
  p.y+=p.vy
  p.vy+=0.02
  p.l-=1
  if p.l<=0 then del(pt,p) end
 end
end

function puff(cx,cy)
 for i=1,4 do
  add(pt,{
   x=10+cx*12+rnd(5)-2,
   y=13+cy*12,
   vx=rnd(1)-0.5,
   vy=-rnd(0.4),
   l=10+rnd(8)})
 end
end

function dwpt()
 for p in all(pt) do
  pset(p.x,p.y,p.l>7 and 7 or 4)
 end
end

-->8
-- intro & level picker

-- the picker lives on the title screen: ⬅️➡️ wrap through
-- every level, ❎ starts the one shown if it is unlocked.
function upintro()
 local c=cd
 if btnp(0) then cd=(cd-1)%#lvls end
 if btnp(1) then cd=(cd+1)%#lvls end
 if cd!=c then bleep(16) end
 if btnp(5) then
  if unl(cd) then
   bleep(18)
   lv=cd+1
   startlev()
  else
   bleep(6)
  end
 elseif btnp(4) then
  bleep(18)
  sc="tut"
 end
end

function dwintro()
 cls(13)
 circfill(98,42,13,9)
 rectfill(0,46,127,127,15)
 rectfill(0,44,127,45,4)
 local px={2,22,6,18,98,80,82,108}
 local py={50,62,84,102,68,54,88,100}
 for i=1,8 do
  dt(i%4==1 and 2 or 1,px[i],py[i])
 end
 ovalfill(58,83,74,86,4)
 sspr(0,12,12,12,50,62,24,24)
 print("\^w\^tkanguroo",30,16,4)
 print("\^w\^tkanguroo",29,15,7)
 print("a hop in the desert",30,32,6)
 dwsel()
 if unl(cd) then
  if tk%60<40 then
   print("❎ play",50,104,4)
  end
 else
  local s="clear level "..cd
  print(s,64-#s*2,104,5)
 end
 print("🅾️ how to play",36,114,5)
end

-- level picker row: arrows, number, and a badge saying
-- whether it is cleared or still locked
function dwsel()
 local u=unl(cd)
 rectfill(28,88,99,99,4)
 print("⬅️",30,91,15)
 print("➡️",88,91,15)
 local s="level "..(cd+1)
 print(s,64-#s*2,91,u and 15 or 6)
 if not u then
  rectfill(104,93,109,97,5)
  rect(105,90,108,93,5)
 elseif dget(cd)==1 then
  line(104,94,106,96,11)
  line(107,95,110,90,11)
 end
end

-- one screen, one rule per row, each pinned to the tile
-- it talks about so the icon carries half the sentence
function dwtut()
 cls(15)
 rectfill(0,0,127,10,4)
 print("how to play",42,3,15)
 turow(12,16,"⬅️➡️⬆️⬇️ to hop","2 tiles, 1 if blocked")
 turow(7,40,"hop into a crate","to push it 1 tile")
 turow(4,64,"land every crate","on an orange pad")
 turow(5,88,"water sinks roo","and crates alike")
 print("❎ undo",8,106,5)
 print("hold 🅾️ retry",60,106,5)
 if tk%60<40 then
  print("🅾️ back",50,118,4)
 end
end

function turow(id,y,a,b)
 dt(id,6,y)
 print(a,22,y+1,4)
 print(b,22,y+7,5)
end

function unl(i)
 return i==0 or dget(i-1)==1
end

-- pause-menu slot 1 belongs to whichever scene is on screen: wipe the save on
-- the title, "back to menu" inside a level.
function resetsave()
 for i=0,#lvls-1 do dset(i,0) end
 cd=0
 bleep(20)
end

function intromenu()
 menuitem(1,"reset progress",resetsave)
end

-->8
-- game: state

function startlev()
 sc="game"
 menuitem(1,"back to menu",
  function()
   sc="intro"
   bk=true
  end)
 music(2)
 loadlev()
end

function loadlev()
 bd={}
 bx={}
 local s=lvls[lv]
 for i=1,100 do
  local c=sub(s,i,i)
  local x,y=(i-1)%10,(i-1)\10
  local t=0
  if c=="#" then t=1
  elseif c=="~" then t=2
  elseif c=="o" or c=="B" then t=3 end
  bd[i]=t
  if c=="b" or c=="B" then add(bx,{x=x,y=y}) end
  if c=="p" then pl={x=x,y=y,f=3} end
 end
 an=nil
 us={}
 fp={}
 hold=0
 dead=0
 winf=0
 snkr=nil
 pt={}
end

function bt(x,y)
 if x<0 or x>9 or y<0 or y>9 then return 1 end
 return bd[y*10+x+1]
end

function bxat(x,y)
 for b in all(bx) do
  if b.x==x and b.y==y then return b end
 end
end

function snap()
 local s={pl.x,pl.y,pl.f}
 for b in all(bx) do
  add(s,b.x)
  add(s,b.y)
 end
 add(us,s)
end

function undo()
 local s=deli(us)
 pl.x=s[1]
 pl.y=s[2]
 pl.f=s[3]
 for i=1,#bx do
  bx[i].x=s[i*2+2]
  bx[i].y=s[i*2+3]
 end
 bleep(22)
end

function won()
 for b in all(bx) do
  if bt(b.x,b.y)!=3 then return false end
 end
 return true
end

-->8
-- game: update

function upgame()
 if winf>0 then
  winf-=1
  if winf==0 then
   -- roll straight into the next level; the picker only
   -- comes back once the last one is cleared
   if lv<#lvls then
    lv+=1
    cd=lv-1
    loadlev()
   else
    sc="intro"
    cd=#lvls-1
    bk=true
   end
  end
  return
 end
 if dead>0 then
  dead-=1
  if dead==0 then loadlev() end
  return
 end
 if an then
  an.t+=1
  if an.t>=an.dur then endan() end
  return
 end
 if btn(4) then
  hold+=1
  if hold>=120 then
   bleep(20)
   loadlev()
  end
 else
  hold=0
 end
 if btnp(5) and #us>0 then
  undo()
  return
 end
 for d=0,3 do
  if btnp(d) then
   try(d)
   return
  end
 end
end

function try(d)
 local dx,dy=dxs[d+1],dys[d+1]
 pl.f=d
 local x1,y1=pl.x+dx,pl.y+dy
 local x2,y2=x1+dx,y1+dy
 local b=bxat(x1,y1)
 if bt(x1,y1)==1 then
  bump()
 elseif b then
  if bt(x2,y2)==1 or bxat(x2,y2) then
   bump()
  else
   snap()
   an={t=0,dur=12,h=4,fx=pl.x-x1,fy=pl.y-y1,b=b,gx=b.x-x2,gy=b.y-y2}
   pl.x=x1
   pl.y=y1
   b.x=x2
   b.y=y2
   bleep(4)
  end
 elseif bt(x2,y2)==1 or bxat(x2,y2) then
  move(x1,y1,1)
 else
  move(x2,y2,2)
 end
end

function move(x,y,n)
 snap()
 an={t=0,
  dur=n<2 and 10 or 16,
  h=n<2 and 4 or 9,
  fx=pl.x-x,
  fy=pl.y-y}
 pl.x=x
 pl.y=y
 bleep(n<2 and 0 or 2)
end

function bump()
 an={t=0,dur=6,h=0,fx=0,fy=0,bp=true}
 bleep(6)
end

function endan()
 local a=an
 an=nil
 if a.bp then return end
 for b in all(bx) do
  if bt(b.x,b.y)==2 then
   bleep(12,3)
   snkr=b
   dead=46
   return
  end
 end
 if bt(pl.x,pl.y)==2 then
  bleep(10,3)
  snkr=pl
  dead=46
  return
 end
 bleep(8,3)
 puff(pl.x,pl.y)
 add(fp,{pl.x,pl.y})
 if #fp>3 then deli(fp,1) end
 if won() then
  bleep(14,3)
  dset(lv-1,1)
  winf=90
 end
end

-->8
-- game: draw

function dwgame()
 cls(15)
 for y=0,9 do
  for x=0,9 do
   local t=bt(x,y)
   local sx,sy=4+x*12,4+y*12
   if t==1 then dt(3,sx,sy)
   elseif t==2 then
    dt(5+(tk\24)%2,sx,sy)
    -- shoreline: only where the lake meets dry land,
    -- so a big lake stays open water instead of a grid
    if bt(x,y-1)!=2 then line(sx,sy,sx+11,sy,1) end
    if bt(x,y+1)!=2 then line(sx,sy+11,sx+11,sy+11,1) end
    if bt(x-1,y)!=2 then line(sx,sy,sx,sy+11,1) end
    if bt(x+1,y)!=2 then line(sx+11,sy,sx+11,sy+11,1) end
   elseif t==3 then dt(4,sx,sy)
   else
    local d=dec(x,y)
    if d>0 then dt(d,sx,sy) end
   end
  end
 end
 -- landing marks, oldest first, gone after 3 moves
 for f in all(fp) do
  local x,y=4+f[1]*12,4+f[2]*12
  pset(x+4,y+8,4)
  pset(x+7,y+9,4)
 end
 for b in all(bx) do
  local x,y=4+b.x*12,4+b.y*12
  if an and an.b==b then
   local p=an.t/an.dur
   x+=an.gx*12*(1-p)
   y+=an.gy*12*(1-p)
  end
  local d,vis=0,true
  if b==snkr then
   d=sinkp()*4
   vis=d<=2 or dead%4>=2
  else
   ovalfill(x+2,y+9,x+9,y+11,4)
  end
  if vis then
   dt(bt(b.x,b.y)==3 and 8 or 7,x,y+d)
  end
  -- rings go on top, or the sprite hides them
  if b==snkr then ripple(x+6,y+6) end
 end
 dwpl()
 dwpt()
end

function sinkp()
 return mid(0,(46-dead)/30,1)
end

-- rings have to read against the water, not match it
function ripple(cx,cy)
 local p=sinkp()
 circ(cx,cy,3+p*8,7)
 circ(cx,cy,1+p*5,1)
end

function dwpl()
 local x,y=4+pl.x*12,4+pl.y*12
 local h,sq=0,0
 if an then
  local p=an.t/an.dur
  if an.bp then
   local n=-sin(p)*2
   x+=dxs[pl.f+1]*n
   y+=dys[pl.f+1]*n
  else
   x+=an.fx*12*(1-p)
   y+=an.fy*12*(1-p)
   h=arc(p,an.h)
   if p<0.2 or p>0.8 then sq=1 end
  end
 end
 if winf>0 then
  h=arc((90-winf)%45/45,6)
 end
 local d,vis=0,true
 if pl==snkr then
  d=sinkp()*4
  vis=d<=2 or dead%4>=2
 else
  local sh=4-h/3
  ovalfill(x+6-sh,y+9,x+6+sh,y+11,4)
 end
 local f,id=pl.f,12
 if f<2 then id=10
 elseif f==2 then id=14 end
 if an and not an.bp then id+=1 end
 if vis then
  sspr(id%10*12,id\10*12,12,12,x,y-h+d+sq,12,12-sq,f==0)
 end
 -- rings go on top, or the sprite hides them
 if pl==snkr then ripple(x+6,y+6) end
 if hold>15 then
  local a=(hold-15)/105
  for i=0,a,0.04 do
   pset(x+6+cos(i)*9,y+6+sin(i)*9,10)
  end
 end
end
__gfx__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1cccccccccc11cccccccccc1000000000000000000000000ffffffffffff00000000
ffffffffffffffffffffffffffffffffffffffff5555ffffffff9999ffffcccccccccccccccccc11cccc00999999990000aaaaaaaa00ffffffffffff00000000
fffffffffffffffffffffffffffffbbffffffff665555ffffff99ff99fffcc77cccccccccccccccccccc0944499444900a999aa999a0ffffff655fff00000000
ffffffffffffffffffffffffffffbbbbffffff66555555ffff99ffff99ffcccccccccc1ccc11cccccccc0944499444900a999aa999a0ffffff552fff00000000
fffffffffffffffffffffffffffbbbbbbfffff66555555ffff9ffffff9ffccccccccccccccccccc77ccc0999999999900aaaaaaaaaa0ffffffffffff00000000
fffffffffffffffffffffffffffbbbb33fffff65555555ffffffffffffffc1cccccc77cccccccccccccc0944499444900a999aa999a0ffffffffffff00000000
ffffffffffffffffffffffffffff3333ffffff65555552ffffffffffffffccccccccccccc77ccccccccc0944499444900a999aa999a0ffffffffffff00000000
ffffffffffffff4444fffffffffff44fffffff65555522ffff9ffffff9ffcccc11cccccccccccccc11cc0999999999900aaaaaaaaaa0fff655ffffff00000000
fffffffffffff4ffff4ffffffffffffffffffff555522fffff99ffff99ffcccccccccccccccccccccccc0944499444900a999aa999a0fff552ffffff00000000
ffffffffffffffffffffffffffffffffffffffff2222fffffff99ff99fffcc77cccccccccccc77cccccc0944499444900a999aa999a0ffffffffffff00000000
ffffffffffffffffffffffffffffffffffffffffffffffffffff9999ffffccccccccc11cc11ccccccccc002222222200004444444400ffffffffffff00000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1cccccccccc11cccccccccc1000000000000000000000000ffffffffffff00000000
00000022222200000022222202220000222000000000000002220000222000000000000000000000000000000000000000000000000000000000000000000000
00000024224200000024224202422002242002220000222002422002242002220000222000000000000000000000000000000000000000000000000000000000
00000024444200000024444202442222442002422002242002442222442002422002242000000000000000000000000000000000000000000000000000000000
0000022424f20000022424f202244444422002442222442002244444422002442222442000000000000000000000000000000000000000000000000000000000
00002244444200002244444200242442420002244444422002244444422002244444422000000000000000000000000000000000000000000000000000000000
000224444ff2002224444ff202244444422000242442420002444444442002444444442000000000000000000000000000000000000000000000000000000000
002244444ff202244444ff220244ffff442002244444422002444444442002444444442000000000000000000000000000000000000000000000000000000000
222444444f222244444442200244ffff44200244ffff442002444444442022444444442200000000000000000000000000000000000000000000000000000000
24444444222024444444420002444ff4442022444ff4442202244444422024444444444200000000000000000000000000000000000000000000000000000000
24422444442024422444420002ff4224ff2024444444444202ff4444ff202ff444444ff200000000000000000000000000000000000000000000000000000000
222222ffff2022222ffff20002ff2222ff202ff442244ff202224444222022222442222200000000000000000000000000000000000000000000000000000000
00000222222000002222220002222002222022222222222200022222200000002222000000000000000000000000000000000000000000000000000000000000
__label__
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
ddddddddddddddddddddddddddddd77dd77dd777777dd7777dddddd7777dd77dd77dd777777dddd7777dddd7777ddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddd774d774d7777774d77774ddddd77774d774d774d7777774ddd77774ddd77774dddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddd774d774d7744774d774477dd77d4444d774d774d7744774d77d4774d77d4774dddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddd774d774d774d774d774d774d774ddddd774d774d774d774d774d774d774d774dddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddd7777d44d7777774d774d774d774ddddd774d774d7777d44d774d774d774d774dddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddd77774ddd7777774d774d774d774ddddd774d774d77774ddd774d774d774d774dddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddd774477dd7744774d774d774d774d77dd774d774d774477dd774d774d774d774dddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddd774d774d774d774d774d774d774d774d774d774d774d774d774d774d774d774dddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddd774d774d774d774d774d774d7777774dd477774d774d774d7777d44d7777d44dddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddd774d774d774d774d774d774d7777774ddd77774d774d774d77774ddd77774dddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddd44dd44dd44dd44dd44dd44dd444444dddd4444dd44dd44dd4444dddd4444dddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd9999999dddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd9999999999999ddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd999999999999999dddddddddddddddddddddd
dddddddddddddddddddddddddddddd666ddddd6d6dd66d666ddddd666d66dddddd666d6d6d666ddddd66dd666d96696669666966699ddddddddddddddddddddd
dddddddddddddddddddddddddddddd6d6ddddd6d6d6d6d6d6dddddd6dd6d6dddddd6dd6d6d6ddddddd6d6d6dd9699969996969969999dddddddddddddddddddd
dddddddddddddddddddddddddddddd666ddddd666d6d6d666dddddd6dd6d6dddddd6dd666d66dddddd6d6d66996669669966999699999ddddddddddddddddddd
dddddddddddddddddddddddddddddd6d6ddddd6d6d6d6d6dddddddd6dd6d6dddddd6dd6d6d6ddddddd6d6d699999696999696996999999dddddddddddddddddd
dddddddddddddddddddddddddddddd6d6ddddd6d6d66dd6ddddddd666d6d6dddddd6dd6d6d666ddddd666d6669669966696969969999999ddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd9999999999999999999999999ddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd9999999999999999999999999ddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd999999999999999999999999999dddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd999999999999999999999999999dddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd999999999999999999999999999dddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd999999999999999999999999999dddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd999999999999999999999999999dddddddddddddddd
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffbbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffbbbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffbbbb33fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffff3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9999fffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff444444ffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff224422224422ffffffffffffffffffffffffffffffffffff9999ffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff224422224422fffffffffffffffffffffffffffffffffff444444fffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff224444444422ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff224444444422ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222442244ff22ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222442244ff22ffffffffffffffffffffffffffffffffff9999ffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222444444444422fffffffffffffffffffffffffffffffff444444fffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222444444444422ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffff222244444444ffff22ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffff222244444444ffff22ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff22224444444444ffff22ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff22224444444444ffff22ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffff222222444444444444ff2222ffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffff9999fffff222222444444444444ff2222ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffff444444ffff2244444444444444222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffff2244444444444444222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffff2244442222444444444422ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffff2244442222444444444422ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffbbfffffffffff222222222222ffffffff22ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffbbbbffffffffff222222222222ffffffff224fffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffbbbbbbfffffffffffffffff44222222222222444fffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffff33fffffffffffffffff44222222222222444fffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffff3ffffffffffffffffffff4444444444444fffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffff9999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffff444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffff9999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffff444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9999ffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff444444fffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff444f444f444ff44ff44ffffff44444ffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff4f4f4f4f4fff4fff4fffffff4494944fffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff444f44ff44ff444f444fffff4444444fffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff4fff4f4f4fffff4fff4fffff44f4f44fffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff4fff4f4f444f44ff44fffffff44444ffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9999fffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff444444ffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

__sfx__
010500002653321525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500002853323525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001f5431a035160250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000215431c035180250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001463012635106250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001663013635116250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600000e3330c325000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000103330d325000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000d0330a625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000f0330b625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01070000245431c03116031100250c625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01070000225431b031150310f0250b625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0108000018043120310d0310902508625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001a043130310e0310a02509625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900001c5401f54023540285502b545000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900001c5402154023540285502d545000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002452000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002652000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600002153028535000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000235302a535000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001e63018635126250e61500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600002063019635136250f61500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000185141f524245250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001a51421524265250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400201503500000000000000000000000000000000000000000000000000000001c02500000000000000000000000000000000000000000000018025000000000000000000000000000000000000000000000
011400202d53500000000000000030535000000000000000325350000000000000003453500000000000000032525000000000000000305350000000000000002d5250000000000000002b525000000000000000
011400202d5350000000000000003253500000000000000034535000000000000000375350000000000000003452500000000000000032535000000000000000305250000000000000002d525000000000000000
01140020150250000000000000000000000000000000000000000000000000000000000000000000000000001a025000000000000000000000000000000000000000000000000000000000000000000000000000
011400202152500000000000000024525000000000000000265250000000000000002852500000000000000000000000000000000000265250000000000000000000000000245250000000000000000000000000
011400202152500000000000000026525000000000000000285250000000000000002b52500000000000000000000000000000000000285250000000000000000000000000245250000000000000000000000000
__music__
01 20214344
02 20224344
01 23244344
02 23254344

