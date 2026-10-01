local game = {
    scoreToRemoveGates = 500,
    highScore = 0
}

function game:resetGame()
    self.snake = {
        {x = 10, y = 10, l = 0},
        {x = 9, y = 10, l = 0},
        {x = 8, y = 10, l = 0},
    }
    self.pause = false
    self.direction = "right"
    self.nextDirection = "right"
    self.gridSize = 20
    self.apple = {}
    self.gate1 = {x = 8, y = 6}
    self.gate2 = {x = 24, y = 18}
    self.currentLevel = 0
    self.box = {}
    self.box.x = 0
    self.box.y = 1
    self.box.w = love.graphics.getWidth() / self.gridSize
    self.box.h = love.graphics.getHeight() / self.gridSize
    self.score = 0
    self:spawnApple()
end

function game:spawnApple()
    local validPositions = {}
    for x = self.box.x, self.box.w - 1 do
        for y = self.box.y, self.box.h - 1 do
            local valid = true

            if ((self.gate1.x == x and self.gate1.y == y) or (self.gate2.x == x and self.gate2.y == y)) then
                valid = false
            end

            for _, segment in ipairs(self.snake) do
                if segment.x == x and segment.y == y then
                    valid = false
                    break
                end
            end
            if valid then
                table.insert(validPositions, {x = x, y = y})
            end
        end
    end

    if #validPositions == 0 then
        return
    end

    local randIndex = love.math.random(1, #validPositions)
    self.apple.x = validPositions[randIndex].x
    self.apple.y = validPositions[randIndex].y
end

function game:endGame()
    sounds.die:play()
    if self.score > self.highScore then
        self.highScore = self.score
        fileIO:save(self.highScore)        
        self.stateManager:switchState("scoredisplay", true)
    else
        self.stateManager:switchState("scoredisplay", false)
    end
end

function game:moveSnake()
    self.direction = self.nextDirection
    local head = self.snake[1]
    local newLevel = head.l

    if (self.currentLevel == 0 and self.gate2.x == head.x and self.gate2.y == head.y) then
        newLevel = 1
        self.currentLevel = 1
        self:spawnApple()
    elseif (self.currentLevel == 1 and self.gate1.x == head.x and self.gate1.y == head.y) then
        newLevel = 0
        self.currentLevel = 0
        self:spawnApple()
    end

    local newHead = {x = head.x, y = head.y, l = newLevel}

    if self.direction == "up" then
        newHead.y = newHead.y - 1
    elseif self.direction == "down" then
        newHead.y = newHead.y + 1
    elseif self.direction == "left" then
        newHead.x = newHead.x - 1
    elseif self.direction == "right" then
        newHead.x = newHead.x + 1
    end

    -- Check collision with walls
    if newHead.x < self.box.x or newHead.y < self.box.y or newHead.x >= self.box.w or newHead.y >= self.box.h then
        self:endGame()
        return
    end

    -- Check collision with self
    for _, segment in ipairs(self.snake) do
        if newHead.x == segment.x and newHead.y == segment.y and newHead.l == segment.l then
            self:endGame()
            return
        end
    end

    -- Move snake
    table.insert(self.snake, 1, newHead)

    -- Check if apple is eaten
    if newHead.x == self.apple.x and newHead.y == self.apple.y then
        self.score = self.score + 1        
        sounds.eat:play()
        self:spawnApple()
    else
        table.remove(self.snake) -- Remove tail
    end
end

function game:drawCircle(obj)
    love.graphics.circle("fill", obj.x * self.gridSize + self.gridSize / 2, obj.y * self.gridSize + self.gridSize / 2, self.gridSize / 2)
end

function game:drawSquare(obj)
    love.graphics.rectangle("fill", obj.x * self.gridSize, obj.y * self.gridSize, self.gridSize, self.gridSize)
end

function game:printCenter(text)
    love.graphics.printf(text, 0, (self.box.h * self.gridSize)/ 2 - 20, self.box.w * self.gridSize, "center")
end

function game:drawApple()
    if self.apple.x == nil or self.apple.y == nil then
        return
    end

    love.graphics.setColor(1, 0, 0)
    self:drawCircle(self.apple)
end

function game:drawSnake()
    love.graphics.setColor(0, 1, 0)
    for _, segment in ipairs(self.snake) do
        if (segment.l == self.currentLevel) then
            self:drawCircle(segment)
        end
    end
end

function game:drawGates()
    love.graphics.setColor(1, 1, 0)
    if self.currentLevel == 0 then
        self:drawSquare(self.gate2)
    elseif self.currentLevel == 1 then
        self:drawSquare(self.gate1)
    end
end

function game:drawHUD()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, self.box.w * self.gridSize, self.gridSize)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Score: " .. self.score, 10, 2)    
    love.graphics.print("High Score: " .. self.highScore, 400, 2)
    if self.pause then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("PAUSE", 280, 2)
    end
end

function game:load()
    self.stateManager = StateManager:new()
    self.stateManager:registerState("playing", PlayingState:new(self))
    self.stateManager:registerState("gameover", GameOverState:new(self))
    self.stateManager:registerState("scoredisplay", ScoreDisplayState:new(self))

    self.stateManager:switchState("playing")
end

function game:update(dt)
    self.stateManager:update(dt)
end

function game:draw()
    self.stateManager:draw()
end

function game:keypressed(key)
    self.stateManager:keypressed(key)
end

createGameScene = function(sceneManager)
    return {
        game = game,
        enter = function(self)            
            local content = fileIO:load()
            game.highScore = tonumber(content) or 0
            game:load()
        end,
        update = function(self, dt)
            game:update(dt)
        end,
        draw = function(self)
            game:draw()
        end,
        keypressed = function(self, key)
            game:keypressed(key)
        end
    }
end