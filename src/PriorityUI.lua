local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
local L = Z.L
local english={WARRIOR="Warrior",PALADIN="Paladin",HUNTER="Hunter",ROGUE="Rogue",
    PRIEST="Priest",SHAMAN="Shaman",MAGE="Mage",WARLOCK="Warlock",DRUID="Druid"}
-- Class names in the game's language when it offers them.
local function className(token)
    local localized=LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]
    return type(localized)=="string" and localized or english[token]
end
local tileWidth,gap=74,4
local stripWidth=9*(tileWidth+gap)-gap
-- The rank list: radio buttons in lines of up to four, 20 pixels a line.
local RANK_LINE,RANK_COLUMNS=20,4
local function button(parent,text,x,y,width)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT",x,y) b:SetSize(width,24) b:SetText(text)
    return b
end
-- A buff's row in the settings window under its tick box: the class tiles with Edit (Lock while
-- editing) and Reset, and, while editing a buff with more than one rank with Advanced's "Enable
-- lower rank buffs" ticked, a radio button per rank under the tiles. `relayout` (UI.lua) makes
-- room for the ranks when they show or hide.
function Z.CreatePriorityRow(parent,p,y,relayout)
    local editor={unlocked=false,tiles={},profile=p}
    local strip=CreateFrame("Frame",nil,parent)
    strip:SetSize(stripWidth,28)
    editor.strip=strip
    editor.lock=button(parent,L.UNLOCK,591,y,140)
    editor.reset=button(parent,L.RESET,475,y,110)
    local function learned(r)
        for _,known in ipairs(p.learned or {}) do if known[1]==r[1] then return true end end
        return false
    end
    -- A rank's name: "Rank 3", or for ranks that are spells of their own (Detect Invisibility's),
    -- the spell's name.
    local function rankName(radio)
        if p.tiers then return Z.SpellName(radio.rank[1],p.tiers[radio.rank[1]] or tostring(radio.rank[1])) end
        return string.format(L.RANK,radio.number)
    end
    local function renderRanks()
        if not editor.radios then return end
        local choice=Z.RankChoice(Z.db,p)
        for _,radio in ipairs(editor.radios) do
            local known=learned(radio.rank)
            local name=rankName(radio)
            radio:SetChecked(radio.index==choice)
            radio:SetEnabled(known)
            radio.label:SetText(known and name or name.."  "..string.format(L.RANK_LEVEL,Z.LearnLevel(radio.rank)))
            local shade=known and 1 or 0.5
            radio.label:SetTextColor(shade,shade,shade)
            local circle=radio.GetNormalTexture and radio:GetNormalTexture()
            if circle then circle:SetDesaturated(not known) circle:SetVertexColor(shade,shade,shade) end
        end
    end
    local function render()
        local custom=Z.PriorityLayout(Z.db,p)
        editor.lock:SetText(editor.unlocked and L.LOCK or L.UNLOCK)
        editor.reset:SetShown(editor.unlocked)
        renderRanks()
        for i,class in ipairs(custom.order) do
            local tile=editor.tiles[class]
            tile:ClearAllPoints() tile:SetPoint("TOPLEFT",strip,"TOPLEFT",(i-1)*(tileWidth+gap),0)
            local enabled=custom.enabled[class]
            local color=(RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]) or {r=0.75,g=0.72,b=0.55}
            tile:SetBackdropColor(enabled and color.r*0.20 or 0.038,
                enabled and color.g*0.20 or 0.034,enabled and color.b*0.20 or 0.028,1)
            tile:SetBackdropBorderColor(enabled and color.r or 0.25,enabled and color.g or 0.25,
                enabled and color.b or 0.25,editor.unlocked and 1 or 0.5)
            tile.text:SetText(className(class))
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
        -- The tooltip: the class and whether this buff goes to it, then how to change that.
        local function tip(self) -- gp:tooltips
            local enabled=Z.PriorityLayout(Z.db,p).enabled[token]
            GameTooltip:SetOwner(self,"ANCHOR_TOP")
            GameTooltip:AddLine(string.format(enabled and L.TILE_ON or L.TILE_OFF,className(token)),1,0.82,0.4)
            GameTooltip:AddLine(editor.unlocked and L.TILE_HELP_UNLOCKED or L.TILE_HELP_LOCKED,0.9,0.9,0.9)
            GameTooltip:Show()
        end
        -- A right-click while editing skips the class or takes it back, and the tooltip over it
        -- says so at once.
        tile:SetScript("OnClick",function(self)
            if not editor.unlocked then return end
            Z.ToggleClass(Z.db,p,token) changed()
            if self and GameTooltip:IsOwned(self) then tip(self) end -- gp:tooltips
        end)
        tile:SetScript("OnDragStart",function(self)
            if not editor.unlocked then return end
            self.dragging=true self:SetFrameLevel(strip:GetFrameLevel()+10) self:StartMoving()
            GameTooltip:Hide() -- gp:tooltips
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
        tile:SetScript("OnEnter",tip)
        tile:SetScript("OnLeave",function() GameTooltip:Hide() end) -- gp:tooltips
        editor.tiles[token]=tile
    end
    -- The ranks, weakest first. One not learned yet is greyed out, can't be picked and shows the
    -- level its class trainer teaches it from; the picked one (the strongest learned until you
    -- pick another) is the strongest ZEUS casts.
    if #p.ranks>1 then
        local box=CreateFrame("Frame",nil,parent)
        local count=#p.ranks
        local columns=math.min(count,RANK_COLUMNS)
        local cell=math.floor(stripWidth/columns)
        editor.rankLines=math.ceil(count/columns)
        box:SetSize(stripWidth,editor.rankLines*RANK_LINE)
        editor.radios={}
        local function tip(self) -- gp:tooltips
            local name=rankName(self)
            local full=p.tiers and name or string.format("%s (%s)",p.label,name)
            local text
            if learned(self.rank) then
                text=string.format(L.RANK_TIP,full)
            else
                local learn,level=Z.LearnLevel(self.rank),UnitLevel("player")
                local reached=Z.Safe(level) and type(level)=="number" and level>=learn
                text=string.format(reached and L.NOT_LEARNED_NOW or L.NOT_LEARNED_AT,full,learn)
            end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:AddLine(text,0.9,0.9,0.9,true)
            GameTooltip:Show()
        end
        for n=1,count do
            local radio=CreateFrame("CheckButton",nil,box,"UIRadioButtonTemplate")
            radio:SetSize(16,16)
            radio:SetPoint("TOPLEFT",((n-1)%columns)*cell,-math.floor((n-1)/columns)*RANK_LINE-2)
            radio.index=count-n+1
            radio.number,radio.rank=n,p.ranks[radio.index]
            radio.label=box:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            radio.label:SetPoint("LEFT",radio,"RIGHT",4,0)
            radio.label:SetWidth(cell-26)
            radio.label:SetJustifyH("LEFT")
            if radio.label.SetWordWrap then radio.label:SetWordWrap(false) end
            -- The name is part of the button, and a greyed-out one still shows its tooltip.
            radio:SetHitRectInsets(0,-(cell-22),0,0)
            if radio.SetMotionScriptsWhileDisabled then radio:SetMotionScriptsWhileDisabled(true) end
            radio:SetScript("OnClick",function(self)
                if editor.unlocked and learned(self.rank) then
                    Z.SetRank(Z.db,p,self.rank[1])
                    Z.Refresh()
                end
                renderRanks()
            end)
            radio:SetScript("OnEnter",tip)
            radio:SetScript("OnLeave",function() GameTooltip:Hide() end) -- gp:tooltips
            editor.radios[n]=radio
        end
        box:Hide()
        editor.ranks=box
    end
    -- Whether the ranks show: while editing, with lower rank buffs enabled.
    local function ranksShown()
        return editor.ranks~=nil and editor.unlocked and Z.db.lowerRanks==true
    end
    -- Extra height the row needs: the rank lines while they show.
    function editor.extra()
        return ranksShown() and editor.rankLines*RANK_LINE+4 or 0
    end
    -- Puts the row's parts at its place in the window (the top of its tick box), and shows the
    -- ranks or hides them.
    function editor.place(top)
        editor.lock:ClearAllPoints() editor.lock:SetPoint("TOPLEFT",591,top)
        editor.reset:ClearAllPoints() editor.reset:SetPoint("TOPLEFT",475,top)
        strip:ClearAllPoints() strip:SetPoint("TOPLEFT",25,top-32)
        if editor.ranks then
            editor.ranks:ClearAllPoints() editor.ranks:SetPoint("TOPLEFT",25,top-64)
            editor.ranks:SetShown(ranksShown())
        end
    end
    local function toggle(unlocked)
        editor.unlocked=unlocked
        render()
        if relayout then relayout() end
    end
    editor.lock:SetScript("OnClick",function() toggle(not editor.unlocked) end)
    editor.lock:SetScript("OnEnter",function(self) -- gp:tooltips
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        local text=editor.unlocked and L.LOCK_TIP or L.UNLOCK_TIP
        if editor.ranks and not editor.unlocked and Z.db.lowerRanks==true then text=text.."\n\n"..L.RANKS_TIP end
        GameTooltip:AddLine(text,0.9,0.9,0.9,true)
        GameTooltip:Show()
    end)
    editor.lock:SetScript("OnLeave",function() GameTooltip:Hide() end) -- gp:tooltips
    -- Closing the settings window locks the order again (UI.lua).
    editor.relock=function()
        if editor.unlocked then toggle(false) end
    end
    editor.reset:SetScript("OnClick",function()
        if editor.unlocked then Z.ResetPriority(Z.db,p) changed() end
    end)
    editor.render=render
    editor.place(y)
    render()
    return editor
end
