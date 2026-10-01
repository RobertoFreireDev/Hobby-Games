ScoreDisplayState = {}
ScoreDisplayState.__index = ScoreDisplayState

function ScoreDisplayState:new(game)
    local state = { game = game }
    setmetatable(state, self)
    return state
end

function ScoreDisplayState:enter(isHighestScore)
    self.game.isHighestScore = isHighestScore
    self.game.gameOverTimer = 2
end

function ScoreDisplayState:update(dt)
    self.game.gameOverTimer = self.game.gameOverTimer - dt
    if self.game.gameOverTimer <= 0 then
        self.game.stateManager:switchState("gameover")
    end
end

function ScoreDisplayState:draw()
    if self.game.isHighestScore then
        love.graphics.setColor(1, 1, 0)
        self.game:printCenter("New Highest Score: " .. self.game.score)
    else
        love.graphics.setColor(1, 1, 1)
        self.game:printCenter("Score: " .. self.game.score)
    end
end