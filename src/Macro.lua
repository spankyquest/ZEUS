local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
local buffClick="/click ZEUSMacroBuffButton LeftButton"
local buffMarker="#ZEUS-BUFF\n"
local definitions={
    toggle={body="/zeus toggle",name="ZEUS Toggle",icon=136048},
    buff={body=buffMarker..buffClick,previous="/click ZEUSMacroBuffButton LeftButton 1\n/click ZEUSMacroBuffButton LeftButton",legacy="/click ZEUSBuffButton LeftButton",name="ZEUS Buff",icon=136015},
}
local function validIcon(icon)
    return type(icon)=="number" and icon>0
end
local function safeName(name)
    return type(name)=="string" and name~="" and not name:find("[%c%[%];/]") and not name:find("\\",1,true)
end
local function buffBody()
    local c=Z.current
    if Z.IsOperational() and c and safeName(c.name) then
        return buffMarker.."/targetexact [nocombat] "..c.name.."\n"..buffClick,c.guid
    end
    return buffMarker..buffClick,nil
end
local function matches(text,kind)
    if type(text)~="string" then return false end
    text=text:match("^%s*(.-)%s*$")
    if kind=="buff" then
        if text==definitions.buff.body then return true end
        local name=text:match("^#ZEUS%-BUFF\n/targetexact %[nocombat%] ([^\r\n]+)\n/click ZEUSMacroBuffButton LeftButton$")
        return safeName(name)
    end
    return text==definitions.toggle.body
end
-- Account and character macro limits; either may be unknown on some clients.
local function limits()
    local c=Constants and Constants.MacroConsts
    return MAX_ACCOUNT_MACROS or (c and c.MAX_ACCOUNT_MACROS),
        MAX_CHARACTER_MACROS or (c and c.MAX_CHARACTER_MACROS)
end
local function capacity()
    local account,character=limits()
    return (account or 0)+(character or 0)
end
-- Runs when the armed recipient changes. Z.buffMacroStale asks the next
-- refresh to try again after combat or a failed edit.
function Z.SyncBuffMacro()
    if InCombatLockdown() then Z.buffMacroStale=true return end
    if not GetMacroInfo or not EditMacro then return end
    local body,guid=buffBody()
    local found,verified=false,false
    for i=1,capacity() do
        local _,icon,text=GetMacroInfo(i)
        if matches(text,"buff") then
            found=true
            if text~=body or icon~=definitions.buff.icon then pcall(EditMacro,i,nil,definitions.buff.icon,body) end
            local _,_,saved=GetMacroInfo(i)
            if saved==body then verified=true end
        end
    end
    Z.buffMacroGUID=verified and guid or nil
    Z.buffMacroStale=found and not verified
end
local syncPending=false
function Z.ScheduleBuffMacroSync()
    if syncPending then return end
    syncPending=true
    -- Do not rewrite a macro between its target command and receiver click.
    C_Timer.After(0,function() syncPending=false Z.SyncBuffMacro() end)
end
function Z.EnsureToggleMacro(kind)
    kind=kind or "toggle"
    local definition=definitions[kind]
    local body,toggleIcon=definition.body,definition.icon
    if kind=="buff" then body=buffBody() end
    if InCombatLockdown() then Z.Print("Leave combat before adding a macro to your action bar.") return false end
    if GetCursorInfo and GetCursorInfo() then
        Z.Print("Place or clear what's on your cursor first.") return false
    end
    if not (GetMacroInfo and CreateMacro and GetNumMacros) then
        Z.Print("Open the game's Macros window and create a macro containing "..body..".") return false
    end
    local accountMax,characterMax=limits()
    if not accountMax or not characterMax then
        Z.Print("Open the game's Macros window and create a macro containing "..body..".") return false
    end
    local names,index,createdHere={},nil,false
    local function compatible(text)
        return matches(text,kind) or (definition.legacy and text==definition.legacy) or (definition.previous and text==definition.previous)
    end
    for i=1,capacity() do
        local name,_,text=GetMacroInfo(i)
        if name then names[name]=true end
        if compatible(text) and not index then index=i end
    end
    if not index then
        local accountCount,characterCount=GetNumMacros()
        local perCharacter=characterCount<characterMax
        if not perCharacter and accountCount>=accountMax then
            Z.Print("Your macro slots are full. Free a slot, then try again.") return false
        end
        local name=definition.name
        local suffix=2
        while names[name] do name=definition.name.." "..suffix suffix=suffix+1 end
        local ok,result=pcall(CreateMacro,name,toggleIcon,body,perCharacter)
        if not ok or type(result)~="number" or result<=0 then
            Z.Print("Macro creation failed: "..tostring(result)..". Create one manually with "..body..".") return false
        end
        index=result
        createdHere=true
    end
    local name,icon,text=GetMacroInfo(index)
    if not compatible(text) then Z.Print("Could not verify the ZEUS macro. Try again.") return false end
    -- Earlier versions wrote a texture path which may produce a blank icon.
    -- Commit only the verified ZEUS macro, preserving its name and scope.
    if text~=body or not validIcon(icon) or (kind=="buff" and icon~=definition.icon) or (createdHere and EditMacro) then
        if not EditMacro then Z.Print("Choose an icon for "..name.." in /macro, then Save.") return false end
        local ok,result=pcall(EditMacro,index,nil,toggleIcon,body)
        if not ok then Z.Print("Could not save the ZEUS macro: "..tostring(result)) return false end
        if type(result)=="number" and result>0 then index=result end
        local savedName,savedIcon,savedBody=GetMacroInfo(index)
        if savedName~=name or not validIcon(savedIcon) or savedBody~=body then
            Z.Print("Could not verify the saved ZEUS macro. Choose an icon in /macro and Save.") return false
        end
    end
    if kind=="buff" then Z.SyncBuffMacro() end
    return index
