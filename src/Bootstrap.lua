local addonName, Z = ...
local embedded=Z.ZEUSModule~=nil
Z = Z.ZEUSModule or Z
Z.portraitPath="Interface/AddOns/"..addonName..(embedded and "/"..Z.folder or "").."/Media/ZeusPortrait"
-- Shared identity only: no guild policy is imported into General.
local state = _G.ZEUSRuntimeSelection
if not state then
    state = {editions={}}
    _G.ZEUSRuntimeSelection = state
    local frame=CreateFrame("Frame")
    state.frame=frame
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent",function()
        if state.warned or not (state.editions.general and state.editions.olympus) then return end
        state.warned=true
        StaticPopupDialogs.ZEUS_EDITION_CONFLICT={
            text="Both ZEUS and ZEUS Olympus are enabled. ZEUS Olympus is running; ZEUS General is inactive. Please disable or uninstall one edition, then reload the UI.",
            button1="OK",timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
        }
        StaticPopup_Show("ZEUS_EDITION_CONFLICT")
    end)
end
state.editions[Z.edition]=Z
if Z.edition=="olympus" then
    if state.editions.general then state.editions.general.runtimeInactive=true end
    state.owner=Z
elseif state.editions.olympus then
    Z.runtimeInactive=true
else
    state.owner=Z
end
