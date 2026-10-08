local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
-- Spell knowledge and aura reading. A unit's buffs are read once into a
-- snapshot; each buff profile is then matched against that snapshot.
local function safe(v) return Z.Safe(v) end
-- Learned passive that doubles blessing duration. Observed auras always win;
-- this only shapes the fallback duration remembered after a cast.
local BLESSING_DURATION_PASSIVE = 435984

function Z.SpellName(id, fallback)
    local name
    if C_Spell and C_Spell.GetSpellName then name = C_Spell.GetSpellName(id)
    elseif GetSpellInfo then name = GetSpellInfo(id) end
    if safe(name) and name then return name end
    return fallback
end
function Z.Known(id)
    if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(id) then return true end
    if IsPlayerSpell and IsPlayerSpell(id) then return true end
    if IsSpellKnown and IsSpellKnown(id) then return true end
    return false
end
function Z.ProfileDuration(p)
    return p.duration * (p.blessing and Z.Known(BLESSING_DURATION_PASSIVE) and 2 or 1)
end
function Z.RefreshSpells()
    Z.active = {}
    for _, p in ipairs(Z.profiles) do
        if p.class == Z.class then
            p.learned, p.names = {}, {}
            for id in pairs(p.ids) do
                local name = Z.SpellName(id)
                if name then p.names[name] = true end
            end
            for _, r in ipairs(p.ranks) do
                if Z.Known(r[1]) then p.learned[#p.learned+1] = r end
            end
            Z.active[#Z.active+1] = p
        end
    end
end
function Z.FullName(unit)
    local name
    if GetUnitName then name = GetUnitName(unit, true)
    else name = UnitName(unit) end
    if not safe(name) or type(name) ~= "string" or name == "" then return nil end
    if name:find("[%c%[%];/]") or name:find("\\",1,true) then return nil end
    return name
end
function Z.InRange(id, unit)
    local value
    if C_Spell and C_Spell.IsSpellInRange then value = C_Spell.IsSpellInRange(id,unit)
    elseif IsSpellInRange then value = IsSpellInRange(Z.SpellName(id),unit) end
    return safe(value) and (value == true or value == 1)
end
function Z.Usable(id)
    local ok
    if C_Spell and C_Spell.IsSpellUsable then ok = C_Spell.IsSpellUsable(id)
    elseif IsUsableSpell then ok = IsUsableSpell(id)
    else return true end
    return safe(ok) and ok == true
end

-- Read every helpful aura on a unit once. `hidden` marks secret or failed
-- reads; it makes the whole snapshot unreadable for every profile.
function Z.ReadAuras(unit)
    local snap = {readable=false, hidden=false, list={}}
    -- A nameplate token discovers candidates; it is never an aura source.
    -- Some clients reject the API call itself, before a secret-value check can run.
    if not safe(unit) or type(unit)~="string" or unit:match("^nameplate") then return snap end
    local list = snap.list
    local function add(a)
        if not safe(a) then snap.hidden=true return end
        if not a then return end
        local id, name = a.spellId or a.spellID, a.name
        if not safe(id) or not safe(name) then snap.hidden=true return end
        list[#list+1] = {id=id, name=name, expirationTime=a.expirationTime,
            duration=a.duration, sourceUnit=a.sourceUnit}
    end
    local indexed = C_UnitAuras and (C_UnitAuras.GetAuraDataByIndex or C_UnitAuras.GetBuffDataByIndex)
    if indexed then
        snap.readable = true
        for i=1,100 do
            local ok,a = pcall(indexed,unit,i,"HELPFUL")
            if not ok or not safe(a) then snap.hidden=true break end
            if not a then break end
            add(a)
        end
    elseif UnitBuff then
        snap.readable = true
        for i=1,100 do
            local ok,name,_,_,_,duration,expiration,source,_,_,id = pcall(UnitBuff,unit,i)
            if not ok or not safe(name) then snap.hidden=true break end
            if not name then break end
            add({name=name,spellId=id,duration=duration,expirationTime=expiration,sourceUnit=source})
        end
    end
    return snap
end

-- Match one buff profile against a snapshot. The strongest known rank and the
-- longest timed instance win; untimed or partially hidden matches are blocked.
function Z.MatchAura(snap, p)
    local result = {found=false, readable=snap.readable and not snap.hidden}
    local untimed = false
    local t = GetTime()
    for _, a in ipairs(snap.list) do
        local id = a.id
        if p.ids[id] or p.names[a.name] then
            result.found = true
            local rank = Z.SpellRankIndex(p,id)
            if not rank then result.rankUnknown = true
            elseif not result.rankIndex or rank < result.rankIndex then result.rankIndex = rank end
            local exp, duration = a.expirationTime, a.duration
            if not safe(exp) or not safe(duration) or type(exp) ~= "number"
                or type(duration) ~= "number" or exp == 0 or duration <= 0 then
                untimed = true
            elseif not result.remaining or exp-t > result.remaining then
                result.remaining, result.duration = exp-t, duration
                result.spellID, result.sourceUnit = id, a.sourceUnit
            end
        end
    end
    if untimed then result.remaining, result.duration = nil, nil end
    -- A positively seen covering buff is safe to skip even on a nameplate.
    if result.found and (untimed or snap.hidden) then result.blocked = true end
    return result
end

function Z.Aura(unit, p)
    return Z.MatchAura(Z.ReadAuras(unit), p)
end
