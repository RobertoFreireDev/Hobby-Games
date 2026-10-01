-- screen dumps. `pico8 -x` never calls _draw, so every shot calls the game's
-- own _draw by hand and then writes the framebuffer out as hex.
--   node mktest.js && pico8 -x shot.p8 && node ../../shot2png.js shot.p8l shot.png
gi,gd,gu=_init,_draw,_update60
hx="0123456789abcdef"

function dump()
 for y=0,127 do
  local s=""
  for x=0,127 do
   local v=peek(0x6000+y*64+flr(x/2))
   local n=(x%2==0) and (v%16) or flr(v/16)
   s=s..sub(hx,n+1,n+1)
  end
  printh(s,"shot")
 end
end

-- walk a path out from a dot without going through the input layer
function pth(f,...)
 grabat(f)
 for d in all({...}) do ext(d) end
end

function _init()
 gi()

 -- level select, fresh save: one card unlocked, fifteen locked
 st=1 cl=0
 for i=1,16 do bm[i]=0 end
 msc=1 tk=0
 gd() dump()

 -- level select with progress: cleared cards, best counts, a star pop
 cl=0b0000000001111111
 for i=1,7 do bm[i]=12+i*3 end
 msc=8 popn=7 pop=22
 gd() dump()

 -- level 1, part drawn: a pipe head, an idle dot pulse, the fill meter
 st=2 loadlv(1) tk=30
 pth(ix(1,1),3)
 pth(ix(0,1),3,3,2,2,2,1)
 pth(ix(0,0),2,2)
 ncon=0 nfil=0
 for f=1,nf do if fl[f].dn then ncon+=1 end end
 for i=1,bw*bh do if co[i]!=0 then nfil+=1 end end
 gd() dump()

 -- level 2: a pipe through the portal, both tiles lit in its colour
 loadlv(2)
 pth(ix(0,0),2,2,2,2)
 ncon=0 nfil=0
 for i=1,bw*bh do if co[i]!=0 then nfil+=1 end end
 cx,cy=cxy(fl[1].p[#fl[1].p]) dcx,dcy=cx,cy gr=1
 gd() dump()

 -- level 7, 6x6 with a portal pair, untouched: the idle board
 loadlv(7) gr=0 cx,cy=2,2 dcx,dcy=2,2
 gd() dump()

 -- level 16, 7x7 seven colours: the worst case for margins and glyphs
 loadlv(16)
 gd() dump()

 -- the "all connected, board not full" state the whole design hangs on
 loadlv(1) st=2
 pth(ix(1,1),3)
 pth(ix(0,1),3,3,2,2,2,1)
 pth(ix(0,0),2,2,2,3)
 gu()   -- the real one: the stub below would steal the name
 msk=40 tk=0
 gd() dump()

 -- the win flash mid-wave
 loadlv(2) st=3 wt=30
 pth(ix(0,0),2,2,3,4,3,2,2,1,1,2,2,2)
 pth(ix(0,1),3)
 gd() dump()

 -- art check at 2x: a real run of tiles laid edge to edge, so the joins are
 -- judged at the seams. cap -> elbow -> straight -> portal with its stub.
 cls(1) pdef()
 for i=0,3 do sspr(0,0,16,16,8+(i%2)*32,16+(i\2)*32,32,32) end
 sspr(0,0,16,16,40,48,32,32) sspr(0,0,16,16,72,48,32,32)
 pcol(1)
 sspr(16,0,16,16,8,16,32,32)     -- straight v, above the bend
 sspr(48,0,16,16,8,48,32,32)     -- elbow n-e
 sspr(32,0,16,16,40,48,32,32)    -- straight h
 sspr(0,16,16,16,72,48,32,32)    -- portal ring, owner tinted
 sspr(80,16,16,16,72,48,32,32)   -- portal stub, entering from the west
 pdef()
 sspr(96,0,16,16,8,96,32,32)     -- dot idle
 sspr(112,0,16,16,44,96,32,32)   -- dot connected
 for f=0,3 do sspr(f*16,16,16,16,80+f*12,96,12,12) end
 dump()

 printh("SHOTS OK")
 extcmd("shutdown")
end

function _update60() end
function _draw() end
