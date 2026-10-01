function _init()
end

local x,y=0,0

function _update()
	if btn(5) then
        sfx(21)
		sfx(10)		
		pal(1)
	end
	if btn(0) then x = x - 1 end
	if btn(1) then x = x + 1 end
	if btn(2) then y = y - 1 end
	if btn(3) then y = y + 1 end
	cam(x,y)
end

function _draw()
	spr(1,50,20,1)
	print("test",0,0,1)
	print("test",0,8,2)
	print("test",0,16,3)
	print("test",0,24,4)
end