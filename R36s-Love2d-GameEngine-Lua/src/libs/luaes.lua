local audio = require("libs/audio")
local bit = require("bit")
local sfxdata = require("data/sfx")
local spritesheetsdata = require("data/spritesheet")
local mapsdata = require("data/map")
local flagdata = require("data/flag")
local emptycartdata = require("data/emptycartdata")
local hasEnet, enet = pcall(require, "enet")
local socket = require("socket")

--#region global variables
local VIRTUAL_WIDTH = 160
local VIRTUAL_HEIGHT = 120
local scale = 4
local window_width = VIRTUAL_WIDTH*scale
local window_height = VIRTUAL_HEIGHT*scale
local offsetX, offsetY
--#endregion

--#region colors
local function hexToRGB(hex, alfa)
    alfa = alfa ~= nil and alfa or "FF"
    hex = hex:gsub("#","")
    local r = tonumber(hex:sub(1,2), 16)/255
    local g = tonumber(hex:sub(3,4), 16)/255
    local b = tonumber(hex:sub(5,6), 16)/255
    local a = tonumber(alfa, 16) / 255
    return {r, g, b, a}
end

local COLORPALETTE = {
    [1] = "#ffffff",
    [2] = "#1a1a1a",
    [3] = "#5d275d",
    [4] = "#b13e53",
    [5] = "#ef7d57",
    [6] = "#ffcd75",
    [7] = "#a7f070",
    [8] = "#38b764",
    [9] = "#257179",
    [10] = "#29366f",
    [11] = "#3b5dc9",
    [12] = "#41a6f6",
    [13] = "#73eff7",
    [14] = "#94b0c2",
    [15] = "#566c86",
    [16] = "#6b4226",
    [17]  = "#f4f4f4",
    [18]  = "#000000",
    [19]  = "#421c42",
    [20]  = "#7d2c3d",
    [21]  = "#b35e41",
    [22]  = "#c79f5a",
    [23]  = "#7fb353",
    [24]  = "#2a8a4c",
    [25]  = "#1b5258",
    [26] = "#1d254d",
    [27] = "#2b4391",
    [28] = "#2f78b8",
    [29] = "#55b4ba",
    [30] = "#6f8494",
    [31] = "#3f5066",
    [32] = "#4a2e1a"
}

local defaultColor = 1

local function getpalette(i, a)
    i = mid(0, i, 32)
    if i <= 0 then
        return hexToRGB("#000000","00") -- transparent
    end

    return hexToRGB(COLORPALETTE[i], a)
end

function alphaToHex(v)
    v = (v ~= nil and type(v) == "number") and v or 10
    v = mid(0,v,10)
    return string.format("%02X", floor((v / 10) * 255 + 0.5))
end

local function setcolor(c,a)
    c = (c ~= nil and type(c) == "number") and c or defaultColor
    love.graphics.setColor(getpalette(c,alphaToHex(a)))
end
--#endregion

--#region fonts
local fonts = {
    [1] = { font = "fonts/Bytesized-Regular.ttf", size = 8 },
    [2] = { font = "fonts/Micro5-Regular.ttf", size = 11 },
    [3] = { font = "fonts/Tiny5-Regular.ttf", size = 8 },    
    [4] = { font = "fonts/PressStart2P-Regular.ttf", size = 8 },
    [5] = { font = "fonts/JacquardaBastarda9-Regular.ttf", size = 13 },
    [6] = { font = "fonts/Tiny5-Regular.ttf", size = 16 },
}

function font(i)
    i = mid(1,i,6)
    local f = love.graphics.newFont(fonts[i].font, fonts[i].size)
    f:setFilter("nearest", "nearest")
    love.graphics.setFont(f)
end
--#endregion

