local _, Z = ...
Z = Z.ZEUSModule or Z
-- Text shown to the player, the same scheme as Olympus Guild's Locales.lua. English here is
-- the reference; Locales/<code>.lua add a language through Z.Locale. A line a language leaves
-- out stays English, and a missing key shows the key itself, so a typo is visible on screen
-- instead of an error. Spell and class names come from the game, already in its language.
-- /zeus debug and its diagnostics stay English: they are for bug reports.
local L = setmetatable({}, {__index=function(_, key) return key end})
Z.L = L

-- Settings window
L.SLOGAN = "Power your allies. Crush your enemies."
L.BUFF_KEY = "BUFF KEY"
L.CHOOSE_KEY = "Choose a key..."
L.RESET = "Reset"
L.RESET_TIP = "Clear your Buff Key and give that key its normal job back."
L.WHEEL_TIP = "Tip: bind the mouse wheel to buff as you scroll. Turn ZEUS off to get your zoom back."
L.TOGGLE_MACRO = "ZEUS on/off"
L.TOGGLE_MACRO_TIP = "Click or drag to put the ZEUS on/off macro on your action bar."
L.BUFF_MACRO = "Buff"
L.BUFF_MACRO_TIP = "Drag to your action bar and spam it. If ZEUS is off, it turns on while you keep pressing and back off a few seconds after you stop. Your Buff Key keeps its normal job meanwhile."
L.DRAG_TO_BAR = "Drag to action bar"
L.BUFFS = "BUFFS"
L.BLESSINGS = "BLESSINGS"
L.ROW_HELP = "Unlock to edit · drag to reorder · right-click to skip a class · leftmost goes first"
L.NOT_LEARNED = "Not learned"
L.REAGENT_TIP = "Needs a reagent."
L.ONE_BLESSING = "One blessing per player, picked by class."
L.NO_BUFFS = "Your class has no buffs ZEUS can hand out."
L.REBUFF_EXPIRED = "Rebuff: once it runs out"
L.REBUFF_AT = "Rebuff with %d%% left"
L.SLIDER_TIP = "Rebuff when this much of a buff is left. Higher refreshes sooner; at 0 ZEUS waits until it runs out. Weaker ranks get upgraded either way. If someone clicks a buff off, ZEUS still waits for its usual refresh time."
L.PVP_PROTECTION = "PvP protection"
L.PVP_TIP = "Skip PvP-flagged players while you're not flagged, and always skip free-for-all PvP."
L.PVP_WARNING = "Heads up: buffing PvP-flagged players can flag you too."
L.TURN_ON = "Turn ZEUS on"
L.TURN_OFF = "Turn ZEUS off"
L.TOGGLE_TIP = "Turn ZEUS on or off. Off gives your Buff Key its normal job back."
L.REPORT_BUTTON = "Buff-hours"
L.REPORT_TIP = "Show your total buff-hours and today's total in chat."
L.LOCK = "Lock"
L.UNLOCK = "Unlock"
L.TILE_ON = "%s: buffed"
L.TILE_OFF = "%s: skipped"
L.TILE_HELP_UNLOCKED = "Drag to reorder. Right-click to skip or include."
L.TILE_HELP_LOCKED = "Unlock this buff to edit it."

-- Status line
L.STATUS_OFF = "ZEUS is off. Click Turn ZEUS on to start."
L.STATUS_NEEDS_PLATES = "ZEUS needs friendly nameplates. Press Shift+V."
L.STATUS_COMBAT = "Paused in combat"
L.STATUS_CHECKING = "Checking: %s"
L.STATUS_NEXT = "Next up: %s"
L.STATUS_READY = "All set. Nobody nearby needs a buff."

-- Choosing a key
L.CHOOSE_TITLE = "Choose your Buff Key"
L.KEY_PROMPT = "Press a key, or click or scroll anywhere on screen. Hold Ctrl, Alt or Shift for a combo.\nEscape cancels. Backspace or Delete clears your key."
L.KEY_MOUSE_TAKEN = "Left and right click are taken. Pick another button, or hold Ctrl, Alt or Shift with it."
L.KEY_IN_USE = "%s is already bound to %s.\nUse it for ZEUS while ZEUS is on? It goes back when ZEUS is off."
L.USE_KEY = "Use this key"
L.CANCEL = "Cancel"

-- Minimap button
L.MINIMAP_ON = "ZEUS is on"
L.MINIMAP_OFF = "ZEUS is off"
L.MINIMAP_PLATES_SHOWN = "Friendly nameplates: shown"
L.MINIMAP_PLATES_HIDDEN = "Friendly nameplates: hidden"
L.MINIMAP_KEY_AFTER_COMBAT = "Your key goes back to normal after combat"
L.MINIMAP_KEY_RELEASED = "Your key is back to normal"
L.MINIMAP_LEFT = "Left-click: settings"
L.MINIMAP_RIGHT_ON = "Right-click: turn ZEUS on"
L.MINIMAP_RIGHT_OFF = "Right-click: turn ZEUS off"
L.MINIMAP_DRAG = "Drag: move this button"
L.MINIMAP_KEY = "Buff Key: %s"
L.KEY_NOT_SET = "not set"
L.PAUSED_GAMEPAD = "Paused: gamepad UI"

