GameOverState = {}
GameOverState.__index = GameOverState

function GameOverState:new(game)
    local state = { game = game }
    setmetatable(state, self)
    return state
end

function GameOverState:draw()
    love.graphics.setColor(1, 0, 0)
    self.game:printCenter("Game Over\nPress Start to Restart")
end

function GameOverState:keypressed(key)
    if key == controls.start then
        self.game.stateManager:switchState("playing")
    end
end