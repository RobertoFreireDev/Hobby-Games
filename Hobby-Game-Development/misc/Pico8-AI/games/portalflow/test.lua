-- test harness: path logic, the portal edge cases from DESIGN.md 3.4, the
-- win condition, and one scripted playthrough through the real input path.
--   node mktest.js && pico8 -x test.p8
nok=0 nbad=0
function ok(c,m)
 nok+=1
 if not c then nbad+=1 printh("FAIL "..m) end
end
function eq(a,b,m)
 ok(a==b,m.." got "..tostr(a).." want "..tostr(b))
end

-- synthetic input. capture the real callbacks first: overriding the globals
-- is the whole trick, and it would otherwise steal them from the tests too.
_ru=_update60
_rd=_draw
sb=0 spb=0
function btn(b,p) if b==nil then return sb end return (sb\(2^b))%2>=1 end
function btnp(b,p) if b==nil then return sb end return ((sb\(2^b))%2>=1) and ((spb\(2^b))%2<1) end
function _draw() end
function _update60() end

bit={l=1,r=2,u=4,d=8,o=16,x=32}
-- run one scripted token per two frames so btnp sees a real edge
function play(s)
 for t in all(split(s," ")) do
  sb=bit[t] or 0
  _ru() spb=sb
  sb=0
  _ru() spb=0
 end
end

-- one press-and-release of a raw button bit
function press(b)
 sb=b _ru() spb=sb
 sb=0 _ru() spb=0
end
-- hold a button down for n frames, then release
function hold(b,n)
 for i=1,n do sb=b _ru() spb=sb end
 sb=0 _ru() spb=0
end

function npath(f) return #fl[f].p end

