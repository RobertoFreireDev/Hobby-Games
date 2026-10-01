
-- ==== tutorial driver: real _update, real _draw ====
_ru=_update
sb=0 spb=0
function btn(b,p)
 if b==nil then return sb end
 return (sb\(2^b))%2>=1
end
function btnp(b,p)
 if b==nil then return sb end
 return ((sb\(2^b))%2>=1) and ((spb\(2^b))%2<1)
end

zc=0 zf=0
function zok(c,m)
 zc+=1
 if not c then zf+=1 printh("TUT FAIL: "..m) end
end

function ink(x0,y0,x1,y1)
 local n=0
 for y=y0,y1 do
  for x=x0,x1 do
   if pget(x,y)!=0 then n+=1 end
  end
 end
 return n
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

 if tf==1 then
  -- ---- shape table ----
  zok(#sh==20,"shape count "..#sh)
  local nl,nb,nk=0,0,0
  local seen={}
  for s in all(sh) do
   local e=0
   local m=0
   for a=1,3 do
    zok(s[a][1]>=0 and s[a][1]<=2
     and s[a][2]>=0 and s[a][2]<=2,"cell off the 3x3 box")
    m+=2^(s[a][2]*3+s[a][1])
    for b=a+1,3 do
     local dx=abs(s[a][1]-s[b][1])
     local dy=abs(s[a][2]-s[b][2])
     zok(dx+dy>0,"duplicate cell in a shape")
     if max(dx,dy)==1 then e+=1 end
    end
   end
   zok(e>=2,"shape is not a chain")
   zok(not seen[m],"duplicate shape "..m)
   seen[m]=true
   if s.n=="line" then nl+=1
   elseif s.n=="block" then nk+=1
   else nb+=1 end
  end
  zok(nl==4,"lines "..nl)
  zok(nk==4,"blocks "..nk)
  zok(nb==12,"bends "..nb)
  printh("NSH="..#sh.." LINE="..nl.." BLOCK="..nk.." BEND="..nb)

  -- ---- the tutorial digits obey the rules they claim ----
  zok(vok(pd[1],pd[2],pd[3],1),"row 1 is not equals")
  zok(vok(pd[4],pd[5],pd[6],2),"row 2 is not 1 delta")
  zok(vok(pd[7],pd[8],pd[9],3),"row 3 is not same hue")
  zok(not vok(pd[7],pd[8],pd[9],1),"row 3 is all equal")
 end

 sb=0
 -- ---- 🅾️ on the intro opens the tutorial ----
 if tf==4 then sb=16 end
 if tf==6 then zok(st==4,"o did not open the tutorial: st="..st) end
 -- ---- ➡️ flips the page ----
 if tf==8 then sb=2 end
 if tf==10 then zok(tp==2,"right did not flip the page") end
 if tf==12 then sb=2 end
 if tf==14 then zok(tp==1,"right did not flip back") end
 -- ---- 🅾️ returns to a finished intro ----
 if tf==16 then sb=16 end
 if tf==18 then
  zok(st==0,"o did not leave the tutorial")
  zok(it>=sn*3,"intro trace restarted")
  zok(ink(20,100,108,124)>40,"intro drew no buttons")
 end

 -- ---- screen dumps: hold the state
 -- across a window, since -x skips
 -- draws and the dump lags them
 if tf>=20 and tf<26 then st=4 tp=1 tt=70 end
 if tf==26 then dumpscr("tut-shapes") end
 if tf>=30 and tf<36 then st=4 tp=1 tt=20 end
 if tf==36 then dumpscr("tut-shapes-reveal") end
 if tf>=40 and tf<46 then st=4 tp=2 tt=35 end
 if tf==46 then dumpscr("tut-rules") end
 if tf>=50 and tf<56 then st=4 tp=2 tt=44 end
 if tf==56 then dumpscr("tut-rules-flash") end
 if tf>=60 and tf<66 then st=0 it=999 end
 if tf==66 then dumpscr("intro") end
 _ru()
 spb=sb


 if tf==80 then
  printh("TUT="..zc.." TFAILS="..zf)
  extcmd("shutdown")
 end
end
