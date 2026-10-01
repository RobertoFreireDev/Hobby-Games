local spriteeditor = {
    firsttime = true,
    collorButtons = {},
    paintbuttons = {},
    flagButtons = {},
    selectedcolor = 0,
    cell = 12,
    grid_w = 10,
    grid_h = 10,
    sprite_x = 275,
    sprites_x = 15,
    sprites_y = 135,
    origin_x = 100,
    origin_y = 5,
    pixelbutton = new_button(0,11,_colors.secondary,10,275,105,0,0,10,10),
    eraserbutton = new_button(0,10,_colors.secondary,10,275+10,105,0,0,10,10),
    linebutton = new_button(0,12,_colors.secondary,10,275+20,105,0,0,10,10),
    rectbutton = new_button(0,13,_colors.secondary,10,275+30,105,0,0,10,10),
    circlebutton = new_button(0,14,_colors.secondary,10,275,115,0,0,10,10),
    paintbutton = new_button(0,9,_colors.secondary,10,275+10,115,0,0,10,10),
    sprites_w = 30,
    sprites_h = 4,
    sprites_cell = 10,
    spriteNumber = 1,
    pageNumber = 0,
    zoom = 1,
    lastZoom = 1,
    maxZoom = 4,
    gridpos = { x= nil, y= nil},
    drawshape = { x0 = nil, y0 = nil, x1 = nil, y1 = nil},
    mousepos = { x= nil, y= nil},
    setpixel = { x = nil, y = nil, c = nil },
    selectedRec = {},
}

function spriteeditor:create()
    local x,y,size=self.sprite_x,self.origin_y,10
    for i=0,31 do
	    local row = flr(i/4)
	    local col = i%4
	    local px = x + col*size
	    local py = y + row*size
        local cbtn = new_colorbutton(i,px,py,0,0,size,size)
        cbtn.clicked = function(o)
            if self.paintbuttonselected == self.eraserbutton then
                return
            end
            self.selectedcolor = o.c  
        end 
        add(self.collorButtons,cbtn)
    end
    
    local x,y,size,incx,incy=self.origin_x + 124,self.origin_y,9,0,1
    for i=0,7 do
	    local row = flr(i/4)
	    local col = i%4
        if col == 0 then
            incx = 0
            incy = incy + 1
        else
            incx = incx + 1
        end
	    local px = x + col*size + incx * 3
	    local py = y + row*size + incy * 2 - 5
        local fbtn = new_flagbutton(_colors.secondary,_colors.primary,px,py,0,0,size,size,i+1)
        fbtn.clicked = function(o)
            o:toggleflag()
            setflags(self.spriteNumber,self.flagButtons)
        end 
        add(self.flagButtons,fbtn)
    end    
    self.eraserbutton.clicked = function(o) self.paintbuttonselected = o self.selectedcolor = -1 end    
    self.pixelbutton.clicked = function(o) 
        self.paintbuttonselected = o
        if self.selectedcolor == -1 then
            self.selectedcolor = 0
        end
    end
    self.linebutton.clicked = function(o) self.paintbuttonselected = o end
    self.rectbutton.clicked = function(o) self.paintbuttonselected = o end
    self.circlebutton.clicked = function(o) self.paintbuttonselected = o end
    self.paintbutton.clicked = function(o) self.paintbuttonselected = o end

    add(self.paintbuttons,self.eraserbutton)
    add(self.paintbuttons,self.pixelbutton)
    add(self.paintbuttons,self.linebutton)
    add(self.paintbuttons,self.rectbutton)
    add(self.paintbuttons,self.circlebutton)
    add(self.paintbuttons,self.paintbutton)
    self:updateflags()
end

function spriteeditor:init()
    if self.firsttime then
        self:create()
        self.paintbuttonselected = self.pixelbutton
        self.firsttime = false
    end
end

function spriteeditor:updateflags()
    local flags = getflags(self.spriteNumber)
    for i = 1, #self.flagButtons do
        self.flagButtons[i]:setflag(flags[i])
    end
end

