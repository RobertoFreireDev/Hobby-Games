require("libs/luaes")

local SFX1 = {
  {note="C7", volume = 1,   length=6, wave=6, effect=5},
  {note="C7", volume = 0.8, length=6, wave=6, effect=5},
  {note="C7", volume = 0.7, length=6, wave=6, effect=5},
  {note="C7", volume = 0.6, length=6, wave=6, effect=5},
  {note="C7", volume = 0.4, length=6, wave=6, effect=5},
  {note="C7", volume = 0.4, length=6, wave=6, effect=5},
  {note="G6", volume = 0.8, length=6, wave=6, effect=5},
  {note="G6", volume = 0.6, length=6, wave=6, effect=5},
  {note="C7", volume = 1,   length=6, wave=6, effect=5},
  {note="C7", volume = 0.8, length=6, wave=6, effect=5},
  {note="C7", volume = 0.7, length=6, wave=6, effect=5},
  {note="C7", volume = 0.6, length=6, wave=6, effect=5},
  {note="C7", volume = 0.4, length=6, wave=6, effect=5},
  {note="C7", volume = 0.4, length=6, wave=6, effect=5},
  {note="G6", volume = 0.8, length=6, wave=6, effect=5},
  {note="G6", volume = 0.6, length=6, wave=6, effect=5},
}

local SFX2 = {
  {note="C3", volume = 0.4,   length=6, wave=1, effect=5},
  {note="C3", volume = 0.2, length=6, wave=1, effect=5},
  {note="C3", volume = 0.4, length=6, wave=1, effect=5},
  {note="C3", volume = 0.2, length=6, wave=1, effect=5},
  {note="C3", volume = 0.4, length=6, wave=1, effect=5},
  {note="C3", volume = 0.2, length=6, wave=1, effect=5},
  {note="C3", volume = 0.1, length=6, wave=1, effect=5},
  {note=0, volume = 0.0, length=6, wave=0, effect=5},
  {note="C3", volume = 0.4,   length=6, wave=1, effect=5},
  {note="C3", volume = 0.2, length=6, wave=1, effect=5},
  {note="C3", volume = 0.4, length=6, wave=1, effect=5},
  {note="C3", volume = 0.2, length=6, wave=1, effect=5},
  {note="C3", volume = 0.4, length=6, wave=1, effect=5},
  {note="C3", volume = 0.2, length=6, wave=1, effect=5},
  {note="C3", volume = 0.1, length=6, wave=1, effect=5},
  {note=0, volume = 0.0, length=6, wave=0, effect=5},
}

local SFX3 = {
  {note="Ds2", volume = 0.2,   length=6, wave=7, effect=5},
  {note="C5", volume = 0.1, length=6, wave=7, effect=5},
  {note=0, volume = 0.0, length=6, wave=0, effect=5},
  {note="Ds2", volume = 0.1, length=6, wave=7, effect=5},
  {note="C5", volume = 0.2, length=6, wave=7, effect=5},
  {note="Ds4", volume = 0.1, length=6, wave=7, effect=5},
  {note="As4", volume = 0.2, length=6, wave=7, effect=5},
  {note="Ds2", volume = 0.1, length=6, wave=7, effect=5},
  {note="Ds2", volume = 0.2,   length=6, wave=7, effect=5},
  {note="C5", volume = 0.1, length=6, wave=7, effect=5},
  {note=0, volume = 0.0, length=6, wave=0, effect=5},
  {note="Ds2", volume = 0.1, length=6, wave=7, effect=5},
  {note="C5", volume = 0.2, length=6, wave=7, effect=5},
  {note="Ds4", volume = 0.1, length=6, wave=7, effect=5},
  {note="As4", volume = 0.2, length=6, wave=7, effect=5},
  {note="Ds2", volume = 0.1, length=6, wave=7, effect=5},
}

