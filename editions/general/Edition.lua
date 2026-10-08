-- Edition identity: the only Lua that differs between the General and Olympus
-- builds besides Olympus-only modules. build.py fills in the version from VERSION.
local _, Z = ...
Z = Z.ZEUSModule or Z
Z.edition = "general"
Z.version = "@VERSION@"
Z.folder = "ZEUS"
Z.savedVariables = "ZEUSDB"
Z.tagline = "Buff players you pass across Azeroth."
