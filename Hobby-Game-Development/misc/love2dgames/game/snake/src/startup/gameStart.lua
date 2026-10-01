function gameStart()
    love.window.setMode(640, 480, { resizable = false })
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    pixelFont = love.graphics.newFont("fonts/slkscreb.ttf", 16)
    love.graphics.setFont(pixelFont)
    
    require "src/utils/controls"    
    require "src/utils/statemanager"
    require "src/scenes/gamestates/scoredisplaystate"
    require "src/scenes/gamestates/playingstate"
    require "src/scenes/gamestates/gameoverstate"

    require "src/utils/scenemanager"
    sceneManager = SceneManager:new()
    
    require "src/utils/file"    
    fileIO = FileIO:new("gamestate.lua")

    introImage = love.graphics.newImage('sprites/intro.png')
    menuImage = love.graphics.newImage('sprites/menu.png')

    crtShader = love.graphics.newShader("shaders/crt_shader.glsl")
    
    sounds = {}
    sounds.eat = love.audio.newSource("sounds/coin.wav", "static")
    sounds.die = love.audio.newSource("sounds/hurt.wav", "static")
    sounds.pause = love.audio.newSource("sounds/pause.wav", "static")

    require "src/scenes/introscene"
    require "src/scenes/menuscene"
    require "src/scenes/gamescene"
    
    sceneManager:registerScene("intro", createIntroScene(sceneManager))
    sceneManager:registerScene("menu", createMenuScene(sceneManager))
    sceneManager:registerScene("game", createGameScene(sceneManager))
    sceneManager:switchTo("intro")
end
