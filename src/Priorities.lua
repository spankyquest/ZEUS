local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
Z.targetClasses={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local valid={}
for _,class in ipairs(Z.targetClasses) do valid[class]=true end
local function defaults(p)
    local order,seen={},{}
    for _,class in ipairs(p.defaultOrder) do order[#order+1]=class seen[class]=true end
    for _,class in ipairs(Z.targetClasses) do
        if not seen[class] then order[#order+1]=class end
    end
    local enabled={}
    for _,class in ipairs(order) do enabled[class]=p.priority[class]~=nil end
    return {order=order,enabled=enabled}
end
function Z.ClassPriority(db,p,class)
    local custom=db.priorities and db.priorities[p.key]
    if not custom then
        if not p.priority[class] then return nil end
        for i,token in ipairs(p.defaultOrder) do if token==class then return i end end
        return nil
    end
    if not custom.enabled[class] then return nil end
    for i,token in ipairs(custom.order) do if token==class then return i end end
end
function Z.PriorityLayout(db,p)
    local original=(db.priorities or {})[p.key] or defaults(p)
    local copy={order={},enabled={}}
    for i,class in ipairs(original.order) do copy.order[i]=class copy.enabled[class]=original.enabled[class] end
    return copy
end
function Z.NormalizePriorities(db)
    db.priorities=type(db.priorities)=="table" and db.priorities or {}
    for _,p in ipairs(Z.profiles) do
        local custom=db.priorities[p.key]
        if custom~=nil then
            if type(custom)~="table" or type(custom.order)~="table" or type(custom.enabled)~="table" then
                db.priorities[p.key]=nil
            else
                local base=defaults(p)
                local clean={order={},enabled={}}
                local seen={}
                for _,class in ipairs(custom.order) do
                    if valid[class] and not seen[class] then
                        seen[class]=true clean.order[#clean.order+1]=class
                    end
                end
                for _,class in ipairs(base.order) do
                    if not seen[class] then clean.order[#clean.order+1]=class end
                    local value=custom.enabled[class]
                    clean.enabled[class]=type(value)=="boolean" and value or (value==nil and base.enabled[class] or false)
                end
                db.priorities[p.key]=clean
            end
        end
    end
    -- Before 0.5.2 paladins got no blessing, so a blessing row saved back then has them
    -- switched off without the player ever choosing that. Switch them on once; skipping them
    -- again later is kept like any other choice.
    if (tonumber(db.priorityVersion) or 1) < 2 then
        for _,p in ipairs(Z.profiles) do
            local custom=db.priorities[p.key]
            if p.blessing and custom and p.priority.PALADIN then custom.enabled.PALADIN=true end
        end
    end
    db.priorityVersion=2
end
function Z.MoveClass(db,p,class,index)
    local custom=Z.PriorityLayout(db,p)
    local from
    for i,token in ipairs(custom.order) do if token==class then from=i break end end
    if not from then return end
    index=math.max(1,math.min(#custom.order,math.floor(index)))
    if index==from then return end
    table.remove(custom.order,from)
    table.insert(custom.order,index,class)
    db.priorities[p.key]=custom
end
function Z.ToggleClass(db,p,class)
    if not valid[class] then return end
    local custom=Z.PriorityLayout(db,p)
    custom.enabled[class]=not custom.enabled[class]
    db.priorities[p.key]=custom
end
function Z.ResetPriority(db,p) db.priorities[p.key]=nil end
-- Ranks (picked under a buff's class tiles while editing, with Advanced's "Enable lower rank
-- buffs" ticked): the strongest rank ZEUS casts of that buff, players too low for it getting
-- the strongest they can take. With none picked, or the box unticked, it is the strongest
-- learned (a pick is kept for when the box is ticked again). A pick keeps the strongest rank learned when it was made (top), so
-- once the trainer teaches a stronger one ZEUS goes back to the strongest (UpdateRankChoices).
local function byKey(key)
    for _,p in ipairs(Z.profiles) do if p.key==key then return p end end
end
local function strongest(p) return p.learned and p.learned[1] end
-- The index in p.ranks (1 = strongest) of the rank ZEUS casts at most, nil with none learned.
function Z.RankChoice(db,p)
    local pick=type(db)=="table" and db.lowerRanks==true and type(db.ranks)=="table" and db.ranks[p.key]
    local index=type(pick)=="table" and Z.SpellRankIndex(p,pick.spell)
    if index then return index end
    local top=strongest(p)
    return top and Z.SpellRankIndex(p,top[1]) or nil
end
-- Picks a learned rank; the strongest learned clears the pick.
function Z.SetRank(db,p,id)
    db.ranks=type(db.ranks)=="table" and db.ranks or {}
    local top,learned=strongest(p),false
    for _,r in ipairs(p.learned or {}) do if r[1]==id then learned=true end end
    if not learned or not top or id==top[1] then db.ranks[p.key]=nil return end
    db.ranks[p.key]={spell=id,top=top[1]}
end
function Z.NormalizeRanks(db)
    db.ranks=type(db.ranks)=="table" and db.ranks or {}
    for key,pick in pairs(db.ranks) do
        local p=byKey(key)
        if not p or type(pick)~="table" or not Z.SpellRankIndex(p,pick.spell) or not Z.SpellRankIndex(p,pick.top) then
            db.ranks[key]=nil
        end
    end
end
-- After the spellbook changes: a rank stronger than the strongest learned when a pick was made
-- means the trainer taught a new one, and ZEUS casts the strongest again.
function Z.UpdateRankChoices(db)
    if type(db.ranks)~="table" then return end
    for key,pick in pairs(db.ranks) do
        local p=byKey(key)
        local top=p and strongest(p)
        local now=top and Z.SpellRankIndex(p,top[1])
        local before=now and type(pick)=="table" and Z.SpellRankIndex(p,pick.top)
        if before and now<before then db.ranks[key]=nil end
    end
end
