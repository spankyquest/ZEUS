local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
local L = Z.L
-- Secure click receivers and the Buff Key override. Attributes are prepared
-- out of combat; the inherited secure OnClick performs the actual cast.
local S = Z.state
local owner = CreateFrame("Frame")
local button, macroButton
-- Whether ZEUS holds key overrides now, so they are given back only when held.
local held = false
-- Identity of what the receivers currently hold. Rewriting identical
-- attributes on every refresh is skipped; nil forces the next Arm to write.
local armedKey

local function identifier(id)
    local name = Z.SpellName(id)
    local sub
    if C_Spell and C_Spell.GetSpellSubtext then sub=C_Spell.GetSpellSubtext(id)
    elseif GetSpellSubtext then sub=GetSpellSubtext(id) end
    if name and Z.Safe(sub) and sub and sub~="" then return name.."("..sub..")" end
    return id -- Numeric IDs preserve downranking when localized rank text is unavailable.
end
local function clear(b) -- gp:cast-buttons!undo
    b:SetAttribute("type",nil)
    b:SetAttribute("spell",nil)
    b:SetAttribute("macrotext",nil)
    b:SetAttribute("unit",nil)
end
function Z.Arm(c)
    if InCombatLockdown() then return end
    if c and not Z.Allowed("cast-buttons") then c = nil end
    Z.current = c
    local spell = c and not c.inspect and identifier(c.spellID)
    -- The recipient is part of the key: the Buff macro names them even when
    -- the unit token and spell are unchanged.
    local key = not c and "none"
        or table.concat({c.inspect and "inspect" or "cast", c.guid, c.name, c.unit, tostring(spell)}, "\n")
    if key == armedKey then
        -- Retry a macro update that combat or a failed edit left behind.
        if Z.buffMacroStale and Z.ScheduleBuffMacroSync then Z.ScheduleBuffMacroSync() end
        return
    end
    armedKey = key
    clear(button) -- gp:cast-buttons!undo
    if c then
        if c.inspect then
            button:SetAttribute("unit","none") -- gp:cast-buttons
            button:SetAttribute("macrotext","/cleartarget\n/targetexact "..c.name) -- gp:cast-buttons
            button:SetAttribute("type","macro") -- gp:cast-buttons
        else
            button:SetAttribute("spell",spell) -- gp:cast-buttons
            button:SetAttribute("unit",c.unit) -- gp:cast-buttons
            button:SetAttribute("type","spell") -- gp:cast-buttons
        end
    end
    if macroButton then
        clear(macroButton) -- gp:cast-buttons!undo
        if c and not c.inspect then
            macroButton:SetAttribute("unit",c.unit) -- gp:cast-buttons
            macroButton:SetAttribute("spell",spell) -- gp:cast-buttons
            macroButton:SetAttribute("type","spell") -- gp:cast-buttons
        end
    end
    if Z.ScheduleBuffMacroSync then Z.ScheduleBuffMacroSync() end
end
-- Cancel this click's action; the next Arm rewrites both receivers.
local function disarm(b)
    b:SetAttribute("type",nil) -- gp:cast-buttons!undo
    armedKey = nil
end

-- Whether the Buff Key should be bound now: ZEUS enabled, and not under the gamepad UI. A
-- temporary run started by the Buff macro leaves the key alone: it keeps its normal job.
function Z.BindingWanted()
    return Z.IsEnabled() and not Z.oneShot and Z.Allowed("buff-key")
end
local function release() -- gp:buff-key!undo
    if held then ClearOverrideBindings(owner) held = false end
end
function Z.ApplyBinding()
    if InCombatLockdown() then Z.bindingPending=true return end
    Z.bindingPending=false
    Z.bindingEnabled=Z.BindingWanted()
    release()
    if Z.db.key and Z.bindingEnabled then
        held=true
        local prefix,direction=Z.db.key:match("^(.-)MOUSEWHEEL(UP)$")
        if not direction then prefix,direction=Z.db.key:match("^(.-)MOUSEWHEEL(DOWN)$") end
        if direction then
            local opposite="MOUSEWHEEL"..(direction=="UP" and "DOWN" or "UP")
            -- Consume the reverse scroll without changing saved camera bindings.
            SetOverrideBindingClick(owner,false,opposite,"ZEUSWheelBlockButton","LeftButton") -- gp:buff-key
            if prefix~="" then
                SetOverrideBindingClick(owner,false,prefix..opposite,"ZEUSWheelBlockButton","LeftButton") -- gp:buff-key
            end
        end
        SetOverrideBindingClick(owner,false,Z.db.key,"ZEUSBuffButton","LeftButton") -- gp:buff-key
    end
end
function Z.SetKey(key)
    if InCombatLockdown() then Z.Print(L.NO_COMBAT_KEY) return false end
    Z.db.key=key
    Z.ApplyBinding()
    return true
end

-- Spam guard: ZEUS acts on one press every INPUT_COOLDOWN seconds, shared by the Buff Key,
-- the wheel and the Buff macro. Buffs share the 1.5-second global cooldown, so faster
-- presses could not cast anything sooner; they would only cost a rescan and, for the macro
-- while ZEUS is off, switching friendly nameplates on again. A key's release belongs to
-- its press: an accepted press is finished on release, an ignored one stays ignored.
Z.INPUT_COOLDOWN = 0.25
local lastPress = -math.huge
local pressState, skipPost = {}, {}
local function throttled(self,down,dualEdge)
    if dualEdge and not down then
        local state=pressState[self]
        pressState[self]=nil
        if state=="open" then return false end
        if state=="ignored" then return true end
        -- A release without a press: some builds deliver one edge only.
    end
    local t=GetTime()
    if t-lastPress<Z.INPUT_COOLDOWN then
        if dualEdge and down then pressState[self]="ignored" end
        return true
    end
    lastPress=t
    Z.lastBuffPress=t
    if dualEdge and down then pressState[self]="open" end
    return false
