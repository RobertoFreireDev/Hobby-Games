-- ── Particle helpers (unchanged) ─────────────────────────────────────────────

function raindrop()
    part(
        math.random(0,240), 0,
        2.0, 1, 1, 1,
        nil,
        { vy = 150, maxY = 150 }
    )
end

function orbitingmagicparticle()
    part(
        140, 120,
        1.2, 1, 1, 2,
        nil, nil,
        { cx = 120, cy = 120, angle = 0, av = 180 }
    )
end

function fire()
    part(
        220, 100,
        1.5, 1, 4, 0,
        {
            sprIdxs  = {1,1,1,1,1,1,1,1},
            sprSizes = {1,2,2,3,2,2,1,1},
        },
        { vx = math.random(-10,10), vy = -40, ay = -5 }
    )
end

function explosion()
    for i = 1, 50 do
        part(
            100, 100,
            0.8, 1, 1, 2,
            nil,
            { vx = math.random(-100,100), vy = math.random(-100,100) }
        )
    end
end

function comet()
    part(
        10, 60,
        2.0, 1, 2, 3,
        {
            sprIdxs  = {1,1,1,1,1,1,1,1},
            sprSizes = {3,3,2,2,2,1,1,1},
        },
        {
            { vx=200, vy= -20, ax=-30, ay=  5, maxX=200, maxY=40 },
            { vx=170, vy= -15, ax=-25, ay=  5, maxX=170, maxY=40 },
            { vx=140, vy= -10, ax=-20, ay=  8, maxX=140, maxY=40 },
            { vx=110, vy=   0, ax=-15, ay= 10, maxX=110, maxY=40 },
            { vx= 80, vy=  10, ax=-10, ay=  8, maxX= 80, maxY=40 },
            { vx= 50, vy=  15, ax= -8, ay=  5, maxX= 50, maxY=30 },
            { vx= 20, vy=  10, ax= -5, ay=  2, maxX= 20, maxY=20 },
            { vx=  5, vy=   5, ax=  0, ay=  0, maxX=  5, maxY=10 },
        }
    )
end

function spiralburst()
    local cx, cy = 120, 120
    for i = 1, 12 do
        local angle0 = (i - 1) * (360 / 12)
        local r = 30
        local sx = cx + r * math.cos(math.rad(angle0))
        local sy = cy + r * math.sin(math.rad(angle0))
        part(
            sx, sy,
            2.0, 1, 1, 4,
            {
                sprIdxs  = {1,1,1,1,1,1,1,1},
                sprSizes = {1,1,2,2,2,1,1,1},
            },
            nil,
            {
                { cx=cx, cy=cy, angle=angle0,      av= 60,  aa=20, maxAv=300 },
                { cx=cx, cy=cy, angle=angle0+ 60,  av= 90,  aa=25, maxAv=300 },
                { cx=cx, cy=cy, angle=angle0+120,  av=130,  aa=30, maxAv=300 },
                { cx=cx, cy=cy, angle=angle0+180,  av=175,  aa=35, maxAv=300 },
                { cx=cx, cy=cy, angle=angle0+240,  av=220,  aa=35, maxAv=300 },
                { cx=cx, cy=cy, angle=angle0+285,  av=260,  aa=25, maxAv=300 },
                { cx=cx, cy=cy, angle=angle0+315,  av=290,  aa=10, maxAv=300 },
                { cx=cx, cy=cy, angle=angle0+345,  av=300,  aa= 0, maxAv=300 },
            }
        )
    end
end

-- ── IDs ──────────────────────────────────────────────────────────────────────

local elementPixel = 0
local elementAnim  = 1

local TWEEN_SCALE = 1
local TWEEN_ANGLE = 2

-- Path IDs
local PATH_ENTITY   = 1   -- "something" follows a curved patrol route
local PATH_ENTITY2  = 2   -- "something2" bounces back and forth (pingpong)
local PATH_COMET    = 3   -- drives comet spawn position each frame

-- ── Path definitions ─────────────────────────────────────────────────────────

-- Curved patrol loop for "something" (shape=1 small curve, ease-in/out, loop)
local patrol_points = {
    { x =  30, y =  80 },
    { x = 120, y =  40 },
    { x = 210, y =  80 },
    { x = 210, y = 160 },
    { x = 120, y = 200 },
    { x =  30, y = 160 },
}

-- Horizontal pingpong for "something2" (shape=0 linear, ease-out, pingpong)
local pingpong_points = {
    { x =  20, y = 120 },
    { x = 220, y = 120 },
}

-- Curved arc the comet spawns from each time btn(0) is held
-- (path drives where the comet origin is, not the comet itself)
local comet_spawn_points = {
    { x =  10, y =  30 },
    { x = 120, y =  10 },
    { x = 230, y =  50 },
}

