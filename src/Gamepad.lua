local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
-- The gamepad gate, with Olympus Guild's rule and detection (Olympus/Gamepad.lua).
-- Blizzard's gamepad UI drives parts of the game's interface itself; when addon code reaches
-- into them the game can refuse its own protected calls in that addon's name until a /reload.
-- So with the gamepad UI on, ZEUS pauses (see GamepadRegistry.lua for each reach):
--
-- Z.Allowed(id)       asked before every reach into the game's UI: false for a "gate" entry
--                     while the gamepad UI is on, and always false for an id not in the list.
-- Z.GamepadHooks(id, t)  what a switch does: t.park on a switch to the gamepad UI (t.now: in the
--                     switch's own event, else the next frame), t.install on the way back
--                     (the next frame, out of combat).
-- Z.GamepadLeftover(id)  something that stays on the game's side until a /reload.
-- Z.OutOfCombat(fn)   fn now, or when combat ends.

local REGISTRY = {}
for _, e in ipairs(Z.GAMEPAD or {}) do REGISTRY[e.id] = e end
Z.GAMEPAD_BY_ID = REGISTRY
Z.GAMEPAD_PAUSED = Z.L.GAMEPAD_PAUSED
Z.GAMEPAD_NOTICE = Z.L.GAMEPAD_NOTICE

local function padEnum()
	return Enum and Enum.InputDeviceInterfaceType and Enum.InputDeviceInterfaceType.Gamepad
end
function Z.GamepadUI()
	local current = C_InputInterfaceStyle and C_InputInterfaceStyle.GetCurrentStyle
	local gamepad = padEnum()
	if type(current) ~= "function" or gamepad == nil then return false end
	local ok, style = pcall(current)
	return ok and style == gamepad
end

local unlisted = {}
function Z.Allowed(id)
	local e = REGISTRY[id]
	if not e then
		if not unlisted[id] then
			unlisted[id] = true
			if Z.Print then Z.Print("Internal: refused an unlisted UI integration (" .. tostring(id) .. ").") end -- gp:chat-output
		end
		return false
	end
	return e.guard ~= "gate" or not Z.GamepadUI()
end

local hooks, leftovers, waiting = {}, {}, {}
local noticed, queued = false, false
function Z.GamepadHooks(id, t)
	if REGISTRY[id] and type(t) == "table" then hooks[#hooks + 1] = { id = id, t = t } end
end
function Z.GamepadLeftover(id) if REGISTRY[id] then leftovers[id] = true end end
function Z.OutOfCombat(fn)
	if InCombatLockdown() then waiting[#waiting + 1] = fn else fn() end
end
local function run(field, onlyNow)
	for _, h in ipairs(hooks) do
		local fn = h.t[field]
		if type(fn) == "function" and (onlyNow == nil or (h.t.now == true) == onlyNow) then
			local ok, err = pcall(fn)
			if not ok and Z.Print then Z.Print("Gamepad switch (" .. h.id .. "): " .. tostring(err)) end -- gp:chat-output
		end
	end
end
local function settle()
	queued = false
	if Z.GamepadUI() then
		run("park", false)
		if next(leftovers) and not noticed and Z.Print then
			noticed = true
			Z.Print(Z.GAMEPAD_NOTICE) -- gp:chat-output
		end
	else
		Z.OutOfCombat(function()
			if not Z.GamepadUI() then
				for id in pairs(leftovers) do leftovers[id] = nil end
				run("install")
			end
		end)
	end
end
-- The switch's payload is (newMode, oldMode); the game has already set the new style.
function Z.GamepadSwitched(newMode)
	local gamepad = padEnum()
	local pad
	if newMode ~= nil and gamepad ~= nil then pad = newMode == gamepad else pad = Z.GamepadUI() end
	-- Only giving back the keys happens inside the game's own transition.
	if pad then run("park", true) end
	if not queued then
		queued = true
		C_Timer.After(0, settle)
	end
end

local frame = CreateFrame("Frame")
Z.gamepadFrame = frame
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(frame.RegisterEvent, frame, "INPUT_DEVICE_INTERFACE_TRANSITION")
frame:SetScript("OnEvent", function(_, event, newMode)
	if Z.runtimeInactive then return end
	if event == "PLAYER_REGEN_ENABLED" then
		local ready = waiting
		waiting = {}
		for _, fn in ipairs(ready) do fn() end
	else
		Z.GamepadSwitched(newMode)
	end
end)
