# Joy-8

Game engine for pixel art style

[MenuScene]

<p align="center">
  <img src="./gitimages/menuscene.png?raw=true">
</p>

[TileScene] 

Behavior:
- Add flags

Data:
- Save list of flags. 1 flag value per tile. Save as int (example: 3 = 11000000)

<p align="center">
  <img src="./gitimages/tilescene.png?raw=true">
</p>

[MapScene]

- Arrow keys to move 
- Scroll up/down for zoom
- Select tile of size 1 only
- Draw, Bucket (visible area) and erase tiles

<p align="center">
  <img src="./gitimages/mapscene.png?raw=true">
</p>

[CustomScriptScenes]

- Uses Lua scripts to run each logic and draw on screen
- Add 4 empty custom ScriptScenes

You can use for example for draft

- Pathfinder
- Raycast
- Lighting System (Basic 2D lighting & shadows)
- Shader Support (Custom shaders for effects like water, fire, etc.)
- Tile-Based Collision System
- Pixel-Perfect Collision
- Camera System (Zoom, pan, parallax layers)
- Post-Processing Effects Editor (Control bloom, color grading, screen shake, etc.)
- Weather System Editor (Create rain, snow, fog effects)
- Tween
- UI components
- Dialog box