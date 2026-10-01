require("libs/luaes")

function _init()
end

function _update(dt)
end

function _draw()
    local m = mouse()
    print(string.format("Mouse: x=%d y=%d",m.x, m.y), 10, 0, 4)
    local info = stat(10)
    local infoStr = string.format("w=%d h=%d sc=%d ox=%d oy=%d",info.x, info.y, info.scale, info.ofx, info.ofy)
    print(infoStr, 10, 30, 5)
    print(stat(2), 10, 40, 5)
    print(stat(3), 10, 50, 5)
    print(stat(4), 10, 60, 5)
    print(stat(5), 10, 70, 5)
    print(stat(6), 10, 80, 5)
    local local_time = stat(7)
    print(string.format("Local time: %02d:%02d:%02d", local_time.hour, local_time.min, local_time.sec), 10, 90, 5)
    local utc_time = stat(8)
    print(string.format("UTC time: %02d:%02d:%02d", utc_time.hour, utc_time.min, utc_time.sec), 10, 100, 5)
end