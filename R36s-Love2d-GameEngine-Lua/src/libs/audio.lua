local floor = math.floor
local sin   = math.sin
local pi    = math.pi
local exp   = math.exp
local rate  = 22050

local notes = {}
do
    local A4 = 440.0
    local names = {"C","Cs","D","Ds","E","F","Fs","G","Gs","A","As","B"}
    for n = 12, 131 do
        local freq = A4 * 2 ^ ((n - 69) / 12)
        local octave = floor(n / 12) - 1
        notes[names[n % 12 + 1] .. octave] = freq
    end
end

local EFFECTS = {
    [1] = { slide = { depth = 12, speed = 3 } },
    [2] = { vibrato = { depth = 0.02, speed = 6 } },
    [3] = { drop = 2.0 },
    [4] = { fade_in = 0.04, fade_out = 0.01 },
    [5] = { fade_in = 0.01, fade_out = 0.04 },
    [6] = { arp = {0,4,7}, arpSpeed = 0.03 },
    [7] = { arp = {0,4,7}, arpSpeed = 0.12 },
    [8] = { tremolo = { depth = 0.8, speed = 6 } },
}

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

local noiseValue   = 0
local noiseCounter = 0
local noiseRate    = 32

local function sampleWave(phase, wave)
    if wave == "square" then
        return (sin(phase) > 0) and 0.4 or -0.4

    elseif wave == "triangle" then
        return (2 / pi) * math.asin(math.sin(phase - pi/2))

    elseif wave == "saw" then
        return (2 * ((phase / (2*pi)) % 1) - 1)*0.5

    elseif wave == "tilted saw" then
        local t = (phase / (2*pi)) % 1
        return t < 0.5 and (-1 + t*4) or (1 - (t-0.5)*2)

    elseif wave == "pulser" then
        local step = floor(phase * 32 / (2*pi)) % 32
        local duty = 6
        return (step < duty) and 0.4 or -0.4

    elseif wave == "organ" then
        return (
            1.00 * sin(phase) +
            0.50 * sin(phase*2) +
            0.30 * sin(phase*3) +
            0.20 * sin(phase*4) +
            0.10 * sin(phase*6)
        ) * 0.5

    elseif wave == "phaser" then
        local lfo = 0.5 * sin(phase * 0.5 + pi/2)
        return sin(phase + lfo * 3)

    elseif wave == "noise" then
        noiseCounter = noiseCounter + 1
        if noiseCounter >= noiseRate then
            noiseCounter = 0
            noiseValue = love.math.random() * 2 - 1
        end
        return noiseValue * 0.5
    end

    return 0
end

local function genMusic(pattern, fadeLength)
    fadeLength = fadeLength or 1/40

    local totalLen = 0
    for _, n in ipairs(pattern) do
        totalLen = totalLen + (n.length or 1) / 32
    end

    local sampleCount = floor(totalLen * rate)
    local soundData = love.sound.newSoundData(sampleCount, rate, 16, 1)

    local dt = 1 / rate
    local t  = 0

    local noteIndex = 1
    local noteTime  = 0

    -- current note state
    local curPhase = 0
    local curNote  = pattern[1]

    -- previous note state (for fade-out)
    local prevNote, prevPhase, prevTime

    for i = 0, sampleCount - 1 do
        local noteLen = (curNote.length or 1) / 32

        -- advance note
        if noteTime >= noteLen and noteIndex < #pattern then
            -- move current to previous
            prevNote  = curNote
            prevPhase = curPhase
            prevTime  = 0

            noteIndex = noteIndex + 1
            curNote   = pattern[noteIndex]
            curPhase  = curPhase -- keep phase continuity
            noteTime  = 0
        end

        local function renderNote(note, phase, noteTime)
            local freq = type(note.tone) == "string" and notes[note.tone] or note.tone or 440
            local effects = EFFECTS[note.effects or 0] or {}

            if effects.arp then
                local step = floor(t / (effects.arpSpeed or 0.05))
                local semi = effects.arp[(step % #effects.arp) + 1]
                freq = freq * (2 ^ (semi / 12))
            end

            if effects.slide then
                local bubble = exp(-noteTime * effects.slide.speed)
                freq = freq * (2 ^ ((effects.slide.depth * bubble) / 12))
            end

            if effects.drop then
                freq = freq * exp(-effects.drop * noteTime)
            end

            if effects.vibrato then
                freq = freq * (1 + sin(t * effects.vibrato.speed * 2*pi) * effects.vibrato.depth)
            end

            phase = phase + 2 * pi * freq * dt
            local v = sampleWave(phase, WAVES[note.waveType] or "square")

            return v, phase
        end

        local sample = 0

        -- current note (fade in)
        do
            local v
            v, curPhase = renderNote(curNote, curPhase, noteTime)

            local env = math.min(noteTime / fadeLength, 1)
            sample = sample + v * env * (curNote.volume or 1)
        end

        -- previous note (fade out)
        if prevNote then
            local v
            v, prevPhase = renderNote(prevNote, prevPhase, prevTime)

            local env = math.max(1 - prevTime / fadeLength, 0)
            sample = sample + v * env * (prevNote.volume or 1)

            prevTime = prevTime + dt
            if prevTime >= fadeLength then
                prevNote = nil
            end
        end

        soundData:setSample(i, sample)

        t = t + dt
        noteTime = noteTime + dt
    end

    return love.audio.newSource(soundData)
end

return {
    genMusic = genMusic
}