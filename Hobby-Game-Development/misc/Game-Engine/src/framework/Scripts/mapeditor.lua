local mapeditor={
    firsttime = true,
    map_x = 15, 
    map_y = 5, 
    map_pos = {x=0,y=0},
    map_columns = 30,
    map_rows = 12,
    sprites_x = 15, 
    sprites_y = 135,
    sprites_w = 30,
    sprites_h = 4,
    sprites_cell= 10,
    spriteNumber = 0,
    pageNumber = 0,
    selectedRec = {},
    drawshape = { x0 = nil, y0 = nil},
}

function mapeditor:create()
end

function mapeditor:init()
    if self.firsttime then
        self:create()
        self.firsttime = false
    end
end

function mapeditor:update()   
    if _mouseclick(0) or _mouseclickr(0) then
        local mousepos = _mousepos()
        local gridpos = screen_to_grid(mousepos,self.map_x, self.map_y, self.map_columns, self.map_rows, self.sprites_cell)
        if gridpos.x and gridpos.y then
            if _btn(_keys.LeftControl) then
                if _mouseclickp(0) then
                    self.drawshape = { x0 = gridpos.x, y0 = gridpos.y}
                elseif _mouseclickr(0) then
                    if self.drawshape.x0 and self.drawshape.y0 then
                        _bmap(
                            self.map_pos.x + self.drawshape.x0,
                            self.map_pos.y + self.drawshape.y0,
                            self.map_pos.x + gridpos.x,
                            self.map_pos.y + gridpos.y,
                            self.spriteNumber)
                    end                    
                    self.drawshape = { x0 = nil, y0 = nil}
                end
            else
                self.drawshape = { x0 = nil, y0 = nil}
                _smap(self.map_pos.x + gridpos.x,self.map_pos.y + gridpos.y,self.spriteNumber)
            end
        else
            local spritespos = screen_to_grid(mousepos,self.sprites_x, self.sprites_y, self.sprites_w, self.sprites_h, self.sprites_cell)
            self.spriteNumber = updateSpriteNumber(spritespos,self.spriteNumber,self.pageNumber,self.sprites_w,self.sprites_h)
        end
    end

    self.pageNumber = movepage(0,self.pageNumber,const.maxPage)
    self.map_pos = movearrows(0,0,320-self.map_columns,180-self.map_rows,self.map_pos)
    self.selectedRec = getSelectedRec(self.spriteNumber, self.pageNumber, self.sprites_w, self.sprites_h, self.sprites_cell,1)
end

function mapeditor:draw()
    _rect(self.map_x - 1, self.map_y - 1,self.map_columns*10 + 2,self.map_rows*10 + 2, _colors.secondary)
    _dimg(1,0,self.map_x,self.map_y,3,2,self.map_columns,self.map_rows)
    _dmap(self.map_pos.x, self.map_pos.y, self.map_x,self.map_y, self.map_columns, self.map_rows);
    _print("("..self.map_pos.x..","..self.map_pos.y..")",80,self.sprites_y - 8,_colors.secondary)

    drawPageSpriteNumbers(self.spriteNumber,self.pageNumber,self.sprites_x,self.sprites_y)

    _rect(self.sprites_x - 1, self.sprites_y - 1,self.sprites_w*10 + 2,self.sprites_h*10 + 2, _colors.secondary)
    _dimg(1,0,self.sprites_x,self.sprites_y,3,2,self.sprites_w,self.sprites_h)
    _dgrid(self.pageNumber*self.sprites_w*self.sprites_h,self.sprites_x,self.sprites_y,1,-1,10,self.sprites_w,self.sprites_h,false,false)
    
    if self.selectedRec.x and self.spriteNumber >= self.pageNumber*self.sprites_w*self.sprites_h and self.spriteNumber < (self.pageNumber+1)*self.sprites_w*self.sprites_h then    
        _rect(self.sprites_x + self.selectedRec.x, self.sprites_y + self.selectedRec.y, self.selectedRec.sw, self.selectedRec.sh, 1)  
    end
end

return mapeditor