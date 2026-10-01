pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- puzzle game

-- name game
function _init()
 pal()
	cartdata("cheesearchitect_fjhwbcv")
	load_game()
 menuitem(3,"dark/light mode",toggle_feature)
 menuitem(4, "erase save", function()
     reset_game()
     state = menu
					state:init()
 end)
	state = intro
	state:init()
end

function _update()
	state:update()
end

function _draw()
	cls()	
	applypallete()
	state:draw()
end


-->8
-- states
game = {
	shake_timer=0,
	shake_x=0,
	shake_y=0
}

function game:init()
	level:new()
	history:clear()	
 menuitem(1, "restart stage", function()
     state = game
					state:init()
 end)
 menuitem(2, "menu", function()
     state = menu
					state:init()
 end)  
end

function game:shake()
	if self.shake_timer > 0 then
   self.shake_timer -= 1
   self.shake_x = rnd(2)-1
   self.shake_y = rnd(2)-1
 else
   self.shake_x = 0
   self.shake_y = 0
 end
end

function game:update()		
		level:update()
		self:shake()
end

function game:draw()
		camera(self.shake_x,self.shake_y)
		level:draw()
		camera()
		map(32,2,0,player.mapposy-128,16,16)
end

intro = {
	tmr=0
}

function intro:init()
	self.tmr=0
end

function intro:update()
			if self.tmr > 60 then
					state=menu
					state:init()
					return					
			end			
			self.tmr+=1
end

function intro:draw()
 map(0,0,0,0,16,16)
 rect(40,16,40+64,16+64,1)
 
	printol("cheese architect",41,16+64+8,6,1)
	printol("by roberto freire",41,16+64+24,6,1)
end

menu = {
	spr_w = 16,  
	spr_h = 16,    
	padding = 8,  
	grid_cols = 4,
	grid_rows = 6,
	visible_rows = 4,
	grid = {},
	sel_x = 1,
	sel_y = 1,
	scroll_row = 1,
	mapposy=0,
}

function menu:init()
	menuitem(1)
	menuitem(2)
 self.mapposy=0
	for y=1,self.grid_rows do
   self.grid[y] = {}
   for x=1,self.grid_cols do
       self.grid[y][x] = level.completed[x+(y-1)*self.grid_cols]
   end
	end
end

function menu:update()		
		if self.mapposy>0 then
			self.mapposy+=4
		end
		
		if self.mapposy>=127 then
			state=game
			state:init()
		end
		
		if self.mapposy>0 then
			return
		end
		
		if btnp(❎) or btnp(🅾️) then
				sfx(3)	
				self.mapposy+=1				
		end
	
	 -- handle input
  if btnp(0) then
  				if self.sel_x > 1 or self.sel_y > 1 then
	  				sfx(1)
	  				if self.sel_x == 1 then
	  				 	self.sel_x = self.grid_cols
	  				 	self.sel_y -= 1
  					else
  							self.sel_x -= 1
  					end
  				end
  elseif btnp(1) then
  				if self.sel_x < self.grid_cols or self.sel_y < self.grid_rows then
	  				sfx(1)
	  				if self.sel_x == self.grid_cols then
	  				 	self.sel_x = 1
	  				 	self.sel_y += 1
  					else
  							self.sel_x += 1
  					end
  				end
  elseif btnp(2) then
      if self.sel_y >1 then
	  				sfx(1)
	  				self.sel_y -= 1
  				end
  elseif btnp(3) then
      if self.sel_y <self.grid_rows then
	  				sfx(1)
	  				self.sel_y += 1
  				end
  end
  
  level.crtlevl = self.sel_x+(self.sel_y-1)*self.grid_cols

  -- adjust scroll if selector leaves visible window
  if self.sel_y < self.scroll_row then
      self.scroll_row = self.sel_y
  elseif self.sel_y > self.scroll_row + self.visible_rows - 1 then
      self.scroll_row = self.sel_y - self.visible_rows + 1
  end
end

function menu:draw()
  map(48,0,0,-(self.scroll_row-1)*12,16,29)
		-- calc grid pixel size
  local cell_w = self.spr_w + self.padding
  local cell_h = self.spr_h + self.padding
  local grid_w_px = self.grid_cols * cell_w - self.padding
  local grid_h_px = self.visible_rows * cell_h - self.padding

  -- center grid on screen
  local ox = (128 - grid_w_px) \ 2
  local oy = (128 - grid_h_px) \ 2

  for row=0,self.visible_rows-1 do
      local gy = self.scroll_row + row
      if gy > self.grid_rows then
          break
      end

      for gx=1,self.grid_cols do
         	local cmplt = self.grid[gy][gx]
          local x = ox + (gx-1)*(self.spr_w + self.padding)
          local y = oy + row*(self.spr_h + self.padding)
          
          -- draw selector
          if gx==self.sel_x and gy==self.sel_y then
              spr(cmplt and 99 or 96, x, y,2,2)
          end
          
          spr(cmplt and 66 or 64, x, y,2,2)
      end
  end
  
  map(32,0,0,self.mapposy-127,16,18)
  local indices = string_to_font_indices("level".."_"..tostr(level.crtlevl))

		for i=1,#indices do
		  spr(font[indices[i]],24+i*8,4)
		end
		
		if alllvlscompleted() then
				local indices = string_to_font_indices("completed")
		
				for i=1,#indices do
				  spr(font[indices[i]],16+i*8,110)
				end
		end
end

function alllvlscompleted()
		local result=true
		
		for i=1,#level.completed do
				if level.completed[i]==false then
						result=false
				end
		end
		
		return result
