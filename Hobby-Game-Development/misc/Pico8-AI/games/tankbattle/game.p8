pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- tank battle
-- by roberto freire

-- globals --
pfx,pfy,cols,rows=8,8,14,13
dxs,dys={0,1,0,-1},{-1,0,1,0}
bmap={4,2,1,3}          -- btn 0..3 -> dir (1 up,2 right,3 down,4 left)
chk=0b0101101001011010  -- 50% checker
tk,shake,freeze,flash,flc,wipe,slow=0,0,0,0,8,0,0
hsh,ash,apop,lsfx,hb=0,0,0,0,0
parts,pops,ens,buls,booms={},{},{},{},{}
lv,sel,score,dscore,lives,tkills=1,1,0,0,3,0
-- enemy types: sprite, frames/cell, hp, fire period, score
et={
 {s=32,f=10,hp=1,fr=90,sc=100},
 {s=36,f=6,hp=1,fr=0,sc=150},
 {s=40,f=14,hp=1,fr=45,sc=100},
 {s=44,f=12,hp=3,fr=90,sc=250},
 {s=68,f=16,hp=8,fr=40,sc=1000,w=2},
}
-- per level: enemy mask (1 grunt,2 runner,4 gunner,8 armor,16 boss),
-- spawn delay, speed mod, player bullets
meta=split("1,60,1.2,1|1,55,1.1,1|1,50,1,1|1,50,1,1|3,50,1,1|3,45,1,1|1,45,1,2|5,45,1,1|5,40,1,2|17,45,1,2|7,40,1,1|3,40,.9,2|9,40,1,1|11,40,.9,2|13,40,.9,1|7,35,.9,2|15,35,.9,2|15,35,.8,2|15,30,.8,2|25,30,.8,2","|")

-->8
-- entry / scenes --
function _init()
 cartdata("rbt_tankbattle_1")
 sel=max(dget(0),1)
 go_intro()
end

function set_wipe(f) wipe,wfn=24,f end

function intro_menu()
 menuitem(1,"clear progress",function()
  menuitem(1,"sure? ok",function()
   for i=0,2 do dset(i,0) end
   sel,flash,flc=1,2,7 sfx(19,0) intro_menu()
  end)
 end)
end

function go_intro()
 state="intro" bsq,sl,go=0,0,0
 sel=mid(sel,1,max(dget(0),1))
 att={{x=20,d=1,s=48},{x=90,d=-1,s=32}} abul=nil
 parts,pops={},{}
 music(0) intro_menu()
end

function start_game()
 lives,score,dscore,tkills=3,0,0,0
 set_wipe(function()
  state="game" load_level()
  menuitem(1,"back to intro",function() set_wipe(go_intro) end)
 end)
end

function load_level()
 reload(0x1000,0x1000,0x2000)
 local i=(lv-1)%20
 bx,by=i%9*14,i\9*13
 local m=split(meta[i+1])
 mask,sdel,smod,maxb=m[1],m[2],m[3],m[4]
 if lv>20 then smod*=0.8 end
 quota=min(8+lv*2,40)
 boss=mask>=16
 if boss then quota=quota\2+1 end
 cap=min(2+lv\2,5)
 ens,buls,parts,pops,booms={},{},{},{},{}
 kills,lc,go,card,tele,spt=0,0,0,0,nil,30
 spc={}
 for x=0,cols-1 do for y=0,rows-1 do
  if tile(x,y)==24 then add(spc,{x=x,y=y}) end
 end end
 if #spc==0 then spc={{x=0,y=0},{x=6,y=0},{x=13,y=0}} end
 respawn() p.inv=0
 ammo,rl=4,0
 if boss then
  add_enemy(5,6,0) card=40 sfx(15,0) music(12)
 else music(4) end
end

function respawn()
 p=mk_tank(6,12,0) p.d=1 p.inv=90
end

-->8
-- tanks --
function mk_tank(cx,cy,t)
 local e=et[t] or {f=6}
 return {cx=cx,cy=cy,ox=cx,oy=cy,x=cx*8,y=cy*8,d=3,md=3,m=0,w=e.w or 1,t=t,
  sp=8/(e.f*(t>0 and smod or 1)),hp=e.hp,ft=e.fr or 0,
  af=0,rot=0,fl=0,dead=0,inv=0,mf=0,rc=0,jit=0}
end

function add_enemy(t,cx,cy)
 local e=mk_tank(cx,cy,t) e.ft+=rnd(30) add(ens,e) return e
end

function tile(x,y) return mget(bx+x,by+y) end

-- does tank t cover cell x,y (current or previous cell)
function hits(t,x,y)
 local w=t.w
 return (x>=t.cx and x<t.cx+w and y>=t.cy and y<t.cy+w)
  or (x>=t.ox and x<t.ox+w and y>=t.oy and y<t.oy+w)
end

function free(cx,cy,e)
 for i=0,e.w-1 do for j=0,e.w-1 do
  local x,y=cx+i,cy+j
  if x<0 or y<0 or x>=cols or y>=rows then return false end
  local tl=tile(x,y)
  if fget(tl,0) and not (e.w==2 and fget(tl,3)) then return false end
  for t in all(ens) do if t!=e and hits(t,x,y) then return false end end
  if e!=p and e.t!=2 and p.dead==0 and hits(p,x,y) then return false end
 end end
 return true
end

function try_move(e,d)
 local nx,ny=e.cx+dxs[d],e.cy+dys[d]
 if free(nx,ny,e) then
  e.ox,e.oy,e.cx,e.cy,e.m,e.md=e.cx,e.cy,nx,ny,8,d
  if e.w==2 then
   for i=0,1 do for j=0,1 do
    if fget(tile(nx+i,ny+j),3) then hit_brick(nx+i,ny+j,true) end
   end end
  end
  return true
 end
end

function move(e)
 if e.m>0 then
  local s=min(e.sp,e.m) e.m-=s
  e.x+=dxs[e.md]*s e.y+=dys[e.md]*s e.af+=0.25
  if e.m<=0 then e.x,e.y,e.ox,e.oy=e.cx*8,e.cy*8,e.cx,e.cy end
 end
end

function fire(e,d,pl,sx,sy)
 local c=e.w*4
 add(buls,{x=e.x+c+dxs[d]*(c+1),y=e.y+c+dys[d]*(c+1),
  dx=dxs[d]+(sx or 0),dy=dys[d]+(sy or 0),pl=pl,bnc=0,sp=pl and 4 or 2})
end

