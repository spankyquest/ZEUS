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
L.BUFF_KEY_TIP = "The key you buff with. While ZEUS is enabled, each press buffs the next player in the queue. While it's disabled, the key does its normal job."
L.CHOOSE_KEY = "Choose a key..."
L.CHOOSE_KEY_TIP = "Click, then press the key you want to buff with. You can also click a mouse button or scroll the wheel, anywhere on screen."
L.RESET = "Reset"
L.RESET_TIP = "Clear your Buff Key and give that key its normal job back."
L.WHEEL_TIP = "Tip: bind the mouse wheel to buff as you scroll. Disable ZEUS to get your zoom back."
L.MACROS = "MACROS"
L.MACROS_TIP = "Buttons for your action bars, if you'd rather click than press a key. Buff does what your Buff Key does, and Enable/disable turns ZEUS on and off. Drag one to a bar."
L.TOGGLE_MACRO = "Enable/disable"
L.TOGGLE_MACRO_TIP = "Click or drag to put the macro that enables and disables ZEUS on your action bar."
L.BUFF_MACRO = "Buff"
L.BUFF_MACRO_TIP = "Drag to your action bar and spam it. If ZEUS is disabled, the macro enables it while you keep pressing and disables it again a few seconds after you stop. Your Buff Key keeps its normal job meanwhile."
L.DRAG_TO_BAR = "Drag to action bar"
L.BUFF_ORDERING = "BUFF ORDERING"
L.BLESSING_ORDERING = "BLESSING ORDERING"
L.NOT_LEARNED = "Not learned"
L.REAGENT_TIP = "Needs a reagent."
L.ONE_BLESSING = "One blessing per player, picked by class. ZEUS keeps the one you gave and skips one another paladin already gave."
L.BUFF_ORDERING_TIP = "Which buffs ZEUS hands out, and which classes get each one first. Hover a buff or Edit to see how to change them."
L.SPELL_TIP = "Tick to have ZEUS hand out %s; untick to stop."
L.NOT_LEARNED_AT = "You haven't learned %s yet. Your class trainer teaches it from level %d."
L.NOT_LEARNED_NOW = "You haven't learned %s yet. Your class trainer teaches it from level %d, so you can learn it now."
L.RANK = "Rank %d"
L.RANK_LEVEL = "(level %d)"
L.RANK_TIP = "ZEUS casts %s, or a lower rank on players too low for it."
L.RANKS_TIP = "Editing also lists this buff's ranks under the tiles: pick the one ZEUS casts. It's the strongest you know until you pick another, and goes back to the strongest when your trainer teaches you a new rank."
L.NO_BUFFS = "Your class has no buffs ZEUS can hand out."
L.REBUFF_EXPIRED = "Rebuff: once it runs out"
L.REBUFF_AT = "Rebuff with %d%% left"
L.SLIDER_TIP = "Rebuff when this much of a buff is left. Higher refreshes sooner; at 0 ZEUS waits until it runs out. Weaker ranks get upgraded either way. If someone clicks a buff off, ZEUS still waits for its usual refresh time."
L.PVP_PROTECTION = "PvP protection"
L.PVP_TIP = "Skip PvP-flagged players while you're not flagged, and always skip free-for-all PvP."
L.PVP_WARNING = "Heads up: buffing PvP-flagged players can flag you too."
L.SKIP_AFK = "Skip AFK players"
L.SKIP_AFK_TIP = "Leave players flagged AFK alone. They get their buffs once they're back."
L.SKIP_LEVEL_ONE = "Skip level 1 players"
L.SKIP_LEVEL_ONE_TIP = "Leave level 1 characters alone, like fresh alts and bank characters parked in town."
L.SORT_BY_CLASS = "Sort by class"
L.SORT_BY_CLASS_TIP = "Changes the order of ZEUS's buffing queue: who gets buffed next. Ticked: the class tiles under each buff decide first, and the players' level only breaks ties. Unticked (default): the players around you are lined up by their level, and the class tiles only break ties. Your target always comes first."
L.LOW_LEVEL_FIRST = "Lower-level players first"
L.LOW_LEVEL_FIRST_TIP = "Changes which players ZEUS buffs first when their levels differ. Ticked (default): lower-level players get buffed before higher-level ones (a level 20 before a level 60). Unticked: higher-level players go first."
L.MINIMAP_BUTTON = "Minimap button"
L.MINIMAP_BUTTON_TIP = "Show the ZEUS button on your minimap. Without it, /zeus still opens this window."
L.TRACK_GIVERS = "Track buffs given to me"
L.TRACK_GIVERS_TIP = "Show who gave you each buff at the bottom of its tooltip, and left-click one of your buffs to whisper them. The game only says who cast a buff while it can see them, so strangers are only caught with friendly nameplates on (ZEUS turns them on while it's enabled)."
L.TURN_ON = "Enable ZEUS"
L.TURN_OFF = "Disable ZEUS"
L.TOGGLE_TIP = "Enable or disable ZEUS. While it's disabled, your Buff Key does its normal job."
L.ADVANCED = "Advanced"
L.ADVANCED_TIP = "More options: the order of the buffing queue, which players to skip, instant buff-back, lower rank buffs, PvP protection, the minimap button, seeing who buffed you, protecting your buffs from right-click and the queue window. Click again to hide them."
L.ADVANCED_QUEUE = "BUFFING QUEUE"
L.ADVANCED_INTERFACE = "INTERFACE"
L.PROTECT_BUFFS = "Protect buffs from right-click"
L.PROTECT_BUFFS_TIP = "A right-click on one of your buffs (or weapon enchants) no longer removes it at once: its tooltip asks you to right-click again, and a second right-click within 5 seconds removes it."
L.CONFIRM_REMOVAL = "Right-click to confirm removal"
L.SHOW_QUEUE = "Show queue window"
L.SHOW_QUEUE_TIP = "A see-through window, like the chat window, listing who ZEUS buffs next, top to bottom. Drag it to move it, and drag its bottom-right corner to resize it: a taller window shows more names. Grey names are out of sight."
L.QUEUE_OFF = "ZEUS is disabled."
L.QUEUE_NO_PLATES = "ZEUS needs friendly nameplates."
L.QUEUE_NO_BUFFS = "No buffs to hand out."
L.QUEUE_EMPTY = "Nobody nearby needs a buff."
L.QUEUE_OOM = "Out of mana"
L.INSTANT_BUFF_BACK = "Instant buff-back"
L.INSTANT_BUFF_BACK_TIP = "When another player buffs you, they go first in the queue for a minute: your next press of the Buff Key or the Buff macro buffs them back, if they need one of your buffs. Needs Track buffs given to me."
L.LOWER_RANKS = "Enable lower rank buffs"
L.LOWER_RANKS_TIP = "Lets you pick a lower rank of a buff, to save mana: click Edit next to the buff and choose one under its class tiles. Off (default), ZEUS casts your strongest rank, and players too low for it get the strongest they can take."
L.RESTORE_DEFAULTS = "Restore Defaults"
L.RESTORE_CONFIRM = "Click to confirm"
L.RESTORE_TIP = "Put every ZEUS setting back the way it was when you installed it: the buffs, class orders, ranks, sorting, rebuff slider, Buff Key and all the boxes. Your buff-hours are kept. Click twice to confirm."
L.DEFAULTS_RESTORED = "Settings are back to their defaults. Your buff-hours are kept."
L.NO_COMBAT_RESET = "You can't restore defaults in combat."
L.REPORT_BUTTON = "Buff-hours"
L.REPORT_TIP = "Show your buff-hours in chat: total, today, and per buff and rank."
L.LOCK = "Lock"
L.UNLOCK = "Edit"
L.LOCK_TIP = "Lock the class order so a stray click can't change it. Closing the window locks it too."
L.UNLOCK_TIP = "Change which classes get this buff first. Drag the class tiles (leftmost goes first) and right-click one to skip that class. Click Lock when you're done; closing the window locks it too."
L.TILE_ON = "%s: buffed"
L.TILE_OFF = "%s: skipped"
L.TILE_HELP_UNLOCKED = "Drag to reorder. Right-click to skip or include."
L.TILE_HELP_LOCKED = "Click Edit to change this buff's class order."