function spriteeditor:update()
    foreach(self.collorButtons, function(o)
        o:update()
    end)
    foreach(self.paintbuttons, function(o)
        o:update()
        o.b.c = self.paintbuttonselected == o and _colors.tertiary or _colors.secondary
    end)    
    foreach(self.flagButtons, function(o)
        o:update()
    end)

    self.pageNumber = movepage(0,self.pageNumber,const.maxPage)
    self.lastZoom = self.zoom
    self.zoom = mousescroll(1,self.zoom,self.maxZoom)
    self.mousepos = _mousepos()
    self.gridpos = screen_to_grid(self.mousepos,self.origin_x, self.origin_y, self.grid_w*self.zoom, self.grid_h*self.zoom, self.cell/self.zoom)

    if (_btn(_keys.LeftControl) or _btn(_keys.RightControl)) and (self.paintbuttonselected == self.rectbutton or self.paintbuttonselected == self.circlebutton) then
        self.rectbutton:updatesprite(23)
        self.circlebutton:updatesprite(16)
    else
        self.rectbutton:updatesprite(13)
        self.circlebutton:updatesprite(14)
    end

    local offsetX, offsetY = (self.spriteNumber  % self.sprites_w) * self.sprites_cell, flr(self.spriteNumber / self.sprites_w) * self.sprites_cell
    self.selectedRec = getSelectedRec(self.spriteNumber, self.pageNumber, self.sprites_w, self.sprites_h, self.sprites_cell,self.zoom)
    local scale = self.sprites_cell*self.zoom
    
    if _btn(_keys.LeftControl) then
        if _btnp(_keys.Z) then
            _ugrid()
        elseif _btnp(_keys.Y) then
            _rgrid()
        elseif _btnp(_keys.C) then
            _cgrid(
                offsetX,
                offsetY,
                scale,
                scale)
        elseif _btnp(_keys.V) then
            _pgrid(
                offsetX,
                offsetY,
                scale,
                scale)
        end
    end

    if not self.gridpos.x or not self.gridpos.y then
        self.drawshape = { x0 = nil, y0 = nil, x1 = nil, y1 = nil }
    else

        if self.lastZoom > self.zoom then
            self.drawshape = { x0 = nil, y0 = nil, x1 = nil, y1 = nil }
        end

        if self.paintbuttonselected == self.linebutton or 
           self.paintbuttonselected == self.rectbutton or
           self.paintbuttonselected == self.circlebutton then
           if _mouseclickp(0) then
                self.drawshape = { x0 = self.gridpos.x, y0 = self.gridpos.y, x1 = nil, y1 = nil}
           end
           self.drawshape.x1 = self.gridpos.x
           self.drawshape.y1 = self.gridpos.y

           if _mouseclickr(0) and self.drawshape.x0 and self.drawshape.y0 then
                if self.paintbuttonselected == self.linebutton then
                    _slinegrid(
                        offsetX + self.drawshape.x0,
                        offsetY + self.drawshape.y0,
                        offsetX + self.drawshape.x1,
                        offsetY + self.drawshape.y1,
                        self.selectedcolor)
                elseif self.paintbuttonselected == self.rectbutton then
                    _srectgrid(
                        offsetX + self.drawshape.x0,
                        offsetY + self.drawshape.y0,
                        offsetX + self.drawshape.x1,
                        offsetY + self.drawshape.y1,
                        self.selectedcolor,
                        _btn(_keys.LeftControl) or _btn(_keys.RightControl))
                elseif self.paintbuttonselected == self.circlebutton then
                    _scircgrid(
                        offsetX + self.drawshape.x0,
                        offsetY + self.drawshape.y0,
                        offsetX + self.drawshape.x1,
                        offsetY + self.drawshape.y1,
                        self.selectedcolor,
                        _btn(_keys.LeftControl) or _btn(_keys.RightControl))
                end

                self.drawshape = { x0 = nil, y0 = nil, x1 = nil, y1 = nil }
           end
        else
            self.drawshape = { x0 = nil, y0 = nil, x1 = nil, y1 = nil }
        end 

        if self.paintbuttonselected == self.pixelbutton or self.paintbuttonselected == self.eraserbutton then
            if _mouseclick(0) and 
                (
                    self.setpixel.x ~= offsetX + self.gridpos.x or
                    self.setpixel.y ~= offsetY + self.gridpos.y or
                    self.setpixel.c ~= self.selectedcolor
                ) then
                _spixelgrid(
                    offsetX + self.gridpos.x,
                    offsetY + self.gridpos.y,
                    self.selectedcolor)
                -- to avoid unnecessary setpixel and add to history
                self.setpixel = { 
                    x = offsetX + self.gridpos.x, 
                    y = offsetY + self.gridpos.y, 
                    c = self.selectedcolor 
                }
            end
        end

        if self.paintbuttonselected == self.paintbutton then
            if _mouseclickp(0) then
                _bgrid(
                    offsetX + self.gridpos.x,
                    offsetY + self.gridpos.y,
                    offsetX,
                    offsetY,
                    self.sprites_cell*self.zoom,
                    self.sprites_cell*self.zoom,
                    self.selectedcolor)
            end
        end
    end

    if (not self.gridpos.x or not self.gridpos.y) and _mouseclickp(0) then 
        local spritespos = screen_to_grid(self.mousepos,self.sprites_x, self.sprites_y, self.sprites_w, self.sprites_h, self.sprites_cell)
        local sn = updateSpriteNumber(spritespos,self.spriteNumber,self.pageNumber,self.sprites_w,self.sprites_h)
        if sn > 0 and self.spriteNumber ~= sn then
            self.spriteNumber = sn
            self:updateflags()
        end
    end

    local mvg = { x= 0, y = 0}
    if _btnp(_keys.A) then     
        mvg.x = mvg.x - 1
    end
    if _btnp(_keys.D) then
        mvg.x = mvg.x + 1
    end
    if _btnp(_keys.W) then
        mvg.y = mvg.y - 1
    end
    if _btnp(_keys.S) then
        mvg.y = mvg.y + 1
    end

    if mvg.x ~=0 or mvg.y ~=0 then
        _mgrid(
            offsetX,
            offsetY,
            scale,
            scale,
            mvg.x,
            mvg.y)
    end