end

local function preClick(self,mouse,down)
    skipPost[self]=nil -- Each click's PostClick follows its own PreClick.
    -- With the gamepad UI the receivers are empty: a press does nothing at all.
    if InCombatLockdown() or not Z.Allowed("cast-buttons") then pressState[self]=nil return end
    local edge=down and "down" or "up"
    Z.diag[edge]=Z.diag[edge]+1
    -- Out-of-combat attribute preparation: each delivered hardware edge
    -- selects the matching branch of the inherited secure handler.
    -- Some client builds deliver just one edge; release-only is available.
    local dualEdge=self==macroButton or Z.db.dualEdge
    self:SetAttribute("useOnKeyDown",dualEdge and (down and true or false) or false) -- gp:cast-buttons
    if not dualEdge and down then skipPost[self]=true return end -- The release does the work.
    if throttled(self,down,dualEdge) then skipPost[self]=true disarm(self) return end
    if self==macroButton then
        if not Z.BeginBuffMacro() then disarm(self) return end
    elseif not Z.BeginBuffKey(down) then
        Z.Refresh() disarm(self) return
    end
    Z.Refresh(true) -- Recheck GUID, PvP, auras, and range on the input itself.
    local c=Z.current
    if not c then return end
    if self==macroButton and (c.inspect or c.guid~=Z.buffMacroGUID or UnitGUID("target")~=Z.buffMacroGUID) then
        disarm(self)
        return
    end
    local fresh=Z.Candidate(c.unit,c.profile,c.intent,S.retry and S.retry.guid==c.guid)
    if not fresh or fresh.guid~=c.guid then Z.Arm(nil) return end
    Z.Arm(fresh)
    if fresh.inspect then
        S.acquisition={guid=fresh.guid,profile=fresh.profile,at=GetTime()}
        Z.diag.last="Checking "..fresh.name
    else
        local buffExpiresBefore,buffSpellBefore=Z.CaptureBuffTime(fresh.unit,fresh.profile)
        Z.StartBatch(fresh)
        S.pending={guid=fresh.guid,unit=fresh.unit,spellID=fresh.spellID,
            profile=fresh.profile,name=fresh.name,intent=fresh.intent,at=GetTime(),
            buffExpiresBefore=buffExpiresBefore,buffSpellBefore=buffSpellBefore,
            auras=Z.ReadAuras(fresh.unit)} -- What the player carried, should the cast bounce.
        Z.diag.attempts=Z.diag.attempts+1
        Z.diag.last="Buffing "..fresh.name
    end
end
-- Both hardware edges and rapid scroll ticks share one next-frame scan.
local refreshQueued=false
local function queuedRefresh()
    refreshQueued=false
    Z.Refresh(true)
end
local function postClick(self)
    if skipPost[self] then skipPost[self]=nil return end
    if InCombatLockdown() or refreshQueued then return end
    refreshQueued=true
    C_Timer.After(0,queuedRefresh)
end

local function hiddenButton(name)
    local b=CreateFrame("Button",name,UIParent,"SecureActionButtonTemplate")
    b:SetSize(1,1)
    b:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",-10,-10)
    b:RegisterForClicks("AnyDown","AnyUp")
    return b
end
local function castReceiver(name) -- gp:cast-buttons
    local b=hiddenButton(name)
    b:SetAttribute("useOnKeyDown",false)
    b:SetAttribute("pressAndHoldAction",false)
    b:SetAttribute("checkselfcast",false)
    b:SetAttribute("checkfocuscast",false)
    b:SetAttribute("checkmouseovercast",false)
    -- Keep Blizzard's inherited OnClick intact. No Lua calls CastSpell or Click.
    RegisterStateDriver(b,"visibility","[combat] hide; show") -- gp:state-driver
    b:SetScript("PreClick",preClick)
    b:SetScript("PostClick",postClick)
    return b
end
function Z.CreateButtons()
    -- No action attributes: this secure button consumes a hardware scroll only.
    hiddenButton("ZEUSWheelBlockButton")
    button=castReceiver("ZEUSBuffButton")
    Z.button=button
    macroButton=castReceiver("ZEUSMacroBuffButton")
    Z.macroButton=macroButton
    armedKey=nil
end
-- Gamepad switches (Gamepad.lua): the keys go back to the game inside the switch itself, so
-- the gamepad UI binds on clean keys; the receivers are emptied the next frame.
Z.GamepadHooks("buff-key",{now=true,
    park=function()
        if InCombatLockdown() then Z.bindingPending=true return end
        release()
        Z.bindingEnabled=false
    end,
    install=function() if Z.db then Z.ApplyBinding() end end,
})
Z.GamepadHooks("cast-buttons",{
    park=function() Z.OutOfCombat(function() if button and Z.GamepadUI() then Z.Arm(nil) end end) end,
    install=function() if Z.Refresh then Z.Refresh() end end,
})
