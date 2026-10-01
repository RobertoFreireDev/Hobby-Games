pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- monstergram label generator
-- draws the cover art, dumps it as __label__ hex

hx="0123456789abcdef"

bay={0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5}
function dith(x,y,t)
 return t*16>bay[(y%4)*4+(x%4)+1]
end

-->8
-- fonts

-- 4x5 letters
lt={
 m={"10001","11011","10101","10001","10001"},
 o={"0110","1001","1001","1001","0110"},
 n={"1001","1101","1111","1011","1001"},
 s={"0111","1000","0110","0001","1110"},
 t={"1111","0110","0110","0110","0110"},
 e={"1111","1000","1110","1000","1111"},
 r={"1110","1001","1110","1010","1001"},
 g={"0111","1000","1011","1001","0111"},
 a={"0110","1001","1111","1001","1001"},
}

-- 3x5 digits
dg={
 ["0"]={"111","101","101","101","111"},
 ["1"]={"010","110","010","010","111"},
 ["2"]={"111","001","111","100","111"},
 ["3"]={"111","001","111","001","111"},
 ["4"]={"101","101","111","001","001"},
 ["5"]={"111","100","111","001","111"},
 ["6"]={"111","100","111","101","111"},
 ["7"]={"111","001","001","001","001"},
 ["8"]={"111","101","111","101","111"},
}

-- walk a glyph's cells, calling f(col,row)
function cells(g,f)
 for r=1,5 do
  local s=g[r]
  for c=1,#s do
   if sub(s,c,c)=="1" then f(c-1,r-1) end
  end
 end
end

function gw(g) return #g[1] end

-- draw a string of glyphs from table tb at cell size cz
function word(tb,str,x,y,cz,f)
 local cx=x
 for i=1,#str do
  local ch=sub(str,i,i)
  local g=tb[ch]
  local gx=cx
  cells(g,function(c,r)
   f(gx+c*cz,y+r*cz,cz,r)
  end)
  cx+=gw(g)*cz+cz-1
 end
end

function strw(tb,str,cz)
 local w=0
 for i=1,#str do
  w+=gw(tb[sub(str,i,i)])*cz+cz-1
 end
 return w-(cz-1)
end

-->8
-- composition

-- background: cold dungeon gradient
for y=0,127 do
 for x=0,127 do
  local c=0
  if dith(x,y,1-y/150) then c=1 end
  pset(x,y,c)
 end
end

-- red glow behind the monster
for y=30,127 do
 for x=0,127 do
  local d=sqrt((x-76)^2+(y-82)^2)
  if dith(x,y,(1-d/70)*0.55) then pset(x,y,2) end
 end
end

-- ---- the monster, drawn as a solved 11x11 board.
-- every line here obeys the game's own clue rule:
-- at most 3 runs, none longer than 9
pat={
 "01000000010",
 "01100000110",
 "01111111110",
 "01111111110",
 "01100100110",
 "01100100110",
 "01111111110",
 "01101110110",
 "01111111110",
 "00111111100",
 "00011011000"}

gx0,gy0,cz=32,38,8

for j=0,10 do
 for i=0,10 do
  local x,y=gx0+i*cz,gy0+j*cz
  if sub(pat[j+1],i+1,i+1)=="1" then
   -- monster flesh: raised slab
   rectfill(x,y,x+6,y+6,8)
   line(x,y,x+6,y,9)
   line(x,y,x,y+6,9)
   line(x,y+6,x+6,y+6,2)
   line(x+6,y,x+6,y+6,2)
  else
   -- dug out: recessed floor
   rectfill(x,y,x+6,y+6,1)
   line(x,y+6,x+6,y+6,5)
   line(x+6,y,x+6,y+6,5)
  end
 end
end

-- the blank cells at rows 4-5 are the eyes
for i in all({3,6}) do
 local x,y=gx0+i*cz+7,gy0+4*cz+7
 circfill(x,y,5,9)
 circfill(x,y,3,10)
 circfill(x,y,1,7)
end

-- ---- row clues, computed from the pattern and
-- right-aligned against the field, as in the game
function runsof(j)
 local r,c={},0
 for i=1,11 do
  if sub(pat[j+1],i,i)=="1" then c+=1
  elseif c>0 then add(r,c) c=0 end
 end
 if c>0 then add(r,c) end
 return r
end

for j=0,10 do
 local r=runsof(j)
 local n=#r
 if n==0 then
  print("0",gx0-6,gy0+j*cz+1,6)
 else
  -- one digit per cell, nearest the field first
  for k=0,n-1 do
   print(r[n-k],gx0-6-k*8,gy0+j*cz+1,6)
  end
 end
end

-- ---- title
function title(str,ty,cz)
 local w=strw(lt,str,cz)
 local tx=(128-w)\2
 -- fat black outline, then a drop shadow
 for oy=-2,2 do
  for ox=-2,2 do
   word(lt,str,tx+ox,ty+oy,cz,function(x,y,z)
    rectfill(x,y,x+z-1,y+z-1,0)
   end)
  end
 end
 word(lt,str,tx+2,ty+3,cz,function(x,y,z)
  rectfill(x,y,x+z-1,y+z-1,0)
 end)
 -- letters, ramped 10 -> 9 -> 8 down the glyph
 word(lt,str,tx,ty,cz,function(x,y,z,r)
  local c=10
  if r>=2 then c=9 end
  if r>=4 then c=8 end
  rectfill(x,y,x+z-1,y+z-1,c)
 end)
end

title("monster",3,3)
title("gram",19,3)

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
