local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
-- Protect buffs from right-click (Advanced, off by default). The game's buff frame removes a buff
-- on a right-click. With protection on, its buttons take left-clicks only (the whisper in
-- Givers.lua still works), so a right-click alone reaches nothing. ZEUS sees the mouse button
-- come up instead, and lets that one button take right-clicks again for five seconds, with
-- "Right-click to confirm removal" in its tooltip. The second right-click then goes to the game's
-- own click handler, which removes the buff (or weapon enchant) as it always has, in combat too:
-- ZEUS never removes a buff itself. After five seconds, once the button shows another buff, or
-- after the removal, the button takes left-clicks only again and its tooltip is as it was.
local L = Z.L
local CONFIRM_SECONDS = 5
local protecting = false -- the buttons take left-clicks only
local armed, armedAura, token = nil, nil, 0
local hooked = {}
local function safe(v) return Z.Safe(v) end

-- The game's buff frames: your buffs, the ones folded into consolidated buffs, and external
-- defensives. Each of their buttons removes its buff on a right-click.
local function holders() -- gp:buff-protect
    local list = {}
    local frame = BuffFrame -- gp:buff-protect
    if type(frame) == "table" then
        list[#list + 1] = frame
        local folded = frame.ConsolidatedBuffs
        if type(folded) == "table" and type(folded.Tooltip) == "table" and type(folded.Tooltip.Auras) == "table" then
            list[#list + 1] = folded.Tooltip.Auras
        end
    end
    if type(ExternalDefensivesFrame) == "table" then list[#list + 1] = ExternalDefensivesFrame end -- gp:buff-protect
    return list
end
local function buttons()
    local list = {}
    for _, holder in ipairs(holders()) do
        for _, b in ipairs(type(holder.auraFrames) == "table" and holder.auraFrames or {}) do
            if type(b) == "table" and not b.isAuraAnchor and type(b.RegisterForClicks) == "function" then
                list[#list + 1] = b
            end
        end
    end
    return list
end
-- Left-clicks only, or both as the game sets them.
local function clicks(button, both) -- gp:buff-protect
    if both then button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    else button:RegisterForClicks("LeftButtonUp") end
end
-- Which buff (or weapon enchant slot) a button shows, to tell when it moves on to another.
local function shown(button)
    local info = button.buttonInfo
    if type(info) ~= "table" then return nil end
    local id = info.auraInstanceID
    if id == nil then id = info.ID end
    if not safe(id) then return nil end
    return id
end
-- Redraws the tooltip if it is over that button, so the confirm line comes and goes at once.
local function retip(button) -- gp:buff-protect
    if not button or type(GameTooltip) ~= "table" or not GameTooltip.IsOwned or not GameTooltip:IsOwned(button) then return end
    if type(GameTooltip.RefreshData) == "function" then
        GameTooltip:RefreshData()
    elseif armed == button and not Z.TooltipHasLine(GameTooltip, L.CONFIRM_REMOVAL) then
        GameTooltip:AddLine(L.CONFIRM_REMOVAL, 1, 0.35, 0.35)
        GameTooltip:Show()
    end
end
local function disarm()
    local button = armed
    armed, armedAura = nil, nil
    token = token + 1
    if not button then return end
    if protecting then clicks(button, false) end
    retip(button)
end
local function arm(button)
    disarm()
    armed, armedAura = button, shown(button)
    local mine = token
    -- The right-click that armed it is still being handled: the button takes right-clicks
    -- from the next frame, so this one can't remove the buff.
    C_Timer.After(0, function() if armed == button and token == mine and protecting then clicks(button, true) end end)
    C_Timer.After(CONFIRM_SECONDS, function() if token == mine then disarm() end end)
    retip(button)
end
-- After the game's own handler (if any): the first right-click arms the button, the second
-- (the game removes the buff with it) disarms it on the next frame.
local function onMouseUp(button, mouse) -- gp:buff-protect
    if mouse ~= "RightButton" or not protecting or not Z.Allowed("buff-protect") then return end
    if button.isExample then return end
    local kind = button.auraType
    if not safe(kind) or (kind ~= "Buff" and kind ~= "TempEnchant") then return end
    if armed == button then
        local mine = token
        C_Timer.After(0, function() if token == mine then disarm() end end)
        return
    end
    arm(button)
end
-- The confirm line, under everything else in the tooltip of the button waiting for its second
-- right-click.
local function postCall(tooltip) -- gp:buff-protect
    if not armed or type(tooltip) ~= "table" or not tooltip.GetOwner then return end
    if tooltip:GetOwner() ~= armed or not Z.Allowed("buff-protect") then return end
    if not Z.TooltipHasLine(tooltip, L.CONFIRM_REMOVAL) then tooltip:AddLine(L.CONFIRM_REMOVAL, 1, 0.35, 0.35) end
end

-- Puts the buttons the way the setting and the gamepad gate want them. Nothing of the game's is
-- touched until protection is first turned on.
function Z.ApplyBuffProtection()
    disarm()
    local want = Z.db and Z.db.protectBuffs == true and Z.Allowed("buff-protect") or false
    if not want and not protecting then return end
    protecting = want
    for _, b in ipairs(buttons()) do
        if want and not hooked[b] then
            hooked[b] = true
            b:HookScript("OnMouseUp", onMouseUp) -- gp:buff-protect
        end
        clicks(b, not want)
    end
    -- A button that moves on to another buff stops waiting for its second right-click.
    if want then
        local function moved()
            if armed and (not armed:IsShown() or shown(armed) ~= armedAura) then disarm() end
        end
        for _, holder in ipairs(holders()) do
            if not hooked[holder] and type(holder.UpdateAuraButtons) == "function" then
                hooked[holder] = true
                hooksecurefunc(holder, "UpdateAuraButtons", moved) -- gp:buff-protect
            end
        end
    end
end
-- The Advanced box.
function Z.SetProtectBuffs(on)
    Z.db.protectBuffs = on and true or false
    Z.ApplyBuffProtection()
    if Z.protectCheck then Z.protectCheck:SetChecked(Z.db.protectBuffs) end
end
Z.BuffProtection = {buttons = buttons, armed = function() return armed end}

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then -- gp:buff-protect
    TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes or "ALL", postCall) -- gp:buff-protect
end
Z.GamepadHooks("buff-protect", {park = function() Z.ApplyBuffProtection() end,
    install = function() Z.ApplyBuffProtection() end})
