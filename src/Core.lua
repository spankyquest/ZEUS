local addonName, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
local L = Z.L
-- Shared runtime state and lifecycle: refresh scheduling, cast outcomes,
-- saved settings, events, and the slash command. Auras.lua, Blockers.lua, Queue.lua
-- and Buttons.lua (loaded next) add the subsystems.
Z.frame = CreateFrame("Frame")
Z.plates, Z.seen, Z.skips, Z.queue, Z.active = {}, {}, {}, {}, {}
Z.diag = {down=0, up=0, attempts=0, successes=0, last="Ready"}
-- The in-flight cast, shared by the queue, the click receivers, and events:
--   pending      cast prepared by the last click, awaiting success or failure
--   acquisition  nameplate player being targeted so their auras can be read
--   retry        mana/cooldown failure that keeps the same recipient and buff
--   batch        one recipient's remaining buffs, finished before moving on
--   passSkipped  recipients whose visit ended, set aside until the current pass ends
--   los          players a cast could not reach for line of sight (Queue.lua)
local S = {passSkipped={}, los={}}
Z.state = S
local started, elapsed, cleanupElapsed = false, 0, 0
-- A temporary run (the Buff macro pressed while ZEUS is off) ends this many seconds after the
-- last press, whatever is left to buff: around other players there nearly always is, so
-- waiting for an empty queue could leave ZEUS and nameplates on indefinitely. Spamming keeps
-- the run going, so nameplates aren't switched off and on with every press.
local ONE_SHOT_IDLE = 3
-- Set by frequent client events; the next frame performs one rebuild.
local dirty = false
local function safe(v) return Z.Safe(v) end
local function now() return time() end
function Z.Print(s) DEFAULT_CHAT_FRAME:AddMessage("|cffffd166ZEUS:|r " .. tostring(s)) end -- gp:chat-output

function Z.SyncNameplateState()
    if not started then return end
    local enabled=Z.IsOperational()
    if Z.enabled~=enabled or Z.bindingEnabled~=Z.BindingWanted() or Z.bindingPending then
        Z.enabled=enabled
        Z.ApplyBinding()
    end
    if not enabled then
        S.acquisition,S.retry,S.batch=nil,nil,nil
        S.passSkipped={}
        Z.queue={}
        if not InCombatLockdown() then Z.Arm(nil) else Z.current=nil end
    end
    if Z.UpdateStatus then Z.UpdateStatus() end
end
local nextInputScan,inputTarget=0,nil
function Z.Refresh(fromInput)
    if not started then return end
    local wasDirty=dirty
    dirty=false
    Z.SyncNameplateState()
    if InCombatLockdown() then return end
    -- End a temporary run once the macro has rested, or at once if its nameplates were hidden.
    if Z.oneShot and Z.IsEnabled() and not Z.GamepadUI() and (not Z.FriendsEnabled()
        or GetTime()-(Z.lastBuffPress or -math.huge)>=ONE_SHOT_IDLE) then
        Z.SetZEUSEnabled(false,false)
        return
    end
    if not Z.enabled then return end
    local targetGUID=UnitGUID("target")
    -- Input reuses a scan under 100 ms old unless something changed since.
    if fromInput and not wasDirty and not S.pending and not S.acquisition and safe(targetGUID)
        and targetGUID==inputTarget and GetTime()<nextInputScan then return end
    if S.pending and GetTime()-S.pending.at > 2 then Z.FinishBatchAttempt(S.pending) S.pending=nil end
    local acquisition=S.acquisition
    if acquisition then
        local guid=UnitGUID("target")
        if safe(guid) and guid==acquisition.guid then
            Z.autoTarget=guid
            local c=Z.Candidate("target",acquisition.profile,2,S.retry and S.retry.guid==guid)
            S.acquisition=nil
            if c and not c.inspect then Z.Arm(c) if Z.UpdateStatus then Z.UpdateStatus() end return end
            -- The target resolved but cannot be safely buffed. Do not reacquire
            -- the same nameplate repeatedly while its data stays unavailable, and
            -- remember a buff or blocker they carry for when they are a nameplate again.
            Z.NoteVerified("target",guid,acquisition.profile)
            Z.skips[guid]=GetTime()+2
        elseif GetTime()-acquisition.at < 0.45 then
            Z.Arm(nil) return
        else
            Z.skips[acquisition.guid]=GetTime()+10
            Z.diag.last="Could not verify the selected player"
            S.acquisition=nil
        end
    end
    if S.pending then Z.Arm(nil) else
        -- Rebuild from live units even after the previous queue is empty.
        -- Temporary skips expire normally; never reset successful-buff memory.
        Z.queue=Z.BuildQueue()
        nextInputScan=GetTime()+0.1
        inputTarget=targetGUID
        Z.Arm(Z.queue[1])
    end
    if Z.UpdateStatus then Z.UpdateStatus() end
