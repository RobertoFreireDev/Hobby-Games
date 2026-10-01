pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- rougue dungeon
-- roberto freire

-- name game
function _init()
	state = game
end

function _update()
	game:update()
end


function _draw()
	cls()
	game:draw()
end


-->8
-- states
game = {
	first=true,
	grid={}
}

function game:init()
	self.grid = grid7x6(0)
	self.grid:set(1, 1, 1)
	self.grid:set(2, 2, 4)
	self.grid:set(2, 1, 2)	
	self.grid:set(3, 2, 3)
	self.grid:set(3, 3, 6)
	self.grid:set(3, 4, 7)
	self.grid:set(4, 4, 8)	
	self.grid:set(2, 4, 5)	
	self.grid:set(1, 4, 9)
end

function game:update()
		if self.first then
				self.first = false
				self:init()
		end
		
		player:update()
end

function game:draw()
		self.grid:draw()
		player:draw()
end

-->8
-- grid
function grid7x6(default_val)
    local g = {
        w = 15,
        h = 14,
        data = {}
    }

    for y=1,g.h do
        g.data[y] = {}
        for x=1,g.w do
            g.data[y][x] = default_val or 0
        end
    end

    function g:get(x, y)
        return self.data[y][x]
    end

    function g:set(x, y, val)
        self.data[y][x] = val
    end
    
    function g:removetile(x,y)
    				local o = convertpostogrid(x,y)
								
								if o.x < 1 or o.x > self.w
										or o.y < 1 or o.y > self.h then
										return 0
								end
								
								local value = self.data[o.y][o.x]
								self.data[o.y][o.x] = 0
								return value
				end
				
				function g:addtile(x,y,val)
    				local o = convertpostogrid(x,y)
								
								if o.x < 1 or o.x > self.w
										or o.y < 1 or o.y > self.h then
										return false
								end
								
								if self.data[o.y][o.x] == 0 then
									self.data[o.y][o.x] = val
									return true
								end
								
								return false
				end
				
    function g:canwalk(x,y,bit,shift,x0,y0,bit0,shift0)
    				local o = convertpostogrid(x,y)
								local oo = convertpostogrid(x0,y0)
								
								if o.x < 1 or o.x > self.w
										or o.y < 1 or o.y > self.h then
										return false
								end
								
								if self.data[o.y][o.x] == 0 then
										return false
								end
								
								local tl = tiles[self.data[o.y][o.x]]
								local tl0 = tiles[self.data[oo.y][oo.x]]
								
								return ((tl.v & bit) >> shift) == 1
									and ((tl0.v & bit0) >> shift0) == 1
				end

    function g:draw()
        local ox, oy, gsz = grid_pos_x,
        				grid_pos_y,
        				grid_size

        for y=1,self.h do
            for x=1,self.w do
                local val = self:get(x,y)
                if val > 0 then
                	local tl=tiles[val]
	                spr(tl.s, ox + (x-1)*gsz, oy + (y-1)*gsz,1,1,tl.fx,tl.fy)
                end
            end
        end
    end

    return g
end
-->8
-- constants and utils
grid_size = 8
grid_pos_x = 4
grid_pos_y = 4
max_pyr_tiles = 3

function convertpostogrid(x,y)
		return {
				x = flr((x-grid_pos_x)/grid_size) +1,
				y =	flr((y-grid_pos_y)/grid_size) +1
		}
end

-- tiles
--v->15 = 1x8 top 1x4 right 1x2 down 1x1 left
tiles = {
	{
		s = 16,
		fx=false,
		fy=false,
		v=14--1110 
	},
	{
		s = 32,
		fx=false,
		fy=false,
		v=7--0111 
	},
	{
		s = 16,
		fx=true,
		fy=false,
		v=11--1011 
	},
	{
		s = 32,
		fx=false,
		fy=true,
		v=13--1101 
	},
	{
		s = 17,
		fx=false,
		fy=false,
		v=5--0101 
	},
	{
		s = 33,
		fx=false,
		fy=false,
		v=10--1010 
	},
	{
		s = 18,
		fx=false,
		fy=false,
		v=15--1111 
	},
	{ s = 19,
		fx=false,
		fy=false,
		v=1--0001 
	},
	{
		s = 19,
		fx=true,
		fy=false,
		v=4--0100 
	}
}

