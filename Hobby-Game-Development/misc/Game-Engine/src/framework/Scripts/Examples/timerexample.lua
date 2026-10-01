local timerexample={
    title = "Timer example"
}

function timerexample:init()

end

function timerexample:update() 

end

function timerexample:draw()

end

return timerexample

--[[
    ⏱️ Timer Functions

    | Function                         | Lua Alias      |
    | -------------------------------- | -------------- |
    | `StartTimer(int i = 0)`          | `_stimer`      |
    | `GetTimer(int i = 0, int d = 4)` | `_gtimer`      |
    | `PauseGame()`          | `_pgame`       |
    | `ResumeGame()`          | `_rgame`       |
    | `GetDateTime(int i = 0)`         | `_gtime`       |
    | `GetDeltaTime()`                 | `_gdeltatime`  |
    | `GetElapsedTime()`               | `_gelapsedtime`|
]]