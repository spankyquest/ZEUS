local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
local names={WARRIOR="Warrior",PALADIN="Paladin",HUNTER="Hunter",ROGUE="Rogue",
    PRIEST="Priest",SHAMAN="Shaman",MAGE="Mage",WARLOCK="Warlock",DRUID="Druid"}
local tileWidth,gap=74,4
local function button(parent,text,x,y,width)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT",x,y) b:SetSize(width,24) b:SetText(text)
    return b
end
function Z.CreatePriorityRow(parent,p,y)
    local editor={unlocked=false,tiles={},profile=p}
    local strip=CreateFrame("Frame",nil,parent)
    strip:SetPoint("TOPLEFT",25,y-32)
    strip:SetSize(9*(tileWidth+gap)-gap,28)
    editor.strip=strip
    editor.lock=button(parent,"Unlock",657,y,74)
    editor.reset=button(parent,"Reset",580,y,70)
    local function render()
        local custom=Z.PriorityLayout(Z.db,p)
        editor.lock:SetText(editor.unlocked and "Lock" or "Unlock")
        editor.reset:SetShown(editor.unlocked)
        for i,class in ipairs(custom.order) do
            local tile=editor.tiles[class]
            tile:ClearAllPoints() tile:SetPoint("TOPLEFT",strip,"TOPLEFT",(i-1)*(tileWidth+gap),0)
            local enabled=custom.enabled[class]
            local color=(RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]) or {r=0.75,g=0.72,b=0.55}
            tile:SetBackdropColor(enabled and color.r*0.20 or 0.038,
                enabled and color.g*0.20 or 0.034,enabled and color.b*0.20 or 0.028,1)
            tile:SetBackdropBorderColor(enabled and color.r or 0.25,enabled and color.g or 0.25,
                enabled and color.b or 0.25,editor.unlocked and 1 or 0.5)
            tile.text:SetText(names[class])
            tile.text:SetTextColor(enabled and 1 or 0.45,enabled and 1 or 0.45,enabled and 1 or 0.45)
            tile.index=i
        end
    end
    local function changed()
        render() Z.Refresh()
    end
    for _,class in ipairs(Z.targetClasses) do
        local token=class
        local tile=CreateFrame("Button",nil,strip,"BackdropTemplate")
        tile:SetSize(tileWidth,28) tile:SetMovable(true) tile:SetClampedToScreen(true)
        tile:SetBackdrop({bgFile="Interface/Buttons/WHITE8X8",edgeFile="Interface/Tooltips/UI-Tooltip-Border",
            edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
        tile.text=tile:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        tile.text:SetPoint("CENTER") tile.text:SetWidth(tileWidth-6)
        tile:RegisterForClicks("RightButtonUp") tile:RegisterForDrag("LeftButton")
        tile:SetScript("OnClick",function()
            if editor.unlocked then Z.ToggleClass(Z.db,p,token) changed() end
        end)
        tile:SetScript("OnDragStart",function(self)
            if not editor.unlocked then return end
            self.dragging=true self:SetFrameLevel(strip:GetFrameLevel()+10) self:StartMoving()
            GameTooltip:Hide()
        end)
        tile:SetScript("OnDragStop",function(self)
            if not self.dragging then return end
            self.dragging=nil self:StopMovingOrSizing()
            local cursor=GetCursorPosition()
            local index=math.floor((cursor/strip:GetEffectiveScale()-strip:GetLeft())/(tileWidth+gap))+1
            Z.MoveClass(Z.db,p,token,index)
            self:SetFrameLevel(strip:GetFrameLevel()+1)
            changed()
        end)
        tile:SetScript("OnEnter",function(self)
            local enabled=Z.PriorityLayout(Z.db,p).enabled[token]
            GameTooltip:SetOwner(self,"ANCHOR_TOP")
            GameTooltip:AddLine(names[token]..(enabled and " — enabled" or " — disabled"),1,0.82,0.4)
            GameTooltip:AddLine(editor.unlocked and "Drag to reorder. Right-click to toggle." or "Unlock this spell to edit targets.",0.9,0.9,0.9)
            GameTooltip:Show()
        end)
        tile:SetScript("OnLeave",function() GameTooltip:Hide() end)
        editor.tiles[token]=tile
    end
    editor.lock:SetScript("OnClick",function() editor.unlocked=not editor.unlocked render() end)
    editor.reset:SetScript("OnClick",function()
        if editor.unlocked then Z.ResetPriority(Z.db,p) changed() end
    end)
    editor.render=render
    render()
    return editor
end
