pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- moonfall
-- by roberto freire

-- screens
-- 0 intro  1 menu  2 how to
-- 3 brief  4 board 5 dialog
-- 6 notebook 7 accuse 8 verdict

function _init()
 cartdata("moonfall_rf1")
 nm=split"bela,mara,otto,vesna,dragan,luka,iris,stefan"
 lmn=split"CHAPEL,MILL,INN,FORGE,GRAVEYARD,MANOR,WATCHTOWER,WELL,MOUNTAIN,FOREST,LAKE"
 hue=split"7,3,4,9,8,5,2,12"
 hhi=split"7,11,9,10,14,6,13,6"
 hlo=split"5,1,2,4,2,1,1,1"
 plt=split(pltd,"|",false)
 wit=split(witd,"|",false)
 sgn=split(sgnd,"|",false)
 rmps=split(rmpd,"|",false)
 night=mid(1,dget(0),32)
 menuitem(1,"clear progress",clearsave)
 fr=0
 setscr(0)
end

function clearsave()
 dset(0,1) night=1
end

function setscr(s)
 scr=s
 it=0
 if s==1 then mi=1 end
 if s==2 then hpage=1 end
 if s==6 then npage=1 end
 if s==7 then ai=1 confirm=false end
end

function _update60()
 fr+=1
 it+=1
 if scr==0 then upintro()
 elseif scr==1 then upmenu()
 elseif scr==2 then uphow()
 elseif scr==3 then upbrief()
 elseif scr==4 then upboard()
 elseif scr==5 then updlg()
 elseif scr==6 then upnote()
 elseif scr==7 then upacc()
 else upverd() end
end

function _draw()
 pal()
 if scr>=3 and scr<=7 then setramp() end
 if scr==0 then dwintro()
 elseif scr==1 then dwintro() dwmenu()
 elseif scr==2 then dwhow()
 elseif scr==3 then dwboard() dwbrief()
 elseif scr==4 then dwboard() dwhud()
 elseif scr==5 then dwboard() dwdlg()
 elseif scr==6 then dwnote()
 elseif scr==7 then dwboard() dwacc()
 else dwverd() end
end

-->8
-- intro & menu

function upintro()
 if it==1 then music(16) end
 if it==200 then sfx(20) end
 if scr==0 and (btnp(4) or btnp(5) or it>560) then
  setscr(1)
 end
end

