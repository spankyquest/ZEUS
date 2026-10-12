local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
-- Buffs you received: who gave them. The tooltip of each of your buffs gets a "Given by" line,
-- and left-clicking one of your buffs opens a whisper to the giver, unless you're already
-- typing in chat (a right-click still removes the buff, after a second one with Protect buffs from
-- right-click on: Protect.lua). ZEUS only opens the whisper; you
-- type and send it. The game only names a buff's caster while it can see them as a unit (in your group, your
-- target, your mouseover or a nameplate); this client gives addons no combat log to look them
-- up later. So ZEUS notes the caster when each buff lands, refreshes or is replaced, and the
-- name stays known after they walk away. A buff whose caster the game never showed says so in
-- grey. Buffs from yourself and from creatures get no line. The givers ZEUS knows are kept across
-- a /reload or a log out and back in (see "Across /reloads and logins" below).
local L = Z.L
local function safe(v) return Z.Safe(v) end
-- One receipt per buff on you, by aura instance: {kind="player", name=, class=} for another
-- player, {kind="self"} or {kind="other"} (a creature or object) when nothing is shown, and
-- `expires` from the aura, to tell a rebuff from other updates.
local receipts = {}
Z.giverStats = {tooltips=0, lines=0, restored=0}
-- "Track buffs given to me" in settings (on unless the player turned it off).
local function tracking() return not Z.db or Z.db.trackGivers ~= false end

-- Who is behind a unit token: another player the game can name, you, or something else.
-- nil when the token is missing or the game won't say.
local function classify(unit)
    if not safe(unit) or type(unit) ~= "string" or unit == "" or not UnitExists(unit) then return end
    local guid, mine = UnitGUID(unit), UnitGUID("player")
    if not safe(guid) or not guid then return end
    if guid == mine then return {kind="self"} end
    if not UnitIsPlayer(unit) then return {kind="other"} end
    local name = Z.FullName(unit)
    if not name then return end
    local _, class = UnitClass(unit)
    return {kind="player", name=name, class=safe(class) and type(class) == "string" and class or nil, guid=guid}
end
local function expiresOf(aura)
    local e = aura.expirationTime
    if safe(e) and type(e) == "number" and e > 0 then return e end
