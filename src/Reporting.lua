local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
-- Net duration added at a successful cast, not elapsed uptime or proof of benefit.
local seen, order, active = {}, {}, {}
local function finite(n)
    return Z.Safe(n) and type(n)=="number" and n==n and n>=0 and n<9007199254740991
end
local function timestamp()
    local value = GetServerTime and GetServerTime() or time()
    if finite(value) then return math.floor(value) end
end
local function clean(map, integers)
    if type(map)~="table" then return {} end
    for day,n in pairs(map) do
        if not finite(day) or day~=math.floor(day) or not finite(n)
            or (integers and n~=math.floor(n)) then map[day]=nil end
    end
    return map
end
function Z.InitializeReporting()
    -- Never reinterpret old schema-1 cast counts as minutes; leave them archived.
    local db=Z.db
    if type(db.buffReports)~="table" or db.buffReports.schema~=2 then
        db.buffReports={schema=2,seconds={},unmeasured={}}
    end
    db.buffReports.seconds=clean(db.buffReports.seconds,false)
    db.buffReports.unmeasured=clean(db.buffReports.unmeasured,true)
end
local function key(guid,p) return guid..":"..p.key end
-- One observation per recipient of a cast. A cast is settled when all of its
-- observations finish: measured time is added per recipient, and a cast that
-- measured nobody counts once as unmeasured.
local function finish(r,seconds)
    if active[r.key]~=r then return end
    active[r.key]=nil
    local cast,db=r.cast,Z.db.buffReports
    if seconds~=nil then
        db.seconds[cast.day]=(db.seconds[cast.day] or 0)+seconds
        cast.measured=true
    end
    cast.open=cast.open-1
    if cast.open==0 and not cast.measured then
        db.unmeasured[cast.day]=(db.unmeasured[cast.day] or 0)+1
    end
end
local function observe(r,unit,aura)
    if active[r.key]~=r or UnitGUID(unit)~=r.guid then return end
    if type(unit)~="string" or unit:match("^nameplate") then return end
    aura=aura or Z.Aura(unit,r.profile)
    if not aura.readable or not aura.found or aura.blocked or aura.spellID~=r.spellID
        or not finite(aura.remaining) or not finite(aura.duration) or aura.duration<=0 then return end
    if not Z.Safe(aura.sourceUnit) then return end
    -- Where the client supplies a source, it must be this player.
    if aura.sourceUnit and UnitGUID(aura.sourceUnit)~=UnitGUID("player") then return end
    local expires=GetTime()+aura.remaining
    -- An unchanged aura may be stale; allow subsequent UNIT_AURA/timer observations.
    if expires<=r.before and aura.spellID==r.beforeSpellID then return end
    local seconds=math.max(0,math.min(aura.duration,expires-math.max(r.before,r.succeededAt)))
    finish(r,seconds)
end
function Z.CaptureBuffTime(unit,p)
    local aura=Z.Aura(unit,p)
    local guid=UnitGUID(unit)
    local old=guid and active[key(guid,p)]
    if old then
        observe(old,unit,aura)
        -- Never let an unresolved earlier cast claim a subsequent cast's aura.
        if active[old.key]==old then finish(old,nil) end
    end
    if not aura.readable or aura.blocked then return nil end
    if not aura.found then return 0 end
    local remaining=aura.remaining
    if not Z.Safe(remaining) or type(remaining)~="number" or remaining~=remaining
        or math.abs(remaining)>=9007199254740991
        or not finite(aura.duration) or aura.duration<=0 then return nil end
    return GetTime()+math.max(0,remaining),aura.spellID
end
local ALIASES={"target","mouseover","player"}
local function observeAliases(r,skip)
    if r.unit~=skip then observe(r,r.unit) end
    for _,alias in ipairs(ALIASES) do
        if active[r.key]~=r then return end
        if alias~=skip and alias~=r.unit then observe(r,alias) end
    end
