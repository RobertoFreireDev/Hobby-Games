
-- ==== test driver (appended after the game code) ====
tests=0 fails=0
function ok(c,m)
 tests+=1
 if not c then
  fails+=1
  printh("FAIL: "..m)
 end
end

function setsel(t)
 sel={} ss={}
 for c in all(t) do add(sel,c) ss[c]=true end
end

function land()
 for f in all(fl) do got+=1 del(fl,f) end
end

-- independent oracle: every
-- 8-connected triple fits in a 3x3
-- box, so sweep the boxes and count
-- the matches by hand.  this must
-- agree with scan(), which reaches
-- the same triples a cleverer way.
function brute(f)
 local sn={}
 local n=0
 for by=0,7 do
  for bx=0,8 do
   local cl={}
   for dy=0,2 do
    for dx=0,2 do
     add(cl,(by+dy)*11+bx+dx+1)
    end
   end
   for i=1,7 do
    for j=i+1,8 do
     for k=j+1,9 do
      local a,b,c=cl[i],cl[j],cl[k]
      if g[a]>=0 and g[b]>=0 and g[c]>=0 then
       local e=0
       if nbm[a][b] then e+=1 end
       if nbm[a][c] then e+=1 end
       if nbm[b][c] then e+=1 end
       if e>=2 and vok(g[a],g[b],g[c],f) then
        sn[a]=sn[a] or {}
        local ky=b*111+c
        if not sn[a][ky] then
         sn[a][ky]=true n+=1
        end
       end
      end
     end
    end
   end
  end
 end
 return n
end

-- no two instances share or touch a
-- cell, so clearing one can never
-- damage another
function sepok(a)
 local own={}
 for j=1,#a do
  for c in all(a[j]) do
   if own[c] then return false end
   own[c]=j
  end
 end
 for c=1,110 do
  if own[c] then
   for b in all(nbc[c]) do
    if own[b] and own[b]!=own[c] then return false end
   end
  end
 end
 return true
end

function dump()
 for r=0,9 do
  local s=""
  for c=0,10 do
   local i=r*11+c+1
   s=s..(g[i]<0 and "." or g[i])
  end
  printh(s)
 end
end
fnm={"equals","1 delta","same hue"}

