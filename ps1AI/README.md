# ps1AI

PlayStation 1 games in C++20, built with PSn00bSDK and run in PCSX-Redux.
Replace `demo` with any game folder name under `games/`.

`games/demo` is a 3D playground (walk, jump, climb, throw and kick bouncing balls, orbit and
zoom the camera); its controls and test recipes are in [games/demo/GAME.md](games/demo/GAME.md).
New games start from the 2D template `games/_template` (`tools/new-game.ps1 -Name <name>`).

**Build a game** (outputs `build/demo/game.exe` and the CD image `game.bin` + `game.cue`):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build.ps1 -Game demo
```

**Run it in the emulator** (builds first, then opens PCSX-Redux; add `-Iso` to boot the CD image):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run.ps1 -Game demo
```

Pad 1 on the keyboard: arrows = D-pad, X = ✕, D = ○, Z = □, S = △, Q/R = L1/R1, A/F = L2/R2,
Enter = START, Backspace = SELECT.
