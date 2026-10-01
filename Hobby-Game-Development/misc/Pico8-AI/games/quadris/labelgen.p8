pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- quadris label generator
-- draws the 128x128 cover art and
-- dumps it as __label__ hex rows.
-- run: pico8 -x labelgen.p8

hx="0123456789abcdef"
bay={0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5}

-- one step darker / lighter, for the
-- few palette entries that have a twin
dk={} dk[15]=4 dk[10]=9 dk[9]=4 dk[8]=2 dk[4]=2 dk[2]=1 dk[1]=0 dk[7]=6 dk[6]=5
lt={} lt[15]=7 lt[10]=7 lt[9]=10 lt[8]=14 lt[4]=15 lt[2]=8 lt[6]=7

function hl(x0,x1,y,c)
 if x0<=x1 then rectfill(x0,y,x1,y,c) end
end

-- ordered dither: t=0 never, t=1 always
function dith(x,y,t)
 return t*16>bay[(y%4)*4+(x%4)+1]
end

function hnum(ch)
 for i=1,16 do
  if sub(hx,i,i)==ch then return i-1 end
 end
 return 0
end

-- banded gas giant, lit from the upper
-- left. bands is one hex digit per row,
-- so the whole 2r+1 rows are spelled out
function planet(cx,cy,r,bands)
 for y=cy-r,cy+r do
  local dy=y-cy
  local w=flr(sqrt(max(0,r*r-dy*dy)))
  local c0=hnum(sub(bands,dy+r+1,dy+r+1))
  for x=cx-w,cx+w do
   local dx=x-cx
   local c=c0
   -- distance from the light centre,
   -- offset up and to the left
   local lx,ly=dx+r*0.42,dy+r*0.42
   local ld=sqrt(lx*lx+ly*ly)
   if ld<r*0.55 and dith(x,y,mid(0,(r*0.55-ld)/(r*0.44),1)) then
    c=lt[c] or c
   elseif ld>r*0.88 and dith(x,y,mid(0,(ld-r*0.88)/(r*0.3),1)) then
    c=dk[c] or c
   end
   if ld>r*1.22 then c=dk[c] or c end
   pset(x,y,c)
  end
 end
end

-- the ring plane: an ellipse centred on
-- the planet. near=true draws only the
-- half below centre, which is the part
-- that passes in front of the disc.
function ring(cx,cy,a,b,near)
 local y0=near and cy+1 or cy-b-1
 for y=y0,cy+b+1 do
  for x=cx-a-1,cx+a+1 do
   local dx,dy=x-cx,y-cy
   local e=sqrt((dx*dx)/(a*a)+(dy*dy)/(b*b))
   local c=-1
   if e>0.68 and e<0.79 then c=13
   elseif e>0.83 and e<0.92 then c=6
   elseif e>=0.92 and e<0.97 then c=7
   elseif e>=0.97 and e<1 then c=13 end
   -- dust is translucent: only the
   -- brightest band is solid
   if c>=0 and (c==7 or dith(x,y,0.62)) then pset(x,y,c) end
  end
 end
end

-- debris on the ring: tetromino cells
-- caught in orbit. skipped where the
-- planet would occlude them.
function debris(cx,cy,a,b,r,n)
 local pc={12,10,14,11,8,15,9}
 for i=0,n-1 do
  local t=i/n
  local x=cx+a*0.88*cos(t)
  local y=cy+b*0.88*sin(t)
  local dx,dy=x-cx,y-cy
  -- behind the planet?
  if not (y<cy and dx*dx+dy*dy<r*r) then
   local c=pc[i%7+1]
   rectfill(x-1,y-1,x+1,y+1,c)
   pset(x-1,y-1,lt[c] or c)
   pset(x+1,y+1,dk[c] or c)
  end
 end
end

function moon(cx,cy,r)
 for y=cy-r,cy+r do
  for x=cx-r,cx+r do
   local dx,dy=x-cx,y-cy
   if dx*dx+dy*dy<=r*r then
    local lx,ly=dx+r*0.4,dy+r*0.4
    pset(x,y,lx*lx+ly*ly>r*r*0.85 and 5 or 6)
   end
  end
 end
 pset(cx-1,cy-1,5)
 pset(cx+1,cy-2,5)
 pset(cx+2,cy+1,5)
end

-- a tetromino, 5px cells, black rim
function piece(px,py,cs,c,cl,cd)
 for p in all(cs) do
  local x,y=px+p[1]*5,py+p[2]*5
  rectfill(x-1,y-1,x+5,y+5,0)
 end
 for p in all(cs) do
  local x,y=px+p[1]*5,py+p[2]*5
  rectfill(x,y,x+4,y+4,c)
  hl(x,x+4,y,cl)
  line(x,y,x,y+4,cl)
  hl(x,x+4,y+4,cd)
  line(x+4,y,x+4,y+4,cd)
 end
