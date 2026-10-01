pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- metrodvania

function _init()
		change_state(game)
end

function _update()
		state:update()
end

function _draw()
		cls(7)
		state:draw()
end
-->8
-- states
function change_state(st)
		state=st
		state:init()
end

intro={}
function intro:init()
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
end
function game:update()
end
function game:draw()
		map()
end
-->8
-- entities	
-->8
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
-->8
-- systems
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
