-- Player Class
Player = {}
Player.__index = Player

function Player:new(x, y)
    local player = setmetatable({}, self)
    player.x = x
    player.y = y
    player.lastSelectTime = love.timer.getTime()
    player.nextFruitIndex = self:selectRandomFruit()
    player.currentFruitIndex = self:selectRandomFruit()
    player.canDropFruit = false
    player.speed = 4
    return player
end

function Player:draw()
    local fruit = fruitsProps[self.nextFruitIndex]
    love.graphics.setHexColor("#A9A9A9");
    fruit.sprite:draw(fruitsImage, 32, 32, nil, fruit.scale/2, fruit.scale/2, fruit.offSet, fruit.offSet)
    love.graphics.setHexColor(scene.defaultColor);

    if self.canDropFruit then
        local fruit = fruitsProps[self.currentFruitIndex]
        fruit.sprite:draw(fruitsImage, self.x, self.y, nil, fruit.scale, fruit.scale, fruit.offSet, fruit.offSet)
    else
        love.graphics.circle("fill", self.x, self.y, 5) 
    end
end

function Player:update()
    self.canDropFruit = love.timer.getTime() - self.lastSelectTime >= 1
    local limit = fruitsProps[self.currentFruitIndex].radius

    if self.x < limit then
        self.x = limit
    end
    
    if self.x > 640 - limit then
        self.x = 640 - limit
    end

    if (love.keyboard.isDown(controls.left) or love.keyboard.isDown(controls.left_analog_left)) and self.x > limit then
        self.x = self.x - self.speed
    elseif (love.keyboard.isDown(controls.right) or love.keyboard.isDown(controls.left_analog_right)) and self.x < 640 - limit  then
        self.x = self.x + self.speed
    end
end

function Player:selectRandomFruit()
    return math.random(#fruits - 4)
end

function Player:keypressed(key)
    if key == controls.a and self.canDropFruit then
        table.insert(scene.balls, fruits[self.currentFruitIndex]:new(self.x, self.y, scene.world))
        self.currentFruitIndex = self.nextFruitIndex
        self.nextFruitIndex = self:selectRandomFruit()
        self.lastSelectTime = love.timer.getTime()
    end
end