function upd_player()
 if p.mf>0 then p.mf-=1 end
 if p.rc>0 then p.rc-=1 end
 if p.jit>0 then p.jit-=1 end
 if p.dead>0 then
  p.dead-=1
  if p.dead==0 then respawn() end
  return
 end
 if p.inv>0 then p.inv-=1 end
 move(p)
 if p.rot>0 then p.rot-=1
 elseif p.m<=0 then
  for b=0,3 do
   if btn(b) then
    local d=bmap[b+1]
    if d!=p.d and not btn(4) then
     p.d,p.rot,p.rc=d,2,1 sfx(0,0)
    elseif try_move(p,d) then
     sfx(1,0) burst(p.ox*8+4,p.oy*8+4,2,6)
    end
    break
   end
  end
 end
 if btnp(5) then
  local n=0
  for b in all(buls) do if b.pl then n+=1 end end
  if ammo>0 and n<maxb then
   fire(p,p.d,true) ammo-=1 rl,p.mf,p.rc=30,3,2
   shake=max(shake,1) sfx(2,0)
  else
   sfx(3,0) p.jit,ash=4,6
  end
 end
 if rl>0 then rl-=1
 elseif ammo<4 then ammo+=1 rl,apop=30,4 sfx(4,0) end
end

function upd_enemy(e)
 local ty=et[e.t]
 if e.fl>0 then e.fl-=1 end
 move(e)
 if e.w==2 and e.m>0 and tk%8==0 then shake=max(shake,1) end
 if e.m<=0 then
  local bd,bs=nil,999
  for d=1,4 do
   local nx,ny=e.cx+dxs[d],e.cy+dys[d]
   if free(nx,ny,e) then
    local s=abs(nx-p.cx)+abs(ny-p.cy)
    if e.t==2 then s=(rows-ny)*2+abs(nx-p.cx) end
    if e.t==3 then s=abs(nx-p.cx)*3+abs(ny-p.cy)*0.3 end
    if rnd()<0.25 then s=rnd(10) end
    if s<bs then bd,bs=d,s end
   end
  end
  if bd then e.d=bd try_move(e,bd) end
  if e.t==3 and e.cx==p.cx then e.d=p.cy>e.cy and 3 or 1 end
 end
 if ty.fr>0 then
  e.ft-=1
  if e.ft<=0 then
   e.ft=ty.fr+rnd(30)
   fire(e,e.d,false)
   if e.w==2 then
    fire(e,e.d,false,dys[e.d]*.5,dxs[e.d]*.5)
    fire(e,e.d,false,-dys[e.d]*.5,-dxs[e.d]*.5)
   end
  end
 end
 if e.t==2 then
  if p.dead==0 and abs(e.x-p.x)<8 and abs(e.y-p.y)<8 and lose_life() then
   kill_enemy(e,false,true)
  elseif e.cy==rows-1 and e.m<=0 then
   kill_enemy(e,false,true) lose_life(true)
  end
 end
end

function lose_life(force)
 if p.dead>0 or (p.inv>0 and not force) then return end
 lives-=1 shake,flash,flc,hsh,lsfx=8,2,8,6,10
 boom(p.x+4,p.y+4,1) burst(p.x+4,p.y+4,8,11) sfx(11,0)
 p.dead=90
 if lives<=0 then go=120 music(-1) sfx(21,0) end
 return true
end

function kill_enemy(e,ric,quiet)
 del(ens,e)
 boom(e.x+4*e.w,e.y+4*e.w,e.w,ric)
 burst(e.x+4*e.w,e.y+4*e.w,6,9)
 sfx(ric and 7 or 8,0) shake=max(shake,2+e.w) freeze=e.w*2
 if quiet then return end
 kills+=1 tkills+=1 hb=3 sfx(13,1)
 addscore(et[e.t].sc*(ric and 2 or 1),e.x+4*e.w,e.y)
 if ric then pop("x2",e.x+4*e.w,e.y-8,7) end
 if e.t==5 then flash,flc,slow,freeze=6,7,30,6 sfx(16,0) end
end

-->8
-- bullets / spawning --
function hit_brick(x,y,hard)
 local tl=tile(x,y)
 mset(bx+x,by+y,(tl==16 and not hard) and 17 or 0)
 burst(x*8+4,y*8+4,3,4) burst(x*8+4,y*8+4,2,9) sfx(5,0)
end

-- returns true when the bullet is spent
function upd_bul(b)
 for i=1,b.sp do
  b.x+=b.dx b.y+=b.dy
  local cx,cy=b.x\8,b.y\8
  if cx<0 or cy<0 or cx>=cols or cy>=rows then return true end
  local tl=tile(cx,cy)
  if fget(tl,2) and b.pl and b.bnc<2 then
   b.dx,b.dy,b.bnc=-b.dx,-b.dy,b.bnc+1
   burst(b.x,b.y,4,7) burst(b.x,b.y,2,10) sfx(6,0)
  elseif fget(tl,1) then
   if fget(tl,3) then hit_brick(cx,cy) else burst(b.x,b.y,3,6) end
   return true
  end
  if b.pl then
   for e in all(ens) do
    if b.x>=e.x and b.x<e.x+8*e.w and b.y>=e.y and b.y<e.y+8*e.w then
     e.hp-=1 e.fl=3
     if e.hp<=0 then kill_enemy(e,b.bnc>0) else sfx(9,0) burst(b.x,b.y,3,7) end
     return true
    end
   end
  elseif p.dead==0 and p.inv==0 and b.x>=p.x and b.x<p.x+8 and b.y>=p.y and b.y<p.y+8 then
   lose_life() return true
  end
 end
end

