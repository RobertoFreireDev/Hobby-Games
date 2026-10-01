-- screen dumps. `pico8 -x` never calls _draw, so every shot calls it by hand
-- and then writes the framebuffer to shot.p8l as 128 hex digits a row.
--   node mktest.js && pico8 -x shot.p8 && node ../../shot2png.js shot.p8l shot.png
gi,gd=_init,_draw
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

-- settle the drop animation so the board is drawn standing
function settle()
 for i=1,200 do
  lnd=true
  for t in all(ts) do
   if t.dly>0 then t.dly-=1 lnd=false
   elseif t.ay<0 then t.vy+=1.4 t.ay+=t.vy
    if t.ay>=0 then t.ay=0 t.vy=0 end
    lnd=false
   end
   t.rv=0
  end
  if cur then cx=tx(cur) cy=ty(cur) end
  if lnd then return end
 end
end

-- put the cursor on the nth buried stone, and mark a few of them so the
-- grey tiles are shown carrying guesses as well as question marks
function marks()
 local i=0
 for t in all(ts) do
  if t.hd then
   i+=1
   if i%2==1 then t.fl=(i%6)+1 end
   if i==3 then cur=t cx=tx(t) cy=ty(t) end
  end
 end
end

 -- the game's own _init still has to run: it sets the palette and the state
function _init()
 gi()
 unl=nlv
 st=0 gd() dump()                         -- title
 st=4 gd() dump()                         -- how to play
 pst=nil st=6 gd() dump()                 -- law glyphs, taught example
 start(5) settle() gd() dump()            -- a board, mid ladder
 marks() gd() dump()                      -- marks on the buried stones
 oh=20 gd() dump()                        -- hold O: the laws in words
 oh=0
 pst=2 st=6 gd() dump()                   -- law glyphs off this board
 st=2
 start(12) settle() gd() dump()           -- the widest board
 tstart(3) settle() gd() dump()           -- a lesson with laws
 tstart(4) settle() gd() dump()

 -- the dead-end screen: every buried stone turned face up on its grey
 start(7) settle() tut=0
 st=5 rvl=true why=2 twin={ts[1],ts[2]}
 gd() dump()

 start(1) settle() st=3 rd=1 scr=1300 gd() dump()   -- cleared stamp
 printh("SHOTS OK")
 extcmd("shutdown")
end
