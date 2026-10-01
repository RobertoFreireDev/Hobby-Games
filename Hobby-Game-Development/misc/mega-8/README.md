# mega-8

# FIRST

First, implement all the logic to run a full game

- all positions x,y to draw are vector2d (not integer). it converts to int to draw
- change spritesheet to 320x64
- add multiple spritesheets 8
- add multiple maps
- add map animations
- add flags
- add music
- add file to save scenes, entity and elements

# adjust animation

- add w and h to be used in sprite in Lua: part(x, y, ttl, sprIdx, sprSize, zIndex [, anim] [, movement] [, rotation])

## Drawing an entity:

- For entities at same ZIndex, if scene has orderbyY flag enabled, draw these entities ordered by position y

# map
- multiple 8 map sheets to draw in layers
- each map sheet size: 8x8 of 320x180
- create animation map list
  - if there is a animation for a map grid position. draw animation instead. example: water moving in a river.
- get tile id from x,y pos
- set tile id in map for grid pos x,y
- create object to draw maps
    - array of 8.
    - each item
        - zindex
        - point to mapindex
        - grid rectangle (what part of the map to draw)
        - Pos x,y to where to draw
        - visible
        - custom palette

# AFTER

# intro

- add intro in c#
  - white border
  - center mega-8 color title
  - no sfx

# boot logic
- load intro
- find all local .mzip8 files
   - if any, show screen to choose
      - select any, load all files from zip
   - if not, do normal flow (main.lua, etc)