local SFX4 = {
  {note="Fs6", volume = 1,   length=4, wave=4, effect=0},
  {note="B4", volume = 1, length=4, wave=5, effect=0},
  {note="B5", volume = 1, length=4, wave=4, effect=0},
  {note="F6", volume = 1, length=4, wave=5, effect=0},
  {note="Fs5", volume = 1, length=4, wave=4, effect=0},
  {note="B3", volume = 1, length=4, wave=5, effect=0},
  {note="Ds5", volume = 1, length=4, wave=4, effect=0},
  {note="G3", volume = 1, length=4, wave=5, effect=0},
}

local SFX5 = {
  {note="E3", volume = 1, length=6, wave=3, effect=0},
  {note="E3", volume = 1, length=6, wave=3, effect=0},
  {note="E3", volume = 1, length=6, wave=3, effect=0},
  {note="E3", volume = 1, length=6, wave=3, effect=0},
  {note="E3", volume = 1, length=6, wave=2, effect=0},
  {note="E3", volume = 1, length=6, wave=2, effect=0},
  {note="E3", volume = 1, length=6, wave=2, effect=0},
  {note="E3", volume = 1, length=6, wave=2, effect=0},
}

local SFX6 = {
  {note="Fs2", volume = 0.2, length=6, wave=5, effect=0},
  {note="Gs2", volume = 0.2, length=6, wave=5, effect=0},
  {note="A2", volume = 0.2, length=6, wave=5, effect=0},
  {note="B2", volume = 0.2, length=6, wave=5, effect=0},
  {note="As4", volume = 0.2, length=6, wave=5, effect=0},
  {note="Fs5", volume = 0.2, length=6, wave=5, effect=0},
  {note="C7", volume = 1, length=6, wave=7, effect=0},
  {note="B6", volume = 1, length=6, wave=7, effect=0},
  {note="B6", volume = 1, length=6, wave=7, effect=0},
  {note="A6", volume = 1, length=6, wave=7, effect=0},
  {note="Fs6", volume = 1, length=6, wave=7, effect=0},
  {note="D6", volume = 1, length=6, wave=7, effect=0},
  {note="A5", volume = 1, length=6, wave=7, effect=0},
  {note="E5", volume = 1, length=6, wave=7, effect=0},
  {note="C5", volume = 1, length=6, wave=7, effect=0},
  {note="A4", volume = 1, length=6, wave=7, effect=0},
}

local SFX7 = {
  {note="C7", volume = 1,   length=1, wave=6, effect=5},
  {note="C7", volume = 0.8, length=1, wave=6, effect=5},
  {note="C7", volume = 0.7, length=1, wave=6, effect=5},
  {note="C7", volume = 0.6, length=1, wave=6, effect=5},
  {note="C7", volume = 0.4, length=1, wave=6, effect=5},
  {note="C7", volume = 0.4, length=1, wave=6, effect=5},
  {note="G6", volume = 0.8, length=1, wave=6, effect=5},
  {note="G6", volume = 0.6, length=1, wave=6, effect=5},
}

local SFX8 = { 
  {note="C3", volume = 0.4,   length=1, wave=1, effect=5},
  {note="C3", volume = 0.2, length=1, wave=1, effect=5},
  {note="C3", volume = 0.4, length=1, wave=1, effect=5},
  {note="C3", volume = 0.2, length=1, wave=1, effect=5},
  {note="C3", volume = 0.4, length=1, wave=1, effect=5},
  {note="C3", volume = 0.2, length=1, wave=1, effect=5},
  {note="C3", volume = 0.1, length=1, wave=1, effect=5},
  {note=0, volume = 0.0, length=1, wave=0, effect=5},
}

local SFX9 = {
  {note="Ds2", volume = 0.2,   length=1, wave=7, effect=5},
  {note="C5", volume = 0.1, length=1, wave=7, effect=5},
  {note=0, volume = 0.0, length=1, wave=0, effect=5},
  {note="Ds2", volume = 0.1, length=1, wave=7, effect=5},
  {note="C5", volume = 0.2, length=1, wave=7, effect=5},
  {note="Ds4", volume = 0.1, length=1, wave=7, effect=5},
  {note="As4", volume = 0.2, length=1, wave=7, effect=5},
  {note="Ds2", volume = 0.1, length=1, wave=7, effect=5},
}