end
function Z.PrepareToggleMacroButton(button,kind)
    if InCombatLockdown() then return false end
    local index=Z.EnsureToggleMacro(kind)
    button:SetAttribute("zeus-macro",index or nil)
    return index
end
function Z.OpenToggleMacroFallback(index,kind)
    if InCombatLockdown() or (GetCursorInfo and GetCursorInfo()) then return false end
    local name,_,text=GetMacroInfo(index)
    if not name or not matches(text,kind) then return false end
    -- Use the game's own macro window when this client refuses GUI pickup.
    -- Never clear the cursor, place an action, or overwrite another macro.
    local opened=false
    if MacroFrame_LoadUI then
        local loaded=pcall(MacroFrame_LoadUI)
        if loaded and MacroFrame and ShowUIPanel then
            local ok=pcall(ShowUIPanel,MacroFrame)
            opened=ok and MacroFrame:IsShown()
        end
    end
    Z.Print((opened and "Drag " or "Open /macro and drag ")..'"'..name..'" from the Macros window onto your action bar.')
    return opened
end
function Z.CheckMacroPickup(ok,err,index,source,kind)
    if not ok then
        Z.Print((source or "Click").." macro pickup failed: "..tostring(err)..".")
        if index then Z.OpenToggleMacroFallback(index,kind) end
        return false
    end
    if GetCursorInfo then
        local cursorKind=GetCursorInfo()
        if cursorKind~="macro" then
            Z.Print((source or "Click").." macro pickup returned cursor type "..tostring(cursorKind).."; expected macro.")
            if index and not cursorKind then Z.OpenToggleMacroFallback(index,kind) end
            return false
        end
    end
    return true
end
function Z.PickupToggleMacro(kind)
    local index=Z.EnsureToggleMacro(kind)
    if not index then return false end
    if type(PickupMacro)~="function" then Z.Print("Macro pickup API is unavailable.") return false end
    local ok,err=pcall(PickupMacro,index)
    return Z.CheckMacroPickup(ok,err,index,"Click",kind)
end
function Z.ConfigureToggleMacroButton(button,kind)
    button:SetAttribute("_ondragstart", [[
        if (button and button ~= "LeftButton") or kind or self:GetAttribute("state-combat") == "combat" then return end
        local index = self:GetAttribute("zeus-macro")
        if index then return "macro", index end
    ]])
    RegisterStateDriver(button,"combat","[combat] combat; clear")
    button:SetScript("OnMouseDown",function(self,mouse)
        self.dragged=nil
        if mouse=="LeftButton" then Z.PrepareToggleMacroButton(self,kind) end
    end)
    -- Keep Blizzard's inherited OnDragStart intact. The trusted handler consumes
    -- the snippet's macro/index return and performs pickup; addon Lua does not.
    button:HookScript("OnDragStart",function(self,mouse)
        if mouse and mouse~="LeftButton" then return end
        self.dragged=true
        if not InCombatLockdown() and self:GetAttribute("zeus-macro") then
            Z.CheckMacroPickup(true,nil,self:GetAttribute("zeus-macro"),"Drag",kind)
        end
    end)
    button:SetScript("OnClick",function(self)
        if self.dragged then self.dragged=nil return end
        Z.PickupToggleMacro(kind)
    end)
    button:RegisterEvent("UPDATE_MACROS")
    button:SetScript("OnEvent",function(self)
        if InCombatLockdown() then return end
        -- Re-resolve existing content without creating macros in an event.
        local index
        if GetMacroInfo then
            for i=1,capacity() do
                local _,_,text=GetMacroInfo(i)
                if matches(text,kind) then index=i break end
            end
        end
        self:SetAttribute("zeus-macro",index)
    end)
end
