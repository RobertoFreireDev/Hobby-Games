pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- snakebox
-- by roberto freire

tile,cols,rows=16,6,6
-- one 8px text row now, so the bar is 8px shorter: the floor line under it
-- said nothing the score line and the minimaps were not already saying.
-- the board takes 96px of the 112 left over and does not centre in it -- it
-- is pushed the whole 8px down off centre, so all the headroom is above and
-- the board rests straight on the bar. horizontally it does not centre
-- either: it sits against the left margin and the minimap column takes the
-- 26px strip on the right (section 2)
bar_h=16
bar_y=128-bar_h
marg=2
ox,oy=marg,(bar_y-rows*tile)\2
-- minimap column. ox+96 is the board right edge, +marg puts the outline at
-- x=100, so the first 4px block starts at 101. two of them, 48px apart,
-- which centres the pair against the board it stands beside
mm_x,mm_y,mm_tile,mm_gap=101,20,4,48
bcx=ox+cols*tile\2       -- board centre x, for the two end panels
total_cells=0

-- 1 or 2 blocks a floor. where there are two they keep a clear tile
-- between them (chebyshev>=2) so they never fuse into a bar or an l, and
-- neither ever sits diagonally inside a board corner (section 7.6)
wall_min,wall_max=1,2
min_corner_dist=1
min_door_dist=2
wall_corner_dist=2
min_wall_dist=2

floor_name={"a","b","c"}
ink_outline=0
-- the second outline ink, for the two elements that sit straight on the
-- background: the board and the minimaps. their 0 rect was black on black
-- and did nothing, which is not a rule with an exception -- it is the rule
-- doing nothing (section 6.1).
-- 5 is the bar's own slab colour, so the three frames and the bar read as
-- one chassis the game is mounted on rather than as three separate borders.
-- the price is on the minimaps and only there: a wall block is also 5 and
-- touches the frame directly, so a wall on the border ring merges into it.
-- board pieces cannot do that -- every one of them carries its own black
-- outline in between
ink_edge=5

-- the title screen is up at boot and never comes back: restart goes straight
-- into a new board, because the intro is there to name the game, not to
-- stand between the player and the next run. tk exists only to blink the
-- prompt, so it wraps inside its own period and can never overflow -- the
-- counter that runs past 32767 in 18 minutes is the classic pico-8 bug
intro=true
tk=0

dith_25=0b1010000010100000
dith_50=0b1010010110100101

sfx_step={0,1,2,3,4,5}
sfx_eat,sfx_door,sfx_bump=6,7,8
sfx_die,sfx_win=10,11
sfx_deny=27
-- slots 9 and 26 were the view-toggle clicks. the toggle is gone -- the two
-- floors you are not standing on are always on screen now (section 2) -- but
-- the slots stay where they are: every music pattern is written against this
-- numbering, and closing the gap would renumber the bed
mus_main=0

function _init()
 -- one press = one step: kill btnp auto-repeat
 poke(0x5f5c,255)
 -- the pieces carry their own outline in colour 0, so black must stay opaque;
 -- 2 is the key colour their rounded corners are cut out with (spritegen.js).
 -- it was 14 until the tail became pink: the key has to be an ink no sprite
 -- paints in, and 2 is the last one -- the grid lines and the minimap's free
 -- tiles are drawn with line()/rectfill(), which palt() does not touch
 palt(0,false)
 palt(2,true)
 -- o and x are deliberately left unbound now that the view toggle is gone.
 -- this is a slow puzzle with an hour of board behind it and no clock to
 -- punish a pause, so a face button that restarts is one stray press from
 -- throwing the run away. restart stays on the menu, two deliberate inputs in
 menuitem(1,"restart",new_game)
 -- once per run, and before new_game: the bar reads best on frame one.
 -- a cartdata id is global to the machine and permanent: renaming it
 -- abandons every save under the old one, which is why it was written as
 -- the name the cart would ship under while it was still called multi-floor
 -- snake. the rename cost nothing: the id never moved. dget returns 0 where
 -- no save exists
 cartdata("rfreire_snakebox")
 best=dget(0)
 new_game()
end

function new_game()
 gen_doors()
 gen_walls()
 -- doors are transit, not floor space: they hold no food and count toward
 -- no fill total, so the endgame can no longer deadlock on a free list
 -- that is all doors. 6 = 2 doors x 3 floors
 total_cells=cols*rows*3-wall_count-6
 -- view is no longer a control: it is a cache of snake[1].f, kept global
 -- because the whole draw path reads it. the head always starts on floor 1
 view,score=1,0
 -- best carries across games; new_best only marks the game that set it
 new_best=false
 gameover,won=false,false
 -- not dead code: free_cell reads occupancy off snake, so last game body
 -- has to go before the first roll
 snake={}
 -- a start cell can still be boxed in -- two doors and a wall around an
 -- edge tile do it -- and free_neighbor then falls back to the head itself,
 -- so re-roll until the tail is a real cell.
 -- not trapped() is the belt to that braces. at 1-2 walls a floor it can no
 -- longer fire: a trapped start needs all 3 non-neck exits shut, doors are
 -- open at the roll (nothing is standing in one yet), an interior head would
 -- need 3 walls, and a border head always keeps a border neighbour no wall
 -- can reach. it stays because its absence is a turn-1 death, and because
 -- the wall cap is a tuning constant that could move back.
 -- always terminates, since the four corners can never be walled or doored,
 -- and a corner's two neighbours are border tiles no wall can reach
 local h,tl
 repeat
  h=free_cell(1)
  tl=free_neighbor(1,h)
  snake={{x=h.x,y=h.y,f=1,dx=h.x-tl.x,dy=h.y-tl.y},{x=tl.x,y=tl.y,f=1}}
 until (tl.x~=h.x or tl.y~=h.y) and not trapped()
 spawn_food()
 music(mus_main,2000,7)