-->8
-- player
player = {
	x = grid_pos_x,
	y = grid_pos_y,
	tx = grid_pos_x,
	ty = grid_pos_y,
	fx=false,
	fy=false,
	spd = 2,
	spt = 1,
	dir=4,
	tiles={}
}

function player:update()
 self:move()
 self:interact()
end

function player:interact()
	if self.x ~= self.tx 
		or self.y ~= self.ty then
		return
	end
		
	-- collect tile
	if btnp(4) and #self.tiles < max_pyr_tiles then
		local value = 0
			
		if self.dir == 1 then
			value = game.grid:removetile(self.tx-grid_size,self.ty)
		elseif self.dir == 2 then
			value = game.grid:removetile(self.tx+grid_size,self.ty)
		elseif self.dir == 3 then
			value = game.grid:removetile(self.tx,self.ty-grid_size)
		elseif self.dir == 4 then
			value = game.grid:removetile(self.tx,self.ty+grid_size)
		end
		
		if value > 0 then
			add(self.tiles,value)
		end
	end	
	
	-- place tile
	if btnp(5) and #self.tiles > 0 then
		local added = false
		local tiletoadd = self.tiles[#self.tiles]
		
		if self.dir == 1 then
			added = game.grid:addtile(self.tx-grid_size,self.ty,tiletoadd)
		elseif self.dir == 2 then
			added = game.grid:addtile(self.tx+grid_size,self.ty,tiletoadd)
		elseif self.dir == 3 then
			added = game.grid:addtile(self.tx,self.ty-grid_size,tiletoadd)
		elseif self.dir == 4 then
			added = game.grid:addtile(self.tx,self.ty+grid_size,tiletoadd)
		end
		
		if added then
			self.tiles[#self.tiles]=nil
		end
	end	
end

function player:move()
	-- if we are not moving
 if self.x == self.tx 
		and self.y == self.ty then
   -- check input to set new target
   if btnp(0) then -- left
   	if self.dir ~= 1 then
    		self.dir = 1
    		self.fx = true
      self.spt = 2
    elseif game.grid:canwalk(self.tx - grid_size,self.y,0b0100,2,self.x,self.y,0b0001,0) then
   			self.tx -= grid_size
   	end
   elseif btnp(1) then -- right
    if self.dir ~= 2 then
    		self.dir = 2
    		self.fx = false
      self.spt = 2
    elseif game.grid:canwalk(self.tx + grid_size,self.y,0b0001,0,self.x,self.y,0b0100,2) then
      self.tx += grid_size
    end
   elseif btnp(2) then -- top
    if self.dir ~= 3 then
    		self.dir = 3
    		self.fy = true
      self.spt = 1
    elseif game.grid:canwalk(self.x,self.ty-grid_size,0b0010,1,self.x,self.y,0b1000,3) then
      self.ty -= grid_size
    end
   elseif btnp(3) then -- down
    if self.dir ~= 4 then
    		self.dir = 4
    		self.fy = false
      self.spt = 1
    elseif game.grid:canwalk(self.x,self.ty+grid_size,0b1000,3,self.x,self.y,0b0010,1) then
      self.ty += grid_size
    end
   end
 else
  -- move toward target
  if self.x < self.tx then
    self.x = min(self.x + self.spd, self.tx)
  elseif self.x > self.tx then
    self.x = max(self.x - self.spd, self.tx)
  elseif self.y < self.ty then
    self.y = min(self.y + self.spd, self.ty)
  elseif self.y > self.ty then
    self.y = max(self.y - self.spd, self.ty)
  end
 end
end

function player:draw()
		spr(self.spt, self.x, self.y,1,1,self.fx,self.fy)
		
		for i=1,#self.tiles do
			local tl = tiles[self.tiles[i]]
			spr(tl.s,2+(i-1)*10,117,1,1,tl.fx,tl.fy)
			if i == #self.tiles then
				rect(2+(i-1)*10,126,9+(i-1)*10,126,13)
			end
		end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000880000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000880000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000880000888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000088888800888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700008888000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000880000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666650000000000566665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666655555555555566665555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666666666666666666666666666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666666666666666666666666666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666666666666666666666666666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666666666666666666666666666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666655555555555566665555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666650000000000566665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000056666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555056666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666056666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666056666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666056666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666056666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55666655056666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666650056666500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
