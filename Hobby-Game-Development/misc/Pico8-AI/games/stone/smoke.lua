-- walks every screen and calls the real _draw by hand. `pico8 -x` never calls
-- _draw itself, so this is the only way a drawing error shows up headlessly.
gu,gd=_update,_draw
fr=0

function _update()
 fr+=1
 if fr==2 then st=4                    -- how to play
 elseif fr==4 then pst=nil st=6        -- law glyphs, taught example
 elseif fr==6 then start(12)           -- hardest board
 elseif fr==70 then
  -- marks on the buried stones, and the cursor sitting on one
  for t in all(ts) do
   if t.hd then t.fl=(t.c+t.r)%7 cur=t end
  end
 elseif fr==75 then oh=20              -- hold O: law panel
 elseif fr==85 then oh=0 pk=true       -- hold X: peek rims
 elseif fr==90 then scr=1234 st=3      -- cleared stamp, last level
 elseif fr==95 then rd=1 st=3          -- cleared stamp, mid run
 elseif fr==100 then
  -- dead end with a buried twin: every face turned over, no panel
  rd=12 st=5 rvl=true pk=false
  twin={ts[1],ts[2]}
 elseif fr==110 then twin={}           -- dead end with nothing matching
 elseif fr==120 then start(1) rvl=false
 elseif fr==180 then tstart(1)         -- lesson without laws
 elseif fr==200 then tstart(3)         -- lesson with laws
 elseif fr==220 then tstart(4)
 elseif fr==240 then pst=2 st=6        -- law glyphs read off a real board
 elseif fr==245 then st=0 mnu(2)       -- back to title
 elseif fr==250 then
  printh("SMOKE OK")
  extcmd("shutdown")
 end
 gu()
 gd()
end