end
-->8
-- grid
function grid7x6(default_val)
    local g = {
        w = grid_h,
        h = grid_w,
        data = {},
        coins = {}
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
    
    function g:canaddtile(o)
						if self:invalidposgrid(o) then
								return false
						end						
						return self.data[o.y][o.x] == 0
				end
				
    function g:canremovetile(o)
    		if self:invalidposgrid(o) then
								return false
						end						
						return self.data[o.y][o.x] > 0
    end
				
				function g:invalidposgrid(o)
						if o.x < 1 or o.x > self.w
								or o.y < 1 or o.y > self.h then
								return true
						end
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
        
        rect(ox,oy,ox-1+self.h*gsz,oy-1+self.w*gsz,1)
        
        for y=1,self.h do
            for x=1,self.w do
                local val = self:get(x,y)
                if val > 0 then
                	local tl=tiles[val]
	                spr(tl.s, ox + (x-1)*gsz, oy + (y-1)*gsz,scale,scale,tl.fx,tl.fy)
                end
            end
        end
        
        foreach(self.coins, function(c)
								  spr(64,ox+(c[1]-1)*gsz,oy+(c[2]-1)*gsz,scale,scale)
								end)
    end

    return g
end
-->8
-- constants and utils
--config
mode={}
mode.palletedark=false

-- animation
plyanim1={1,69}
plyanim2={3,71}

--grid
grid_size = 16
grid_pos_x = 8
grid_pos_y = 4
max_pyr_tiles = 3
scale=2
grid_h=7
grid_w=7

function convertpostogrid(x,y)
		return {
				x = flr((x-grid_pos_x)/grid_size) +1,
				y =	flr((y-grid_pos_y)/grid_size) +1
		}
end

-- tiles
--v->15 = 1x8 top 1x4 right 1x2 down 1x1 left
minitiles = {32,48,32,48,33,49,34,35,35,51,51,36,36,36,36}

tiles = {
	{
		s = 5,
		fx=false,
		fy=false,
		v=14--1110 
	},
	{
		s = 37,
		fx=false,
		fy=false,
		v=7--0111 
	},
	{
		s = 5,
		fx=true,
		fy=false,
		v=11--1011 
	},
	{
		s = 37,
		fx=false,
		fy=true,
		v=13--1101 
	},
	{
		s = 7,
		fx=false,
		fy=false,
		v=5--0101 
	},
	{
		s = 39,
		fx=false,
		fy=false,
		v=10--1010 
	},
	{
		s = 9,
		fx=false,
		fy=false,
		v=15--1111 
	},
	{ s = 11,
		fx=false,
		fy=false,
		v=1--0001 
	},
	{
		s = 11,
		fx=true,
		fy=false,
		v=4--0100 
	},
	{ s = 43,
		fx=false,
		fy=false,
		v=2--0010 
	},
	{
		s = 43,
		fx=false,
		fy=true,
		v=8--1000 
	},
	{
		s = 13,
		fx=false,
		fy=false,
		v=6--0110 
	},
	{
		s = 13,
		fx=false,
		fy=true,		
		v=12--1100
	},
	{
		s = 13,
		fx=true,
		fy=false,
		v=3--0011 
	},
	{
		s = 13,
		fx=true,
		fy=true,
		v=9--1001
	}		
}

--fonts
font={
200,201,202,203,204,205,206,207,
216,217,218,219,220,221,222,223,
232,233,234,235}

letters="levcomptd0123456789_"

function char_to_font_index(ch)
  -- convert ch to lowercase
  ch = sub(tostr(ch),1,1)
  for i=1,#letters do
    if sub(letters,i,i)==ch then
      return i
    end
  end
  -- not found
  return nil
end

function string_to_font_indices(str)
  local indices = {}
  for i=1,#str do
    local ch = sub(str,i,i)
    local idx = char_to_font_index(ch)
    if idx then
      add(indices, idx)
    end
  end
  return indices
end

-- colors
function applypallete()
	if mode.palletedark then
			pal({[0]=0,129,130,131,132,133,134,135,136,9,10,139,140,141,142,15},1)
	else
			pal()
	end	
end

function toggle_feature(b)
		if b&1==1 or b&2==2 then
  	return
  end
  
		mode.palletedark = not mode.palletedark 
  applypallete()
		save_config()
end

-- print
function printol(t,x,y,c1,c2)
	print(t,x,y+1,c2)
	print(t,x,y,c1)
end
-->8
-- player
player = {
	spd = 2
}

function player:reset(mgt,gl,x,y)
	self.fx=false
	self.fy=false
	self.spt = 1
	self.dir=4
	self.tiles={}
	self.coins=0
	self.mapposy=0
	self.anim = plyanim1	
	self.tmranim=0
 self.indxanim=1
	
	self.x = grid_pos_x+(x-1)*grid_size
	self.y = grid_pos_y+(y-1)*grid_size
	self.tx = self.x
	self.ty = self.y
	self.maxgettiles=mgt
	self.goal=gl
end

function player:update()
	if self:tomenu() or player:undo() then
			return
	end
	
	self:win()
	self:loose()
 self:move()
 self:interact()
end

function player:tomenu()
		if self.mapposy == 0 then
				return false
		end
		
		self.mapposy+=4
		
		if self.mapposy >= 127 then
				state=menu
				state:init()
		end
		
		return true
end

function player:undo()
	if not btnp(🅾️) then
		return false
	end 
	
	if history:undo()	then
			game.shake_timer = 10
			sfx(6)
			return true
	end
	
	return false
end

function player:interact()
	if self.x ~= self.tx 
		or self.y ~= self.ty then
		return
	end
	
	local nxtpos = {}
	if self.dir == 1 then
		nxtpos = { self.tx-grid_size,self.ty}
	elseif self.dir == 2 then
		nxtpos = { self.tx+grid_size,self.ty}
	elseif self.dir == 3 then
		nxtpos = { self.tx,self.ty-grid_size}
	elseif self.dir == 4 then
		nxtpos = { self.tx,self.ty+grid_size}
	end
	
	local posgrid = convertpostogrid(nxtpos[1],nxtpos[2])
	
	-- collect tile
	if btnp(❎) and #self.tiles < max_pyr_tiles
			and level.grid:canremovetile(posgrid) then
				history:save()
				self.maxgettiles-=1
				add(self.tiles,level.grid:get(posgrid.x,posgrid.y))
				level.grid:set(posgrid.x,posgrid.y,0)
		return
	end	
	
	-- place tile
	if btnp(❎) and #self.tiles > 0
			and	level.grid:canaddtile(posgrid) then
				history:save()
				level.grid:set(posgrid.x,posgrid.y,self.tiles[#self.tiles])
				self.tiles[#self.tiles]=nil
	end	
end

function player:loose()
	if self.maxgettiles<=0 then
			sfx(4)
			self.mapposy+=1
	end
end

function player:win()
	if self.coins >= self.goal then
			sfx(5)			
			level.completed[level.crtlevl]=true
			self.mapposy+=1
			save_game()
	end
end

function player:move()
	-- if we are not moving
 if self.x == self.tx 
		and self.y == self.ty then
			local changes=false
			history:save()
			local posgd=convertpostogrid(self.x,self.y)
			
			--check coins
			for i=1,#level.grid.coins  do
		  local c=level.grid.coins[i]
		  if c ~=nil and posgd.x == c[1] and posgd.y == c[2] then
						self.coins+=1
						del(level.grid.coins,c)
						sfx(0)
				end
		 end
		
   -- check input to set new target
   if btnp(0) then -- left
   	if self.dir ~= 1 then
    		self.dir = 1    		
    		self.fx = true
    		self.fy = true
    		self.anim = plyanim2
      self.spt = self.anim[1]
      changes=true
    elseif level.grid:canwalk(self.tx - grid_size,self.y,0b0100,2,self.x,self.y,0b0001,0) then
   			self.tx -= grid_size
   			changes=true
   	end
   elseif btnp(1) then -- right
    if self.dir ~= 2 then
    		self.dir = 2
    		self.fx = false
    		self.fy = false
    		self.anim = plyanim2
      self.spt = self.anim[1]
      changes=true
    elseif level.grid:canwalk(self.tx + grid_size,self.y,0b0001,0,self.x,self.y,0b0100,2) then
      self.tx += grid_size
      changes=true
    end
   elseif btnp(2) then -- top
    if self.dir ~= 3 then
    		self.dir = 3
    		self.fx = true
    		self.fy = true
    		self.anim = plyanim1
      self.spt = self.anim[1]
      changes=true
    elseif level.grid:canwalk(self.x,self.ty-grid_size,0b0010,1,self.x,self.y,0b1000,3) then
      self.ty -= grid_size
      changes=true
    end
   elseif btnp(3) then -- down
    if self.dir ~= 4 then
    		self.dir = 4
    		self.fx = false
    		self.fy = false
    		self.anim = plyanim1
      self.spt = self.anim[1]      
    		changes=true
    elseif level.grid:canwalk(self.x,self.ty+grid_size,0b1000,3,self.x,self.y,0b0010,1) then
      self.ty += grid_size
    		changes=true
    end
   end
   
   if changes==false then
   	history:remove()
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
  
  --update animation
  self.tmranim+=1  
  if self.tmranim>2 then
  		self.tmranim=0
  		self.indxanim+=1
  		if self.indxanim > #self.anim then
  				self.indxanim=1
  		end
  		self.spt = self.anim[self.indxanim]
  end
 end
end

function player:draw()
		spr(self.spt, self.x, self.y,scale,scale,self.fx,self.fy)
		
		for i=1,#self.tiles do
			local tl = tiles[self.tiles[i]]
			local mtl = minitiles[self.tiles[i]]
			spr(mtl,2+(i-1)*10,117,1,1,tl.fx,tl.fy)
			if i == #self.tiles then
				rect(2+(i-1)*10,126,9+(i-1)*10,126,13)
			end
		end
		
		for i=1,self.coins do
			spr(50,2+(i+2)*10,117,1,1)
		end
		
		local indices = string_to_font_indices(tostr(self.maxgettiles))

		for i=1,#indices do
		  spr(font[indices[i]],100+i*8,120)
		end
end
-->8
-- levels
level={
	crtlevl=1,
	completed={},
	stages={
		{-- 1
			ltls = {
				{3,1,10},{3,2,6},
				{3,3,6},{3,4,6},
			},
			cheeses = {{3,5}},
			maxgettiles = 3,
			pos={3,1}
		},
		{-- 2
			ltls = {
				{2,1,1},{3,1,2},{4,1,3},{5,1,4},
				{2,3,5},{3,3,6},{4,3,7},{5,3,8},
				{2,4,9},{3,4,10},{4,4,11},{5,4,12},
				{2,6,13},{3,6,14},{4,6,15}
			},
			cheeses = {{2,1},{3,6},{5,3}},
			maxgettiles = 8,
			pos={3,3}
		},
		{-- 3
				ltls = {
				{1,1,1},{2,2,4},{2,1,2},
				{3,2,3},{3,3,6},{3,4,7},
				{4,4,8},{2,4,5},{1,4,9},
				{6,4,8},{6,7,5},{5,7,9}
			},
			cheeses = {{4,4},{5,7}},
			maxgettiles = 7,
			pos={1,1}
		},
		{-- 4
			ltls = {
				{1,1,1},{2,2,4},{2,1,2},
				{6,4,8},{6,7,5},{5,7,9}
			},
			cheeses = {{4,4},{5,7}},
			maxgettiles = 10,
			pos={1,1}
		},
		{-- 5
			ltls = {
				{2,1,5},{3,1,12},{4,1,13},{5,1,14},
				{2,3,9},{3,3,6},{4,3,7},{5,3,8},
				{2,6,1},{3,6,1},{6,6,1}
			},
			cheeses = {{2,1},{6,6}},
			maxgettiles = 10,
			pos={3,3}
		},
		{-- 6
			ltls = {
				{2,3,15},{3,3,7},{1,4,6},{5,3,3},
				{2,4,1},{3,6,9},{4,6,3},{5,4,6},
			},
			cheeses = {{5,5},{1,6}},
			maxgettiles = 9,
			pos={3,3}
		},
		{-- 7
			ltls = {
				{2,3,5},{3,3,6},{4,3,7},{5,3,8},
			},
			cheeses = {{1,1},{6,6}},
			maxgettiles = 13,
			pos={3,3}
		},
		{-- 8
			ltls = {
				{2,3,1},{3,2,2},
				{4,3,7},{4,4,4},{5,4,2},
				{5,5,14},{5,6,15},{7,4,6}
			},
			cheeses = {{2,1},{6,6}},
			maxgettiles = 8,
			pos={4,3}
		},
		{-- 9
			ltls = {
				{2,1,13},{3,1,15},{4,1,14},{5,1,4},
				{2,3,14},{3,3,6},{4,3,7},{5,3,8},
				{2,4,9},{3,4,15},{4,4,11},{5,4,13},
				{2,6,13},{3,6,14},{4,6,15}
			},
			cheeses = {{6,1},{6,6}},
			maxgettiles = 13,
			pos={3,3}
		},
		{-- 10
			ltls = {
				{2,1,1},{3,1,2},{4,1,3},{5,1,4},
				{2,3,5},{3,3,6},{4,3,7},{5,3,8},
				{2,4,9},{3,4,10},{4,4,7},{5,4,12},
				{2,6,13},{3,6,14},{4,6,15},
				{6,6,13},{5,6,14},{6,5,15}
			},
			cheeses = {{2,1},{3,6},{5,3}},
			maxgettiles = 8,
			pos={6,6}
		},
		{-- 11
			ltls = {
				{2,2,10},{3,1,1},{3,3,3},{5,1,4},
				{2,3,5},{3,3,2},{4,3,15},{5,3,8},
				{2,6,13},{3,6,4},{4,6,10}
			},
			cheeses = {{2,2},{6,6},{1,6}},
			maxgettiles = 17,
			pos={3,3}
		},
		{-- 12 
			ltls = {
				{2,2,10},{3,1,1},{3,3,3},{5,1,4},
				{2,3,5},{3,3,2},{4,3,15},{5,3,8},
				{2,6,13},{3,6,4},{4,6,10}
			},
			cheeses = {{2,2},{6,1},{4,6}},
			maxgettiles = 14,
			pos={3,3}
		},
		{-- 13
			ltls = {
				{1,1,12},{2,1,8},{1,2,13},{5,1,4},
				{2,3,11},{3,3,12},{4,3,15},{5,3,8},
				{2,6,2},{3,6,4},{4,6,10}
			},
			cheeses = {{2,6},{6,3},{4,6}},
			maxgettiles = 26,
			pos={1,1}
		},
		{-- 14
			ltls = {
				{1,1,1},{1,2,12},{1,3,3},{1,6,3},
				{2,4,9},{3,4,6},{4,4,11},
				{6,5,3},{5,6,2},{6,6,1}
			},
			cheeses = {{1,1},{3,4},{1,6}},
			maxgettiles = 11,
			pos={6,6}
		},
		{-- 15
			ltls = {
				{1,1,1},{1,2,12},{1,3,3},{1,6,3},
				{2,4,12},{3,4,15},{4,4,2},
				{6,5,3},{5,6,2},{6,6,1}
			},
			cheeses = {{1,1},{3,4},{1,6}},
			maxgettiles = 9,
			pos={6,6}
		},
		{-- 16
			ltls = {
				{4,1,1},{2,2,12},{1,3,3},{1,6,3},
				{2,4,12},{3,4,15},{4,4,2},
				{6,5,3},{5,6,2},{6,6,1}
			},
			cheeses = {{4,1},{3,4},{1,6}},
			maxgettiles = 11,
			pos={5,6}
		},
		{-- 17
			ltls = {
				{1,1,1},{3,1,2},{1,6,3},
				{2,3,5},{3,3,6},{4,3,7},{5,3,8},
				{2,4,13},{3,4,15},{4,4,11},{5,4,12},
				{3,6,14},{6,6,15}
			},
			cheeses = {{1,1},{1,7},{7,1},{6,6}},
			maxgettiles = 19,
			pos={3,3}
		},
		{-- 18
			ltls = {
				{2,1,13},{3,1,14},{4,1,11},{5,1,12},
				{3,4,15},{3,3,5},{4,4,1},{5,4,12},
				{2,6,13},{3,6,14},{4,6,15}
			},
			cheeses = {{2,2},{2,5},{5,2},{5,4}},
			maxgettiles = 15,
			pos={3,3}
		},
		{-- 19
			ltls = {
				{2,1,13},{3,1,14},{4,1,11},{5,1,12},
				{3,4,15},{3,3,5},{4,3,14},{4,4,1},{5,4,12},
				{2,6,13}
			},
			cheeses = {{1,1},{2,5},{5,2},{5,4}},
			maxgettiles = 11,
			pos={4,3}
		},
		{-- 20
			ltls = {
				{2,1,13},{3,1,14},{4,1,11},{5,1,15},
				{3,3,5},{4,3,14},{4,4,1},{5,4,12},
				{2,6,13}
			},
			cheeses = {{2,5},{5,2},{5,4}},
			maxgettiles = 9,
			pos={4,3}
		},
		{-- 21
			ltls = {
				{2,1,13},{3,1,14},{4,1,11},{5,1,15},
				{3,3,5},{4,3,14},{4,4,1},{5,4,12},
				{2,6,13}
			},
			cheeses = {{3,6},{5,2},{5,4}},
			maxgettiles = 10,
			pos={2,1}
		},
		{-- 22
			ltls = {
				{4,1,11},{5,1,15},
				{3,3,5},{4,3,14},{4,4,1},{5,4,12},
				{2,6,13}
			},
			cheeses = {{2,7},{5,4}},
			maxgettiles = 12,
			pos={3,3}
		},		
		{-- 23
			ltls = {
				{5,1,4},
				{5,3,7},{3,3,15},{4,3,12},
				{5,4,12},
				{2,6,13},{3,6,14},{4,6,15}
			},
			cheeses = {{3,6},{2,1}},
			maxgettiles = 11,
			pos={5,3}
		},
		{-- 24
			ltls = {
				{5,1,4},
				{2,3,13},{3,3,15},{4,3,12},
				{4,4,7},{5,4,12},
				{2,6,13},{3,6,14},{4,6,15}
			},
			cheeses = {{2,1},{3,6},{5,3}},
			maxgettiles = 16,
			pos={3,3}
		}
	}
}

function level:new()
	self.grid = grid7x6(0)	
	local cs = self.stages[self.crtlevl]
	
	foreach(cs.ltls, function(t)
	  self.grid:set(t[1],t[2],t[3])
	end)	
	foreach(cs.cheeses, function(c)
	  add(self.grid.coins,c)
	end)
	
	player:reset(cs.maxgettiles,#cs.cheeses,cs.pos[1],cs.pos[2])
end

function level:update()
	player:update()
end

function level:draw()
		self.grid:draw()
		player:draw()
end
-->8
-- save/load
function load_game()
	level.completed={}
	local nmbrlvls=menu.grid_cols*menu.grid_rows
	
	for i=1,nmbrlvls do
		add(level.completed,dget(i) == 1)
	end
	
	mode.palletedark=dget(0)==1
end

function save_game()
	local nmbrlvls=menu.grid_cols*menu.grid_rows
	
	for i=1,nmbrlvls do
		dset(i,level.completed[i] and 1 or 0)
	end
end

function save_config()
	dset(0,mode.palletedark and 1 or 0)
end

function reset_game()
	for i=0,1+menu.grid_cols*menu.grid_rows do
		dset(i,0)
	end
	load_game()
end
-->8
history = {
 stack = {},
}

function history:save()
  local copy = {}
  
  --grid
  copy.grid = {}
  copy.grid.data = {}
  copy.coins={}
  local lg = level.grid
  for y=1,lg.h do
    copy.grid.data[y] = {}
    for x=1,lg.w do
        copy.grid.data[y][x] = lg.data[y][x]
    end
  end
  foreach(lg.coins, function(c)
				add(copy.coins,{c[1],c[2]})
		end)
		
		--player
		copy.pyr={}		
		copy.pyr.fx=player.fx
		copy.pyr.fy=player.fy
		copy.pyr.spt=player.spt
		copy.pyr.dir=player.dir
		copy.pyr.tiles={}
		foreach(player.tiles, function(t)
				add(copy.pyr.tiles,t)
		end)
		copy.pyr.coins=player.coins
		copy.pyr.anim={}
		foreach(player.anim, function(a)
				add(copy.pyr.anim,a)
		end)	
		copy.pyr.tmranim=player.tmranim
	 copy.pyr.indxanim=player.indxanim	
		copy.pyr.x=player.x
		copy.pyr.y=player.y 
		copy.pyr.tx=player.tx 
		copy.pyr.ty=player.ty
		copy.pyr.maxgettiles=player.maxgettiles 
		
  add(self.stack, copy)
end

function history:undo()
		if #self.stack == 0 then
				return false
		end
		
  -- undo grid
  local lg = level.grid
  local copy = self.stack[#self.stack]
  for y=1,lg.h do
    lg.data[y] = {}
    for x=1,lg.w do
        lg.data[y][x] = copy.grid.data[y][x]
    end
  end
  if #copy.coins>0 then
  	lg.coins={}
  end
  foreach(copy.coins, function(c)
				add(lg.coins,{c[1],c[2]})
		end)
  
  --undo player
  --player
		player.fx=copy.pyr.fx
		player.fy=copy.pyr.fy
		player.spt=copy.pyr.spt
		player.dir=copy.pyr.dir
		player.tiles={}
		foreach(copy.pyr.tiles, function(t)
				add(player.tiles,t)
		end)
		player.coins=copy.pyr.coins
		player.anim={}
		foreach(copy.pyr.anim, function(a)
				add(player.anim,a)
		end)	
		player.tmranim=copy.pyr.tmranim
	 player.indxanim=copy.pyr.indxanim	
		player.x=copy.pyr.x
		player.y=copy.pyr.y 
		player.tx=copy.pyr.tx 
		player.ty=copy.pyr.ty
		player.maxgettiles=copy.pyr.maxgettiles 
		
	 deli(self.stack)
	 
	 return true
end

function history:remove()
		if #self.stack > 0 then
	  deli(self.stack)
	 end
end

function history:clear()
 	self.stack = {}
end
__gfx__
000000000000000000000000000000000000000044ffffffffffff44444444444444444444ffffffffffff444444444444444444444444444444444400000000
000000000000dddd00000000000000000000000044fffffaffffff44444444444444444444fffff9ffffff444444444444444444444444444444444400000000
00700700000d6666dddd0000000000000000000044fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44444ffffffffffffff00000000
000770000000dd666666d000000ddd0ddd00000044fffff9fffffffffffffffffffffffffffffffffaffffffffffffffffffff4444ffffffffffffff00000000
00077000000d66666666d00000d666d666d0000044ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4444ffffffffffffff00000000
00700700000d66666666d00000d666d6666d000044ffffffafffffffffffffffffffffffffffffff9fffffffffffffffffffff4444ffffffffffffff00000000
000000000000dd6666dd000000d6666d6556d00044ffffffffffffffffffffffffffafffffffffffffffffffffffffffffffff4444ffffffffffafff00000000
00000000000d66d66d66d00000d6666666666d0044ffffffffffffaff9ffaffffaffff9ffffffff9fff9ffffffffffffffffff4444ffffffffffff9f00000000
00000000000d66666666d0000d66666666666d0044fffff9ffff9ffffffffff9fffffffff9ffaffffaffff9ffaffffffffffff4444fffffffaf9ffff00000000
00000000000d66566566d0000d66666d6556d00044ffffffffaffffffffffffffffffffffffffffffffffffffff9ffffffffff4444ffffffffffffff00000000
000000000000d656656d00000d6d66d6666d000044ffffff9fffffffffffffffffffffffffffffff9fffffffffffffffffffff4444fffffff9ffffff00000000
0000000000000d6666d000000d6d66d666d0000044ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4444ffffffffffffff00000000
00000000000000d66d00000000d0dd0ddd00000044ffffffaffffffffffffffffffffffffffffffaffffffffffffffffffffff4444ffffffafffffff00000000
000000000000000dd0000000000000000000000044fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44444ffffffffffffff00000000
000000000000000000000000000000000000000044fffffaffffff44444444444444444444ffffff9fffff44444444444444444444ffffff9fffff4400000000
000000000000000000000000000000000000000044ffffffffffff44444444444444444444ffffffffffff44444444444444444444ffffffffffff4400000000
44ffff444444444444ffff444444444444444444444444444444444444ffffffffffff4400000000000000004444444444444444000000000000000000000000
44ffff444444444444ffff444444444444444444444444444444444444fffff9ffffff4400000000000000004444444444444444000000000000000000000000
44ffffffffffffffffffffffffffff4444ffffffffffffffffffffff44ffffffffffff440000000000000000444ffffffffff444000000000000000000000000
44ffffffffffffffffffffffffffff4444ffffffffffffffffffffff44ffffafffffff44000000000000000044ffffffffffff44000000000000000000000000
44ffffffffffffffffffffffffffff4444ffffffffffffffffffffff44ffffffffffff44000000000000000044ffffffffffff44000000000000000000000000
44ffffffffffffffffffffffffffff4444ffffffffffffffffffffff44ffffffffffff44000000000000000044ffffffffffff44000000000000000000000000
44ffff444444444444ffff444444444444ffff44ffffffffffffffff44fffffaffffff44000000000000000044ffffffffffff44000000000000000000000000
44ffff444444444444ffff444444444444ffff44fafffff9ffff9faf44ffffffffffff44000000000000000044ffffffffffff44000000000000000000000000
4444444444ffff440000ddd04444444400000000fffaf9ffffafffff44ffffff9fffff44000000000000000044ffffffffffff44000000000000000000000000
4444444444ffff44000daaad4444444400000000ffffffffffffffff44ffffffffffff44000000000000000044ffffffffffff44000000000000000000000000
ffffffff44ffff4400daa9ad44ffff4400000000ffffffafffffffff44ffffffffffff44000000000000000044ffffffffffff44000000000000000000000000
ffffffff44ffff440daaaaad44ffff4400000000ffffffffffffffff44fffffaffffff44000000000000000044ffffffffffff44000000000000000000000000
ffffffff44ffff44d777777d44ffff4400000000fffffff9ffffffff44ffffffffffff44000000000000000044fffffff9ffff44000000000000000000000000
ffffffff44ffff44d9a99a9d44ffff4400000000ffffffffffffffff44ffffffffffff44000000000000000044ffffffffffff44000000000000000000000000
44ffff4444ffff44d999999d44ffff440000000044ffffffafffff4444fffff9ffffff44000000000000000044ffffffafffff44000000000000000000000000
44ffff4444ffff440dddddd044ffff440000000044ffffffffffff4444ffffffffffff44000000000000000044ffffffffffff44000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000dddd0000000000000000000000000000dddd000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000d6666dddd00000000000000000000000d0000dddd00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000d6dd666666d000000dddd0ddd0000000d0dd000000d000000dddd0ddd00000000000000000000000000000
0000000ddddd0000000000000000000000000000000d66666666d00000d6666d666d0000000d00000000d00000d0000d000d0000000000000000000000000000
000000daaaaad000000000000000000000000000000d66666666d00000d6666d6666d000000d00000000d00000d0000d0000d000000000000000000000000000
00000daa9aaad0000000000dd000000000000000000d66666666d00000d66666d6556d00000d00000000d00000d00000d0000d00000000000000000000000000
0000daaaaaaad000000000daaddd0000000000000000dd6666dd000000d66666666666d00000dd0000dd000000d00000000000d0000000000000000000000000
000d77777777d00000000d777777d00000000000000d66d66d66d0000d666666666666d0000d00d00d00d0000d000000000000d0000000000000000000000000
000d99a99999d000000000d99999d00000000000000d66666666d0000d666666d6556d00000d00000000d0000d000000d0000d00000000000000000000000000
000d999999a9d00000000d9999a9d00000000000000d66566566d0000d6d666d6666d000000d00000000d0000d0d000d0000d000000000000000000000000000
0000d9999999d0000000d9999999d000000000000000d656656d00000d6d666d666d00000000d000000d00000d0d000d000d0000000000000000000000000000
00000ddddddd000000000ddddddd00000000000000000d6666d0000000d6ddd0ddd0000000000d0000d0000000d0ddd0ddd00000000000000000000000000000
0000000000000000000000000000000000000000000000d66d000000000d000000000000000000d00d000000000d000000000000000000000000000000000000
00000000000000000000000000000000000000000000000dd000000000000000000000000000000dd00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000ffffffff00000000000000000000000000000000000000000000000000000000000000000000000dd0000000000000000000000000000000
0000000000000000ffffffff000000000000000000000000000000000000000000000000000000000000d000000000d00d000000000000000000000000000000
0000000000000000ffffffff00000000000000000000000000000000000000000000000000000ddd0ddd0d0000000d0000d00000000000000000000000000000
0000000000000000ffffffff0000000000000000000000000000000000000000000000000000d000d000d0d00000d000000d0000000000000000000000000000
0000000000000000ffffffff000000000000000000000000000000000000000000000000000d0000d000d0d0000d00000000d000000000000000000000000000
0000000000000000ffffffff00000000000000000000000000000000000000000000000000d0000d000000d0000d00000000d000000000000000000000000000
0000000000000000ffffffff0000000000000000000000000000000000000000000000000d000000000000d0000d00d00d00d000000000000000000000000000
0000ffffffff0000ffffffff0000666666660000000000000000000000000000000000000d00000000000d000000dd0000dd0000000000000000000000000000
00ffffffffffff00ffffffff00666666666666000000000000000000000000000000000000d0000d00000d00000d00000000d000000000000000000000000000
0ffffffffffffff0ffffffff066666666666666000000000000000000000000000000000000d0000d0000d00000d00000000d000000000000000000000000000
0ffffffffffffff0ffffffff0666666666666660000000000000000000000000000000000000d000d0000d00000d00000000d000000000000000000000000000
0ffffffffffffff0ffffffff06666666666666600000000000000000000000000000000000000ddd0dddd000000d000000dd0d00000000000000000000000000
04ffffffffffff40ffffffff05666666666666500000000000000000000000000000000000000000000000000000dddd0000d000000000000000000000000000
0044ffffffff4400ffffffff005566666666550000000000000000000000000000000000000000000000000000000000dddd0000000000000000000000000000
00004444444400004444444400005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111ddddddddddddd1444444411111111111111111111166666666666666666666666666666666666666666666666666666666d6d6d6d6
4111111111111111111111dddddddddddddd1144444411111111111111d1d111666666666611111116666666661166666666116666116666666611666d6d6d6d
4441111111112112121211dddddddddddddddd144441511111111111111dddd16666666661777777716666666177166666617716617716666661771666666666
4444111111121221212121ddddddddddddddddd1141551121212121111dddddd6666666661777777716666666177166666617716617716666661771666666666
4444441111212122222211ddddddddddddddddddd15551212121212111dddddd6666666661777777716666666177166666617716617716666661771666666666
4444444111121222222221ddddddddddddddddddd15551112222221211dddddd6666666661777777716666666177111111117716617716666661771666666666
4444444441212222222221ddddddddddddddddddd15551122222222121dddddd6666666661777777716666666177777777777716617716666661771666666666
6444444444112222f2f2f1ddddddddddddddddddd15551222222222221dddddd6666666661777777716666666177777777777716617716666661771666666666
d664444444441f2f2f2f21ddddddddddddddddddd15551222222222221dddddd6666666161771177716666666177777777777716617716666661771600000000
ddd6444444444112f2f2f1ddddddddddddddddddd15551222222222221dddddd6666666161771177771111666177777777777716617771111117771600000000
dddd664444444441ffff21ddddddddddddddddddd15551222222222221dddddd6666666161777777777777166177111111117716617777777777771600000000
dddddd644444444411fff1ddddddddddddddddddd1555122222222222211dddd6666666161777777777777166177166666617716617777777777771600000000
ddddddd664444444441ff1ddddddddddddddddddd15551222222222222221ddd6666666161777777777777166177166666617716617777777777771600000000
ddddddddd6444444444111ddddddddddddddddddd1555122222222222222211d6666666166177777777777166177166666617716617777777777771600000000
dddddddddd664444444441ddddddddddddddddddd155512222222222222222216666666166611111111111666611666666661166661111111111116600000000
dddddddddddd644444444411ddddddddddddddddd155512222222222222222226666666166666666666666666666666666666666666666666666666600000000
ddddddddddddd664444444441dddddddddddddddd155512222222222222222226666666666666666666666666666666666666666666666666666666666666666
ddddddddddddddd644444444411dddddddddddddd155512222222222222222226611111111111666661111111111166666666666666666666666661111666666
dddddddddddddddd66444444651dddddddddddddd155512f2f2f2222222222226177777777777166617777777777716666666611116666666666661771666666
dddddddddddddddddd644446551dddddddddddddd15551f2f2f2f22222222222617777777777771661777777777777166666661ee16666666666661771666666
ddddddddddddddddddd66465551dddddddddddddd155512fffff2f2222222222617777777777771661777777777777166666111ee11166666666661771666666
ddddddddddddddddddddd655551ddddddddd1111d15551fff1111222222222226177777777777716617711777711771666661ff77dd166666666661771666666
ddddddddddddddddddddd65555111dddddd16666115551ff166661f2222222226177777777777716617711777711771666111ff77dd111666666661111666666
ddddddddddddddddddddd655551ff1dddd166666615551f16655661f222222226177111111117716617711777711771666188777777cc1666666666666666666
ddddddddddddddddddddd655551fff11d1666666661551f665555612f22222226177111111117716617711777711771666188777777cc166dddddddd00000000
ddddddddddddddddddddd655551fffff1166666666155116555556612222222261777777777777166177117777117716661119977bb11166dddddddd00000000
ddddddddddddddddddddd655551ffffff16666666d1551665555ee61ff22222261777777777777166177777777777716666619977bb16666dddddddd00000000
ddddddddddddddddddddd655551ffffff1666666dd1551655555ee61f2f22222617777777777771661777777777777166666111aa1116666dddddddd00000000
ddddddddddddddddddddd655551ffffff1666666ddd11165555eee61ff2f2222617777777777771661777777777777166666661aa1666666dddddddd00000000
ddddddddddddddddddddd655551ffffff166666dd6666165555eee61ff2f2222617777777777771666111117777777166666661111666666dddddddd00000000
ddddddddddddddddddddd655551fffffff1666666666666655eeee61fff2f221661111111111116666666661111111666666666666666666dddddddd00000000
ddddddddddddddddddddd655551ffffffff166666666666665eee661ffff2214666666666666666666666666666666666666666666666666dddddddd00000000
ddddddddddddddddddddd655551ffffffff16666666666666eeee61ffff2f1440100000001111110010000100111111001111110010000100111110001111110
ddddddddddddddddddddd655551fffffff1666666666666666eee61fff2f14441910000019999991191001911999999119999991191001911999991019999991
ddddddddddddddddddddd655551ffffff165666655666666666e661ffff144441910000019111110191001911911111019111191199119911911119101191110
ddddddddddddddddddddd655551ffffff157566575566666666661ffff1444441910000019999100191001911910000019100191191991911999991000191000
ddddddddddddddddddddd655551ffffff15556655556666666661ffff14444441910000019111000191001911910000019100191191111911911110000191000
ddddddddddddddddddddd655551ffffff1656666556666666666611f144444441911111019111110019119101911111019111191191001911910000000191000
ddddddddddddddddddddd655551ffffff16666666666666666666661444444441999999101999991001991001999999119999991191001911910000000191000
ddddddddddddddddddddd655551fffff166666666666666666666614444444440111111000111110000110000111111001111110010000100100000000010000
1dddddddddddddddddddd655551fff55166effe66665555566666144444444460111100000011000000110000011110000111100001001000011110000111100
f11dddddddddddddddddd655551fffff166eeee66666666666661444444444651999910000199100001991000199991001999910019119100199991001999910
fff1d11111ddddddddddd655551ffff51666ee6666656666666d1644444446551911191001911910000191000011191000111910019119100191110001911100
ffff1aaaaa1dddddddddd655551fff5ff11666666666556666dd1d66444465551910119101911910000191000011191000111910019119100191110001911100
fff1aaa9aaa1ddddddddd655551ffffffff11111666666566ddd1ddd644655551910119101911910000191000199991001999910019999100199991001999910
ff1aa9aaaaaa1dddddddd655551fffffffffffff1d666666666d1dddd66555551911191001911910001191000191110001111910001119100011191001911910
f1aaaaaaaa9aa1ddddddd655551fffffffffffff1dd6666666661ddddd6555551999910000199100019999100199991001999910000019100199991001999910
19777aaaaaaaaa1dddddd655551ffffffffffff16666666616661ddddd6555550111100000011000001111000011110000111100000001000011110000111100
19999777aaaaaaa1ddddd655551fffffffffff166666666166661ddddd6555550011110000111100001111000000000000000000000000000000000000000000
19a99999777777771dddd655551ffffffffffff11666666611161ddddd6555550199991001999910019999100000000000000000000000000000000000000000
19999a99999999991dddd655551ffffffffffffff1d6666666661ddddd6555550011191001911910019119100000000000000000000000000000000000000000
199a99999999a99911ddd65551fffffffffffffff1d6d66666661ddddd6555550000191001911910019119100000000000000000000000000000000000000000
f1999999a99999a91f1dd6551fffffffffffffffff1d66d666661ddddd6555550000191001999910019999100000000000000000000000000000000000000000
ff111999999999991ff11651fffffffffffffffffff1ddd666661ddddd6555550000191001911910001119100000000000000000000000000000000000000000
fffff111999999991ffff11fffffffffffffffffffff1d6d6d661ddddd6555550000191001999910000019100000000000000000000000000000000000000000
ffffffff11111111ffffffffffffffffffffffffff11dddddddd1ddddd6555550000010000111100000001000000000000000000000000000000000000000000
fffffffffffffffffffffffffffffffffffffffff1dd6dddd1111ddddd6555550000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffff166666dd1fff1ddddd6555550000000000000000000000000000000000000000000000000000000000000000
fffffffffffffffffffffffffffffffffffffffff16666d1ffff1ddddd6555550000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffff11111fffff1ddddd6555550000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffff1ddddd6555550000000000000000000000000000000000000000000000000000000000000000
f7f7ffffffffffffffffffffffffffffffffffffffffffffffff1ddddd6555550000000000000000000000000000000000000000000000000000000000000000
7f7f7f7f7fffffffffffffffffffffffffffffffffffffffffff1ddddd6555550000000000000000000000000000000000000000000000000000000000000000
7777f7f7f7ffffffffffffffffffffffffffffffffffffffffff1ddddd6555550000000000000000000000000000000000000000000000000000000000000000
__label__
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666111166666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
666666666666661ee166666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
666666666666111ee111666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
6666666666661ff77dd1666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
6666666666111ff77dd1116666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
6666666666188777777cc16666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
6666666666188777777cc16666666661dddddddd11111111111111111111111111111111111111111111111111111111111111111ddddddddddddddddddddddd
66666666661119977bb1116666666661dddddddd1111111111111111111111dddddddddddddd1144444411111111111111d1d1111ddddddddddddddddddddddd
66666666666619977bb1666666666661dddddddd1441111111112112121211dddddddddddddddd144441511111111111111dddd11ddddddddddddddddddddddd
666666666666111aa111666666666661dddddddd1444111111121221212121ddddddddddddddddd1141551121212121111dddddd1ddddddddddddddddddddddd
666666666666661aa166666666666661dddddddd1444441111212122222211ddddddddddddddddddd15551212121212111dddddd1ddddddddddddddddddddddd
66666666666666111166666666666661dddddddd1444444111121222222221ddddddddddddddddddd15551112222221211dddddd1ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1444444441212222222221ddddddddddddddddddd15551122222222121dddddd1ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1444444444112222f2f2f1ddddddddddddddddddd15551222222222221dddddd1ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1664444444441f2f2f2f21ddddddddddddddddddd15551222222222221dddddd1ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1dd6444444444112f2f2f1ddddddddddddddddddd15551222222222221dddddd1ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1ddd664444444441ffff21ddddddddddddddddddd15551222222222221dddddd1ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1ddddd644444444411fff1ddddddddddddddddddd1555122222222222211dddd1ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1dddddd664444444441ff1ddddddddddddddddddd15551222222222222221ddd1ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1dddddddd6444444444111ddddddddddddddddddd1555122222222222222211d1ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1ddddddddd664444444441ddddddddddddddddddd155512222222222222222211ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1ddddddddddd644444444411ddddddddddddddddd155512222222222222222221ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1dddddddddddd664444444441dddddddddddddddd155512222222222222222221ddddddddddddddddddddddd
66666666661111111111166666666661dddddddd1dddddddddddddd644444444411dddddddddddddd155512222222222222222221ddddddddddddddddddddddd
66666666617777777777716666666661dddddddd1ddddddddddddddd66444444651dddddddddddddd155512f2f2f2222222222221ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd1ddddddddddddddddd644446551dddddddddddddd15551f2f2f2f222222222221ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd1dddddddddddddddddd66465551dddddddddddddd155512fffff2f22222222221ddddddddddddddddddddddd
66666666617711777711771666666661dddddddd1dddddddddddddddddddd655551ddddddddd1111d15551fff1111222222222221ddddddddddddddddddddddd
66666666617711777711771666666661dddddddd1dddddddddddddddddddd65555111dddddd16666115551ff166661f2222222221ddddddddddddddddddddddd
66666666617711777711771666666661dddddddd1dddddddddddddddddddd655551ff1dddd166666615551f16655661f222222221ddddddddddddddddddddddd
66666666617711777711771666666661dddddddd1dddddddddddddddddddd655551fff11d1666666661551f665555612f22222221ddddddddddddddddddddddd
66666666617711777711771666666661dddddddd1dddddddddddddddddddd655551fffff116666666615511655555661222222221ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd1dddddddddddddddddddd655551ffffff16666666d1551665555ee61ff2222221ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd1dddddddddddddddddddd655551ffffff1666666dd1551655555ee61f2f222221ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd1dddddddddddddddddddd655551ffffff1666666ddd11165555eee61ff2f22221ddddddddddddddddddddddd
66666666661111177777771666666661dddddddd1dddddddddddddddddddd655551ffffff166666dd6666165555eee61ff2f22221ddddddddddddddddddddddd
66666666666666611111116666666661dddddddd1dddddddddddddddddddd655551fffffff1666666666666655eeee61fff2f2211ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1dddddddddddddddddddd655551ffffffff166666666666665eee661ffff22141ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1dddddddddddddddddddd655551ffffffff16666666666666eeee61ffff2f1441ddddddddddddddddddddddd
66666666666666111166666666666661dddddddd1dddddddddddddddddddd655551fffffff1666666666666666eee61fff2f14441ddddddddddddddddddddddd
66666666666666177166666666666661dddddddd1dddddddddddddddddddd655551ffffff165666655666666666e661ffff144441ddddddddddddddddddddddd
66666666666666177166666666666661dddddddd1dddddddddddddddddddd655551ffffff157566575566666666661ffff1444441ddddddddddddddddddddddd
66666666666666177166666666666661dddddddd1dddddddddddddddddddd655551ffffff15556655556666666661ffff14444441ddddddddddddddddddddddd
66666666666666177166666666666661dddddddd1dddddddddddddddddddd655551ffffff1656666556666666666611f144444441ddddddddddddddddddddddd
66666666666666111166666666666661dddddddd1dddddddddddddddddddd655551ffffff16666666666666666666661444444441ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1dddddddddddddddddddd655551fffff166666666666666666666614444444441ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1dddddddddddddddddddd655551fff55166effe66665555566666144444444461ddddddddddddddddddddddd
66666666661111111111166666666661dddddddd111dddddddddddddddddd655551fffff166eeee66666666666661444444444651ddddddddddddddddddddddd
66666666617777777777716666666661dddddddd1ff1d11111ddddddddddd655551ffff51666ee6666656666666d1644444446551ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd1fff1aaaaa1dddddddddd655551fff5ff11666666666556666dd1d66444465551ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd1ff1aaa9aaa1ddddddddd655551ffffffff11111666666566ddd1ddd644655551ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd1f1aa9aaaaaa1dddddddd655551fffffffffffff1d666666666d1dddd66555551ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd11aaaaaaaa9aa1ddddddd655551fffffffffffff1dd6666666661ddddd6555551ddddddddddddddddddddddd
66666666617711111111771666666661dddddddd19777aaaaaaaaa1dddddd655551ffffffffffff16666666616661ddddd6555551ddddddddddddddddddddddd
66666666617711111111771666666661dddddddd19999777aaaaaaa1ddddd655551fffffffffff166666666166661ddddd6555551ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd19a99999777777771dddd655551ffffffffffff11666666611161ddddd6555551ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd19999a99999999991dddd655551ffffffffffffff1d6666666661ddddd6555551ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd199a99999999a99911ddd65551fffffffffffffff1d6d66666661ddddd6555551ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd11999999a99999a91f1dd6551fffffffffffffffff1d66d666661ddddd6555551ddddddddddddddddddddddd
66666666617777777777771666666661dddddddd1f111999999999991ff11651fffffffffffffffffff1ddd666661ddddd6555551ddddddddddddddddddddddd
66666666661111111111116666666661dddddddd1ffff111999999991ffff11fffffffffffffffffffff1d6d6d661ddddd6555551ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1fffffff11111111ffffffffffffffffffffffffff11dddddddd1ddddd6555551ddddddddddddddddddddddd
66666666666666666666666666666661dddddddd1ffffffffffffffffffffffffffffffffffffffff1dd6dddd1111ddddd6555551ddddddddddddddddddddddd
66666666661166666666116666666661dddddddd1fffffffffffffffffffffffffffffffffffffff166666dd1fff1ddddd6555551ddddddddddddddddddddddd
66666666617716666661771666666661dddddddd1ffffffffffffffffffffffffffffffffffffffff16666d1ffff1ddddd6555551ddddddddddddddddddddddd
66666666617716666661771666666661dddddddd1fffffffffffffffffffffffffffffffffffffffff11111fffff1ddddd6555551ddddddddddddddddddddddd
66666666617716666661771666666661dddddddd1fffffffffffffffffffffffffffffffffffffffffffffffffff1ddddd6555551ddddddddddddddddddddddd
66666666617716666661771666666661dddddddd17f7ffffffffffffffffffffffffffffffffffffffffffffffff1ddddd6555551ddddddddddddddddddddddd
66666666617716666661771666666661dddddddd1f7f7f7f7fffffffffffffffffffffffffffffffffffffffffff1ddddd6555551ddddddddddddddddddddddd
66666666617716666661771666666661dddddddd1777f7f7f7ffffffffffffffffffffffffffffffffffffffffff1ddddd6555551ddddddddddddddddddddddd
66666666617716666661771666666661dddddddd11111111111111111111111111111111111111111111111111111111111111111ddddddddddddddddddddddd
66666666617771111117771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666661111111111116666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddd66d6d6d666d666dd66d666ddddd666d666dd66d6d6d666d666d666dd66d666dddddddddddddddddddddddd
66666666661166666666116666666661ddddddddd611d6d6d611d611d611d611ddddd616d616d611d6d6d161d161d611d611d161dddddddddddddddddddddddd
66666666617716666661771666666661ddddddddd6ddd666d66dd66dd666d66dddddd666d661d6ddd666dd6ddd6dd66dd6dddd6ddddddddddddddddddddddddd
66666666617716666661771666666661ddddddddd6ddd616d61dd61dd116d61dddddd616d616d6ddd616dd6ddd6dd61dd6dddd6ddddddddddddddddddddddddd
66666666617716666661771666666661ddddddddd166d6d6d666d666d661d666ddddd6d6d6d6d166d6d6d666dd6dd666d166dd6ddddddddddddddddddddddddd
66666666617711111111771666666661dddddddddd11d1d1d111d111d11dd111ddddd1d1d1d1dd11d1d1d111dd1dd111dd11dd1ddddddddddddddddddddddddd
66666666617777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617711111111771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617716666661771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617716666661771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617716666661771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666661166666666116666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661ddddddddd666d6d6ddddd666dd66d666d666d666d666dd66ddddd666d666d666d666d666d666dddddddddddddddddddd
66666666661111111666666666666661ddddddddd616d6d6ddddd616d616d616d611d616d161d616ddddd611d616d611d161d616d611dddddddddddddddddddd
66666666617777777166666666666661ddddddddd661d666ddddd661d6d6d661d66dd661dd6dd6d6ddddd66dd661d66ddd6dd661d66ddddddddddddddddddddd
66666666617777777166666666666661ddddddddd616d116ddddd616d6d6d616d61dd616dd6dd6d6ddddd61dd616d61ddd6dd616d61ddddddddddddddddddddd
66666666617777777166666666666661ddddddddd666d666ddddd6d6d661d666d666d6d6dd6dd661ddddd6ddd6d6d666d666d6d6d666dddddddddddddddddddd
66666666617777777166666666666661ddddddddd111d111ddddd1d1d11dd111d111d1d1dd1dd11dddddd1ddd1d1d111d111d1d1d111dddddddddddddddddddd
66666666617777777166666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617777777166666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617711777166666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617711777711116666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666617777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666661777777777771666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666111111111116666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
66666666666666666666666666666661dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__map__
88888898bebebebebebebebebebebebe0000000000000000000000000000000062626262626262626262626262626262494a00006b6c00006b6c0000494a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88acad98bebebebebebebebebebebebe0000000000000000000000000000000062626262626262626262626262626262595a00007b7c00007b7c0000595a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88bcbd98be8081828384858687bebebe00000000000000000000000000000000626262626262626262626262626262620000696a00004b4c0000494a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888898be9091929394959697bebebe00000000000000000000000000000000626262626262626262626262626262620000797a00005b5c0000595a004b4c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88aaab98bea0a1a2a3a4a5a6a7bebebe0000000000000000000000000000000062626262626262626262626262626262696a000000000000696a0000005b5c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88babb98beb0b1b2b3b4b5b6b7bebebe0000000000000000000000000000000062626262626262626262626262626262797a6b6c004b4c00797a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88aeaf98bec0c1c2c3c4c5c6c7bebebe000000000000000000000000000000006262626262626262626262626262626200007b7c005b5c000000494a0000494a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88a8a998bed0d1d2d3d4d5d6d7bebebe000000000000000000000000000000006262626262626262626262626262626200000000000000000000595a0000595a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88b8b998bee0e1e2e3e4e5e6e7bebebe0000000000000000000000000000000062626262626262626262626262626262494a0000494a00696a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888d8e98bef0f1f2f3f4f5f6f7bebebe0000000000000000000000000000000062626262626262626262626262626262595a0000595a00797a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
889d9e98bebebebebebebebebebebebe000000000000000000000000000000006262626262626262626262626262626200006b6c000000000000494a0000494a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888b8c98bebebebebebebebebebebebe000000000000000000000000000000006262626262626262626262626262626200007b7c000000000000595a0000595a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
889b9c98bebebebebebebebebebebebe0000000000000000000000000000000062626262626262626262626262626262696a0000696a0000494a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88898a98bebebebebebebebebebebebe0000000000000000000000000000000062626262626262626262626262626262797a0000797a0000595a006b6c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88999a98bebebebebebebebebebebebe00000000000000000000000000000000626262626262626262626262626262620000494a000000000000007b7c00494a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888898bebebebebebebebebebebebe00000000000000000000000000000000626262626262626262626262626262620000595a004b4c00000000000000595a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000626262626262626262626262626262626b6c0000005b5c00494a0000696a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000727272727272727272727272727272727b7c000000000000595a0000797a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000494a0000494a0000000000006b6c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000595a0000595a0000000000007b7c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006b6c00006b6c0000696a0000494a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007b7c00007b7c0000797a0000595a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000494a00004b4c00006b6c0000696a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000595a00005b5c00007b7c0000797a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006b6c0000696a0000494a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007b7c0000797a0000595a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000494a0000494a0000000000006b6c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000595a0000595a004b4c0000007b7c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000494a000000000000005b5c00494a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000595a00000000000000000000595a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000264502d4503145032450324502d4502045000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000e5500d5500c5500b55009550075500555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000b5500b5500c5500d5500f550155500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800000a3500a3500b3500d35011350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000253502535023350223501f3501c3501a3501835015350123500e350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e000019350193501e35022350193501e350223501e3502235019350203501b3500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
990300003f65131651276521c651166520d6510465100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0020000018e5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 46424344

