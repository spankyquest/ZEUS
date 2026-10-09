local addonName, Z = ...
local embedded=Z.ZEUSModule~=nil
Z = Z.ZEUSModule or Z
Z.portraitPath="Interface/AddOns/"..addonName..(embedded and "/"..Z.folder or "").."/Media/ZeusPortrait"
-- Shared identity only: no guild policy is imported into General.
-- Runtime selection across every loaded copy: the Olympus edition wins over General, and a
-- second copy of the same edition (for example one embedded in another addon) stays inactive.
local state = _G.ZEUSRuntimeSelection
-- The gamepad gate's test (Gamepad.lua), here because this file runs before the gate loads.
local function gamepadUI()
    local current = C_InputInterfaceStyle and C_InputInterfaceStyle.GetCurrentStyle
    local gamepad = Enum and Enum.InputDeviceInterfaceType and Enum.InputDeviceInterfaceType.Gamepad
    if type(current) ~= "function" or gamepad == nil then return false end
    local ok, style = pcall(current)
    return ok and style == gamepad
end
local function say(text) DEFAULT_CHAT_FRAME:AddMessage("|cffffd166ZEUS:|r "..text) end -- gp:chat-output
if not state then
    state = {editions={}}
    _G.ZEUSRuntimeSelection = state
    local frame=CreateFrame("Frame")
    state.frame=frame
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent",function()
        if state.warned then return end
        if state.duplicates then
            state.warned=true
            say(Z.L.DUPLICATE)
        end
        if not (state.editions.general and state.editions.olympus) then return end
        state.warned=true
        local text=Z.L.BOTH_EDITIONS
        -- With the gamepad UI, a game popup opened by an addon breaks the game's popups.
        if gamepadUI() then say(text) return end
        StaticPopupDialogs.ZEUS_EDITION_CONFLICT={ -- gp:popup
            text=text,button1=Z.L.OK,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
        }
        StaticPopup_Show("ZEUS_EDITION_CONFLICT") -- gp:popup
    end)
end
if state.editions[Z.edition] then
    Z.runtimeInactive=true
    state.duplicates=(state.duplicates or 0)+1
else
    state.editions[Z.edition]=Z
    if Z.edition=="olympus" then
        if state.editions.general then state.editions.general.runtimeInactive=true end
        state.owner=Z
    elseif state.editions.olympus then
        Z.runtimeInactive=true
    else
        state.owner=Z
    end
end
