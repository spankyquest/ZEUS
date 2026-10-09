local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
local L = Z.L
local function read(name)
    local get=(C_CVar and C_CVar.GetCVar) or GetCVar
    if type(get)~="function" then return nil end
    local ok,value=pcall(get,name)
    if not ok or not Z.Safe(value) then return nil end
    if value=="1" or value==1 or value==true then return true end
    if value=="0" or value==0 or value==false then return false end
    return nil -- An unsupported/unknown CVar is not an OFF setting.
end
local function setting()
    -- Forever's Friendly Players control uses the split player CVar. The old
    -- combined CVar can still exist but no longer control friendly players.
    for _,name in ipairs({"nameplateShowFriendlyPlayers","nameplateShowFriends"}) do
        local value=read(name)
        if value~=nil then return name,value end
    end
end
function Z.FriendsEnabled()
    local _,value=setting()
    return value==true
end
function Z.IsEnabled()
    return Z.db and Z.db.zeusEnabled==true
end
-- Scanning and arming: enabled, friendly nameplates shown, and not under the gamepad UI.
function Z.IsOperational()
    return Z.IsEnabled() and Z.FriendsEnabled() and not Z.GamepadUI()
end
local previousPlates,writing
local function update()
    if Z.runtimeInactive then return end
    local visible=Z.FriendsEnabled()
    if Z.db and not writing and (not visible or (previousPlates~=nil and visible~=previousPlates)) then
        -- Any external visibility change ends our ownership. A later Shift+V
        -- enable belongs to the player, not this addon.
        Z.db.nameplatesOwned=false
    end
    previousPlates=visible
    if Z.SyncNameplateState then Z.SyncNameplateState() end
    if Z.UpdateMinimap then Z.UpdateMinimap() end
end
function Z.SetZEUSEnabled(value,oneShot)
    if InCombatLockdown() then
        Z.Print(L.NO_COMBAT_TOGGLE) return false
    end
    if not Z.Allowed("nameplate-setting") then Z.Print(Z.GAMEPAD_PAUSED) return false end
    local name,current=setting()
    local set=(C_CVar and C_CVar.SetCVar) or SetCVar -- gp:nameplate-setting
    if previousPlates~=nil and current~=previousPlates then Z.db.nameplatesOwned=false end
    previousPlates=current
    local change=value and not current or (not value and Z.db.nameplatesOwned and current)
    if change then
        if not name or type(set)~="function" then
            Z.Print(L.NEED_PLATES) return false
        end
        writing=true
        local ok=pcall(set,name,value and "1" or "0") -- gp:nameplate-setting
        writing=false
        if not ok or read(name)~=value then
            update() Z.Print(L.NEED_PLATES) return false
        end
        Z.db.nameplatesOwned=value and true or false
    elseif not value then Z.db.nameplatesOwned=false end
    Z.db.zeusEnabled=value
    Z.oneShot=value and oneShot or nil
    Z.db.oneShotRun=Z.oneShot or nil
    update()
    if Z.Refresh then Z.Refresh() end
    return true
end
function Z.ToggleZEUS()
    return Z.SetZEUSEnabled(not Z.IsEnabled(),false)
end
local warnedOnDown
function Z.BeginBuffKey(down)
    if not Z.IsEnabled() then warnedOnDown=nil return false end
    if Z.FriendsEnabled() then warnedOnDown=nil return true end
    -- Two hardware edges belong to one press; wheel/release-only inputs still warn.
    if down or not warnedOnDown then
        Z.Print(L.NEED_PLATES)
    end
    warnedOnDown=down and true or nil
    return false
end
function Z.BeginBuffMacro()
    if InCombatLockdown() then return false end
    if not Z.IsEnabled() then
        return Z.SetZEUSEnabled(true,true)
    elseif not Z.FriendsEnabled() then
        Z.Print(L.NEED_PLATES)
        return false
    end
    return true
end
local frame=CreateFrame("Frame")
Z.nameplateFrame=frame
for _,event in ipairs({"CVAR_UPDATE","PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD"}) do
    frame:RegisterEvent(event)
end
frame:SetScript("OnEvent",update)