end

-- Returns true when the success belongs to the cast ZEUS prepared.
local function success(unit, castGUID, id)
    local a=S.pending
    if not safe(unit) or unit~="player" or not safe(id) or not a
        or a.spellID~=id or GetTime()-a.at>2 then return end
    if a.castGUID and safe(castGUID) and castGUID~=a.castGUID then return end
    Z.RecordReportedSuccess(a,castGUID)
    Z.NoteBuffSuccess(a)
    Z.FinishBatchAttempt(a)
    Z.ClearOutOfSight(a.guid)
    S.pending,S.retry=nil,nil
    -- Profile duration is only a fallback; the observed aura wins below.
    Z.Remember(Z.db,a.guid,a.profile.key,now(),Z.ProfileDuration(a.profile))
    Z.diag.successes=Z.diag.successes+1
    Z.diag.last="Applied "..a.profile.label.." to "..a.name
    local function reconcile()
        if InCombatLockdown() or UnitGUID(a.unit)~=a.guid then return end
        local aura=Z.Aura(a.unit,a.profile)
        if aura.found and aura.duration and aura.remaining and aura.remaining>0 then
            Z.Remember(Z.db,a.guid,a.profile.key,now(),aura.duration,now()+aura.remaining)
        end
    end
    C_Timer.After(0.15,reconcile)
    C_Timer.After(0,Z.Refresh)
    return true
end
local function failure(message)
    local pending=S.pending
    local inBatch=S.batch and S.batch.guid==pending.guid
    local retryFailure=Z.RetryFailure(message)
    local bounce=message and ((SPELL_FAILED_AURA_BOUNCED and message==SPELL_FAILED_AURA_BOUNCED)
        or message:gsub("%.$","")=="A more powerful spell is already active")
    if Z.LineOfSightFailure(message) then
        Z.skips[pending.guid]=nil -- Remove the provisional cast-failed delay.
        Z.NoteOutOfSight(pending.guid)
        S.retry=nil
        -- Every remaining buff of a visit needs sight of the same player: end the visit.
        if inBatch then S.batch=nil end
    elseif retryFailure and not inBatch then
        Z.skips[pending.guid]=nil
        S.retry={guid=pending.guid,profile=pending.profile,intent=pending.intent}
    elseif bounce then
        S.retry=nil
        -- Find the stronger buff and hold the player while it lasts (Blockers.lua).
        Z.NoteBounce(pending)
        if not inBatch then Z.skips[pending.guid]=GetTime()+3 end
    elseif not inBatch then S.retry=nil Z.skips[pending.guid]=GetTime()+10 end
    if inBatch then
        Z.skips[pending.guid]=nil
        S.retry=nil
        Z.FinishBatchAttempt(pending)
    end
    Z.diag.last=message or "Cast unavailable"
    S.pending=nil
end
local function cleanup()
    local t=now()
    for guid, entries in pairs(Z.db.memory) do
        for key,r in pairs(entries) do
            if type(r)~="table" or (tonumber(r.expires) or 0)<=t then entries[key]=nil end
        end
        if not next(entries) then Z.db.memory[guid]=nil end
    end
    for guid,expires in pairs(Z.skips) do if expires<=GetTime() then Z.skips[guid]=nil end end
    Z.ForgetOldSightFailures()
