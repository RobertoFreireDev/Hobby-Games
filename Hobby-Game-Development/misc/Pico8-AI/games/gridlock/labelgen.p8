pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- gridlock label generator
-- run: pico8.exe -x games/gridlock/labelgen.p8 > dump.txt 2>&1
-- then: node label-tool.js dump.txt games/gridlock/game.p8 preview.png 3
hx="0123456789abcdef"

-- 4x5 cell block font. 4 wide,
-- not 3 -- at 3 cells n reads
-- as h and p as f.
fnt={
 g=".###,#...,#.##,#..#,.###",
 r="###.,#..#,###.,#.#.,#..#",
 i="####,.##.,.##.,.##.,####",
 d="###.,#..#,#..#,#..#,###.",
 l="#...,#...,#...,#...,####",
 o=".##.,#..#,#..#,#..#,.##.",
 c=".###,#...,#...,#...,.###",
 k="#..#,#.#.,##..,#.#.,#..#"}

-- one letter, cell size s.
-- the outer contour is
-- embossed, never each cell,
-- or strokes turn to ladders.
function letter(ch,x0,y0,s,c,hi,lo)
 local rows=split(fnt[ch],",",false)
 for r=1,5 do
  for k=1,4 do
   if sub(rows[r],k,k)=="#" then
    local x=x0+(k-1)*s
    local y=y0+(r-1)*s
    rectfill(x,y,x+s-1,y+s-1,c)
    local up=r>1 and sub(rows[r-1],k,k)=="#"
    local dn=r<5 and sub(rows[r+1],k,k)=="#"
    local lf=k>1 and sub(rows[r],k-1,k-1)=="#"
    local rt=k<4 and sub(rows[r],k+1,k+1)=="#"
    -- only the top and bottom
    -- contour: side lines eat a
    -- 4px stroke and the letter
    -- goes hollow at 1x
    if not up then line(x,y,x+s-1,y,hi) end
    if not dn then line(x,y+s-1,x+s-1,y+s-1,lo) end
   end
  end
 end
end

function word(w,x0,y0,s,c,hi,lo)
 for i=1,#w do
  local x=x0+(i-1)*(4*s+2)
  letter(sub(w,i,i),x+1,y0+1,s,1,1,1)
  letter(sub(w,i,i),x,y0,s,c,hi,lo)
 end
end

-- board, same look as the game
pcol=split("12,11,9,13,14,6,10,3,15,4,2")
dk={[2]=1,[3]=1,[4]=2,[6]=5,[8]=2,[9]=4,
 [10]=9,[11]=3,[12]=1,[13]=1,[14]=2,[15]=4}
lt={[2]=14,[3]=11,[4]=15,[6]=7,[8]=14,
 [9]=10,[10]=7,[11]=7,[12]=6,[13]=6,
 [14]=15,[15]=7}

function rr(x0,y0,x1,y1,c)
 rectfill(x0+1,y0,x1-1,y1,c)
 rectfill(x0,y0+1,x1,y1-1,c)
end

-->8
-- compose

cls(0)

-- title
word("grid",22,4,4,10,7,9)
word("lock",22,26,4,10,7,9)

-- board frame
bx=22
by=52
cs=12
rectfill(bx-4,by-4,bx+72+3,by+72+3,5)
rect(bx-4,by-4,bx+72+3,by+72+3,6)
rectfill(bx,by,bx+71,by+71,1)
for i=1,5 do
 line(bx+i*cs,by,bx+i*cs,by+71,0)
 line(bx,by+i*cs,bx+71,by+i*cs,0)
end
-- exit gap in the right wall
rectfill(bx+72,by+2*cs,bx+75,by+3*cs-1,0)
for i=0,4 do
 line(bx+78+i,by+26+i,bx+78+i,by+35-i,9)
end

-- the finale board: 12 pieces, par 25
s="022004214421252053310021102151212420312120314020"
n=0
for i=1,#s,4 do
 n+=1
 local px=tonum(sub(s,i,i))
 local py=tonum(sub(s,i+1,i+1))
 local pl=tonum(sub(s,i+2,i+2))
 local pd=tonum(sub(s,i+3,i+3))
 local x0=bx+px*cs+1
 local y0=by+py*cs+1
 local x1=x0+(pd==0 and pl or 1)*cs-3
 local y1=y0+(pd==1 and pl or 1)*cs-3
 local c=n==1 and 8 or pcol[(n-2)%#pcol+1]
 rr(x0+1,y0+1,x1+1,y1+1,0)
 rr(x0,y0,x1,y1,dk[c])
 rr(x0+1,y0+1,x1-1,y1-1,c)
 line(x0+2,y0+1,x1-2,y0+1,lt[c])
end

printh("@@begin")
for y=0,127 do
 local r=""
 for x=0,127 do
  r=r..sub(hx,pget(x,y)+1,pget(x,y)+1)
 end
 printh(r)
end
printh("@@end")
extcmd("shutdown")
__gfx__