--#region table
function add(t, v)
    t[#t + 1] = v
    return v
end

function del(tbl, val)
    for i = #tbl, 1, -1 do
        if tbl[i] == val then
            table.remove(tbl, i)
            return val
        end
    end
    return nil
end

function foreach(tbl, func)
    for i, v in ipairs(tbl) do
        func(v, i)
    end
end

function all(tbl)
    local t = {}
    for i, v in ipairs(tbl) do
        t[i] = v
    end
    return t
end
--#endregion

--#region math
function floor(v)
    return math.floor(v)
end

function min(a, b)
    return math.min(a, b)
end

function max(a, b)
    return math.max(a, b)
end

function mid(a, v, b)
    return max(a, min(b, v))
end

function sgn(x)
    if x > 0 then return 1
    elseif x < 0 then return -1
    else return 0
    end
end

function abs(x)
    return math.abs(x)
end

function ceil(x)
    return math.ceil(x)
end

function rnd(x)
    if x then
        return love.math.random() * x
    else
        return love.math.random()
    end
end

function srnd(x)
    love.math.setRandomSeed(x)
end

function sqrt(x)
    return math.sqrt(x)
end

function sin(x)
    return math.sin(x)
end

function cos(x)
    return math.cos(x)
end

function atan2(y, x)
    return math.atan2(y, x)
end

function band(a, b)
    return bit.band(a, b)
end

function bor(a, b)
    return bit.bor(a, b)
end

function bxor(a, b)
    return bit.bxor(a, b)
end

function shl(a, n)
    return bit.lshift(a, n)
end

function shr(a, n)
    return bit.rshift(a, n)
end
--#endregion

--#region io
local function loadFile(filename)
    return io.lines(filename..".txt")
end

local function saveFile(filename, content)
    local file, err = io.open(filename..".txt", "w")
    assert(file, err)
    file:write(content)
    file:close()
end

local function fileExists(filename)
    local f = io.open(filename..".txt", "r")
    if f then
        f:close()
        return true
    end
    return false
end

local function createIfDoesntExist(filename, content)
    if not fileExists(filename) then
        local f, err = io.open(filename..".txt", "w")
        assert(f, "Failed to create file: " .. (err or "unknown error"))
        f:write(content)
        f:close()
    end
end
--#endregion

--#region sfx
local SFX = {}  -- X indexes x 16 notes
local SOUNDS = {} -- X sounds.
local LUAESSFXDATA = "luaessfxdata"

local function parseSFX(str)
    local tone     = str:sub(1, 3):gsub("X", "")
    local volume   = tonumber(str:sub(4, 5))
    local waveType = tonumber(str:sub(6, 6))
    local effects  = tonumber(str:sub(7, 7))
    local length  = tonumber(str:sub(8, 9))

    return {
        tone = tone,
        volume = volume,
        waveType = waveType,
        effects = effects,
        length = length
    }
end

local function loadsfxdata()
    createIfDoesntExist(LUAESSFXDATA, sfxdata)
    local lines = loadFile(LUAESSFXDATA)
    local soundIndex = 1

    for line in lines do
        local CHUNK_SIZE = 9
        local chunks = {}
        for i = 1, #line, CHUNK_SIZE do
            add(chunks, line:sub(i, i + CHUNK_SIZE - 1))
        end
        
        local newsound = {}
        for i = 1, #chunks do
            local sfxIdx = (soundIndex-1)*16 + i
            SFX[sfxIdx] = parseSFX(chunks[i])
            add(newsound,SFX[sfxIdx])
        end
        SOUNDS[soundIndex] = audio.genMusic(newsound)
        
        soundIndex = soundIndex + 1
    end
end

local function buildSFX(data)
    local tone = data.tone or ""

    if tone == "" or #tone == 1 then
        tone = "XX0"
    elseif #tone == 2 then
        tone = ("X"..data.tone)
    end

    local volume = string.format("%02d", tonumber(data.volume) or 0)
    local waveType = tostring(tonumber(data.waveType) or 0)
    local effects  = tostring(tonumber(data.effects) or 0)
    local length   = string.format("%02d", tonumber(data.length) or "01")
    return tone .. volume .. waveType .. effects .. length
end

local function savesfxdata()
    local lines = {}
    local count = #SFX/16

    for i = 1, count do
        local line = ""

        for j = 1, 16 do
            local sfxIdx = (i - 1) * 16 + j
            line = line .. buildSFX(SFX[sfxIdx])
        end
        
        add(lines, line)
    end
    local content = table.concat(lines, "\n")
    saveFile(LUAESSFXDATA, content)
end

local lastPlayedTime = {}
local MIN_DELAY = 1/32
local FADE_TIME = 0.05
local active_sounds = {} 

function sfx(index, d)
    d = (d ~= nil and type(d) == "number") and d or 3
    local delay = mid(1, d, 16)
    local currentTime = os.clock()

    if lastPlayedTime[index] and (currentTime - lastPlayedTime[index] < MIN_DELAY * delay) then
        return
    end
    lastPlayedTime[index] = currentTime

    for i = #active_sounds, 1, -1 do
        local snd = active_sounds[i]
        if snd.index == index and snd.state ~= "fade_out" then
            snd.state = "fade_out"
        end
    end

    local newSource = SOUNDS[index]:clone()
    newSource:setVolume(0)
    newSource:play()
    
    table.insert(active_sounds, {
        index = index,
        source = newSource,
        state = "fade_in",
        volume = 0,
        target_volume = 1.0
    })
end

function updatesfx(dt)
    for i = #active_sounds, 1, -1 do
        local snd = active_sounds[i]
        
        if snd.state == "fade_in" then
            snd.volume = snd.volume + (dt / FADE_TIME)
            if snd.volume >= snd.target_volume then
                snd.volume = snd.target_volume
                snd.state = "playing"
            end
            snd.source:setVolume(snd.volume)
            
        elseif snd.state == "fade_out" then
            snd.volume = snd.volume - (dt / FADE_TIME)
            if snd.volume <= 0 then
                snd.volume = 0
                snd.source:stop()
                table.remove(active_sounds, i)
            else
                snd.source:setVolume(snd.volume)
            end
            
        elseif snd.state == "playing" then
            if not snd.source:isPlaying() then
                table.remove(active_sounds, i)
            end
        end
    end
end

function ssfx(index, t, v, w, e, l)
    local soundIndex = floor(index/16) + 1
    local newsound = {}
    local startIndex = floor(index/16)*16 + 1
    for i=startIndex,startIndex+15 do
        if index == i then
            SFX[i] = {
                tone = t,
                volume = v,
                waveType = w,
                effects = e,
                length = l
            }
        end
        add(newsound,SFX[i])
    end
    SOUNDS[soundIndex] = audio.genMusic(newsound)
end

--#region music

local cmp = nil
local cmpIndex = 1
local toPlay = true

local function changecmpindex(i)
    cmpIndex = i
    toPlay = true
end

local MUSICS = {}

function music(i)
    i = mid(1,i,16)
    local p = MUSICS[i]
    if cmp ~= nil and #cmp > 0 and cmp[cmpIndex].play ~= nil then
        for i=1, #cmp[cmpIndex].play do
            SOUNDS[cmp[cmpIndex].play[i]]:stop()
        end
        cmp = nil
        changecmpindex(1)
    end

    cmp = p
end

function smusic(i,p)
    i = mid(1,i,16)
    MUSICS[i] = p
end

local function updatemusic()
    if cmp == nil or #cmp == 0 then return end

    if cmp[cmpIndex] ~= nil and type(cmp[cmpIndex].next) == "number" then
        changecmpindex(cmp[cmpIndex].next)
    end

    if cmpIndex > #cmp then 
        changecmpindex(1)
    end

    if cmp[cmpIndex].stop then
        cmp = nil
        changecmpindex(1)
        return
    end

    local isPlaying = false

    for i=1, #cmp[cmpIndex].play do
        if SOUNDS[cmp[cmpIndex].play[i]]:isPlaying() then
            isPlaying = true
        end
    end

    if isPlaying then
        return
    end

    if toPlay then
       for i=1, #cmp[cmpIndex].play do
            SOUNDS[cmp[cmpIndex].play[i]]:play()
        end
        toPlay = false
        return
    end

    changecmpindex(cmpIndex + 1)
end
--#endregion

--#region camera
function camera(x, y)
     -- Always resetcamera in the same frame if camera function was called
    love.graphics.push()
    love.graphics.translate(-x, -y)
end

function resetcamera()
    love.graphics.pop()
end
--#endregion

--#region sprite
local spriteSheets = {}
local spritesheetsdataastable = {}
local sheetWidth, sheetHeight = 160, 32 -- each spritesheet has 160x32 pixels with tile 8x8. Each spritesheet has 20x4 tiles => 1 to 80 index.
local spriteSheetImages = {}
local SPR_SIZE = 8
local MAX_SHEETS = 8
local spritesPerRow = sheetWidth / SPR_SIZE
local rerenderImage = { false, false, false, false, false, false, false, false } -- 8 spread sheets
local LUAESSPRITESSHEETSDATA = "luaesspritesheetsdata"

local function charToNum(c)
    if c >= '0' and c <= '9' then
        return tonumber(c)
    elseif c >= 'A' and c <= 'X' then
        return 10 + (c:byte() - string.byte('A'))
    else
        return 0
    end
end

local function numToChar(n)
    if n >= 0 and n <= 9 then
        return tostring(n)
    elseif n >= 10 and n <= 32 then
        return string.char(string.byte('A') + (n - 10))
    else
        return '0'
    end
end

local function validSheet(i)
    return type(i) == "number" and i >= 1 and i <= MAX_SHEETS
end

local function validCoord(x, y)
    return type(x) == "number"
       and type(y) == "number"
       and x >= 1 and x <= sheetWidth
       and y >= 1 and y <= sheetHeight
end

function spixel(i, x, y, c)
    if not validSheet(i) then return end
    if not validCoord(x, y) then return end
    c = (type(c) == "number" and c >= 0 and c <= 32) and c or 0

    spritesheetsdataastable[i] = spritesheetsdataastable[i] or {}
    spritesheetsdataastable[i][y] = spritesheetsdataastable[i][y] or {}
    spritesheetsdataastable[i][y][x] = c

    local rgb = getpalette(c)
    spriteSheets[i]:setPixel(x-1, y-1, rgb[1], rgb[2], rgb[3], rgb[4])
    rerenderImage[i] = true
end

function gpixel(i, x, y)
    if not validSheet(i) then return 0 end
    if not validCoord(x, y) then return 0 end
    
    return spritesheetsdataastable[i][y][x]
end

local function loadspritesheetdata()
    createIfDoesntExist(LUAESSPRITESSHEETSDATA, spritesheetsdata)

    local lineIter = loadFile(LUAESSPRITESSHEETSDATA)
    local LINES_PER_IMAGE = 32

    local img = 1
    local y = 1

    spriteSheets[img] = love.image.newImageData(sheetWidth, sheetHeight)

    for line in lineIter do
        for x = 1, #line do
            spixel(img, x, y, charToNum(line:sub(x, x)))
        end

        y = y + 1

        if y > LINES_PER_IMAGE then
            spriteSheetImages[img] = love.graphics.newImage(spriteSheets[img])

            img = img + 1
            if img > 8 then break end

            spriteSheets[img] = love.image.newImageData(sheetWidth, sheetHeight)
            y = 1
        end
    end
end

local function savespritesheetdata()
    local lines = {}
    local LINES_PER_IMAGE = 32

    for img = 1, 8 do
        for y = 1, LINES_PER_IMAGE do
            local row = {}
            for x = 1, sheetWidth do
                local c = gpixel(img, x, y)
                row[#row + 1] = numToChar(c)
            end
            lines[#lines + 1] = table.concat(row)
        end
    end

    saveFile(LUAESSPRITESSHEETSDATA, table.concat(lines, "\n"))
end

function updatespritesheetimages()
    for i=1,8 do
        if rerenderImage[i] then
            spriteSheetImages[i] = love.graphics.newImage(spriteSheets[i])
        end
    end
end
--#endregion

--#region maps
-- each map 180x45
-- 45 x 8 maps = 360 lines
-- 180 chars per line => 60 tiles. Each tile contains 3 chars
-- each tile => 1 char (for spritesheet index 0 to 8) + 2 chars (for sprite index 0 to 80)
-- notes:
-- spritesheet index 0 means no spritesheet selected
-- sprite index 0 means no tile
local maps = {}
local MAP_WIDTH_TILES  = 60
local MAP_HEIGHT_TILES = 45
local MAP_COUNT        = 8
local CHARS_PER_TILE   = 3
local LUAESMAPSDATA    = "luaesmapdata"

local function loadmapsdata()
    createIfDoesntExist(LUAESMAPSDATA, mapsdata)

    local lineIter = loadFile(LUAESMAPSDATA)

    maps = {}

    local mapIndex = 1
    local y = 1

    maps[mapIndex] = {}

    for line in lineIter do
        maps[mapIndex][y] = {}

        local x = 1
        local i = 1

        while i <= #line do
            local spritesheetindex = line:sub(i, i)
            local spriteindex    = line:sub(i + 1, i + 2)

            maps[mapIndex][y][x] = {
                sheet  = spritesheetindex,
                sprite = spriteindex
            }

            x = x + 1
            i = i + CHARS_PER_TILE
        end

        y = y + 1

        if y > MAP_HEIGHT_TILES then
            mapIndex = mapIndex + 1
            if mapIndex > MAP_COUNT then
                break
            end
            maps[mapIndex] = {}
            y = 1
        end
    end
end

local function savemapsdata()
    local lines = {}

    for mapIndex = 1, MAP_COUNT do
        local map = maps[mapIndex] or {}

        for y = 1, MAP_HEIGHT_TILES do
            local row = {}
            local line = map[y] or {}

            for x = 1, MAP_WIDTH_TILES do
                local tile = line[x] or { sheet = 0, sprite = 0 }
                row[#row + 1] = tile.sheet or 0
                row[#row + 1] = tonumber(tile.sprite) < 10 and ("0"..tile.sprite) or tile.sprite
            end

            lines[#lines + 1] = table.concat(row)
        end
    end

    saveFile(LUAESMAPSDATA, table.concat(lines, "\n"))
end

function mget(i, x, y)
    i = mid(1,i,MAP_COUNT)
    x = floor(x)
    y = floor(y)

    if x < 1 or x > MAP_WIDTH_TILES then
        return 0, 0
    end
    if y < 1 or y > MAP_HEIGHT_TILES then
        return 0, 0
    end

    local map = maps[i]
    if not map or not map[y] or not map[y][x] then
        return 0, 0
    end

    local tile = map[y][x]

    return tonumber(tile.sheet) or 0,
           tonumber(tile.sprite) or 0
end

function mset(i, x, y, sheet, sprite)
    i = mid(1,i,MAP_COUNT)
    x = floor(x)
    y = floor(y)

    if x < 1 or x > MAP_WIDTH_TILES then return end
    if y < 1 or y > MAP_HEIGHT_TILES then return end

    sheet  = mid(0,(tonumber(sheet)  or 0),8)
    sprite = mid(0,(tonumber(sprite) or 0),80)

    maps[i] = maps[i] or {}
    maps[i][y] = maps[i][y] or {}

    maps[i][y][x] = {
        sheet  = tostring(sheet),
        sprite = (sprite < 10) and ("0" .. sprite) or tostring(sprite)
    }
end

--#endregion

--#region flags
local spritesFlags = {{},{},{},{},{},{},{},{}} -- Flags per spritesheets. 8 spritesheets. each spritesheet has 80 flags
local LUAESFLAGSDATA = "luaesflagdata"
local FLAGS_PER_LINE  = 80
local CHARS_PER_FLAG  = 3
local FLAG_LINES      = 8

function fset(spritesheetindex, spriteindex, f, v)
    if type(spritesheetindex) ~= "number" or type(spriteindex) ~= "number" or type(f) ~= "number" or (f < 0 or f > 7) or (spritesheetindex < 1 or spritesheetindex > 8) or (spritesheetindex < 1 or spritesheetindex > 80) then
        return
    end

    local flags = spritesFlags[spritesheetindex][spriteindex] or 0
    local mask  = shl(1, f)

    if v then
        flags = bor(flags, mask) -- set bit
    else
        flags = band(flags, bxor(mask, -1)) -- clear bit
    end

    spritesFlags[spritesheetindex][spriteindex] = flags
end

function fget(spritesheetindex, spriteindex, f)
    if (type(spritesheetindex) ~= "number" or type(spriteindex) ~= "number") or (spritesheetindex < 1 or spritesheetindex > 8) or (spritesheetindex < 1 or spritesheetindex > 80) then
        return false
    end
    local flags = spritesFlags[spritesheetindex][spriteindex] or 0

    if f == nil or type(f) ~= "number" then
        return flags
    end

    if f < 0 or f > 7 then return false end
    local mask  = shl(1, f)
    return band(flags, mask) ~= 0
end

local function loadflagsdata()
    createIfDoesntExist(LUAESFLAGSDATA, flagdata)
    local lineIter = loadFile(LUAESFLAGSDATA)

    local lineIndex = 1

    for line in lineIter do
        if lineIndex > FLAG_LINES then break end

        spritesFlags[lineIndex] = {}

        local i = 1
        local flagIndex = 1

        while i <= #line and flagIndex <= FLAGS_PER_LINE do
            local value = tonumber(line:sub(i, i + 2)) or 0
            spritesFlags[lineIndex][flagIndex] = value

            i = i + CHARS_PER_FLAG
            flagIndex = flagIndex + 1
        end

        lineIndex = lineIndex + 1
    end
end

local function saveflagsdata()
    local lines = {}

    for lineIndex = 1, FLAG_LINES do
        local row = {}
        local line = spritesFlags[lineIndex] or {}

        for i = 1, FLAGS_PER_LINE do
            local value = line[i] or 0
            value = mid(0, value, 255)
            row[#row + 1] = -- always 3 chars (000–255)
                value < 10  and ("00" .. value) or
                value < 100 and ("0"  .. value) or
                tostring(value)
        end

        lines[#lines + 1] = table.concat(row)
    end

    saveFile(LUAESFLAGSDATA, table.concat(lines, "\n"))
end
--#endregion

--#region draw
function print(text, x, y, c, a)
    setcolor(c, a)
    love.graphics.print(text, x, y)
    setcolor()
end

function rect(x, y, w, h, c, a)
    setcolor(c, a)
    love.graphics.rectangle("line", x, y, w, h)
    setcolor()
end

function rectfill(x, y, w, h, c, a)
    setcolor(c, a)
    love.graphics.rectangle("fill", x, y, w, h)
    setcolor()
end

function line(x0, y0, x1, y1, c, a)
    setcolor(c, a)
    love.graphics.line(x0, y0, x1, y1)
    setcolor()
end

function circ(x, y, r, c, a)
    setcolor(c, a)
    love.graphics.circle("line", x, y, r)
    setcolor()
end

function circfill(x, y, r, c, a)
    setcolor(c, a)
    love.graphics.circle("fill", x, y, r)
    setcolor()
end

function spr(i, n, x, y, w, h, flip_x, flip_y, scale_x, scale_y, c, a)
    w = w and floor(w) or 1
    h = h and floor(h) or 1

    flip_x = flip_x and -1 or 1
    flip_y = flip_y and -1 or 1
    scale_x = mid(1, floor(scale_x or 1), 4)
    scale_y = mid(1, floor(scale_y or 1), 4)

    local sx = floor((n - 1) % spritesPerRow) * SPR_SIZE
    local sy = floor((n - 1) / spritesPerRow) * SPR_SIZE
    local sw = SPR_SIZE * w
    local sh = SPR_SIZE * h

    local ox = flip_x == -1 and sw or 0
    local oy = flip_y == -1 and sh or 0

    setcolor(c, a)
    love.graphics.draw(
        spriteSheetImages[i],
        love.graphics.newQuad(sx, sy, sw, sh, sheetWidth, sheetHeight),
        x, y,
        0,
        flip_x * scale_x,
        flip_y * scale_y,
        ox,
        oy
    )
    setcolor()
end

function fillsp(i, n, x, y, w, h, gap_x, gap_y, c, a)
    w = floor(w or 1)
    h = floor(h or 1)

    gap_x = floor(gap_x or 0)
    gap_y = floor(gap_y or 0)

    x = floor(x or 0)
    y = floor(y or 0)

    local step_x = (1 + gap_x) * SPR_SIZE
    local step_y = (1 + gap_y) * SPR_SIZE

    for ty = 0, h - 1 do
        for tx = 0, w - 1 do
            spr(
                i,
                n,
                x + tx * step_x,
                y + ty * step_y,
                1,
                1,
                false,
                false,
                1,
                1,
                c,
                a
            )
        end
    end
end

function map(i, cel_x, cel_y, sx, sy, cel_w, cel_h)
    i = floor(i or 1)
    local mapdata = maps[i]
    if not mapdata then return end

    cel_x = floor(cel_x or 1)
    cel_y = floor(cel_y or 1)
    sx    = floor(sx or 0)
    sy    = floor(sy or 0)

    cel_w = floor(cel_w or (MAP_WIDTH_TILES  - cel_x + 1))
    cel_h = floor(cel_h or (MAP_HEIGHT_TILES - cel_y + 1))

    for my = 0, cel_h - 1 do
        local ty = cel_y + my
        if ty >= 1 and ty <= MAP_HEIGHT_TILES then
            local row = mapdata[ty]
            if row then
                for mx = 0, cel_w - 1 do
                    local tx = cel_x + mx
                    if tx >= 1 and tx <= MAP_WIDTH_TILES then
                        local tile = row[tx]
                        if tile then
                            local sheet  = tonumber(tile.sheet)  or 0
                            local sprite = tonumber(tile.sprite) or 0

                            if sprite ~= 0 then
                                spr(
                                    sheet,
                                    sprite,
                                    sx + mx * SPR_SIZE,
                                    sy + my * SPR_SIZE
                                )
                            end
                        end
                    end
                end
            end
        end
    end
end
--#endregion

--#region time
timer = {
    list = {}
}

local function newTime()
    return {
        startTime = love.timer.getTime(),
        pauseTime = 0,
        offset    = 0,
        paused    = false
    }
end

local function normIndex(i)
    i = (type(i) == "number") and i or 1
    return mid(1, i, 64)
end

function timer:create(i)
    i = normIndex(i)
    self.list[i] = newTime()
end

function timer:get(i)
    i = normIndex(i)
    local t = self.list[i]
    if not t then return 0 end

    if t.paused then
        return t.pauseTime
    end

    return love.timer.getTime() - t.startTime + t.offset
end

function timer:pause(i)
    i = normIndex(i)
    local t = self.list[i]
    if not t or t.paused then return end

    t.pauseTime = self:get(i)
    t.paused = true
end

function timer:resume(i)
    i = normIndex(i)
    local t = self.list[i]
    if not t or not t.paused then return end

    t.startTime = love.timer.getTime()
    t.offset    = t.pauseTime
    t.paused    = false
end

--#endregion

--#region status
function stat(n)
    if n == 1 then
        return love.timer.getFPS()
    elseif n == 2 then
        return collectgarbage("count")
    elseif n == 3 then
        return love.graphics.getWidth()     
    elseif n == 4 then
        return love.graphics.getHeight()
    elseif n == 5 then
        return love.system.getOS()
    elseif n == 6 then -- Seconds after application started
        return love.timer.getTime()
    elseif n == 7 then -- Local time as table        
        return os.date("*t")
    elseif n == 8 then -- UTC time as table
        return os.date("!*t")
    elseif n == 9 then
        return { x = VIRTUAL_WIDTH,  y = VIRTUAL_HEIGHT}
    elseif n == 10 then
        return { x = window_width,  y = window_height, scale = scale, ofx = offsetX,  ofy = offsetY }
    elseif n == 11 then -- IP Local (example: 192.168.100.186)
        local s = socket.udp()
        s:setpeername("8.8.8.8", 80)
        local ip, _ = s:getsockname()
        s:close()
        return ip or "127.0.0.1"
    else
        return nil
    end
end
--#endregion

--#region buttons
-- Keyboard mapping
local joysticks = love.joystick.getJoysticks()
local joy = joysticks[1]

local btnKeys = {
    [0] = {"left","a"}, -- left
    [1] = {"right","d"}, -- right
    [2] = {"up","w"}, -- up
    [3] = {"down","s"}, -- down
    [4] = {"lshift","x"}, -- b
    [5] = {"z"}, -- a
    [6] = {"space","c"}, -- x
    [7] = {"b","v"}, -- y
    [8] = {"return"} -- start
}

local joyKeys = {
    [0] = 16, -- left
    [1] = 17, -- right
    [2] = 14, -- up
    [3] = 15, -- down
    [4] = 1, -- b
    [5] = 2, -- a
    [6] = 3, -- x
    [7] = 4, -- y
    [8] = 10 -- start
}

local prevKeys = {}
local prevMouseLeft, prevMouseRight = false, false

local function validateexit()
    -- select to exit
    if joy and joy:isDown(9) then
        exit()
    end
end

local function updatePrevKeys()
    prevKeys = {}

    if joy then
        for i = 0, 8 do
            prevKeys[i] = joy:isDown(joyKeys[i])
        end
    else
        for i = 0, 8 do
            for _, key in ipairs(btnKeys[i]) do
                if love.keyboard.isDown(key) then
                    prevKeys[i] = true
                    break
                end
            end
        end

        prevMouseLeft  = love.mouse.isDown(1)
        prevMouseRight = love.mouse.isDown(2)
    end
end

function mouse()
    local x, y = love.mouse.getPosition()
    x = floor((x - offsetX) / scale)
    y = floor((y - offsetY) / scale)
    local left  = love.mouse.isDown(1)
    local right = love.mouse.isDown(2)
    return {
        x = x,
        y = y,
        l = left,
        r = right,
        lp = left and not prevMouseLeft,
        rp = right and not prevMouseRight,
    }
end

function btn(n)
    if joy then
        local key = joyKeys[n]
        if not key then return false end

        if joy:isDown(key) then
            return true
        end
    else
        local keys = btnKeys[n]
        if not keys then return false end

        for i = 1, #keys do
            if love.keyboard.isDown(keys[i]) then
                return true
            end
        end
    end
end

function btnp(n)
    if joy then
        local key = joyKeys[n]
        if not key then return false end

        if joy:isDown(key) and not prevKeys[n] then
            return true
        end
    else
        local keys = btnKeys[n]
        if not keys then return false end

        for i = 1, #keys do 
            if love.keyboard.isDown(keys[i]) and not prevKeys[n] then
                return true
            end
        end
    end
end
--#endregion

--#region save game
local cartDataName = "cartdata_"

function cdata(name)
    if cartDataName ~= "cartdata_" then
        error("calling cdata function multiple times")
        return
    end

    cartDataName = cartDataName .. name
end

function gdata(index)
    if cartDataName == "cartdata_" then
        error("call cdata function to set name of cart data")
        return
    end

    createIfDoesntExist(cartDataName, emptycartdata)

    local lines = loadFile(cartDataName)
    local lineIndex = 1
    for line in lines do
        if lineIndex == index then
            return line
        end
        lineIndex = lineIndex + 1
    end

    return ""
end

function sdata(index, value)
    index = (index ~= nil and type(index) == "number") and index or ""

    if cartDataName == "cartdata_" then
        error("call cdata function to set name of cart data")
        return
    end

    createIfDoesntExist(cartDataName, emptycartdata)

    local lines = loadFile(cartDataName)
    local lineIndex = 1
    local newLines =  {}
    for line in lines do
        if lineIndex == index then
            add(newLines, value)
        else
            add(newLines, line)
        end
        lineIndex = lineIndex + 1        
    end

    local content = table.concat(newLines, "\n")
    saveFile(cartDataName, content)
end
--#endregion

--#region networking
local netHost = nil
local netServerPeer = nil
local netAddress = nil

_netevent = function(_) end

function createserver(ip)
    if not hasEnet then
        return false, "enet module not found"
    end

    ip = (type(ip) == "string" and ip ~= "") and ip or "0.0.0.0:6789"
    netAddress = ip
    netServerPeer = nil
    netHost = enet.host_create(ip)

    if not netHost then
        return false, "failed to start server on " .. ip
    end

    return true
end

function connecttoserver(ip)
    if not hasEnet then
        return false, "enet module not found"
    end

    ip = (type(ip) == "string" and ip ~= "") and ip or netAddress or "127.0.0.1:6789"
    netAddress = ip
    netHost = enet.host_create()

    if not netHost then
        return false, "failed to create client host"
    end

    netServerPeer = netHost:connect(ip)
    return netServerPeer ~= nil, netServerPeer and nil or ("failed to connect to " .. ip)
end

local function updatenetwork()
    if not netHost then return end

    local event = netHost:service(0)
    while event do
        if type(_netevent) == "function" then
            _netevent(event)
        end
        event = netHost:service()
    end
end
--#endregion

--#region main
_init = function() end
_update = function(dt) end
_draw = function() end

function love.resize(w, h)
    window_width = w
    window_height = h
    updateScale()
end

function updateScale()
    local scaleXRaw = floor(window_width / VIRTUAL_WIDTH)
    local scaleYRaw = floor(window_height / VIRTUAL_HEIGHT)
    scale = min(scaleXRaw, scaleYRaw)
    offsetX = floor((window_width - VIRTUAL_WIDTH * scale) / 2)
    offsetY = floor((window_height - VIRTUAL_HEIGHT * scale) / 2)
end

function love.load()
    local icon = love.image.newImageData("icon.png")
    love.window.setIcon(icon)
    love.window.setTitle("LuaES")
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setMode(window_width, window_height, {resizable = true, fullscreen = false, minwidth = VIRTUAL_WIDTH, minheight = VIRTUAL_HEIGHT, vsync = 1})
    font(1)
    updateScale()
    loadsfxdata()
    loadspritesheetdata()
    loadmapsdata()
    loadflagsdata()
    _init()
    updatespritesheetimages()
end

function love.update(dt)
    rerenderImage = { false, false, false, false, false, false, false, false }
    _update(dt)
    updatenetwork()
    updatesfx(dt)
    updatemusic()
    updatespritesheetimages()
    updatePrevKeys()
    validateexit()
end

function love.draw()
    love.graphics.clear(0, 0, 0)
    love.graphics.setScissor(offsetX, offsetY, scale*VIRTUAL_WIDTH, scale*VIRTUAL_HEIGHT)
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)

    _draw()

    love.graphics.pop()
    love.graphics.setScissor()
end

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	if love.timer then love.timer.step() end

	local dt = 0
	local TARGET_FPS = 60
	local FRAME_TIME = 1 / TARGET_FPS

	return function()
		local frameStart = love.timer and love.timer.getTime() or 0

		-- Process events
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt
		if love.timer then dt = love.timer.step() end

		if love.update then love.update(dt) end

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then love.draw() end

			love.graphics.present()
		end

		-- FPS cap
		if love.timer then
			local frameEnd = love.timer.getTime()
			local frameDuration = frameEnd - frameStart
			local sleepTime = FRAME_TIME - frameDuration

			if sleepTime > 0 then
				love.timer.sleep(sleepTime)
			end
		end
	end
end

function exit()
    love.event.quit()
end

function save()
    savesfxdata()
    savespritesheetdata()
    savemapsdata()
    saveflagsdata()
end
--#endregion

-- All functions
-- -- table --
-- add     = add,
-- del     = del,
-- foreach = foreach,
-- all     = all,
-- -- math --
-- mid    = mid,
-- sgn    = sgn,
-- abs    = abs,
-- floor  = floor,
-- ceil   = ceil,
-- rnd    = rnd,
-- srnd   = srnd,
-- sqrt   = sqrt,
-- sin    = sin,
-- cos    = cos,
-- atan2  = atan2,
-- max    = max,
-- min    = min,
-- band   = band,
-- bor    = bor,
-- bxor   = bxor,
-- shl    = shl,
-- shr    = shr,
-- -- sfx --
-- sfx    = sfx,
-- ssfx   = ssfx,
-- music  = music,
-- smusic = smusic,
-- -- font --
-- font = font,
-- -- system --
-- stat = stat,
-- save = save,
-- exit = exit,
-- -- save game --
-- sdata = sdata,
-- gdata = gdata,
-- cdata = cdata,
-- -- camera --
-- camera = camera,
-- resetcamera = resetcamera,
-- -- sprite --
-- spixel = spixel,
-- gpixel = gpixel,
-- -- map --
-- mget = mget,
-- mset = mset,
-- -- flags --
-- fget = fget,
-- fset = fset,
-- -- draw --
-- print = print,
-- rect = rect,
-- rectfill = rectfill,
-- line = line,
-- circ = circ,
-- circfill = circfill,
-- spr = spr,
-- fillsp = fillsp,
-- map = map,
-- -- time --
-- timer = timer,
-- -- input --
-- btn = btn,
-- btnp = btnp,
-- mouse = mouse,
-- -- networking --
-- createserver = createserver,
-- connecttoserver = connecttoserver,
-- _netevent = _netevent,
-- -- loop --
-- _init = _init,
-- _update = _update,
-- _draw = _draw,