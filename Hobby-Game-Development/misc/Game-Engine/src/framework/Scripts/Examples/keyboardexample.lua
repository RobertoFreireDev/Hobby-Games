local keyboardexample={
    title = "keyboard example"
}

local text = ""

function keyboardexample:init()
end

function keyboardexample:update()
    if _btnp(_keys.Back) then
        if #text > 0 then
            text = text:sub(1, -2)
        end
        return
    end    
    
    for char, keycode in pairs(_keyboard) do
        if _btnp(keycode) then
            text = text ..char
            return
        end
    end
end

function keyboardexample:draw()
    _print("Text: " .. string.upper(text), 20, 20, 1)
end

return keyboardexample