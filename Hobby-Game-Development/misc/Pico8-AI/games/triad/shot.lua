
-- screenshot driver: dumps chosen frames
-- to shot.p8l (128 hex chars per row).
-- shots: title, tutorial 1-3, play, over
hx="0123456789abcdef"
function dump()
 for y=0,127 do
  local s=""
  for x=0,63 do
   local b=peek(0x6000+y*64+x)
   local l=b%16
   local r=b\16
   s=s..sub(hx,l+1,l+1)..sub(hx,r+1,r+1)
  end
  printh(s,"shot")
 end
end

sb=0 spb=0
function btn(b) if b==nil then return sb end return (sb\(2^b))%2>=1 end
function btnp(b) if b==nil then return sb end return ((sb\(2^b))%2>=1) and ((spb\(2^b))%2<1) end

_ru=_update
_rd=_draw
function _draw() end
f=0
function _update()
 f+=1
 sb=0
 if f==5 then sb=16 end   -- o: tutorial
 if f==12 then sb=32 end  -- x: page 2
 if f==18 then sb=32 end  -- x: page 3
 if f==24 then sb=16 end  -- o: back to title
 if f==30 then sb=32 end  -- x: start
 _ru()
 spb=sb
 if f==2 or f==9 or f==15 or f==21 then
  _rd() dump()
 end
 if f==60 then
  -- freeze a lively play frame
  st="play" stt=0
  sel={bt[1][1],bt[1][2]}
  cur=bt[1][3]
  for i=1,9 do ba[i].d=0 end
  for i=1,3 do ka[i].d=0 end
  for i=1,20 do animall() end
  score=1450 dscore=1450 chain=3
 end
 if f==63 then _rd() dump() end
 if f==70 then goover() newrec=true score=1875 end
 if f==95 then _rd() dump() end
 if f>100 then extcmd("shutdown") end
end
