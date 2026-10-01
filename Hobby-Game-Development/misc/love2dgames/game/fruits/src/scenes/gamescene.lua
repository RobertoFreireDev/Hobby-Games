scene = {}

function scene:load()    
    self.platforms = {}
    self.player = nil
    self.balls = {}
    self.world = nil
    self.score = 0
    self.defaultColor = "#FFFFFF"
    self.dashedLine = {
        x1 = 20, 
        y1 = 120, 
        x2 = 620, 
        y2 = 120, 
        dashLength = 10
    }
    self.gameover = false
    self.toRemove = {}

    love.physics.setMeter(64) -- Set 1 meter = 64 pixels
    self.world = love.physics.newWorld(0, 500, true)
   
    local platformData = {
        {x = 0, y = 470, width = 640, height = 10},
        {x = 0, y = 0, width = 10, height = 470},
        {x = 630, y = 0, width = 10, height = 470}
    }
    for _, p in ipairs(platformData) do
        table.insert(self.platforms, Platform:new(p.x, p.y, p.width, p.height, self.world))
    end

    self.player = Player:new(200, 60, self.world)

    self.world:setCallbacks(
        function(a, b, coll)
            local objA = a:getUserData()
            local objB = b:getUserData()

            if objA ~= nil and objB ~= nil and objA.type == objB.type then
                local ballToRemoveA, ballToRemoveB
                for i, v in ipairs(scene.balls) do
                    if v == objA then
                        ballToRemoveA = v
                    elseif v == objB then 
                        ballToRemoveB = v
                    end
                end
                table.insert(scene.toRemove,{ a = ballToRemoveA, b = ballToRemoveB })
            end
        end, nil, nil, nil
    )
end

function scene:destroyFruits()
    local x, y = 0, 0
    for i, ballPair in ipairs(self.toRemove) do
        if ballPair.a.body == nil or ballPair.b.body == nil or ballPair.a.body:isDestroyed() or ballPair.b.body:isDestroyed() then
            table.remove(self.toRemove, i)
            return
        end

        x = ballPair.a.body:getX()
        y = ballPair.a.body:getY()
        
        local fruitIndex = 0
        for pi, prop in ipairs(fruitsProps) do
            if prop.type == ballPair.a.type then
                fruitIndex = pi
            end
        end

        if ballPair.a.body and not ballPair.a.body:isDestroyed() then ballPair.a.body:destroy() end
        if ballPair.b.body and not ballPair.b.body:isDestroyed() then ballPair.b.body:destroy() end
        for j, ball in ipairs(self.balls) do
            if ball == ballPair.a then
                table.remove(self.balls, j)
            end
        end
        for j, ball in ipairs(self.balls) do
            if ball == ballPair.b then
                table.remove(self.balls, j)
            end
        end
        table.remove(self.toRemove, i)

        if fruitIndex+1 <= #fruits then
            sounds.joinFruits:play()
            table.insert(self.balls, fruits[fruitIndex+1]:new(x, y, self.world))   
            self.score = self.score + fruitIndex+1
        end
    end
end

function scene:update(dt)
    self:destroyFruits()
    for i, ball in ipairs(self.balls) do
        ball:update()
    end
    self.player:update()
    self.world:update(dt)
end

function scene:draw()
    for _, platform in ipairs(self.platforms) do
        platform:draw()
    end
    for _, ball in ipairs(self.balls) do
        ball:draw()
    end
    self.player:draw()
    
    if self.gameover then
        love.graphics.setHexColor("#f00000");
    end
    love.graphics.dashedLine(self.dashedLine.x1, self.dashedLine.y1, self.dashedLine.x2, self.dashedLine.y2, self.dashedLine.dashLength)
    love.graphics.setHexColor(self.defaultColor);
    love.graphics.print("Score: " ..self.score, 420,10)
end

function scene:keypressed(key)
    self.player:keypressed(key)
end

createGameScene = function(sceneManager)
    return {
        scene = scene,
        enter = function(self)
            scene:load()
        end,
        update = function(self, dt)
            scene:update(dt)
        end,
        draw = function(self)
            scene:draw()
        end,
        keypressed = function(self, key)
            if key == controls.start then
                sceneManager:switchTo("game")
            end
            scene:keypressed(key)
        end
    }
end