-- Chat
L.HINT = "Type /zeus to pick a Buff Key or grab the Buff macro."
L.NEED_PLATES = "ZEUS needs friendly nameplates. Press Shift+V to show them."
L.NO_COMBAT_TOGGLE = "You can't turn ZEUS on or off in combat."
L.NO_COMBAT_KEY = "You can't change the Buff Key in combat."
L.NO_COMBAT_INPUT = "You can't change the input mode in combat."
L.NO_COMBAT_MACRO = "You can't add a macro in combat."
L.INPUT_BOTH = "Both-edge input is on. Check it with /zeus debug."
L.INPUT_RELEASE = "Release-only mode is on, for clients that only send key releases."
L.CURSOR_BUSY = "Put down or clear what's on your cursor first."
L.MAKE_MACRO = "Open the game's Macros window and make a macro with: %s"
L.MACROS_FULL = "Your macro slots are full. Free one up and try again."
L.MACRO_CREATE_FAILED = "Couldn't create the macro (%s). Make one yourself with: %s"
L.MACRO_VERIFY_FAILED = "Couldn't find the ZEUS macro. Try again."
L.MACRO_PICK_ICON = "Pick an icon for %s in /macro, then click Save."
L.MACRO_SAVE_FAILED = "Couldn't save the ZEUS macro: %s"
L.MACRO_SAVE_VERIFY = "Couldn't check the saved ZEUS macro. Pick an icon in /macro and click Save."
L.MACRO_DRAG_OPENED = "Drag \"%s\" from the Macros window onto your action bar."
L.MACRO_DRAG_OPEN = "Open /macro and drag \"%s\" onto your action bar."
L.PICKUP_FAILED = "Couldn't pick up the macro: %s"
L.PICKUP_WRONG = "Couldn't pick up the macro (the cursor type was %s)."
L.PICKUP_UNAVAILABLE = "This game client can't pick up macros."
L.REPORT_TOTAL = "Total buff-hours provided: %.2f | Today (UTC): %.2f"
L.REPORT_UNMEASURED = "%d successful casts couldn't be measured."
L.BLOCKER_LEARNED = "%s blocks %s (rank %d and lower), so ZEUS skips players who have it. /zeus blockers shows the list."
L.BLOCKER_GUESSED = "%s seems to block %s (rank %d and lower), so ZEUS skips players who have it and double-checks now and then. /zeus blockers shows the list."
L.BLOCKER_FORGOTTEN = "%s doesn't block %s after all. ZEUS forgot it."
L.BLOCKER_ROW = "%s (%d) blocks %s, rank %d and lower."
L.BLOCKER_ROW_GUESS = "%s (%d) blocks %s, rank %d and lower (a guess ZEUS double-checks)."
L.BLOCKERS_NONE = "ZEUS hasn't learned any blocking buffs yet."
L.BLOCKERS_CLEAR_HINT = "/zeus blockers clear forgets them."
L.BLOCKERS_CLEARED = "Forgot all blocking buffs."
L.UNKNOWN_BUFF = "Unknown buff"
L.GAMEPAD_PAUSED = "ZEUS is paused while the gamepad UI is on. Switch to mouse and keyboard to use it."
L.GAMEPAD_NOTICE = "ZEUS paused for the gamepad UI and comes back when you switch to mouse and keyboard. Its /zeus command sticks around until a /reload, so don't type it in gamepad mode."
L.DUPLICATE = "Two copies of ZEUS are loaded (one may be inside another addon). Only the first one runs, so remove the extra copy."
L.BOTH_EDITIONS = "ZEUS and ZEUS Olympus are both turned on. ZEUS Olympus is running and ZEUS is sitting out. You'll want to disable or uninstall one of them, then /reload."
L.OK = "OK"

-- The codes in a line that a translation must keep, in order: format codes (%s, %d, %.2f, %%)
-- and escape codes (|cff...|r colours, |T...|t icons). Lua can't reorder them.
local function codes(s)
    local out, i, n = {}, 1, #s
    while i <= n do
        local c = s:sub(i, i)
        if c == "%" then
            local spec = s:match("^%%[%-%+ #0]*%d*%.?%d*[%a%%]", i)
            out[#out+1] = spec or "%?"
            i = i + (spec and #spec or 1)
        elseif c == "|" then
            local nxt = s:sub(i+1, i+1)
            out[#out+1] = "|"..nxt
            if nxt == "c" then i = i + 10
            elseif nxt == "T" then i = (s:find("|t", i+2, true) or n) + 2
            else i = i + 2 end
        else
            i = i + 1
        end
    end
    return table.concat(out, " ")
end
Z.LocaleCodes = codes

-- Z.Locale(codes, strings): take a language's lines when the game runs in one of `codes`
-- ("deDE", or {"esES","esMX"}). A line whose codes differ from the English one, or whose key
-- English doesn't have, is left out (it shows in English) and listed by /zeus debug.
Z.language = {code=GetLocale and GetLocale() or "enUS", taken=0, skipped={}}
function Z.Locale(list, strings)
    if type(list) == "string" then list = {list} end
    local mine = false
    for _, code in ipairs(type(list) == "table" and list or {}) do
        if code == Z.language.code then mine = true end
    end
    if not mine or type(strings) ~= "table" then return end
    for key, text in pairs(strings) do
        local english = type(key) == "string" and rawget(L, key)
        if type(english) == "string" and type(text) == "string" and text ~= ""
            and codes(text) == codes(english) then
            L[key] = text
            Z.language.taken = Z.language.taken + 1
        else
            table.insert(Z.language.skipped, tostring(key))
        end
    end
end
