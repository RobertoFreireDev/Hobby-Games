require("libs/luaes")

local imageIndex = 1
local t = 0

function _init()
    -- first 8x8 pattern
    for y = 1, 8 do
        for x = 1, 8 do
            local color = ((x + y) % 16) + 1
            spixel(imageIndex, x, y, color)
        end
    end

    -- second 8x8 pattern
    for y = 1, 8 do
        for x = 1, 8 do
            local color = ((x * y) % 16) + 1
            spixel(imageIndex, x + 8, y, color + 16)
        end
    end
end

function _update(dt)
    t = t + dt

    if btnp(4) or btnp(5) then
        save()
    end
end

function _draw()
    local sx = math.floor(1 + (math.sin(t * 2.0) * 0.5 + 0.5) * 3)
    local sy = math.floor(1 + (math.sin(t * 2.0 + math.pi * 0.5) * 0.5 + 0.5) * 3)
    sx = mid(1, sx, 4)
    sy = mid(1, sy, 4)

    fillsp(1, 1, 20, 10, 4, 2)
    fillsp(1, 1, 80, 10, 4, 2, 1, 1, 12, 6)
    spr(1, 1, 20, 40)
    spr(1, 1, 30, 40, 1, 2)
    spr(1, 2, 40, 40, 1, 2)
    spr(1, 1, 30, 50, 2, 1)
    spr(1, 2, 60, 40, 1, 2, true, false, sx, sy)
    spr(1, 1, 60, 80, 2, 1, false, true, sy, sx)
    spr(1, 1, 20, 48, 1, 1, true, false)
    spr(1, 1, 20, 56, 1, 1, false, true)
    spr(1, 1, 20, 70, 1, 1, false, false, 1, 1, 12, 2)
    spr(1, 1, 20, 80, 1, 1, false, false, 1, 1, 4, 8)
end