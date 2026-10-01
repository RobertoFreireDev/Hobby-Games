StateManager = {}
StateManager.__index = StateManager

function StateManager:new()
    local instance = {
        states = {},
        currentState = nil
    }
    setmetatable(instance, self)
    return instance
end

function StateManager:registerState(name, state)
    self.states[name] = state
end

function StateManager:switchState(name, ...)
    if self.currentState and self.currentState.exit then
        self.currentState:exit()
    end
    self.currentState = self.states[name]
    if self.currentState and self.currentState.enter then
        self.currentState:enter(...)
    end
end

function StateManager:update(dt)
    if self.currentState and self.currentState.update then
        self.currentState:update(dt)
    end
end

function StateManager:draw()
    if self.currentState and self.currentState.draw then
        self.currentState:draw()
    end
end

function StateManager:keypressed(key)
    if self.currentState and self.currentState.keypressed then
        self.currentState:keypressed(key)
    end
end