-- Load from Olympus after its own modules and the embedded ZEUS runtime.
-- For separate installed addons, add ZEUS_Olympus to Olympus's OptionalDeps and load
-- this file after Olympus's modules. No API global from Olympus is needed.
local _, ns = ...
local api = _G.ZEUSOlympusAPI
if not api or api.apiVersion ~= 3 then return end
api.SetGuildEligibilityProvider(function(unit, guild, faction)
    if not ns.rdb or faction ~= ns.faction then return false end
    if type(ns.IsFederation) ~= "function" or not ns.Data or type(ns.Data.NetOff) ~= "function" then return false end
    -- Same membership/removal predicate as Data.Summary; warning marks are
    -- informational. Do not use Borders.MarkOf: special people may get marks
    -- independently of guild membership.
    return ns.IsFederation(guild) == true and not ns.Data.NetOff(guild)
end, "olympus-live")
-- Pull at the host's chosen time; this sends nothing to other players:
-- local snapshot = api.GetDailyTotals()
-- snapshot.days[math.floor(GetServerTime()/86400)] or 0 -- today's UTC buff-hours
