-- labelgen: draws the 128x128 cover art and dumps it as __label__ hex.
-- It is built with the game's own __gfx__ (see mklabelgen.js), so the cover is
-- the real tiles and the real logo, not a redrawing of them.
--   node mklabelgen.js
--   rm -f lbl.p8l && pico8 -x labelgen.p8
--   node ../../label-tool.js lbl.p8l game.p8 label.png 3
hx="0123456789abcdef"
rmp={{14,8,2},{7,12,1},{10,11,3},{7,10,9},{10,9,4},{15,14,2},{7,6,5}}
fdp={0b1111111111111111,0b1111010111110101,0b1010010110100101,0b1010000010100000,0}

function pcol(c)
 local r=rmp[c]
 pal(7,r[1]) pal(6,r[2]) pal(5,r[3])
 palt(0,false) palt(14,true)
end
function pdef() pal() palt(0,false) palt(14,true) end

-- the glyph picker, lifted from the cart: 1=n 2=e 4=s 8=w
function adjm(a,b)
 if not b then return 0 end
 if b[1]==a[1] then
  if b[2]==a[2]-1 then return 1 end
  if b[2]==a[2]+1 then return 4 end
 elseif b[2]==a[2] then
  if b[1]==a[1]+1 then return 2 end
  if b[1]==a[1]-1 then return 8 end
 end
 return 0
end
-- the short tongue a portal tile draws over its ring (tiles 12/13)
function stub(m,x,y)
 local s,a,b=40,false,false
 if m==4 then b=true
 elseif m==8 then s=42
 elseif m==2 then s=42 a=true
 elseif m!=1 then return end
 spr(s,x,y,2,2,a,b)
end

function pipe(m,x,y)
 local s,a,b=8,false,false
 if m==5 then s=2
 elseif m==10 then s=4
 elseif m==3 then s=6
 elseif m==9 then s=6 a=true
 elseif m==6 then s=6 b=true
 elseif m==12 then s=6 a=true b=true
 elseif m==4 then b=true
 elseif m==8 then s=10
 elseif m==2 then s=10 a=true
 elseif m!=1 then return end
 spr(s,x,y,2,2,a,b)
end

-->8
-- composition

-- a six by five fragment of a solved board: three pipes woven through it and
-- one red pipe crossing the whole picture through the portal pair
gw,gh=6,5
ox,oy=16,38
pa={5,2}  -- portal tiles, 1-based grid coords
pb={2,4}

paths={
 -- colour, then the ordered cells; a jump between two cells that are not
 -- neighbours is exactly where the portal pair sits
 {c=3,{1,1},{2,1},{3,1},{4,1},{5,1},{6,1},{6,2},{6,3}},
 {c=1,{1,2},{2,2},{3,2},{4,2},{5,2},{2,4},{3,4},{4,4},{5,4},{5,5}},
 {c=2,{1,3},{1,4},{1,5},{2,5},{3,5},{4,5}},
}

-- background: the same dithered indigo vignette the game uses, darkest at
-- the corners so the board reads as lit from the middle
cls(1)
for i=1,3 do
 fillp(fdp[5-i]+0.5)
 rectfill(20-i*6,20-i*6,107+i*6,107+i*6,13)
end
fillp()

-- board frame
local w,h=gw*16,gh*16
rectfill(ox-2,oy-2,ox+w+3,oy+h+3,0)
rectfill(ox-4,oy-4,ox+w+3,oy+h+3,13)
rect(ox-4,oy-4,ox+w+3,oy+h+3,1)
rect(ox-1,oy-1,ox+w,oy+h,6)

pdef()
for y=0,gh-1 do
 for x=0,gw-1 do
  spr(0,ox+x*16,oy+y*16,2,2)
 end
end

-- portal glow, under the pipes so it haloes them instead of speckling them
function pcen(c) return ox+(c[1]-1)*16+8,oy+(c[2]-1)*16+8 end
for _,c in pairs({pa,pb}) do
 local x,y=pcen(c)
 fillp(0b1010000010100000+0.5) circfill(x,y,15,12)
 fillp(0b1010010110100101+0.5) circfill(x,y,11,12)
 fillp()
end

-- pipes
for p in all(paths) do
 pcol(p.c)
 for j=1,#p do
  local c=p[j]
  pipe(adjm(c,p[j-1])|adjm(c,p[j+1]),ox+(c[1]-1)*16,oy+(c[2]-1)*16)
 end
end
pdef()

-- endpoint dots, connected, with their colour-blind glyph
for p in all(paths) do
 for _,c in pairs({p[1],p[#p]}) do
  local x,y=ox+(c[1]-1)*16,oy+(c[2]-1)*16
  pcol(p.c)
  spr(14,x,y,2,2)
  pdef()
  spr(63+p.c,x+4,y+4)
 end
end

-- a dithered thread between the two mouths. this is the one piece of poster
-- licence on the cover: it is not drawn in game, but it is what makes the
-- mechanic legible in a glance at thumbnail size.
local ax,ay=pcen(pa)
local bx,by=pcen(pb)
fillp(0b1010000010100000+0.5)
line(ax,ay,bx,by,12)
line(ax,ay+1,bx,by+1,7)
fillp()

-- the portal pair, on top of the red pipe's caps so the pipe reads as
-- entering one mouth and leaving the other
for _,c in pairs({pa,pb}) do
 local x,y=pcen(c)
 -- the ring takes the owner's highlight and its tongue goes over the top,
 -- exactly as in game, so the cover shows the real thing
 for q in all(paths) do
  for j=1,#q do
   if q[j][1]==c[1] and q[j][2]==c[2] then
    pcol(q.c)
    spr(32,x-8,y-8,2,2)
    stub(adjm(q[j],q[j-1])|adjm(q[j],q[j+1]),x-8,y-8)
    pdef()
   end
  end
 end
 -- a few escaping motes, so a portal reads as live rather than decorative
 for i=0,5 do
  local a,r=i/6+0.05,9+i%3
  pset(x+cos(a)*r,y+sin(a)*r,i%2==0 and 7 or 12)
 end
end

-- title: the cart's own logo strip, no credits, no press start
sspr(0,64,112,16,8,6)

-->8
-- dump

-- to a named file, not stdout: pico-8's own RUNNING banner interleaves
-- with early printh output and would land inside the block
printh("@@begin","lbl")
for y=0,127 do
 local s=""
 for x=0,127 do
  local c=pget(x,y)
  s=s..sub(hx,c+1,c+1)
 end
 printh(s,"lbl")
end
printh("@@end","lbl")
extcmd("shutdown")
