-- Olympus-only extensions to the shared reporting API. Loaded after Reporting.lua.
local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
local API = Z.ReportingAPI
local getDailyTotals = API.GetDailyTotals
-- The export names the policy active now, not proof of each cast's policy.
function API.GetDailyTotals()
    local out = getDailyTotals()
    out.policy = Z.GuildPolicyRevision()
    return out
end
function API.SetGuildEligibilityProvider(fn, revision)
    local ok = Z.SetGuildProvider(fn, revision)
    if ok and Z.db and Z.Refresh and not InCombatLockdown() then Z.Refresh() end
    return ok
end
Z.OlympusAPI = API
_G.ZEUSOlympusAPI = API
