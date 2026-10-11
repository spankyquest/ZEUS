local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
Z.profiles = {}
-- Target level floors follow ZEUS's level-based rank rules. Rank 1 always
-- works at level 1. Live aura duration supersedes these fallback durations.
local function profile(key, class, label, duration, ranks, priority, extra)
    local p = extra or {}
    p.key, p.class, p.label, p.duration, p.ranks = key, class, label, duration, ranks
    p.priority, p.ids, p.names, p.defaultOrder = {}, {}, {}, {}
    for i, tier in ipairs(priority) do
        for token in tier:gmatch("%S+") do
            p.priority[token] = i
            p.defaultOrder[#p.defaultOrder+1]=token
        end
    end
    for _, r in ipairs(ranks) do p.ids[r[1]] = true end
    for _, id in ipairs(p.cover or {}) do p.ids[id] = true end
    Z.profiles[#Z.profiles + 1] = p
    return p
end
profile("intellect", "MAGE", "Arcane Intellect", 3600,
    {{10157,46},{10156,32},{1461,18},{1460,3},{1459,1}},
    {"PRIEST","WARLOCK","DRUID","SHAMAN","PALADIN","HUNTER"},
    {cover={23028,27127}, mana=true})
profile("fortitude", "PRIEST", "Power Word: Fortitude", 3600,
    {{10938,50},{10937,38},{2791,26},{1245,14},{1244,2},{1243,1}},
    {"WARRIOR","WARLOCK","DRUID","PALADIN","SHAMAN","ROGUE","HUNTER","MAGE"},
    {cover={21562,21564}})
profile("mark", "DRUID", "Mark of the Wild", 3600,
    {{9885,50},{9884,40},{8907,30},{5234,20},{6756,10},{5232,1},{1126,1}},
    {"SHAMAN","PALADIN","HUNTER","WARRIOR","ROGUE","WARLOCK","PRIEST","MAGE"},
    {cover={21849,21850}})
profile("might", "PALADIN", "Blessing of Might", 3600,
    {{25291,50},{19838,42},{19837,32},{19836,22},{19835,12},{19834,2},{19740,1}},
    {"WARRIOR","ROGUE","DRUID SHAMAN PALADIN"},
    {blessing=true, cover={25782,25916}})
profile("wisdom", "PALADIN", "Blessing of Wisdom", 3600,
    {{25290,50},{19854,44},{19853,34},{19852,24},{19850,14},{19742,1}},
    {"PRIEST","MAGE","DRUID","SHAMAN","PALADIN","HUNTER","WARLOCK"},
    {blessing=true, mana=true, cover={25894,25918}})
profile("kings", "PALADIN", "Blessing of Kings", 3600, {{20217,1}},
    {"DRUID","SHAMAN","PALADIN","HUNTER","WARRIOR ROGUE","WARLOCK PRIEST MAGE"},
    {blessing=true, cover={25898}})
profile("breath", "WARLOCK", "Unending Breath", 600, {{5697,1}},
    {"WARRIOR ROGUE HUNTER MAGE PRIEST PALADIN","SHAMAN","DRUID"},
    {cover={131}})
profile("detect", "WARLOCK", "Detect Invisibility", 600,
    {{11743,1},{2970,1},{132,1}},
    {"WARRIOR ROGUE HUNTER MAGE PRIEST PALADIN SHAMAN DRUID"},
    {labelSpell=2970})
profile("waterbreathing", "SHAMAN", "Water Breathing", 600, {{131,1}},
    {"WARRIOR ROGUE HUNTER MAGE PRIEST PALADIN","DRUID","WARLOCK"},
    {cover={5697}, reagent=17057})
profile("waterwalking", "SHAMAN", "Water Walking", 600, {{546,1}},
    {"WARRIOR ROGUE HUNTER MAGE PRIEST PALADIN WARLOCK","DRUID"},
    {defaultOff=true, reagent=17058, breaksOnDamage=true}) -- Any damage cancels it.
-- Each paladin gives a player one blessing (their next one replaces it), while blessings from
-- different paladins stack. These are the choices for each class, best first; Queue.lua skips
-- one another paladin already gave. ZEUS can't tell a hybrid's spec, so hybrids start at Kings.
Z.blessings = {
    WARRIOR={"might","kings"}, ROGUE={"might","kings"},
    PRIEST={"wisdom","kings"}, MAGE={"wisdom","kings"},
    WARLOCK={"wisdom","kings"}, HUNTER={"kings","wisdom"},
    DRUID={"kings","wisdom","might"}, SHAMAN={"kings","wisdom","might"},
    PALADIN={"kings","wisdom","might"},
}

profile("spirit", "PRIEST", "Divine Spirit", 3600,
    {{27841,50},{14819,40},{14818,30},{14752,1}},
    {"DRUID","MAGE","SHAMAN","PALADIN","WARLOCK","HUNTER"},
    {cover={27681}, mana=true})
profile("shadow", "PRIEST", "Shadow Protection", 600,
    {{10958,46},{10957,32},{976,1}},
    {"WARRIOR PALADIN DRUID SHAMAN ROGUE HUNTER WARLOCK MAGE"},
    {cover={27683}, defaultOff=true})
profile("thorns", "DRUID", "Thorns", 600,
    {{9910,50},{9756,40},{8914,30},{1075,20},{782,10},{467,1}},
    {"WARRIOR","PALADIN SHAMAN","ROGUE","HUNTER","WARLOCK PRIEST MAGE"},
    {defaultOff=true})
