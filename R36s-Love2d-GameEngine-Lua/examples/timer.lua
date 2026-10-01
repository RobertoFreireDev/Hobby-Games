require("libs/luaes")

local timeidx = 1

function _init()
    
end

function _update(dt)
    if btnp(0) then
        timeidx = timeidx - 1
    end

    if btnp(1) then
        timeidx = timeidx + 1
    end

    timeidx = mid(1,timeidx,64)

    if btnp(3) then
        timer:create(timeidx)
    end

    if btnp(4) then
        timer:pause(timeidx)
    end

    if btnp(5) then
        timer:resume(timeidx)
    end
end

function _draw()
    print("time:" ..timeidx .. " " .. string.format("%.2f", timer:get(timeidx)), 10, 10, 4)
end