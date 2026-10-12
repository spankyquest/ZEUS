local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
Z.profiles = {}
-- Target level floors follow ZEUS's level-based rank rules. Rank 1 always
-- works at level 1. Live aura duration supersedes these fallback durations.
-- Each rank, strongest first: {spell ID, lowest target level, level a class trainer teaches it
-- from}. The trainer levels are Classic's, but Blessing of Kings (20) and Divine Spirit (30) are
-- trained in WoW Forever instead of talents. The settings window shows them for ranks and buffs
-- not learned yet, asking the game first (C_Spell.GetSpellLevelLearned) and using these if it
-- can't say. `tiers`: ranks that are spells of their own, named in the rank list.
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
    {{10157,46,56},{10156,32,42},{1461,18,28},{1460,3,14},{1459,1,1}},
    {"PRIEST","WARLOCK","DRUID","SHAMAN","PALADIN","HUNTER"},
    {cover={23028,27127}, mana=true})
profile("fortitude", "PRIEST", "Power Word: Fortitude", 3600,
    {{10938,50,60},{10937,38,48},{2791,26,36},{1245,14,24},{1244,2,12},{1243,1,1}},
    {"WARRIOR","WARLOCK","DRUID","PALADIN","SHAMAN","ROGUE","HUNTER","MAGE"},
    {cover={21562,21564}})
profile("mark", "DRUID", "Mark of the Wild", 3600,
    {{9885,50,60},{9884,40,50},{8907,30,40},{5234,20,30},{6756,10,20},{5232,1,10},{1126,1,1}},
    {"SHAMAN","PALADIN","HUNTER","WARRIOR","ROGUE","WARLOCK","PRIEST","MAGE"},
    {cover={21849,21850}})
profile("might", "PALADIN", "Blessing of Might", 3600,
    {{25291,50,60},{19838,42,52},{19837,32,42},{19836,22,32},{19835,12,22},{19834,2,12},{19740,1,4}},
    {"WARRIOR","ROGUE","DRUID SHAMAN PALADIN"},
    {blessing=true, cover={25782,25916}})
profile("wisdom", "PALADIN", "Blessing of Wisdom", 3600,
    {{25290,50,60},{19854,44,54},{19853,34,44},{19852,24,34},{19850,14,24},{19742,1,14}},
    {"PRIEST","MAGE","DRUID","SHAMAN","PALADIN","HUNTER","WARLOCK"},
    {blessing=true, mana=true, cover={25894,25918}})
profile("kings", "PALADIN", "Blessing of Kings", 3600, {{20217,1,20}},
    {"DRUID","SHAMAN","PALADIN","HUNTER","WARRIOR ROGUE","WARLOCK PRIEST MAGE"},
    {blessing=true, cover={25898}})
profile("breath", "WARLOCK", "Unending Breath", 600, {{5697,1,16}},
    {"WARRIOR ROGUE HUNTER MAGE PRIEST PALADIN","SHAMAN","DRUID"},
    {cover={131}})
profile("detect", "WARLOCK", "Detect Invisibility", 600,
    {{11743,1,50},{2970,1,38},{132,1,26}},
    {"WARRIOR ROGUE HUNTER MAGE PRIEST PALADIN SHAMAN DRUID"},
    {labelSpell=2970, tiers={[11743]="Detect Greater Invisibility",
        [2970]="Detect Invisibility", [132]="Detect Lesser Invisibility"}})
profile("waterbreathing", "SHAMAN", "Water Breathing", 600, {{131,1,22}},
    {"WARRIOR ROGUE HUNTER MAGE PRIEST PALADIN","DRUID","WARLOCK"},
    {cover={5697}, reagent=17057})
profile("waterwalking", "SHAMAN", "Water Walking", 600, {{546,1,28}},
    {"WARRIOR ROGUE HUNTER MAGE PRIEST PALADIN WARLOCK","DRUID"},
    {reagent=17058, breaksOnDamage=true}) -- Any damage cancels it.
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
    {{27841,50,60},{14819,40,50},{14818,30,40},{14752,1,30}},
    {"DRUID","MAGE","SHAMAN","PALADIN","WARLOCK","HUNTER"},
    {cover={27681}, mana=true})
profile("shadow", "PRIEST", "Shadow Protection", 600,
    {{10958,46,56},{10957,32,42},{976,1,30}},
    {"WARRIOR PALADIN DRUID SHAMAN ROGUE HUNTER WARLOCK MAGE"},
    {cover={27683}})
profile("thorns", "DRUID", "Thorns", 600,
    {{9910,50,54},{9756,40,44},{8914,30,34},{1075,20,24},{782,10,14},{467,1,6}},
    {"WARRIOR","PALADIN SHAMAN","ROGUE","HUNTER","WARLOCK PRIEST MAGE"})
