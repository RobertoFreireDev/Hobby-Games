
-- ==== smoke driver: runs the REAL _update and the REAL _draw ====
-- _draw is deliberately NOT overridden, so pico-8 keeps calling the
-- game's own renderer; pget checks read the previous frame's screen.
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

sc=0 sf=0
function sok(c,m)
 sc+=1
 if not c then
  sf+=1
  printh("SMOKE FAIL: "..m)
 end
end

-- non-black pixels in a region
function ink(x0,y0,x1,y1)
 local n=0
 for y=y0,y1 do
  for x=x0,x1 do
   if pget(x,y)!=0 then n+=1 end
  end
 end
 return n
end

-- the cursor cell's 2x digit box
function curx() return 4+((cur-1)%11)*11+2 end
function cury() return 5+((cur-1)\11)*11+1 end

tf=0
sawgrid=0 sawfly=0 sawcur=0 sawmsg=0 wins=0 loses=0
function _update()
 tf+=1

 -- ---- observe the frame pico-8 just drew ----
 if tf==50 then
  sok(ink(20,20,108,110)>40,"intro drew nothing")
 end
 if st==1 and rv>=110 then
  sawgrid=max(sawgrid,ink(4,5,124,114))
  sawcur=max(sawcur,ink(curx(),cury(),curx()+7,cury()+9))
 end
 if st==1 and #fl>0 then
  sawfly=max(sawfly,ink(0,100,127,114))
 end
 if st>1 then
  sawmsg=max(sawmsg,ink(0,116,127,122))
 end

 sb=0
 -- ---- scripted input ----
 if tf==60 then sb=32 end          -- x: skip the trace
 if tf==64 then sb=32 end          -- x: start the round
 if st==1 and rv>=110 and #fl==0 then
  if tf%60==10 then sb=2 end       -- right
  if tf%60==14 then sb=8 end       -- down
  if tf%60==18 then sb=32 end      -- x: select
  if tf%60==22 then sb=32 end      -- x: deselect
  if tf%60==26 then sb=16 end      -- o: submit 0 cells, must be ignored
  -- submit a real instance
  if tf%60==40 then
   local cs=scan(tr)
   if #cs>0 then
    sel={} ss={}
    for c in all(cs[1]) do add(sel,c) ss[c]=true end
    sb=16
   end
  end
 end
 if st==2 and tf%60==30 then
  wins+=1
  sb=32                            -- x: new grid after a win
 end
 if st==3 then
  loses+=1
  if tf%60==30 then sb=32 end
 end

 _ru()
 spb=sb

 if tf==900 then
  sok(sawgrid>100,"grid drew nothing: "..sawgrid)
  sok(sawcur>0,"cursor cell drew nothing: "..sawcur)
  sok(sawfly>0,"no digit ever drew on the flight path")
  sok(sawmsg>0,"win/lose banner never drew")
  sok(wins>0,"never reached a win")
  sok(loses==0,"lost a scripted round")
  printh("wins="..wins.." loses="..loses)
  printh("SMOKE="..sc.." SFAILS="..sf)
  extcmd("shutdown")
 end
end
