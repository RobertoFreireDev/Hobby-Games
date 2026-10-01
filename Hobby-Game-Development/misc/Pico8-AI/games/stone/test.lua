-- appended to a copy of the cart by mktest.js. overrides _init, so it runs
-- under `pico8 -x` and never touches _draw (which -x does not call).
--
-- what it proves, for every board the cart ships: the stacks hang from layer
-- 1 with nothing floating, the faces pair up, every published law is true of
-- the dealt board, the recorded order clears it without ever reaching for a
-- buried stone, and every stone lands inside its own layer panel and clear
-- of the ribbon. then it drives the mark and the pick-up by hand.
--
-- the deduction proof - that the tally and the laws leave exactly one way to
-- fill the buried cells - is levelgen.js's job and verify.js re-checks it in
-- node by brute force. nothing here re-derives it.

bad=0
function fail(s) bad+=1 printh("FAIL "..s) end
function ck(c,s) if not c then fail(s) end end

-- two stones touch when one rests on the other, or when they sit at the
-- same layer in cells that share an edge
function touch(a,b)
 if a.c==b.c and a.r==b.r then return abs(a.l-b.l)==1 end
 return a.l==b.l and abs(a.c-b.c)+abs(a.r-b.r)==1
end

function lawok(n,w)
 local k,x,y=w[1],w[2],w[3]
 for t in all(ts) do
  if k==4 then
   if t.f==x and t.l==y then fail(n.." depth broken") return end
  elseif t.f==x then
   local nr=false
   for o in all(ts) do
    if o~=t and o.f==y and touch(t,o) then nr=true end
   end
   if k==2 and not nr then fail(n.." bond broken") return end
   if k==3 and nr then fail(n.." taboo broken") return end
  elseif k==3 and t.f==y then
   for o in all(ts) do
    if o~=t and o.f==x and touch(t,o) then fail(n.." taboo broken") return end
   end
  end
 end
end

-- rebuild oc from whatever is left in ts
function reoc()
 oc={}
 for t in all(ts) do oc[key(t.c,t.r,t.l)]=t end
 refresh(true)
end

