local sfxeditor={
    firsttime = true,
    sfxIndex = 1,
    sounds = {}
}

function new_sfx(idx)
    local sfx = {
        idx = idx,
        speed = 1,
        notes = {},
        octaves = {},
        waves = {},
        vol = {},
        notepos = { x = 20, y = 60, r = 12 },
        octpos = { x = 20, y = 88, r = 3 },
        wavepos = { x = 20, y = 132, r = 9 },
        volpos = { x = 20, y = 166, r = 6 },
        step = { x = 12, y = 3 }
    }

    function sfx:load()
        self.notes = {}
        self.vol = {}
        self.octaves = {}
        self.waves = {}
        self.vol = {}
        for i=1,24 do
            add(self.notes,new_verticalbar(self.notepos.x + (i-1)*self.step.x,self.notepos.y,self.notepos.r,self.step.x,self.step.y))
            add(self.octaves,new_verticalbar(self.octpos.x + (i-1)*self.step.x,self.octpos.y,self.octpos.r,self.step.x,self.step.y))
            add(self.waves,new_verticalbar(self.wavepos.x + (i-1)*self.step.x,self.wavepos.y,self.wavepos.r,self.step.x,self.step.y))
            add(self.vol,new_verticalbar(self.volpos.x + (i-1)*self.step.x,self.volpos.y,self.volpos.r,self.step.x,self.step.y))
        end

        local str = _getsfx(self.idx)
        local len = #str - 2
        local count = 1
        for i = 1, len, 5 do
            local note = (tonumber(str:sub(i, i+1)) or 0) - 36
            local octave = flr(note/12)
            local pitch = note % 12
            local wave  = tonumber(str:sub(i+2, i+2)) or 0
            local vol   = tonumber(str:sub(i+3, i+4))
            self.notes[count].value = pitch 
            self.octaves[count].value = octave < 0 and 0 or octave
            self.waves[count].value = wave
            self.vol[count].value = flr(vol/2)
            count = count + 1
        end
    end

    function sfx:update()
        if _mouseclick(0) then        
            self:updatenote()
        end

        self:changespeed()
    end

    function sfx:updatenote()
        for i = 1, #self.notes do        
            local n = self.notes[i]:update(_mousepos())
            if n >= 0 then
                self:setnote(
                    i,
                    n,
                    self.octaves[i].value,
                    self.waves[i].value,
                    self.vol[i].value)
                return
            end

            local o = self.octaves[i]:update(_mousepos())
            if o >= 0 then
                self:setnote(
                    i,
                    self.notes[i].value,
                    o,
                    self.waves[i].value,
                    self.vol[i].value)
                return
            end

            local w = self.waves[i]:update(_mousepos())
            if w >= 0 then
                self:setnote(
                    i,
                    self.notes[i].value,
                    self.octaves[i].value,
                    w,
                    self.vol[i].value)
                return
            end

            local v = self.vol[i]:update(_mousepos())
            if v >= 0 then
                self:setnote(
                    i,
                    self.notes[i].value,
                    self.octaves[i].value,
                    self.waves[i].value,
                    v)
                return
            end
        end
    end

    function sfx:changespeed()
        if _btnp(_keys.D) then
            self.speed = min(self.speed + 1,16)
            _spdsfx(self.idx, self.speed)
        end
        if _btnp(_keys.A) then
            self.speed = max(1,self.speed - 1)
            _spdsfx(self.idx, self.speed)
        end
    end

    function sfx:setnote(i,n,o,w,v)
        v = v == 5 and "10" or "0"..tostring(v*2)
        _setnotesfx(self.idx, i-1, tostring(36+n + o*12)..tostring(w)..v)
    end

    function sfx:draw()
        _print("Spd: "..self.speed.." Sfx: "..self.idx, self.notepos.x + 60, 0, _colors.secondary)
        self:drawSection("Notes", self.notepos)
        self:drawSection("Octaves", self.octpos)
        self:drawSection("Wave", self.wavepos)
        self:drawSection("Volume", self.volpos)

        for i = 1, #self.notes do
            self.notes[i]:draw()
            self.octaves[i]:draw()
            self.waves[i]:draw()
            self.vol[i]:draw()
        end
    end

    function sfx:drawSection(label, pos)
        _print(label, pos.x - 3, pos.y - pos.r*self.step.y - 10, _colors.primary)
        _rect(
            pos.x-2,
            pos.y-2 - pos.r*self.step.y,
            24*self.step.x+4,
            pos.r*self.step.y+4,
            _colors.secondary
        )
    end

    return sfx
end

function sfxeditor:create()
    self.sounds = {}
    for i = 1, 64 do
        add(self.sounds,new_sfx(i-1))
    end
    self.sounds[self.sfxIndex]:load()
end

function sfxeditor:init()
    if self.firsttime then
        self:create()
        self.firsttime = false
    end
end

function sfxeditor:update()
    self.sounds[self.sfxIndex]:update()

    if _btnp(_keys.Space) then
        _playsfx(self.sfxIndex-1)        
    end

    if _btnp(_keys.Q) then
        self.sfxIndex = max(1,self.sfxIndex-1)
        self.sounds[self.sfxIndex]:load()
    end
    if _btnp(_keys.E) then
        self.sfxIndex = min(self.sfxIndex+1,64)
        self.sounds[self.sfxIndex]:load()
    end
end

function sfxeditor:draw()
    self.sounds[self.sfxIndex]:draw()
end

return sfxeditor