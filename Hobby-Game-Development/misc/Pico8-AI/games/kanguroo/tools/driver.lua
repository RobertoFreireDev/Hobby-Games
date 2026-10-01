
-->8
-- test driver (appended by mkharness.js; not part of the game)

-- fixed test boards. the harness asserts on exact coordinates, so it supplies
-- its own levels instead of riding on whatever the shipped set happens to be:
-- 1 is the mechanics board, 3 the wall-shortened-jump board, 5 the
-- box-drowning board and 7 the far-shore board.
lvls[1]=
"##########".."#........#".."#........#".."#........#"..
"#...b.o..#".."#........#".."#..p.....#".."#........#"..
"#........#".."##########"
lvls[3]=
"##########".."#p.#######".."#..#######".."#..#######"..
"#..#######".."#..#######".."#..#######".."#........#"..
"#....b.o.#".."##########"
lvls[5]=
"##########".."#p.......#".."#........#".."#..~~~~..#"..
"#..~~~~..#".."#........#".."#....b...#".."#........#"..
"#....o...#".."##########"
lvls[7]=
"##########".."#..p.....#".."#........#".."#........#"..
"#~~~~~~~~#".."#..#.....#".."#........#".."#....b...#"..
"#....o...#".."##########"

_rd=_draw
_ru=_update60
sb=0
spb=0
tf=0
qi=1
wait=0
fails=0

function btn(b,pl)
 if b==nil then return sb end
 return (sb\(2^b))%2>=1
end

function btnp(b,pl)
 if b==nil then return sb end
 return ((sb\(2^b))%2>=1) and ((spb\(2^b))%2<1)
end

-- the real _draw is left in place so stat(1) measures real render cost

hexs="0123456789abcdef"

function shot(tag)
 _rd()
 printh("shot "..tag.." cpu="..stat(1))
 for y=0,127 do
  local s=""
  for x=0,127 do
   local c=pget(x,y)
   s=s..sub(hexs,c+1,c+1)
  end
  printh("px "..s)
 end
end

function ok(c,m)
 if not c then
  fails+=1
  printh("FAIL "..m)
 else
  printh("ok "..m)
 end
end

function q(b,f,h)
 add(scr,{b=b,f=f,h=h})
end

scr={}
-- intro
q(0,function()
 for i=0,15 do dset(i,0) end
 ok(sc=="intro","start scene is intro")
 shot("intro")
end)
q(32)
q(0,function() ok(sc=="levels","x leaves intro") shot("levels") end)
-- level 1: jump, undo, then solve it
q(32)
q(0,function()
 ok(sc=="game","x starts a level")
 ok(lv==1,"level 1 selected")
 ok(#bx==1,"level 1 has 1 box")
 ok(pl.x==3 and pl.y==6,"player start 3,6")
 shot("game")
end)
q(4)
q(0,function() ok(pl.x==3 and pl.y==4,"up jumps 2 tiles") end)
q(32)
q(0,function()
 ok(pl.x==3 and pl.y==6,"x undoes the jump")
 ok(#us==0,"undo stack emptied")
end)
q(4)
q(2)
q(0,function()
 ok(pl.x==4 and pl.y==4,"push moves player 1 tile")
 ok(bx[1].x==5 and bx[1].y==4,"push moves the box 1 tile")
 shot("push")
end)
q(2)
q(0,function()
 ok(bx[1].x==6 and bx[1].y==4,"box reached the goal")
 ok(won(),"level counts as won")
end)
q(0,function()
 ok(sc=="levels","win returns to level select")
 ok(dget(0)==1,"level 1 recorded as cleared")
 ok(unl(1),"level 2 unlocked")
 shot("cleared")
end)
-- the title screen's "reset progress" menu entry
q(0,function()
 resetsave()
 ok(dget(0)==0,"reset clears the cleared flag")
 ok(not unl(1),"reset relocks level 2")
 ok(unl(0),"level 1 stays unlocked after a reset")
end)
-- level 3: bumping into a wall
q(0,function()
 for i=0,15 do dset(i,1) end
 cd=2
end)
q(32)
q(0,function() ok(lv==3,"cursor picks level 3") end)
q(2)
q(0,function() ok(pl.x==2 and pl.y==1,"wall shortens the jump to 1 tile") end)
q(0,function() bu=#us end)
q(2)
q(0,function()
 ok(pl.x==2 and pl.y==1,"blocked move does not move the player")
 ok(#us==bu,"blocked move pushes no undo state")
end)
-- level 7: the far-shore wall drowns you
q(0,function() sc="levels" bk=true cd=6 end)
q(32)
q(0,function() ok(lv==7,"level 7 started") shot("lake") end)
q(8)
q(0,function() ok(pl.x==3 and pl.y==3,"crossed to row 3") end)
q(8,nil)
q(0,function()
 ok(skp,"the player was the one sinking")
end)
q(0,function()
 ok(pl.x==3 and pl.y==1,"death reloads the level")
 ok(dead==0,"death timer cleared")
 ok(#us==0,"undo stack cleared on death")
end)
-- box in water loses too
q(0,function()
 lv=5
 loadlev()
 pl.x=5 pl.y=6
 bx[1].x=5 bx[1].y=5
 try(2)
end)
q(0,function()
 ok(sk!=nil and not skp,"the box was the one sinking")
end)

q(0,function() ok(stat(16)==35 or stat(17)==35,"game music bed is on a music channel, got "..stat(16)..","..stat(17)..","..stat(18)..","..stat(19)) end)
-- hold O to restart: move first, then hold
q(0,function() lv=1 loadlev() end)
q(4)
q(0,function() ok(pl.y==4,"moved before the restart hold") end)
q(16,nil,130)
q(0,function()
 ok(pl.x==3 and pl.y==6,"holding o restarts the level")
 ok(#us==0,"restart clears the undo stack")
end)
q(0,function() sc="levels" bk=true end)
q(0,function() ok(stat(16)==32 or stat(17)==32,"menu music bed is on a music channel, got "..stat(16)..","..stat(17)) end)

function _update60()
 tf+=1
 spb=sb
 sb=0
 if wait>0 then
  wait-=1
  sb=hb
 elseif an==nil and (dead or 0)==0 and (winf or 0)==0 then
  local e=scr[qi]
  if e==nil then
   printh("done fails="..fails.." frames="..tf)
   extcmd("shutdown")
   return
  end
  qi+=1
  if e.f then e.f() end
  sb=e.b
  hb=e.b
  wait=e.h or 0
 end
  _ru()
 if tf%60==0 then printh("cpu "..sc.." "..stat(1)) end
 if winf==60 then
  ok(winf>0,"win animation runs")
  shot("win")
 end
 if dead==30 then
  sk=snkr
  skp=(snkr==pl)
  sn=(sn or 0)+1
  shot("sink"..sn)
 end
 if tf>3000 then
  printh("done timeout fails="..fails)
  extcmd("shutdown")
 end
end
