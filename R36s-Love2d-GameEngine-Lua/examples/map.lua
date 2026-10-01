require("libs/luaes")

local imageIndex = 1
local mapindex = 2
local mapstartpos = { x = 1, y = 1}
local mapdrawqty = { w = 2, h = 1 }
local mapdrawdestinationpos = { x= 1, y = 8 }

function _init()
    for y = 1, 8 do
        for x = 1, 8 do
            local color = ((x + y) % 16) + 1
            spixel(imageIndex, x, y, color)
        end
    end

    for y = 1, 8 do
        for x = 1, 8 do
            local color = ((x * y) % 16) + 1
            spixel(imageIndex, x + 8, y, color)
        end
    end
    mset(mapindex, 1, 1, 1, 1)
    mset(mapindex, 2, 1, 1, 2)
end

function _update(dt)
    if btnp(4) then save() end
end

function _draw()
    map(mapindex, mapstartpos.x, mapstartpos.y, mapdrawdestinationpos.x, mapdrawdestinationpos.y, mapdrawqty.w, mapdrawqty.h)
    map(mapindex, 1, 1, 0, 0)
    print("FPS: " ..stat(1), 120, 110, 4)
end