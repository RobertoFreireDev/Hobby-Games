
-- rule tests (spliced in by tools/test.js). numbers here are written out
-- on purpose - a test that quotes the cart's own constants agrees with
-- whatever the cart believes.
_ru=_update
function _draw() end
ok=0 bad=0
function chk(c,m)
 if c then ok+=1 else bad+=1 printh("FAIL "..m) end
end

-- a clean board: every tile w, player mid-board, exit far away
function setup(w)
 bd={} gt={}
 for i=1,210 do bd[i]=w gt[i]=99 end
 hs={} fl={}
 st=1 bt=0 ft=0 rat=0 hold=0
 pc=7 pr=7 pf=1 mov=10 act=5
 ec=1 er=1 ei=ti(1,1)
end

function tests()
 -- rotation is clockwise: top->right->bottom->left->top
 chk(rotw(1)==2,"rot top to right")
 chk(rotw(2)==4,"rot right to bottom")
 chk(rotw(4)==8,"rot bottom to left")
 chk(rotw(8)==1,"rot left to top")
 chk(rotw(9)==3,"rot left+top to top+right")
 chk(rotw(0)==0,"rot empty tile")
 chk(rotw(15)==15,"rot sealed tile")
 chk(rotw(5)==10,"rot opposite pair")

 -- a clear step costs one movement and turns the player
 setup(0)
 trymv(2)
 chk(pc==8 and pr==7,"step right moves one tile")
 chk(pf==2,"step sets facing")
 chk(mov==9,"step costs 1 mov")
 chk(act==5,"step costs no act")
 chk(#hs==1,"step pushes history")

 -- a blocked press only re-aims, and is free
 setup(15)
 trymv(3)
 chk(pc==7 and pr==7,"blocked press does not move")
 chk(pf==3,"blocked press aims")
 chk(mov==10,"blocked press is free")
 chk(#hs==0,"blocked press writes no history")

 -- either tile's wall blocks, in both directions
 setup(0)
 bd[ti(7,7)]=2
 trymv(2)
 chk(pc==7,"own right wall blocks")
 setup(0)
 bd[ti(8,7)]=8
 trymv(2)
 chk(pc==7,"neighbour left wall blocks")
 setup(0)
 bd[ti(8,7)]=8
 pc=8 trymv(1)
 chk(pc==8,"a one sided wall blocks both ways")

 -- the board edge is hard
 setup(0)
 pc=0 trymv(1)
 chk(pc==0,"cannot walk off the left edge")
 chk(mov==10,"off grid press is free")

 -- x turns the faced tile, through the wall
 setup(0)
 bd[ti(8,7)]=1
 pf=2
 rot()
 chk(bd[ti(8,7)]==2,"x rotates the faced tile")
 chk(act==4,"rotation costs 1 act")
 chk(mov==10,"rotation costs no mov")
 chk(#hs==1,"rotation pushes history")

 -- ...but never the tile you stand on
 setup(0)
 bd[ti(7,7)]=1
 pf=2
 rot()
 chk(bd[ti(7,7)]==1,"own tile never rotates")

 -- rotating an empty tile still costs, and still records
 setup(0)
 pf=2
 rot()
 chk(act==4,"no-op rotation still costs 1 act")
 chk(#hs==1,"no-op rotation still records")

 -- facing off grid: x does nothing at all
 setup(0)
 pc=0 pf=1
 rot()
 chk(act==5,"x off grid costs nothing")
 chk(#hs==0,"x off grid writes no history")

 -- no actions left
 setup(0)
 act=0 pf=2
 rot()
 chk(#hs==0,"x with act 0 is ignored")

 -- rewind puts a rotation back
 setup(0)
 bd[ti(8,7)]=9
 pf=2
 rot()
 rew()
 chk(bd[ti(8,7)]==9,"rewind restores the tile")
 chk(act==5,"rewind refunds the act")
 chk(#hs==0,"rewind pops the entry")

 -- rewind puts a step back, facing and all
 setup(0)
 pf=3
 trymv(2)
 rew()
 chk(pc==7 and pr==7,"rewind restores position")
 chk(pf==3,"rewind restores facing")
 chk(mov==10,"rewind refunds the mov")

 -- rewind with nothing to undo is ignored
 setup(0)
 rew()
 chk(mov==10 and act==5 and pc==7,"rewind on empty history")

 -- out of movements: the stuck state
 setup(0)
 mov=0
 trymv(2)
 chk(pc==7,"no movements left, clear step ignored")
 setup(15)
 mov=0
 trymv(3)
 chk(pf==3,"no movements left, turning still works")
 setup(0)
 mov=0 pf=2
 rot()
 chk(act==5 and #hs==0,"no movements left, x is dead")

 -- reaching the exit wins
 setup(0)
 pc=2 pr=1
 trymv(1)
 chk(pc==1 and pr==1,"stepped onto the exit")
 chk(st==2,"reaching the exit wins")

 -- thick wall: two walls, two rotations, from two sides
 setup(0)
 bd[ti(7,7)]=2
 bd[ti(8,7)]=8
 pf=2
 rot()
 chk(bd[ti(8,7)]==1,"neighbour half of the thick wall turned")
 trymv(2)
 chk(pc==7,"own half of the thick wall still blocks")

 -- restart unwinds everything
 setup(0)
 trymv(2) trymv(2)
 pf=3 rot()
 restart()
 chk(pc==7 and pr==7,"restart returns to the start tile")
 chk(mov==10 and act==5,"restart refunds every counter")
 chk(#hs==0,"restart empties the history")

 -- the maze bag deals all 64 before repeating
 local seen={}
 local dup=0
 for i=1,64 do
  newmz()
  if seen[mzi] then dup+=1 end
  seen[mzi]=true
 end
 chk(dup==0,"bag deals 64 distinct mazes")
 chk(#bag==0,"bag is empty after 64 draws")
 newmz()
 chk(#bag==63,"bag reshuffles when exhausted")

 -- every shipped maze is loadable and sane
 local nb=0
 for m=0,63 do
  loadmz(m)
  if mov<18 or mov>40 then nb+=1 end
  if act<1 or act>12 then nb+=1 end
  if pc==ec and pr==er then nb+=1 end
  if pf<1 or pf>4 then nb+=1 end
  if abs(pc-ec)+abs(pr-er)<16 then nb+=1 end
 end
 chk(nb==0,"all 64 headers in range")
end

tf=0
function _update()
 tf+=1
 if tf==1 then
  tests()
  return
 end
 -- holding o rewinds all the way back (frame driven, real update)
 if tf==2 then
  setup(0)
  trymv(2) trymv(2) trymv(2)
  chk(#hs==3,"three steps recorded")
  sb=16 spb=0
 end
 if tf==60 then
  chk(#hs==0,"holding o unwinds the whole maze")
  chk(pc==7 and mov==10,"held rewind restores the start")
  sb=0
  -- and rewind still works once the maze is won
  setup(0)
  pc=2 pr=1
  trymv(1)
  chk(st==2,"won, ready for the win screen test")
 end
 if tf==63 then sb=16 end
 if tf==64 then sb=0 end
 if tf==66 then
  chk(st==1,"o leaves the win screen")
  chk(pc==2 and pr==1,"rewind steps back off the exit")
  printh("DONE ok="..ok.." fail="..bad)
  extcmd("shutdown")
 end
 _ru()
 spb=sb
end

sb=0 spb=0
function btn(b,pl)
 if b==nil then return sb end
 return (sb\(2^b))%2>=1
end
function btnp(b,pl)
 if b==nil then return sb end
 return ((sb\(2^b))%2>=1) and ((spb\(2^b))%2<1)
end