end
-- /zeus: registered only where the gamepad gate allows (never at a gamepad login). Once
-- registered it stays until a /reload, so it does nothing while the gamepad UI is on.
local slashInstalled=false
local function slash(msg)
    if not started then return end
    if Z.GamepadUI() then Z.Print(Z.GAMEPAD_PAUSED) return end
    msg=(msg or ""):lower():match("^%s*(.-)%s*$")
    if msg=="toggle" then Z.ToggleZEUS() return end
    if msg=="report" then Z.PrintBuffReport() return end
    if msg=="blockers" then Z.PrintBlockers() return end
    if msg=="blockers clear" then Z.ClearBlockers() return end
    if msg=="debug" or msg=="status" then
        Z.Print(string.format("v%s | %s | %s | key %s | edges down/up %d/%d | attempts %d | successes %d",
            Z.version,Z.class,Z.db.dualEdge and "both edges" or "release only",Z.db.key or "unbound",
            Z.diag.down,Z.diag.up,Z.diag.attempts,Z.diag.successes))
        Z.Print(Z.diag.last)
        local language=Z.language
        Z.Print(string.format("language: %s, %d lines translated, %s left out",language.code,language.taken,
            #language.skipped>0 and table.concat(language.skipped,", ") or "none"))
    elseif msg=="input release" or msg=="input both" then
        if InCombatLockdown() then Z.Print(L.NO_COMBAT_INPUT) return end
        Z.db.dualEdge=msg=="input both"
        Z.Print(Z.db.dualEdge and L.INPUT_BOTH or L.INPUT_RELEASE)
    else Z.ToggleSettings() end
end
local function installSlash()
    if slashInstalled or not Z.Allowed("slash") then return end
    slashInstalled=true
    SLASH_ZEUS1="/zeus" -- gp:slash
    SlashCmdList.ZEUS=slash -- gp:slash
end
Z.GamepadHooks("slash",{
    park=function() if slashInstalled then Z.GamepadLeftover("slash") end end,
    install=installSlash,
})
local function copy(value)
    if type(value)~="table" then return value end
    local out={} for k,v in pairs(value) do out[k]=copy(v) end return out
end
local function initialize()
    local saved=Z.savedVariables
    if type(_G[saved])~="table" then
        -- Seed a new edition-specific save from loaded legacy settings, without
        -- sharing tables or overwriting an existing save.
        local legacy=Z.legacySavedVariables and _G[Z.legacySavedVariables]
        _G[saved]=type(legacy)=="table" and copy(legacy) or {}
    end
    Z.db=_G[saved]
    Z.InitializeReporting()
    Z.db.enabled=type(Z.db.enabled)=="table" and Z.db.enabled or {}
    Z.db.memory=type(Z.db.memory)=="table" and Z.db.memory or {}
    Z.NormalizeBlockers(Z.db)
    Z.NormalizePriorities(Z.db)
    if type(Z.db.zeusEnabled)~="boolean" then Z.db.zeusEnabled=false end
    -- A temporary run interrupted by a /reload carries on, so it still ends by itself (at once).
    Z.oneShot=Z.db.oneShotRun==true and Z.db.zeusEnabled or nil
    Z.db.refresh=math.max(0,math.min(99,math.floor((tonumber(Z.db.refresh) or 20)+0.5)))
    if Z.db.pvp==nil then Z.db.pvp=true end
    if Z.db.dualEdge==nil then Z.db.dualEdge=true end
    for _,p in ipairs(Z.profiles) do
        if Z.db.enabled[p.key]==nil then Z.db.enabled[p.key]=not p.defaultOff end
    end
    Z.class=select(2,UnitClass("player"))
    Z.RefreshSpells()
    local durations={}
    for _,p in ipairs(Z.profiles) do durations[p.key]=Z.ProfileDuration(p) end
    Z.MigrateMemory(Z.db,durations)
    Z.CreateButtons()
    installSlash()
    started=true
    Z.CreateUI()
    Z.ApplyBinding()
    Z.Refresh()
    -- A one-time pointer for a new character; ZEUS stays quiet after that.
    if not Z.db.key and not Z.db.hinted and not Z.GamepadUI() then
        Z.db.hinted=true
        Z.Print(L.HINT)
    end
end

-- Frequent world events only mark the queue stale; OnUpdate rebuilds once.
local DEFERRED={UNIT_AURA=true,NAME_PLATE_UNIT_ADDED=true,NAME_PLATE_UNIT_REMOVED=true,
    UPDATE_MOUSEOVER_UNIT=true,GROUP_ROSTER_UPDATE=true,CVAR_UPDATE=true,
    ADDON_ACTION_BLOCKED=true,ADDON_ACTION_FORBIDDEN=true}
for _,e in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","SPELLS_CHANGED",
    "PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED",
    "UNIT_AURA","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","GROUP_ROSTER_UPDATE",
    "UI_ERROR_MESSAGE","ADDON_ACTION_BLOCKED","ADDON_ACTION_FORBIDDEN","CVAR_UPDATE"}) do
    Z.frame:RegisterEvent(e)
