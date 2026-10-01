# NPico8
Build retro games in C# with a PICO-8-style powered by MonoGame

> **Disclaimers:** 

> This project is a runtime/interpreter engine only. It does not include any other author's games. No game code, assets, cartridges, sprites, music, or any other creative content from PICO-8 games are included in this repository. 

> All games referenced here are the intellectual property of their respective authors. To play any of the listed games, obtain the original cartridge files directly from the authors via the links provided.

> This project does not include a full PICO-8 development environment — there are no built-in editors for sprites, maps, or SFX/music. It is intended for running existing cartridges, not creating new ones from within the tool.
Additionally, this is not a complete or fully accurate PICO-8 implementation — not all PICO-8 features have been implemented, and behavior may differ from the official PICO-8 fantasy console in some cases.

Command to publish:

```
- dotnet publish npico8.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```

# Games tested using N8

## LastPilot

- https://www.lexaloffle.com/bbs/?pid=169999

![alt text](img/laspilot.png)

## Bas

- https://www.lexaloffle.com/bbs/?tid=54986

![alt text](img/bas.png)

## Celeste

- https://www.lexaloffle.com/bbs/?tid=2145

![alt text](img/celeste.png)

## Bunny

- https://www.lexaloffle.com/bbs/?tid=48032

![alt text](img/bunny.png)

## Golf 

- https://www.lexaloffle.com/bbs/?tid=38918

![alt text](img/golf.png)

# Functions

## System

- time() — returns elapsed time in seconds
- stat(id) — returns system stats by ID
- load(folder) — loads a cart from a folder
- menuitem(index, label, callback) — adds a pause-menu item with a callback
- menuitem(index) — removes a pause-menu item

## Graphics

- cls(color) — clears the screen to a color (default 0)
- pixel(x, y, color) — draws a single pixel on screen
- line(x0, y0, x1, y1, color) — draws a line
- rect(x0, y0, x1, y1, color) — draws a rectangle outline
- rectfill(x0, y0, x1, y1, color) — draws a filled rectangle
- circ(x, y, radius, color) — draws a circle outline
- circfill(x, y, radius, color) — draws a filled circle
- spr(id, x, y, w, h, scale, flipX, flipY) — draws a sprite from the spritesheet
- sspr(sx, sy, sw, sh, dx, dy, dw, dh, flipX, flipY) — draws a stretched/clipped region from the spritesheet
- print(text, x, y, color) — draws text on screen
- camera(x, y) — sets the camera offset
- pal() — resets the palette
- pal(c0, c1) — remaps color c0 to c1
- palt() — resets transparency flags
- palt(colorIndex) — toggles a color as transparent
- palt(colorIndex, transparent) — explicitly sets a color's transparency

## Map

- mget(cellX, cellY) — gets the sprite ID at a map cell
- mset(cellX, cellY, spriteId) — sets the sprite ID at a map cell
- map(cellX, cellY, screenX, screenY, cellWidth, cellHeight, layerMax, color) — draws a region of the map to screen

## Sprite Flags

- fget(spriteId) — gets all flags for a sprite as a bitmask
- fget(spriteId, flag) — gets a single flag value (bool) for a sprite
- fset(spriteId, flag, value) — sets a single flag on a sprite
- fset(spriteId, value) — sets all flags on a sprite via bitmask

## Input

- btn(button) / btn(button, player) — returns true while a button is held
- btnp(button) / btnp(button, player) — returns true on the frame a button is first pressed
- btnr(button) — returns true on the frame a button is released
- mouseup() / mousedown() — left mouse button up/down state
- mouselp() / mouselr() — left mouse just pressed / just released
- mousel() — left mouse held
- mouserp() / mouserr() — right mouse just pressed / just released
- mouser() — right mouse held
- mousexy() — returns current mouse position as (x, y)

## Audio

- sfx(id, channel, offset, length) — plays a sound effect
- music(id, fadeLength, channelMask) — plays a music track

## Random

- rnd(max) — returns a random float/double/int in [0, max)
- srand(seed) — seeds the random number generator

## Math

- abs(value) — absolute value
- atan2(dy, dx) — angle from two components (0..1 range, PICO-8 style)
- cos(angle) — cosine (0..1 range input)
- sin(angle) — sine (0..1 range input)
- sqrt(value) — square root
- min(a, b) — smaller of two values
- max(a, b) — larger of two values
- mid(a, b, c) — middle/clamped value of three
- flr(value) — floor
- ceil(value) — ceiling
- round(value) — round to nearest integer
- sgn(value) — sign: returns -1, 0, or 1

## Persistence

- dget(index) — reads a saved data value by index
- dset(index, value) — writes a saved data value by index

## Misc

- run() — restarts the cart
