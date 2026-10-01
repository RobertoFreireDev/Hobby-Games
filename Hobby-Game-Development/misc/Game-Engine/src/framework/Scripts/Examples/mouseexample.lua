local mouseexample={
    title = "Mouse example"
}

function mouseexample:init()

end

function mouseexample:update() 

end

function mouseexample:draw()

end

return mouseexample

--[[
    🖱️ Input Functions

    | Function                        | Lua Alias      |
    | ------------------------------- | -------------- |
    | `GetMousePos()`                 | `_mousepos`    |
    | `MouseButtonPressed(int i)`     | `_mouseclick`  |
    | `MouseButtonJustPressed(int i)` | `_mouseclickp` |
    | `MouseButtonReleased(int i)`    | `_mouseclickr` |
    | `Scroll(int i)`                 | `_mousescroll` |
    | `UpdateCursor(int i)`           | `_mousecursor` |
    | `ShowHideMouse(bool show)`      | `_mouseshow`  |
]]