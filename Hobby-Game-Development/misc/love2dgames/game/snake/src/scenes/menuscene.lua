createMenuScene = function(sceneManager)
    return {
        enter = function(self)
        end,
        update = function(self, dt)
            if love.keyboard.isDown(controls.b) or love.keyboard.isDown(controls.start) then                
                sceneManager:switchTo("game")
            end
        end,
        draw = function(self)
            love.graphics.draw(menuImage,0,0)
        end,
    }
end