require("libs/luaes")

local frame = 0
local FRAME_SKIP = 30
local index  = 0

function _init()
end

function _update(dt)
    frame = frame + 1
    if frame < FRAME_SKIP then return end
    frame = 0

    index = index + 1

    if index > 32 then
        index = 0
    end
end

function _draw()
    print("Text", 10, 10, 10, 2)
    rect(10, 30, 30, 20, 8, 2)
    rectfill(10, 60, 30, 20, index, 10)
    line(60, 10, 70, 30, 10, 2)
    circ(100, 30, 10, 11, 1)
    circfill(100, 60, 10, 12, 2)
end