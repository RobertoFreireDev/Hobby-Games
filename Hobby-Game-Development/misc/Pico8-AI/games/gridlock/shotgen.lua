-->8
-- screenshot harness (harness only)
_rd=_draw
function _draw() end

function dump(name)
 _rd()
 for y=0,127 do
  local r=""
  for x=0,127 do
   r=r..sub("0123456789abcdef",pget(x,y)+1,pget(x,y)+1)
  end
  printh(r,name)
 end
end

sh=0
function _update()
 sh+=1
 if sh==1 then
  -- a fresh save: only "start"
  dset(63,0)
  for i=0,11 do dset(i,0) end
  tt()
  tk=10
  dump("shot_title_new")
  -- and a save partway in: the full menu
  dset(63,8)
  for i=0,7 do dset(i,1) end
  tt()
  sel=3
  tk=10
  dump("shot_title")
  st=7
  dump("shot_erase")
  dset(63,0)
  for i=0,7 do dset(i,0) end
  st=6
 elseif sh==2 then
  ld(1)
  tk=10
  dump("shot_play1")
 elseif sh==3 then
  ld(12)
  hd=3
  tk=2
  dump("shot_play12")
 elseif sh==4 then
  ld(9)
  boom()
  for k=1,3 do
   et+=1
   for p in all(pcs) do p.ox+=p.vx p.oy+=p.vy p.vy+=0.25 end
  end
  dump("shot_boom3")
  for k=1,7 do
   et+=1
   for p in all(pcs) do p.ox+=p.vx p.oy+=p.vy p.vy+=0.25 end
  end
  dump("shot_boom10")
  for k=1,10 do
   et+=1
   for p in all(pcs) do p.ox+=p.vx p.oy+=p.vy p.vy+=0.25 end
  end
  dump("shot_boom20")
 elseif sh==5 then
  ld(7)
  moves=prs[7]
  st=2
  tk=10
  dump("shot_clear")
  -- the last level says "finish", not "next"
  ld(12)
  moves=prs[12]
  st=2
  dump("shot_finish")
 elseif sh==6 then
  ld(7)
  moves=prs[7]+1
  st=5
  tk=10
  dump("shot_fail")
 elseif sh==7 then
  st=3
  tk=10
  dump("shot_allclear")
 else
  extcmd("shutdown")
 end
end
