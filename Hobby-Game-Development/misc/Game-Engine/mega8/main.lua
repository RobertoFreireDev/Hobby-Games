local left = 65
local right = 68

function _init()
end

function _update()
	if btnp(left) then    
		sfx(21)
		sfx(10)
    end
	
	if btnp(right) then
		sfx(12)
    end
end

function _draw()
	line(10,10,20,60,4)
end