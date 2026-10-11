local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
-- Buffs you received: who gave them. The tooltip of each of your buffs gets a "Given by" line,
-- and left-clicking one of your buffs opens a whisper to the giver, unless you're already
-- typing in chat (right-click on the buff still removes it). ZEUS only opens the whisper; you
-- type and send it. The game only names a buff's caster while it can see them as a unit (in your group, your
-- target, your mouseover or a nameplate); this client gives addons no combat log to look them
-- up later. So ZEUS notes the caster when each buff lands, refreshes or is replaced, and the
-- name stays known after they walk away. A buff whose caster the game never showed says so in
-- grey. Notes last for the session; buffs from yourself and from creatures get no line.
local L = Z.L
local function safe(v) return Z.Safe(v) end
-- One receipt per buff on you, by aura instance: {kind="player", name=, class=} for another
-- player, {kind="self"} or {kind="other"} (a creature or object) when nothing is shown, and
-- `expires` from the aura, to tell a rebuff from other updates.
local receipts = {}
Z.giverStats = {tooltips=0, lines=0}
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
    return {kind="player", name=name, class=safe(class) and type(class) == "string" and class or nil}
end
local function expiresOf(aura)
    local e = aura.expirationTime
    if safe(e) and type(e) == "number" and e > 0 then return e end
end
-- Note who cast a buff that landed (or was updated). A rebuff by someone the game can't name
-- (the buff now lasts longer) makes the old receipt wrong, so it is dropped.
local function note(aura, updated)
    if not safe(aura) or type(aura) ~= "table" then return end
    local id = aura.auraInstanceID
    if not safe(id) or type(id) ~= "number" or not safe(aura.isHelpful) or not aura.isHelpful then return end
    local receipt, expires = classify(aura.sourceUnit), expiresOf(aura)
    if receipt then
        receipt.expires = expires
        receipts[id] = receipt
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
        for _, aura in ipairs(added) do note(aura) end
    end
    if safe(updated) and type(updated) == "table" then
        for _, id in ipairs(updated) do note(byInstance(id), true) end
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
    return string.format("buffs on you %d: giver known %d, giver not seen %d | tracking %s | tooltip calls %d, lines added %d",
        n, known, unseen, tracking() and "on" or "off", Z.giverStats.tooltips, Z.giverStats.lines)
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
-- The tooltip's last line, to add ours only once when more than one hook sees the same tooltip.
local function lastLine(tooltip)
    local n = tooltip.NumLines and tooltip:NumLines()
    local name = tooltip.GetName and tooltip:GetName()
    local line = type(n) == "number" and n > 0 and type(name) == "string" and _G[name .. "TextLeft" .. n]
    return line and line.GetText and line:GetText()
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
    if not text or lastLine(tooltip) == text then return end
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

-- The settings box: off forgets every receipt; on notes the givers of the buffs you have now,
-- wherever the game can still see them.
function Z.SetTrackGivers(on)
    Z.db.trackGivers = on and true or false
    for id in pairs(receipts) do receipts[id] = nil end
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
