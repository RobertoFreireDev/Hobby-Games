
-- ==== screen-dump driver: prints frames as hex for png.js ====
_ru=_update
sb=0 spb=0
function btn(b,pl)
 if b==nil then return sb end
 return (sb\(2^b))%2>=1
end
function btnp(b,pl)
 if b==nil then return sb end
 return ((sb\(2^b))%2>=1) and ((spb\(2^b))%2<1)
end

hx="0123456789abcdef"
function dumpscr(tag)
 printh("SCR "..tag)
 for y=0,127 do
  local s=""
  for x=0,127 do
   local p=pget(x,y)+1
   s=s..sub(hx,p,p)
  end
  printh(s)
 end
end

tf=0
function _update()
 tf+=1
 -- dump what pico-8 drew last frame
 if tf==41 then dumpscr("intro-mid") end
 if tf==91 then dumpscr("intro-done") end
 if tf==141 then dumpscr("play") end
 if tf==166 then dumpscr("tween") end
 if tf==600 then dumpscr("win") end
 if tf==681 then dumpscr("lose") end

 sb=0
 if tf==95 then sb=32 end           -- x: start round
 if st==2 and tf==610 then done=true sb=32 end   -- x: new grid
 if done and tf==670 then sel={1,2} ss={} ss[1]=true ss[2]=true sb=16 end
 if st==1 and rv>=63 and #fl==0 then
  if tf==120 then sb=32 end         -- select
  if tf==124 then sb=2 end          -- right
  if tf==126 then sb=2 end          -- right
  if tf==130 then sb=32 end         -- select
  if tf==134 then sb=8 end          -- down
  -- from here on, solve it
  if tf>=150 and tf%40==0 and st==1 and not done then
   local cs=scan(lr or tr)
   if #cs>0 then
    sel={} ss={}
    for c in all(cs[1]) do add(sel,c) ss[c]=true end
    sb=16
   end
  end
 end
 _ru()
 spb=sb
 if tf==700 then
  printh("st="..st)
  extcmd("shutdown")
 end
end