function upd_spawn()
 if kills>=quota or #ens>=cap then return end
 spt-=1
 if spt<=30 and not tele then tele=spc[flr(rnd(#spc))+1] sfx(10,0) end
 if spt<=0 then
  local f={cx=tele.x,cy=tele.y,ox=tele.x,oy=tele.y,w=1,t=9}
  if free(tele.x,tele.y,f) then
   local t
   repeat t=flr(rnd(4))+1 until (mask&(1<<(t-1)))>0
   add_enemy(t,tele.x,tele.y)
   spt,tele=sdel,nil
  else spt=8 end
 end
end

-->8
-- update --
function _update()
 tk+=1
 if wipe>0 then wipe-=1 if wipe==12 then wfn() end end
 if flash>0 then flash-=1 end
 if lsfx>0 then lsfx-=1 if lsfx==0 then sfx(12,0) end end
 if state=="intro" then upd_intro() else upd_game() end
end

function upd_fx()
 for q in all(parts) do
  q.x+=q.dx q.y+=q.dy q.l-=1
  if q.l<=0 then del(parts,q) end
 end
 for q in all(pops) do
  q.y-=0.5 q.l-=1
  if q.l<=0 then del(pops,q) end
 end
 for q in all(booms) do
  q.f+=0.4
  if q.f>=5 then del(booms,q) end
 end
 dscore+=ceil((score-dscore)/8)
 hb=max(hb-1) ash=max(ash-1) apop=max(apop-1) hsh*=0.8
 shake*=0.85 if shake<0.5 then shake=0 end
end

function upd_game()
 if freeze>0 then freeze-=1 return end
 if slow>0 then slow-=1 if slow%2==1 then return end end
 if card>0 then card-=1 return end
 upd_fx()
 if go>0 then
  go-=1
  if go==0 then
   dset(1,max(dget(1),score)) dset(2,dget(2)+tkills)
   set_wipe(go_intro)
  end
  return
 end
 if lc>0 then
  lc+=1
  if lc%8==0 and #ens>0 then kill_enemy(ens[1],false,true) end
  if #ens==0 and lc>40 then
   addscore(50*lives*lv,56,52) sfx(14,0)
   dset(0,max(dget(0),lv+1)) dset(1,max(dget(1),score))
   dset(2,dget(2)+tkills) tkills=0
   lc=-1 set_wipe(function() lv+=1 load_level() end)
  end
  return
 end
 if lc<0 then return end
 upd_player()
 for e in all(ens) do upd_enemy(e) end
 for b in all(buls) do if upd_bul(b) then del(buls,b) end end
 for a in all(buls) do for b in all(buls) do
  if a.pl and not b.pl and abs(a.x-b.x)<3 and abs(a.y-b.y)<3 then
   del(buls,a) del(buls,b) burst(a.x,a.y,4,7)
  end
 end end
 upd_spawn()
 if kills>=quota and lc==0 then lc=1 buls={} sfx(20,0) end
end

function upd_intro()
 upd_fx()
 local mx=max(dget(0),1)
 if bsq==0 and wipe==0 then
  if btnp(0) and sel>1 then sel-=1 sl=-8 sfx(17,0) end
  if btnp(1) and sel<mx then sel+=1 sl=8 sfx(17,0) end
  if btnp(4) or btnp(5) then bsq=8 sfx(18,0) end
 end
 sl*=0.7
 if bsq>0 then
  bsq-=1
  if bsq==0 then lv=sel start_game() end
 end
 for a in all(att) do
  a.x+=a.d*0.5
  if a.x<8 or a.x>112 then a.d=-a.d end
 end
 if abul then
  abul.x+=abul.dx abul.y+=abul.dy abul.l-=1
  if abul.x<1 or abul.x>126 then abul.dx=-abul.dx burst(abul.x,abul.y,3,7) end
  if abul.y<1 or abul.y>126 then abul.dy=-abul.dy burst(abul.x,abul.y,3,7) end
  if abul.l<=0 then abul=nil end
 elseif rnd()<0.02 then
  local a=att[flr(rnd(2))+1]
  abul={x=a.x+4,y=114,dx=a.d*1.5,dy=-2,l=120}
 end
end

-- effects helpers
function burst(x,y,n,c)
 for i=1,n do
  add(parts,{x=x,y=y,dx=rnd(2)-1,dy=rnd(2)-1,l=8+rnd(10),c=c})
 end
 while #parts>48 do deli(parts,1) end
end
function pop(s,x,y,c) add(pops,{s=s,x=x,y=y,c=c,l=24}) end
function boom(x,y,w,wh) add(booms,{x=x,y=y,w=w,f=0,wh=wh}) end
function addscore(n,x,y) score+=n pop(""..n,x,y,10) end

-->8
-- draw --
function rp() pal() palt(0,false) palt(15,true) end

function oprint(s,x,y,c)
 for i=-1,1 do for j=-1,1 do print(s,x+i,y+j,0) end end
 print(s,x,y,c)
end

function _draw()
 rp()
 if state=="intro" then draw_intro() else draw_game() end
 if flash>0 then for c=0,15 do pal(c,flc,1) end end
 if wipe>0 then
  local w=(wipe>12 and 24-wipe or wipe)*11
  if wipe>12 then
   rectfill(0,0,w-8,127,0) fillp(chk) rectfill(w-8,0,w,127,0)
  else
   rectfill(136-w,0,127,127,0) fillp(chk) rectfill(128-w,0,136-w,127,0)
  end
  fillp()
 end
end

function draw_tank(e)
 local w,d=e.w,e.d
 local ty=et[e.t]
 local s=(ty and ty.s or 48)+(d%2==0 and 2*w or 0)+(w==1 and flr(e.af)%2 or 0)
 local ox,oy=0,0
 if e.rc>0 then ox,oy=-dxs[d],-dys[d] end
 if e.jit>0 then ox+=rnd(2)-1 end
 if e.fl>0 then for c=1,14 do pal(c,7) end end
 if e.t==4 then pal(4,({8,9,4})[e.hp]) end
 if e.t==0 and tk%8<4 then pal(7,3) end
 spr(s,e.x+ox,e.y+oy,w,w,d==4,d==3)
 rp()
end

function card_txt(s,c,big)
 fillp(chk|0.5) rectfill(8,8,119,111,0) fillp()
 rectfill(20,48,107,70,0) rect(20,48,107,70,c)
 if big then s="\^w\^t"..s oprint(s,64-(#s-4)*4,54,c)
 else oprint(s,64-#s*2,57,c) end
end

function draw_game()
 cls(0)
 fillp(chk) rectfill(3,3,124,108,0x50) fillp()
 rectfill(6,6,121,109,5)
 oprint(""..dscore,4,1,7)
 clip(pfx,pfy,cols*8,rows*8)
 camera(-pfx+rnd(shake)-shake/2,-pfy+rnd(shake)-shake/2)
 fillp(chk) rectfill(0,0,111,103,0x51) fillp()
 pal(12,tk%30<15 and 12 or 6)
 map(bx,by,0,0,cols,rows,16)
 pal(12,12)
 if tele then
  local r=(30-spt)/30
  circ(tele.x*8+4,tele.y*8+4,r*9,8)
  if tk%4<2 then rect(tele.x*8,tele.y*8,tele.x*8+7,tele.y*8+7,8) end
 end
 for e in all(ens) do draw_tank(e) end
 if p.dead==0 and (p.inv==0 or tk%4<2) then draw_tank(p) end
 if p.mf>0 then spr(67-p.mf,p.x+dxs[p.d]*8,p.y+dys[p.d]*8) end
 for b in all(buls) do rectfill(b.x-1,b.y-1,b.x,b.y,b.pl and 7 or 8) end
 for q in all(booms) do
  local f=flr(q.f)
  if q.wh and q.f<1 then for c=1,14 do pal(c,7) end end
  if q.w==1 then spr(80+f,q.x-4,q.y-4)
  else local z=8*q.w+8 sspr(f*8,40,8,8,q.x-z/2,q.y-z/2,z,z) end
  rp()
 end
 map(bx,by,0,0,cols,rows,32)
 for q in all(parts) do pset(q.x,q.y,q.c) end
 for q in all(pops) do oprint(q.s,q.x-#q.s*2,q.y,q.l<8 and 6 or q.c) end
 camera() clip()
 draw_hud()
 if card>0 then card_txt("boss",8,card<20) end
 if go>0 then card_txt("game over",8) end
 if lc>8 then card_txt("level clear",11) end
end

function draw_hud()
 local hy=113+(hsh>0.5 and rnd(hsh)-hsh/2 or 0)-(hb>0 and 1 or 0)
 fillp(chk) rectfill(0,112,127,127,0x50) fillp()
 oprint("lv "..lv,4,hy+4,7)
 for i=1,lives do spr(98,22+i*6,hy+4) end
 rect(44,hy+3,85,hy+9,5)
 local f=flr(kills/quota*39)
 if f>0 then rectfill(45,hy+4,45+f,hy+8,11) end
 for x=48,84,4 do line(x,hy+4,x,hy+8,0) end
 for i=1,4 do
  local yy=hy+3+(ash>0 and rnd(3)-1 or 0)
  if i==ammo and apop>0 then sspr(0,48,8,8,84+i*8-2,yy-2,12,12)
  else spr(i<=ammo and 96 or 97,84+i*8,yy) end
 end
end

function draw_intro()
 cls(1)
 fillp(chk) rectfill(0,0,127,127,0x10) fillp()
 sspr(0,80,70,30,29,8+sin(tk/60)*2)
 -- level selector
 local mx=max(dget(0),1)
 local s="level "..sel
 oprint(s,64-#s*2+sl,52,7)
 local a=sin(tk/30)*2
 if sel>1 then spr(99,28-a,51,1,1,true) end
 if sel<mx then spr(99,94+a,51) end
 -- start button
 local h=bsq>0 and 8 or 12
 local y=74+sin(tk/40)+12-h
 rrectfill(44,y,40,h,3,11) rrect(44,y,40,h,3,3)
 oprint("start",54,y+h/2-2,7)
 oprint("best "..dget(1),4,100,6)
 oprint("kills "..dget(2),4,108,6)
 for t in all(att) do spr(t.s+2+tk\4%2,t.x,112,1,1,t.d<0) end
 if abul then rectfill(abul.x-1,abul.y-1,abul.x,abul.y,7) end
 for q in all(parts) do pset(q.x,q.y,q.c) end
end
__gfx__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
494949494949494977777776ffffffff11111111fffffffff3b3ffbfffffffff5ffffff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
949494949404949476666665ffffffff1cc11cc1ffffffff3bbb3bb3fffffffff5ffff5fffffffffffffffffffffffffffffffffffffffffffffffffffffffff
222222222220222276767665ffffffffc11cc11cffffffffbb3bbb3bffffffffff8ff8ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
949494949494049476666665ffffffff11111111ffffffff3bbb33bbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
494949494900494976667665ffffffff11111111fffffffffb3bbb3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
222222222222022276666665ffffffffc11cc11cffffffff3bb3bb33ffffffffff8ff8ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
494949494949404976666665ffffffff1cc11cc1ffffffffb3bbb3bffffffffff5ffff5fffffffffffffffffffffffffffffffffffffffffffffffffffffffff
949494949494949465555555ffffffff11111111fffffffff3fb3f3fffffffff5ffffff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fff00ffffff44fff0404040440404040fff00ffffff22fff0202020220202020fff00ffffff11fff0101010110101010fff00ffffff44fff0404040440404040
fff00ffffff44fff4040404004040404fff00ffffff22fff2020202002020202fff00ffffff11fff1010101001010101fff00ffffff44fff4040404004040404
0499994040999904f999999ff999999f02eeee2020eeee02feeeeeeffeeeeeef01cccc1010cccc01fccccccffccccccf0444444040444404f844448ff844448f
4099990404999940f9999900f999994420eeee0202eeee20feeeee00feeeee2210cccc0101cccc10fccccc00fccccc114048840404488440f8488400f8488444
0499994040999904f9999900f999994402eeee2020eeee02feeeee00feeeee2201cccc1010cccc01fccccc00fccccc110448844040488404f4488400f4488444
4099990404999940f999999ff999999f20eeee0202eeee20feeeeeeffeeeeeef10cccc0101cccc10fccccccffccccccf4044440404444440f844448ff844448f
0499994040999904040404044040404002eeee2020eeee02020202022020202001cccc1010cccc01010101011010101004888840408888040404040440404040
40ffff0404ffff40404040400404040420ffff0202ffff20202020200202020210ffff0101ffff10101010100101010140ffff0404ffff404040404004040404
fff00ffffff33fff0303030330303030ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fff00ffffff33fff3030303003030303ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
03bbbb3030bbbb03fbbbbbbffbbbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
30bbbb0303bbbb30fbbbbb00fbbbbb33ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
03bbbb3030bbbb03f7bbbb00f7bbbb33ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
30b77b0303b77b30fbbbbbbffbbbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
03bbbb3030bbbb030303030330303030ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
30ffff0303ffff303030303003030303ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fff7ffffffffffffffffffffffffffffffffff0000ffffffffffffffffffffff0022002200220022ffffffffffffffffffffffffffffffffffffffffffffffff
f7f7f7fffff7fffffffffffffff7ffffffffff0000ffffffffffffffffffffff0022002200220022ffffffffffffffffffffffffffffffffffffffffffffffff
ffaaafffffa9affffff7ffffffffffffffffff0000ffffffffffffffffffffff2200220022002200ffffffffffffffffffffffffffffffffffffffffffffffff
7aa7aa7ff7a7a7ffff797ffff7f7f7ffffffff0000ffffffffffffffffffffff2200220022002200ffffffffffffffffffffffffffffffffffffffffffffffff
ffaaafffffa9affffff7ffffffffffff00222d2d2d2d2200ffffffffffffffffff2d2d2d2d2d2dffffffffffffffffffffffffffffffffffffffffffffffffff
f7f7f7fffff7fffffffffffffff7ffff0022ddddddd22200ffffffffffffffffffd2ddddddd2d2ffffffffffffffffffffffffffffffffffffffffffffffffff
fff7ffffffffffffffffffffffffffff22002ddddddd0022ffffffffffffffffff2d2ddddddd0000ffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffff2200ddddddd20022ffffffffffffffffffd2ddddddd20000ffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffff9f9fff8f898fff5f585ffdddd2200ffffffffffffffffff882ddddddd0000ffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffafafffff9a9a9f8989998f5858885fddd22200ffffffffffffffffff88ddddddd20000ffffffffffffffffffffffffffffffffffffffffffffffff
fff7f7fffa7a7afff9aaaaa9f8999998f588888588dd0022ffffffffffffffffff2d2ddddddd2dffffffffffffffffffffffffffffffffffffffffffffffffff
ff777fffffa777af9aaaaa9f899999995888888888d20022ffffffffffffffffffd2d2d2d2d2d2ffffffffffffffffffffffffffffffffffffffffffffffffff
fff777fffa777afff9aaaaa999999998888888852d2d2200ffffffffffffffff0022002200220022ffffffffffffffffffffffffffffffffffffffffffffffff
ff7f7fffffa7a7af9aaaaa9f8999998f5888885fd2d22200ffffffffffffffff0022002200220022ffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffafafff9a9a9fff8999898f5888585ffff0022ffffffffffffffff2200220022002200ffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffff9f9fffff898f8fff585f5fffff0022ffffffffffffffff2200220022002200ffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fff7fffffff5fffffff3ffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffaaafffff555ffff3bbb3ffff77ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffa9afffff505ffff33333ffff777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff999fffff000ffff3b7b3ffff77ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff999fffff000ffff33333ffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff494fffff050fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
01000000002121002100000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000010000210000210000010000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004141414100004141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000021210000010000010000212100000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21012101210000000021012101210000610000000000000000610000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffff0bbbbbbbbbb0ff0bbbbbb0ff0bb0ffff0bb00bb0ffff0bb0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffff0bbbbbbbbbb0000bbbbbb0000bb000ff0bb00bb0ff000bb0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffff00000bb000000bb000000bb00bbbb0ff0bb00bb0ff0bb000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff0bb0ffff0bb0ffff0bb00bbbb0ff0bb00bb0000bb0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff0bb0ffff0bb0ffff0bb00bbbb0ff0bb00bb00bb000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff0bb0ffff0bb000000bb00bbbb0000bb00bb00bb0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff0bb0ffff0bbbbbbbbbb00bb00bb00bb00bbbb000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff0bb0ffff0bbbbbbbbbb00bb00bb00bb00bbbb000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff03b0ffff03b0000003b003b00003b3b003b003b0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff0b30ffff0b30ffff0b300b30ff0b3b300b300b3000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff0330ffff0330ffff03300330ff0333300330000330fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff0330ffff0330ffff03300330ff0333300330ff033000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff0330ffff0330ffff03300330ff0003300330ff000330fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff0330ffff0330ffff03300330ffff03300330ffff0330fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff0000ffff0000ffff00000000ffff00000000ffff0000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
000000000ffff00000000ff0000000000000000000000000000ffffffff00000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbbbbbb0ffff0bbbbbb0ff0bbbbbbbbbb00bbbbbbbbbb00bb0ffffffff0bbbbbbbbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbbbbbb000000bbbbbb0000bbbbbbbbbb00bbbbbbbbbb00bb0ffffffff0bbbbbbbbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bb000000bb00bb000000bb000000bb0000000000bb000000bb0ffffffff0bb00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bb0ffff0bb00bb0ffff0bb0ffff0bb0ffffffff0bb0ffff0bb0ffffffff0bb0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bb0ffff0bb00bb0ffff0bb0ffff0bb0ffffffff0bb0ffff0bb0ffffffff0bb0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bb000000bb00bb000000bb0ffff0bb0ffffffff0bb0ffff0bb0ffffffff0bb0000000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbbbbbb0000bbbbbbbbbb0ffff0bb0ffffffff0bb0ffff0bb0ffffffff0bbbbbbbb0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbbbbbb0000bbbbbbbbbb0ffff0bb0ffffffff0bb0ffff0bb0ffffffff0bbbbbbbb0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3b0000003b003b0000003b0ffff03b0ffffffff03b0ffff03b0ffffffff03b0000000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
b30ffff0b300b30ffff0b30ffff0b30ffffffff0b30ffff0b30ffffffff0b30fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
330ffff03300330ffff0330ffff0330ffffffff0330ffff0330ffffffff0330fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
330000003300330ffff0330ffff0330ffffffff0330ffff03300000000003300000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
333333330000330ffff0330ffff0330ffffffff0330ffff03333333333003333333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
333333330ff0330ffff0330ffff0330ffffffff0330ffff03333333333003333333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
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
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007070777077707770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007070007070007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007770777077707070505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505000
00000070700000707070050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050000
00005070777077707770505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505000
00050000000000000000555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555050000
00005055555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555505000
00050555888888881515151515151515151515151515151515151515551515151515151515151515151515151515151515151515151515155515151555050000
00005055888151885151515151515151515151515151515151515151555151515151515151515151515151515151515151515151515151515551515155505000
00050555888518181515151515151515151515151515151515151515158518151515151515151515151515151515151515151515151515151585181555050000
00005055815151588151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515155505000
00050555851515188515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151555050000
00005055818158588151515151515151515151515151515151515151518158515151515151515151515151515151515151515151515151515181585155505000
00050555881515581515151515151515151515151515151515151515151515551515151515151515151515151515151515151515151515151515155555050000
00005055888888885151515151515151515151515151515151515151515151555151515151515151515151515151515151515151515151515151515555505000
00050555151888151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515155505000
00050555151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515155505000
00050555151515151515151515151515151515150bbbbbbbbbb0150bbbbbb0150bb015150bb00bb015150bb01515151515151515151515151515151555050000
00005055515151515151515151515151515151510bbbbbbbbbb0000bbbbbb0000bb000510bb00bb051000bb05151515151515151515151515151515155505000
000505551515151515151515151515151515151500000bb000000bb000000bb00bbbb0150bb00bb0150bb0001515151515151515151515151515151555050000
000050555151515151515151515151515151515151510bb051510bb051510bb00bbbb0510bb00bb0000bb0515151515151515151515151515151515155505000
000505557777777640777704777777767777777677770bb015150bb015150bb00bbbb0150bb00bb00bb000767777777610777701777777767777777655050000
000050557666666504999940766666657666666576660bb051510bb000000bb00bbbb0000bb00bb00bb066657666666501cccc10766666657666666555505000
000505557676766540999904767676657676766576760bb015150bbbbbbbbbb00bb00bb00bb00bbbb00076657676766510cccc01767676657676766555050000
000050557666666504999940766666657666666576660bb051510bbbbbbbbbb00bb00bb00bb00bbbb00066657666666501cccc10766666657666666555505000
0005055576667665409999047666766576667665766603b0151503b0000003b003b00003b3b003b003b076657666766510cccc01766676657666766555050000
000050557666666504999940766666657666666576660b3051510b3051510b300b30510b3b300b300b3000657666666501cccc10766666657666666555505000
00050555766666657660066576666665766666657666033015150330151503300330150333300330000330657666666576600665766666657666666555050000
00005055655555556550055565555555655555556555033051510330515103300330510333300330650330006555555565500555655555556555555555505000
00050555151515151515151515151515151515151515033015150330151503300330150003300330150003301515151515151515151515151515151555050000
00005055515151515151515151515151515151515151033051510330515103300330515103300330515103305151515151515151515151515151515155505000
00050555151515151515151515151515151515151515000015150000151500000000151500000000151500001515151515151515151515151515151555050000
00005055515151515151515151515000000000515100000000510000000000000000000000000000515151510000000000015151515151515151515155505000
00050555151515151515151515151bbbbbbbb015150bbbbbb0150bbbbbbbbbb00bbbbbbbbbb00bb0151515150bbbbbbbbbb51515151515151515151555050000
00005055515151515151515151515bbbbbbbb000000bbbbbb0000bbbbbbbbbb00bbbbbbbbbb00bb0515151510bbbbbbbbbb15151515151515151515155505000
00050555151515151515151515151bb000000bb00bb000000bb000000bb0000000000bb000000bb0151515150bb0000000051515151515151515151555050000
00005055515151515151515151515bb051510bb00bb051510bb051510bb0515151510bb051510bb0515151510bb0515151515151515151515151515155505000
00050555151515151515151515151bb015150bb00bb015150bb015150bb0151515150bb015150bb0404040400bb0151549494949151515151515151555050000
00005055515151515151515151515bb000000bb00bb000000bb051510bb0515151510bb051510bb0040404040bb0000000949494515151515151515155505000
00050555151515151515151515151bbbbbbbb0000bbbbbbbbbb015150bb0151515150bb015150bb0184444850bbbbbbbb0222222151515151515151555050000
00005055515151515151515151515bbbbbbbb0000bbbbbbbbbb051510bb0515151510bb051510bb0004884810bbbbbbbb0949494515151515151515155505000
000505551515151515151515151513b0000003b003b0000003b0151503b01515151503b0151503b00048844503b0000000494949151515151515151555050000
00005055515151515151515151515b3051510b300b3051510b3051510b30515151510b3051510b30584444810b30515122222222515151515151515155505000
00050555151515151515151515151330151503300330151503301515033015151515033015150330404040400330151549494949151515151515151555050000
00005055515151515151515151515330000003300330815103305151033051515151033051510330000000000330000000049494515151515151515155505000
00050555151515151515151549494333333330000330850203301515033077767777033015150333333333300333333333351515151515151515151555050000
00005055515151515151515194949333333330510330ee2003305151033066657666033051510333333333300333333333315151515151515151515155505000
000505551515151515151515222222221515151520eeee0215151515767676657676766515151515151515151515151515151515151515151515151555050000
000050555151515151515151949494945151515102eeee2051515151766666657666666551515151515151515151515151515151515151515151515155505000
000505551515151515151515494949491515151520eeee0215151515766676657666766515151515151515151519191515151515151515151515151555050000
000050555151515151515151222222225151515102eeee205151515176666665766666655151515151515151519a9a9151515151515151515151515155505000
000505551515151515151515494949491515151515100515151515157666666576666665151515151515151519aaaaa915151515151515151515151555050000
00005055515151515151515194949494515151515150015151515151655555556555555551515151515151519aaaaa9151515151515151515151515155505000
000505551515151515151515151515151515151515151515151515157777777677777776151515151515151519aaaaa949494949151515151515151555050000
00005055515151515151515151515151515151515151515151515151766666657666666551515151515151519aaaaa9194949494515151515151515155505000
000505551515151515151515151515151515151515151515151515157676766576767665151515151515151519a9a91522222222151515151515151555050000
00005055515151515151515151515151515151515151515151515151766666657666666551515151515151515191915194949494515151515151515155505000
00050555151515151515151515151515151515151515151515151515766676657666766515151515151515151515151549494949151515151515151555050000
00005055515151515151515151515151515151515151515151515151766666657666666551515151515151515151515122222222515151515151515155505000
00050555151515151515151515151515151515151515151515151515766666657666666515151515151515151515151549494949151515151515151555050000
00005055515151515151515151515151515151515151515151515151655555556555555551515151515151515151515194949494515151515151515155505000
00050555151515151515151549494949151515151515151515151515151515151515151515151515151515151515151515151515404040401515151555050000
00005055515151515151515194949494515151515151515151515151515151515151515151515151515151515151515151515151040404045151515155505000
00050555151515151515151522222222151515151515151515151515151515151515151515151515151515151515151515151515199999951515151555050000
00005055515151515151515194949494515151515151515151515151515151515151515151515151515151515151515151515151009999915151515155505000
00050555151515151515151549494949151515151515151515151515151515151515151515151515151515151515151515151515009999951515151555050000
00005055515151515151515122222222515151515151515151515151515151515151515151515151515151515151515151515151599999915151515155505000
00050555151515151515151549494949151515151515151515151515151515151515151515151515151515151515151515151515404040401515151555050000
00005055515151515151515194949494515151515151515151515151515151515151515151515151515151515151515151515151040404045151515155505000
00050555151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515155505000
00050555151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515155505000
00050555151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151515771515151515151515151515151515151515151515151515151515151515155505000
00050555151515151515151515151515151515151515151515151515151775151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515155505000
00050555777777767777777677777776777777767777777615151515151515151515151515151515777777767777777677777776777777767777777655050000
00005055766666657666666576666665766666657666666551515151515151515151515151515151766666657666666576666665766666657666666555505000
00050555767676657676766576767665767676657676766515151515151515151515151515151515767676657676766576767665767676657676766555050000
00005055766666657666666576666665766666657666666551515151515151515151515151515151766666657666666576666665766666657666666555505000
00050555766676657666766576667665766676657666766515151515151515151515151515151515766676657666766576667665766676657666766555050000
00005055766666657666666576666665766666657666666551515151515151515151515151515151766666657666666576666665766666657666666555505000
00050555766666657666666576666665766666657666666515151515151515151515151515151515766666657666666576666665766666657666666555050000
00005055655555556555555565555555655555556555555551515151515151515151515151515151655555556555555565555555655555556555555555505000
00050555151515151515151515151515151515151515151515151515151715151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151575757515151515151515151515151515151515151515151515151515151515155505000
0005055515151515151515151515151515151515151515151515151515aaa5151515151515151515151515151515151515151515151515151515151555050000
000050555151515151515151515151515151515151515151515151517aa7aa715151515151515151515151515151515151515151515151515151515155505000
0005055515151515151515151515151515151515151515151515151515aaa5151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151575757515151515151515151515151515151515151515151515151515151515155505000
00050555151515151515151515151515151515151515151515151515151715151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515155505000
00050555151515151515151515151515151515151515151515151515151005151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151515001515151515151515151515151515151515151515151515151515151515155505000
0005055515151515151515151515151515151515151515151515151503bbbb301515151515151515151515151515151515151515151515151515151555050000
0000505551515151515151515151515151515151515151515151515130bbbb035151515151515151515151515151515151515151515151515151515155505000
0005055515151515151515151515151515151515151515151515151503bbbb301515151515151515151515151515151515151515151515151515151555050000
0000505551515151515151515151515151515151515151515151515130b33b035151515151515151515151515151515151515151515151515151515155505000
0005055515151515151515151515151515151515151515151515151503bbbb301515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151305151035151515151515151515151515151515151515151515151515151515155505000
00050555151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515155505000
00050555151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151555050000
00005055515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515155505000
00050555151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151555050000
00000055515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515155000000
00000000151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151500000000
00000000515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515151515100000000
05050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
50505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050
05050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
50505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050
05000000000005000000050505050505050505050505555555555555555555555555555555555555555555050505050505050505050505050505050505050505
505070507070505077705050505050505050505050505bbb0bbb0bbb005000500050005000500050005005505050505750505057505050575050505750505050
050070007070050070700505050505030505030505035bbb0bbb0bbb05050505050505050505050505050505050505aaa50505aaa50505aaa50505aaa5050505
505070507070505077705050505053bbb353bbb353bb5bbb0bbb0bbb00500050005000500050005000500550505050a9a05050a9a05050a9a05050a9a0505050
050070007770050000700505050503333303333303335bbb0bbb0bbb050505050505050505050505050505050505059995050599950505999505059995050505
505077700700505050705050505053b7b353b7b353b75bbb0bbb0bbb005000500050005000500050005005505050509990505099905050999050509990505050
05000000000505050000050505050333330333330333555555555555555555555555555555555555555555050505054945050549450505494505054945050505
50505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050
05050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
50505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050
05050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
50505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050
__gff__
000000000000000000000000000000001b1b1700110020001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1800000000001800000000000018180000000000000000000000001818000000000018000000000000181800000000000000000000000018180000000000180000000000001818000000000000000000000000181800000000001800000000000018180000000000000000000000001818000000000018000000000000180000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000100000000000001000000000000000000000000000000000000010101000001010000010101000001000101000101000101000100000001010101010101010101010100000120000000000000000120000001200001000000000100000120012121212120000000012121212120000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000100000001000000000000000000000000000000000000000000000000000000000001000000000100000000000000000000000000000000000000000
0000000010000000001000000000000000000000000000000000000000001010000000000000101000000000100010101010101000100000001000101000101000101000100000001000101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000
0000000000000000000000000000000000000000101000000000000000000000000000000000000000000000100000000000000000100000000000000000000000000000000000001000100000000000000010001200000000001212000000000012000010120000000000001210000000001000000012120000000000000000
0000000000000000000000000000000000000000101000000000000000000000000000000000000000000000100010101010101000100000101000101000000000101000101000001000100000101010000010000000000000000000000000000000000000000000000000000000000000000000000012120000001000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000100000101010000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000
0000000010000000001000000000000000000000000000000000000000000000001010101000000000000010100000001010000000101000001000101000101000101000100000001000100000000000000010000000120000000000000000120000001200001000000000100000120000000000000000000000000000000000
0000000000000000000000000000000000100000000000001000000000000000000000000000000000000000000000000000000000000000001000000000000000000000100000001000101010101010101010000000000000000000000000000000000000001000000000100000000012121212120000000012121212120000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000101000101000101000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1800000000000000000000000018180000000000180000000000001818000000000000000000000000181800000000001800000000000018180000000000000000000000001818000000000018000000000000181800000000000000000000000018180000000000180000000000001818000000000000000000000000180000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001600000000000000000000160000
0000000000000000000000000000000000000000000000000000000016160000000000000000000000160010100000000000000000101000000000000000000000000000000012001200120012000012001200120012121212000000001212121200000010000014141414000010000016161616160000100000161616160000
0000120000000000000000120000141414141400000000141414141416160010000000000000001000160010100000120000120000101000141414140000141400001414141400000000000000000000000000000012000000000000000000001200000010000000000000000010000000001600000000000000000000160000
0000000000000000000000000000000000000000000000000000000000000000001616161616000000000000000000000000000000000000000000000000000000000000000000001000001000001000001000000012001010101010100000000000120010001200000000120010001200000000001200000000120000000000
0000000010000000001000000000000000000000000000000000000000000000001616161616000000000000000010101010101000000000001600001200000000120000160000000000000000000000000000000012001000000000100000120000000000000000000000000000000000001616161600000000161616000000
0000000000000000000000000000000010000014141414000010000000000000000000000000000000000000000000000000000000000000001600000000000000000000160000001000001000001000001000000000001000161600100000120000000000001600000000160000000000001600000000000000000000160000
0000000010000000001000000000000000000000000000000000000000001616000000000000001616000010100000120000120000101000000000000000000000000000000000000000000000000000000000000000001000000000100000120000000000000000000000000000000000000000001200000000120000000000
0000000000000000000000000000000000000000000000000000000000001616000000000000001616000010100000000000000000101000141400001414141414140000141400001000001000001000001000000012001010101010100000000000120010001200000000120010001200001600000000000000000000160000
0000120000000000000000120000141414141400000000141414141400000000101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012000000000000000000001200000010000000000000000010000016161616160000100000161616160000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012001200120012000012001200120012121212000000001212121200000010000014141414000010000000001600000000000000000000160000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1800000000001800000000000018180000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1210121012000000001210121012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001212000010000010000012120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000141414140000141414140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000010000012000012000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010200001803012025000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200001002500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300003066024653183431063500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000c34008335000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002a43031435000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001c650146430c6350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0103000030751367513c7450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400003055034550375503c5653c545000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000286701e673146630c65306645036250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000223501a643103350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500002444000000244450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0105000030670246731c2631266308655046350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002c340263401e3401433500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000344303a425000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000185501c5501f5502456024555245350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000081520a1520c1620f1620f155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0108000030670286702067318663106630a6550564502625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002c43030435000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000245502b550305650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01050000303502a350243501e34500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01090000185501c5501f550245501d5502155024550295501f55023550265502b55024560285602b5603056030555305350000000000000000000000000000000000000000000000000000000000000000000000
010e00001c0501c045170501704510050100451002500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000c040000001804000000130400000018040000000c0400000018040000001304000000110400000013040000001f040000001a040000001f0400000013040000001f040000001a040000001804000000
01120000150400000021040000001c040000002104000000150400000021040000001c040000001a0400000011040000001d0400000018040000001d0400000011040000001d0400000018040000001604000000
01120000245342453024530245302453024530245302453024534245302453024530245302453024530245302b5342b5302b5302b5302b5302b5302b5302b5302b5342b5302b5302b5302b5302b5302b5302b530
011200002d5342d5302d5302d5302d5302d5302d5302d5302d5342d5302d5302d5302d5302d5302d5302d53029534295302953029530295302953029530295302953429530295302953029530295302953029530
011200002844500000000002b4450000000000304450000000000000002f445000002b4450000000000000002644500000000002b44500000000002f4450000000000000002d445000002b445000000000000000
011200002844500000000002d4450000000000304450000000000000003444500000304450000000000000002444500000000002944500000000002d4450000000000000002b4450000029445000002844500000
011200002b44500000000002844500000000002444500000000000000028445000002b4450000000000000002f44500000000002b4450000000000264450000000000000002b445000002f445000000000000000
011200003044500000000002d4450000000000284450000000000000002d44500000304450000000000000002944500000000002d4450000000000304450000000000000002f4450000000000000003044500000
010f00000c050000001805000000130500000018050000000c0500000018050000001305000000110500000013050000001f050000001a050000001f0500000013050000001f050000001a050000001805000000
010f0000150500000021050000001c050000002105000000150500000021050000001c050000001a0500000011050000001d0500000018050000001d0500000011050000001d0500000018050000001605000000
010f000011050000001d0500000018050000001d0500000011050000001d050000001805000000160500000013050000001f050000001a050000001f0500000013050000001f050000001a050000001805000000
010f00000e050000001a0500000015050000001a050000000e050000001a050000001505000000130500000013050000001f050000001a050000001f0500000013050000001f050000001a050000001805000000
010f0000184201c4201f420244251f4201c420184201c425184201c4201f420244251f4201c420184201c4251f42023420264202b42526420234201f420234251f42023420264202b42526420234201f42023425
010f00002142024420284202d425284202442021420244252142024420284202d425284202442021420244251d42021420244202942524420214201d420214251d42021420244202942524420214201d42021425
010f00001d42021420244202942524420214201d420214251d42021420244202942524420214201d420214251f42023420264202b42526420234201f420234251f42023420264202b42526420234201f42023425
010f00001a4201d4202142026425214201d4201a4201d4251a4201d4202142026425214201d4201a4201d4251f42023420264202b42526420234201f420234251f42023420264202b42526420234201f42023425
010f000028145000002b145000003014500000000002b14528145000002b145000002d145000002b1450000026145000002b145000002f14500000000002b14532145000002f145000002b145000002614500000
010f000028145000002b14500000301450000000000321453414500000321450000030145000002b145000002f145000002b145000002614500000000002b1452f14500000321450000037145000000000000000
010f00002d145000003014500000341450000000000301452d1450000030145000002f145000002d1450000029145000002d145000003014500000000002d14529145000002d145000002b145000002914500000
010f00002d1450000034145000003014500000000002d145341450000030145000002d145000002814500000291450000030145000002d14500000000002914530145000002d1450000029145000002414500000
010f000029145000002d145000003014500000000002d1453514500000341450000030145000002d145000002b145000002f145000003214500000000002f1453714500000351450000032145000002f14500000
010f0000261450000029145000002d145000000000029145321450000030145000002d1450000029145000002b145000002f14500000321450000000000371453714500000000000000032145000002f14500000
010c0000150500000021050000001c050000002105000000150500000021050000001c050000001a0500000010050000001c0500000017050000001c0500000010050000001c0500000017050000001505000000
010c000011050000001d0500000018050000001d0500000011050000001d050000001805000000160500000010050000001c0500000017050000001c0500000010050000001c0500000017050000001505000000
010c00002142024420284202d425284202442021420244252142024420284202d425284202442021420244251c4201f4202342028425234201f4201c4201f4251c4201f4202342028425234201f4201c4201f425
010c00001d42021420244202942524420214201d420214251d42021420244202942524420214201d420214251c4201f4202342028425234201f4201c4201f4251c4201f4202342028425234201f4201c4201f425
010c00002d745000003074500000347450000000000307452d7450000030745000003274500000307450000028745000002c745000002f74500000000002c74534745000002f745000002c745000002874500000
010c00002d74500000347450000039745000000000034745307450000034745000002d74500000000000000028745000002f745000003474500000000002f7452c745000002f7450000028745000000000000000
010c000029745000002d745000003074500000000002d7453574500000347450000030745000002d7450000028745000002c745000002f74500000000002c745347450000032745000002f745000002c74500000
010c0000357450000034745000003074500000000002d7453574500000347450000030745000002d745000002f745000002c745000002874500000000002c7452f74500000347450000038745000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 41181a16
00 41191b17
00 41181c16
02 41191d17
01 4122261e
00 4122271e
00 4123281f
00 4123291f
00 4122261e
00 4122271e
00 41242a20
02 41252b21
01 412e302c
00 412e312c
00 412f322d
02 412f332d

