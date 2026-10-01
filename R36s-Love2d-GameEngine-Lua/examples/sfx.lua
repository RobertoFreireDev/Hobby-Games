require("libs/luaes")

local v,l,w,e =1,4,1,4

function addsounds()
  ssfx(1, "C3", v, w, e, l)
  ssfx(2, "C3", v, w, e, l)
  ssfx(3, "C3", v, w, e, l)
  ssfx(4, "C3", v, w, e, l)
  ssfx(5, "C3", v, w, e, l)
  ssfx(6, "C3", v, w, e, l)
  ssfx(7, "C3", v, w, e, l)
  ssfx(8, "C3", v, w, e, l)

  ssfx(17, "C3", v, w, e, l)
  ssfx(18, "D3", v, w, e, l)
  ssfx(19, "E3", v, w, e, l)
  ssfx(20, "F3", v, w, e, l)
  ssfx(21, "G3", v, w, e, l)
  ssfx(22, "A3", v, w, e, l)
  ssfx(23, "B3", v, w, e, l)
  ssfx(24, "C4", v, w, e, l)
end

function _init()
  addsounds()
  smusic(1,{{ play = {1} } , { stop = true }})
  font(2)
end

function _update(dt)
    if btnp(4) then
        sfx(1)
    end

    if btnp(5) then
        sfx(2)
    end

    if btnp(0)  then
        v = v + 0.2
        if v > 1 then
            v = 0
        end
        addsounds()
    end

    if btnp(1)  then
        w = w + 1
        if w == 8 then
            w = 1
        end
        addsounds()
    end

    if btnp(2)  then
        l = l + 2
        if l > 14 then
            l = 1
        end
        addsounds()
    end

    if btnp(3)  then
        e = e + 1
        if e == 8 then
            e = 0
        end
        addsounds()
    end
end

local WAVES = {
    [1] = "triangle",
    [2] = "tilted saw",
    [3] = "saw",
    [4] = "square",
    [5] = "pulser",
    [6] = "organ",
    [7] = "noise",
    [8] = "phaser",
}

local EFFECTS = {
    [0] = "none",
    [1] = "slide",
    [2] = "vibrato",
    [3] = "drop",
    [4] = "fade_in",
    [5] = "fade_out",
    [6] = "fast arp",
    [7] = "slow arp",
    [8] = "tremolo",
}

function _draw()
    print("vol: " ..tostring(v), 10, 40, 3)
    print("time: " ..l, 60, 10, 7)
    print("(z/x)", 60, 40, 4)
    print("wv: " ..WAVES[w], 100, 40, 5)
    print("efx: " ..EFFECTS[e], 60, 80, 6)
end