function tests()
 -- ---------------------------------------------------------- parse
 loadlv(2)                       -- "1..p" "2..." "2..." "p..1"
 eq(bw,4,"lv2 width") eq(bh,4,"lv2 height") eq(nf,2,"lv2 colours")
 eq(pa,4,"portal a index") eq(pb,13,"portal b index")
 eq(ox,32,"4x4 ox") eq(oy,32,"4x4 oy")

 -- ------------------------------------------------- grab / extend / retrace
 grabat(ix(0,0))
 eq(gr,1,"grab starts colour 1") eq(npath(1),1,"fresh path is one tile")
 ok(ext(2),"extend east") eq(npath(1),2,"path grew") eq(mv,1,"move counted")
 ok(ext(4),"retrace west") eq(npath(1),1,"retrace shrank the path")
 eq(co[ix(1,0)],0,"retraced tile freed")

 -- --------------------------------------------- portal traversal (3.2)
 loadlv(2) grabat(ix(0,0))
 ext(2) ext(2)                   -- (1,0) (2,0)
 ok(ext(2),"enter portal a")
 eq(npath(1),5,"portal costs two path entries")
 eq(co[pa],1,"portal a owned") eq(co[pb],1,"portal b owned")
 eq(pw,1,"portal owner recorded")
 eq(fl[1].p[5],pb,"head teleported to the twin")
 eq(cx,0,"cursor followed to b (x)") eq(cy,3,"cursor followed to b (y)")

 -- from b, the only orthogonal route back into a is refused (3.4)
 ok(not ext(1),"no re-entry from b upward")

 -- retrace back through the pair frees both tiles at once (3.2.5)
 ok(not ext(4),"west off the board does not extend")
 ok(pback(4),"reverse of the entry direction pulls back out")
 eq(npath(1),3,"both portal tiles dropped")
 eq(pw,0,"portal released") eq(co[pa],0,"portal a freed") eq(co[pb],0,"portal b freed")

 -- -------------------------------- a second colour cannot take a held pair
 loadlv(2) grabat(ix(0,0))
 ext(2) ext(2) ext(2)            -- colour 1 now holds the portal
 eq(pw,1,"colour 1 holds the pair")
 grabat(ix(0,1))                 -- colour 2
 eq(gr,2,"grabbed colour 2")
 ext(2) ext(2) ext(2)            -- (1,1) (2,1) (3,1)
 eq(npath(2),4,"colour 2 walked to the portal's neighbour")
 ok(not ext(1),"entry rejected while another pipe holds the pair")
 eq(npath(2),4,"rejected move changed nothing")
 eq(pw,1,"ownership unchanged")

 -- ---------------- truncating the owner elsewhere frees the pair instantly
 loadlv(2) grabat(ix(0,0))
 ext(2) ext(2) ext(2)
 grabat(ix(0,1)) ext(2) ext(2)   -- colour 2 at (2,1)
 ok(ext(1),"colour 2 crosses colour 1 at (2,0)")
 eq(pw,0,"portals freed when their owner was truncated")
 eq(co[pa],0,"portal a free after truncation")
 eq(npath(1),2,"colour 1 truncated at the crossed tile")

 -- ------------------------------------------------- crossing your own pipe
 loadlv(2) grabat(ix(0,0))
 ext(2) ext(3) ext(2) ext(1)     -- (1,0)(1,1)(2,1)(2,0)
 eq(npath(1),5,"four steps drawn")
 ok(ext(4),"step back onto own earlier tile")
 eq(npath(1),2,"self-cross truncates to that tile")

 -- ------------------------- a colour cannot close a loop onto its own start
 loadlv(4) grabat(ix(0,0))       -- flow 1 runs (0,0) to (4,2)
 ext(2) ext(3) ext(4)            -- (1,0)(1,1)(0,1): back beside the start dot
 eq(npath(1),4,"walked round beside the start dot")
 ok(not ext(1),"stepping onto your own start dot is refused")
 ok(not fl[1].dn,"and it certainly does not count as connected")
 eq(npath(1),4,"path unchanged")

 -- ---------------------------------- re-grabbing a dot starts that colour over
 loadlv(2) grabat(ix(0,0))
 ext(2) ext(2)
 eq(npath(1),3,"three tiles drawn")
 grabat(ix(0,0))
 eq(npath(1),1,"re-grabbing the dot cleared the old path")
 eq(co[ix(1,0)],0,"and freed its tiles")
 -- grabbing the far endpoint works the same way, running the path backwards
 loadlv(2) grabat(ix(0,2))       -- colour 2's second dot
 eq(gr,2,"grabbed from the b end")
 ok(ext(1),"step north toward the twin")
 ok(fl[2].dn,"connected running backwards")

 -- -------------------------------------------------- undo and clear (2)
 loadlv(2) st=2
 grabat(ix(0,1)) ext(3)          -- connect colour 2
 ok(fl[2].dn,"colour 2 joined") eq(#hs,1,"one colour on the undo stack")
 grabat(ix(0,0)) ext(2)
 press(16)                       -- tap o
 ok(not fl[2].dn,"undo took back the last completed colour")
 eq(npath(2),0,"its path is gone")
 hold(16,62)                     -- hold o
 eq(npath(1),0,"hold cleared the board")
 eq(gr,0,"and dropped the grab")

 -- ------------------------------- the connect pulse runs the pipe and stops
 loadlv(2) st=2
 grabat(ix(0,1)) ext(3)
 eq(fl[2].pl,0,"pulse armed the moment the colour joined")
 for i=1,4 do sb=0 _ru() spb=0 end
 eq(fl[2].pl,4,"pulse advances a tile a frame")
 for i=1,20 do sb=0 _ru() spb=0 end
 ok(fl[2].pl==nil,"pulse stops once it runs off the end")
 wipe(2)
 ok(fl[2].pl==nil,"clearing a colour disarms its pulse")

 -- --------------- crossing someone else's pipe shows what it cost them (9)
 loadlv(2) st=2
 grabat(ix(0,0)) ext(2) ext(2)     -- colour 1 out to (2,0)
 grabat(ix(0,1)) ext(2)            -- colour 2 at (1,1)
 ps={}
 ok(ext(1),"colour 2 crosses colour 1 at (1,0)")
 ok(#ps>0,"the lost tail flashed as it went")
 eq(npath(1),1,"and colour 1 lost the crossed tile and everything past it")

 -- ---------------------------------------- save bitfield, including bit 15
 local keep=cl
 cl=0
 for n=1,16 do cl=cl|(1<<(n-1)) end
 for n=1,16 do ok(cld(n),"level "..n.." reads back cleared") end
 cl=0
 ok(unl(1),"level 1 is always unlocked")
 ok(not unl(2),"level 2 is locked until 1 is cleared")
 cl=1
 ok(unl(2),"clearing 1 unlocks 2")
 ok(not unl(3),"but not 3")
 cl=keep

 -- ------------------------------- connected but not full is not a win (2.5)
 loadlv(1) st=2                  -- "1..." "23.1" ".3.2" "...."
 grabat(ix(1,1)) ext(3)                                  -- colour 3
 grabat(ix(0,1)) ext(3) ext(3) ext(2) ext(2) ext(2) ext(1)  -- colour 2
 grabat(ix(0,0)) ext(2) ext(2) ext(2) ext(3)             -- colour 1
 sb=0 spb=0 _ru()
 eq(ncon,3,"every colour connected")
 eq(nfil,14,"but only 14 of 16 tiles covered")
 eq(st,2,"still playing")
 ok(warn,"the game flagged the gap")
 ok(msk>0,"and shook the fill meter")

 -- --------------------------------------------- a full solve through input
 loadlv(2) st=2
 play("x r r d l d r r u u r r r")     -- colour 1, through the portal
 eq(ncon,1,"colour 1 joined")
 play("l l l u u x d")                 -- colour 2
 eq(nfil,16,"board covered")
 eq(st,3,"win state entered")
 ok(cld(2),"level 2 marked cleared")
 ok(bm[2]>0,"a best-move count was stored")

 -- ------------------------------- the clear survives a reboot, and the wipe
 -- clears cartdata too, not just the in-memory copy
 eq(dget(0)&2,2,"the cleared bit reached cartdata")
 eq(dget(2),bm[2],"and so did the best-move count")
 -- reboot: cartdata() may only be called once per run, so replay just the
 -- part of _init that restores progress
 local was=bm[2]
 cl=0 for i=1,16 do bm[i]=0 end
 cl=dget(0) for i=1,16 do bm[i]=dget(i) end
 ok(cld(2),"level 2 still cleared after a reload")
 eq(bm[2],was,"best moves survived the reload")

 wipep()
 ok(not cld(2),"clear progress dropped the cleared flag")
 eq(bm[2],0,"and the best-move count")
 eq(dget(0),0,"cartdata cleared flags wiped")
 eq(dget(2),0,"cartdata best moves wiped")
 eq(msc,1,"the cursor went back to level 1")
 cl=99 for i=1,16 do bm[i]=99 end
 cl=dget(0) for i=1,16 do bm[i]=dget(i) end
 ok(not cld(2),"and the wipe survives a reload")
 eq(bm[2],0,"with no stale best move")

 -- ------------------------------------------------ every level still loads
 for n=1,16 do
  loadlv(n)
  eq(nfil,0,"lv"..n.." starts empty")
  ok(nf>=2 and nf<=7,"lv"..n.." colour count")
 end
end

gi=_init
function _init()
 gi()
 tests()
 -- leave no progress behind: the tests share the real cartdata slot
 cl=0 dset(0,0)
 for i=1,16 do bm[i]=0 dset(i,0) end
 printh("TESTS "..(nok-nbad).."/"..nok.." passed, "..nbad.." failed")
 extcmd("shutdown")
end