end
-- Only the player's own casts matter; other players' casts are frequent in hubs.
for _,e in ipairs({"UNIT_SPELLCAST_SENT","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_FAILED"}) do
    if Z.frame.RegisterUnitEvent then Z.frame:RegisterUnitEvent(e,"player") else Z.frame:RegisterEvent(e) end
end
Z.frame:SetScript("OnEvent",function(_,event,...)
    if Z.runtimeInactive then return end
    if event=="PLAYER_LOGIN" then if not started then initialize() end return end
    if not started then return end
    local a,b,c,d=...
    if event=="PLAYER_REGEN_DISABLED" then
        S.pending,S.acquisition,S.retry,S.batch=nil,nil,nil,nil
        S.passSkipped={}
        if Z.CancelCapture then Z.CancelCapture() end
        if Z.UpdateStatus then Z.UpdateStatus() end
        return
    elseif event=="PLAYER_REGEN_ENABLED" then
        Z.ApplyBinding()
    elseif event=="SPELLS_CHANGED" or event=="PLAYER_ENTERING_WORLD" then
        Z.RefreshSpells()
        if Z.RefreshSettings then Z.RefreshSettings() end
    elseif event=="NAME_PLATE_UNIT_ADDED" then
        if safe(a) and a then Z.plates[a]=true end
    elseif event=="NAME_PLATE_UNIT_REMOVED" then
        if safe(a) and a then Z.plates[a]=nil end
    elseif event=="PLAYER_TARGET_CHANGED" then
        if not S.acquisition then Z.autoTarget=nil end
    elseif event=="UNIT_AURA" then
        Z.ObserveBuffReports(a)
    elseif event=="UNIT_SPELLCAST_SENT" then
        if a~="player" then return end
        -- The first matching send belongs to ZEUS's prepared cast; any other
        -- buff you cast yourself still counts toward buff-hours.
        local pending=S.pending
        if pending and not pending.castGUID and safe(d) and d==pending.spellID then pending.castGUID=c
        else Z.NoteManualCast(b,c,d) end
    elseif event=="UNIT_SPELLCAST_SUCCEEDED" then
        if not success(a,b,c) and a=="player" then Z.ConfirmManualCast(b,c) end
        return
    elseif event=="UNIT_SPELLCAST_FAILED" then
        if a~="player" then return end
        local pending=S.pending
        if pending and safe(c) and c==pending.spellID then
            if not pending.castGUID or not safe(b) or b==pending.castGUID then
                if not (S.batch and S.batch.guid==pending.guid) then
                    Z.skips[pending.guid]=GetTime()+3
                end
                -- Keep correlation for a following UI_ERROR_MESSAGE, which
                -- can remove this provisional skip for a retryable failure.
                pending.failed=true
                Z.diag.last=S.batch and "Cast failed; trying next buff" or "Cast failed; trying another player"
            end
        end
    elseif event=="UI_ERROR_MESSAGE" then
        if S.pending and GetTime()-S.pending.at<=2 and safe(b) then failure(b) end
    elseif event=="ADDON_ACTION_BLOCKED" or event=="ADDON_ACTION_FORBIDDEN" then
        if a==addonName then Z.diag.last=event..": "..(safe(b) and tostring(b) or "restricted") Z.Print(Z.diag.last) end
    elseif event=="CVAR_UPDATE" then
        if Z.UpdateMinimap then Z.UpdateMinimap() end
    end
    if DEFERRED[event] then dirty=true return end
    Z.Refresh()
end)
Z.frame:SetScript("OnUpdate",function(_,dt)
    if Z.runtimeInactive or not started then return end
    elapsed,cleanupElapsed=elapsed+dt,cleanupElapsed+dt
    -- Range has no event, so rescan every 0.2 s; stale events rescan next frame.
    if elapsed>=0.2 then elapsed=0 Z.Refresh()
    elseif dirty then Z.Refresh() end
    if cleanupElapsed>=60 then cleanupElapsed=0 cleanup() end
end)
