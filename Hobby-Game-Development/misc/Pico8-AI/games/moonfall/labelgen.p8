pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- labelgen -- moonfall cover art
-- draws the label, then dumps the screen as __label__ hex.
-- never ships, so there is no token pressure here.

hx="0123456789abcdef"
bay={0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5}

function dith(x,y,t)
 return t*16>bay[(y%4)*4+(x%4)+1]
end

-->8
-- block title font
-- 3x5 cells per letter, rendered as chunky blocks

-- Proportional, not a fixed grid. An m needs five cells to keep its vee --
-- squeezed into four it becomes an h, and the word reads "hoonfall". An l
-- needs only three, which is what buys the m its extra column.
glyphs={
 m={5,"1000111011101011000110001"},
 o={4,"01101001100110010110"},
 n={4,"10011101111110111001"},
 f={4,"11111000111010001000"},
 a={4,"01101001111110011001"},
 l={3,"100100100100111"},
}

function gat(g,cx,cy)
 local w=g[1]
 if cx<0 or cx>=w or cy<0 or cy>4 then return false end
 return sub(g[2],cy*w+cx+1,cy*w+cx+1)=="1"
end

function wordw(s,cell)
 local n=0
 for i=1,#s do n+=glyphs[sub(s,i,i)][1]*cell+2 end
 return n-2
end

-- emboss the letter's OUTER contour only. lighting every cell turns a
-- vertical stroke into a ladder of stripes and fills in the counters.
function word(w,x0,y0,cell,fill,light,dark,flat)
 local gx=x0
 for i=1,#w do
  local g=glyphs[sub(w,i,i)]
  for cy=0,4 do
   for cx=0,g[1]-1 do
    if gat(g,cx,cy) then
     local x,y=gx+cx*cell,y0+cy*cell
     rectfill(x,y,x+cell-1,y+cell-1,fill)
     if not flat then
      if not gat(g,cx,cy-1) then line(x,y,x+cell-1,y,light) end
      if not gat(g,cx-1,cy) then line(x,y,x,y+cell-1,light) end
      if not gat(g,cx,cy+1) then line(x,y+cell-1,x+cell-1,y+cell-1,dark) end
      if not gat(g,cx+1,cy) then line(x+cell-1,y,x+cell-1,y+cell-1,dark) end
     end
    end
   end
  end
  gx+=g[1]*cell+2
 end
end

-- print with a one-pixel black outline, so small text survives over artwork
function otext(s,x,y,c)
 for dx=-1,1 do
  for dy=-1,1 do
   print(s,x+dx,y+dy,0)
  end
 end
 print(s,x,y,c)
end

-->8
-- the villagers

-- a hooded figure. the whole pitch of the game is that these are
-- indistinguishable -- except that one of them is looking back at you.
function figure(x,base,wolf,col)
 for i=0,21 do
  local w=2+i*0.19
  line(x-w,base-i,x+w,base-i,col)
 end
 rectfill(x-4,base-26,x+4,base-21,col)
 circfill(x,base-25,4,col)
 circfill(x,base-28,3,col)
 if wolf then
  pset(x-2,base-25,8) pset(x-1,base-25,8)
  pset(x+1,base-25,8) pset(x+2,base-25,8)
 end
end

-- a rim of indigo behind each figure, or eight black shapes at this size
-- merge into one black mass and the count stops reading
function crowd(base)
 for i=0,7 do
  local x=8+i*16
  figure(x-1,base,false,13)
  figure(x+1,base,false,13)
  figure(x,base-1,false,13)
 end
 for i=0,7 do
  figure(8+i*16,base,i==4,0)
 end
end

-->8
-- compose

cls(0)

-- night sky: black at the crown, indigo at the horizon
for y=0,127 do
 for x=0,127 do
  local c=1
  if dith(x,y,0.9-y/70) then c=0 end
  if y>64 and dith(x,y,(y-64)/60) then c=13 end
  pset(x,y,c)
 end
end

-- The moon. The halo stays tight and thins fast: a wide pink corona is a
-- saturated mid-tone field, which is the one thing the art direction rules out.
mx,my,mr=80,56,22
for y=my-32,my+32 do
 for x=mx-32,mx+32 do
  if x>=0 and x<128 and y>=0 and y<128 then
   local dx,dy=x-mx,y-my
   local d=sqrt(dx*dx+dy*dy)
   if d<mr then
    pset(x,y,7)
   elseif d<mr+4 then
    if dith(x,y,(1-(d-mr)/4)^2) then pset(x,y,14) end
   elseif d<mr+11 then
    if dith(x,y,(1-(d-mr-4)/7)^3) then pset(x,y,2) end
   end
  end
 end
end
circfill(mx-9,my-8,4,6)
circfill(mx+7,my+6,5,6)
circfill(mx-3,my+12,3,6)
circfill(mx+11,my-11,2,6)

-- The village sits behind a horizon at y=96 and stops there. Running it down
-- to the bottom edge put black roofs behind black figures, and the whole lower
-- half went to one unreadable mass.
HZ=96
for i=0,6 do
 local x=i*20-8
 local h=9+(i%3)*5
 rectfill(x,HZ-h,x+15,HZ,0)
 line(x-1,HZ-h,x+7,HZ-h-6,0)
 line(x+7,HZ-h-6,x+16,HZ-h,0)
 line(x-1,HZ-h-1,x+7,HZ-h-7,13)
 line(x+7,HZ-h-7,x+16,HZ-h-1,13)
end
-- the chapel spire, the one landmark worth a silhouette
rectfill(31,72,39,HZ,0)
line(30,72,35,60,0) line(35,60,40,72,0)
line(29,72,35,59,13) line(35,59,41,72,13)
line(35,54,35,60,0) line(33,56,37,56,0)

-- ground: mist at the horizon, settling to night blue underfoot
for y=HZ,127 do
 for x=0,127 do
  pset(x,y,dith(x,y,1-(y-HZ)/26) and 13 or 1)
 end
end

crowd(126)

-- title: black outline in a 5x5 neighbourhood lifts it off the sky
tx=64-wordw("moonfall",3)/2
for dx=-2,2 do
 for dy=-2,2 do
  word("moonfall",tx+dx,7+dy,3,0,0,0,true)
 end
end
word("moonfall",tx+1,9,3,2,2,2,true)
word("moonfall",tx,7,3,8,9,2)

otext("one of them is lying",25,29,6)

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
