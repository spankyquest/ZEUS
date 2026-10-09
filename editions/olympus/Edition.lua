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
-- The line under the slogan in settings, in the game's language (enUS for any other).
Z.tagline = {
    enUS = "Press your key and ZEUS picks the next Olympus guildmate who needs a buff.",
    deDE = "Drück deine Taste und ZEUS sucht das nächste Olympus-Gildenmitglied aus, das einen Buff braucht.",
    esES = "Pulsa tu tecla y ZEUS elige al siguiente miembro de Olympus que necesite un buff.",
    esMX = "Pulsa tu tecla y ZEUS elige al siguiente miembro de Olympus que necesite un buff.",
    frFR = "Appuie sur ta touche et ZEUS choisit le prochain membre d'Olympus qui a besoin d'un buff.",
    ptBR = "Aperte sua tecla e o ZEUS escolhe o próximo membro do Olympus que precisa de buff.",
}
