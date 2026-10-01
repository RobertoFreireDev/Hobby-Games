pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
trail_lifetime = 120
trail_max_length = 50

function getnewtrail()
	return {color = 0, timestamp = 0}
end

function create_screen_buffer()
	scbfr = {}
 for i=0,127 do
   scbfr[i] = {}
   for j=0,127 do
    scbfr[i][j] = getnewtrail()
   end
 end
end

function _init()
 p = {
		x = 64,
		y = 64
	}
	
 trail_color = 7

 create_screen_buffer()

 frame_count = 0
 
 trail_history = {}
end

function _update()
	frame_count += 1
	
	if btn(0) then p.x = max(p.x - 1, 0) end -- left
	if btn(1) then p.x = min(p.x + 1, 127) end -- right
	if btn(2) then p.y = max(p.y - 1, 0) end -- up
	if btn(3) then p.y = min(p.y + 1, 127) end -- down
	
	scbfr[p.x+4][p.y+4] = {color = trail_color, timestamp = frame_count}

	add(trail_history, {x=p.x+4,y=p.y+4,timestamp=frame_count})

	-- remove the oldest pixel if the trail history exceeds the max length
	if #trail_history > trail_max_length then
		del(trail_history, trail_history[1])
	end
end

function _draw()
	cls()
	
	for i=0,127 do
	 for j=0,127 do
	  local cell = scbfr[i][j]
	  if cell.color ~= 0 then
	   -- check if the trail should still be visible
	   if frame_count - cell.timestamp < trail_lifetime then
	    pset(i, j, cell.color)
	   else
     -- clear the cell if the trail has expired
     scbfr[i][j] = getnewtrail()
	   end
	  end
	 end
	end
	
	spr(1,p.x,p.y)
end
__gfx__
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000