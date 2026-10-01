-- Ball Class
Ball = {}
Ball.__index = Ball

function Ball:new(x, y, world, props)
    local ball = setmetatable({}, self)
    ball.body = love.physics.newBody(world, x, y, "dynamic")
    ball.shape = love.physics.newCircleShape(props.radius)
    ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1) -- Density = 1
    ball.fixture:setRestitution(props.restitution)
    ball.color = props.color
    ball.type = props.type
    ball.sprite = props.sprite
    ball.radius = props.radius
    ball.scale = props.scale
    ball.offSet = props.offSet
    ball.creationTime = love.timer.getTime()
    ball.fixture:setUserData(ball)
    return ball
end

function Ball:draw()
    if not self.body or self.body:isDestroyed() then
        return
    end
    self.sprite:draw(fruitsImage, self.body:getX(), self.body:getY(), self.body:getAngle(), self.scale, self.scale, self.offSet, self.offSet)
end

function Ball:update()
    if not self.body or self.body:isDestroyed() then
        return
    end

    if self.body and self.body:getY() <= scene.dashedLine.y1 and 
        self.creationTime + 3 < love.timer.getTime() then
        scene.gameover = true
    end
end

local grid = anim8.newGrid(16, 16, fruitsImage:getWidth(), fruitsImage:getHeight())

CherryProps = { sprite = anim8.newAnimation(grid(1, 1), 1), type = "Cherry", radius = 32, scale = 4, offSet = 8, restitution = 0.5, color = "#FF0000" }  -- Red color
StrawberryProps = { sprite = anim8.newAnimation(grid(2, 1), 1), type = "Strawberry", radius = 32, scale = 4, offSet = 8, restitution = 0.45, color = "#FF1493" }  -- Deep pink color
GrapeProps = { sprite = anim8.newAnimation(grid(3, 1), 1), type = "Grape", radius = 32, scale = 4, offSet = 8, restitution = 0.45, color = "#800080" }  -- Purple color
LemonProps = { sprite = anim8.newAnimation(grid(4, 1), 1), type = "Lemon", radius = 48, scale = 6, offSet = 8, restitution = 0.45, color = "#FFFF00" }  -- Yellow color
AppleProps =  { sprite = anim8.newAnimation(grid(5, 1), 1), type = "Apple", radius = 48, scale = 6, offSet = 8, restitution = 0.4, color = "#FF0000" }  -- Red color
OrangeProps = { sprite = anim8.newAnimation(grid(6, 1), 1), type = "Orange", radius = 48, scale = 6, offSet = 8, restitution = 0.4, color = "#FFA500" }  -- Orange color
MangoProps = { sprite = anim8.newAnimation(grid(7, 1), 1), type = "Mango", radius = 64, scale = 8, offSet = 8, restitution = 0.4, color = "#FFB000" }  -- Mango color
MeloaProps = { sprite = anim8.newAnimation(grid(8, 1), 1), type = "Meloa", radius = 64, scale = 8, offSet = 8, restitution = 0.4, color = "#32CD32" }  -- Green color
PineappleProps = { sprite = anim8.newAnimation(grid(9, 1), 1), type = "Pineapple", radius = 64, scale = 8, offSet = 8, restitution = 0.3, color = "#FFD700" }  -- Yellow color
WatermelonProps = { sprite = anim8.newAnimation(grid(10, 1), 1), type = "Watermelon", radius = 96, scale = 12, offSet = 8, restitution = 0.2, color = "#FF6347" }  -- Watermelon color (red)

Cherry = setmetatable({}, Ball)
Cherry.__index = Cherry

function Cherry:new(x, y, world)
    return Ball.new(self, x, y, world, CherryProps)
end

Strawberry = setmetatable({}, Ball)
Strawberry.__index = Strawberry

function Strawberry:new(x, y, world)
    return Ball.new(self, x, y, world, StrawberryProps)
end

Grape = setmetatable({}, Ball)
Grape.__index = Grape

function Grape:new(x, y, world)
    return Ball.new(self, x, y, world, GrapeProps)
end

Lemon = setmetatable({}, Ball)
Lemon.__index = Lemon

function Lemon:new(x, y, world)
    return Ball.new(self, x, y, world, LemonProps)
end

Apple = setmetatable({}, Ball)
Apple.__index = Apple

function Apple:new(x, y, world)
    return Ball.new(self, x, y, world, AppleProps)
end

Orange = setmetatable({}, Ball)
Orange.__index = Orange

function Orange:new(x, y, world)
    return Ball.new(self, x, y, world, OrangeProps)
end

Mango = setmetatable({}, Ball)
Mango.__index = Mango

function Mango:new(x, y, world)
    return Ball.new(self, x, y, world, MangoProps)
end

Meloa = setmetatable({}, Ball)
Meloa.__index = Meloa

function Meloa:new(x, y, world)
    return Ball.new(self, x, y, world, MeloaProps)
end

Pineapple = setmetatable({}, Ball)
Pineapple.__index = Pineapple

function Pineapple:new(x, y, world)
    return Ball.new(self, x, y, world, PineappleProps)
end

Watermelon = setmetatable({}, Ball)
Watermelon.__index = Watermelon

function Watermelon:new(x, y, world)
    return Ball.new(self, x, y, world, WatermelonProps)
end

fruits = {
    Cherry, Strawberry, Grape, Lemon, Apple, Orange, Mango, Meloa, Pineapple, Watermelon
}

fruitsProps = {
    CherryProps, StrawberryProps, GrapeProps, LemonProps, AppleProps, OrangeProps, MangoProps, MeloaProps, PineappleProps, WatermelonProps
}