-- Status line
L.STATUS_OFF = "ZEUS is disabled. Click Enable ZEUS to start."
L.STATUS_NEEDS_PLATES = "ZEUS needs friendly nameplates. Press %s."
L.STATUS_NEEDS_PLATES_NO_KEY = "ZEUS needs friendly nameplates. Turn them on in the game's options."
L.STATUS_COMBAT = "Paused in combat"
L.STATUS_CHECKING = "Checking: %s"
L.STATUS_NEXT = "Next up: %s"
L.STATUS_READY = "All set. Nobody nearby needs a buff."
L.STATUS_OOM = "Out of mana. The queue waits until you can cast again."

-- Choosing a key
L.CHOOSE_TITLE = "Choose your Buff Key"
L.KEY_PROMPT = "Press a key, or click or scroll anywhere on screen. Hold Ctrl, Alt or Shift for a combo.\nEscape cancels. Backspace or Delete clears your key."
L.KEY_MOUSE_TAKEN = "Left and right click are taken. Pick another button, or hold Ctrl, Alt or Shift with it."
L.KEY_IN_USE = "%s is already bound to %s.\nUse it for ZEUS while ZEUS is enabled? It goes back when ZEUS is disabled."
L.USE_KEY = "Use this key"
L.CANCEL = "Cancel"

