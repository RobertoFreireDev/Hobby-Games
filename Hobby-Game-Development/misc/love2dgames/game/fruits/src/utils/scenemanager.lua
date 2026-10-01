SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager:new()
    local instance = {
        scenes = {},
        currentScene = nil
    }
    setmetatable(instance, SceneManager)
    return instance
end

function SceneManager:registerScene(name, scene)
    self.scenes[name] = scene
end

function SceneManager:switchTo(name, ...)
    if self.scenes[name] then
        if self.currentScene and self.currentScene.leave then
            self.currentScene:leave()
        end
        self.currentScene = self.scenes[name]
        if self.currentScene.enter then
            self.currentScene:enter(...)
        end
    else
        error("Scene '" .. name .. "' does not exist.")
    end
end

function SceneManager:update(dt)
    if self.currentScene and self.currentScene.update then
        self.currentScene:update(dt)
    end
end

function SceneManager:draw()
    if self.currentScene and self.currentScene.draw then
        self.currentScene:draw()
    end
end

function SceneManager:keypressed(key)
    if self.currentScene and self.currentScene.keypressed then
        self.currentScene:keypressed(key)
    end
end

function SceneManager:keyreleased(key)
    if self.currentScene and self.currentScene.keyreleased then
        self.currentScene:keyreleased(key)
    end
end