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
-- The level a class trainer teaches a rank from: the game's own answer, or Data.lua's when the
-- game can't say.
function Z.LearnLevel(r)
    if C_Spell and C_Spell.GetSpellLevelLearned then
        local ok, level = pcall(C_Spell.GetSpellLevelLearned, r[1])
        if ok and safe(level) and type(level) == "number" and level > 0 then return level end
    end
    return r[3] or 1
end
function Z.ProfileDuration(p)
    return p.duration * (p.blessing and Z.Known(BLESSING_DURATION_PASSIVE) and 2 or 1)
end
-- Buff names in the game's language: English clients keep the profile's label; others use the
-- client's own name for the spell (the label spell, or the strongest rank).
local function localLabel(p)
    p.englishLabel = p.englishLabel or p.label
    local code = Z.language and Z.language.code
    if not code or code == "enUS" or code == "enGB" then return p.englishLabel end
    return Z.SpellName(p.labelSpell or p.ranks[1][1], p.englishLabel)
end
function Z.RefreshSpells()
    Z.active = {}
    for _, p in ipairs(Z.profiles) do
        if p.class == Z.class then
            p.label = localLabel(p)
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
    -- A rank learned at the trainer since a lower one was picked: back to the strongest.
    if Z.db and Z.UpdateRankChoices then Z.UpdateRankChoices(Z.db) end
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
-- Seconds until a spell can be cast again, the global cooldown included; 0 when it can be cast
-- now or the game won't say.
function Z.CooldownLeft(id)
    local get = C_Spell and C_Spell.GetSpellCooldown
    if type(get) ~= "function" then return 0 end
    local ok, info = pcall(get, id)
    if not ok or not safe(info) or type(info) ~= "table" then return 0 end
    local start, duration = info.startTime, info.duration
    if not safe(start) or not safe(duration) or type(start) ~= "number" or type(duration) ~= "number" then return 0 end
    if start <= 0 or duration <= 0 then return 0 end
    return math.max(0, start + duration - GetTime())
end
-- The game's spell queue window in seconds: a cast pressed this close to the end of the global
-- cooldown waits and goes off as it ends. 0 when the game won't say.
function Z.QueueWindow()
    local get = C_Spell and C_Spell.GetSpellQueueWindow
    if type(get) ~= "function" then return 0 end
    local ok, ms = pcall(get)
    if not ok or not safe(ms) or type(ms) ~= "number" or ms <= 0 then return 0 end
    return ms / 1000
end
-- Whether you can cast a spell now; when you can't, the second value says it's only for mana.
function Z.Usable(id)
    local ok, noMana
    if C_Spell and C_Spell.IsSpellUsable then ok, noMana = C_Spell.IsSpellUsable(id)
    elseif IsUsableSpell then ok, noMana = IsUsableSpell(id)
    else return true end
    if not safe(ok) then return false, false end
    if ok == true then return true end
    return false, safe(noMana) and noMana == true or false
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

-- Whether an aura's caster (its sourceUnit) is your own character: cast by ZEUS or by hand.
function Z.CastByMe(unit)
    if not safe(unit) or type(unit) ~= "string" or unit == "" then return false end
    if unit == "player" then return true end
    local guid, mine = UnitGUID(unit), UnitGUID("player")
    return safe(guid) and safe(mine) and guid ~= nil and guid == mine
end

-- /zeus auras: every buff on your target (or on you, with no target), with its spell ID, time
-- left and caster, to find the ID of a buff that keeps one of yours from landing.
function Z.PrintAuras()
    local L = Z.L
    local unit = UnitExists("target") and "target" or "player"
    local who = Z.FullName(unit) or unit
    local snap = Z.ReadAuras(unit)
    if not snap.readable or snap.hidden then Z.Print(string.format(L.AURAS_HIDDEN, who)) return end
    if #snap.list == 0 then Z.Print(string.format(L.AURAS_NONE, who)) return end
    Z.Print(string.format(L.AURAS_HEADER, who))
    local t = GetTime()
    for _, a in ipairs(snap.list) do
        local exp = a.expirationTime
        local left = L.AURA_NO_TIMER
        if safe(exp) and type(exp) == "number" and exp > 0 then
            left = string.format(L.AURA_MINUTES, math.max(0, math.ceil((exp - t) / 60)))
        end
        local from = L.AURA_FROM_UNKNOWN
        if Z.CastByMe(a.sourceUnit) then from = L.AURA_FROM_YOU
        elseif safe(a.sourceUnit) and type(a.sourceUnit) == "string" then
            from = Z.FullName(a.sourceUnit) or from
        end
        Z.Print(string.format(L.AURA_ROW, tostring(a.name), tonumber(a.id) or 0, left, from))
    end
end
