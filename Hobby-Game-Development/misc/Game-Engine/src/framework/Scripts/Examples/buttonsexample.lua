local buttonsexample={
    title = "Buttons example"
}

local newPlayer = function(x,y)
    local o = {}
    o.x = x
    o.y = y
    o.c = 12
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
        if _btn(_keys.Left) then
            self.mask = self.mask + 1
        end

        -- RIGHT = 2
        if _btn(_keys.Right) then
            self.mask = self.mask + 2
        end

        -- UP = 4
        if _btn(_keys.Up) then
            self.mask = self.mask + 4
        end

        -- DOWN = 8
        if _btn(_keys.Down) then
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
    end

    function o:draw()    
        _circfill(self.x, self.y, self.r, self.c, 10)
        _print("lastdir = "..self.lastdir, 50, 100, 1)
        _print("mask = "..self.mask, 50, 120, 1)
        _print(self.x..", "..self.y, 50, 140, 1)
    end

    return o
end

function buttonsexample:init()
    player = newPlayer(100,100)
end

function buttonsexample:update() 
    player:update()
end

function buttonsexample:draw()
    player:draw()
end

return buttonsexample