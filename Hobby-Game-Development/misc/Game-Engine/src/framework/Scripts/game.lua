local buttonsexample = require("Scripts/Examples/buttonsexample")
local keyboardexample   = require("Scripts/Examples/keyboardexample")
local mouseexample = require("Scripts/Examples/mouseexample")
local gamepadexample = require("Scripts/Examples/gamepadexample")
local tablesexample = require("Scripts/Examples/tablesexample")
local timerexample  = require("Scripts/Examples/timerexample")
local cameraexample   = require("Scripts/Examples/cameraexample")
local topdowngameexample   = require("Scripts/Examples/topdowngameexample")
local platformgameexample   = require("Scripts/Examples/platformgameexample")

local game={
    examples = {},
    index = 1,
    onexample = false
}

function game:init()
    add(self.examples,buttonsexample)
    add(self.examples,keyboardexample)
    add(self.examples,mouseexample)
    add(self.examples,gamepadexample)
    add(self.examples,tablesexample)
    add(self.examples,timerexample)
    add(self.examples,cameraexample)
    add(self.examples,topdowngameexample)
    add(self.examples,platformgameexample)
end

function game:update()
    if _btnp(_keys.Q) then
        self.onexample = not self.onexample

        if self.onexample then
            self.examples[self.index]:init()
        end
    end

    if self.onexample then
        self.examples[self.index]:update()
        return
    end

    if _btnp(_keys.S) or _btnp(_keys.A) or _btnp(_keys.Down) or _btnp(_keys.Left) then
        self.index = self.index - 1

        if self.index < 1 then
            self.index = #self.examples
        end
    end

    if _btnp(_keys.W) or _btnp(_keys.D) or _btnp(_keys.Up) or _btnp(_keys.Right) then
        self.index = self.index + 1

        if self.index > #self.examples then
            self.index = 1
        end
    end
end

function game:draw()
    if self.onexample then
        self.examples[self.index]:draw()
        return
    end

    _print(self.examples[self.index].title,20,20,_colors.primary)
end

return game