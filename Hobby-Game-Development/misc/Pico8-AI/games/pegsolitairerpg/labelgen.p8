pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- labelgen for peg dungeon
-- draws the 128x128 cover art, then
-- dumps the screen as __label__ hex.
-- run: pico8 -x labelgen.p8 > dump.txt
-- then: node label-tool.js dump.txt
--       games/pegsolitairerpg/game.p8
--       preview.png 3

hx="0123456789abcdef"

-- 4x5 block font. one string per
-- letter, 5 rows of 4 chars.
-- 4 wide because 3 columns cannot
-- hold a diagonal: at 3 wide the n
-- is indistinguishable from an h.
gly={
-- p's bowl is 2 rows tall: a 1-row
-- bowl leaves its right stem as a
-- single cell that the emboss eats
-- entirely, and it reads as an f.
 p="###.|#..#|#..#|###.|#...",
 e="####|#...|###.|#...|####",
 g=".###|#...|#.##|#..#|.###",
 d="###.|#..#|#..#|#..#|###.",
 u="#..#|#..#|#..#|#..#|.##.",
 n="#..#|##.#|#.##|#..#|#..#",
 o=".##.|#..#|#..#|#..#|.##.",
}

function cell(s,r,c)
 local row=split(s,"|")[r+1]
 return sub(row,c+1,c+1)=="#"
end

-- draw one letter as 3x5 cells of
-- b x b pixels.  emboss only the
-- outer contour: light an edge only
-- where the neighbour that way is
-- off, so vertical strokes stay
-- solid instead of turning into a
-- ladder of stripes.
function letter(s,x,y,b,base,lt,dk)
 for r=0,4 do
  for c=0,3 do
   if cell(s,r,c) then
    local px,py=x+c*b,y+r*b
    rectfill(px,py,px+b-1,py+b-1,base)
    if r==0 or not cell(s,r-1,c) then
     line(px,py,px+b-1,py,lt)
    end
    if c==0 or not cell(s,r,c-1) then
     line(px,py,px,py+b-1,lt)
    end
    if r==4 or not cell(s,r+1,c) then
     line(px,py+b-1,px+b-1,py+b-1,dk)
    end
    if c==3 or not cell(s,r,c+1) then
     line(px+b-1,py,px+b-1,py+b-1,dk)
    end
   end
  end
 end
end

function word(w,y,b,base,lt,dk)
 local lw=b*4
 local gap=max(2,b\3)
 local tw=#w*lw+(#w-1)*gap
 local x=(128-tw)\2
 for i=1,#w do
  letter(gly[sub(w,i,i)],x,y,b,base,lt,dk)
  x+=lw+gap
 end
end

-- a rooted monster: body, white
-- eyes, and the dark root row that
-- says "this peg never moves".
function mon(cx,by,w,h,col,horns)
 local x0,x1=cx-w,cx+w
 ovalfill(x0,by-h,x1,by,col)
 if horns then
  for i=0,4 do
   line(x0+2+i,by-h+2-i,x0+2+i,by-h+6-i,9)
   line(x1-2-i,by-h+2-i,x1-2-i,by-h+6-i,9)
  end
 end
 local ey=by-h*0.62
 local er=max(2,w\5)
 circfill(cx-w*0.42,ey,er,7)
 circfill(cx+w*0.42,ey,er,7)
 circfill(cx-w*0.42,ey,er\2,0)
 circfill(cx+w*0.42,ey,er\2,0)
 rectfill(x0+1,by-2,x1-1,by+2,2)
end

-- ---------------------------------
cls(0)

-- floor: a hint of the solitaire
-- grid, so the board reads even
-- before you see a peg.
rectfill(0,52,127,127,1)
for y=52,127,12 do
 line(0,y,127,y,0)
end
for x=2,127,12 do
 line(x,52,x,127,0)
end
for y=58,127,12 do
 for x=8,127,12 do
  rectfill(x,y,x+1,y+1,0)
 end
end

-- monsters, biggest in the middle
mon(24,120,12,24,13,false)
mon(104,120,12,24,13,false)
mon(64,122,20,40,14,true)

-- the stone, mid-arc over the big
-- one, with a fading trail behind.
for i=1,4 do
 local t=i/9
 local px=16+t*96
 local py=96-(1-((px-64)/48)^2)*34
 circfill(px,py,2,i>2 and 6 or 5)
end
circfill(64,62,9,5)
circfill(63,61,7,6)
circfill(60,58,3,7)

-- title
word("peg",3,5,9,10,4)
word("dungeon",31,4,9,10,4)

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
