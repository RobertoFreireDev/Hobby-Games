-->8
-- test driver (harness only)
sols=split("__SOLS__",",",false)
ix={}
for i=0,35 do
 ix[sub("0123456789abcdefghijklmnopqrstuvwxyz",i+1,i+1)]=i
end
fails=0
function ok(c,m)
 if not c then
  fails+=1
  printh("FAIL "..m)
 end
end

-- synthetic input, so the real _update can be driven for the paths that
-- read buttons rather than being called through mv() directly
sb=0 spb=0
function btn(b) return flr(sb/2^b)%2>=1 end
function btnp(b) return flr(sb/2^b)%2>=1 and flr(spb/2^b)%2<1 end
function press(bit)
 sb=bit _ru() spb=bit
 sb=0 _ru() spb=0
end

function tap(bit,n)
 for k=1,n do
  sb=bit _ru() spb=bit
  sb=0 _ru() spb=0
 end
end

-- n frames with the button never released, which is
-- the only way to reach the hold-to-reset path
function hold(bit,n)
 for k=1,n do
  sb=bit _ru() spb=bit
 end
end

-- move any piece one cell, whichever one has room
function nudge()
 for i=2,#pcs do
  for s=-1,1,2 do
   hd=i
   local m0=moves
   mv(pcs[i].d==0 and s or 0,
      pcs[i].d==1 and s or 0)
   if moves>m0 then
    hd=nil
    return true
   end
  end
 end
 hd=nil
end

_ru=_update
_rd=_draw
function _draw() end