local SFX10 = {
  {note="Fs6", volume = 1,   length=1, wave=4, effect=0},
  {note="B4", volume = 1, length=1, wave=5, effect=0},
  {note="B5", volume = 1, length=1, wave=4, effect=0},
  {note="F6", volume = 1, length=1, wave=5, effect=0},
  {note="Fs5", volume = 1, length=1, wave=4, effect=0},
  {note="B3", volume = 1, length=1, wave=5, effect=0},
  {note="Ds5", volume = 1, length=1, wave=4, effect=0},
  {note="G3", volume = 1, length=1, wave=5, effect=0},
}

local SFX11 = {
  {note="E3", volume = 1, length=1, wave=3, effect=0},
  {note="E3", volume = 1, length=1, wave=3, effect=0},
  {note="E3", volume = 1, length=1, wave=3, effect=0},
  {note="E3", volume = 1, length=1, wave=3, effect=0},
  {note="E3", volume = 1, length=1, wave=2, effect=0},
  {note="E3", volume = 1, length=1, wave=2, effect=0},
  {note="E3", volume = 1, length=1, wave=2, effect=0},
  {note="E3", volume = 1, length=1, wave=2, effect=0},
}

local SFX12 = {
  {note="Fs2", volume = 0.2, length=1, wave=5, effect=0},
  {note="Gs2", volume = 0.2, length=1, wave=5, effect=0},
  {note="A2", volume = 0.2, length=1, wave=5, effect=0},
  {note="B2", volume = 0.2, length=1, wave=5, effect=0},
  {note="As4", volume = 0.2, length=1, wave=5, effect=0},
  {note="Fs5", volume = 0.2, length=1, wave=5, effect=0},
  {note="C7", volume = 1, length=1, wave=7, effect=0},
  {note="B6", volume = 1, length=1, wave=7, effect=0},
  {note="B6", volume = 1, length=1, wave=7, effect=0},
  {note="A6", volume = 1, length=1, wave=7, effect=0},
  {note="Fs6", volume = 1, length=1, wave=7, effect=0},
  {note="D6", volume = 1, length=1, wave=7, effect=0},
  {note="A5", volume = 1, length=1, wave=7, effect=0},
  {note="E5", volume = 1, length=1, wave=7, effect=0},
  {note="C5", volume = 1, length=1, wave=7, effect=0},
  {note="A4", volume = 1, length=1, wave=7, effect=0},
}

indexsound = 0
SOUNDINDEX = 5
SOUNDS = {
  {{ play = {1,2,3} }},
  {{ play = {2} } , { stop = true } },
  {{ play = {3} } , { stop = true } },
  {{ play = {4} } , { stop = true } },
  {{ play = {5} } , { stop = true } },
  {{ play = {6} } },
  {{ play = {7} } , { stop = true } },
  {{ play = {8} } , { stop = true } },
  {{ play = {9} } , { stop = true } },
  {{ play = {10} } , { stop = true } },
  {{ play = {11} } , { stop = true } },
  {{ play = {12} } , { stop = true } },
}

function addsounds(s)
  for i=1,#s do
    ssfx(i + indexsound, s[i].note, s[i].volume, s[i].wave, s[i].effect, s[i].length)
  end
  indexsound = indexsound + 16
end

function _init()
  addsounds(SFX1)
  addsounds(SFX2)
  addsounds(SFX3)
  addsounds(SFX4)
  addsounds(SFX5)
  addsounds(SFX6)
  addsounds(SFX7)
  addsounds(SFX8)
  addsounds(SFX9)
  addsounds(SFX10)
  addsounds(SFX11)
  addsounds(SFX12)

  for i=1,#SOUNDS do
    smusic(i,SOUNDS[i])
  end
end

function _update(dt)

    if btnp(4) then
        music(SOUNDINDEX)
    end

    if btnp(1) and SOUNDINDEX < #SOUNDS  then
        SOUNDINDEX = SOUNDINDEX + 1
    elseif btnp(0) and SOUNDINDEX > 1 then
        SOUNDINDEX = SOUNDINDEX - 1
    end
end

function _draw()    
    print("Ifx: " ..SOUNDINDEX, 10, 10, 4)
end