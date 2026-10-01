pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- text to show on cartridge
function _init()
		cartdata("gamename_randomchars")
		load_game()
		change_state(game)	
end

function _update()--_update60()
		state:update()
end

function _draw()
		cls()
		state:draw()
		debug_draw()
end

-- states
function change_state(st)
		state=st
		state:init()
end

intro={}
function intro:init()
		--self
end

function intro:update()
end

function intro:draw()
end

menu={}
function menu:init()
end

function menu:update()
end

function menu:draw()
end

game={}
function game:init()
		add(obj,new_player(1,1,8,8,0))
		add(obj,new_enemy(2,2,16,16,0))
		add(obj,new_enemy(3,2,32,24,0))
		add(obj,new_enemy(4,2,32,32,0))
		add(obj,new_enemy(5,2,32,40,0))
		add(obj,new_enemy(6,2,24,48,0))
		add(obj,new_area(7,3,64,64,0))
		--add(obj,new_area(7,4,64,64,1))
end

function game:update()
		foreach(obj, function(o)
				if o.update ~= nil then
						o:update()
				end
		end)
end

function game:draw()
		sort_by_y(obj)
		-- draw in sorted order
		foreach(obj, function(o)								
				if o.b ~= nil then
						o.b:draw()
				end
		end)
end

--objects
obj={}

-- ecs
-- entities
function new_player(id,s,x,y,z)
		local o={id=id}		
		o.b=new_body(s,x,y,0,0,8,8,true,z)
		o.a=new_anim({1,16,17,18,19},5)
		
		function o:update()
			local s=self
			local b=s.b
			local dx,dy=0,0
			if btn(⬅️) then dx-=1 end	
			if btn(➡️) then dx+=1 end	
			if btn(⬆️) then dy-=1 end
			if btn(⬇️) then dy+=1 end
			
			foreach(obj, function(o)
					if o.id ~= s.id then
							if b:collides(dx,0,o.b) then
									dx=0	
							end
							if b:collides(0,dy,o.b) then
									dy=0							
							end
					end
			end)
			
			b.x+=dx
			b.y+=dy
			b.s=o.a:update()
		end
		
		return o
end

function new_enemy(id,s,x,y,z)
		local o={id=id}		
		o.b=new_body(s,x,y,1,1,6,6,true,z)
		
		return o
end

function new_area(id,s,x,y,z)
		local o={id=id}		
		o.b=new_body(s,x,y,0,0,8,8,false,z)
		
		return o
end

-- components
function new_body(s,x,y,x1,y1,w,h,sl,z)
		--sprite,x,y,box,solid,z index
		local o={
			s=s,x=x,y=y,sl=sl,z=z,
			box={x=x1,y=y1,w=w,h=h}
		}
		
		function o:collides(dx,dy,o2)		
				local b=self
				
				if o2.box==nil or not o2.sl or not b.sl then
						return
				end
				
				local o1x,o1y,o2x,o2y=
						b.x+b.box.x+dx,
						b.y+b.box.y+dy,
						o2.x+o2.box.x,
						o2.y+o2.box.y
		
		  return o1x < o2x + o2.box.w and
		         o1x + b.box.w > o2x and
		         o1y < o2y + o2.box.h and
		         o1y + b.box.h > o2y
		end
		
		function o:draw()
				local b=self
				spr(b.s,b.x,b.y)
		end
		
		return o
end

function new_anim(frames, delay, loop)
  local o={
    frames = frames,   -- list of sprite ids
    delay = delay,     -- ticks per frame
    timer = 0,
    index = 1,
    loop = loop == nil and true or loop, -- default true
    done = false
  }
  
  function o:update()
  		local s=self
  		if s.done then 
  				return s:getsprite()
  		end		  
		  s.timer += 1
		  if s.timer >= s.delay then
		    s.timer = 0
		    s.index += 1
		    if s.index > #s.frames then
		      if s.loop then
		        s.index = 1
		      else
		        s.index = #s.frames
		        s.done = true
		      end
		    end
		  end
		  
		  return s:getsprite()
  end
  
  function o:getsprite()
  		return self.frames[self.index]
  end
  
  return o
end

-- systems
function sort_by_y(t)
  local n = #t
  for i=1,n-1 do
    for j=1,n-i do
      if t[j].b.y > t[j+1].b.y then
        t[j], t[j+1] = t[j+1], t[j]
      end
    end
  end
end

function sort_by_z_then_y(t)
  local n = #t
  for i = 1, n - 1 do
    for j = 1, n - i do
      local a, b = t[j].b, t[j + 1].b
      -- compare by z first
      if a.z > b.z or (a.z == b.z and a.y > b.y) then
        t[j], t[j + 1] = t[j + 1], t[j]
      end
    end
  end
end

-- saves
function load_game()
		--dget(i) i -> 0 to 63.
end

function save_game()
		--dset(index,value)
end

-- debug
function debug_draw()
		print(stat(7).." fps",100,8,4)
		print(#obj,100,16,4)
end

-- menu options
-- menuitem(index, [label,] [callback] )
-- menuitem(index) to disable this option

-- buttons
--btn(❎) btnp(❎) ⬅️⬆️➡️⬇️ ❎ 🅾️

-- palette
-- pal({[0]=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},1)
-- second palette
-- pal({[0]=128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143},1)

-- functions
--foreach(obj, function(o)
--		o
--end)

--for i=1,#list do
--		i
--end

-- if else
-- if a==b then
--  ...
-- elseif c~=d then
--  ...
--end

-- ♪
-- music(number) number -1 to stop
-- sfx(number)
__gfx__
00000000aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa03333330b303313b055555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aaaaaaaa033333301b3b3b31050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa0335533003bb30b3050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa033553300313b3b0050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aaaaaaaa03333330b03b3b3b050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa033333303b33b3b3055555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa0000000003b3b330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaa0aaaaaaaa0aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaa0aaaaaaaa0aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaa0aaaaaaaa0aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaa0aaaaaaaa0aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaa0aaaaaaaa0aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaa0aaaaaaaa0aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaa0aaaaaaaa0aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaa0000000000aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
