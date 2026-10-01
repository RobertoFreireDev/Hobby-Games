function love.graphics.setHexColor(hex)
    hex = hex:gsub("#", "")
    
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    
    love.graphics.setColor(r, g, b)
end

function love.graphics.dashedLine(x1, y1, x2, y2, dashLength)
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx * dx + dy * dy)
    local numDashes = math.floor(distance / dashLength)/2
    local dashX = dx / distance * dashLength
    local dashY = dy / distance * dashLength

    for i = 0, numDashes - 1 do
        local startX = x1 + dashX * i * 2
        local startY = y1 + dashY * i * 2
        local endX = startX + dashX
        local endY = startY + dashY
        love.graphics.line(startX, startY, endX, endY)
    end
end