local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
local L = Z.L
-- "A more powerful spell is already active." The game does not say which spell, so ZEUS
-- works it out from the buffs the player carried when the cast bounced:
--   1. the same buff at the same or a stronger rank, or a group version of it
--      (Arcane Brilliance for Arcane Intellect, say). A group version is learned at once;
--   2. a buff ZEUS already learned blocks this one;
--   3. otherwise one of the player's other timed buffs (a scroll, say). The one buff that
--      three bouncing players within ten minutes all carried is learned as a guess.
-- The player is then held while that buff (or, if not yet known, any of the suspects)
-- stays on them, instead of being queued again every few seconds.
-- Learned blockers are saved per buff and rank, listed by /zeus blockers, and forgotten
-- after a week without being seen again. A success on a player carrying one unlearns it;
-- because a learned blocker stops those casts, a guess is let through once every five
-- minutes so that a wrong guess is corrected.
local function now() return time() end
local MAX_LEARNED = 24          -- per buff; the least recently confirmed is dropped beyond this
local GUESS_PLAYERS = 3         -- distinct bouncing players before a guess is learned
local SUSPECT_WINDOW = 600      -- seconds a set of suspects stays open
local PROBE_EVERY = 300         -- seconds between casts let past a guessed blocker
local FORGET_AFTER = 7 * 86400  -- seconds a learned blocker lasts without being seen again
local cleared = {}  -- [profile key][aura ID] = weakest rank index seen succeeding beside it
local suspects = {} -- [profile key] = {ids={[id]=name}, guids={}, players=n, rank=index, since=t}
local probeAt = {}  -- [profile key] = GetTime() from which one cast may pass a guess

local zeusIDs
local function ownedByZEUS(id)
    if not zeusIDs then
        zeusIDs = {}
        for _, p in ipairs(Z.profiles) do
            for spell in pairs(p.ids) do zeusIDs[spell] = true end
        end
    end
    return zeusIDs[id]
end
local function usable(snap) return snap and snap.readable and not snap.hidden end
local function timed(a)
    return Z.Safe(a.expirationTime) and Z.Safe(a.duration) and type(a.expirationTime) == "number"
        and type(a.duration) == "number" and a.expirationTime > 0 and a.duration > 0
end
local function sameUnit(unit, guid)
    local current = UnitGUID(unit)
    return Z.Safe(current) and current ~= nil and current == guid
end
local function rankNumber(p, index) return #p.ranks - index + 1 end
local function profileByKey(key)
    for _, p in ipairs(Z.profiles) do if p.key == key then return p end end
end

