-- smoke harness: load every level, check the parse invariants, exit clean.
--   node mktest.js && pico8 -x smoke.p8
gi=_init
function _draw() end

function _init()
 gi()
 local bad=0
 for n=1,16 do
  loadlv(n)
  local pc,dc=0,0
  for i=1,bw*bh do
   if ck[i]==2 then pc+=1 end
   if ck[i]==1 then dc+=1 end
  end
  local why=""
  -- a portal is a pair or it is nothing
  if pc!=0 and pc!=2 then why=why.." portals="..pc end
  if pc==2 and (pa==0 or pb==0 or pa==pb) then why=why.." portalidx" end
  -- every colour appears exactly twice and 1..nf are all present
  if dc!=nf*2 then why=why.." dots="..dc.."/"..nf end
  for f=1,nf do
   local q=fl[f]
   if not q then why=why.." missing"..f
   elseif q.a==q.b then why=why.." single"..f end
  end
  if nf<2 or nf>7 then why=why.." nf="..nf end
  if nf>bw then why=why.." colours>width" end
  -- a dot never sits on a portal tile
  for i=1,bw*bh do
   if ck[i]==2 and cd[i]!=0 then why=why.." dotonportal" end
  end
  -- the board is centred and on screen
  if ox<0 or oy<0 or ox+bw*16>128 or oy+bh*16>128 then why=why.." offscreen" end
  if why!="" then bad+=1 end
  printh("lv"..n.." "..bw.."x"..bh.." cols="..nf.." portals="..pc..
         " tiles="..(bw*bh)..(why=="" and " ok" or (" BAD"..why)))
 end
 printh("SMOKE bad="..bad)
 extcmd("shutdown")
end