function checkboard(n,d,w,nb)
 -- n is a label ("lv3", "t2"), not a number
 deal(d)
 mklaw(w)
 local nst=#ts
 ck(nst%2==0,n.." odd stone count")
 ck(#laws<5,n.." "..#laws.." laws will not fit the ribbon")

 -- faces pair up, or the board cannot be cleared at all
 local cnt={0,0,0,0,0,0}
 for t in all(ts) do cnt[t.f]+=1 end
 for f=1,6 do ck(cnt[f]%2==0,n.." odd count of face "..f) end

 -- a stack hangs from layer 1 down: no stone floats with a hole above it,
 -- and the stone on layer 1 is the only one of its cell that starts face up
 local mx=0
 for t in all(ts) do
  if t.l>1 then ck(occ(t.c,t.r,t.l-1)~=nil,n.." floating stone at layer "..t.l) end
  ck(t.hd==(t.l>1),n.." layer "..t.l.." stone starts "..(t.hd and "buried" or "face up"))
  if t.l>mx then mx=t.l end
 end
 if nb then ck(mx>1,n.." nothing is buried") end

 for L in all(laws) do lawok(n,L) end

 -- every stone inside its own layer panel, and clear of the hud ribbon
 for t in all(ts) do
  local x,y=tx(t)-5,ty(t)-5
  local px,py=((t.l-1)%2)*64,flr((t.l-1)/2)*50
  ck(x>px+1 and x+9<px+62,n.." stone off panel "..t.l.." in x")
  ck(y>py+5 and y+9<py+49,n.." stone off panel "..t.l.." in y")
  ck(y+9<101,n.." stone under the ribbon")
 end

 -- walk the recorded order: four digits a stone, two stones a move
 for k=1,#d,8 do
  local p={}
  for j=0,1 do
   local o=k+j*4
   add(p,oc[key(tonum(sub(d,o,o)),tonum(sub(d,o+1,o+1)),tonum(sub(d,o+2,o+2)))])
  end
  if not p[1] or not p[2] then fail(n.." stone gone at "..k) return end
  ck(p[1].f==p[2].f,n.." pair faces differ at "..k)
  ck(not p[1].hd and not p[2].hd,n.." pair is buried at "..k)
  ck(anymove(),n.." dead before move "..k)
  del(ts,p[1]) del(ts,p[2]) reoc()
 end
 ck(#ts==0,n.." "..#ts.." stones left over")
 printh(n.." stones "..nst.." laws "..#laws.." deepest "..mx.." ok")
end

function _init()
 for n=1,nlv do checkboard("lv"..n,lvl[n],lws[n],true) end
 -- lesson 1 is four singles: it is the only board with nothing buried
 for n=1,#tdat do checkboard("t"..n,tdat[n],twl[n],n>1) end

 -- the loaders the game actually uses
 for n=1,nlv do
  start(n)
  ck(#laws>0,"lv"..n.." start() built no laws")
  ck(cur~=nil,"lv"..n.." no opening cursor")
  ck(cur and not cur.hd,"lv"..n.." cursor starts on a buried stone")
  ck(anymove(),"lv"..n.." dead on arrival")
  ck(not dmd(),"lv"..n.." doomed on arrival")
 end
 for n=1,#tdat do
  tstart(n)
  ck(anymove(),"t"..n.." dead on arrival")
 end

 -- the mark: o steps a buried stone through all six faces and back to none
 start(5)
 lnd=true
 local h=nil
 for t in all(ts) do if t.hd and not h then h=t end end
 if not h then fail("lv5 has nothing buried") else
  cur=h sel=nil
  for i=1,6 do
   flag()
   ck(h.fl==i,"mark step "..i.." gave "..h.fl)
  end
  flag()
  ck(h.fl==0,"mark did not come back round to none")

  -- and a buried stone can never be picked up: it gets the same refusal
  -- flash as any impossible pick, but must not cost a miss
  h.fl=3
  mis=0 mf=0
  press()
  ck(sel==nil,"a buried stone was picked up")
  ck(mf>0,"no refusal flash when x hit a buried stone")
  ck(mis==0,"x on a buried stone cost a miss")

  -- uncovering it drops the mark and turns it face up
  local up=occ(h.c,h.r,h.l-1)
  ck(up~=nil,"nothing was covering the buried stone")
  del(ts,up) oc[key(up.c,up.r,up.l)]=nil
  refresh(true)
  ck(not h.hd,"stone stayed buried after its cover left")
  ck(h.fl==0,"mark survived the reveal")
 end

 -- the cursor reaches buried stones while nothing is held, and only
 -- matching face-up ones while a stone is held
 start(6)
 lnd=true
 sel=nil
 for t in all(ts) do ck(pick(t),"pick() refused a stone while nothing was held") end
 local seen=false
 for a in all(ts) do
  for d=1,4 do
   cur=a
   nav(d)
   if cur.hd then seen=true end
  end
 end
 ck(seen,"no direction from any stone reached a buried stone")

 local a=nil
 for t in all(ts) do if not t.hd and pair(t) and not a then a=t end end
 if not a then fail("lv6 has no pair on show") else
  cur=a press()
  ck(sel==a,"a face-up stone with a partner was not picked up")
  for i=1,40 do
   nav(1+i%4)
   ck(not cur.hd and cur.f==sel.f,"held a stone and the cursor left its face")
  end
 end

 -- a diagonal on the pad reports two directions in the same frame. only the
 -- first may move, or the cursor walks out and straight back again.
 start(4)
 lnd=true sel=nil
 oh=0 xh=0                -- the real _init sets these; this one replaced it
 local home=cur
 nav(2)
 local rt=cur
 cur=home
 local ob=btnp
 btnp=function(b) return b==1 or b==2 end   -- right and up together
 play()
 btnp=ob
 ck(cur==rt,"up+right in one frame did not land where right alone does")

 -- clearing the ladder takes two picks, and only the second one writes.
 -- dset is stubbed so the test never touches the real save.
 local od,wrote=dset,nil
 dset=function(i,v) wrote=v end
 unl=7 lsel=7 cfm=false
 clr()
 ck(unl==7 and wrote==nil,"the first pick cleared the ladder without asking")
 ck(cfm,"the first pick did not arm the confirm")
 clr()
 ck(unl==1 and lsel==1,"the second pick did not clear the ladder")
 ck(wrote==1,"clearing did not write the save")
 ck(not cfm,"the confirm stayed armed")
 dset=od

 printh(bad<1 and "ALL LEVELS PASS" or ("FAILURES: "..bad))
 extcmd("shutdown")
end