end

-->8
-- generation

function cheb(ax,ay,bx,by)
 return max(abs(ax-bx),abs(ay-by))
end

function corner_dist(x,y)
 return max(min(x,cols-1-x),min(y,rows-1-y))
end

function legal_door_cells()
 local c={}
 for x=0,cols-1 do
  for y=0,rows-1 do
   if corner_dist(x,y)>=min_corner_dist then
    add(c,{x=x,y=y})
   end
  end
 end
 return c
end

function gen_doors()
 local dest={{2,3},{1,3},{1,2}}
 local cells=legal_door_cells()
 doors={}
 for f=1,3 do
  local a,b
  repeat
   a=rnd(cells)
   b=rnd(cells)
  until cheb(a.x,a.y,b.x,b.y)>=min_door_dist
  doors[f]={
   {x=a.x,y=a.y,to=dest[f][1]},
   {x=b.x,y=b.y,to=dest[f][2]}
  }
 end
end

function door_at(f,x,y)
 for d in all(doors[f]) do
  if d.x==x and d.y==y then return d end
 end
end

-- the far end of the passage: floor g door back to floor f
function paired_door(f,g)
 for d in all(doors[g]) do
  if d.to==f then return d end
 end
end

function wall_at(f,x,y)
 for w in all(walls[f]) do
  if w.x==x and w.y==y then return true end
 end
 return false
end

-- interior only, so the border ring stays open and no floor is ever cut in
-- two -- and never the four tiles diagonally inside a board corner, which
-- is what corner_dist>=2 excludes. a wall on one of those pins its corner
-- into a forced three-tile run (the corner plus both its neighbours, each
-- down to one way on), the tightest pocket this geometry can make. that
-- leaves 12 of the 16 interior tiles
function legal_wall_cells()
 local c={}
 for x=1,cols-2 do
  for y=1,rows-2 do
   if corner_dist(x,y)>=wall_corner_dist then
    add(c,{x=x,y=y})
   end
  end
 end
 return c
end

function gen_walls()
 walls={}
 wall_count=0
 local cells=legal_wall_cells()
 for f=1,3 do
  local n=wall_min+flr(rnd(wall_max-wall_min+1))
  local w
  -- the whole set is re-rolled, not each tile in turn: the spacing rule is
  -- the only one a second pick can fail, and rolling the pair together
  -- cannot paint itself into a corner the way sequential picking can.
  -- it always terminates -- at most 2 of the 12 cells are doors, and the
  -- remaining 10 are full of pairs at cheb>=2
  repeat
   w={}
   for i=1,n do
    local c=rnd(cells)
    add(w,{x=c.x,y=c.y})
   end
  until not door_at(f,w[1].x,w[1].y)
        and (n<2 or (not door_at(f,w[2].x,w[2].y)
             and cheb(w[1].x,w[1].y,w[2].x,w[2].y)>=min_wall_dist))
  walls[f]=w
  wall_count+=n
 end
end

-->8
-- cells and food

function occupied(x,y,f)
 for s in all(snake) do
  if s.x==x and s.y==y and s.f==f then return true end
 end
 return false
end

function free_cell(f)
 local c
 repeat
  c={x=flr(rnd(cols)),y=flr(rnd(rows))}
 until not door_at(f,c.x,c.y) and not wall_at(f,c.x,c.y)
       and not occupied(c.x,c.y,f)
 return c
end

function free_neighbor(f,c)
 local dirs={{-1,0},{1,0},{0,-1},{0,1}}
 for d in all(dirs) do
  local x,y=c.x+d[1],c.y+d[2]
  if x>=0 and x<cols and y>=0 and y<rows
     and not door_at(f,x,y) and not wall_at(f,x,y) then
   return {x=x,y=y}
  end
 end
 return c
end

function cell_id(x,y,f) return f*36+y*6+x end

function free_cells()
 local taken={}
 for s in all(snake) do taken[cell_id(s.x,s.y,s.f)]=true end
 local c={}
 for f=1,3 do
  for y=0,rows-1 do
   for x=0,cols-1 do
    if not taken[cell_id(x,y,f)] and not wall_at(f,x,y)
       and not door_at(f,x,y) then
     add(c,{x=x,y=y,f=f})
    end
   end
  end
 end
 return c
end

-- food lands only where the snake can come to rest: no wall, no door, and
-- no tile it already holds. excluding doors used to deadlock the endgame --
-- the last free cells were often exactly the doors -- but they are out of
-- total_cells now too, so an empty list means the board is full, not stuck
function spawn_food()
 local c=free_cells()
 if #c==0 then food=nil return end
 food=rnd(c)
end

-->8
-- update

dirs4={{-1,0},{1,0},{0,-1},{0,1}}

function step_sound(ny)
 sfx(sfx_step[rows-ny],3)
end

function _update()
 if intro then
  tk=(tk+1)%48
  -- o and x are bound here and nowhere else. the reason they are unbound in
  -- play -- a stray press must never cost an hour-long run -- is exactly
  -- what makes them right on a screen whose whole job is waiting for one
  if btnp(4) or btnp(5) then intro=false end
  return
 end

 if gameover or won then return end

 if btnp(0) then try_move(-1,0) end
 if btnp(1) then try_move(1,0) end
 if btnp(2) then try_move(0,-1) end
 if btnp(3) then try_move(0,1) end
end

