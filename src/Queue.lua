local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
-- Recipient discovery and ordering. A scan checks each player once (identity,
-- eligibility, PvP, skips), reads their auras at most once, then evaluates each
-- active buff. Batches and retries pin one recipient across scans.
local S = Z.state
local function safe(v) return Z.Safe(v) end
local function now() return time() end
local ordinal = 0

-- Line of sight. No API tells whether a player is in sight before casting, so a failure is
-- the only signal. Each one keeps that player out for a short, growing wait (2, 4, 8, then
-- 15 seconds); after it they sort behind everyone not marked, so the rest of the queue is
-- finished first instead of alternating between players out of sight. A successful cast
-- on them clears the mark, and marks fade two minutes after the last failure.
local LOS_WAIT = {2, 4, 8, 15}
function Z.NoteOutOfSight(guid)
    local r = S.los[guid] or {n=0}
    r.n = r.n + 1
    r.at = GetTime()
    r.untilT = r.at + LOS_WAIT[math.min(r.n, #LOS_WAIT)]
    S.los[guid] = r
end
function Z.ClearOutOfSight(guid) S.los[guid] = nil end
function Z.ForgetOldSightFailures()
    for guid, r in pairs(S.los) do
        if GetTime() - r.at > 120 then S.los[guid] = nil end
    end
end

local function enabled(p)
    return Z.db.enabled[p.key] ~= false and #p.learned > 0
end
-- Per-player checks shared by every buff. Returns guid, class, level or nil.
local function basic(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or not UnitIsFriend("player",unit) then return end
    -- Edition hook: Olympus installs a guild filter; General leaves it unset.
    if Z.RecipientFilter and not Z.RecipientFilter(unit) then return end
    local guid = UnitGUID(unit)
    if not safe(guid) or not guid then return end
    if UnitIsDeadOrGhost(unit) then
        Z.db.memory[guid]=nil
        return
    end
    if UnitIsConnected and not UnitIsConnected(unit) then return end
    if UnitIsVisible and not UnitIsVisible(unit) then return end
    local _, class = UnitClass(unit)
    if not safe(class) or not class  then return end
    if Z.db.pvp and ((UnitIsPVP(unit) and not UnitIsPVP("player"))
        or (UnitIsPVPFreeForAll and UnitIsPVPFreeForAll(unit))) then return end
    if S.passSkipped[guid] then return end
    if Z.skips[guid] and Z.skips[guid] > GetTime() then return end
    local los = S.los[guid]
    if los and los.untilT > GetTime() then return end
    local level = UnitLevel(unit)
    if not safe(level) or type(level) ~= "number" or level < 1 then return end
    return guid, class, level
end
local function blessingFor(class, level)
    local choices={}
    for _,key in ipairs(Z.blessings[class] or {}) do choices[#choices+1]=key end
    for _,p in ipairs(Z.active) do
        if p.blessing then
            local found=false
            for _,key in ipairs(choices) do if key==p.key then found=true end end
            if not found then choices[#choices+1]=p.key end
        end
    end
    for _, key in ipairs(choices) do
        for _, p in ipairs(Z.active) do
            if p.key == key and enabled(p) and Z.ClassPriority(Z.db,p,class) and Z.Rank(p,level) then return key end
        end
    end
end
-- Decide whether one buff is needed on an already-checked player. `ctx` caches
-- that player's aura snapshot across the buffs evaluated in the same scan.
local function evaluate(unit, guid, class, level, p, intent, waitForCaster, ctx)
    local priority = Z.ClassPriority(Z.db,p,class)
    if not enabled(p) or not priority then return end
    if p.blessing and blessingFor(class,level) ~= p.key then return end
    local id = Z.Rank(p,level)
    if not id or not Z.InRange(id,unit) or (not waitForCaster and not Z.Usable(id)) then return end
    local snap = ctx and ctx.auras
    if not snap then
        snap = Z.ReadAuras(unit)
        if ctx then ctx.auras = snap end
    end
    local a = Z.MatchAura(snap,p)
    if a.blocked then return end
    local rank = Z.SpellRankIndex(p,id)
    -- Another caster's stronger rank: a weaker cast would only bounce.
    if rank and a.rankIndex and a.rankIndex < rank then return end
    -- A buff that bounced this one before, on this player or learned for everyone.
    if Z.Held(guid,p,snap) or Z.LearnedBlocker(snap,p,rank) then return end
    local upgrade=Z.CanUpgrade(p,id,a)
    if Z.Suppressed(Z.db,guid,p.key,now()) then
        if not upgrade then return end
        local record=Z.db.memory[guid][p.key]
        -- Allow the just-cast aura to arrive before trusting a stale lower rank.
        if record.cast and now()-record.cast<2 then return end
    end
    -- Changing the selected blessing must not undo a recipient's opt-out. Only a blessing
    -- ZEUS put on them counts: not a bounce, and not another paladin's blessing it saw.
    if p.blessing then
        local records = Z.db.memory[guid]
        for _, other in ipairs(Z.active) do
            local r = records and records[other.key]
            if other.blessing and r and not r.blockedBy and not r.observed and (other.key~=p.key or not upgrade)
                and Z.Suppressed(Z.db,guid,other.key,now()) then return end
        end
    end
    if not upgrade and a.found and a.duration and a.remaining and a.remaining > a.duration*Z.db.refresh/100 then return end
    local need, remaining = Z.Need(a,Z.db.refresh,upgrade)
    if not need then return end
    -- Unknown aura data is only actionable through a nameplate acquisition.
    if need == "inspect" and not unit:match("^nameplate") then return end
    local name = Z.FullName(unit)
    if not name then return end
    if not Z.seen[guid] then ordinal=ordinal+1 Z.seen[guid]=ordinal end
    return {unit=unit,guid=guid,class=class,level=level,spellID=id,profile=p,name=name,
        inspect=need=="inspect",state=need=="refresh" and 1 or 0,
        remaining=remaining,priority=priority,intent=intent or 2,order=Z.seen[guid],
        los=S.los[guid] and 1 or 0}
end
function Z.Candidate(unit, p, intent, waitForCaster)
    local guid, class, level = basic(unit)
    if not guid then return end
    return evaluate(unit,guid,class,level,p,intent,waitForCaster)
end

-- Unit tokens to scan, deduplicated, in a reused list. Callers iterate it
-- immediately and never call tokens() again while iterating.
local PARTY, RAID, PLATES = {}, {}, {}
for i=1,4 do PARTY[i]="party"..i end
for i=1,40 do RAID[i]="raid"..i PLATES[i]="nameplate"..i end
local list, listed, count = {}, {}, 0
local function push(u)
    if listed[u] then return end
    listed[u]=true count=count+1 list[count]=u
end
local function tokens()
    for u in pairs(listed) do listed[u]=nil end
    count=0
    push("target") push("mouseover")
    if IsInRaid and IsInRaid() then
        for i=1,math.min(GetNumGroupMembers(),40) do push(RAID[i]) end
    else
        for i=1,4 do push(PARTY[i]) end
    end
    for u in pairs(Z.plates) do if UnitExists(u) then push(u) else Z.plates[u]=nil end end
    -- Some builds do not expose a token on the nameplate frame.
    for i=1,40 do push(PLATES[i]) end
    for i=count+1,#list do list[i]=nil end
    return list
end

function Z.FinishBatchAttempt(attempt)
    local batch=S.batch
    if batch and attempt and batch.guid==attempt.guid then
        batch.done[attempt.profile.key]=true
    end
end
function Z.StartBatch(first)
    if S.batch then return end
    local guid,class,level=basic(first.unit)
    if not guid then return end
    local spells,ctx={},{}
    for _,p in ipairs(Z.active) do
        local c=evaluate(first.unit,guid,class,level,p,first.intent,nil,ctx)
        if c and not c.inspect then spells[#spells+1]=c end
    end
    if #spells<2 then return end
    table.sort(spells,Z.Compare)
    local profiles={}
    for _,c in ipairs(spells) do profiles[#profiles+1]=c.profile end
    S.batch={guid=first.guid,intent=first.intent,profiles=profiles,done={}}
end
local function scan()
    local queue, seen, ctx = {}, {}, {}
    for _, u in ipairs(tokens()) do
        local guid = UnitGUID(u)
        if guid and safe(guid) and not seen[guid] then
            seen[guid]=true
            local okGUID, class, level = basic(u)
            if okGUID then
                local intent = u=="target" and 0 or (u=="mouseover" and 1 or 2)
                -- Targets acquired by ZEUS stay in world priority, not user intent.
                if u=="target" and Z.autoTarget == guid then intent=2 end
                ctx.auras=nil
                for _, p in ipairs(Z.active) do
                    local c = evaluate(u,okGUID,class,level,p,intent,nil,ctx)
                    if c then queue[#queue+1]=c end
                end
            end
        end
    end
    table.sort(queue,Z.Compare)
    return queue
end
function Z.BuildQueue()
    if not Z.IsOperational() then return {} end
    local batch=S.batch
    if batch then
        for _,p in ipairs(batch.profiles) do
            if not batch.done[p.key] then
                for _,unit in ipairs(tokens()) do
                    if UnitGUID(unit)==batch.guid then
                        local c=Z.Candidate(unit,p,batch.intent)
                        if c then return {c} end
                    end
                end
                -- Another player may have buffed them, or eligibility changed.
                batch.done[p.key]=true
            end
        end
        -- Complete this recipient's visit before retrying any failed spell.
        S.passSkipped[batch.guid]=true
        S.batch=nil
    end
    -- Mana and cooldown failures retain the attempted GUID and buff
    -- while rechecking every recipient eligibility rule.
    local retry=S.retry
    if retry then
        for _,u in ipairs(tokens()) do
            if UnitGUID(u)==retry.guid then
                local c=Z.Candidate(u,retry.profile,retry.intent,true)
                if c then return {c} end
            end
        end
        S.retry=nil -- Gone, out of range, buffed, disabled, dead, or unsafe.
    end
    local queue=scan()
    if #queue==0 and next(S.passSkipped) then
        -- End of this pass: reconsider failed visits immediately, without a
        -- timer. One additional scan avoids recursion when nobody is eligible.
        S.passSkipped={}
        queue=scan()
    end
    return queue
end