end
function Z.ObserveBuffReports(unit)
    if not Z.Safe(unit) or type(unit)~="string" then return end
    -- Only the player whose auras changed needs a look, through any readable
    -- alias (a nameplate event settles through target or a group token).
    local guid=UnitGUID(unit)
    if not Z.Safe(guid) then guid=nil end
    for _,r in pairs(active) do
        if not guid or r.guid==guid then
            observe(r,unit)
            if active[r.key]==r then observeAliases(r,unit) end
        end
    end
end
-- Start observing one successful cast. `recipients` lists {guid, unit, before,
-- beforeSpellID}; an empty list records a cast that cannot be measured.
local function recordCast(profile,spellID,recipients,castGUID)
    if not Z.db or not Z.db.buffReports then return end
    if not Z.Safe(castGUID) or (castGUID~=nil and type(castGUID)~="string") then return end
    if castGUID and seen[castGUID] then return end
    local stamp=timestamp()
    if not stamp then return end
    if castGUID then
        seen[castGUID]=true order[#order+1]=castGUID
        if #order>512 then seen[table.remove(order,1)]=nil end
    end
    local cast={day=math.floor(stamp/86400),open=0,measured=false}
    local records={}
    for _,who in ipairs(recipients) do
        local k=key(who.guid,profile)
        if active[k] then finish(active[k],nil) end
        local r={key=k,guid=who.guid,unit=who.unit,profile=profile,spellID=spellID,
            before=who.before,beforeSpellID=who.beforeSpellID,succeededAt=GetTime(),cast=cast}
        active[k]=r cast.open=cast.open+1 records[#records+1]=r
    end
    if #records==0 then
        local db=Z.db.buffReports
        db.unmeasured[cast.day]=(db.unmeasured[cast.day] or 0)+1
        return
    end
    for _,r in ipairs(records) do
        if not finite(r.before) then finish(r,nil) end
    end
    local function check(last)
        for _,r in ipairs(records) do
            if active[r.key]==r then observeAliases(r) end
            if last and active[r.key]==r then finish(r,nil) end
        end
    end
    check(false)
    if cast.open==0 then return end
    C_Timer.After(0.15,function() check(false) end)
    C_Timer.After(0.5,function() check(false) end)
    C_Timer.After(1,function() check(true) end)
end
function Z.RecordReportedSuccess(attempt,castGUID)
    if not attempt or attempt.failed then return end
    recordCast(attempt.profile,attempt.spellID,{{guid=attempt.guid,unit=attempt.unit,
        before=attempt.buffExpiresBefore,beforeSpellID=attempt.buffSpellBefore}},castGUID)
end

-- Buffs cast without ZEUS: action bars, macros, click-casting. The send event
-- names the recipient before the aura changes, so the previous expiration is
-- captured exactly as for ZEUS casts. Group buffs (Arcane Brilliance, Prayer of
-- Fortitude, Greater Blessings...) watch every group member; only members who
-- actually receive the buff are credited. Buffs on yourself are not counted.
local manual={}
local GROUP={}
for i=1,40 do GROUP[i]="raid"..i end
local PARTY={"party1","party2","party3","party4"}
local NAMED={"target","mouseover","focus"}
local function groupTokens()
    if IsInRaid and IsInRaid() then return GROUP,math.min(GetNumGroupMembers(),40) end
    return PARTY,4
end
local function profileFor(id)
    for _,p in ipairs(Z.active or {}) do
        for _,rank in ipairs(p.ranks) do if rank[1]==id then return p,false end end
    end
    for _,p in ipairs(Z.active or {}) do
        for _,cover in ipairs(p.cover or {}) do if cover==id then return p,true end end
    end
end
local function recipient(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or not UnitIsFriend("player",unit) then return end
    local guid=UnitGUID(unit)
    if not Z.Safe(guid) or not guid or guid==UnitGUID("player") then return end
    -- Edition hook: the Olympus guild filter applies to manual casts too.
    if Z.RecipientFilter and not Z.RecipientFilter(unit) then return end
    return guid
end
local function named(unit,name)
    if not UnitExists(unit) then return false end
    local short=UnitName(unit)
    return Z.FullName(unit)==name or (Z.Safe(short) and short==name)
end
local function unitNamed(name)
    for _,unit in ipairs(NAMED) do if named(unit,name) then return unit end end
    local tokens,n=groupTokens()
    for i=1,n do if named(tokens[i],name) then return tokens[i] end end
end
-- UNIT_SPELLCAST_SENT for a player cast that ZEUS did not prepare.
function Z.NoteManualCast(targetName,castGUID,spellID)
    if not Z.db or not Z.Safe(spellID) or not Z.Safe(castGUID) then return end
    if not Z.Safe(targetName) then targetName=nil end
    local p,group=profileFor(spellID)
    if not p then return end
    local t=GetTime()
    for k,entry in pairs(manual) do if t-entry.at>2 then manual[k]=nil end end
    local recipients,added,unknown={},{},false
    local function add(unit)
        local guid=recipient(unit)
        if not guid or added[guid] then return end
        added[guid]=true
        local before,beforeSpellID=Z.CaptureBuffTime(unit,p)
        recipients[#recipients+1]={guid=guid,unit=unit,before=before,beforeSpellID=beforeSpellID}
    end
    if type(targetName)=="string" and targetName~="" then
        local unit=unitNamed(targetName)
        if unit then add(unit)
        elseif targetName~=Z.FullName("player") and targetName~=UnitName("player")
            and not Z.RecipientFilter then
            unknown=true -- Another player we cannot read: a cast, but unmeasured.
        end
    end
    if group then
        local tokens,n=groupTokens()
        for i=1,n do add(tokens[i]) end
    end
    if #recipients==0 and not unknown then return end
    manual[castGUID or ("spell:"..spellID)]={profile=p,spellID=spellID,recipients=recipients,at=t}
end
-- UNIT_SPELLCAST_SUCCEEDED for a player cast that ZEUS did not prepare.
function Z.ConfirmManualCast(castGUID,spellID)
    if not Z.Safe(castGUID) or not Z.Safe(spellID) then return end
    local k=castGUID or ("spell:"..tostring(spellID))
    local entry=manual[k]
    if not entry or entry.spellID~=spellID then return end
    manual[k]=nil
    if GetTime()-entry.at>2 then return end
    recordCast(entry.profile,entry.spellID,entry.recipients,castGUID)
end
local API={apiVersion=3,addonVersion=Z.version,trust="client-reported"}
function API.GetDailyTotals()
    local out={schema=3,trust="client-reported",timezone="UTC",unit="buff-hours",
        metric="total_buff_hours_provided",label="Total buff-hours provided",
        addonVersion=Z.version,days={},unmeasuredCasts={},totalBuffHours=0}
    if not Z.db then return out end
    out.characterGUID=UnitGUID("player") out.characterName=Z.FullName("player")
    out.realm=GetRealmName and GetRealmName() out.generatedAt=timestamp()
    for day,seconds in pairs(Z.db.buffReports.seconds) do
        out.days[day]=seconds/3600
        out.totalBuffHours=out.totalBuffHours+seconds/3600
    end
    for day,n in pairs(Z.db.buffReports.unmeasured) do out.unmeasuredCasts[day]=n end
    return out
end
function API.GetLegacyCastTotals()
    local out={schema=1,unit="casts",trust="client-reported",days={}}
    local old=Z.db and Z.db.castReports
    if type(old)=="table" and old.schema==1 and type(old.days)=="table" then
        for day,n in pairs(old.days) do
            if finite(day) and day==math.floor(day) and finite(n) and n==math.floor(n) then out.days[day]=n end
        end
    end
    return out
end
Z.ReportingAPI=API
_G.ZEUSReportingAPI=API

function Z.PrintBuffReport()
    local report=API.GetDailyTotals()
    local today=math.floor((report.generatedAt or 0)/86400)
    Z.Print(string.format("Total buff-hours provided: %.2f | Today (UTC): %.2f",
        report.totalBuffHours,report.days[today] or 0))
    local unmeasured=0
    for _,n in pairs(report.unmeasuredCasts) do unmeasured=unmeasured+n end
    if unmeasured>0 then Z.Print(string.format("%d successful casts could not be measured.",unmeasured)) end
end
