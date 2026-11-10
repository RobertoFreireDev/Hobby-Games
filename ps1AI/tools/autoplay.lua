-- Loaded by test.ps1 (-dofile). Config arrives as globals from -exec.
-- Counts VBlanks from game start (ShellReached), holds scripted buttons on pad 1,
-- and pauses on shot frames so test.ps1 can grab a screenshot and resume.
local BTN = PCSX.CONSTS.PAD.BUTTON
local frame, vblanks, started, inputs, shots = 0, 0, false, nil, {}

local function setup()
  inputs = {}
  for item in string.gmatch(AUTOPLAY_INPUTS or '', '[^,]+') do
    local f, b, d = string.match(item, '^(%d+):(%w+):?(%d*)$')
    if f and BTN[b] then
      inputs[#inputs + 1] = { at = tonumber(f), btn = BTN[b], len = tonumber(d) or 1 }
    else
      print('autoplay: bad input "' .. item .. '"')
    end
  end
  for item in string.gmatch(AUTOPLAY_SHOTS or '', '[^,]+') do shots[tonumber(item)] = true end
end

-- Listeners are deleted when garbage-collected, so keep them in globals.
AutoplayShell = PCSX.Events.createEventListener('ExecutionFlow::ShellReached',
  function() started = true end)
AutoplayVsync = PCSX.Events.createEventListener('GPU::Vsync', function()
  vblanks = vblanks + 1
  if not started and vblanks > 600 then started = true end -- fallback
  if not started then return end
  if inputs == nil then setup() end
  local pad = PCSX.SIO0.slots[1].pads[1]
  for _, e in ipairs(inputs) do
    if frame == e.at then pad.setOverride(e.btn) end
    if frame == e.at + e.len then pad.clearOverride(e.btn) end
  end
  if shots[frame] then PCSX.pauseEmulator() end
  frame = frame + 1
end)
