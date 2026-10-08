-- Edition identity: the only Lua that differs between the General and Olympus
-- builds besides Olympus-only modules. build.py fills in the version from VERSION.
local _, Z = ...
Z = Z.ZEUSModule or Z
Z.edition = "olympus"
Z.version = "@VERSION@-olympus"
Z.folder = "ZEUS_Olympus"
Z.savedVariables = "ZEUSOlympusDB"
-- A new Olympus save is seeded once from a loaded General save; never shared.
Z.legacySavedVariables = "ZEUSDB"
Z.tagline = "Buff nearby Olympus guildmates across Azeroth."
