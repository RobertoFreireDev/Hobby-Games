local gamepadexample={
    title = "GamePad example"
}

local newPlayer = function(x,y,i)
    local o = {}
    o.x = x
    o.y = y
    o.i = i
    o.fc = (i + 1)*3
    o.sc = (i + 1)*2    
    o.c = o.fc
    o.pr = true
    o.r = 4
    o.speed = 1
    o.butarr={1,2,0,3,5,6,3,4,8,7,4,0,1,2,0}
    o.butarr[0]=0
    o.dirx={-1,1, 0,0,-0.7071, 0.7071,0.7071,-0.7071}
    o.diry={ 0,0,-1,1,-0.7071,-0.7071,0.7071, 0.7071}
    o.lastdir = 0
    o.mask = 0
    o.dx = 0
    o.dy = 0

    function o:update()
        self.mask = 0
        self.dx=0
        self.dy=0

        -- LEFT = 1
        if _gmpd(_gamepadbuttons.DPadLeft,self.i) or _gmpd(_gamepadbuttons.RightThumbstickLeft,self.i) or _gmpd(_gamepadbuttons.LeftThumbstickLeft,self.i) then
            self.mask = self.mask + 1
        end

        -- RIGHT = 2
        if _gmpd(_gamepadbuttons.DPadRight,self.i) or _gmpd(_gamepadbuttons.RightThumbstickRight,self.i) or _gmpd(_gamepadbuttons.LeftThumbstickRight,self.i) then
            self.mask = self.mask + 2
        end

        -- UP = 4
        if _gmpd(_gamepadbuttons.DPadUp,self.i) or _gmpd(_gamepadbuttons.RightThumbstickUp,self.i) or _gmpd(_gamepadbuttons.LeftThumbstickUp,self.i) then
            self.mask = self.mask + 4
        end

        -- DOWN = 8
        if _gmpd(_gamepadbuttons.DPadDown,self.i) or _gmpd(_gamepadbuttons.RightThumbstickDown,self.i) or _gmpd(_gamepadbuttons.LeftThumbstickDown,self.i) then
            self.mask = self.mask + 8
        end

        local dir = self.butarr[self.mask]

        if self.lastdir ~= dir and dir>=5 then
            self.x=flr(self.x)+0.5
            self.y=flr(self.y)+0.5
        end

        if dir > 0 then
            self.dx=self.dx+self.dirx[dir]*self.speed
            self.dy=self.dy+self.diry[dir]*self.speed
        end

        self.lastdir=dir
        self.x = self.x + self.dx
        self.y = self.y + self.dy

        if _gmpd(_gamepadbuttons.LeftShoulder,self.i) or _gmpd(_gamepadbuttons.RightShoulder,self.i) or _gmpdp(_gamepadbuttons.A,self.i) or _gmpdp(_gamepadbuttons.B,self.i) or _gmpdr(_gamepadbuttons.X,self.i) or _gmpdr(_gamepadbuttons.Y,self.i) then
            self.c = self.pr and self.fc or self.sc
            self.pr = not self.pr
        end
    end

    function o:draw()    
        _circ(self.x, self.y, self.r, self.c, 10)
        _print("lastdir = "..self.lastdir, 50, 100, 1)
        _print("mask = "..self.mask, 50, 120, 1)
        _print(self.x..","..self.y, 50, 140, 1)
    end

    return o
end

players = {}

function gamepadexample:init()
    players = {}
    add(players,newPlayer(100,100,0))
    add(players,newPlayer(150,150,1))
end

function gamepadexample:update() 
    for i = 1, #players do
        players[i]:update()
    end
end

function gamepadexample:draw()
    for i = 1, #players do
        players[i]:draw()
    end
end

return gamepadexample