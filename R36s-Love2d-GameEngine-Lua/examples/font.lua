require("libs/luaes")

local idx = 1
local limit = 6
local modeidx = 1
local modelimit = 4
function _init()
    font(idx)
end

function _update(dt)
    if btnp(1) and idx < limit  then
        idx = idx + 1
        font(idx)
    elseif btnp(0) and idx > 1 then
        idx = idx - 1
        font(idx)
    end

    if btnp(2) and modeidx < modelimit  then
        modeidx = modeidx + 1
    elseif btnp(3) and modeidx > 1 then
        modeidx = modeidx - 1
    end
end

local c = 1
local sc = 26

function printmode(t,x,y)
    if modeidx == 2 or modeidx == 4 then
        print(t,x+1,y,sc)
    end
    if modeidx == 3 or modeidx == 4 then
        print(t,x,y+1,sc)
    end
    if modeidx == 4 then
        print(t,x-1,y,sc)
        print(t,x,y-1,sc)
    end
    print(t,x,y,c)
end

function _draw()
    printmode("0123456789 {|}~", 0, 0)
    printmode("!\"#$%&'()*+,-./", 0, 20)
    printmode("ABCDEFGHIJKLMNO", 0, 40)
    printmode("PQRSTUVWXYZ", 0, 60)
    printmode("abcdefghijklmno", 0, 80)
    printmode("pqrstuvwxyz", 0, 100)
end