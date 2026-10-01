pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- pattern hunt label generator
-- see PICO8-LABEL.md

hx="0123456789abcdef"

-- the game's hue cycle
hue={8,9,11,12,13,14}

-- the intro computer: 28 wireframe
-- segments, four numbers each.
-- copied verbatim from game.p8.
-- the two key rows are inset ~2px
-- inside the case: drawn at their
-- original width they poked out
-- through the right-hand edge.
pc=split"30,22,98,22,98,22,98,70,98,70,30,70,30,70,30,22,36,28,92,28,92,28,92,62,92,62,36,62,36,62,36,28,40,36,74,36,40,42,82,42,40,48,66,48,88,66,92,66,92,66,92,68,92,68,88,68,88,68,88,66,56,70,56,80,72,70,72,80,46,80,82,80,82,80,82,86,82,86,46,86,46,86,46,80,64,86,64,94,30,94,98,94,98,94,106,106,106,106,22,106,22,106,30,94,30,98,98,98,27,102,101,102"

-->8
-- 4x5 block font

-- one string per glyph: five rows
-- of four cells, top row first.
-- four columns, not three, so n
-- can carry a real diagonal and
-- stop reading as m.
fnt={
 p="11101001111010001000",
 a="01101001111110011001",
 t="11110110011001100110",
 e="11111000111010001111",
 r="11101001111010101001",
 n="10011101101110011001",
 h="10011001111110011001",
 u="10011001100110010110",
}

cel=3           -- pixels per font cell
gap=2           -- pixels between glyphs
lw=cel*4        -- glyph width
lh=cel*5        -- glyph height

-- is cell (cx,cy) of glyph g set?
function gat(g,cx,cy)
 if cx<0 or cx>3 or cy<0 or cy>4 then
  return false
 end
 local i=cy*4+cx+1
 return sub(g,i,i)=="1"
end

-- one glyph at x,y.  only the outer
-- contour is embossed -- an edge is
-- lit when the neighbouring cell in
-- that direction is empty -- so a
-- stroke stays solid instead of
-- turning into a ladder of stripes.
function glyph(g,x,y,body,hi,lo)
 for cy=0,4 do
  for cx=0,3 do
   if gat(g,cx,cy) then
    local px=x+cx*cel
    local py=y+cy*cel
    rectfill(px,py,px+cel-1,py+cel-1,body)
    if not gat(g,cx,cy-1) then
     line(px,py,px+cel-1,py,hi)
    end
    if not gat(g,cx-1,cy) then
     line(px,py,px,py+cel-1,hi)
    end
    if not gat(g,cx,cy+1) then
     line(px,py+cel-1,px+cel-1,py+cel-1,lo)
    end
    if not gat(g,cx+1,cy) then
     line(px+cel-1,py,px+cel-1,py+cel-1,lo)
    end
   end
  end
 end
end

function tw(s)
 return #s*lw+(#s-1)*gap
end

-- a word, horizontally centred
function word(s,y,body,hi,lo)
 local x=(128-tw(s))\2
 for i=1,#s do
  glyph(fnt[sub(s,i,i)],x,y,body,hi,lo)
  x+=lw+gap
 end
end

-->8
-- compose

cls(0)

-- the computer, pushed below the
-- title.  native scale, integer
-- coordinates: the 2px details in
-- the stand and the keyboard rows
-- do not survive being resized.
dy=19
for j=1,#pc\4 do
 local a=(j-1)*4
 line(pc[a+1],pc[a+2]+dy,
      pc[a+3],pc[a+4]+dy,
      hue[(j-1)%6+1])
end

word("pattern",4,7,7,6)
word("hunt",20,7,7,6)

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