-- Minimap button
L.MINIMAP_ON = "ZEUS is enabled"
L.MINIMAP_OFF = "ZEUS is disabled"
L.MINIMAP_PLATES_SHOWN = "Friendly nameplates: shown"
L.MINIMAP_PLATES_HIDDEN = "Friendly nameplates: hidden"
L.MINIMAP_KEY_AFTER_COMBAT = "Your key goes back to normal after combat"
L.MINIMAP_KEY_RELEASED = "Your key is back to normal"
L.MINIMAP_LEFT = "Left-click: settings"
L.MINIMAP_RIGHT_ON = "Right-click: enable ZEUS"
L.MINIMAP_RIGHT_OFF = "Right-click: disable ZEUS"
L.MINIMAP_DRAG = "Drag: move this button"
L.MINIMAP_KEY = "Buff Key: %s"
L.KEY_NOT_SET = "not set"
L.PAUSED_GAMEPAD = "Paused: gamepad UI"

-- Chat
L.HINT = "Type /zeus to pick a Buff Key or grab the Buff macro."
L.NEED_PLATES = "ZEUS needs friendly nameplates. Press %s to show them."
L.NEED_PLATES_NO_KEY = "ZEUS needs friendly nameplates. Turn them on in the game's options, or set a key for \"%s\" in %s."
L.NO_COMBAT_TOGGLE = "You can't enable or disable ZEUS in combat."
L.NO_COMBAT_KEY = "You can't change the Buff Key in combat."
L.NO_COMBAT_SETTINGS = "You can't open the ZEUS window in combat."
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
L.REPORT_SPELL = "%s: %.2f buff-hours"
L.REPORT_RANK = "  - Rank %d: %.2f"
L.REPORT_VERSION = "  - %s: %.2f"
L.REPORT_UNSPLIT = "Earlier buff-hours, from before ZEUS split them by spell: %.2f"
L.BLOCKER_LEARNED = "%s blocks %s (rank %d and lower), so ZEUS skips players who have it. /zeus blockers shows the list."
L.BLOCKER_GUESSED = "%s seems to block %s (rank %d and lower), so ZEUS skips players who have it and double-checks now and then. /zeus blockers shows the list."
L.BLOCKER_FORGOTTEN = "%s doesn't block %s after all. ZEUS forgot it."
L.BLOCKER_ROW = "%s (%d) blocks %s, rank %d and lower."
L.BLOCKER_ROW_GUESS = "%s (%d) blocks %s, rank %d and lower (a guess ZEUS double-checks)."
L.BLOCKERS_NONE = "ZEUS hasn't learned any blocking buffs yet."
L.BLOCKERS_CLEAR_HINT = "/zeus blockers clear forgets them."
L.BLOCKERS_CLEARED = "Forgot all blocking buffs."
L.UNKNOWN_BUFF = "Unknown buff"
L.GIVEN_BY = "Given by: %s"
L.GIVEN_BY_UNKNOWN = "Given by: someone out of sight"
L.AURAS_HEADER = "Buffs on %s:"
L.AURAS_NONE = "%s has no buffs."
L.AURAS_HIDDEN = "The game won't show the buffs on %s right now."
L.AURA_ROW = "%s, spell ID %d, %s, from %s"
L.AURA_MINUTES = "%d min left"
L.AURA_NO_TIMER = "no timer"
L.AURA_FROM_YOU = "you"
L.AURA_FROM_UNKNOWN = "someone out of sight"
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
