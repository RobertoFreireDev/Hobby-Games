-- alt + l
-- compact all files in same level as file main.lua to zip file and rename to .love extension
function love.load()
    require 'src/startup/gameStart'
    gameStart()
end

function love.update(dt)
    sceneManager:update(dt)
end

function love.draw()
    sceneManager:draw()
end

function love.keypressed(key)
    sceneManager:keypressed(key)
end

function love.keyreleased(key)
    sceneManager:keyreleased(key)
end