function Z.NormalizeBlockers(db)
    if type(db.blockers) ~= "table" then db.blockers = {} end
    local t = now()
    for key, list in pairs(db.blockers) do
        local p = type(key) == "string" and profileByKey(key)
        if not p or type(list) ~= "table" then db.blockers[key] = nil
        else
            for id, b in pairs(list) do
                local rank = type(b) == "table" and tonumber(b.rank)
                local at = type(b) == "table" and tonumber(b.at)
                if type(id) ~= "number" or not rank or rank ~= math.floor(rank) or rank < 1
                    or (at and t - at > FORGET_AFTER) then
                    list[id] = nil
                else
                    b.rank = math.min(rank, #p.ranks)
                    b.at = at or t
                    b.name = type(b.name) == "string" and b.name or nil
                    b.guess = b.guess == true or nil
                end
            end
            if not next(list) then db.blockers[key] = nil end
        end
    end
end

-- A learned blocker in this snapshot that stops a cast of rank index `rank` (1 = strongest).
function Z.LearnedBlocker(snap, p, rank)
    local list = Z.db.blockers[p.key]
    if not list or not rank or not usable(snap) then return end
    local probing = (probeAt[p.key] or 0) <= GetTime()
    for _, a in ipairs(snap.list) do
        local b = list[a.id]
        if b and rank >= b.rank and not (b.guess and probing) then return a end
    end
end

-- Whether a bounce hold keeps this player out of this buff. With readable buffs the hold
-- lasts while one of its blockers is present and ends the moment they are all gone;
-- without (a nameplate) it lasts until the remembered expiration.
function Z.Held(guid, p, snap)
    local records = Z.db.memory[guid]
    local r = records and records[p.key]
    if type(r) ~= "table" or type(r.blockedBy) ~= "table" then return false end
    local t = now()
    if usable(snap) and t < (tonumber(r.expires) or 0) then
        for _, a in ipairs(snap.list) do
            for _, id in ipairs(r.blockedBy) do
                if a.id == id then return true end
            end
        end
    elseif not usable(snap) then
        return t < (tonumber(r.expires) or 0)
    end
    records[p.key] = nil
    if not next(records) then Z.db.memory[guid] = nil end
    return false
end

-- Learn, or confirm, that aura `a` blocks rank index `rank` of p. `lower` lets a bounce at a
-- stronger rank widen it; a guess is only widened by evidence it alone explains.
local function learn(p, a, rank, guess, lower)
    local list = Z.db.blockers[p.key]
    if not list then list = {} Z.db.blockers[p.key] = list end
    local b = list[a.id]
    if b then
        b.at = now()
        if lower and rank < b.rank then b.rank = rank end
        if not guess then b.guess = nil end
        return
    end
    list[a.id] = {rank=rank, name=a.name, at=now(), guess=guess or nil}
    local count, oldest = 0, nil
    for id, other in pairs(list) do
        count = count + 1
        if not oldest or other.at < list[oldest].at then oldest = id end
    end
    if count > MAX_LEARNED then list[oldest] = nil end
    if guess then probeAt[p.key] = GetTime() + PROBE_EVERY end
    Z.Print(string.format(guess and L.BLOCKER_GUESSED or L.BLOCKER_LEARNED,
        tostring(a.name or a.id), p.label, rankNumber(p, rank)))
end

-- Narrow the unknown suspects with this bounce; learn the one buff every bouncing player shared.
local function narrow(p, others, guid, rank)
    local ids = {}
    for _, a in ipairs(others) do ids[a.id] = a.name end
    local s = suspects[p.key]
    if s and GetTime() - s.since > SUSPECT_WINDOW then s = nil end
    local shared = 0
    if s then
        local both = {}
        for id, name in pairs(s.ids) do
            if ids[id] then both[id] = name shared = shared + 1 end
        end
        if shared > 0 then
            s.ids = both
            if not s.guids[guid] then s.guids[guid] = true s.players = s.players + 1 end
            if rank > s.rank then s.rank = rank end -- Only ranks every one of them refused.
        end
    end
    if not s or shared == 0 then
        s = {ids=ids, guids={[guid]=true}, players=1, rank=rank, since=GetTime()}
        suspects[p.key] = s
    end
    -- Drop a suspect that a success has since shown harmless at this rank.
    local okay = cleared[p.key] or {}
    local left, last = 0, nil
    for id in pairs(s.ids) do
        if okay[id] and okay[id] >= s.rank then s.ids[id] = nil
        else left = left + 1 last = id end
    end
    if s.players >= GUESS_PLAYERS and left == 1 then
        learn(p, {id=last, name=s.ids[last]}, s.rank, true)
        suspects[p.key] = nil
    end
end

-- Which buffs on the player stopped a cast of rank index `rank`; learns what it can.
local function identify(snap, p, rank, guid)
    local own, covers, known, others = {}, {}, {}, {}
    local list = Z.db.blockers[p.key]
    local okay = cleared[p.key] or {}
    for _, a in ipairs(snap.list) do
        local id = a.id
        if p.ids[id] or (p.names and p.names[a.name]) then
            local r = Z.SpellRankIndex(p, id)
            if not r then
                covers[#covers+1] = a -- A group or unlisted version of this buff.
                own[#own+1] = id
            elseif r <= rank then
                own[#own+1] = id -- The same or a stronger rank: hold only, never learn.
            end
        elseif list and list[id] then
            known[#known+1] = a
        elseif timed(a) and not ownedByZEUS(id) and not (okay[id] and okay[id] >= rank) then
            others[#others+1] = a -- An untimed aura (a paladin aura, a form) cannot do this.
        end
    end
    if #own > 0 then
        for _, a in ipairs(covers) do learn(p, a, rank, false, true) end
        return own
    end
    if #known > 0 then
        local ids = {}
        for i, a in ipairs(known) do
            learn(p, a, rank, list[a.id].guess, #known == 1 and #others == 0)
            ids[i] = a.id
        end
        probeAt[p.key] = GetTime() + PROBE_EVERY
        return ids
    end
    if #others == 0 then return end
    narrow(p, others, guid, rank)
    local ids = {}
    for i, a in ipairs(others) do ids[i] = a.id end
    return ids
end

-- Called for "A more powerful spell is already active" on the prepared cast.
function Z.NoteBounce(pending)
    local p, guid = pending.profile, pending.guid
    local snap = pending.auras
    if sameUnit(pending.unit, guid) then
        local fresh = Z.ReadAuras(pending.unit)
        if usable(fresh) then snap = fresh end
    end
    local t = now()
    local duration = Z.ProfileDuration(p)
    local rank = Z.SpellRankIndex(p, pending.spellID) or #p.ranks
    local ids = usable(snap) and identify(snap, p, rank, guid)
    if ids then
        -- Hold until the longest-lasting blocker ends; the profile duration caps it.
        local hold, length = 0, duration
        for _, a in ipairs(snap.list) do
            for _, id in ipairs(ids) do
                if a.id == id then
                    local left = timed(a) and a.expirationTime - GetTime() or duration
                    if left > hold then hold, length = left, timed(a) and a.duration or duration end
                end
            end
        end
        hold = math.min(math.max(hold, 1), duration)
        Z.Remember(Z.db, guid, p.key, t, length, t + hold, ids)
        return
    end
    -- Nothing identifiable: remember the buff's observed timing, or the profile duration.
    local expiration = t + duration
    if usable(snap) then
        local aura = Z.MatchAura(snap, p)
        if aura.duration and aura.remaining and aura.remaining > 0 then
            duration, expiration = aura.duration, t + aura.remaining
        end
    end
    Z.Remember(Z.db, guid, p.key, t, duration, expiration)
end

-- A success beside a buff shows that buff does not block this rank (or any stronger one).
function Z.NoteBuffSuccess(pending)
    local snap = pending.auras
    local p = pending.profile
    local rank = Z.SpellRankIndex(p, pending.spellID)
    if not usable(snap) or not rank then return end
    local okay = cleared[p.key]
    if not okay then okay = {} cleared[p.key] = okay end
    local list = Z.db.blockers[p.key]
    for _, a in ipairs(snap.list) do
        if not okay[a.id] or okay[a.id] < rank then okay[a.id] = rank end
        local b = list and list[a.id]
        if b and rank >= b.rank then
            list[a.id] = nil
            Z.Print(string.format(L.BLOCKER_FORGOTTEN,
                tostring(b.name or a.name or a.id), p.label))
        end
    end
    if list and not next(list) then Z.db.blockers[p.key] = nil end
end

-- A targeted nameplate player turned out to need nothing: remember why, so the next
-- nameplate scan does not target them again for the same buff. These records are
-- marked observed: they describe a buff ZEUS saw, not one it cast. One you cast by hand is
-- also marked mine. For a blessing every blessing they carry is noted, since which one ZEUS
-- gives depends on the others (Queue.lua).
local verify
function Z.NoteVerified(unit, guid, p)
    if not sameUnit(unit, guid) then return end
    local snap = Z.ReadAuras(unit)
    if not usable(snap) then return end
    if p.blessing then
        for _, other in ipairs(Z.active) do
            if other.blessing and other ~= p then verify(unit, guid, other, snap) end
        end
    end
    verify(unit, guid, p, snap)
end
function verify(unit, guid, p, snap)
    local t = now()
    local id = Z.Rank(p, UnitLevel(unit))
    local rank = id and Z.SpellRankIndex(p, id)
    local aura = Z.MatchAura(snap, p)
    local blocker = rank and Z.LearnedBlocker(snap, p, rank)
    if not blocker and rank and aura.rankIndex and aura.rankIndex < rank then
        blocker = {id=aura.spellID, expirationTime=aura.remaining and GetTime() + aura.remaining,
            duration=aura.duration}
    end
    if blocker and blocker.id then
        local duration = Z.ProfileDuration(p)
        local left = timed(blocker) and blocker.expirationTime - GetTime() or duration
        Z.Remember(Z.db, guid, p.key, t, duration, t + math.min(math.max(left, 1), duration), {blocker.id})
    elseif aura.found and aura.duration and aura.remaining and aura.remaining > 0 then
        Z.Remember(Z.db, guid, p.key, t, aura.duration, t + aura.remaining)
        Z.db.memory[guid][p.key].mine = Z.CastByMe(aura.sourceUnit) or nil
    else
        return
    end
    Z.db.memory[guid][p.key].observed = true
end

function Z.PrintBlockers()
    local any = false
    for _, p in ipairs(Z.profiles) do
        local list = Z.db.blockers[p.key]
        if list then
            local rows = {}
            for id, b in pairs(list) do rows[#rows+1] = {id=id, b=b} end
            table.sort(rows, function(x, y) return x.id < y.id end)
            for _, row in ipairs(rows) do
                any = true
                Z.Print(string.format(row.b.guess and L.BLOCKER_ROW_GUESS or L.BLOCKER_ROW,
                    row.b.name or L.UNKNOWN_BUFF, row.id, p.label, rankNumber(p, row.b.rank)))
            end
        end
    end
    if not any then Z.Print(L.BLOCKERS_NONE) end
    Z.Print(L.BLOCKERS_CLEAR_HINT)
end

-- Forget every learned blocker and release every player held by one.
function Z.ClearBlockers()
    Z.db.blockers = {}
    for key in pairs(suspects) do suspects[key] = nil end
    for key in pairs(probeAt) do probeAt[key] = nil end
    for guid, records in pairs(Z.db.memory) do
        if type(records) == "table" then
            for key, r in pairs(records) do
                if type(r) == "table" and r.blockedBy then records[key] = nil end
            end
            if not next(records) then Z.db.memory[guid] = nil end
        end
    end
    Z.Print(L.BLOCKERS_CLEARED)
end
