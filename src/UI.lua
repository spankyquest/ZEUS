local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
local L = Z.L
local settings, minimap, capture, catcher, bindButton, status, thresholdText, warning, enableButton
local rows, pendingKey = {}, nil
local slider
Z.priorityEditors={}
local gold={1,0.82,0}
local function section(parent,x,y,width,height)
    local box=CreateFrame("Frame",nil,parent,"InsetFrameTemplate")
    box:SetPoint("TOPLEFT",x,y) box:SetSize(width,height)
    box:SetFrameLevel(parent:GetFrameLevel())
    box:EnableMouse(false)
    return box
end
local function rowShade(parent,x,y,width,height,shade)
    local fill=parent:CreateTexture(nil,"BACKGROUND",nil,1)
    fill:SetPoint("TOPLEFT",x,y) fill:SetSize(width,height)
    fill:SetColorTexture(shade,shade,shade,0.7)
end
local function label(parent,text,x,y,width,font)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT",x,y)
    t:SetWidth(width or 450)
    t:SetJustifyH("LEFT")
    t:SetText(text)
    return t
end
local function panel(name,width,height,parent,withPortrait)
    local template=withPortrait and "PortraitFrameTemplate" or "BasicFrameTemplateWithInset"
    local ok,f=pcall(CreateFrame,"Frame",name,parent or UIParent,template)
    if not ok or not f then
        f=CreateFrame("Frame",name,parent or UIParent,"BackdropTemplate")
        f:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",
            edgeFile="Interface/DialogFrame/UI-DialogBox-Border",tile=true,tileSize=16,edgeSize=24,
            insets={left=8,right=8,top=8,bottom=8}})
        f:SetBackdropColor(0.06,0.06,0.06,1)
    end
    f:SetSize(width,height)
    f:EnableMouse(true)
    -- Hide directly so the close button also works while in combat.
    local close=f.CloseButton or CreateFrame("Button",nil,f,"UIPanelCloseButton")
    if not f.CloseButton then close:SetPoint("TOPRIGHT",-3,-3) end
    close:SetScript("OnClick",function() f:Hide() end)
    f.CloseButton=close
    return f
end
local function title(frame,text)
    local t=frame.TitleText or (frame.TitleContainer and frame.TitleContainer.TitleText)
    if t then t:SetText(text)
    else
        t=label(frame,text,70,-8,620,"GameFontNormal")
        t:SetJustifyH("CENTER")
    end
end
local function action(parent,text,x,y,w,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(w or 160,26)
    b:SetPoint("TOPLEFT",x,y)
    b:SetText(text)
    b:SetScript("OnClick",fn)
    return b
end
local function check(parent,text,x,y,fn)
    local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    b:SetSize(26,26)
    b:SetPoint("TOPLEFT",x,y)
    b.caption=label(parent,text,x+31,y-6,380,"GameFontHighlight")
    b:SetScript("OnClick",function(self) fn(self:GetChecked() and true or false,self) end)
    return b
end
local function tooltip(control,text) -- gp:tooltips
    control:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:AddLine(text,0.9,0.9,0.9,true)
        GameTooltip:Show()
    end)
    control:SetScript("OnLeave",function() GameTooltip:Hide() end)
end
function Z.UpdateStatus()
    if not status then return end
    if enableButton then enableButton:SetText(Z.IsEnabled() and L.TURN_OFF or L.TURN_ON) end
    local text
    if not Z.IsEnabled() then text=L.STATUS_OFF
    elseif not Z.FriendsEnabled() then text=Z.NeedPlatesText(true)
    elseif InCombatLockdown() then text=L.STATUS_COMBAT
    elseif #Z.active==0 then text=L.NO_BUFFS
    elseif Z.current then
        local c=Z.current
        text=string.format(c.inspect and L.STATUS_CHECKING or L.STATUS_NEXT,c.name)
    else text=L.STATUS_READY end
    status:SetText(text)