function dwintro()
 cls(1)
 -- 1/13 gradient sky, dithered through the middle
 fillp(0b1010010110100101)
 rectfill(0,44,127,79,0xd1)
 fillp()
 rectfill(0,80,127,127,13)

 -- the moon rises out of the bottom of the frame
 local my=max(40,132-it*0.3)
 circfill(64,my,19,14)
 circfill(64,my,17,7)
 circfill(58,my-5,3,6)
 circfill(68,my+4,4,6)
 circfill(62,my+7,2,6)

 -- village and castle, then a nearer treeline at twice the speed
 local o=min(it,150)
 skyline(180-o*1.1,100,0)
 treeline(200-o*2.2,116,0)

 -- a bat crosses the moon
 if it>170 and it<300 then
  local bx=(it-170)*1.4
  local by=my-14+sin(it/60)*8
  local w=2+sin(it/6)*2
  line(bx-4,by-w,bx,by,0)
  line(bx,by,bx+4,by-w,0)
 end

 -- title drops in a letter at a time
 for i=1,8 do
  local d=it-300-i*7
  if d>0 then
   local y=48+min(0,-40+d*4)
   local c=sub("moonfall",i,i)
   bigch(c,26+(i-1)*10,y+2,2)
   bigch(c,26+(i-1)*10,y,8)
  end
 end
 if it>400 then
  local s="one of them is lying"
  print(s,64-#s*2,80,min(6,(it-400)\12))
 end
end

-- a doubled-size glyph, drawn from the p8scii wide+tall modes
function bigch(c,x,y,col)
 print("\^w\^t"..c,x,y,col)
end

function skyline(ox,base,c)
 local d=split"0,26,30,10,10,18,22,8,26,34,14,4,44,10,16,12,54,8,10,20,62,14,26,6,76,10,12,16,86,20,18,10"
 for i=1,#d,4 do
  local x=ox+d[i]
  rectfill(x,base-d[i+2],x+d[i+1],127,c)
 end
 -- the keep, with battlements
 rectfill(ox+26,base-34,ox+40,127,c)
 for i=0,3 do
  rectfill(ox+26+i*4,base-38,ox+28+i*4,base-34,c)
 end
end

function treeline(ox,base,c)
 for i=0,11 do
  local x=ox+i*14
  local h=8+(i%3)*4
  for j=0,3 do
   local w=6-j
   rectfill(x-w,base-j*3-h,x+w,base-j*3-h+4,c)
  end
  rectfill(x-1,base-h,x+1,127,c)
 end
end

mitems=split("play|how to play|clear progress","|",false)

function upmenu()
 if btnp(2) then mi=max(1,mi-1) sfx(13) end
 if btnp(3) then mi=min(3,mi+1) sfx(13) end
 if btnp(4) then
  sfx(14)
  if mi==1 then
   loadnight(night) setscr(3)
  elseif mi==2 then
   setscr(2)
  else
   clearsave()
  end
 end
end

function dwmenu()
 panel(28,52,100,94)
 for i=1,3 do
  local y=58+(i-1)*10
  print(mitems[i],40,y,i==mi and 7 or 5)
  if i==mi then print(">",33,y,8) end
 end
 print("night "..night.." / 32",40,88,6)
end

function uphow()
 if btnp(0) then hpage=hpage>1 and hpage-1 or 5 sfx(12) end
 if btnp(1) then hpage=hpage<5 and hpage+1 or 1 sfx(12) end
 if btnp(4) or btnp(5) then sfx(15) setscr(1) end
end

-- pages 3-5 are the legend: every tile the board can show, named, so the
-- notebook's words map onto the art without the player having to guess
function dwhow()
 cls(0)
 print(htl[hpage],6,6,8)
 if hpage<3 then
  local ls=split(split(howd,"/",false)[hpage],"|",false)
  for i=1,#ls do print(ls[i],6,18+(i-1)*7,6) end
 elseif hpage==3 then
  for i=1,8 do
   local x,y=6+((i-1)%2)*62,18+((i-1)\2)*22
   lmtile(i,x,y)
   print(lmn[i],x+19,y+5,7)
  end
  print("buildings block your way.",6,108,5)
 elseif hpage==4 then
  for i=1,4 do
   local y=18+(i-1)*22
   if i<4 then
    lmtile(i+8,6,y)
   else
    pal(3,0) spr(72,6,y-2,2,2) pal()
   end
   print(i<4 and lmn[i+8] or "you",25,y+3,7)
   print(natd[i],25,y+11,6)
  end
 else
  for i=1,8 do
   local x,y=2+((i-1)%4)*32,20+((i-1)\4)*42
   vpal(i,5)
   spr((i-1)*2,x+8,y,2,2)
   pal()
   print(nm[i],x+16-#nm[i]*2,y+18,7)
  end
  print("one of them is lying.",6,108,5)
 end
 print("⬅️➡️ page "..hpage.."/5   🅾️ back",6,118,5)
end

-- a board tile as the board itself draws it: ground first, then the landmark
function lmtile(v,x,y)
 palt(0,false)
 spr(70,x,y,2,2)
 spr(lmspr(v),x,y,2,2)
 palt()
end

-->8
-- board, clock, hud

function loadnight(n)
 local o=(n-1)*77
 wolf=d32(nig,o+1)
 local li=d32(nig,o+2)
 site=d32(nig,o+3)
 tellv=d32(nig,o+4)
 tellc=d32(nig,o+5)+1

 local lo=(li-1)*36
 cells={} lmc={} vcl={}
 for i=0,35 do
  local v=d32(lay,lo+i+1)
  cells[i]=v
  if v>=1 and v<=11 then lmc[v]=i
  elseif v>=12 and v<=19 then vcl[v-11]=i
  elseif v==20 then pcell=i end
 end

 stm={} claim={} heard={}
 nheard=0
 for v=1,8 do
  stm[v]={}
  local b=o+5+(v-1)*9
  for k=0,2 do
   local t=d32(nig,b+k*3+1)
   if t<3 then
    add(stm[v],{t,d32(nig,b+k*3+2),d32(nig,b+k*3+3)})
   end
  end
  claim[v]=stm[v][1][2]
  heard[v]=false
 end
 tk=0
 mstate=-1
end

function d32(s,i)
 local c=ord(s,i)
 return c<58 and c-48 or c-87
end

-- landmarks 1-8 are buildings, 9-11 nature
function lmspr(v)
 return v<9 and 30+v*2 or 46+v*2
end

function cellx(c) return 16+(c%6)*16 end
function celly(c) return 6+(c\6)*16 end

function vat(c)
 for v=1,8 do
  if vcl[v]==c then return v end
 end
end

function upbrief()
 if btnp(4) then sfx(14) setscr(4) music(0) mstate=0 end
end

function dwbrief()
 panel(6,40,122,88)
 local ls=wrap("wilhelm was found at the "..lmn[site]..". he was cold before the bell.",26)
 for i=1,#ls do print(ls[i],12,48+(i-1)*8,7) end
 print("night "..night.." / 32",12,72,6)
 print("🅾️ walk out",12,80,5)
end

function upboard()
 -- nightfall forces the accusation
 if tk>=40 then setscr(7) return end
 if btnp(5) then sfx(12) setscr(6) return end
 if btnp(4) then
  local v=vat(pcell)
  if v then opendlg(v) else sfx(1) end
  return
 end
 for i=0,3 do
  if btnp(i) then trymove(i) return end
 end
end

function trymove(d)
 local x,y=pcell%6,pcell\6
 if d==0 then x-=1
 elseif d==1 then x+=1
 elseif d==2 then y-=1
 else y+=1 end
 if x<0 or x>5 or y<0 or y>5 then sfx(1) return end
 local c=y*6+x
 if cells[c]>=1 and cells[c]<=11 then sfx(1) return end
 pcell=c
 addtick(1)
 sfx(0)
end

function addtick(n)
 local h=tk\4
 tk=tk+n
 if tk\4>h and tk<40 then sfx(16) end
 -- the day rots audibly: four states, crossfaded
 local m=tk>=38 and 12 or tk>=32 and 8 or tk>=20 and 4 or 0
 if m~=mstate then
  mstate=m
  music(m,800)
 end
end

-- 11/12/13 are the cloak ramp, 3 is the outline that carries state
function vpal(v,o)
 pal(11,hhi[v])
 pal(12,hue[v])
 pal(13,hlo[v])
 pal(3,o)
end

function dwboard()
 cls(0)
 palt(0,false)
 for i=0,35 do
  local x,y,v=cellx(i),celly(i),cells[i]
  spr(70,x,y,2,2)
  if v>=1 and v<=11 then spr(lmspr(v),x,y,2,2) end
 end
 palt()
 for v=1,8 do
  vpal(v,heard[v] and 5 or 0)
  spr((v-1)*2,cellx(vcl[v]),celly(vcl[v]),2,2)
  pal()
 end
 if scr==4 or scr==5 then
  pal(3,0)
  spr(72,cellx(pcell),celly(pcell)-2,2,2)
  pal()
 end
end

function dwhud()
 rectfill(0,102,127,127,0)
 line(0,102,127,102,5)
 print("night "..night.."/32",4,106,6)
 print("❎ notebook",76,106,5)

 -- an analogue face, so the hand sweeps rather than ticks
 local cx,cy=8,118
 circ(cx,cy,3,6)
 local a=tk/40
 line(cx,cy,cx+2.5*cos(a),cy+2.5*sin(a),7)
 print(clockstr(),15,116,tk>=32 and 8 or 7)

 -- sun before 16:00, moon after
 if tk>=32 then
  circfill(44,118,3,7) circfill(46,117,3,0)
 else
  circfill(44,118,2,10)
 end
 print("heard "..nheard.."/8",58,116,6)
 if vat(pcell) then print("🅾️ talk",96,116,10) end
end

function clockstr()
 local m=480+tk*15
 local h=m\60
 local r=m%60
 return (h<10 and "0" or "")..h..":"..(r==0 and "00" or r)
end

-- the whole screen darkens on the display palette, so no draw code changes
function setramp()
 local s=rmps[tk>=40 and 5 or tk>=38 and 4 or tk>=34 and 3 or tk>=28 and 2 or 1]
 for c=0,15 do
  pal(c,d32(s,c+1),1)
 end
end

function panel(x0,y0,x1,y1)
 fillp(0b1010010110100101)
 rectfill(x0,y0,x1,y1,0)
 fillp()
 rect(x0,y0,x1,y1,5)
 rect(x0+1,y0+1,x1-1,y1-1,0)
 line(x0+1,y0+1,x1-1,y0+1,7)
 line(x0+1,y0+1,x0+1,y1-1,7)
end

-->8
-- dialog & notebook

function ctext(v,c)
 local t=c[1]
 if t==0 then return fill(plt[v],"",lmn[c[2]]) end
 if t==1 then return fill(wit[v],nm[c[2]],lmn[c[3]]) end
 return fill(sgn[c[2]*4+(v-1)%4+1],"",c[3]>0 and lmn[c[3]] or "")
end

function fill(s,n,l)
 local o=""
 for i=1,#s do
  local c=sub(s,i,i)
  o=o..(c=="~" and n or c=="^" and l or c)
 end
 return o
end

function wrap(s,w)
 local ls,ln={},""
 for wd in all(split(s," ",false)) do
  local t=ln=="" and wd or ln.." "..wd
  if #t>w then add(ls,ln) ln=wd else ln=t end
 end
 add(ls,ln)
 return ls
end

function opendlg(v)
 dv=v
 if not heard[v] then
  heard[v]=true
  nheard+=1
 end
 addtick(2)
 setpage(1)
 setscr(5)
 sfx(2)
end

function setpage(p)
 dpage=p
 dtick=0
 dlines=wrap(ctext(dv,stm[dv][p]),22)
 dtotal=0
 for l in all(dlines) do dtotal+=#l end
end

function updlg()
 local shown=dtick\2
 if shown<dtotal then
  dtick+=1
  if dtick%6==0 then sfx(3+dv) end
  if btnp(4) then dtick=dtotal*2 end
  return
 end
 if btnp(4) then
  if dpage<#stm[dv] then
   sfx(12) setpage(dpage+1)
  else
   sfx(3) setscr(4)
  end
 elseif btnp(5) then
  sfx(3) setscr(4)
 end
end

function dwdlg()
 -- portrait, at twice the board size so board and portrait never disagree
 local px,py=88,8
 rectfill(px-2,py-2,px+33,py+41,0)
 rect(px-2,py-2,px+33,py+41,5)
 line(px-2,py-2,px+33,py-2,7)
 line(px-2,py-2,px-2,py+41,7)
 vpal(dv,5)
 sspr(((dv-1)%8)*16,0,16,16,px,py,32,32)
 pal()
 print(nm[dv],px,py+34,7)

 panel(4,46,124,98)
 local n=dtick\2
 for i=1,#dlines do
  local l=dlines[i]
  if n<=0 then break end
  print(sub(l,1,min(n,#l)),9,52+(i-1)*8,7)
  n-=#l
 end
 print(dpage.."/"..#stm[dv],108,90,5)
 if dtick\2>=dtotal then print("🅾️",96,90,6) end
end

function upnote()
 if btnp(0) or btnp(1) then npage=3-npage sfx(12) end
 if btnp(5) then sfx(15) setscr(4) end
 if btnp(4) then sfx(14) setscr(7) end
end

function dwnote()
 cls(0)
 rect(2,2,125,110,5)
 print(npage==1 and "claims" or "sightings",6,7,8)

 if nheard==0 then
  print("you have heard nobody yet.",6,22,6)
 elseif npage==1 then
  local y=20
  for v=1,8 do
   if heard[v] then
    rectfill(6,y,10,y+4,hue[v])
    print(nm[v],14,y,7)
    print(lmn[claim[v]],54,y,6)
    y+=11
   end
  end
 else
  local y=20
  for v=1,8 do
   if heard[v] then
    for c in all(stm[v]) do
     if c[1]==1 and y<100 then
      -- who said it matters as much as what was said, so the speaker is
      -- named rather than left to the hue pip alone
      local clash=heard[c[2]] and claim[c[2]]~=c[3]
      rectfill(6,y,10,y+4,hue[v])
      print(nm[v],13,y,6)
      print(">",40,y,5)
      -- a clash is drawn red, but never labelled a lie: which side
      -- is lying is the player's call, not the notebook's
      print(nm[c[2]],46,y,clash and 8 or 7)
      print(lmn[c[3]],73,y,clash and 8 or 6)
      y+=11
     end
    end
   end
  end
  if y==20 then print("no sightings recorded.",6,22,6) end
 end
 print("⬅️➡️ page  ❎ back  🅾️ accuse",4,116,5)
end

-->8
-- accuse & verdict

function upacc()
 if confirm then
  if btnp(4) then
   sfx(19) guilty=ai setscr(8)
   music(-1)
   sfx(guilty==wolf and 22 or 20)
  elseif btnp(5) then
   confirm=false sfx(15)
  end
  return
 end
 if btnp(0) then ai=ai>1 and ai-1 or 8 sfx(13) end
 if btnp(1) then ai=ai<8 and ai+1 or 1 sfx(13) end
 if btnp(4) then confirm=true sfx(14) end
 if btnp(5) and tk<40 then sfx(15) setscr(6) end
end

function dwacc()
 panel(4,20,124,100)
 local s=tk>=40 and "the moon is up. name them." or "who fed at the well?"
 print(s,64-#s*2,26,8)

 for i=1,8 do
  local x=10+(i-1)*14
  vpal(i,i==ai and 8 or 5)
  sspr(((i-1)%8)*16,0,16,16,x,40,13,13)
  pal()
  if heard[i] then print("·",x+5,54,6) end
 end
 print(nm[ai],64-#nm[ai]*2,62,7)
 print(heard[ai] and lmn[claim[ai]] or "you never heard them",
       64-#(heard[ai] and lmn[claim[ai]] or "you never heard them")*2,70,6)

 if confirm then
  print("name them before the moon?",12,84,8)
  print("🅾️ yes    ❎ no",34,92,6)
 else
  print("⬅️➡️ choose  🅾️ accuse",18,92,5)
 end
end

function upverd()
 if it<60 then return end
 if btnp(4) then
  if guilty==wolf then
   night=min(32,night+1)
   dset(0,night)
  end
  loadnight(night)
  setscr(3)
 elseif btnp(5) then
  loadnight(night)
  setscr(3)
 end
end

function dwverd()
 local win=guilty==wolf
 cls(win and 1 or 0)
 if not win then
  -- night falls, and the moon keeps what it took
  circfill(64,30,16,2)
  if it%20<10 then circfill(64,30,14,1) end
 else
  circfill(64,30,16,6)
  circfill(64,30,14,7)
 end

 vpal(wolf,win and 5 or 8)
 sspr(((wolf-1)%8)*16,0,16,16,56,52,16,16)
 pal()

 local h=win and "the village takes them." or "night falls. it feeds again."
 print(h,64-#h*2,74,win and 11 or 8)
 print(nm[wolf].." was the wolf.",64-#(nm[wolf].." was the wolf.")*2,84,7)

 -- always show the tell: a deduction game that hides its
 -- solution teaches nothing
 local ls=wrap(nm[tellv]..": "..ctext(tellv,stm[tellv][tellc]),30)
 for i=1,#ls do print(ls[i],6,96+(i-1)*7,6) end
 if it>60 then
  print(win and "🅾️ next night" or "🅾️ go on   ❎ retry",6,118,5)
 end
end

-->8
-- data

--<data>
lay="72000a3d00k08c4i0j00g9010b50f600eh00a8c003j0007100k060ed0hg040005f00b29i0000d4hi000f0b8050g0061c39020jak00e700j0g8e00d060bi032500100ac00k740f9h02bg01e5k000000080f06c0a4h070i03j00d900i2e4abj000gf006ch0900dk0705000813004029kd003e0a0h7000010g00c0f058ij60b0c07380h00efg00a900k000jb40i26100d05"
nig="3123106015a22005018b21403020916807021a15a0a022014708020317404018b2180b01322154136104016821805016820b06020118a0902111710201432170801432170101362060a015221162b6101020312707015920104021a14a0a013421809016b2120602181590202091590302181118278101020714306017921504022015a0301112180a021313402021b17909018721b05011121623a810b015322008013220b02017621605016421103012a23004018722006018720207012a2201311102013121607021a16a03021a18904015521705011121b0a01332200801332150902121786281103016821a04014a2150601132200a016821801011320305021612409018b2050b0212179544510a015421408018722005011a21a0b013521303023017206018720802022016607011a2127467104020a3000501613000801763000a015730007013830001012530003014a3000902143008158104018530008016330002011430001017a3000b01283000302173000a0132300090125300358410901833000a016730001012a300060138300040119300070138300020183300030146300459410801343000b018130004014930002021730003016630006017730007011830001021230053b5101021530005021830006015b300080136300030164300040125300070182300020148300263210101233000801533000901113000501663000b01393000601453000402203000a015b30016a5107014830001020330009011a3000801393000b011a30004017230002015b3000501213006416104015930003014b3000501143000b0123300090161300020141300080187300070216300775710901243000401433000701513000302123000101883000b017530006021930008016b300872210601273000701823000a01543000301823000401693000901433000b011630008021a3001561103013a3000801613000a018730004013a3000502023000101723000201553000701163003873104012a3000a01373000801473000601143000501463000b017230002020630001016b3005883102013a3000601583000a015830001020b3000401123000b0126300070183300030177300669610101753000201343000401223000b015a3000a01693000702053000501113000802073004744106012b3000b018530008017a3000701543000902143000201593000a014430005011630021b210901753000601873000102163000a013130003016230002012b3000502163000701533001831109020730005018830001016b30002015a3000a01423000b02143000601253000801133007287106013730005022030007011630009015b3000b014930004018a3000301483000a0178300255210902143000b01653000301673000601253000801713000701333000101583000a01463004496106013130003015230001014930005018430002016730007014930008011630004020a300831810501813000701423000a01273000201273000601153000901783000801693000b020a300368310502173000a015b30006015b3000901383000b012a30002018430007014930004016230068a6107018930008011730001022030005015230002016a3000601313000b01313000901283005767109012430004017330005014b3000b02053000701193000101563000301563000a0161300"
--</data>

pltd="i was at the ^ all night.|i was at the ^ from dusk to dawn.|i was down at the ^, half asleep.|oh, i was over at the ^ all evening.|the ^. all night.|i was out at the ^, where else.|i stayed near the ^, as i always do.|post: the ^, dusk to dawn."

witd="~ was at the ^. i saw them.|i passed ~ by the ^, near midnight.|~ went past the ^, i think.|and ~! over at the ^, plain as day.|~ was at the ^.|~ was by the ^. i saw that much.|poor ~ was out by the ^.|sighting: ~, at the ^."

sgnd="the ^ stood right beside me.|i could have touched the ^.|the ^ was at my shoulder all night.|i was near enough to hear the ^.|i could see the ^ across the field.|the ^ was in plain view.|nothing stood between me and the ^.|i had a clear line to the ^.|the scream came from far off.|the cry was a long way away.|whatever screamed, it was distant.|i heard it faint, from far off.|the scream was close. i ran the other way.|it screamed almost on top of me.|the cry was near. too near.|i heard it close by, and hid."

rmpd="0123456789abcdef|0123455684a3cde4|0121255d82a11de2|01010111809111e0|0111112782211122"

htl=split("the rule of evidence|the rule of evidence|the village|the wild|the eight","|",false)

natd=split("the ridge stops sight.|the trees stop sight.|sight carries across it.|a step costs 15 minutes.","|",false)

howd="one of the eight is the wolf.|the other seven never lie.|whoever stood at the attack|site is the wolf, and nobody|will admit to being there.||nobody is guilty for being|unvouched-for. two things|convict: a statement that|contradicts another, or one|the board proves impossible./when two people contradict|each other, the one with|independent corroboration|is innocent.||sight carries two cells, or|along a clear row or column.|the mountain and the forest|block it.||you cannot hear all eight.|the day is too short on|purpose."

__gfx__
-->8
-- test driver (appended to __lua__ by verify.js; not part of the game)

-- capture the real callbacks BEFORE overriding them, or the tests end up
-- calling their own stubs and proving nothing
_rd=_draw
_ru=_update60

fails=0
checks=0
kchecks=0

-- Measure text rather than assuming 4px a character: LANDMARK names are drawn
-- in p8scii's uppercase set, and the dialogue panel is only 115px wide.
-- print() returns the rightmost x; drawing offscreen keeps it invisible.
function txtw(s) return print(s,0,-40,0) end

function ok(c,m)
 checks+=1
 if checks>=1000 then checks=0 kchecks+=1 end
 if not c then
  fails+=1
  if fails<=20 then printh("fail: "..m) end
 end
end

-- every night must decode into a well-formed, self-consistent story
function testdata()
 for n=1,32 do
  loadnight(n)
  local p="n"..n.." "
  ok(wolf>=1 and wolf<=8,p.."wolf "..wolf)
  ok(site>=1 and site<=11,p.."site "..site)
  ok(tellv>=1 and tellv<=8,p.."tellv")
  ok(stm[tellv] and stm[tellv][tellc]~=nil,p.."tell clause missing")

  local nl,nv,ns=0,0,0
  for i=0,35 do
   local c=cells[i]
   ok(c>=0 and c<=20,p.."cell value "..c)
   if c>=1 and c<=11 then nl+=1
   elseif c>=12 and c<=19 then nv+=1
   elseif c==20 then ns+=1 end
  end
  ok(nl==11,p.."landmarks "..nl)
  ok(nv==8,p.."villagers "..nv)
  ok(ns==1,p.."starts "..ns)
  for l=1,11 do ok(lmc[l]~=nil,p.."landmark "..l.." missing") end
  ok(cells[pcell]==20,p.."start cell")
  -- the player must not begin inside a wall
  ok(cells[pcell]<1 or cells[pcell]>11,p.."start is impassable")

  for v=1,8 do
   ok(#stm[v]>=2 and #stm[v]<=3,p.."v"..v.." has "..#stm[v].." clauses")
   ok(claim[v]>=1 and claim[v]<=11,p.."v"..v.." claim")
   ok(vcl[v]~=nil,p.."v"..v.." has no cell")
   local vc=cells[vcl[v]]
   ok(vc>=12 and vc<=19,p.."v"..v.." not on a villager cell")
   for ci=1,#stm[v] do
    local c=stm[v][ci]
    ok(c[1]>=0 and c[1]<=2,p.."clause type "..c[1])
    local s=ctext(v,c)
    ok(#s>4,p.."v"..v.." short text")
    for i=1,#s do
     local ch=sub(s,i,i)
     ok(ch~="~" and ch~="^",p.."unfilled placeholder: "..s)
    end
    for l in all(wrap(s,22)) do
     ok(#l<=22,p.."overlong line ("..#l.."): "..l)
     ok(txtw(l)<=115,p.."line too wide ("..txtw(l).."px): "..l)
    end
   end
  end

  -- the two rules the whole deduction rests on
  ok(claim[wolf]~=site,p.."the wolf claims the attack site")
  for v=1,8 do
   if v~=wolf then ok(claim[v]~=site,p.."innocent "..v.." claims the attack site") end
  end
 end
end

-- walking, talking, and the clock
function testboard()
 loadnight(7)
 ok(tk==0,"clock does not start at zero")
 local st=pcell
 -- walking into every wall must cost nothing
 for d=0,3 do
  local before=pcell
  local x,y=pcell%6,pcell\6
  if d==0 then x-=1 elseif d==1 then x+=1 elseif d==2 then y-=1 else y+=1 end
  local blocked = x<0 or x>5 or y<0 or y>5 or (cells[y*6+x]>=1 and cells[y*6+x]<=11)
  local t0=tk
  trymove(d)
  if blocked then
   ok(pcell==before,"moved into a wall")
   ok(tk==t0,"a blocked move cost time")
  else
   ok(pcell~=before,"a legal move did not happen")
   ok(tk==t0+1,"a move cost "..(tk-t0).." ticks")
  end
 end

 -- a conversation costs exactly two ticks, and only counts once
 loadnight(7)
 local t0=tk
 opendlg(3)
 ok(tk==t0+2,"a talk cost "..(tk-t0).." ticks")
 ok(heard[3],"talking did not mark the villager heard")
 ok(nheard==1,"heard count "..nheard)
 opendlg(3)
 ok(nheard==1,"re-hearing double counted")
 ok(tk==t0+4,"re-hearing was free")

 -- the clock must never run past nightfall
 loadnight(7)
 for i=1,200 do addtick(1) end
 ok(tk==40,"clock overran to "..tk)
 ok(clockstr()=="18:00","clock reads "..clockstr())
 loadnight(7)
 ok(clockstr()=="08:00","day starts at "..clockstr())
 addtick(23)
 ok(clockstr()=="13:45","23 ticks reads "..clockstr())

 -- every villager must be reachable, or the night is unwinnable
 loadnight(7)
 local seen={}
 local q={pcell}
 seen[pcell]=true
 local h=1
 while h<=#q do
  local c=q[h] h+=1
  local x,y=c%6,c\6
  for d=0,3 do
   local nx,ny=x,y
   if d==0 then nx-=1 elseif d==1 then nx+=1 elseif d==2 then ny-=1 else ny+=1 end
   if nx>=0 and nx<6 and ny>=0 and ny<6 then
    local n=ny*6+nx
    if not seen[n] and (cells[n]<1 or cells[n]>11) then
     seen[n]=true add(q,n)
    end
   end
  end
 end
 for v=1,8 do ok(seen[vcl[v]],"villager "..v.." is unreachable") end
end

-- Every tile the board draws must exist and have art in it. The sprite numbers
-- are spelled out rather than recomputed from lmspr(), so that a test cannot
-- quote the code back at itself and agree with whatever it believes.
function testsprites()
 local want=split"32,34,36,38,40,42,44,46,64,66,68"
 for l=1,11 do
  ok(lmspr(l)==want[l],"landmark "..l.." maps to sprite "..lmspr(l))
 end
 local function ink(n)
  local sx,sy=(n%16)*8,(n\16)*8
  local c=0
  for y=sy,sy+15 do
   for x=sx,sx+15 do
    if sget(x,y)~=0 then c+=1 end
   end
  end
  return c
 end
 -- board tiles are opaque and full-bleed; figures keep a transparent margin
 for l=1,11 do ok(ink(want[l])>120,"landmark "..l.." tile is blank ("..ink(want[l])..")") end
 -- The ground tile is deliberately not solid: a dotted black seam runs down its
 -- right edge and along its bottom, and that seam is the only thing that makes
 -- the 6x6 grid legible. Assert the art AND the seam, or a regression that ate
 -- one of them would still pass.
 ok(ink(70)>200,"the ground tile is blank ("..ink(70)..")")
 local seam=0
 for y=32,47 do
  if sget(63,y)==0 then seam+=1 end
 end
 ok(seam>=6,"the ground tile has lost its grid seam ("..seam..")")
 for v=1,8 do ok(ink((v-1)*2)>60,"villager "..v.." sprite is blank") end
 ok(ink(72)>60,"the player token is blank")
 ok(ink(74)>60,"the wolf sprite is blank")
end

-- the display ramp must stay inside the palette at every hour
function testramp()
 loadnight(1)
 for t=0,40 do
  tk=t
  setramp()
  local s=rmps[tk>=40 and 5 or tk>=38 and 4 or tk>=34 and 3 or tk>=28 and 2 or 1]
  ok(#s==16,"ramp string is "..#s.." long")
  for c=0,15 do
   local v=d32(s,c+1)
   ok(v>=0 and v<=15,"ramp maps to "..v)
  end
 end
 pal()
end

-- run every draw path once, so a nil in any screen surfaces here
function testdraw()
 loadnight(1)
 for i=1,560,40 do scr=0 it=i _rd() end
 scr=1 mi=1 _rd() mi=3 _rd()
 scr=2 for p=1,5 do hpage=p _rd() end
 scr=3 _rd()
 scr=4 tk=0 _rd()
 tk=30 _rd()
 tk=40 _rd()
 for v=1,8 do
  tk=0
  opendlg(v)
  _rd()
  while dtick\2<dtotal do dtick+=1 end
  _rd()
  for p=1,#stm[v] do
   setpage(p)
   -- assert the game's own wrapping, not a width the test picked itself
   ok(#dlines<=5,"dialog page needs "..#dlines.." lines")
   for l in all(dlines) do ok(#l<=22,"dialog line ("..#l.."): "..l) end
   _rd()
  end
 end
 -- the how-to legend: two text columns beside a 16px tile, so a name that
 -- grew would either collide with the next column or leave the screen
 ok(#htl==5,"how-to has "..#htl.." page titles")
 ok(#split(howd,"/",false)==2,"the rule of evidence is no longer two pages")
 ok(#natd==4,"the wild page needs 4 notes")
 for l=1,8 do
  ok(txtw(lmn[l])<=40,"legend building name too wide: "..lmn[l])
 end
 for l=9,11 do
  ok(25+txtw(lmn[l])<=127,"legend nature name overruns: "..lmn[l])
 end
 for i=1,4 do
  ok(25+txtw(natd[i])<=127,"legend note overruns: "..natd[i])
 end
 for v=1,8 do
  ok(txtw(nm[v])<=32,"legend villager name too wide: "..nm[v])
 end

 -- the notebook's widest possible row must stay inside its frame
 for l=1,11 do
  ok(73+txtw(lmn[l])<=124,"notebook landmark overruns: "..lmn[l])
 end
 for v=1,8 do
  ok(13+txtw(nm[v])<=40,"notebook speaker overruns: "..nm[v])
  ok(46+txtw(nm[v])<=72,"notebook subject overruns: "..nm[v])
 end
 scr=6 npage=1 _rd() npage=2 _rd()
 nheard=0 heard={} _rd() npage=1 _rd()
 loadnight(1)
 scr=7 ai=1 confirm=false _rd()
 ai=8 confirm=true _rd()
 tk=40 _rd()
 scr=8 it=100
 guilty=wolf _rd()
 guilty=(wolf%8)+1 _rd()
 pal()
end

tf=0
function _update60()
 tf+=1
 if tf==2 then
  testdata()
  testboard()
  testsprites()
  testramp()
  testdraw()
  printh("checks="..(kchecks*1000+checks).." fails="..fails)
  printh(fails==0 and "ALL PASS" or "FAILED")
  extcmd("shutdown")
 end
end
function _draw() end

00003377773300000003333333333000000333333333300000033335533330000003333333333000000003333330000000033333333330000003333333333000
00033765657330000033555555553300033355555555333000335551155533000033555555553300333333555533333303335555555533300033666666663300
00037555555730000035111111115300035511111111553000351111111153000035111111115300355555111155555303551111111155300036151555156300
0003ffffffff300000351ffffff513000333ffffffff33300033ffffffff330000338888888833003333ffffffff33330351ffffffff51300036111151111300
0003f2ff442f30000033f2ff442f33000003f2ff442f30000003f2ff442f30000003f2ffff2f30000003f2ff442f30000351f2ff442f51300033f2f61f2f3300
0003fff4f4f430000003fff4f4f430000003fff4f4f430000003fff4f4f430000003fff4f4f430000003fff4f4f430000351fff4f4f451300003fffff4f43000
00333f444443330000333f444443330000333f444443330000333f444443330000333f444443330000333f444443330003333f444443333000333f4444433300
033bbccccccbb330033bbccccccbb330033bbccccccbb330033bbccccccbb330033bbccccccbb330033bbccccccbb330033bbccccccbb330033bbccccccbb330
03bcdccccccddb3003bcdccccccddb3003bcdccccccddb3003bcdccccccddb3003bcdccccccddb3003bcdccccccddb3003bcdccccccddb3003bcdccccccddb30
03bcdccccccdcd3003bcdccccccdcd3003bcdccccccdcd3003bcdccccccdcd3003bcdccccccdcd3003bcdccccccdcd3003bcdccccccdcd3003bcdccccccdcd30
03bcdccccccddd3003bcdccccccddd3003bcdccccccddd3003bcdccccccddd3003bcdccccccddd3003bcdccccccddd3003bcdccccccddd3003bcdccccccddd30
03bcdccdcdcdcd3003bcdccdcdcdcd3003bcdccdcdcdcd3003bcdccdcdcdcd3003bcdccdcdcdcd3003bcdccdcdcdcd3003bcdccdcdcdcd3003bcdccdcdcdcd30
03cddddddddddd3003cddddddddddd3003cddddddddddd3003cddddddddddd3003cddddddddddd3003cddddddddddd3003cddddddddddd3003cddddddddddd30
03bdcd3333bdcd3003bdcd3333bdcd3003bdcd3333bdcd3003bdcd3333bdcd3003bdcd3333bdcd3003bdcd3333bdcd3003bdcd3333bdcd3003bdcd3333bdcd30
03bdd330033bdd3003bdd330033bdd3003bdd330033bdd3003bdd330033bdd3003bdd330033bdd3003bdd330033bdd3003bdd330033bdd3003bdd330033bdd30
03333300003333300333330000333330033333000033333003333300003333300333330000333330033333000033333003333300003333300333330000333330
1111111611111110111111111111111011111111111111101111166111111110111111111111111011661111111166101111111aa11111101111111dd1111110
1111116061111111111111119999999111111999999111111111666611111111111111111111111111660111111166011111119aa911111111111dd22dd11111
1111111600111110111111192424242011199444444991101111651101111110111111116111111011610111111161001116616706616610111dd202020dd110
1111111dd051111111111192222222201192424242424911111165510051111111166611605111111161dddddddd6100111656556556110111d0000000000d11
111111d20d011110111111104499444019222222222222901166555566666610116555660601111011dd22222222dd0011116515551100001114000040004000
11511d2220d111111156611145aa91101444444444444440165555555555516111655110600111111d202020202020d011516555555100101154001050104010
1101d222220d11101665566145aa92101425522222255210165515155555551011655510600111101d00000000000000110165a7551101101104011444414000
111d20202020d1116006006642992110145aa922215aa91016511111555151101165511060166611167766776677666011116575555100111114001411104011
11d0000000000d106006000642222210145aa922225aa9101618888655111510116555106065556017aa75aa75aa7510111165555a7101101116666666666000
1116667aa7666001666556604222211014299121212991101689aa9861000610116551106065511017aa75aa75aa711011116555575100111161000000006611
1116119aa965100060055000421222101422194111222210168aaaa8610006101165551060655510167755771577551011116555551101101161000000006100
1116516996551011600600064211211014215a9000422110168aaaa861000610116151106061511017aa7511115aa71011165551555160111161000000006100
1117a756655a7000660600604100421014222910004222101667777611000610116111106061111017aa7100007aa71011165511155510001165666666661100
1117a710065a70111660560041004110142121100041211016515151510006101444444444444440167751000067711011615100065156111161515151515100
11167110061710001106000041004110141111100041111016111111116661101411111111111110161111000061111011611100061111001116111111111000
01010000000000010100000000000000010000000000000001000000000000000130000030000300010000000000000001000000000000000101000000000000
111111111111111011111111111b1110111111111111111011111111111111100000333333330000033330000003333000000000000000000000000000000000
1111111771111111111b111111b1b111111cccccccccc1111111111111111111033335555553333003bb33000033bb3000000000000000000000000000000000
1111117dd711111011b3b11111b310101ccc1c111c1c1cc01111111111111110035551111115553003bcb330033bdd3000000000000000000000000000000000
111117d66771111111b110111b333b11c1c1c117c1c1c1cc11111111115111110333ffffffff333003bccb3333bccd3000000000000000000000000000000000
11116665556611101b331b011b331100cc1c1c177c1c1c1111111111110111100003f2ff442f300003bcccb33bccdd3000000000000000000000000000000000
11576555511161111b333101b33331b0c1c11116c1c1c1c111511111111111110003ff4444f4300033bdcccbbccccd3300000000000000000000000000000000
117d655555111610b33333b1b3333310cc166c177c1c1111110111111111111000033555555330003bcdccccccccdcb300000000000000000000000000000000
1666555555511101b33331101b333100c1ccc116c1c166c1111111111111111100335111111533003bdabccdcdcdabd300000000000000000000000000000000
16555555555511601b331100b33333b0cc1c1c177c1ccc11111111115111111000351111111153333bcbccddddccbcd300000000000000000000000000000000
6555566555555110b13131bb3333333bc1c11116c1c1c1c1111111110111111100351111111119a33bcccd2222bccdd300000000000000000000000000000000
6555666555555516b111111313131311cc166c177c1c1c1111111111111111100035111111119aa333bcdd2222bcdd3300000000000000000000000000000000
65566655555555511004000b11111111c1ccc116c1c1c1c1111111111111151100351111111159a303bdcd7227bccd3000000000000000000000000000000000
65566555555555111104010100040000cc1c1c17cc1c1c1111111111111111000035111111111333033bdcbbbbccd33000000000000000000000000000000000
616551515151515111140011101400101cc1c1ccc1c1c110111111111111111100351113351113000033bdcdcdcd330000000000000000000000000000000000
6151111111111111111101111114011011c11111111111001111111111111110003511333351130000033bddddd3300000000000000000000000000000000000
00000000000000000101000101010001010000000000000001010101010101010033333003333300000033333333000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100010000000000010000000000000000000100000000000000000000000000000000000000000000000000000001000000010000000000010001000100010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010009920001010009920000099999200101000999992001009920010009920099999999999200000999992001009920010100099200010101010101010
00000000009820000000009820000098888200000000988882000009820000009820098888888888200000988882000009820000000098200000000000000000
00100010009822000000009822000022222220000000222222200009822000009822098822222222220000222222200009822010000098220010001000100010
00000000009889920009998822099202222299200992022222992009889920009822098222222222220992022222992009822000000098220000000000000000
10101010009888820009888822098202222298200982022222982009888820009822098222222222220982022222982009822010100098220010101010101010
00000000009882222002228822098220000098220982200000982209888822009822098220000000000982200000982209822000000098220000000000000000
10101010009822229920229822098220100098220982201000982209888889998822098899999200100988999999882209822010100098220010101010101010
00000000009822229820229822098220000098220982200000982209888888888822098888888200000988888888882209822000000098220000000000000000
10101010009822002222009822098220100098220982201000982209882228888822098822222220100988222222882209822010100098220010101010101010
00000000009822000222009822098220000098220982200000982209822229888822098222222220000982222222982209822000000098220000000000000000
10101010009822000222009822098220000098220982200000982209822229888822098222222220100982222222982209822000000098220000000010101010
01000100009822000100009822022220000022220222200000222209822002228822098220000100000982200100982209822000000098220000000001000100
10101010009822001010009822002299999202220022999992022209822000229822098220101010100982201000982209889999920098899999200010101010
00010001009822010001009822002298888202220022988882022209822000229822098220010001000982200000982209888888820098888888200100010001
10101010002222001010002222000022222220101000222222201002222010002222022220101010100222201000222202222222222022222222220010101010
01000100000222000100000222000002222220000100022222200000222001000222002220000100000022200100022200222222222002222222220001000100
10101010000222001010000222000002222220101000022222201000222010000222002220101010100022201000022200222222222002222222220010101010
00010001000100010001000100010001000100010001000100010001000100010001000100012001200120010001000100010001000100010001000100010001
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010121012101010101010101010101010101010101010101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
01010101010101010101010100000000000001010000000001010000000000000000010100000000012100010000000000000000010101010101010101010101
10101010101010101010101000660660066600100066066600100666060606660666001006660066021206020606066606600066001010101010101010101010
01010101010101010101010106060606060001010606060001010060060606000666012100600600022206020606006006060600010101010101010101010101
10101010101010101010101006060606066010100606066010101060066606600606021210600666001006000666006006060600001010101010101010101010
0101010101010101010101010606060606000101060606000101006006060600060602210060000601e106000006006006060606010101010101010101010101
101010101010101010101010066006060666001006600600101010600606066606060010066606600e1e06660666066606060666001010101010101010101010
0101010101010101010101010000000000000101000000010101000000000000000001e100000000eeee00000000000000000000010101010101010101010101
11101110111011101110111011101110111011101110111011101110111011121110111e1e7777777777777e1e1e111012101110111011101110111011101110
0101010101010101010101010101010101010101010101010101010121012122e1e1eee7777777777777777777eee1e1e2212101210101010101010101010101
1011101110111011101110111011101110111011101110111011101110111221101ee77777777777777777777777ee1110221211101110111011101110111011
0101010101010101010101010101010101010101010101010101010101212201e1ee7777777777777777777777777ee1e1022121010101010101010101010101
11101110111011101110111011101110111011101110111011101110111211101ee777777777777777777777777777ee11101210111011101110111011101110
010101010101010101010101010101010101010101010101010121012122e1e1e7777777777777777777777777777777e1e1e221210121010101010101010101
101110111011101110111011101110111011101110111011101110111211101e777777777777777777777777777777777e111012101110111011101110111011
01010101010101010101010101010101010101010101010101010121212101ee777777777777777777777777777777777ee10122212101010101010101010101
1111111111111111111111111111111111111111111111111111111212111ee77777777777777777777777777766677777ee1112111111111111111111111111
010101010101010101010101010101010101010101010101010121212101ee7777777766677777777777777776666677777ee101212121010101010101010101
10111011101110111011101110111011101110111011101110111012201117777777666666677777777777777666667777771e11221110111011101110111011
0101010101010101010101010101010101010101010101010101012221e1e777777766666667777777777777766666777777e1e1212101010101010101010101
11111111111111111111111111111111111111111111111111111112111e77777776666666667777777777777766677777777e11121111111111111111111111
01010101010101010101010101010101010101010101010101012122e1ee77777776666666667777777777777777777777777ee1e22121010101010101010101
11111111111111111111111111111111111111111111111111111211111e77777776666666667777777777777777777777777e11111211111111111111111111
1101110111011101110111011101110111011101110111011101212111e7777777776666666777777777777777777777777777e1112121011101110111011101
1111111111111111111111111111111111111111111111111111121111177777777766666667777777777777777777777777771e111211111111111111111111
01010101010101010101010101010101010101010101010121012221e1e7777777777766677777777777777777777777777777e1e12121012101010101010101
111111111111111111111111111111111111111111111111111112211ee7777777777777777777777777777777777777777777ee112211111111111111111111
11011101110111011101110111011101110011011101110111212121e1e7777777777777777777777777777777777777777777e1e12221211101110111011101
111111111111111111111111111111111110111111111111111112211ee7777777777777777777777777777777777777777777ee112211111111111111111111
01110111011101110111011101110111000000110111011121112221eee7777777777777777777777777777777777777777777e1e12221112111011101110111
111111111111111111111111111111111110111111111111111112211ee7777777777777777777777777766666777777777777ee112211111111111111111111
11011101110111011101110111011101110011011101110111212121e1e7777777777777777777777777666666677777777777e1e12221211101110111011101
111111111111111111111111111111111110111111111111111112211ee7777777777777777777777776666666667777777777ee112211111111111111111111
01110111011101110111011101110111011001110111011121112221e1e7777777777777777777777766666666666777777777e1e12121112111011101110111
1111111111111111111111111111111111d0d11111111111111112111e177777777777777777777777666666666667777777771e111211111111111111111111
1111111111111111111111111111111111d1d111111111111111212111e7777777777777777777777766666666666777777777e1112121111111111111111111
111111111111111111111111111111111d010d111111111111111111111e77777777777777777777776666666666677777777e11111211111111111111111111
111111111111111111111111111111111d111d111111111111112122e1ee77777777777777777777776666666666677777777ee1e22121111111111111111111
11111111111111111111111111111111d01110d11111111111111212111e77777777777777776667777666666666777777777e11121111111111111111111111
11111111111111111111111111111111d01110d1111111111111112221e1e777777777777776666677776666666777777777e1e1212111111111111111111111
1111111111111111111111111111111d0111110d1111111111111112111e17777777777777666666677776666677777777771111121111111111111111111111
d111d111d111d111d111d111d111d11d0111d10dd111d111d11121212111ee7777777777776666666777777777777777777ee11121212111d111d111d111d111
111111111111111111111111111111d011111110d11111111111111112111ee77777777777666666677777777777777777ee1112121111111111111111111111
11d111d111d111d111d111d111d111d011d111d0d1d111d111d11121212111ee777777777776666677777777777777777eed1122212111d111d111d111d111d1
11111111111111111111111111111d01111111d00d111111111111111211111e777777777777666777777777777777777ed0dd12111111111111111111111111
d1d1d1d1d1d1d1d1d1d1d1d1d1d1dd00000000000dd1d1d1d1d121d12122e1e1e7777777777777777777777777777777dd0100d121d121d1d1d1d1d1d1d1d1d1
1111111111111111111111111111111000000000110dd11111111111111221111ee777777777777777777777777777ed0011220dd11111111111111111111111
11d111d111d111d111d111d111d111d00000000011d00dd111d111d1112122d1e1ee7777777777777777777777777ed0e1d221200dd111d111d111d111d111d1
1111111111111111111d11111111111000000000111110dd1111111111111221111e17777777777d777777777777dd011122111110dd11111111111111111111
d1d1d1d1d1d1d1d1d1d0ddd1d1d1d1d000000000d1d1d100d1d1d1d121d12122e1e1eee7777777d0dd77777777ed00e1e22121d12100d1d1d1d1d1d1d1d1d1d1
1111111111111111dd0100d1111111100000000000000000011111111111121221111e1eee77dd0700d7777eee10000000000000000001111111111111111111
d1d1d1d1d1d1d1dd00d1d10dd1d1d1d00000000000000000d1d1d1d1d1d1d1212221d1e1e1ed00eeee0ddee1e1e10000000000000000d1d1d1d1d1d1d1d1d1d1
11111111111111d0111111100d111110000000000000000011111111111111111212111111d01e1e1e100d111111000000000000000011111111111111111111
d1d1d1d1d1d1dd01d1d1d1d1d0ddd1d00000000000000000d1d1d1d1d1dd21d121212221dd01e1e1e1e1e0dde1220000000000000000d1d1d1d1d1ddd1d1d1d1
dd111d111d1d00111d111d111d00dd1000000000000000001d111d111dd0dd111d11121d00111d111d111d00d21200000000000000001d111d111dd0dd111d11
00d1d1d1d1d0000000000000000001d00000000000000000d1d1d1d1dd0100d1d1212120000000000000000001210000000000000000d1d1d1d1dd0100d1d1d1
110dd11d111d000000000000000011100000000000000000111d111d001d110dd11d111d0000000000000000111d0000000000000000111d111d001d110dd11d
d1d00dd1d1d10000000000000000d1d00000000000000000d1d1d1d0d1d1d1d00dd121d1000000000000000021d10000000000000000d1d1d1d0d1d1d1d00dd1
1d1110dd1d1100000000000000001d1000000000000000001d11dd011d111d1110dd1d1100000000000000001d1100000000000000001d11dd011d111d1110dd
d1d1d100d1d10000000000000000d1d00000000000000000d1dd00d1d1d1d1d1d100d1d10000000000000000d1d10000000000000000d1dd00d1d1d1d1d1d100
00000000011d00000000000000001110000000000000000011100000000000000000011d0000000000000000111d000000000000000011100000000000000000
00000000d1d10000000000000000d1d00000000000000000d1d10000000000000000d1d10000000000000000d1d10000000000000000d1d10000000000000000
000000001d1d00000000000000001d1000000000000000001d1d00000000000000001d1d00000000000000001d1d00000000000000001d1d0000000000000000
00000000d1d10000000000000000d1d00000000000000000d1d10000000000000000d1d10000000000000000d1d10000000000000000d1d10000000000000000
000000001d1d00000000000000001d1000000000000000001d1d00000000000000001d1d00000000000000001d1d00000000000000001d1d0000000000000000
00000000d1d10000000000000000d1d00000000000000000d1d10000000000000000d1d10000000000000000d1d10000000000000000d1d10000000000000000
000000001d1d00000000000000001d1000000000000000001d1d00000000000000001d1d00000000000000001d1d00000000000000001d1d0000000000000000
0000000dddd100000000000ddd00d1d00000000ddd000000d1d1000ddd0000000000d1dddd0000000000000dddd100000000000ddd00d1d10000000ddd000000
000000d000dd0000000000d000d01d10000000d000d000001d1d00d000d0000000001dd000d00000000000d000dd0000000000d000d01d1d000000d000d00000
dddddd00000ddddddddddd00000ddddddddddd00000ddddddddddd00000ddddddddddd00000ddddddddddd00000ddddddddddd00000ddddddddddd00000ddddd
ddddd0000000ddddddddd0000000ddddddddd0000000ddddddddd0000000ddddddddd0000000ddddddddd0000000ddddddddd0000000ddddddddd0000000dddd
ddddd0000000ddddddddd0000000ddddddddd0000000ddddddddd0000000ddddddddd0000000ddddddddd0000000ddddddddd0000000ddddddddd0000000dddd
1dddd0000000dddd1dddd0000000dddd1dddd0000000dddd1dddd0000000dddd1dddd0000000dddd1dddd0000000dddd1dddd0000000dddd1dddd0000000dddd
dddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddd
dd1d000000000d1ddd1d000000000d1ddd1d000000000d1ddd1d000000000d1ddd1d008808800d1ddd1d000000000d1ddd1d000000000d1ddd1d000000000d1d
dddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddd
1d1d000000000d1d1d1d000000000d1d1d1d000000000d1d1d1d000000000d1d1d1d000000000d1d1d1d000000000d1d1d1d000000000d1d1d1d000000000d1d
dddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddddddd000000000ddd
1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd
dd000000000000dddd000000000000dddd000000000000dddd000000000000dddd000000000000dddd000000000000dddd000000000000dddd000000000000dd
1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd
dd000000000000d1dd000000000000d1dd000000000000d1dd000000000000d1dd000000000000d1dd000000000000d1dd000000000000d1dd000000000000d1
1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd1d000000000000dd
dd000000000000d1dd000000000000d1dd000000000000d1dd000000000000d1dd000000000000d1dd000000000000d1dd000000000000d1dd000000000000d1
11d0000000000d1d11d0000000000d1d11d0000000000d1d11d0000000000d1d11d0000000000d1d11d0000000000d1d11d0000000000d1d11d0000000000d1d
d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1
1dd0000000000d111dd0000000000d111dd0000000000d111dd0000000000d111dd0000000000d111dd0000000000d111dd0000000000d111dd0000000000d11
d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1d1d0000000000dd1
11d0000000000d1111d0000000000d1111d0000000000d1111d0000000000d1111d0000000000d1111d0000000000d1111d0000000000d1111d0000000000d11
d1dd00000000d1d1d1dd00000000d1d1d1dd00000000d1d1d1dd00000000d1d1d1dd00000000d1d1d1dd00000000d1d1d1dd00000000d1d1d1dd00000000d1d1
111d00000000d111111d00000000d111111d00000000d111111d00000000d111111d00000000d111111d00000000d111111d00000000d111111d00000000d111
11dd00000000d1d111dd00000000d1d111dd00000000d1d111dd00000000d1d111dd00000000d1d111dd00000000d1d111dd00000000d1d111dd00000000d1d1
111d00000000d111111d00000000d111111d00000000d111111d00000000d111111d00000000d111111d00000000d111111d00000000d111111d00000000d111
d11d00000000d111d11d00000000d111d11d00000000d111d11d00000000d111d11d00000000d111d11d00000000d111d11d00000000d111d11d00000000d111
1111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d1111
1111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d1111
1111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d1111
1111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d1111
1111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d11111111d000000d1111
11111d00000d111111111d00000d111111111d00000d111111111d00000d111111111d00000d111111111d00000d111111111d00000d111111111d00000d1111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
__gff__
__sfx__
010400001862514615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600000e6330a625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0107000021530285402d5350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700002d530265301f5250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002e5202c515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002b02029015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002202020015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002d4202b415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001e3201c315000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000200201e015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002c5202a515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002642024415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001e62026625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002832500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01050000285402f545000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500002853021535000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00002d04000000260350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002d03032035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900002524026245000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b00001a2521a245000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000285512d5622d5622b55126552215450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001e6531a253142530e64500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00002d55031550345503956500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00002d7502c750277402074500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200002d5403454039540345403654034540315402d5402d5403454039540345403654034540315402d54000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200001503500000000000000000000000000000000000150350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01120000285402f540345402f540315402f5402c54028540285402f540345402f540315402f5402c5402854000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200001003500000000000000000000000000000000000100350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200002d5403454039540345403554034540305402d5402d5403454039540345403554034540305402d54000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200001504000000150400000015040000001504000000150400000015040000001504000000150400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01120000285402f540345402f540305402f5402b54028540285402f540345402f540305402f5402b5402854000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200001004000000100400000010040000001004000000100400000010040000001004000000100400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400002d030000003903000000350300000030030000002d0300000039030000003503000000300300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0114000015240000001524000000152400000015240000001b240000001b240000001b240000001b2400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400002803000000340300000030030000002b030000002803000000340300000030030000002b0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400001024000000102400000010240000001024000000162400000016240000001624000000162400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00002d7502675021750267502475026750297502d7502d7502675021750267502475026750297502d75000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e000015250000001525000000152500000015250000001b250000001b250000001b250000001b2500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e000028750217501c750217501f75021750247502875028750217501c750217501f75021750247502875000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00001025000000102500000010250000001025000000162500000016250000001625000000162500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011600002d5403454039540345403554034540305402d5402d5403454039540345403554034540305402d54000000000000000000000000000000000000000000000000000000000000000000000000000000000
011600001503500000000000000000000000000000000000150350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01160000285402f540345402f540305402f5402b54028540285402f540345402f540305402f5402b5402854000000000000000000000000000000000000000000000000000000000000000000000000000000000
011600001003500000000000000000000000000000000000100350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 18194344
02 1a1b4344
00 41424344
00 41424344
01 1c1d4344
02 1e1f4344
00 41424344
00 41424344
01 20214344
02 22234344
00 41424344
00 41424344
01 24254344
02 26274344
00 41424344
00 41424344
01 28294344
02 2a2b4344
00 41424344
00 41424344
04 16424344
00 41424344
04 17424344
00 41424344