-- ── Init ─────────────────────────────────────────────────────────────────────

function _init()
    scene_create("menu")
    scene_create("game")
    scene_set("menu")

    entity_create("something",  100, 120, 1)
    entity_create("something2", 100, 120, 0)
    entity_set_activeelements("something",  3)
    entity_set_activeelements("something2", 3)
    entity_create_anim("something2", elementAnim, 2)
    scene_attach_entity("menu", "something")
    scene_attach_entity("menu", "something2")

    -- PATH_ENTITY: "something" patrols a smooth loop, 5 s, ease-in/out, loop
    path(PATH_ENTITY, patrol_points, 5.0, 3, true, false, 1)

    -- PATH_ENTITY2: "something2" pingpongs across the screen, 1.5 s, ease-out
    path(PATH_ENTITY2, pingpong_points, 1.5, 2, true, true, 0)

    -- PATH_COMET: slow arc used as the comet spawn origin, 4 s, linear, loop
    path(PATH_COMET, comet_spawn_points, 4.0, 0, true, false, 2)
end

-- ── Update ───────────────────────────────────────────────────────────────────

function _update()

    -- ── btn(0): scale tween + raindrop + comet from path-driven origin ───
    if btn(0) then
        sfx(21); sfx(10)
        pal()
        entity_change_color("something", 8, 0)
        tween(TWEEN_SCALE, 1, 4, 0.6, 6)
        raindrop()

        -- Comet always spawns from wherever PATH_COMET currently is
        local spawn = path(PATH_COMET)
        part(
            spawn.x, spawn.y,
            2.0, 1, 2, 3,
            {
                sprIdxs  = {1,1,1,1,1,1,1,1},
                sprSizes = {3,3,2,2,2,1,1,1},
            },
            {
                { vx=200, vy=-20, ax=-30, ay= 5, maxX=200, maxY=40 },
                { vx=170, vy=-15, ax=-25, ay= 5, maxX=170, maxY=40 },
                { vx=140, vy=-10, ax=-20, ay= 8, maxX=140, maxY=40 },
                { vx=110, vy=  0, ax=-15, ay=10, maxX=110, maxY=40 },
                { vx= 80, vy= 10, ax=-10, ay= 8, maxX= 80, maxY=40 },
                { vx= 50, vy= 15, ax= -8, ay= 5, maxX= 50, maxY=30 },
                { vx= 20, vy= 10, ax= -5, ay= 2, maxX= 20, maxY=20 },
                { vx=  5, vy=  5, ax=  0, ay= 0, maxX=  5, maxY=10 },
            }
        )
    end

    -- ── btn(1): explosion + fire + spiralburst, then pause "something" path
    if btnp(1) then
        sfx(12, 1)
        entity_change_color("something2", 5, 8)
        entity_set_rectanim("something2", elementAnim, true, 5, 5, 20, 20, 5)
        fire()
        explosion()
        spiralburst()
        path_pause(PATH_ENTITY)    -- freeze patrol on impact
    end

    -- ── btn(2): resume the patrol path ───────────────────────────────────
    if btnp(2) then
        path_resume(PATH_ENTITY)
    end

    -- ── btn(3): restart patrol from the beginning ─────────────────────────
    if btnp(3) then
        path_restart(PATH_ENTITY)
    end

    -- ── btn(4): snap "something" to midpoint of its patrol ───────────────
    if btnp(4) then
        path_position(PATH_ENTITY, 0.5)
    end

    -- ── Move entities along their paths ──────────────────────────────────
    local pos1 = path(PATH_ENTITY)
    local pos2 = path(PATH_ENTITY2)

    -- Scale tween still drives the sprite size
    local scale = tween(TWEEN_SCALE).value
    if scale > 0 then
        entity_set_sprite("something", elementPixel,
            1,
            math.floor(pos1.x), math.floor(pos1.y),
            7,
            math.floor(scale),
            2, 4, false, false)
    end

    -- "something2" rides the pingpong path; leave its anim in place
    entity_set_sprite("something2", elementPixel,
        1,
        math.floor(pos2.x), math.floor(pos2.y),
        0,
        1, 1, 1, false, false)

    -- Spawn orbiting particles that trail "something" as it patrols
    orbitingmagicparticle_at(pos1.x, pos1.y)
end

-- Variant of orbitingmagicparticle that orbits around a given point
function orbitingmagicparticle_at(cx, cy)
    part(
        cx + 10, cy,
        0.8, 1, 1, 2,
        nil, nil,
        { cx = cx, cy = cy, angle = 0, av = 240 }
    )
end