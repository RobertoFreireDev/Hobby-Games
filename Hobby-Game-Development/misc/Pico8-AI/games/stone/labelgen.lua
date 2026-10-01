-- stone logic label generator
-- run: pico8.exe -x games/stone/labelgen.p8 > dump.txt 2>&1
-- then: node label-tool.js dump.txt games/stone/game.p8 label.png 3
hx="0123456789abcdef"
chk=0b0101101001011010
d25=0b1101011111010111
p25=0b0010100000101000
fc={12,11,14,9,8,2}

-- 4x5 cell block font. 4 wide, not 3 -- at 3 cells n reads as h and p as f.
fnt={
 s=".###,#...,.##.,...#,###.",
 t="####,.##.,.##.,.##.,.##.",
 o=".##.,#..#,#..#,#..#,.##.",
 n="#..#,##.#,#.##,#..#,#..#",
 e="####,#...,###.,#...,####",
 l="#...,#...,#...,#...,####",
 g=".###,#...,#.##,#..#,.###",
 i="####,.##.,.##.,.##.,####",
 c=".###,#...,#...,#...,.###"}

-- one letter, cell size s. only the outer contour is embossed: lighting
-- every cell turns a vertical stroke into a ladder of stripes.
function letter(ch,x0,y0,s,c,hi,lo)
 local rows=split(fnt[ch],",",false)
 for r=1,5 do
  for k=1,4 do
   if sub(rows[r],k,k)=="#" then
    local x=x0+(k-1)*s
    local y=y0+(r-1)*s
    rectfill(x,y,x+s-1,y+s-1,c)
    if r<2 or sub(rows[r-1],k,k)!="#" then line(x,y,x+s-1,y,hi) end
    if r>4 or sub(rows[r+1],k,k)!="#" then line(x,y+s-1,x+s-1,y+s-1,lo) end
   end
  end
 end
end

-- black at every offset in a 3x3 ring first, so the word lifts off whatever
-- is behind it, then the real letters on top
function word(w,x0,y0,s,c,hi,lo)
 for i=1,#w do
  local x=x0+(i-1)*(4*s+2)
  for a=-2,2 do
   for b=-2,2 do
    letter(sub(w,i,i),x+a,y0+b,s,0,0,0)
   end
  end
  letter(sub(w,i,i),x,y0,s,c,hi,lo)
 end
end

-- the game's stone, scaled up: white face up, dark grey while buried
function stone(x,y,g,c,hd)
 rectfill(x+2,y+2,x+15,y+15,0)
 rectfill(x,y,x+13,y+13,hd and 5 or 7)
 rect(x,y,x+13,y+13,hd and 1 or 6)
 pal(0,c)
 sspr(g*8,0,8,8,x+1,y+1,12,12)
 pal(0,0)
end

function panel(x,y,w,h)
 rectfill(x,y,x+w,y+h,0)
 dfill(x+1,y+1,x+w-1,y+h-1,p25,0xd1)
 rect(x,y,x+w,y+h,5)
end

function dfill(x0,y0,x1,y1,p,c)
 fillp(p) rectfill(x0,y0,x1,y1,c) fillp()
end

-->8
-- compose

palt(0,false)
palt(14,true)
cls(0)

-- lamp over the table, brightest behind the title
fillp(p25) ovalfill(-40,-60,168,120,0x10)
fillp(chk) ovalfill(-24,-48,152,106,0x10)
fillp(d25) ovalfill(-8,-36,136,92,0x10)
fillp() ovalfill(8,-26,120,78,1)
fillp(chk) ovalfill(20,-18,108,66,0x21)
fillp(d25) ovalfill(32,-12,96,56,0xd2)
fillp() ovalfill(44,-8,84,46,13)

word("stone",20,3,4,7,7,6)

-- four layers, four panels: the top one face up, everything under it a "?"
lx={3,65,3,65}
ly={50,50,89,89}
for q=1,4 do
 panel(lx[q],ly[q],59,37)
end

-- layer 1: the whole footprint, every face on show
f1={1,4,2,5}
for i=0,3 do
 stone(lx[1]+15+(i%2)*16,ly[1]+4+flr(i/2)*16,f1[i+1],fc[f1[i+1]])
end
-- layers 2-4: buried, and shrinking as the stacks get shorter
n2={4,3,2}
for q=2,4 do
 for i=0,n2[q-1]-1 do
  stone(lx[q]+15+(i%2)*16,ly[q]+4+flr(i/2)*16,8,8,true)
 end
end

-->8
-- dump

printh("@@begin")
for y=0,127 do
 local s=""
 for x=0,127 do
  s=s..sub(hx,pget(x,y)+1,pget(x,y)+1)
 end
 printh(s)
end
printh("@@end")
extcmd("shutdown")