end
function Z.RefreshSettings()
    if not settings then return end
    bindButton:SetText(Z.db.key or L.CHOOSE_KEY)
    for i,p in ipairs(Z.active) do
        local row=rows[i]
        if row then
            row:SetChecked(Z.db.enabled[p.key]~=false)
            local learned=#p.learned>0
            row.caption:SetText(p.label..(learned and "" or "  |cff888888"..L.NOT_LEARNED.."|r"))
            row:SetEnabled(learned)
        end
    end
    thresholdText:SetText(Z.db.refresh==0 and L.REBUFF_EXPIRED
        or string.format(L.REBUFF_AT,Z.db.refresh))
    if slider:GetValue()~=Z.db.refresh then slider:SetValue(Z.db.refresh) end
    for _,editor in pairs(Z.priorityEditors) do editor.render() end
    if Z.minimapCheck then Z.minimapCheck:SetChecked(not (type(Z.db.minimap)=="table" and Z.db.minimap.hide)) end
    if Z.giversCheck then Z.giversCheck:SetChecked(Z.db.trackGivers~=false) end
    Z.UpdateStatus()
end
function Z.CancelCapture()
    pendingKey=nil
    if capture then capture:Hide() capture:EnableKeyboard(false) end
    if catcher then catcher:Hide() end
end
local MOUSE_KEYS={LeftButton="BUTTON1",RightButton="BUTTON2",MiddleButton="BUTTON3",
    Button4="BUTTON4",Button5="BUTTON5"}
local function modifiers(key)
    local prefix=""
    if IsControlKeyDown() then prefix=prefix.."CTRL-" end
    if IsAltKeyDown() then prefix=prefix.."ALT-" end
    if IsShiftKeyDown() then prefix=prefix.."SHIFT-" end
    return prefix..key
end
local function chooseKey(key)
    if key=="ESCAPE" then Z.CancelCapture() return end
    if key=="LSHIFT" or key=="RSHIFT" or key=="LCTRL" or key=="RCTRL" or key=="LALT" or key=="RALT" then return end
    if key=="BACKSPACE" or key=="DELETE" then
        Z.SetKey(nil) Z.CancelCapture() Z.RefreshSettings() return
    end
    key=modifiers(key)
    if key=="BUTTON1" or key=="BUTTON2" then
        capture.info:SetText(L.KEY_MOUSE_TAKEN) return
    end
    local bound=GetBindingAction and GetBindingAction(key,true) or ""
    if bound and bound~="" and bound~="CLICK ZEUSBuffButton:LeftButton" then
        pendingKey=key
        local display=GetBindingText and GetBindingText(bound,"BINDING_NAME_") or bound
        capture.info:SetText(string.format(L.KEY_IN_USE,key,display))
        capture.confirm:Show()
        return
    end
    if Z.SetKey(key) then Z.CancelCapture() Z.RefreshSettings() end
end
local function captureKey()
    if InCombatLockdown() then Z.Print(L.NO_COMBAT_KEY) return end
    pendingKey=nil
    capture.confirm:Hide()
    capture.info:SetText(L.KEY_PROMPT)
    catcher:Show()
    capture:Show()
    capture:EnableKeyboard(true)
    if capture.SetPropagateKeyboardInput then capture:SetPropagateKeyboardInput(false) end
end
function Z.ToggleSettings() -- gp:settings
    if settings:IsShown() then Z.CancelCapture() settings:Hide()
    elseif not Z.Allowed("settings") then Z.Print(Z.GAMEPAD_PAUSED)
    else settings:Show() Z.RefreshSettings() end
end
-- The Escape list (UISpecialFrames): ZEUS's name is added only where the gamepad gate allows,
-- and taken off at a switch when it is still last (an earlier entry stays until a /reload).
local ESCAPE="ZEUSSettings"
local function escapeOn()
    if not Z.Allowed("escape-list") then return end
    for _,name in ipairs(UISpecialFrames) do if name==ESCAPE then return end end -- gp:escape-list
    tinsert(UISpecialFrames,ESCAPE) -- gp:escape-list
