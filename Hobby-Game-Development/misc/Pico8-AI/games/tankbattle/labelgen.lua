-- label harness: staged battle scene with the logo over it
_ru,_rd=_update,_draw
function btn() return false end
function btnp() return false end
function _draw() end
srand(5)
tf=0
function _update()
 tf+=1
 if tf==1 then
  lives,score,dscore,tkills=3,0,4250,0
  state="game" lv=9 load_level() music(-1)
  add_enemy(1,1,2).d=3 add_enemy(3,11,2).d=3 add_enemy(2,4,5).d=3
  add_enemy(4,9,4).d=4 add_enemy(1,12,7).d=4
  kills=7 spt=15 tele=spc[1]
  p.cx,p.cy,p.ox,p.oy,p.x,p.y,p.d=6,11,6,11,48,88,1
  p.mf=3 add(buls,{x=52,y=70,dx=0,dy=-1,pl=true,bnc=0,sp=4})
  add(buls,{x=36,y=40,dx=0,dy=1,pl=false,bnc=0,sp=2})
  boom(84,48,1) booms[1].f=2
  _rd()
  palt(0,false) palt(15,true)
  sspr(0,80,70,30,29,20)
  printh("@@begin")
  for y=0,127 do
   local r=""
   for x=0,127 do r=r..sub("0123456789abcdef",pget(x,y)+1,pget(x,y)+1) end
   printh(r)
  end
  printh("@@end")
  extcmd("shutdown")
 end
end
