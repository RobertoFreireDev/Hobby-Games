-- Platform Class
Platform = {}
Platform.__index = Platform

function Platform:new(x, y, width, height, world)
    local platform = setmetatable({}, self)
    platform.body = love.physics.newBody(world, x + width / 2, y + height / 2, "static")
    platform.shape = love.physics.newRectangleShape(width, height)
    platform.fixture = love.physics.newFixture(platform.body, platform.shape)
    platform.width = width
    platform.height = height
    return platform
end

function Platform:draw()
    local x, y = self.body:getPosition()
    love.graphics.rectangle("line", x - self.width / 2, y - self.height / 2, self.width, self.height)
end