function _update()
 -- every level must be beatable in exactly par moves, using the cart's
 -- own mv() rather than the solver's model of it
 for n=1,#lvs do
  ld(n)
  local s=sols[n]
  ok(#s/2==prs[n],"lv"..n.." path len "..(#s/2).." vs par "..prs[n])
  for i=1,#s,2 do
   hd=ix[sub(s,i,i)]
   local d=sub(s,i+1,i+1)
   local m0=moves
   mv(d=="l" and -1 or (d=="r" and 1 or 0),
      d=="u" and -1 or (d=="d" and 1 or 0))
   ok(moves==m0+1,"lv"..n.." move "..((i+1)/2).." rejected")
   ok(st==0,"lv"..n.." ended early at move "..((i+1)/2))
  end
  ok(moves==prs[n],"lv"..n.." used "..moves.." of "..prs[n])
  hd=1
  mv(1,0)
  ok(st==1,"lv"..n.." did not exit")
  ok(dget(n-1)==1,"lv"..n.." not recorded solved")
 end
 ok(sv()==#lvs,"solved count "..sv())

 -- one move past par must detonate the board
 -- on a packed board most pieces are wedged solid, so the waster has to be a
 -- piece with somewhere to go, not merely the first vertical one
 ld(1)
 local vi,dir
 for i=2,#pcs do
  local p=pcs[i]
  if p.d==1 and not vi then
   if p.y>0 and not at(p.x,p.y-1,i) then vi=i dir=-1 end
   if p.y+p.l<6 and not at(p.x,p.y+p.l,i) then vi=i dir=1 end
  end
 end
 ok(vi!=nil,"no vertical piece on lv1 has room to waste a move")
 hd=vi
 for k=1,400 do
  if st!=0 then break end
  local m0=moves
  mv(0,dir)
  if moves==m0 then dir=-dir end
 end
 ok(st==4,"overspending did not detonate (st="..st..")")
 ok(moves==prs[1]+1,"detonated at "..moves.." not "..(prs[1]+1))
 ok(hd==nil,"piece still held after detonation")


 -- mv() must accept exactly the moves the board allows, and never let a
 -- piece leave its own axis. at() is the oracle for "is that cell free".
 for n=1,#lvs,3 do
  ld(n)
  hd=1
  moves=0
  mv(0,1)
  ok(moves==0,"lv"..n.." main piece moved vertically")
  for i=2,#pcs do
   local p=pcs[i]
   for s=-1,1,2 do
    local dx=p.d==0 and s or 0
    local dy=p.d==1 and s or 0
    local ex,ey=p.x,p.y
    if s>0 then
     ex+=p.d==0 and p.l or 0
     ey+=p.d==1 and p.l or 0
    else
     ex-=p.d==0 and 1 or 0
     ey-=p.d==1 and 1 or 0
    end
    local free=ex>=0 and ex<6 and ey>=0 and ey<6
     and not at(ex,ey,i)
    hd=i
    moves=0
    mv(dx,dy)
    ok((moves==1)==free,"lv"..n.." piece "..i.." dir "..s.." wrongly "..(free and "refused" or "allowed"))
    if moves==1 then
     moves=0
     mv(-dx,-dy)
    end
    moves=0
    mv(p.d==0 and 0 or s,p.d==0 and s or 0)
    ok(moves==0,"lv"..n.." piece "..i.." moved off its axis")
   end
  end
 end

 -- neither button may be swallowed by the drive-out
 -- animation: one tap ends it, the next passes the level
 ld(1)
 hd=1
 pcs[1].x=4
 mv(1,0)
 ok(st==1,"exit did not start the drive-out")
 press(32)
 ok(st==2,"x during the drive-out did not cut to the panel (st="..st..")")
 press(32)
 ok(lv==2,"x on the panel did not pass the level (lv="..lv..")")

 -- and o must work exactly the same, since the
 -- panel offers both buttons
 ld(1)
 hd=1
 pcs[1].x=4
 mv(1,0)
 press(16)
 ok(st==2,"o during the drive-out did not cut to the panel (st="..st..")")
 press(16)
 ok(lv==2,"o on the panel did not pass the level (lv="..lv..")")

 -- the cursor must reach every cell of the 6x6 board
 ld(1)
 tap(2,20)
 ok(cx==5,"cursor stops at x="..cx)
 tap(8,20)
 ok(cy==5,"cursor stops at y="..cy)
 tap(1,20)
 ok(cx==0,"cursor stops at x="..cx)
 tap(4,20)
 ok(cy==0,"cursor stops at y="..cy)

 -- o is no longer a game button: x alone grabs and
 -- drops, and o only does anything when held down
 ld(1)
 press(16)
 ok(hd==nil,"a tap of o grabbed a piece")
 cx=pcs[1].x cy=er
 press(32)
 ok(hd==1,"x did not grab the piece under the cursor")
 press(16)
 ok(hd==1,"a tap of o dropped the piece")
 press(32)
 ok(hd==nil,"x did not drop the piece")

 -- disturb the board, then hold o: it must come back
 ok(nudge(),"no piece on lv1 can move")
 ok(moves==1,"the setup move was not counted")
 hold(16,32)
 ok(moves==0,"holding o did not reset the level")
 ok(rh<0,"the reset did not latch until release")
 -- still held, so it must not fire a second time
 ok(nudge(),"no piece can move after the reset")
 hold(16,40)
 ok(moves==1,"a held o reset again without a release")
 sb=0 spb=0 _ru()
 ok(rh==0,"releasing o did not clear the gauge")

 -- p8scii double-size title actually doubles
 cls()
 local w=print("\^w\^tabc",0,0,7)
 ok(w==24,"wide title width "..w.." (want 24)")
 local low=0
 for y=0,20 do
  for x=0,30 do
   if pget(x,y)!=0 then low=y end
  end
 end
 ok(low>=8,"tall title only reaches y="..low)

 -- audio routing: the bed owns 0-2, gameplay sfx get channel 3
 music(0)
 sfx(0,3)
 ok(stat(19)==0,"gameplay sfx not on channel 3 (ch3="..stat(19)..")")
 ok(stat(16)>=8,"music not on channel 0 (ch0="..stat(16)..")")
 ok(stat(17)>=8,"music not on channel 1 (ch1="..stat(17)..")")
 ok(stat(18)>=8,"music not on channel 2 (ch2="..stat(18)..")")

 -- title menu: which entries exist depends on
 -- what is saved. these run last, so every
 -- solved flag from the replay is still there
 dset(63,10)
 tt()
 ok(#tm==3,"menu has "..#tm.." entries with progress, want 3")
 ok(tm[1]=="continue","first entry is "..tm[1])
 ok(tm[3]=="erase progress","third entry is "..tm[3])
 ok(sel==1,"selection did not reset to the top")

 -- the cursor clamps at both ends
 press(4)
 ok(sel==1,"up past the top moved to "..sel)
 for k=1,5 do press(8) end
 ok(sel==3,"down past the bottom moved to "..sel)

 -- erasing takes two presses, and o backs out
 press(32)
 ok(st==7,"erase did not open the confirm (st="..st..")")
 ok(dget(63)==10,"one press erased before confirming")
 ok(sv()==#lvs,"one press cleared solved flags")
 press(16)
 ok(st==6,"o did not back out of the confirm (st="..st..")")
 ok(dget(63)==10,"backing out still wiped the unlock point")
 ok(sv()==#lvs,"backing out still cleared solved flags")

 -- confirming really does clear it
 sel=3
 press(32)
 ok(st==7,"erase did not reopen the confirm")
 press(32)
 ok(st==6,"confirm did not return to the title (st="..st..")")
 ok(sv()==0,"solved flags survived the erase: "..sv())
 ok(dget(63)==0,"unlock point survived the erase: "..dget(63))
 ok(#tm==1 and tm[1]=="start","menu after erase has "..#tm.." entries, want just start")

 -- continue jumps to the saved level
 dset(63,7)
 tt()
 ok(tm[sel]=="continue","top entry is "..tm[sel])
 press(32)
 ok(lv==7,"continue loaded level "..lv)
 ok(st==0,"continue did not start play (st="..st..")")
 dset(63,0)

 printh(fails==0 and "ALL TESTS PASS" or (fails.." FAILURES"))
 extcmd("shutdown")
end
