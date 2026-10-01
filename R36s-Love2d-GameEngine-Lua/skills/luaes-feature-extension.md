---
name: luaes-feature-extension
description: Add new engine-level features to LuaES following architecture and design constraints.
---

# LuaES Feature Extension Instructions

When asked to add a new feature to LuaES, follow these structured steps to ensure architectural consistency and engine integrity:

1. **Understand the Engine Architecture**  
   Carefully analyze how the current engine is structured:
   - Global utility sections (math, table, io, etc.)
   - Data-driven systems (maps, spritesheets, flags, sfx)
   - Love2D lifecycle (`love.load`, `love.update`, `love.draw`)
   - Public API exported in the final return table  
   Any new feature must integrate cleanly into this structure.

2. **Respect Engine Design Principles**
   - Keep the engine lightweight and modular.
   - Avoid external dependencies.
   - Follow existing naming conventions (short, PICO-8–style).
   - Prefer small composable functions over monolithic systems.
   - Maintain 60 FPS compatibility.
   - Avoid breaking backward compatibility.

3. **Determine Feature Category**
   Classify the new feature as one of the following:
   - Rendering (draw, camera, screen effects)
   - Input extension
   - Audio / music extension
   - Physics / collision
   - Entity helpers
   - Data systems (map, sprite, flags)
   - Utility helpers
   - Save/load enhancements
   - Debug tools

4. **Check Integration Points**
   Identify where the feature must integrate:
   - Does it require updates inside `love.update`?
   - Does it require updates inside `love.draw`?
   - Does it use `maps`, `spritesheets`, or `flags`?
   - Does it require persistent save support?
   - Does it need inclusion in `save()`?

5. **Follow Section Organization**
   New code must:
   - Be placed in a clearly labeled `--#region` block.
   - Follow the same commenting and layout style.
   - Avoid modifying unrelated regions.
   - Add only necessary global state.

6. **Expose Public API**
   If the feature is intended for user scripts:
   - Add its functions to the final `return {}` table.
   - Keep API consistent with existing naming style.
   - Ensure arguments are validated like other functions (`mid`, `floor`, etc.).

7. **Maintain Data Safety**
   If the feature writes to files:
   - Use `createIfDoesntExist`
   - Use `.txt` file convention
   - Follow fixed-width encoding where applicable
   - Avoid breaking existing file formats

8. **Ensure Performance Safety**
   - Avoid per-frame heavy allocations.
   - Avoid nested loops over full maps unless required.
   - Prefer precomputation when possible.
   - Reuse tables when feasible.

9. **Provide Usage Example**
   Always include:
   - Minimal example inside `_init`, `_update`, `_draw`
   - Demonstration of how the feature interacts with existing API
   - Clear explanation of expected behavior

Usage example for drawing shapes on the screen:

```lua
require("libs/luaes")

local frame = 0
local FRAME_SKIP = 30
local index  = 0

function _init()
end

function _update(dt)
    frame = frame + 1
    if frame < FRAME_SKIP then return end
    frame = 0

    index = index + 1

    if index > 32 then
        index = 0
    end
end

function _draw()
    print("Text", 10, 10, 10, 2)
    rect(10, 30, 30, 20, 8, 2)
    rectfill(10, 60, 30, 20, index, 10)
    line(60, 10, 70, 30, 10, 2)
    circ(100, 30, 10, 11, 1)
    circfill(100, 60, 10, 12, 2)
end
```

10. **Generate Feature Summary**
    At the end, include:
    - What the feature adds
    - Which regions were modified or added
    - Which API functions were exposed
    - Whether it impacts save system
    - Whether it impacts performance
