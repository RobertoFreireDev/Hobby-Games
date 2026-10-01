-- perf harness: 60fps is a design requirement, so measure the draw instead of
-- assuming it.
--
-- stat(1) reads 0 under `pico8 -x` — the frame timer is never driven — so a
-- harness built on it reports a comfortable "ok" from a null reading and tests
-- nothing. This one times a batch of real _draw calls against the wall clock
-- (stat(93..95), local h/m/s) and reports throughput in draws per second. It
-- refuses to pass if the clock did not move.
--   node mktest.js perf && pico8 -x perf.p8
gi,gd=_init,_draw
function _update60() end

function clk() return stat(93)*3600+stat(94)*60+stat(95) end

-- 60fps needs a draw plus an update inside 1/60s. Ask for 2x headroom: a
-- scene has to sustain at least 120 draws a second.
budget=120
bad=0
function bench(label,n)
 local t0=clk()
 -- wait for a tick boundary so a whole second is never lost to rounding
 while clk()==t0 do end
 t0=clk()
 for i=1,n do tk+=1 gd() end
 local el=clk()-t0
 if el<0 then el+=86400 end
 if el<=0 then
  printh(label.."  UNMEASURABLE (clock did not move)")
  bad+=1
  return
 end
 local rate=n/el
 printh(label.."  "..n.." draws in "..el.."s = "..flr(rate).." draws/sec"..
        (rate<budget and "   OVER BUDGET" or ""))
 if rate<budget then bad+=1 end
end

-- time one piece of the frame, same clock discipline as bench
function part(label,n,f)
 local t0=clk()
 while clk()==t0 do end
 t0=clk()
 for i=1,n do f() end
 local el=clk()-t0
 if el<0 then el+=86400 end
 printh(label.."  "..(el<=0 and "under 1s for "..n.." calls" or (n.." in "..el.."s = "..flr(n/el).."/sec")))
end

function _init()
 gi()

 -- worst case: the 7x7 board, seven colours, every tile covered, the win
 -- flash running and the particle pool full
 st=2 loadlv(16)
 for f=1,nf do
  grabat(fl[f].a)
  for k=1,6 do
   -- ext clears gr the moment a colour joins, so re-check every step
   if gr==0 then break end
   for d=1,4 do if ext(d) then break end end
  end
 end
 gr=0
 for i=1,bw*bh do if co[i]==0 then co[i]=1+i%nf end end
 for i=1,40 do
  add(ps,{x=rnd(128),y=rnd(128),vx=0,vy=0,c=7,l=9999})
 end
 ncon=nf nfil=bw*bh
 bench("7x7 full board + 40 particles",1800)

 -- where the frame actually goes
 local w,h=bw*16,bh*16
 part("  vignette, board-sized hole ",1800,function() bgv(ox-1,oy-1,ox+w+1,oy+h+1) end)
 part("  vignette, full             ",1800,function() bgv() end)
 part("  49 empty tiles             ",1800,function()
  for i=1,bw*bh do spr(0,ox+(i-1)%bw*16,oy+flr((i-1)/bw)*16,2,2) end end)
 part("  hud                        ",1800,drhud)

 st=3 wt=20
 bench("7x7 win flash               ",600)

 st=1
 bench("level select                ",600)

 st=2 loadlv(2) trn=15 nst=1
 bench("4x4 board mid transition    ",600)

 printh("PERF "..(bad==0 and "ok" or (bad.." SCENES OVER BUDGET OR UNMEASURED")))
 extcmd("shutdown")
end
