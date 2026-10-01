FileIO = {}
FileIO.__index = FileIO

function FileIO:new(name)
    local instance = {
        fileName = name
    }
    setmetatable(instance, FileIO)
    return instance
end

function FileIO:save(value)
    local file = io.open(self.fileName, "w")    
    if file then
        file:write(tostring(value))
        file:close()
    end
end

function FileIO:load()
    local file = io.open(self.fileName, "r")    
    if file then
        local content = file:read("*all")
        file:close()
        return content
    end
end