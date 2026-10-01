require("libs/luaes")

function _init()
end

function _update(dt)
    if btnp(4) then
        fset(1,5, 0, true)
        fset(1,5, 2, true)
    end

    if btnp(5) then
        fset(1,5, 0, false)
    end

    if btnp(1) then
        save()
    end
end

function _draw()
    print(tostring(fget(1, 5, 0) and "true" or "false"), 10, 10)
    print(tostring(fget(1, 5, 2) and "true" or "false"), 10, 20)
    print(fget(1,5), 10, 30)
end