function _draw() end
itn=0
seen={}
function _update()
 itn+=1
 if itn>12 then
  ok(seen[1] and seen[2] and seen[3],
   "not every family was generated")
  printh("TESTS="..tests.." FAILS="..fails)
  extcmd("shutdown")
  return
 end

 -- ---- what a pattern is ----
 ok(vok(3,3,3,1),"3,3,3 is not equals")
 ok(not vok(3,3,4,1),"3,3,4 is equals")
 ok(not vok(1,2,3,1),"1,2,3 is equals")
 ok(vok(7,8,9,2),"7,8,9 is not 1 delta")
 ok(vok(9,7,8,2),"1 delta is order-sensitive")
 ok(vok(0,1,2,2),"0,1,2 is not 1 delta")
 ok(not vok(1,1,3,2),"1,1,3 is 1 delta")
 ok(not vok(1,2,4,2),"1,2,4 is 1 delta")
 ok(not vok(5,5,5,2),"5,5,5 is 1 delta")
 ok(not vok(2,3,4,1),"2,3,4 is equals")
 -- same hue: v and v+6 draw alike
 ok(vok(0,6,0,3),"0,6,0 is not same hue")
 ok(vok(2,8,8,3),"2,8,8 is not same hue")
 ok(not vok(0,1,2,3),"0,1,2 is same hue")
 ok(not vok(3,9,4,3),"3,9,4 is same hue")
 ok(not vok(4,4,5,3),"4,4,5 is same hue")
 ok(not vok(0,6,1,3),"0,6,1 is same hue")
 -- f=3 subsumes f=1: every equals
 -- triple is also a same-hue triple
 for v=0,9 do
  ok(vok(v,v,v,3),v.." equals is not same hue")
 end

 -- ---- generator invariants ----
 newround()
 seen[tr]=true
 local ta=scan(tr)
 local hole=0
 for i=1,110 do
  if g[i]<0 then hole+=1 end
 end
 ok(hole==0,"unfilled cells: "..hole)
 ok(#ta==6,"instances "..#ta)
 ok(tot==18,"denominator "..tot)
 ok(brute(tr)==6,"brute "..brute(tr))
 ok(sepok(ta),"two instances touch")
 for o in all(ta) do
  ok(#o==3,"instance size "..#o)
 end
 -- the round's family is the only
 -- rule on the board: every triple
 -- of every family is one of the
 -- groups the generator seeded
 local own={}
 for j=1,#ta do
  for c in all(ta[j]) do own[c]=j end
 end
 for f=1,3 do
  for o in all(scan(f)) do
   local h=own[o[1]]
   ok(h and own[o[2]]==h and own[o[3]]==h,
    "stray f="..f.." triple in an f="..tr.." grid")
  end
 end
 if itn==1 then
  printh("family="..fnm[tr])
  dump()
 end

 -- ---- inst() ----
 setsel(ta[1])
 ok(inst(),"true instance rejected")
 -- matching digits are not enough:
 -- three scattered 5s, then two
 -- touching and one adrift
 g[1]=5 g[3]=5 g[100]=5
 setsel({1,3,100})
 ok(not inst(),"three scattered cells were accepted")
 g[2]=5
 setsel({1,2,100})
 ok(not inst(),"a detached third cell was accepted")
 g[1]=1 g[2]=2 g[100]=3
 setsel({1,2,100})
 ok(not inst(),"a detached 1 delta was accepted")
 -- a diagonal run of three is one
 -- of the legal shapes
 g[1]=4 g[13]=4 g[25]=4
 setsel({1,13,25})
 ok(inst(),"a diagonal line was rejected")
 g[1]=1 g[13]=2 g[25]=3
 ok(inst(),"a diagonal 1 delta was rejected")
 g[1]=0 g[13]=6 g[25]=6
 ok(inst(),"a diagonal same hue was rejected")
 -- an l bend is legal too
 g[1]=6 g[2]=6 g[13]=6
 setsel({1,2,13})
 ok(inst(),"an l bend was rejected")
 g[1]=2 g[2]=8 g[13]=2
 ok(inst(),"a same hue l bend was rejected")
 g[1]=1 g[2]=4 g[13]=9
 ok(not inst(),"an unrelated trio was accepted")

 -- ---- a short selection never commits ----
 newround()
 setsel({1})
 subm()
 ok(st==1,"1-cell submit was not ignored, st="..st)
 setsel({1,2})
 subm()
 ok(st==1,"2-cell submit was not ignored, st="..st)

 -- ---- filler is fatal ----
 newround()
 local fc={}
 local ins={}
 for o in all(scan(tr)) do
  for c in all(o) do ins[c]=true end
 end
 for i=1,108 do
  if not ins[i] and not ins[i+1]
   and not ins[i+2]
   and (i-1)%11<9 then
   fc={i,i+1,i+2}
  end
 end
 if #fc==3 then
  setsel(fc)
  subm()
  ok(st==3,"three filler cells did not lose")
 end

 -- ---- clearing every instance is exactly 100% ----
 newround()
 for j=1,7 do
  local cs=scan(tr)
  if #cs<1 then break end
  setsel(cs[1])
  subm()
  if st!=1 then break end
  land()
 end
 ok(st==1,"lost while solving, st="..st)
 ok(tot>0 and got==tot,"solve got "..got.." of "..tot)
 ok(flr(got*100/max(tot,1)+.5)==100,"final score not 100%")
 ok(#scan(tr)==0,"instances left after a solve")

 -- ---- the cursor only sits on live
 -- cells ----
 newround()
 -- cur starts at row 5, col 5
 mv(1)
 ok(cur==62,"plain step right went to "..cur)
 cur=61
 g[62]=-1 g[63]=-1
 mv(1)
 ok(cur==64,"resolved cells not skipped, cur="..cur)
 cur=61
 g[64]=-1 g[65]=-1 g[66]=-1
 mv(1)
 ok(cur==61,"moved into a dead row end, cur="..cur)
 -- a column of holes above is
 -- skipped the same way
 cur=61
 g[50]=-1 g[39]=-1
 mv(2)
 ok(cur==28,"resolved cells not skipped upward, cur="..cur)
 -- clearing under the cursor moves
 -- it to a live cell
 newround()
 local o=scan(tr)[1]
 setsel(o)
 cur=o[1]
 clr()
 ok(g[cur]>=0,"cursor left on a resolved cell")
end
