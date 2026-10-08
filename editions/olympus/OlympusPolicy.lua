-- Name classifier extracted from Olympus Core.lua, commit
-- 5825ed41843cd9b303276975a92b752cd48daa69. See OLYMPUS-LICENSE.txt.
-- No census, member roster, comms, or Olympus SavedVariables are copied.
local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
local REALM_WORDS = { "olympus", "olympo" } -- as they sound: Olympus, Olympo, Olimpo, Olympos
local OTHER = { "olympy[aceoq]", "olympysch", "polyp" } -- as they sound: Olympia, Olympic...

-- How many slips from a to b (a letter changed, missing or added, or two neighbours
-- swapped), counted up to limit + 1.
local function Slips(a, b, limit)
	local la, lb = #a, #b
	if la - lb > limit or lb - la > limit then return limit + 1 end
	local prev2, prev, row = nil, {}, nil
	for j = 0, lb do prev[j] = j end
	for i = 1, la do
		row = { [0] = i }
		local best = i
		local ca = a:byte(i)
		for j = 1, lb do
			local cost = (ca == b:byte(j)) and 0 or 1
			local v = math.min(prev[j] + 1, row[j - 1] + 1, prev[j - 1] + cost)
			if prev2 and i > 1 and j > 1 and ca == b:byte(j - 1) and a:byte(i - 1) == b:byte(j) then
				v = math.min(v, prev2[j - 2] + 1)
			end
			row[j] = v
			if v < best then best = v end
		end
		if best > limit then return limit + 1 end
		prev2, prev = prev, row
	end
	return prev[lb]
end


-- A word as it sounds: v as u, i as y, z as s, a doubled letter once.
local function Sounds(word)
	word = word:gsub("v", "u"):gsub("i", "y"):gsub("z", "s")
	local out, last = {}, nil
	for c in word:gmatch(".") do
		if c ~= last then out[#out + 1] = c end
		last = c
	end
	return table.concat(out)
end


local function OlympusWord(word)
	for _, other in ipairs(OTHER) do
		if word:find(other) then return false end
	end
	for _, target in ipairs(REALM_WORDS) do
		if word:find(target, 1, true) then return true end
		-- One slip anywhere in the word (Olympo's no shorter than itself: "olymo" is in polymorph).
		for len = target == "olympo" and #target or #target - 1, #target + 1 do
			for i = 1, #word - len + 1 do
				if Slips(word:sub(i, i + len - 1), target, 1) <= 1 then return true end
			end
		end
		-- Two at its start, if it starts with an O.
		if word:sub(1, 1) == "o" then
			for len = #target - 2, #target + 2 do
				if len >= 5 and len <= #word and Slips(word:sub(1, len), target, 2) <= 2 then return true end
			end
		end
	end
	return false
end

-- A guild against Olympus is none of it: "ANTI OLYMPUS", "Against Olympus", "Down with
-- Olympus", "AntiOlympus", "Olympus Haters". The word before (or the one before "with", "to",
-- "the", "of"), glued in front, or the word after.
local AGAINST = { anti = true, against = true, no = true, ["not"] = true, never = true, down = true,
	death = true, kill = true, hate = true, hates = true, haters = true, destroy = true,
	ruin = true, ruins = true, ruined = true, ruining = true, raze = true, burn = true, crush = true,
	doom = true, wreck = true } -- "Ruin Olympus", "Ruins of Olympus", "Burn Olympus" (1.0.1)
local LINKS = { with = true, to = true, the = true, of = true }
local AGAINST_AFTER = { haters = true, hater = true, sucks = true, ruined = true, burns = true, falls = true }
-- ...or after one or two linking words: "Olympus in Ruins", "Olympus in the Ruins" (1.1).
local LINKS_AFTER = { ["in"] = true, of = true, on = true, to = true, the = true }
local RUIN_AFTER = { ruin = true, ruins = true, ruined = true, ashes = true }

local function Against(words, i)
	if words[i]:find("^anti") then return true end -- glued: AntiOlympus
	local before, before2 = words[i - 1], words[i - 2]
	if before and AGAINST[before] then return true end
	if before and LINKS[before] and before2 and AGAINST[before2] then return true end
	local after = words[i + 1]
	if after ~= nil and AGAINST_AFTER[after] then return true end
	for j = i + 1, i + 2 do
		if not (words[j] and LINKS_AFTER[words[j]]) then break end
		local w = words[j + 1]
		if w and (RUIN_AFTER[w] or AGAINST_AFTER[w]) then return true end
	end
	return false
end

local federation, federationSize = {}, 0 -- [name] = true|false, asked often: kept
local function Federation(guild)
	local words = {}
	for word in guild:lower():gsub("0", "o"):gsub("1", "l"):gmatch("%a+") do words[#words + 1] = word end
	for i, word in ipairs(words) do
		if (word:find("olympus", 1, true) or OlympusWord(Sounds(word))) and not Against(words, i) then return true end
	end
	return false
end

-- The name rule alone (cached): what IsFederation says without the King's guild or the signed list.
local function NamedOlympus(guild)
	if type(guild) ~= "string" or guild == "" then return false end
	local known = federation[guild]
	if known == nil then
		known = Federation(guild)
		if federationSize >= 2000 then federation, federationSize = {}, 0 end
		federation[guild], federationSize = known, federationSize + 1
	end
	return known
end


local provider
local revision = "olympus-5825ed4-builtin"
function Z.SetGuildProvider(fn, label)
    if fn ~= nil and type(fn) ~= "function" then return false end
    if label ~= nil and type(label) ~= "string" then return false end
    provider = fn
    revision = fn and (label or "host-policy") or "olympus-5825ed4-builtin"
    return true
end
function Z.GuildPolicyRevision() return revision end
function Z.OlympusGuildAllowed(guild, faction, realm)
    if type(guild) ~= "string" or guild == "" then return false end
    if faction ~= "Alliance" and faction ~= "Horde" then return false end
    local lower = guild:lower()
    if lower == (faction == "Horde" and "mudhutters" or "olympus") then return true end
    if faction == "Alliance" then
        if lower == "olympian" or lower == "olympians" then return true end
        local trimmed = lower:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed == "olympus defense force" then
            -- Unknown realm cannot safely rule out the removed guild.
            if not realm or realm == "" then return false end
            local clean = realm:gsub("[%s%-]", "")
            if clean == "ClassicBetaPvP" or clean == "ClassicBetaPvP2" then return false end
        end
    end
    return NamedOlympus(guild)
end
function Z.OlympusUnitAllowed(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return false end
    local faction = UnitFactionGroup and UnitFactionGroup(unit)
    local mine = UnitFactionGroup and UnitFactionGroup("player")
    if not Z.Safe(faction) or not Z.Safe(mine) or not faction or faction ~= mine then return false end
    local guild = GetGuildInfo and GetGuildInfo(unit)
    if not Z.Safe(guild) or type(guild) ~= "string" or guild == "" then return false end
    if provider then
        -- A host refusal, unknown result, or error NEVER falls back to the snapshot.
        local ok, allowed = pcall(provider, unit, guild, faction)
        return ok and Z.Safe(allowed) and allowed == true
    end
    local realm = GetRealmName and GetRealmName()
    if not Z.Safe(realm) then return false end
    return Z.OlympusGuildAllowed(guild, faction, realm)
end
-- The shared queue calls this for every candidate player.
Z.RecipientFilter = Z.OlympusUnitAllowed
