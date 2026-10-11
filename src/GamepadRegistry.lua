local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
-- Every way ZEUS reaches into the game's own UI, in one list (the gamepad gate, Gamepad.lua).
-- Pure data, in the same shape as Olympus Guild's Olympus/GamepadRegistry.lua.
--
-- The rule: with Blizzard's gamepad UI on, ZEUS pauses. It reads (units, auras, events, so
-- buff-hours from your own casts still count) but sets no key overrides, arms no buttons,
-- edits no macros, opens none of the game's popups or its own settings, and writes nothing on
-- the Escape list. Switching back to mouse and keyboard restores what was paused.
--
-- Fields:
--   id       the name passed to Z.Allowed(id) and Z.GamepadHooks(id, ...).
--   kind     what kind of reach it is.
--   files    where its code is; each site there is tagged "-- gp:<id>".
--   guard    "gate": refused while the gamepad UI is on. "own": ZEUS's own objects, or reads
--            of the game's. "exempt": allowed in both modes, for the reason in `why`.
--   toPad    a switch to the gamepad UI: "park" (undone, ZEUS's side cleared), "reload"
--            (stays until a /reload; the player is told once), "stays" (nothing to do).
--   toMouse  a switch back: "install" (set up again), "nothing".
--   why      the reason, in a sentence.
--   pins     lines of Forever's own UI source (build below) the reason rests on.
--
-- dev/check.py fails on a reach of the game's UI with no tag, a tag with no entry here, an
-- entry tagged nowhere, a "gate" entry whose files never ask Z.Allowed, and an entry the tests'
-- gamepad pass does not cover.

-- The Forever client build the pins were checked against (1.60.1).
Z.GAMEPAD_CHECKED_BUILD = 70291

Z.GAMEPAD = {
	{ id = "buff-key", kind = "binding", files = { "Buttons.lua" },
		guard = "gate", toPad = "park", toMouse = "install",
		why = "The Buff Key and the reverse-wheel block are override bindings, and the gamepad UI keeps its own binding stack on the same keys: never set with the gamepad UI, and the ones ZEUS holds go back to the game in the switch's own event.",
		pins = { "Blizzard_GamepadSharedUtility/InputBindingStack/InputBindingManager.lua:29 SetOverrideBinding(UIParent, false, key, \"\");" } },
	{ id = "cast-buttons", kind = "secure-buttons", files = { "Buttons.lua" },
		guard = "gate", toPad = "park", toMouse = "install",
		why = "ZEUS's hidden click receivers hold a spell or a targeting macro for the next press; with the gamepad UI they stay empty and a press does nothing." },
	{ id = "macros", kind = "macro-data", files = { "Macro.lua" },
		guard = "gate", toPad = "park", toMouse = "install",
		why = "Creating, rewriting and picking up the ZEUS macros writes the game's macro list and cursor, which the gamepad action bars show: with the gamepad UI none is touched, and the Buff macro goes back to its plain form." },
	{ id = "settings", kind = "window", files = { "UI.lua" },
		guard = "gate", toPad = "park", toMouse = "nothing",
		why = "The settings window takes the keyboard to choose a key and puts macros on the game's cursor: with the gamepad UI it stays closed." },
	{ id = "escape-list", kind = "table-write", files = { "UI.lua" },
		guard = "gate", toPad = "park", toMouse = "install",
		why = "The game closes every window named on UISpecialFrames from its own menus: ZEUS writes no name there with the gamepad UI, and at a switch takes its name off the end of the list (a name before another addon's stays until a /reload, so nothing moves).",
		pins = { "Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua:21 UISpecialFrames = {",
			"Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua:1106 function CloseSpecialWindows()" } },
	{ id = "slash", kind = "slash", files = { "Core.lua" }, globals = { "SLASH_ZEUS1" },
		guard = "gate", toPad = "reload", toMouse = "install",
		why = "The chat box calls a slash command's function directly, then clears its gamepad focus in that function's taint: /zeus is not registered at a gamepad login; once registered it stays until a /reload and does nothing with the gamepad UI.",
		pins = { "Blizzard_ChatFrameBase/Shared/ChatFrameEditBox.lua:267 hash_SlashCmdList[command](strtrim(msg), self);",
			"Blizzard_ChatFrameBase/Shared/ChatFrameEditBox.lua:413 self.chatFrame:ClearGamepadFocus();" } },
	{ id = "popup", kind = "popup", files = { "Bootstrap.lua" },
		guard = "gate", toPad = "stays", toMouse = "nothing",
		why = "The both-editions warning is the game's popup with mouse and keyboard; with the gamepad UI it is a chat line, as a game popup opened by an addon writes the popups' shared state in its taint." },
	{ id = "nameplate-setting", kind = "cvar", files = { "Nameplates.lua" },
		guard = "gate", toPad = "stays", toMouse = "nothing",
		why = "Turning friendly nameplates on or off when ZEUS is toggled writes the game's setting: refused with the gamepad UI, where ZEUS is paused." },
	{ id = "minimap", kind = "frame-child", files = { "UI.lua" },
		guard = "exempt", toPad = "stays", toMouse = "nothing",
		why = "The minimap button (LibDBIcon): Forever's minimap has no gamepad binding group, the reason Olympus Guild gives for its own button; with the gamepad UI its clicks only say ZEUS is paused." },
	{ id = "tooltips", kind = "tooltip", files = { "UI.lua", "PriorityUI.lua" },
		guard = "own", toPad = "stays", toMouse = "nothing",
		why = "GameTooltip lines for ZEUS's own controls and minimap button, only while the mouse is over them." },
	{ id = "state-driver", kind = "secure-state", files = { "Buttons.lua", "Macro.lua" },
		guard = "exempt", toPad = "stays", toMouse = "nothing",
		why = "RegisterStateDriver hides ZEUS's own receivers in combat and tells its drag buttons about combat: Blizzard's secure state driver for addons, on no gamepad path." },
	{ id = "buff-givers", kind = "tooltip-callback", files = { "Givers.lua" },
		guard = "gate", toPad = "stays", toMouse = "nothing",
		why = "A post-call on the game's tooltip processor and hooks that run after the game tooltip's aura setters add a \"Given by\" line to your own buffs, once per tooltip. Both stay for the session (neither can be removed); with the gamepad UI on they add nothing.",
		pins = { "Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua:199 function TooltipDataProcessor.AddTooltipPostCall(tooltipType, func)",
			"Blizzard_BuffFrame/BuffFrame.lua:1179 GameTooltip:SetUnitAuraByAuraInstanceID(PlayerFrame.unit, self.buttonInfo.auraInstanceID);" } },
	{ id = "buff-whisper", kind = "event-callback", files = { "Givers.lua" },
		guard = "gate", toPad = "stays", toMouse = "nothing",
		why = "A callback on the buff frame's own BuffButton.OnClick event opens a whisper to the giver of a buff you left-click, through the game's own ChatFrameUtil.SendTell, unless a chat box is already open (ChatFrameUtil.GetActiveWindow). ZEUS only opens it: the player types and sends. The callback runs through the game's secure callback loop, so the right-click that removes a buff is untouched; with the gamepad UI on it does nothing.",
		pins = { "Blizzard_BuffFrame/BuffFrame.lua:1146 EventRegistry:TriggerEvent(\"BuffButton.OnClick\", self, button);",
			"Blizzard_SharedXMLBase/CallbackRegistry.lua:204 secureexecuterange(closures, ExecuteClosurePair, ...);",
			"Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua:383 function ChatFrameUtil.SendTell(name, chatFrame)",
			"Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua:496 function ChatFrameUtil.GetActiveWindow()" } },
	{ id = "chat-output", kind = "chat-output", files = { "Core.lua", "Bootstrap.lua", "Gamepad.lua" },
		guard = "exempt", toPad = "stays", toMouse = "nothing",
		why = "Lines printed in the chat window, as every addon's print: no focus, no filter, no binding." },
}
