function updateSpriteNumber(sp,sn,pn,w,h)
    if sp.x and sp.y then
        sn = pn*w*h + flr(sp.x + sp.y*w)
    end
    return sn
end

function getflags(n)
    local v = _gflag(n)
    local flags = {}
    for i = 0, 7 do
        flags[i + 1] = (v >> i) & 1
    end
    return flags
end

function setflags(sn,flags)
    local v = 0
    local m = 1
    for i = 0, 7 do
        if flags[i + 1].active then
            v = v + m
        end
        m = m*2
    end
    _sflag(sn,v)
end

function movearrows(minX,minY,maxX,maxY,pos)
    if _btn(_keys.A) then
        pos.x = max(minX,pos.x-1)
    end
    if _btn(_keys.D) then
        pos.x = min(pos.x+1,maxX)
    end
    if _btn(_keys.W) then
        pos.y = max(minY,pos.y-1)
    end
    if _btn(_keys.S) then
        pos.y = min(pos.y+1,maxY)
    end

    return pos
end

function movepage(a,pn,b)
    local tmp = pn
    if _btnp(_keys.E) then
        pn = min(pn + 1,b)
    end
    if _btnp(_keys.Q) then
        pn = max(a,pn - 1)
    end

    return pn
end

function mousescroll(a,ms,b)
    if _mousescroll(1) then
        ms = max(a,ms - 1)
    end
    if _mousescroll(0) then
        ms = min(ms + 1,b)
    end

    return ms
end

function drawPageSpriteNumbers(sn,pn,x,y)
    _print("SPR#:",x,y - 8, _colors.secondary)
    _print(tostring(sn),x + 20,y - 8, 1)
    _print("PAG#:",x + 35,y - 8, _colors.secondary)
    _print(tostring(pn),x + 55,y - 8, 1)
end

function table_to_string(tbl, sep, kvsep)
    sep = sep or ", "
    kvsep = kvsep or "="
    local parts = {}
    for k, v in pairs(tbl) do
        table.insert(parts, tostring(k) .. kvsep .. tostring(v))
    end
    return table.concat(parts, sep)
end

function getSelectedRec(sn,pn,w,h,sc,scale)
    -- sprite index inside this page
    local sn = sn - pn*w*h
    local px = (sn % w) * sc
    local py = flr(sn / w) * sc

    -- calculate scaled size
    local psw = sc * scale
    local psh = sc * scale

    -- clamp so it never exceeds page width/height
    local maxw = w * sc
    local maxh = h * sc
    if px + psw > maxw then psw = maxw - px end
    if py + psh > maxh then psh = maxh - py end

    return {x=px,y=py,sw=psw,sh=psh}
end

function screen_to_grid(p,x,y,w,h,s) 
    local gx = flr((p.x - x) / s)
    local gy = flr((p.y - y) / s)

    if gx < 0 or gx >= w or gy < 0 or gy >= h then
        return { x=nil, y=nil}
    end

    return { x=gx, y=gy}
end

function rect_bounds(x0, y0, x1, y1)
    local rx0 = min(x0, x1)
    local ry0 = min(y0, y1)
    local rx1 = max(x0, x1)
    local ry1 = max(y0, y1)
    return rx0, ry0, rx1, ry1, rx1 - rx0 + 1, ry1 - ry0 + 1
end