local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
function Z.Safe(v) return not (issecretvalue and issecretvalue(v)) end
-- Explicit target/mouseover first; class relevance and then lower level.
local SORT_KEYS = {"intent","priority","level","state","remaining","order"}
function Z.Compare(a, b)
    for i = 1, #SORT_KEYS do
        local k = SORT_KEYS[i]
        if a[k] ~= b[k] then return a[k] < b[k] end
    end
    if a.guid ~= b.guid then return a.guid < b.guid end
    return a.profile.key < b.profile.key
end
function Z.Suppressed(db, guid, key, now)
    local records = db.memory[guid]
    local r = records and records[key]
    if not r then return false end
    -- Recompute from the original cast when the slider changes. Absence of an
    -- aura NEVER erases this record; only observed death or expiration does.
    return r.expires and r.duration and now < r.expires - r.duration * db.refresh / 100
end
function Z.Remember(db, guid, key, now, duration, expires)
    db.memory[guid] = db.memory[guid] or {}
    db.memory[guid][key] = {cast=now, duration=duration, expires=expires or now+duration}
end
-- Older builds stored bounce deadlines without a duration. Preserve the
-- expiration and use the same learned/profile fallback as new bounce records.
function Z.MigrateMemory(db, durations)
    for guid, entries in pairs(db.memory) do
        if type(entries) ~= "table" then db.memory[guid]=nil
        else
            for key, record in pairs(entries) do
                if type(record) ~= "table" then entries[key]=nil
                elseif record.rejectUntil then
                    local duration=record.duration or durations[key]
                    if duration then
                        record.expires=record.expires or record.rejectUntil
                        record.duration=duration
                        record.rejectUntil=nil
                    else entries[key]=nil end
                end
            end
        end
    end
end
function Z.Rank(p, level)
    if type(level) ~= "number" or not Z.Safe(level) or level < 1 then return nil end
    for _, r in ipairs(p.learned or {}) do
        if level >= r[2] then return r[1] end
    end
end
-- Rank order comes from the profile's explicit spell list, never numeric IDs.
-- Covering group buffs and name-only matches remain unknown unless mapped.
function Z.SpellRankIndex(p,id)
    for i,rank in ipairs(p.ranks) do if rank[1]==id then return i end end
end
function Z.CanUpgrade(p,id,aura)
    local rank=Z.SpellRankIndex(p,id)
    return aura.found and not aura.rankUnknown and rank~=nil and aura.rankIndex~=nil
        and rank<aura.rankIndex
end
function Z.Need(aura, threshold, upgrade)
    if not aura.readable then return "inspect", math.huge end
    if not aura.found then return "missing", 0 end
    if upgrade then return "upgrade", 0 end
    if not aura.duration or aura.duration <= 0 or not aura.remaining then return nil end
    if aura.remaining > 0 and aura.remaining > aura.duration * threshold / 100 then return nil end
    return "refresh", math.max(0, aura.remaining)
end

-- Retain the current recipient only for mana and cooldown errors.
-- English fallbacks cover Forever builds that omit the globals.
function Z.RetryFailure(message)
    if type(message)~="string" or not Z.Safe(message) then return nil end
    local text=message:gsub("%.$","")
    local function matches(key)
        local value=_G[key]
        return type(value)=="string" and text==value:gsub("%.$","")
    end
    if matches("SPELL_FAILED_NO_POWER") or matches("ERR_OUT_OF_MANA")
        or text=="Not enough mana" then return "mana" end
    if matches("SPELL_FAILED_NOT_READY") or matches("ERR_SPELL_COOLDOWN")
        or matches("ERR_ABILITY_COOLDOWN") or text=="Not yet recovered"
        or text=="Spell is not ready yet" or text=="Ability is not ready yet" then
        return "cooldown"
    end
end

function Z.LineOfSightFailure(message)
    if type(message)~="string" or not Z.Safe(message) then return false end
    local text=message:gsub("%.$","")
    return text=="Target not in line of sight" or
        (type(SPELL_FAILED_LINE_OF_SIGHT)=="string" and
        text==SPELL_FAILED_LINE_OF_SIGHT:gsub("%.$",""))
end
