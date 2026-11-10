# Demo: 3D playground
## Concept
Engine showcase and toolchain test in 3D: a small robot in a walled arena (2048×2048 units,
checkerboard floor with distance fog, sky + horizon) with a 3-step staircase, a floating
platform, a tall pillar and a low block. Beach balls bounce, roll and collide; the robot can
jump, climb, throw and kick balls; the camera orbits, zooms and has three modes. Every pad
button does something and lights up on an on-screen pad tester.

Code: `src/world.*` (state, fixed-point physics, camera), `src/render.*` (scene + HUD),
`src/assets/models.hpp` (colors, level layout, robot boxes, ball setup), `src/sounds.hpp`,
`src/main.cpp` (loop, pad → controls, logs). 3D rendering is `engine/gte3d`.

## Controls
| Pad | PCSX-Redux keyboard (default) | Action |
|---|---|---|
| D-pad | arrow keys | run, relative to the camera (8 directions) |
| ✕ | X | jump; hold for a full jump (~130 units), tap for a short hop |
| □ | Z | throw a ball forward (8 balls max; the oldest is reused) |
| ○ | D | kick balls within 130 units in front of the robot |
| △ | S | camera mode: ORBIT → FOLLOW → TOP |
| L1 / R1 | Q / R | orbit the camera left / right |
| L2 / R2 | A / F | zoom in / out (distance 320–1300) |
| START | Enter | pause; shows the controls help |
| SELECT | Backspace | reset the scene |

## Screens / states
- Playing: HUD top-left `3D DEMO  FPS n  POLYS n`, `CAM <mode>  DIST n`, `BALLS n/8  HEIGHT n`;
  pad tester bottom-right (each button lights while held); hint `START: PAUSE + HELP`.
- Paused: physics frozen, help panel listing all controls.
- No pad: `CONNECT CONTROLLER` (balls keep bouncing).

Camera modes: ORBIT (default, yaw only from L1/R1, pitch ~26°), FOLLOW (swings behind the
robot while it runs, lower pitch, more sky), TOP (pitch ~72°).

Physics (60 Hz, fixed point 20.12, world Y points down):
- Robot: AABB 52×122×52, ground accel 1.5 / friction 0.78 (top speed ~5.3 units/frame),
  air control 0.4 / 0.94, gravity 0.6, jump 12.5 (releasing ✕ caps rising speed at 4), lands on
  box tops, bumps its head on box bottoms, glass walls at the arena edge.
- Balls: radius 40, restitution floor 0.72 / boxes 0.75 / balls 0.92 / robot 0.5, impacts
  below 1.3 rest instead of bouncing, rolling friction, equal-mass ball-ball impulses, the robot
  pushes them (moving unmovable box), rolling spin for drawing.

## Status (done / in progress / next)
- Done (2026-11-09): replaced the 2D bootstrap demo by this 3D playground. All features above
  verified with the recipes below. Performance with 8 balls in view: 60 fps in Debug and Release
  (`STATE ... lines=<physics>+<render>` in tty.log, 263 scanlines = one frame).
- Next ideas: moving platforms, ball-in-goal scoring, title screen.

## Test recipes
Every log line below is printed by the game (`dbg::log`). Check also that no `PRESS` line
appears that the script did not send (real keyboard input, see Known issues).
- Boot + idle: `tools/test.ps1 -Game demo -Shots "60,250"`
  Expect `RESET frame=0 balls=3 boxes=38`, `MESHES player=32v/24f r=125 ball=26v/32f r=41`,
  `BOOT OK`, `STATE ... fps=60`. Shots: robot from behind, stairs left, pillar, teal block,
  balls falling (250: balls on the floor with shadows).
- Walk, jump, throw, kick:
  `tools/test.ps1 -Game demo -Inputs "70:UP:60,140:CROSS:20,200:SQUARE:2,232:CIRCLE:2" -Shots "100,158,212,250"`
  Expect `JUMP frame=136 x=0 z=11 h=0`, `LAND frame=176`, `THROW ... ball=3`, `KICK ... hits=0`.
  Shot 158: robot in the air (HEIGHT 116), shadow on the floor, ✕ lit on the pad tester.
- Camera: `tools/test.ps1 -Game demo -Inputs "70:L1:45,130:R2:40,190:TRIANGLE:2,215:TRIANGLE:2,250:L2:40,250:R1:30" -Shots "122,182,245,300"`
  Expect `CAM ... yaw=2296 dist=720`, `CAM ... yaw=2296 dist=1280`, `mode=FOLLOW`, `mode=TOP`.
  Shots: robot seen from the front (cyan visor), zoomed out, top view, top view zoomed in.
- Stairs, platform, pause, reset:
  `tools/test.ps1 -Game demo -Inputs "70:LEFT:130,205:UP:200,281:CROSS:22,322:CROSS:22,363:CROSS:22,420:RIGHT:40,425:CROSS:22,480:START:2,500:START:2,520:SELECT:2" -Shots "300,410,470,492,540"`
  Expect `LAND` with `h=50`, `h=105`, `h=160`, then `h=176` (floating platform), `PAUSE ... on=1`,
  `PAUSE ... on=0`, `RESET`. Shot 492 shows the help panel, 540 the start position.
- Head bump + many balls: `tools/test.ps1 -Game demo -Inputs "70:LEFT:78,150:UP:180,340:CROSS:20,400:TRIANGLE:2,420:TRIANGLE:2,440:SQUARE:2,455:SQUARE:2,470:SQUARE:2,485:SQUARE:2,500:SQUARE:2,515:SQUARE:2,530:SQUARE:2,548:CIRCLE:2" -Shots "352,500,555,640"`
  Expect `HEADBUMP ... box=35`, throws of balls 3..7 then 0, 1 (pool wraps), `KICK ... hits=1`.
- Ball collisions + kick: `tools/test.ps1 -Game demo -Inputs "70:SQUARE:2,80:SQUARE:2,90:SQUARE:2,150:UP:40,200:CIRCLE:2,232:UP:6,240:CIRCLE:2" -Shots "96,198,212,262"`
  Expect `KICK ... hits=1` then `hits=0`, `fps=60` in every STATE line.
- Follow camera: `tools/test.ps1 -Game demo -Inputs "70:TRIANGLE:2,90:RIGHT:90,190:DOWN:45,245:UP:40" -Shots "150,225,290"`
  Holding RIGHT circles with the camera swinging; walking toward the camera (225) does not spin it.
- Load: `tools/test.ps1 -Game demo -Inputs "70:R2:50,130:SQUARE:2,140:SQUARE:2,150:SQUARE:2,160:SQUARE:2,170:SQUARE:2,175:L1:20" -Shots "200,480"`
  8 balls in view at distance 1300: `polys=~420 fps=60 lines=14+203` in Debug.
- Release + CD image: `tools/test.ps1 -Game demo -Iso -Config Release -Shots "900"`
  Expect `boot file : cdrom:\GAME.EXE;1`, `BOOT OK`, `fps=60`, `resting=3` after a few seconds.

## Known issues
- No near-plane clipping (PS1 has none): polygons with a vertex closer than 40 units to the
  camera are dropped, so a ball right in front of the lens can lose faces.
- Painter's-algorithm sorting (average depth per face): rare overlaps between the robot's
  boxes or near large faces. Blob shadows on box tops can overhang the edge.
- Test runs sometimes log `PRESS` lines that were not scripted: real keyboard input reached the
  emulator window (CLAUDE.md §14.9). Rerun without typing while the test is running.