end

-->8
-- title

font={}
font["q"]="111101101111001"
font["u"]="101101101101111"
font["a"]="111101111101101"
font["d"]="110101101101110"
font["r"]="111101111110101"
font["i"]="111010010010111"
font["s"]="111100111001111"
word={"q","u","a","d","r","i","s"}

-- is cell (rx,ry) of glyph g solid?
function gat(g,rx,ry)
 if rx<0 or rx>2 or ry<0 or ry>4 then return false end
 return sub(g,ry*3+rx+1,ry*3+rx+1)=="1"
end

fc={8,8,9,10,10}
fh={14,14,10,7,7}
fs={2,2,4,9,9}

-- mode 0 = flat black (outline pass)
function title(ox,oy,mode)
 for i=1,#word do
  local g=font[word[i]]
  local lx=ox+(i-1)*14
  for ry=0,4 do
   for rx=0,2 do
    if sub(g,ry*3+rx+1,ry*3+rx+1)=="1" then
     local x,y=lx+rx*4,oy+ry*4
     if mode==0 then
      rectfill(x,y,x+3,y+3,0)
     else
      rectfill(x,y,x+3,y+3,fc[ry+1])
      -- light/shade only on the outer
      -- contour, so the counters stay
      -- open at thumbnail size
      if not gat(g,rx,ry-1) then hl(x,x+3,y,fh[ry+1]) end
      if not gat(g,rx-1,ry) then line(x,y,x,y+3,fh[ry+1]) end
      if not gat(g,rx,ry+1) then hl(x,x+3,y+3,fs[ry+1]) end
      if not gat(g,rx+1,ry) then line(x+3,y,x+3,y+3,fs[ry+1]) end
     end
    end
   end
  end
 end
end

-->8
-- compose

px,py,pr=64,78,24
ra,rb=48,14

-- deep space: black, a dark blue wash
-- around the planet, a purple nebula
-- lobe low left, an indigo halo hugging
-- the disc
for y=0,127 do
 for x=0,127 do
  local c=0
  local dx,dy=x-px,y-py
  local d=sqrt(dx*dx+dy*dy)
  if dith(x,y,mid(0,(66-d)/46,1)) then c=1 end
  local nx,ny=x-24,y-96
  local nd=sqrt(nx*nx+ny*ny)
  if nd<32 and dith(x,y,mid(0,(32-nd)/58,1)) then c=2 end
  if d<40 and dith(x,y,mid(0,(40-d)/40,1)) then c=13 end
  pset(x,y,c)
 end
end

-- starfield
srand(23)
for i=1,120 do
 local x,y=flr(rnd(128)),flr(rnd(124))+2
 local r=rnd()
 if r<0.07 then
  pset(x,y,7)
  pset(x-1,y,6) pset(x+1,y,6)
  pset(x,y-1,6) pset(x,y+1,6)
 elseif r<0.34 then pset(x,y,7)
 elseif r<0.7 then pset(x,y,6)
 else pset(x,y,5)
 end
end

moon(104,40,5)

-- ring behind, planet, ring in front
ring(px,py,ra,rb,false)
planet(px,py,pr,
 "fff999aaaa4499999fff8888229999aaaaa44499999fff999")
ring(px,py,ra,rb,true)
debris(px,py,ra,rb,pr,15)

-- pieces drifting in from all four
-- edges, the quadris hook
piece(52,31,{{0,0},{1,0},{2,0},{1,1}},9,10,4)
piece(52,108,{{0,0},{0,1},{1,1},{2,1}},12,7,1)
piece(2,62,{{0,0},{0,1},{0,2},{0,3}},11,7,3)
piece(118,64,{{0,0},{1,0},{0,1},{1,1}},14,15,2)

-- title: 2px black outline plus a
-- hard drop shadow, so it survives
-- the star field behind it
for dy=-2,2 do
 for dx=-2,2 do
  if dx!=0 or dy!=0 then title(16+dx,3+dy,0) end
 end
end
title(19,6,0)
title(16,3,1)

-- frame
rect(0,0,127,127,0)

-->8
-- dump

printh("@@begin")
for y=0,127 do
 local s=""
 for x=0,127 do
  local c=pget(x,y)
  s=s..sub(hx,c+1,c+1)
 end
 printh(s)
end
printh("@@end")
extcmd("shutdown")
