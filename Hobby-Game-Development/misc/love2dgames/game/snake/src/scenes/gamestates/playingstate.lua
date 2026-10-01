PlayingState = {}
PlayingState.__index = PlayingState

function PlayingState:new(game)
    local state = { game = game }
    setmetatable(state, self)
    return state
end

function PlayingState:enter()
    self.game:resetGame()
end

function PlayingState:update(dt)
    local timeToUpdate = 0.2

    if self.game.pause then
        return
    end

    if self.game.score > self.game.scoreToRemoveGates then
        -- place outside of game area
        self.game.gate1 = {x = 100, y = 100}
        self.game.gate2 = {x = 100, y = 100}
    end

    if (love.keyboard.isDown(controls.up) or love.keyboard.isDown(controls.left_analog_up)) and self.game.direction ~= "down" then
        self.game.nextDirection = "up"
    elseif (love.keyboard.isDown(controls.down) or love.keyboard.isDown(controls.left_analog_down)) and self.game.direction ~= "up" then
        self.game.nextDirection = "down"
    elseif (love.keyboard.isDown(controls.left) or love.keyboard.isDown(controls.left_analog_left)) and self.game.direction ~= "right" then
        self.game.nextDirection = "left"
    elseif (love.keyboard.isDown(controls.right) or love.keyboard.isDown(controls.left_analog_right)) and self.game.direction ~= "left" then
        self.game.nextDirection = "right"
    end

    if love.keyboard.isDown(controls.b) then
        timeToUpdate = 0.1
    end

    if love.timer.getTime() % timeToUpdate < dt then
        self.game:moveSnake()
    end
end

function PlayingState:draw()
    love.graphics.setShader(crtShader)
    self.game:drawApple()
    self.game:drawSnake()        
    self.game:drawGates()
    love.graphics.setShader()
    self.game:drawHUD()
end

function PlayingState:keypressed(key)
    if key == controls.start then
        self.game.pause = not self.game.pause
        sounds.pause:play()
    end
end