require("Scripts/library")
require("Scripts/constants")
require("Scripts/component")
require("Scripts/helperfunctions")

local spriteeditor = require("Scripts/spriteeditor")
local sfxeditor = require("Scripts/sfxeditor")
local mapeditor = require("Scripts/mapeditor")
local tutorialeditor = require("Scripts/tutorialeditor")
local game = require("Scripts/game")

buttonSelected = nil
buttons = {}
state = {}
showmenu = true

local spriteFileName, mapFileName, flagFileName, sfxFileName = "spritedata", "mapData", "flagData", "sfxData"

function change_state(st)
    state=st
    state:init()
end

function changepage(p, o)
    change_state(p)
    buttonSelected = o
end

function _init()   
    _fps30()
    _ngrid(30,(const.maxPage+1)*4,10,true)
    _cmap(320,180,10)
    if _iohasfile(spriteFileName) then
        _sgrid(_ioread(spriteFileName))
    end
    if _iohasfile(mapFileName) then
        _lmap(_ioread(mapFileName))
    end
    if _iohasfile(flagFileName) then
        _loadflags(_ioread(flagFileName))
    end
    if _iohasfile(sfxFileName) then
        _loadsfx(sfxFileName)
    end
    
    buttons = {}
    _limg(0,10,10,"iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAMAAABHPGVmAAAAAXNSR0IArs4c6QAAAGBQTFRFAAAAIiA0RSg8Zjkxj1Y733Em2aBm7sOa+/I2meVQar4wN5RuS2kvUkskMjw5Pz90MGCCW27hY5v/X83ky9v8////m623hH6HaWpqWVZSdkKKrDIy2Vdj13u6j5dKim8w+2O8zwAAACB0Uk5TAP////////////////////////////////////////+Smq12AAAB6ElEQVRoge1YAY7DIAzjE/7/V0+6tsFOQumQ2E63eNKKKMQ4JJCttfcA9mWP6RQAbi7OD7eYA806r8lHO7Mopo83jiQq+H0ALZKAnpBJ6J1zJXBc6q6UBH09Q5JMi7prQmJLpReXz6ISHHik5PQhlGiuBA1ZhFAnPc/F0HZ5+7kSkJkjfDAmUefq63slj3PiM4Dh5XnW4u5u8bIeAsCigmI05+DoCoknTShJrogCU411E5KrdCyEiSCdmgh9rGZbD/4scaYkqoQD9+rBZT2saZkEfUAiRI2vuiso4R3xHIsbn+wJO85xrIVwFl0vYjUZP2u6u2tCsrKCftsMSNzpEwJmYvshCcV4JPHBqTOekTiyQOKut0USmxLHuYsu2aUXSOJSE8/kr5ntlqSP5AkhmZ9F284QHlvZkYx/FBsF+yTyObsTWTLmB0E8r+KgVImLasqt2LQqXq8rM36jA7JA2KrImULCtYCVvbhOmMmeJKVC6/RXJlotADXovR20DF/NAHVeGyv5DhzbsEdyj7OdQI9lUjKsEEOO6XJjkRgH2viEhDM2kR7NJSSsJK81ISPbWfe6cyi94huCb+RHrTgEOoNIeM2Dn2EQJcN/MwqF7wL/07atiHkLSaFQKBQKhUKhUCgUCoXCf8QPX3xXc4WuQQoAAAAASUVORK5CYII=")
    _limg(1,10,10,"iVBORw0KGgoAAAANSUhEUgAAAUAAAAC0CAMAAADSOgUjAAAAAXNSR0IArs4c6QAAAGBQTFRFAAAAIiA0RSg8Zjkxj1Y733Em2aBm7sOa+/I2meVQar4wN5RuS2kvUkskMjw5Pz90MGCCW27hY5v/X83ky9v8////m623hH6HaWpqWVZSdkKKrDIy2Vdj13u6j5dKim8w+2O8zwAAACB0Uk5TAP////////////////////////////////////////+Smq12AAABAUlEQVR4nO3SMQ0AMAzAsJIof6oD0SPHLBPIkdnhYvIC/uZAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlQFoOpOVAWg6k5UBaDqTlwKMHvBM7COSTH1YAAAAASUVORK5CYII=")
    spritebutton = new_button(0,0,_colors.primary,10,0,0,0,0,10,10)
    spritebutton.clicked = function(o) changepage(spriteeditor, o) end
    mapbutton = new_button(0,1,_colors.primary,10,0,10,0,0,10,10)
    mapbutton.clicked = function(o) changepage(mapeditor, o) end
    sfxbutton = new_button(0,2,_colors.primary,10,0,20,0,0,10,10)
    sfxbutton.clicked = function(o) change_state(sfxeditor) buttonSelected = o end
    tutorialbutton = new_button(0,27,_colors.primary,10,0,30,0,0,10,10)
    tutorialbutton.clicked = function(o) changepage(tutorialeditor, o) end
    gamebutton = new_button(0,18,_colors.primary,10,0,40,0,0,10,10)
    gamebutton.clicked = function(o) changepage(game, o) end

    add(buttons,spritebutton)
    add(buttons,mapbutton)
    add(buttons,sfxbutton)
    add(buttons,tutorialbutton)
    add(buttons,gamebutton)

    buttonSelected = spritebutton
    change_state(spriteeditor)
end

function _update()
    if not _isfocused() then
        return
    end

    state:update()

    if (_btn(_keys.LeftControl) or _btn(_keys.RightControl)) and _btnp(_keys.R) then
        _iocreateorupdate(spriteFileName,_ggrid())
        _iocreateorupdate(mapFileName,_gmap())
        _iocreateorupdate(flagFileName,_getflags())
        _savesfx(sfxFileName)
    end

    if _btnp(_keys.F3) then        
        showmenu = not showmenu
    end

    if not showmenu then
        return
    end
    
    foreach(buttons, function(o)
        o:update()
        o.b.c = buttonSelected == o and 1 or _colors.primary
    end)
end

function _draw()
    state:draw()
    if not showmenu then
        return
    end
    _rectfill(0,0,10,180,_colors.secondary)
    foreach(buttons, function(o)
        o.b:draw()
    end)
end