end
local function escapeOff() -- gp:escape-list!undo
    local list=UISpecialFrames
    local listed=false
    for _,name in ipairs(list) do if name==ESCAPE then listed=true end end
    if not listed then return end
    if list[#list]==ESCAPE then table.remove(list) else Z.GamepadLeftover("escape-list") end
end
Z.GamepadHooks("escape-list",{park=escapeOff,install=escapeOn})
Z.GamepadHooks("settings",{park=function() -- gp:settings!undo
    Z.CancelCapture()
    if settings and settings:IsShown() then settings:Hide() end
end})
function Z.UpdateMinimap()
    if minimap then
        minimap.icon:SetDesaturated(not Z.IsEnabled())
        if minimap.hovered then minimap:GetScript("OnEnter")(minimap) end
    end
end
-- Shows or hides the minimap button. Z.db.minimap.hide is LibDBIcon's own saved flag, so the
-- choice holds across logins and minimap-collector addons see it.
function Z.SetMinimapShown(shown)
    if type(Z.db.minimap)~="table" then Z.db.minimap={} end
    Z.db.minimap.hide=not shown or nil
    local icons=LibStub("LibDBIcon-1.0",true)
    if icons and icons:IsRegistered("ZEUS") then
        if shown then icons:Show("ZEUS") else icons:Hide("ZEUS") end -- gp:minimap
    end
    if not shown and minimap and minimap.hovered then minimap.hovered=nil GameTooltip:Hide() end -- gp:tooltips
    if Z.minimapCheck then Z.minimapCheck:SetChecked(shown and true or false) end
end
local function createMinimap() -- gp:minimap
    local ldb=LibStub("LibDataBroker-1.1")
    local icons=LibStub("LibDBIcon-1.0")
    local broker=ldb:GetDataObjectByName("ZEUS") or ldb:NewDataObject("ZEUS",{
        type="launcher",text="ZEUS",icon=136048,
    })
    broker.OnClick=function(self,mouse)
        if self.zeusDragged then self.zeusDragged=nil return end
        if mouse=="LeftButton" then Z.ToggleSettings()
        elseif mouse=="RightButton" then Z.ToggleZEUS() end
    end
    broker.OnEnter=function(self) -- gp:tooltips
        self.hovered=true
        GameTooltip:ClearLines()
        GameTooltip:SetOwner(self,"ANCHOR_LEFT")
        GameTooltip:AddLine("ZEUS",1,0.82,0.4)
        GameTooltip:AddLine(Z.IsEnabled() and L.MINIMAP_ON or L.MINIMAP_OFF,1,1,1)
        GameTooltip:AddLine(Z.FriendsEnabled() and L.MINIMAP_PLATES_SHOWN or L.MINIMAP_PLATES_HIDDEN,0.8,0.8,0.8)
        if not Z.BindingWanted() then
            GameTooltip:AddLine(Z.bindingPending and L.MINIMAP_KEY_AFTER_COMBAT or L.MINIMAP_KEY_RELEASED,0.8,0.8,0.8)
        end
        GameTooltip:AddLine(L.MINIMAP_LEFT,0.8,0.8,0.8)
        GameTooltip:AddLine(Z.IsEnabled() and L.MINIMAP_RIGHT_OFF or L.MINIMAP_RIGHT_ON,0.8,0.8,0.8)
        GameTooltip:AddLine(L.MINIMAP_DRAG,0.8,0.8,0.8)
        GameTooltip:AddLine(string.format(L.MINIMAP_KEY,Z.db.key or L.KEY_NOT_SET),1,0.82,0.4)
        if InCombatLockdown() then GameTooltip:AddLine(L.STATUS_COMBAT,0.7,0.85,1) end
        if Z.GamepadUI() then GameTooltip:AddLine(L.PAUSED_GAMEPAD,0.7,0.85,1) end
        GameTooltip:Show()
    end
    broker.OnLeave=function() minimap.hovered=nil GameTooltip:Hide() end -- gp:tooltips
    if type(Z.db.minimap)~="table" then
        Z.db.minimap={minimapPos=Z.db.minimapAngle or 220}
    end
    if not icons:IsRegistered("ZEUS") then
        icons:Register("ZEUS",broker,Z.db.minimap)
    else
        icons:Refresh("ZEUS",Z.db.minimap)
    end
    minimap=icons:GetMinimapButton("ZEUS")
    Z.minimapButton=minimap
    -- Compatibility reference; the actual frame is LibDBIcon10_ZEUS.
    ZEUSMinimapButton=minimap
    if not minimap.zeusHooked then
        minimap:HookScript("OnMouseDown",function(self) self.zeusDragged=nil end)
        minimap:HookScript("OnDragStart",function(self) self.zeusDragged=true end)
        minimap.zeusHooked=true
    end
    Z.UpdateMinimap()
end
function Z.CreateUI()
    settings=panel("ZEUSSettings",760,500,nil,true)
    Z.priorityEditors={}
    settings:SetPoint("CENTER")
    settings:SetFrameStrata("DIALOG")
    settings:SetClampedToScreen(true)
    settings:SetMovable(true)
    settings:RegisterForDrag("LeftButton")
    settings:SetScript("OnDragStart",function(self) self:StartMoving() end)
    settings:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing()
        local point,_,relative,x,y=self:GetPoint()
        Z.db.position={point,relative,x,y}
    end)
    if type(Z.db.position)=="table" and #Z.db.position==4 then
        local p=Z.db.position
        settings:ClearAllPoints() settings:SetPoint(p[1],UIParent,p[2],p[3],p[4])
    end
    escapeOn()
    settings:SetScript("OnHide",Z.CancelCapture)
    title(settings,"ZEUS")
    local portrait=settings.portrait or settings.Portrait
        or (settings.PortraitContainer and settings.PortraitContainer.portrait)
    if not portrait then
        portrait=settings:CreateTexture(nil,"ARTWORK")
        portrait:SetPoint("TOPLEFT",0,0) portrait:SetSize(60,60)
    end
    portrait:SetTexture(Z.portraitPath)
    portrait:SetTexCoord(0,1,0,1)
    if portrait.SetMask then
        pcall(portrait.SetMask,portrait,"Interface/CharacterFrame/TempPortraitAlphaMask")
    end
    settings.portrait=portrait
    label(settings,L.SLOGAN,72,-32,660,"GameFontNormalLarge")
    local tagline=Z.tagline
    if type(tagline)=="table" then tagline=tagline[Z.language.code] or tagline.enUS end
    label(settings,tagline,72,-54,660)
    section(settings,14,-73,732,87)
    label(settings,L.BUFF_KEY,25,-79,400,"GameFontNormal"):SetTextColor(unpack(gold))
    bindButton=action(settings,L.CHOOSE_KEY,25,-98,230,captureKey)
    Z.bindButton=bindButton
    local resetKey=action(settings,L.RESET,263,-98,118,function()
        if Z.SetKey(nil) then Z.CancelCapture() Z.RefreshSettings() end
    end)
    Z.resetKeyButton=resetKey
    tooltip(resetKey,L.RESET_TIP)
    label(settings,L.WHEEL_TIP,25,-135,710)
    local macro=CreateFrame("Button","ZEUSToggleMacroButton",settings,"SecureHandlerDragTemplate,SecureHandlerStateTemplate")
    macro:SetPoint("TOPLEFT",580,-92) macro:SetSize(36,36)
    macro:SetNormalTexture("Interface/Icons/Spell_Nature_Lightning")
    macro:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
    macro:EnableMouse(true)
    macro:RegisterForClicks("LeftButtonUp") macro:RegisterForDrag("LeftButton")
    label(settings,L.TOGGLE_MACRO,624,-93,108,"GameFontNormal")
    label(settings,L.DRAG_TO_BAR,624,-111,108)
    tooltip(macro,L.TOGGLE_MACRO_TIP)
    Z.ConfigureToggleMacroButton(macro)
    local buffMacro=CreateFrame("Button","ZEUSBuffMacroButton",settings,"SecureHandlerDragTemplate,SecureHandlerStateTemplate")
    buffMacro:SetPoint("TOPLEFT",390,-92) buffMacro:SetSize(36,36)
    buffMacro:SetNormalTexture(136015) -- Chain Lightning
    buffMacro:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
    buffMacro:EnableMouse(true)
    buffMacro:RegisterForClicks("LeftButtonUp") buffMacro:RegisterForDrag("LeftButton")
    label(settings,L.BUFF_MACRO,434,-93,108,"GameFontNormal")
    label(settings,L.DRAG_TO_BAR,434,-111,108)
    tooltip(buffMacro,L.BUFF_MACRO_TIP)
    Z.ConfigureToggleMacroButton(buffMacro,"buff")
    local y=-175
    section(settings,14,-167,732,44)
    label(settings,Z.class=="PALADIN" and L.BLESSINGS or L.BUFFS,25,y,400,"GameFontNormal")
    label(settings,L.ROW_HELP,25,y-22,710)
    y=y-48
    section(settings,14,y+7,732,(#Z.active==0 and 30 or #Z.active*77))
    if #Z.active==0 then
        label(settings,L.NO_BUFFS,25,y,410)
        y=y-30
    else
        for i,p in ipairs(Z.active) do
            local entry=p
            rowShade(settings,18,y+5,724,71,(i%2==1) and 0.10 or 0.045)
            local row=check(settings,p.label,22,y,function(value)
                Z.db.enabled[entry.key]=value Z.Refresh()
            end)
            rows[i]=row
            if entry.reagent then tooltip(row,L.REAGENT_TIP) end
            Z.priorityEditors[p.key]=Z.CreatePriorityRow(settings,p,y)
            y=y-77
        end
    end
    if Z.class=="PALADIN" then
        label(settings,L.ONE_BLESSING,25,y,710)
        y=y-25
    end
    y=y-12
    section(settings,14,y+10,732,73)
    thresholdText=label(settings,"",25,y,710,"GameFontNormal")
    -- The current labelled slider; OptionsSliderTemplate is now only a deprecated alias of it.
    slider=CreateFrame("Slider","ZEUSRefreshSlider",settings,"UISliderTemplateWithLabels")
    slider:SetPoint("TOPLEFT",27,y-30)
    slider:SetSize(704,16)
    slider:SetMinMaxValues(0,99)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    local low,high,caption=slider.Low or _G.ZEUSRefreshSliderLow,slider.High or _G.ZEUSRefreshSliderHigh,
        slider.Text or _G.ZEUSRefreshSliderText
    low:SetText("0%")
    high:SetText("99%")
    caption:SetText("")
    slider:SetValue(Z.db.refresh)
    slider:SetScript("OnValueChanged",function(_,value)
        local nextValue=math.max(0,math.min(99,math.floor(value+0.5)))
        if nextValue==Z.db.refresh then return end
        Z.db.refresh=nextValue Z.RefreshSettings() Z.Refresh()
    end)
    tooltip(slider,L.SLIDER_TIP)
    y=y-84
    local function updateWarning(value)
        warning:SetText(value and "" or L.PVP_WARNING)
    end
    section(settings,14,y+5,732,59)
    local safety=check(settings,L.PVP_PROTECTION,22,y,function(value)
        Z.db.pvp=value
        updateWarning(value)
        Z.Refresh()
    end)
    safety:SetChecked(Z.db.pvp)
    tooltip(safety,L.PVP_TIP)
    warning=label(settings,"",25,y-31,355)
    warning:SetTextColor(1,0.65,0.35)
    updateWarning(Z.db.pvp)
    local minimapCheck=check(settings,L.MINIMAP_BUTTON,388,y,function(value) Z.SetMinimapShown(value) end)
    minimapCheck.caption:SetWidth(320)
    minimapCheck:SetChecked(not (type(Z.db.minimap)=="table" and Z.db.minimap.hide))
    tooltip(minimapCheck,L.MINIMAP_BUTTON_TIP)
    Z.minimapCheck=minimapCheck
    local giversCheck=check(settings,L.TRACK_GIVERS,388,y-28,function(value) Z.SetTrackGivers(value) end)
    giversCheck.caption:SetWidth(320)
    giversCheck:SetChecked(Z.db.trackGivers~=false)
    tooltip(giversCheck,L.TRACK_GIVERS_TIP)
    Z.giversCheck=giversCheck
    local height=-y+144
    settings:SetHeight(height)
    section(settings,14,-height+80,732,36)
    status=label(settings,"",25,-height+68,710)
    status:SetTextColor(1,0.82,0)
    enableButton=action(settings,L.TURN_ON,16,-height+36,360,function() Z.ToggleZEUS() end)
    Z.enableButton=enableButton
    tooltip(enableButton,L.TOGGLE_TIP)
    local report=action(settings,L.REPORT_BUTTON,384,-height+36,360,Z.PrintBuffReport)
    tooltip(report,L.REPORT_TIP)
    -- While choosing a key, a dimmed full-screen layer under the dialog accepts
    -- mouse buttons and the wheel anywhere, so mouse binds need no aiming.
    catcher=CreateFrame("Frame","ZEUSKeyCaptureCatcher",UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:EnableMouse(true)
    catcher:EnableMouseWheel(true)
    local shade=catcher:CreateTexture(nil,"BACKGROUND")
    shade:SetAllPoints(catcher)
    shade:SetColorTexture(0,0,0,0.35)
    catcher:Hide()
    capture=panel("ZEUSKeyCapture",460,180,settings)
    -- Open over the button that was clicked.
    capture:SetPoint("TOPLEFT",bindButton,"TOPLEFT",-12,12)
    capture:SetClampedToScreen(true)
    capture:SetFrameStrata("FULLSCREEN_DIALOG")
    capture:SetFrameLevel(settings:GetFrameLevel()+30)
    catcher:SetFrameLevel(math.max(1,capture:GetFrameLevel()-10))
    title(capture,L.CHOOSE_TITLE)
    capture.info=label(capture,"",20,-40,420)
    capture.confirm=action(capture,L.USE_KEY,20,-131,160,function()
        if pendingKey and Z.SetKey(pendingKey) then Z.CancelCapture() Z.RefreshSettings() end
    end)
    action(capture,L.CANCEL,280,-131,160,Z.CancelCapture)
    -- The title bar close button hides only the dialog; take the layer with it.
    local layer=catcher
    capture:SetScript("OnHide",function() pendingKey=nil layer:Hide() end)
    capture:SetScript("OnKeyDown",function(_,key) if key=="ESCAPE" then Z.CancelCapture() elseif not pendingKey then chooseKey(key) end end)
    local function onMouseDown(_,mouse)
        if pendingKey then return end
        chooseKey(MOUSE_KEYS[mouse] or mouse:upper())
    end
    local function onMouseWheel(_,delta)
        if not pendingKey then chooseKey(delta>0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end
    end
    for _,frame in ipairs({capture,catcher}) do
        frame:SetScript("OnMouseDown",onMouseDown)
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel",onMouseWheel)
    end
    capture:Hide()
    settings:Hide()
    createMinimap()
    Z.RefreshSettings()
end