-- where a step lands, or nil when an edge, a block or the neck refuses it.
-- the 4th return says the step transited a door
function dest(h,dx,dy)
 local nx,ny,nf=h.x+dx,h.y+dy,h.f

 -- edges and blocks both refuse the move; neither kills.
 -- tested on the current floor, before any transit
 if nx<0 or nx>=cols or ny<0 or ny>=rows
    or wall_at(nf,nx,ny) then return end

 -- stepping onto a door transits to the paired door on the target floor --
 -- unless a segment is standing in that doorway, in which case the passage
 -- is shut. any part of the body counts, tail included. nothing else would
 -- have caught this: the head never rests on the door it leaves through, so
 -- fatal() only ever sees the far end of the passage.
 -- refused as nil plus a flag, because what refused is a body and not
 -- terrain -- try_move sounds it like a bite
 local thru=false
 local d=door_at(nf,nx,ny)
 if d then
  if occupied(nx,ny,nf) then return nil,true end
  local p=paired_door(nf,d.to)
  nx,ny,nf,thru=p.x,p.y,d.to,true
 end

 -- the neck is never somewhere you can land: the snake has no reverse gear.
 -- at length 2 the neck is also the tail, so nothing else refuses it -- the
 -- tail vacates and the head walks straight back through its own body.
 -- tested after the transit, since a door can drop you onto the neck too
 local k=snake[2]
 if k and k.x==nx and k.y==ny and k.f==nf then return end

 return nx,ny,nf,thru
end

-- growth is resolved first: the tail vacates unless we grow.
-- tested against the landing cell, which after a transit is the far end of
-- the passage. the door that was stepped on is dest()'s business, not this
function fatal(nx,ny,nf)
 local grow=food and food.x==nx and food.y==ny and food.f==nf
 for i=1,grow and #snake or #snake-1 do
  local s=snake[i]
  if s.x==nx and s.y==ny and s.f==nf then return true end
 end
 return false
end

-- every way out is an edge, a block or a segment. the fourth direction is
-- the neck, so this really asks whether all 3 real exits are shut
function trapped()
 for d in all(dirs4) do
  local nx,ny,nf=dest(snake[1],d[1],d[2])
  if nx and not fatal(nx,ny,nf) then return false end
 end
 return true
end

function die(msg)
 gameover=true
 over_msg=msg
 music(-1,400)
 sfx(sfx_die,3)
end

