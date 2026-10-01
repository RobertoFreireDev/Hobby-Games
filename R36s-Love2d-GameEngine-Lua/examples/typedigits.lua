require("libs/luaes")

local octets = {192, 168, 100, 86}
local selected = 1
local holdTimer = 0

local function clamp(v, a, b)
    return mid(a, v, b)
end

local function ipString()
    return tostring(octets[1]) .. "."
        .. tostring(octets[2]) .. "."
        .. tostring(octets[3]) .. "."
        .. tostring(octets[4])
end

function _init()
end

function _update(dt)
    holdTimer = holdTimer + dt

    -- move selected octet
    if btnp(0) then selected = clamp(selected - 1, 1, 4) end -- left
    if btnp(1) then selected = clamp(selected + 1, 1, 4) end -- right

    -- change value
    if btnp(2) then octets[selected] = clamp(octets[selected] + 1, 0, 255) end -- up
    if btnp(3) then octets[selected] = clamp(octets[selected] - 1, 0, 255) end -- down

    -- quick step
    if btnp(5) then octets[selected] = clamp(octets[selected] + 10, 0, 255) end -- A
    if btnp(4) then octets[selected] = clamp(octets[selected] - 10, 0, 255) end -- B
end

function _draw()
    local ip = ipString()

    print("Build IP with buttons", 10, 8, 7, 10)
    print("IP: " .. ip, 10, 22, 12, 10)

    print("Selected octet: " .. selected, 10, 36, 11, 10)
    print("Left/Right = choose octet", 10, 52, 14, 10)
    print("Up/Down = +1/-1", 10, 62, 14, 10)
    print("A/B = +10/-10", 10, 72, 14, 10)

    -- visual selector boxes
    local x = 10
    for i = 1, 4 do
        local txt = tostring(octets[i])
        local w = #txt * 6 + 4

        rect(x - 1, 89, w, 10, (i == selected) and 8 or 15, 10)
        print(txt, x + 1, 90, 1, 10)

        x = x + w + (i < 4 and 6 or 0)
        if i < 4 then print(".", x - 4, 90, 12, 10) end
    end
end
