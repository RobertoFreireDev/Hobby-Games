-- screenshot harness: dumps intro, level 1 mid-play, level 9 (steel), boss level
sb,spb=0,0
function btn(b) if b==nil then return sb end return (sb\(2^b))%2>=1 end
function btnp(b) return ((sb\(2^b))%2>=1) and ((spb\(2^b))%2<1) end
_ru,_rd=_update,_draw
function _draw() end
function dump()
 _rd()
 for y=0,127 do
  local r=""
  for x=0,127 do r=r..sub("0123456789abcdef",pget(x,y)+1,pget(x,y)+1) end
  printh(r,"shot")
 end
end
srand(3)
tf=0
function _update()
 tf+=1
 sb=0
 if tf==1 then for i=0,2 do dset(i,0) end dset(0,12) dset(1,12340) dset(2,321) sel=7 end
 if tf==30 then dump() end
 if tf==31 then lv=1 start_game() end
 if tf>60 and tf<400 then
  local c=tf%50 if c<15 then sb=4 elseif c<30 then sb=1 else sb=2 end
  if tf%9==0 then sb+=32 end
 end
 if tf==400 then dump() end
 if tf==401 then lv=9 load_level() end
 if tf>420 and tf<700 then sb=(tf%40<20) and 4 or 2 if tf%6==0 then sb+=32 end end
 if tf==700 then dump() end
 if tf==701 then lv=10 load_level() card=0 end
 if tf>720 and tf<900 then sb=(tf%40<20) and 4 or 1 if tf%8==0 then sb+=32 end end
 if tf==900 then dump() end
 if tf==901 then lives=1 lose_life(true) go=60 end
 if tf==905 then dump() extcmd("shutdown") end
 _ru()
 spb=sb
end