function try_move(dx,dy)
 local h=snake[1]
 -- no movement lock any more: the board is always the head floor, so there
 -- is no state in which the player is looking somewhere they cannot move
 local nx,ny,nf,thru=dest(h,dx,dy)
 if not nx then
  -- with no landing, dest's second return is the reason it refused: true
  -- for a segment standing in a doorway, which is the body saying no and
  -- gets the body's sound, and nil for an edge, a block or the neck, which
  -- is terrain and gets the bump
  sfx(ny and sfx_deny or sfx_bump,3)
  return
 end
 -- a bite is refused, not fatal, whenever the player has another way to go:
 -- the press is heard (sfx_deny) and simply not taken. the exception is the
 -- "no way out" case the refusal must never swallow -- if every direction is
 -- shut, the bite is the only move there is and it stands. trapped() cannot
 -- actually be true here (it is tested after every move and at the roll, so
 -- the game would already be over), which is the point: this is the guard
 -- that keeps a missed dead end an honest death instead of a soft lock
 if fatal(nx,ny,nf) then
  if trapped() then
   die("bit yourself")
  else
   sfx(sfx_deny,3)
  end
  return
 end

 -- after the refusal: a press that never became a step plays no door sweep
 if thru then sfx(sfx_door,3) end

 local grow=food and food.x==nx and food.y==ny and food.f==nf

 add(snake,{x=nx,y=ny,f=nf,dx=dx,dy=dy},1)
 if grow then
  score+=1
  sfx(sfx_eat,3)
  -- written on the bite, not on the death: a run abandoned from the pause
  -- menu or by quitting pico-8 keeps the record it earned
  if score>best then
   best=score
   new_best=true
   dset(0,best)
  end
  if filled()>=total_cells then
   won=true
   food=nil
   music(-1,1000)
   sfx(sfx_win,3)
  else
   spawn_food()
  end
 else
  deli(snake,#snake)
  step_sound(ny)
 end

 -- the board is the head floor, always; the other two are the minimaps
 view=nf

 -- a filled board is a win, not a trap: only look for the dead end after
 if not won and trapped() then die("no way out") end
end
-->8
-- draw

function _draw()
 cls(0)
 draw_board()
 draw_walls()
 draw_doors()
 draw_food()
 draw_snake()
 draw_covered_doors()
 -- the board's edge, and it has to come after the pieces. it is the
 -- outermost pixel row of the board, which is also the outermost row of
 -- every tile on the border ring -- so a piece there overdraws it, and a
 -- visible frame reads as a hole punched through. it never showed while the
 -- frame was 0 and so were the outlines punching it
 rect(ox,oy,ox+cols*tile-1,oy+rows*tile-1,ink_edge)
 draw_minimaps()
 draw_bar()
 if intro then
  draw_intro()
 elseif won then
  draw_win()
 elseif gameover then
  draw_gameover()
 end
end

function px(gx) return ox+gx*tile end
function py(gy) return oy+gy*tile end

-- outlined text: every string on screen goes through this
function oprint(s,x,y,c,o)
 o=o or ink_outline
 for dx=-1,1 do
  for dy=-1,1 do
   if dx~=0 or dy~=0 then print(s,x+dx,y+dy,o) end
  end
 end
 print(s,x,y,c)
end

function draw_board()
 fillp(dith_25)
 rectfill(ox,oy,ox+cols*tile-1,oy+rows*tile-1,1+13*16)
 fillp()
 -- grid lines are 2, not 0: black lines would swallow the tile outlines.
 -- interior posts only -- px(cols)/py(rows) land 1px OUTSIDE the rect below,
 -- and that stray line only stayed invisible while the bar sat on top of it
 for i=1,cols-1 do line(px(i),oy,px(i),oy+rows*tile-1,2) end
 for j=1,rows-1 do line(ox,py(j),ox+cols*tile-1,py(j),2) end
end

function draw_walls()
 for w in all(walls[view]) do
  spr(9,px(w.x),py(w.y),2,2)
 end
end

function draw_doors()
 for d in all(doors[view]) do
  spr(7,px(d.x),py(d.y),2,2)
  -- centred in the door's recessed panel, which is what keeps the 7 legible
  oprint(floor_name[d.to],px(d.x)+6,py(d.y)+5,7)
 end
end

function draw_food()
 if food and food.f==view then spr(5,px(food.x),py(food.y),2,2) end
end

function draw_snake()
 for i=#snake,1,-1 do
  local s=snake[i]
  if s.f==view then
   if i==#snake and i>1 then
    -- the tail is its own tile: pink and inset, so the two ends of a long
    -- body read apart at a glance -- and apart at 4px on the minimaps too,
    -- which a second green could not do. at length 2 the neck is the tail,
    -- and there is no body sprite on the board at all
    spr(13,px(s.x),py(s.y),2,2)
   elseif i>1 then
    spr(3,px(s.x),py(s.y),2,2)
   elseif s.dx~=0 then
    spr(1,px(s.x),py(s.y),2,2,s.dx<0)
   else
    spr(11,px(s.x),py(s.y),2,2,false,s.dy<0)
   end
  end
 end
end

-- a piece standing in a doorway covers it completely -- the segment is a
-- full 16x16 tile and the door is under all of it, letter included -- so the
-- only two doors on the floor can vanish from the board for as long as the
-- body is passing through. the tile gets a 16x16 frame on top instead: the
-- door is still there, it is just under something.
-- 12 is not a new ink. it is the door's own highlight, and already the
-- colour a minimap names a door with, so the mark and the block on the
-- minimap beside it are saying the same thing in the same colour.
-- the head counts as much as the body: after a transit the head comes to
-- rest on the far door of the passage (dest()), so the piece most often
-- sitting on a door is the one the player is steering.
-- drawn after the whole snake rather than per segment, so nothing can end up
-- painted over it, and drawn as a plain rect with no outline of its own:
-- it is a marker on a piece that already carries one, not a piece
function draw_covered_doors()
 for s in all(snake) do
  if s.f==view and door_at(s.f,s.x,s.y) then
   rect(px(s.x),py(s.y),px(s.x)+tile-1,py(s.y)+tile-1,12)
  end
 end
end

-- the two floors the board is not showing, one 4px block per tile. each
-- block takes its piece's own identifying colour (section 6.5) with two
-- readings worth stating: the door is 12, not its base 13, because 13 at
-- this size is indistinguishable from the floor's own dither -- and a free
-- tile is 2, the same ink the big board draws its grid lines in, so a
-- minimap reads as that grid with things standing on it.
-- body beats door where a segment rests in a doorway: an occupied door is
-- genuinely shut -- dest() now refuses the step into it -- and there are
-- only two per floor to remember, while losing the body is losing the map.
-- the tail beats the body for the same reason it is its own sprite on the
-- board: which end is about to move out of the way is the question a
-- minimap gets asked
function draw_minimaps()
 -- one pass over the body, not a scan per cell: 96 segments across 72 cells
 -- is real work every frame, and cell_id already exists for exactly this
 local taken={}
 for s in all(snake) do taken[cell_id(s.x,s.y,s.f)]=true end
 -- same test draw_snake uses, so the two never disagree about which segment
 -- is the tail: at length 2 the neck IS the tail, and at length 1 (which the
 -- game never reaches) there is none
 local tl=#snake>1 and cell_id(snake[#snake].x,snake[#snake].y,snake[#snake].f)
 for i=1,2 do
  -- cycle order, so the floor one step "forward" is always the top slot
  local f=(view+i-1)%3+1
  local my=mm_y+(i-1)*mm_gap
  -- the one string in the game with nothing behind it: every other one sits
  -- on the bar, a door or a panel, where the global 0 outline does visible
  -- work, while here it is black on black and the letter has no rim at all.
  -- so it is outlined in 2 -- not a new colour, but the free-tile ink of the
  -- map right below it, which is also exactly what that map's outer edge
  -- reads as (section 6.1)
  oprint(floor_name[f],mm_x+10,my-9,7,2)
  rect(mm_x-1,my-1,mm_x+cols*mm_tile,my+rows*mm_tile,ink_edge)
  for gx=0,cols-1 do
   for gy=0,rows-1 do
    local c=2
    local id=cell_id(gx,gy,f)
    if wall_at(f,gx,gy) then c=5
    elseif id==tl then c=14
    elseif taken[id] then c=11
    elseif food and food.f==f and food.x==gx and food.y==gy then c=8
    elseif door_at(f,gx,gy) then c=12
    end
    local bx,by=mm_x+gx*mm_tile,my+gy*mm_tile
    rectfill(bx,by,bx+mm_tile-1,by+mm_tile-1,c)
   end
  end
 end
end

-- a segment resting on a door is in transit, not filling floor space, so it
-- counts nowhere. pass f for one floor, pass nothing for the whole board
function filled(f)
 local n=0
 for s in all(snake) do
  if (not f or s.f==f) and not door_at(s.f,s.x,s.y) then n+=1 end
 end
 return n
end

function draw_bar()
 rectfill(0,bar_y,127,127,5)
 fillp(dith_50)
 rectfill(0,bar_y+1,127,bar_y+2,5+0*16)
 fillp()
 line(0,bar_y,127,bar_y,ink_outline)
 oprint("score "..score.."  fill "..filled().."/"..total_cells,5,bar_y+5,7)
 -- right-aligned against the same 5px margin the left column uses: 4px per
 -- character, and the outline needs the last one. 9 while this run owns the
 -- record, 6 when it is somebody else's -- the bar's own alert/secondary inks
 local bs="best "..best
 oprint(bs,123-#bs*4,bar_y+5,new_best and 9 or 6)
end

-- an outlined plate with an inner rim in its own light shade, so the two
-- end screens are lit the same way as every piece on the board. its bounds
-- are derived from ox rather than placed, so it covers the board and nothing
-- else -- the minimap column stays readable under a finished game, and a
-- draw literal left behind when the board moves is what cost a bug last time
function panel(c,c2)
 local x0,x1=ox+4,ox+cols*tile-5
 rectfill(x0,40,x1,64,c)
 rect(x0,40,x1,64,ink_outline)
 rect(x0+1,41,x1-1,63,c2)
end

-- the intro is the game's own screen with a plate on it, exactly like both
-- end screens -- same veil, same panel, same two lines at the same heights.
-- nothing here is new art: the board behind it is the real one, already
-- rolled, so the title sits on the layout that is about to be played
function draw_intro()
 fillp(dith_50+0b0.1)
 rectfill(ox,oy,ox+cols*tile-1,oy+rows*tile-1,0)
 fillp()
 panel(1,13)
 oprint("snakebox",bcx-16,46,7)
 oprint("by roberto freire",bcx-34,55,6)
 -- below the plate, on the floor, blinking: the one thing on screen asking
 -- for an input. the glyph is 8px wide where an ascii char is 4, so this is
 -- centred on a measured 68px, not on #s*2 (section 6.1)
 if tk<32 then oprint("press ❎ to start",bcx-34,78,10) end
end

function draw_gameover()
 fillp(dith_50+0b0.1)
 rectfill(ox,oy,ox+cols*tile-1,oy+rows*tile-1,0)
 fillp()
 panel(1,13)
 -- centred on the board, not the screen: bcx is ox+48
 oprint(over_msg,bcx-#over_msg*2,46,8)
 oprint("menu: restart",bcx-26,55,6)
end

function draw_win()
 -- no veil: the full board is the reward
 panel(3,11)
 oprint("every tile",bcx-20,46,10)
 oprint("menu: restart",bcx-26,55,7)
end
__gfx__
00000000220000000000002222000000000000222200000000000022220000000000002222000000000000222200000000000022222222222222222200000000
0000000020ffffffffffff0220bbbbbbbbbbbb02209999999999990220cccccccccccc02206666666666660220ffffffffffff02222222222222222200000000
000000000fffffffffffff400bbbbbbbbbbbbb4009999999999999400ccccccccccccc4006656560656565400fffffffffffff40222200000000222200000000
000000000faaaaaaaaaaaa400bb3b3b3b3b3b34009888888888888400cdcdcdcdcdcdc4006555550555555400faaaaaaaaaaaa402220ffffffff022200000000
000000000f9a9a9a9a709a400b3b3b3b3b3b3b4009989aaaaaa898400ccd00000000cd4006656560656565400f9a9a9a9a9a9a40220fffffffff402200000000
000000000faaaaaaaa00aa400bb3b3b3b3b3b3400988aaffffaa88400cdc01111110dc4000000000000000000faaaaaaaaaaaa40220feeeeeeee402200000000
000000000f9a9a9a9a9a9a400b3b3b3b3b3b3b400998affffffa98400ccd01111110cd4006650565656065400f9a9a9a9a9a9a40220f8e8e8e8e402200000000
000000000faaaaaaaaaaaa400bb3b3b3b3b3b3400988affffffa88400cdc01111110dc4006550555555055400faaaaaaaaaaaa40220feeeeeeee402200000000
000000000f9a9a9a9a9a9a400b3b3b3b3b3b3b400998affffffa98400ccd01111110cd4006650565656065400f9a9a9a9a9a9a40220f8e8e8e8e402200000000
000000000faaaaaaaaaaaa400bb3b3b3b3b3b3400988affffffa88400cdc01111110dc4006550555555055400faaaaaaaaaaaa40220feeeeeeee402200000000
000000000f9a9a9a9a709a400b3b3b3b3b3b3b400998aaffffaa98400ccd01111110cd4000000000000000000f9a709a9a709a40220f8e8e8e8e402200000000
000000000faaaaaaaa00aa400bb3b3b3b3b3b34009888aaaaaa888400cdc00000000dc4006555550555555400faa00aaaa00aa40220444444444402200000000
000000000f9a9a9a9a9a9a400b3b3b3b3b3b3b4009989898989898400ccdcdcdcdcdcd4006656560656565400f9a9a9a9a9a9a40222044444444022200000000
00000000044444444444444004444444444444400444444444444440044444444444444004444444444444400444444444444440222200000000222200000000
00000000204444444444440220444444444444022044444444444402204444444444440220444444444444022044444444444402222222222222222200000000
00000000220000000000002222000000000000222200000000000022220000000000002222000000000000222200000000000022222222222222222200000000
__label__
00000000000010001000100010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010001000
00000000000000000000000000000000000000000000010001000100010001000100010001000100010001000100010001000100000000000000000000000000
00000000000000000010001000100010101010101010101010101010101010101010101010101010101010101010101010101010101010101010001000100010
00000000000000000000000000000000000000000000000000000001000000000000000000000000000000000001000000000000000000000000000000000000
00000000100077777777400774001010774010107777740010077400101077400777777777774007777777740010101077777400100774001010774010101000
0000000000007aaaaaaa4007a40000007a4001007aaaa4000107a40001007a4007aaaaaaaaaa4007aaaaaaa4010001007aaaa4000107a40000007a4000000000
000000000000444444444007a40000107a400000444444000007a4000000444007aa444444444007aa44444400000000444444000007a40010107a4000100010
000000000774000000000007aa7740007a400774000000774007a4010774000007a4000000000007a400000077400774000000774007a40000007a4000000000
0000000007a4000222222207aaaa40107a4007a40012207a4007a40207a4001207a4022222222207a40222207a4007a40012207a4007a40220107a4022101010
000000000444000000022207aaaa40007a4007a40000007a4007a4000444010207a4000000022207a4000000444007a40102207a400444000000444022000000
00000000000077777402220799999777994007997777779940079977400000120799777774022207997777740000079400122079400000777774000022100010
00000000000079999400000799999999994007999999999940079999400122210799999994010007999999940002079402210079402200799994000222000000
00001000100044444400000799444999994007994444449940079944400002200799444444001007994444440000079402201079400000444444000022101010
00000000000000000077400794000799994007940000007940079400077402210794000000010107940000007740079402200079400774000000774022000000
00000000001000122079400794020799994007940222207940079402079400100794022222222007940222207940079402201079400794001220794010100010
00000000000000000044400794020444994007940222207940079402044400000794000000000007940000004440044400000044400794000220794000000000
00001000077777777400000784020000784007840222207840078402000077400788777777774007887777740000000077777400000784001220784010101010
00000000078888888400020784022100784007840221007840078402210078400788888888884007888888840102220078888400020784022100784022000000
00000000044444444400120444022010444004440220104440044402201044400444444444444004444444440012221044444400120444022010444022101010
00000000000000000000020000022000000000000221000000000002210000000000000000000000000000000102220000000001020000022000000022000000
10001000100022222222201010222010101222102220101012221022201011122210222222222222112222222220101010122222201010222010101222101010
00000000000022222222200001222100010222012221010102220122210101022201222222222222012222222221010101022222210001222100010222000000
00000010001022222222201010222010101222102220101012221022201010122210222222222222102222222220101010122222201010222010101222101010
00000000000000000000000000000001000100010001010101010101010101010101010101010101010101010101010101010001000100010000000000000000
10001000100010101010101010101010101010101010101010101110111011101110111011101110111011101110101010101010101010101010101010101010
00000000000000000000000001000100010101010101010101010101010101010101010101010101010101010101010101010101010101000100010001000000
00000010001000101010101010101010101010101010101010101010101010111011101110111011101010101010101010101010101010101010101010101010
00000000000000000000000000010001000100010101010101000000000000000000000000000000000000000000000000000000000000000001000000000000
10001000101010101010101010101010101010101010101011105555555555555555555555555555555555555555555555555555555555550010101010101010
00000000000000000000010001000100010101010101010101005010101010101010101010101101010101010101010101010101010101010100010001000000
00000010001000101010101010101010101010101010101010105101010101010101010101010010111010101011101010101110101010100010101010101010
00000000000000000000000000010001000100010101010101005010101010101010101010101101010101010101010101010101010101010001000000000000
10001000101010101010101010101010101010101010111011105101010101010101010101010010111010101011101010101110101010100000101010101010
00000000000000000000010001000101010101010101010101005010101010101010101010101101010101010101010101010101010101010000010001000100
00000010001000101010101010101010101010101010101010105101010101010101010101010010111010101011101010101110101010100000101010101010
00000000000000000000000000010001000101010101010101005010101010101010101010101101010101010101010101010101010101010001000100000000
10001000101010101010101010101010101010101010111011105101010101010101010101010010111010101011101010101110101010100000101010101010
00000000000000000000010001000101010101010000000000000000000000000000000000000000000000000000000000000001111111110001010001000100
00100010001000101010101010101010101010101066666666666666666666666666666666666666666666666666666666666600101010100000101010101010
00000000000000000000000100010001000101010061111111121111111112111111111211111111121111111112111111111101010101010001000100000000
10001000101010101010101010101010101010101061010101020101010102010101010201010101020101010102010101010100101010100000101010101010
00000000000000000000010001000101010101010061111111121111111112111111110211111111121111111112111111111100010101010001010001000100
00100010001010101010101010101010101010101061010101020101010102010101010201010101020101010102010101010100001010100000101010101010
00000000000000000000000100010001010101010061111111121111111112111111110211111111121111111112111111111100010101010001000100000000
10001000101010101010101010101010101010101061010101020101010102010101010201010101020101010102010101010100001010100000101010101010
00000000000000000100010001000101010101010061111111121111111112111111111211111111121111111112111111111100010101010001010001000100
00100010001010101010101010101010101010101061010101020101010102010101010201010101020101010102010101010100001010100000101010101010
00000000000000000000000100010000000000000000000000000000000000000000000000000000000000000000022222222200011111110001000100000000
10001000101010101010101010101010666666666666666666666666666666600000000666666666666666666666000000000100001010100000101010101010
0000000000000000010001000101010061111111121111111112111111111205660666501111111112111111111103bbbbbbb000010101010001010001000100
0010001000101010101010101010101061d1d1d1d2d1d1d1d1d2d1d1d1d1d20665056540d1d1d1d1d2d1d1d1d1d10b3b3b3b4000001010100000101010101010
000000000000000000000001000100006111111112111111111211111111120655055540111111111211111111110003b3b34000010101010001000100000000
1000100010101010101010101010101061d1d1d1d2d1d1d1d1d2d1d1d1d1d20000000000d1d1d1d1d2d1d1d1d1d1000b3b3b4000001010100000101010101010
000000000000000001000100010101006111111112111111111211111111120655550540111111111211111111110003b3b34000010101010001010001000100
0010001000101010101010101010101061d1d1d1d2d1d1d1d1d2d1d1d1d1d20665650540d1d1d1d1d2d1d1d1d1d1000b3b3b4000001010100000101010101010
000000000000000000000001000100006111111112111111111211111111120655550540111111111211111111110003b3b34000010101010001000100000000
1000100010101010101010101010101061d1d1d1d2d1d1d1d1d2d1d1d1d1d20544440460d1d1d1d1d2d1d1d1d1d1000444443000001010100000101010101010
00000000000000000000010001010100622222222222222222222222222222200000000222222222222222222222000000000200011111110001010001000100
0000001000100010101010101010101061d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000000000100001010100000101010101010
00000000000000000000000100010000611111111211111111121111111112111111111211111111121111111111000bbbbbb000010101010001000100000000
1000100010101010101010101010101061d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000b3b3b4000001010100000101010101010
000000000000000000000100010001006111111112111111111211111111121111111112111111111211111111110003b3b34000010101010001010001000100
0000001000100010101010101010101061d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000b3b3b4000001010100000101010101010
000000000000000000000000000100006111111112111111111211111111121111111112111111111211111111110003b3b34000010101010001000100000000
1000100010101010101010101010101061d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000b3b3b4000001010100000101010101010
000000000000000000000100010001006111111112111111111211111111121111111112111111111211111111110003b3b34000010101010001010001000100
0000001000100010101010101010101061d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000444443000001010100000101010101010
00000000000000000000000000010000622222222222222222222222222222222222222222222222222222222222000000000200011111110001000100000000
0000100010101010101010101010101061d1d1d1d2d000000002d000000002d000000002d000000002d1d1d1d1d1000000000100001010100000101010101010
00000000000000000000010001000100611111111203bbbbbbb003bbbbbbb003bbbbbbb003bbbbbbb01100000011000bbbbbb000010101010000010001000000
0000001000100010101010101010101061d1d1d1d20b3b3b3b400b3b3b3b400b3b3b3b400b3b3b3b40d08ffffe01000b3b3b4000001010100000101010101010
0000000000000000000000000001000061111111120bb3b3b3400bb3b3b3400bb3b3b3400bb3b3b34010feeee4010003b3b34000010101010001000000000000
0000100010001010101010101010101061d1d1d1d20b3b3b3b400b3b3b3b400b3b3b3b400b3b3b3b40d0fe8e8401000b3b3b4000001010100000101010101010
0000000000000000000000000100010061111111120bb3b3b3400bb3b3b3400bb3b3b3400bb3b3b34010feeee4010003b3b34000010101010000010001000000
0000000000100010001010101010101061d1d1d1d20b3b3b3b400b3b3b3b400b3b3b3b400b3b3b3b40d0fe8e8401000b3b3b4000001010100000101010101010
0000000000000000000000000000000061111111120bb3b3b3400bb3b3b3400bb3b3b3400bb3b3b34010e4444e010003b3b34000010101010001000000000000
0000100010001010101010101010101061d1d1d1d20b444444300b444444300b444444300b44444430d1000000d1000444443000001010100000101010101010
00000000000000000000000001000100622222222220000000022000000002200000000220000000022222222222000000000200011111110000010000000000
0000000000100010001010101010101061d1d1d1d2d000000002d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000101010100001010100000101010101010
00000000000000000000000000000000611111111203bbbbbbb01111111112111111111211111111121111111111000111111100010101010000000000000000
0000000010001000101010101010101061d1d1d1d20b3b3b3b40d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000101010100001010100000101010101010
0000000000000000000000000000010061111111120bb3b3b3401111111112111111111211111111121111111111000111111100010101010000010000000000
0000000000000010001000101010101061d1d1d1d20b3b3b3b40d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000101010100001010100000101010100010
0000000000000000000000000000000061111111120bb3b3b3401111111112111111111211111111121111111111000111111100010101010000000000000000
0000000010001000101010101010101061d1d1d1d20b3b3b3b40d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000101010100001010100000101010101010
0000000000000000000000000000010061111111120bb3b3b3401111111112111111111211111111121111111111000111111100010101010000000000000000
0000000000000010001000100010101061d1d1d1d20b44444430d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000101010100001010100000101000100010
00000000000000000000000000000000622222222220000000022222222222222222222222222222222222222222000222222200010101010000000000000000
000000000000100010001010101010106000000002d000000002d000000002d000000002d1d1d1d1d2d1d000d1d1000101010100000000000000101010101000
00000000000000000000000000000000056606665003bbbbbbb003bbbbbbb00affffffa011111111121008880011000111111100000000000000000000000000
0000000000000000001000100010101006650565400b3b3b3b400b3b3b3b400f9a970a40d1d1d1d1d2d0989890d1000101010100000000000000101000100010
0000000000000000000000000000000006550555400bb3b3b3400bb3b3b3400faaa00a401118111112088fa88801000111111100000000000000000000000000
0000000000000000100010001010101000000000000b3b3b3b400b3b3b3b400f9a9a9a408881d1d1d2089a989801000101010100001010101010101010001000
0000000000000000000000000000000006555505400bb3b3b3400bb3b3b3400faaaaaa4011181111120888888801000111111100010000000000000000000000
0000000000000000000000100010001006656505400b3b3b3b400b3b3b3b400f9a970a40d1d1d1d1d2d0989890d1000101010100001010101010001000100000
0000000000000000000000000000000006555505400bb3b3b3400bb3b3b3400faaa00a4011111111121008880011000111111100000000000000000000000000
0000000000000000100010001000101005444404600b444444300b444444300a44444490d1d1d1d1d2d1d000d1d1000101010100001010101010100010001000
00000000000000000000000000000000600000000220000000022000000002200000000222222222222222222222000111111100000000000000000000000000
0000000000000000000000000010001061d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000000000000001010100010001000000000
00000000000000000000000000000000611111111211111111121111111112111111111211111111121111111111000000000000000000000000000000000000
0000000000000000000010001000100061d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000000000000001010101000100010001000
00000000000000000000000000000000611111111211111111121111111112111111111211111111121111111111000000000000000000000000000000000000
0000000000000000000000000000001061d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000010101010001000100010000000000000
00000000000000000000000000000000611111111211111111121111111112111111111211111111121111111111000000000000000000000000000000000000
0000000000000000000000001000100061d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000010101010101010001000100010000000
00000000000000000000000000000000611111111211111111121111111112111111111211111111121111111111000000000000000000000000000000000000
0000000000000000000000000000000061d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d2d1d1d1d1d1000000100010001000100000000000000000
00000000000000000000000000000000611111111211111111121111111112111111111211111111121111111111000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101000100010001000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100010000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000010001000100010001000101010101010101010101010101010101000100010001000100010000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
50505000000000000000000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050
55550077077007770707077707770077070705555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55550700070707070707070007070707070705555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55550777070707770770077007700707007005555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55550007070707070707070007070707070705555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55550770070707070707077707770770070705555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55550000000000000000000000000000000000000000055500000000000000000000000005555555555555555555555555555555555555555555555555555555
55550666060605550666006606660666066606660066055506660666066606660666066605555555555555555555555555555555555555555555555555555555
55550606060605550606060606060600060600600606055506000606060000600606060005555555555555555555555555555555555555555555555555555555
55550660066605550660060606600660066000600606055506600660066050600660066055555555555555555555555555555555555555555555555555555555
55550606000605550606060606060600060600600606055506000606060000600606060005555555555555555555555555555555555555555555555555555555
55550666066605550606066006660666060600600660055506050606066606660606066605555555555555555555555555555555555555555555555555555555
55550000000005550000000000000000000000000000555500050000000000000000000005555555555555555555555555555555555555555555555555555555
__sfx__
010900002403524025240150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900002603526025260150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900002803528025280150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900002b0352b0252b0150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900002d0352d0252d0150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900003003530025300150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700003044034440374403c44500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0106000024730287312b7313073134731377313c73134725000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800000c6150c615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600002d41500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00002b04326043210331c03318025000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00002445026450284502b4502d45030450324503445037450394503c4503c4513c4513c4513c4513c45100000000000000000000000000000000000000000000000000000000000000000000000000000000
012000001803018031180311803118031180311803118031180311803118031180311803118031180311803113030130311303113031130311303113031130311303113031130311303113031130311303113031
012000001103011031110311103111031110311103111031110311103111031110311103111031110311103118030180311803118031180311803118031180311803118031180311803118031180311803118031
012000001503015031150311503115031150311503115031150311503115031150311503115031150311503110030100311003110031100311003110031100311003110031100311003110031100311003110031
01200000130301303113031130311303113031130311303113031130311303113031130311303113031130310e0300e0310e0310e0310e0310e0310e0310e0310e0310e0310e0310e0310e0310e0310e0310e031
012000001f5241f5211f5211f5211f5211f5211f5211f52123520235212352123521235212352123521235211c5201c5211c5211c5211c5211c5211c5211c5211f5201f5211f5211f5211f5211f5211f5211f521
01200000215242152121521215212152121521215212152124520245212452124521245212452124521245211d5201d5211d5211d5211d5211d5211d5211d5212152021521215212152121521215212152121521
012000001c5241c5211c5211c5211c5211c5211c5211c5211f5201f5211f5211f5211f5211f5211f5211f52121520215212152121521215212152121521215211f5201f5211f5211f5211f5211f5211f5211f521
012000001f5241f5211f5211f5211f5211f5211f5211f521245202452124521245212452124521245212452126520265212652126521265212652126521265212452024521245212452124521245212452124521
012000003403034031340313403134031340313403134031370303703137031370313903039031390313903137030370313703137031370313703137031370310000000000000000000000000000000000000000
012000003c0303c0313c0313c0313c0313c0310000000000390303903139031390313703037031370313703134030340313403134031340313403134031340310000000000000000000000000000000000000000
0120000039030390313903139031390313903139031390313703037031370313703134030340313403134031320303203132031320313203132031320313203100000000000000000000394263c4263e4263c426
0120000039030390313903139031390313903139031390313c0303c0313c0313c0313903039031390313903137030370313703137031370313703137031370310000000000000000000000000000000000000000
012000003403034031340313403134031340313403134031320303203132031320313003030031300313003132030320313203132031320313203132031320310000000000000000000000000000000000000000
0120000039030390313903139031390313903139031390313703037031370313703137031370313703137031340303403134031340313403134031340313403100000000000000000000394263c4263e4263c426
010600002b41500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700002833024335213250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 0c101444
00 0c101544
00 0d111644
00 0d114344
00 0e121744
00 0e121844
00 0d111944
02 0f134344

