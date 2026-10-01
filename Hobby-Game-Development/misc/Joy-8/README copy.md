# Joy-8

Game engine for pixel art style

[Menu]

<p align="center">
  <img src="./gitimages/menuscene.png?raw=true">
</p>

[SfxScene]

<p align="center">
  <img src="./gitimages/sfxscene.png?raw=true">
</p>

[CustomScriptScenes]

- Uses Lua scripts to run each logic and draw on screen
- 1 music per time. this is why track is static

[TileScene] 

Behavior:
- Add flags

Data:
- Save list of flags. 1 flag value per tile. Save as int (example: 3 = 11000000)

<p align="center">
  <img src="./gitimages/tilescene.png?raw=true">
</p>

[AnimationScene] 

Load scene:
- It should load the entire spritesheet as a texture2d
- Use the draw function to draw tile(s) depending on the size (1, 2, 3, 4)

Behavior:
- Add animation  button. Adds animation after the current selected animation
- Disable Add button if Max 120 animations
- If it reaches max animation in page. Goes to next animation
- Scroll mouse up/down, navigates through animation list
- Remove button (Remove current selected animation)
- Always have a animation selected
- Disable Remove button if 0 animations
- Clicks on FPS number, Change the current animation FPS (4,8,12,16)
- Clicks on Tl number, Change the scale tile animation (1, 2, 3, 4)
- Click to select current animation
- Click to select current sprite of current animation
- In each sprite box of animations, display the tile of size 1, 2, 3, 4
- In Center of screen, display animation
- Add sprite button, add sprite in current animation right after the current selected sprite
- Remove sprite button, remove current selected sprite in current animation
- Create images: Stop, Play and Loop
- Toggle Pause/Play one time/Loop animation button

Data:
- Save list of object
- Object: Tile size, FPS, list of sprite numbers
- Use the 00 Index to default empty animation if object wants to use invisible animation

<p align="center">
  <img src="./gitimages/animationscene.png?raw=true">
</p>

[AutoTilerScene]

Load scene:
- It should load the entire spritesheet as a texture2d

Behavior:
- Create AutoTiler Scene
- Add a new autotile group rules
- Disable add button if max 12 group rules
- Remove current autotile group rules
- Disable Remove button if no current group rules
- Each group rules could contains until 20 rules
- Add rule button
- Disable Add rule button if max 20 rules
- Remove current rule button
- Disable remove current button if no current rule selected
- Click on rule, selects rule
- Click on default tile, select default tile
- It automatically unselect all other rules/default tile
- 8 different tiles
- Left Click: Toggle option: Set 1 true, Set 2 false
- Right Click: Set 0 ignore tile
- Add tile button, add current tile on the selected rule or default tile
- Remove tile button, remove the current tile on the selected rule or default tile

Data:
- Set list of group rules
- Group rules: Default tile and List of rules.
- List of rules: 8 int values (0 ignore tile, 1 true, 2 false) and Tile: int

<p align="center">
  <img src="./gitimages/autotilescene.png?raw=true">
</p>


Add AutoTiler like https://www.spritefusion.com/

<p align="center">
  <img src="./gitimages/spritefusion.png?raw=true">
</p>

[MapScene] 

Load scene:
- It should load the entire spritesheet as a texture2d

Behavior:
- Pencil
- Eraser. Left click erases 1 tile
- Eraser. Right click erases all visible area
- Bucket only paints visible area
- If bucket select, it doesn't apply auto tile group rules

Data:

<p align="center">
  <img src="./gitimages/mapscene.png?raw=true">
</p>

[ConfigScene] 

Behavior:
- Add Toggle between ScaleInteger/FullScreen options
- Add 6 shortcut buttons (1,2,3,4,5,6) to choose between None, and 5 different scenes to switch

Data:
- ...
 
[InfoScene]

Behavior:
- Create Info Scene
- Create Page structure to explain every thing (example: eraser right click erases all visible area)

[ParticlesScene]

Create a simple 2d particle system.

Using sprites:
- Game sprite of size 1 tile only
- Time: 0, 1, 2, 3, 4. Constant or varies between different sprites. no colors

- Use point or circle size 1,2,3,4 pixels 
- Use any color to 16
- Time: 0, 1, 2, 3, 4; point or circle size 1,2,3,4 pixels and color

- Can use random values for any one of cases values below
- Initial X position
- Initial Y position
- Initial X speed
- Initial Y speed
- Move X: linear or circular (back and forth), Tween/Easing Functions
- Move y: linear or circular (back and forth), Tween/Easing Functions
- Time fade out in seconds (1 to 30)
- Triggered everytime code calls functions generating new particles

https://www.lexaloffle.com/bbs/?tid=53826
https://www.youtube.com/watch?v=RQQRozN7Bew&t=10s&ab_channel=SpaceCat
https://www.youtube.com/watch?v=FEA1wTMJAR0&t=317s&ab_channel=Brackeys
https://www.youtube.com/shorts/Wlw_GI6-LS8

[NormalMapScene]

- Add normal map scene for the whole tilesheet (spritesheet)

https://www.youtube.com/watch?v=gUkY8ZoRfuQ&ab_channel=ThePassiveAggressor
https://youtu.be/vOXrrEvYUVg?si=lYrRYMP11Ic2mDgr

[RayCastScene]

- https://youtube.com/shorts/wCG3Nq_iibA?si=cYEtJbyonzEnPvQI

Read:

https://gameprogrammingpatterns.com/contents.html