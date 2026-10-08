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
