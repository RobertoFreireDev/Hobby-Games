g = {
    x = 1024,
    y = 576
}

p = {
    x = 80,
    y = 250,
    w = 32,
    h = 32,
    b = { -- collision box
        x = 4,
        y = 7,
        w = 26,
        h = 20,
    },
    s = 0, -- initial speed (starts at 0)
    maxSpeed = 3, -- maximum speed forward
    minSpeed = -2, -- maximum speed backward (negative value for reverse)
    acceleration = 0.1, -- how quickly the car accelerates
    deceleration = 0.2, -- how quickly the car decelerates when no input is given
    rotation = -90, -- car's current rotation (in radians)
    rotationSpeed = 2, -- speed of rotation
    spt = 1, -- sprite
}

function _init()
end

function _update()
    -- Rotate the car only when moving (forward or backward)
    if p.s ~= 0 then
        if button(0) then p.rotation = p.rotation - p.rotationSpeed end -- rotate left
        if button(2) then p.rotation = p.rotation + p.rotationSpeed end -- rotate right
    end

    -- Accelerate forward
    if button(1) then 
        if p.s < p.maxSpeed then
            p.s = p.s + p.acceleration -- increase speed up to maxSpeed
        end
    end

    -- Decelerate backward
    if button(3) then 
        if p.s > p.minSpeed then
            p.s = p.s - p.acceleration -- decrease speed (in reverse) down to minSpeed
        end
    end

    -- Apply deceleration when no input is given
    if not button(1) and not button(3) then
        if p.s > 0 then
            p.s = p.s - p.deceleration -- slow down if moving forward
            if p.s < 0 then p.s = 0 end -- stop completely when speed goes below 0
        elseif p.s < 0 then
            p.s = p.s + p.deceleration -- slow down if moving backward
            if p.s > 0 then p.s = 0 end -- stop completely when speed goes above 0
        end
    end

    -- Calculate movement based on rotation
    local rotationAngle = math.rad(p.rotation)
    local moveX = math.cos(rotationAngle) * p.s
    local moveY = math.sin(rotationAngle) * p.s

    -- Move the car, checking for collisions
    if not collidetilewithrect(p.x + moveX + p.b.x, p.y + p.b.y, p.b.w, p.b.h,1) then
        p.x = p.x + moveX
    end
    if not collidetilewithrect(p.x + p.b.x, p.y + moveY + p.b.y, p.b.w, p.b.h,1) then
        p.y = p.y + moveY
    end
end

function _draw()
    cameragrid(p.x, p.y)
    drawmap(0)
    drawmap(1)
    drawmap(2)
    drawsprite(p.x, p.y, p.spt, p.rotation, false, false)
end