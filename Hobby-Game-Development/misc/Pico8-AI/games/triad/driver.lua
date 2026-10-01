
-- test driver: logic assertions + a scripted play-through
fails=0
function ok(c,m)
 if not c then fails+=1 printh("FAIL "..m) end
end

-- card model
ok(istrio(0,1,2),"all-diff number")
ok(istrio(0,0,0),"all same")
ok(istrio(0,3,6),"all-diff shape")
ok(istrio(0,40,80),"diagonal")
ok(not istrio(0,1,3),"non trio")
ok(comp(0,1)==2,"comp 0,1")
ok(comp(0,0)==0,"comp same")
ok(istrio(5,17,comp(5,17)),"comp makes trio")
for i=1,200 do
 local a,b=flr(rnd(81)),flr(rnd(81))
 if a!=b then
  local c=comp(a,b)
  ok(c>=0 and c<81,"comp range")
  ok(c!=a and c!=b,"comp distinct")
  ok(istrio(a,b,c),"comp valid")
 end
end

-- generators
local loaded,raw=0,0
for n=1,60 do
 board={} backlog={} mkdeck()
 local b=gboard()
 ok(b and #b==9,"board size")
 local seen={}
 for v in all(b) do
  ok(not seen[v],"board dup")
  seen[v]=true
 end
 ok(#scan(b)>=2,"board >=2 trios")
 board=b
 local k=gback()
 ok(#k==3,"backlog size")
 for v in all(k) do
  ok(not seen[v],"backlog dup vs board")
 end
 ok(k[1]!=k[2] and k[2]!=k[3] and k[1]!=k[3],"backlog dup")
 if istrio(k[1],k[2],k[3]) then loaded+=1 else raw+=1 end
end
printh("LOADED="..loaded.." RAW="..raw)

-- scan sanity on a known board
local kb={0,1,2,3,4,5,6,7,8}
ok(#scan(kb)>0,"scan finds")
kb[1]=nil
local s=scan(kb)
for t in all(s) do ok(t[1]!=1,"scan skips holes") end

-- the tutorial copy must agree with
-- the cards it sits under
function pval(c,i)
 local v=1
 for j=2,i do v*=3 end
 return (c[1]\v)%3,(c[2]\v)%3,(c[3]\v)%3
end
for pg=1,3 do
 local d=tut[pg]
 ok(#d.c==3,"tut page has 3 cards")
 ok(#d.p==4,"tut page has 4 property lines")
 ok(istrio(d.c[1],d.c[2],d.c[3])==(d.b==0),
  "page "..pg.." trio claim")
 for i=1,4 do
  local a,b,e=pval(d.c,i)
  local same=(a==b and b==e)
  local diff=(a!=b and b!=e and a!=e)
  local h=sub(d.p[i],1,7)
  if h=="all the" then
   ok(same,"page "..pg.." prop "..i.." says same")
   ok(i!=d.b,"a matching prop cannot be the failure")
  elseif h=="all dif" then
   ok(diff,"page "..pg.." prop "..i.." says different")
   ok(i!=d.b,"a differing prop cannot be the failure")
  else
   ok(i==d.b,"prose line must be the failing prop")
   ok(not same and not diff,"failing prop is neither")
  end
 end
end

-- scripted play-through: drive the real
-- state machine through many turns
sb=0 spb=0
function btn(b,pl)
 if b==nil then return sb end
 return (sb\(2^b))%2>=1
end
function btnp(b,pl)
 if b==nil then return sb end
 return ((sb\(2^b))%2>=1) and ((spb\(2^b))%2<1)
end

_ru=_update
_rd=_draw
function _draw() end

turns=0
overs=0
didtut=false
tutseen={}
frames=0
plan={}
function _update()
 frames+=1
 sb=0
 if st=="title" then
  sb=didtut and 32 or 16
 elseif st=="tut" then
  tutseen[tpage]=true
  sb=32
 elseif st=="over" then
  overs+=1
  sb=32
 elseif st=="play" then
  if #plan==0 then
   -- pick a real trio if one exists,
   -- else a deliberate bad triple
   local t=bt[1]
   if t and frames%7!=0 then
    plan={t[1],t[2],t[3]}
   else
    local c={}
    for i=1,9 do if board[i] then add(c,i) end end
    plan={c[1],c[2],c[3]}
   end
   turns+=1
  end
  local want=plan[1]
  if cur==want then
   sb=32
   if frames%2==0 then deli(plan,1) end
  else
   local r,c=(cur-1)\3,(cur-1)%3
   local wr,wc=(want-1)\3,(want-1)%3
   if r!=wr then sb=(wr>r) and 8 or 4
   else sb=(wc>c) and 2 or 1 end
  end
 else
  plan={}
 end
 if frames%2==1 then sb=0 end
 if frames==2 then printh("MUSICROUTE_TITLE "..stat(16).." "..stat(17).." "..stat(18).." "..stat(19)) end
 if frames==400 then printh("MUSICROUTE_PLAY "..stat(16).." "..stat(17).." "..stat(18).." "..stat(19)) end
 if st=="play" then
  ok(stat(16)>=16 and stat(16)<32,"ch0 is music")
  ok(stat(17)>=16 and stat(17)<32,"ch1 is music")
 end
 _ru()
 _rd()
 if st=="tut" then didtut=true end
 spb=sb
 -- invariants every frame
 if st=="play" then
  local n=0
  for i=1,9 do if board[i] then n+=1 end end
  ok(n==9,"9 cards in play")
  ok(#backlog==3,"3 backlog in play")
  local seen={}
  for i=1,9 do
   ok(not seen[board[i]],"dup on board")
   seen[board[i]]=true
  end
  for i=1,3 do
   ok(not seen[backlog[i]],"backlog dup vs board")
   seen[backlog[i]]=true
  end
  ok(#sel<3,"sel never 3 in play")
 end
 ok(score>=0,"score >=0")
 ok(chain>=1 and chain<=5,"chain range")
 ok(#parts<=52,"particle cap")
 if frames>=1800 then
  for i=1,3 do ok(tutseen[i],"tutorial page "..i.." was shown") end
  printh("TURNS="..turns.." OVERS="..overs.." FAILS="..fails)
  printh(fails==0 and "ALL OK" or "HAD FAILURES")
  extcmd("shutdown")
 end
end
