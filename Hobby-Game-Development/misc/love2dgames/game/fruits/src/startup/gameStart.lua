function gameStart()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setMode(640, 480, { resizable = false })
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    pixelFont = love.graphics.newFont("fonts/slkscreb.ttf", 16)
    love.graphics.setFont(pixelFont)
    
    require "src/utils/controls"
    require "src/utils/graphics"

    require "src/utils/scenemanager"
    sceneManager = SceneManager:new()

    anim8 = require "libraries/anim8"
    fruitsImage = love.graphics.newImage('sprites/fruitsSprite.png')

    require "src/scenes/gamescene"

    require "src/objects/platform"
    require "src/objects/player"
    require "src/objects/ball"

    sounds = {}
    sounds.joinFruits = love.audio.newSource("sounds/coin.wav", "static")

    sceneManager:registerScene("game", createGameScene(sceneManager))
    sceneManager:switchTo("game")
end