end

function spriteeditor:draw()
    _rect(self.sprite_x-1,self.origin_y-1,42,82,_colors.secondary)
    _rect(self.sprite_x-1,89-1,42,12,_colors.secondary)
    _dimg(1,0,self.sprite_x,89,3,2,4,1)
    _rectfill(self.sprite_x,89,40,10,self.selectedcolor)
    foreach(self.collorButtons, function(o)
        o:draw()
    end)
    foreach(self.paintbuttons, function(o)
        o:draw()
    end)
    foreach(self.flagButtons, function(o)
        o:draw()
    end)

    _rect(self.origin_x - 1, self.origin_y - 1,self.grid_w * self.cell + 2,self.grid_h * self.cell + 2,_colors.secondary)    
    _dimg(1,0,self.origin_x,self.origin_y,3,2,self.cell,self.cell)
    _dgrid(self.spriteNumber,self.origin_x,self.origin_y,self.cell/self.zoom,-1,10,self.zoom,self.zoom,false,false)    
    self:drawtemporaryshape()

    drawPageSpriteNumbers(self.spriteNumber,self.pageNumber,self.sprites_x,self.sprites_y)
    
    _rect(self.sprites_x - 1, self.sprites_y - 1,self.sprites_w*self.sprites_cell + 2,self.sprites_h*self.sprites_cell + 2,_colors.secondary)
    _dimg(1,0,self.sprites_x,self.sprites_y,3,2,self.sprites_w,self.sprites_h)     
    _dgrid(self.pageNumber*self.sprites_w*self.sprites_h,self.sprites_x,self.sprites_y,1,-1,10,self.sprites_w,self.sprites_h,false,false)
    
    if self.selectedRec.x and self.spriteNumber >= self.pageNumber*self.sprites_w*self.sprites_h and self.spriteNumber < (self.pageNumber+1)*self.sprites_w*self.sprites_h then
        _rect(self.sprites_x + self.selectedRec.x, self.sprites_y + self.selectedRec.y, self.selectedRec.sw, self.selectedRec.sh, 1)
    end
end

function spriteeditor:drawtemporaryshape()
    if not self.drawshape.x0 or not self.drawshape.y0 or not self.drawshape.x1 or not self.drawshape.y1 then
        return
    end

    local scale = self.cell/self.zoom

    if self.paintbuttonselected == self.linebutton then
        _line(
            self.origin_x + self.drawshape.x0*scale,
            self.origin_y + self.drawshape.y0*scale,
            self.drawshape.x1 - self.drawshape.x0,
            self.drawshape.y1 - self.drawshape.y0,
            scale,
            self.selectedcolor)
    elseif self.paintbuttonselected == self.rectbutton then
         local rx0, ry0, rx1, ry1, w, h = rect_bounds(self.drawshape.x0, self.drawshape.y0, self.drawshape.x1, self.drawshape.y1)
         if _btn(_keys.LeftControl) or _btn(_keys.RightControl) then
            _rectfill(
                self.origin_x + rx0*scale,
                self.origin_y + ry0*scale,
                w*scale,
                h*scale,
                self.selectedcolor)
         else
            _rect(
                self.origin_x + rx0*scale,
                self.origin_y + ry0*scale,
                w*scale,
                h*scale,
                self.selectedcolor,
                10,scale)
         end
    elseif self.paintbuttonselected == self.circlebutton then
         if _btn(_keys.LeftControl) or _btn(_keys.RightControl) then
            _circfill2(self.origin_x, self.origin_y,self.drawshape.x0,self.drawshape.y0,self.drawshape.x1,self.drawshape.y1, self.selectedcolor, 10, scale)
         else
            _circ2(self.origin_x, self.origin_y,self.drawshape.x0,self.drawshape.y0,self.drawshape.x1,self.drawshape.y1, self.selectedcolor, 10, scale)
         end
    end
end

return spriteeditor