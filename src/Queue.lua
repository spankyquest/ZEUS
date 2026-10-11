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
-- Blessings. A paladin's blessing on a player replaces any other blessing from that paladin,
-- while blessings from different paladins stack. `snap` is the player's buffs; a nameplate's
-- can't be read, so there ZEUS goes by what it last cast or saw on them (its memory).
local function readable(snap) return snap and snap.readable and not snap.hidden end
-- Who holds blessing p on this player: "mine" when your own character gave it (ZEUS or by
-- hand), "other" when another paladin did, nil when nobody has it or it can't be told.
local function holder(guid, p, snap)
    if readable(snap) then
        local a = Z.MatchAura(snap,p)
        if not a.found then return nil end
        if safe(a.sourceUnit) then return Z.CastByMe(a.sourceUnit) and "mine" or "other" end
        -- The game hides who cast it: go by memory, so your own is never taken for another's.
    end
    local records = Z.db.memory[guid]
    local r = records and records[p.key]
    if type(r) ~= "table" or r.blockedBy or now() >= (tonumber(r.expires) or 0) then return nil end
    if r.observed and not r.mine then return "other" end
    return "mine"
end
-- Whether blessing p can't land on this player now: a bounce hold (Blockers.lua), or a buff
-- they carry that ZEUS learned blocks it (a scroll, say).
local function blockedBlessing(guid, p, level, snap)
    if Z.Held(guid,p,snap) then return true end
    local id = Z.Rank(p,level)
    return Z.LearnedBlocker(snap,p,id and Z.SpellRankIndex(p,id)) ~= nil
end
-- The one blessing to give this player, from the class's choices you allow (enabled, the
-- class not skipped in its row, a rank for their level):
--   1. a blessing you already gave them stays, and is refreshed when due;
--   2. otherwise the first choice no other paladin has given them and nothing blocks;
--   3. otherwise (they have them all) the first choice nothing blocks, kept up like any buff.
local function blessingFor(guid, class, level, snap)
    local keys, choices = {}, {}
    for _,key in ipairs(Z.blessings[class] or {}) do keys[#keys+1]=key end
    for _,p in ipairs(Z.active) do
        if p.blessing then
            local found=false
            for _,key in ipairs(keys) do if key==p.key then found=true end end
            if not found then keys[#keys+1]=p.key end
        end
    end
    for _, key in ipairs(keys) do
        for _, p in ipairs(Z.active) do
            if p.key == key and enabled(p) and Z.ClassPriority(Z.db,p,class) and Z.Rank(p,level) then
                choices[#choices+1]=p
            end
        end
    end
    if #choices == 0 then return end
    local held = {}
    for i, p in ipairs(choices) do
        held[i] = holder(guid,p,snap)
        if held[i] == "mine" then return p.key end
    end
    local open = {}
    for i, p in ipairs(choices) do
        open[i] = not blockedBlessing(guid,p,level,snap)
        if held[i] ~= "other" and open[i] then return p.key end
    end
    for i, p in ipairs(choices) do
        if open[i] then return p.key end
    end
    return choices[1].key
end
-- Whether a different blessing of yours on this player should stay: one you gave that is not
-- yet due for a refresh, or one they clicked off (ZEUS waits its usual time before giving
-- them anything else). A record of yours that another paladin's blessing has since replaced
-- doesn't count.
local function keepOtherBlessing(guid, p, snap)
    local records = Z.db.memory[guid]
    for _, other in ipairs(Z.active) do
        if other.blessing and other ~= p then
            local who = readable(snap) and holder(guid,other,snap)
            if who == "mine" then
                local b = Z.MatchAura(snap,other)
                if b.duration and b.remaining and b.remaining > b.duration*Z.db.refresh/100 then return true end
            else
                local r = records and records[other.key]
                if r and not r.blockedBy and (not r.observed or r.mine) and who ~= "other"
                    and Z.Suppressed(Z.db,guid,other.key,now()) then return true end
            end
        end
    end
end
-- Damage cancels some buffs (Water Walking). ZEUS decides why one of yours is gone the first
-- time it sees it missing: in a fight it was knocked off, and it is given again once the fight
-- ends; otherwise it was clicked off and ZEUS waits its usual time, as for any buff. True while
-- a knocked-off buff waits for the fight to end.
local function knockedOff(guid, p, unit)
    local records = Z.db.memory[guid]
    local r = records and records[p.key]
    if type(r) ~= "table" or r.blockedBy or r.observed or now()-(tonumber(r.cast) or 0) < 2 then return false end
    local ok, fighting = pcall(UnitAffectingCombat, unit)
    fighting = ok and safe(fighting) and fighting == true
    if r.knocked == nil then r.knocked = fighting end
    if not r.knocked then return false end
    if fighting then return true end
    records[p.key] = nil
    return false
end
-- Decide whether one buff is needed on an already-checked player. `ctx` caches that player's
-- aura snapshot and blessing choice across the buffs evaluated in the same scan.
local function evaluate(unit, guid, class, level, p, intent, waitForCaster, ctx)
    local priority = Z.ClassPriority(Z.db,p,class)
    if not enabled(p) or not priority then return end
    local id = Z.Rank(p,level)
    if not id or not Z.InRange(id,unit) or (not waitForCaster and not Z.Usable(id)) then return end
    local snap = ctx and ctx.auras
    if not snap then
        snap = Z.ReadAuras(unit)
        if ctx then ctx.auras = snap end
    end
    if p.blessing then
        local choice = ctx and ctx.blessing
        if choice == nil then
            choice = blessingFor(guid,class,level,snap) or false
            if ctx then ctx.blessing = choice end
        end
        if choice ~= p.key then return end
    end
    local a = Z.MatchAura(snap,p)
    if a.blocked then return end
    local rank = Z.SpellRankIndex(p,id)
    -- Another caster's stronger rank: a weaker cast would only bounce.
    if rank and a.rankIndex and a.rankIndex < rank then return end
    -- A buff that bounced this one before, on this player or learned for everyone.
    if Z.Held(guid,p,snap) or Z.LearnedBlocker(snap,p,rank) then return end
    if p.breaksOnDamage and readable(snap) and not a.found and knockedOff(guid,p,unit) then return end
    local upgrade=Z.CanUpgrade(p,id,a)
    if Z.Suppressed(Z.db,guid,p.key,now()) then
        if not upgrade then return end
        local record=Z.db.memory[guid][p.key]
        -- Allow the just-cast aura to arrive before trusting a stale lower rank.
        if record.cast and now()-record.cast<2 then return end
    end
    -- A new blessing from you would replace your other one: not while that one should stay.
    if p.blessing and keepOtherBlessing(guid,p,snap) then return end
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
-- A nameplate player ZEUS just targeted for buff p, now that their buffs can be read. For a
-- blessing those buffs can change the choice (another paladin already gave the one ZEUS
-- guessed), so the blessing they now call for is given instead.
function Z.AcquiredCandidate(unit, p, intent, waitForCaster)
    local guid, class, level = basic(unit)
    if not guid then return end
    local ctx = {}
    local c = evaluate(unit,guid,class,level,p,intent,waitForCaster,ctx)
    if c or not p.blessing then return c end
    for _, other in ipairs(Z.active) do
        if other.blessing and other ~= p then
            c = evaluate(unit,guid,class,level,other,intent,waitForCaster,ctx)
            if c then return c end
        end
    end
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
                ctx.auras,ctx.blessing=nil,nil
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