end
-- Instant buff-back (Advanced, off by default): a player who has just buffed you goes first in the
-- queue, before your target, for a minute or until they need nothing of yours (Core.lua arms
-- them with Queue.lua's Z.BuffBackCandidate, as for a hovered buff). Oldest first.
local BACK_SECONDS = 60
local backs = {}
local function buffedBy(receipt)
    if not Z.db or Z.db.instantBuffBack ~= true or receipt.kind ~= "player" or not receipt.guid then return end
    for i = #backs, 1, -1 do if backs[i].giver.guid == receipt.guid then table.remove(backs, i) end end
    backs[#backs + 1] = {giver=receipt, at=GetTime()}
end
-- Note who cast a buff that landed (or was updated). A rebuff by someone the game can't name
-- (the buff now lasts longer) makes the old receipt wrong, so it is dropped. `fresh`: the buff
-- has just been cast on you (added, or updated to last longer), not read again at login.
local function note(aura, updated, fresh)
    if not safe(aura) or type(aura) ~= "table" then return end
    local id = aura.auraInstanceID
    if not safe(id) or type(id) ~= "number" or not safe(aura.isHelpful) or not aura.isHelpful then return end
    local receipt, expires = classify(aura.sourceUnit), expiresOf(aura)
    if receipt then
        local old = receipts[id]
        receipt.expires = expires
        receipts[id] = receipt
        if fresh and (not updated or not old or not old.expires or (expires and expires > old.expires + 1)) then
            buffedBy(receipt)
        end
    elseif updated then
        local old = receipts[id]
        if old and expires and (not old.expires or expires > old.expires + 1) then receipts[id] = nil end
    end
end
local function byInstance(id)
    local get = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID
    if not get or not safe(id) or type(id) ~= "number" then return end
    local ok, aura = pcall(get, "player", id)
    if ok and safe(aura) and type(aura) == "table" then return aura end
end

-- Across /reloads and logins. The game gives each buff a new instance number in a new session and
-- names no caster it can't see, so at logout (a /reload too) ZEUS saves, for each buff whose
-- giver it knows, the spell, its duration, the time left and the giver, with the time it saved
-- them. When the session starts, a buff without a giver takes a saved one's if the spell and
-- duration are the same and the time left fits: no more than when it was saved (a rebuff would
-- have more), and no less than that minus the real time since (buffs may pause while you're
-- logged out, or keep running through a /reload). The closest fit wins. What isn't matched in
-- the first 30 seconds is forgotten.
local pending, pendingAt, pendingUntil = nil, 0, 0
local function number(v) if safe(v) and type(v) == "number" then return v end end
local function claim(aura)
    if not pending or GetTime() > pendingUntil then pending = nil return end
    if not safe(aura) or type(aura) ~= "table" then return end
    local id, spell = number(aura.auraInstanceID), number(aura.spellId)
    if not id or not spell or receipts[id] then return end
    local expires = expiresOf(aura)
    local left, duration = expires and expires - GetTime(), number(aura.duration)
    local since = math.max(0, time() - pendingAt)
    local best, gap
    for i, p in ipairs(pending) do
        if p.spell == spell and (not duration or not p.duration or math.abs(duration - p.duration) < 1) then
            local fits, off
            if left and p.left then
                fits = left <= p.left + 3 and left >= p.left - since - 3
                off = math.abs(p.left - left)
            else
                fits, off = (left == nil) == (p.left == nil), 0
            end
            if fits and (not gap or off < gap) then best, gap = i, off end
        end
    end
    if best then
        local p = table.remove(pending, best)
        receipts[id] = {kind="player", name=p.name, class=p.class, guid=p.guid, expires=expires}
        Z.giverStats.restored = Z.giverStats.restored + 1
    end
end
-- At logout: the buffs whose giver ZEUS knows.
local function saveGivers()
    if not Z.db then return end
    Z.db.givers = nil
    if not tracking() then return end
    local list, now = {}, GetTime()
    local get = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID
    if not get then return end
    for id, r in pairs(receipts) do
        if r.kind == "player" then
            local ok, aura = pcall(get, "player", id)
            if ok and safe(aura) and type(aura) == "table" and number(aura.spellId) then
                local expires = expiresOf(aura)
                list[#list + 1] = {spell=aura.spellId, duration=number(aura.duration),
                    left=expires and expires - now or nil, name=r.name, class=r.class, guid=r.guid}
            end
        end
    end
    if #list > 0 then Z.db.givers = {at=time(), list=list} end
end
-- At login (and after a /reload): the saved givers, to match against your buffs.
function Z.LoadGivers()
    pending = nil
    local saved = Z.db and Z.db.givers
    if not tracking() or type(saved) ~= "table" or type(saved.list) ~= "table" then return end
    pending = {}
    for _, p in ipairs(saved.list) do
        if type(p) == "table" and type(p.spell) == "number" and type(p.name) == "string" and p.name ~= "" then
            pending[#pending + 1] = {spell=p.spell, duration=tonumber(p.duration), left=tonumber(p.left),
                name=p.name, class=type(p.class) == "string" and p.class or nil,
                guid=type(p.guid) == "string" and p.guid or nil}
        end
    end
    pendingAt, pendingUntil = tonumber(saved.at) or time(), GetTime() + 30
    Z.NoteGivers("player")
end

-- UNIT_AURA for the player: note who gave each buff that lands, is refreshed or replaced
-- (a replaced blessing is a new buff), and forget the ones that are gone. The game can hide
-- parts of an update as secret values (restricted moments, combat say): ZEUS never tests those,
-- skips what it can't read, and keeps what it noted until an update it can read.
-- `info` nil: read every buff again.
function Z.NoteGivers(unit, info)
    if not safe(unit) or unit ~= "player" or not tracking() then return end
    if not safe(info) or (info ~= nil and type(info) ~= "table") then return end
    local full = info == nil or info.isFullUpdate
    if not safe(full) then return end
    if full then
        local get = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
        if not get then return end
        local present, complete = {}, false
        for i = 1, 100 do
            local ok, aura = pcall(get, "player", i, "HELPFUL")
            if not ok or not safe(aura) then break end
            if not aura then complete = true break end
            note(aura, true)
            claim(aura)
            if safe(aura.auraInstanceID) and aura.auraInstanceID then present[aura.auraInstanceID] = true end
        end
        -- Forget the buffs that are gone only when every buff could be read.
        if complete then
            for id in pairs(receipts) do if not present[id] then receipts[id] = nil end end
        end
        return
    end
    local added, updated, removed = info.addedAuras, info.updatedAuraInstanceIDs, info.removedAuraInstanceIDs
    if safe(added) and type(added) == "table" then
        for _, aura in ipairs(added) do note(aura, false, true) claim(aura) end
    end
    if safe(updated) and type(updated) == "table" then
        for _, id in ipairs(updated) do note(byInstance(id), true, true) end
    end
    if safe(removed) and type(removed) == "table" then
        for _, id in ipairs(removed) do
            if safe(id) and id ~= nil then receipts[id] = nil end
        end
    end
end

-- The receipt for one of your buffs: the caster if the game can see them now, or the one noted
-- when it landed. false: a buff of yours whose caster the game never showed. nil: not a buff.
function Z.BuffReceipt(id)
    if not tracking() then return end
    local aura = byInstance(id)
    if not aura or not safe(aura.isHelpful) or not aura.isHelpful then return end
    local live = classify(aura.sourceUnit)
    if live then
        live.expires = expiresOf(aura)
        receipts[id] = live
    end
    return receipts[id] or false
end
function Z.BuffGiver(id)
    local receipt = Z.BuffReceipt(id)
    if receipt and receipt.kind == "player" then return receipt end
end

-- Buffing back. With the mouse over one of your buffs, the next press of the Buff Key or the
-- Buff macro buffs whoever gave it, if they need one of your buffs and ZEUS could buff them
-- anyway (Queue.lua's Z.BuffBackCandidate, armed by Core.lua ahead of the queue). That holds for a
-- few seconds after the mouse leaves too: time to click a Buff macro on an action bar.
local HOVER_GRACE = 3
local hovered -- {giver=, at=}
-- Your buff under the mouse: its aura instance, or nil.
local function buffUnderMouse()
    if type(GetMouseFoci) ~= "function" then return end
    local ok, foci = pcall(GetMouseFoci)
    if not ok or not safe(foci) or type(foci) ~= "table" then return end
    local frame = foci[1]
    if type(frame) ~= "table" then return end
    local read, kind, info, unit = pcall(function() return frame.auraType, frame.buttonInfo, frame.unit end)
    if not read or kind ~= "Buff" or type(info) ~= "table" or (unit ~= nil and unit ~= "player") then return end
    local got, id = pcall(function() return info.auraInstanceID end)
    if got and safe(id) and type(id) == "number" then return id end
end
function Z.HoveredGiver()
    if not tracking() or not Z.Allowed("buff-givers") then hovered = nil return end
    local id = buffUnderMouse()
    local giver = id and Z.BuffGiver(id)
    if giver then
        hovered = {giver=giver, at=GetTime()}
        return giver
    end
    if hovered and GetTime() - hovered.at < HOVER_GRACE then return hovered.giver end
    hovered = nil
end
-- Everyone to buff back before the queue, in order: the giver of a hovered buff, then (with
-- Instant buff-back) the players who have just buffed you, oldest first.
function Z.BuffBackGivers()
    local list = {}
    local giver = Z.HoveredGiver()
    if giver then list[1] = giver end
    if Z.db and Z.db.instantBuffBack == true and tracking() and Z.Allowed("buff-givers") then
        local now = GetTime()
        for i = #backs, 1, -1 do if now - backs[i].at >= BACK_SECONDS then table.remove(backs, i) end end
        for _, b in ipairs(backs) do list[#list + 1] = b.giver end
    end
    return list
end
-- The Advanced box. Off forgets who has just buffed you.
function Z.SetInstantBuffBack(on)
    Z.db.instantBuffBack = on and true or false
    if not on then for i = #backs, 1, -1 do backs[i] = nil end end
    if Z.instantBackCheck then Z.instantBackCheck:SetChecked(Z.db.instantBuffBack) end
end
local function colored(giver)
    local color = giver.class and type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[giver.class]
    if type(color) == "table" and type(color.colorStr) == "string" then
        return "|c" .. color.colorStr .. giver.name .. "|r"
    end
    return giver.name
end
-- What /zeus debug says about receipts.
function Z.GiverDebug()
    local known, unseen, n = 0, 0, 0
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 100 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not ok or not safe(aura) or not aura then break end
            n = n + 1
            local receipt = safe(aura.auraInstanceID) and Z.BuffReceipt(aura.auraInstanceID)
            if receipt and receipt.kind == "player" then known = known + 1
            elseif receipt == false then unseen = unseen + 1 end
        end
    end
    return string.format("buffs on you %d: giver known %d, giver not seen %d | restored after login %d | tracking %s | tooltip calls %d, lines added %d",
        n, known, unseen, Z.giverStats.restored, tracking() and "on" or "off", Z.giverStats.tooltips, Z.giverStats.lines)
end

-- Which of your buffs a tooltip shows: from the game's getter and its arguments, or from the
-- buff button that owns the tooltip.
local BY_INSTANCE = {GetUnitAuraByAuraInstanceID=true, GetUnitBuffByAuraInstanceID=true}
local BY_INDEX = {GetUnitAura=true, GetUnitBuff=true}
local function auraByGetter(getterName, unit, which, filter)
    if not safe(unit) or unit ~= "player" or not safe(which) or type(which) ~= "number" then return end
    if BY_INSTANCE[getterName] then return which end
    if BY_INDEX[getterName] and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        if getterName == "GetUnitBuff" or not safe(filter) or type(filter) ~= "string" then filter = "HELPFUL" end
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", which, filter)
        if ok and safe(aura) and type(aura) == "table" and safe(aura.auraInstanceID) then return aura.auraInstanceID end
    end
end
local function auraOfOwner(tooltip)
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    if type(owner) ~= "table" or owner.auraType ~= "Buff" or type(owner.buttonInfo) ~= "table" then return end
    if owner.unit ~= nil and owner.unit ~= "player" then return end
    local id = owner.buttonInfo.auraInstanceID
    if safe(id) and type(id) == "number" then return id end
end
-- Whether a tooltip already has a line, to add ours only once when more than one hook sees the
-- same tooltip (Protect.lua's line can come after this one).
function Z.TooltipHasLine(tooltip, text)
    local n = tooltip.NumLines and tooltip:NumLines()
    local name = tooltip.GetName and tooltip:GetName()
    if type(n) ~= "number" or type(name) ~= "string" then return false end
    for i = 1, n do
        local line = _G[name .. "TextLeft" .. i]
        if line and line.GetText and line:GetText() == text then return true end
    end
    return false
end
local function addReceipt(tooltip, id, show)
    Z.giverStats.tooltips = Z.giverStats.tooltips + 1
    if not id or not Z.Allowed("buff-givers") then return end
    local receipt = Z.BuffReceipt(id)
    local text, r, g, b
    if receipt and receipt.kind == "player" then
        text, r, g, b = string.format(L.GIVEN_BY, colored(receipt)), 1, 1, 1
    elseif receipt == false then
        text, r, g, b = L.GIVEN_BY_UNKNOWN, 0.6, 0.6, 0.6
    end
    if not text or Z.TooltipHasLine(tooltip, text) then return end
    tooltip:AddLine(text, r, g, b)
    Z.giverStats.lines = Z.giverStats.lines + 1
    if show then tooltip:Show() end
end
-- The game's tooltip processor, for every tooltip type (the type a buff tooltip reports is not
-- relied on): the getter says whether it is one of your buffs.
local function postCall(tooltip) -- gp:buff-givers
    if type(tooltip) ~= "table" then return end
    local info = tooltip.GetProcessingTooltipInfo and tooltip:GetProcessingTooltipInfo()
    local id
    if safe(info) and type(info) == "table" and safe(info.getterName) and safe(info.getterArgs)
        and type(info.getterArgs) == "table" then
        id = auraByGetter(info.getterName, info.getterArgs[1], info.getterArgs[2], info.getterArgs[3])
    end
    if not id then id = auraOfOwner(tooltip) end
    if id then addReceipt(tooltip, id) end
end
-- And the game tooltip's own aura setters, after they have run: the same line, added once.
local function setterHook(getterName)
    return function(tooltip, ...) -- gp:buff-givers
        local id = auraByGetter(getterName, ...) or auraOfOwner(tooltip)
        if id then addReceipt(tooltip, id, true) end
    end
end

-- The settings box: off forgets every receipt (and the saved ones); on notes the givers of the
-- buffs you have now, wherever the game can still see them, and keeps what it knew.
function Z.SetTrackGivers(on)
    Z.db.trackGivers = on and true or false
    if not on then
        for id in pairs(receipts) do receipts[id] = nil end
        pending, Z.db.givers = nil, nil
    end
    if on then Z.NoteGivers("player") end
    if Z.giversCheck then Z.giversCheck:SetChecked(Z.db.trackGivers) end
end
-- Whether you're typing in chat. When the game can't say, ZEUS assumes you are: it never
-- interrupts a message.
local function typing()
    local active = ChatFrameUtil and ChatFrameUtil.GetActiveWindow -- gp:buff-whisper
    if type(active) ~= "function" then return true end
    local ok, box = pcall(active)
    return not ok or box ~= nil
end
-- Left-clicking one of your buffs: a whisper to whoever gave it, with the game's own whisper
-- (/w and their name), ready for you to type.
local function onBuffClick(_, button, mouse) -- gp:buff-whisper
    if mouse ~= "LeftButton" or not Z.Allowed("buff-whisper") then return end
    if type(button) ~= "table" or button.auraType ~= "Buff" or type(button.buttonInfo) ~= "table" then return end
    local giver = Z.BuffGiver(button.buttonInfo.auraInstanceID)
    if not giver or typing() then return end
    local tell = ChatFrameUtil and ChatFrameUtil.SendTell -- gp:buff-whisper
    if type(tell) == "function" then pcall(tell, giver.name) end
end

-- The game's own extension points, registered once: a tooltip post-call, hooks that run after
-- the game tooltip's aura setters, and the buff frame's BuffButton.OnClick event. Each checks
-- the gamepad gate every time it runs.
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then -- gp:buff-givers
    TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes or "ALL", postCall) -- gp:buff-givers
end
if type(hooksecurefunc) == "function" and type(GameTooltip) == "table" then -- gp:buff-givers
    for setter, getterName in pairs({SetUnitAuraByAuraInstanceID="GetUnitAuraByAuraInstanceID",
        SetUnitBuffByAuraInstanceID="GetUnitBuffByAuraInstanceID", SetUnitAura="GetUnitAura", SetUnitBuff="GetUnitBuff"}) do
        if type(GameTooltip[setter]) == "function" then -- gp:buff-givers
            hooksecurefunc(GameTooltip, setter, setterHook(getterName)) -- gp:buff-givers
        end
    end
end
if EventRegistry and EventRegistry.RegisterCallback then -- gp:buff-whisper
    Z.giversOwner = Z.giversOwner or {}
    EventRegistry:RegisterCallback("BuffButton.OnClick", onBuffClick, Z.giversOwner) -- gp:buff-whisper
end
-- Saved at logout (and before a /reload); read again once the world is up, when every buff is in.
local session = CreateFrame("Frame")
session:RegisterEvent("PLAYER_LOGOUT")
session:RegisterEvent("PLAYER_ENTERING_WORLD")
session:SetScript("OnEvent", function(_, event)
    if Z.runtimeInactive or not Z.db then return end
    if event == "PLAYER_LOGOUT" then saveGivers() elseif pending then Z.NoteGivers("player") end
end)
Z.giversSession = session
