-- Edition identity: the only Lua that differs between the General and Olympus
-- builds besides Olympus-only modules. build.py fills in the version from VERSION.
local _, Z = ...
Z = Z.ZEUSModule or Z
Z.edition = "general"
Z.version = "@VERSION@"
Z.folder = "ZEUS"
Z.savedVariables = "ZEUSDB"
-- The line under the slogan in settings, in the game's language (enUS for any other).
Z.tagline = {
    enUS = "Press your key and ZEUS picks who needs a buff next.",
    deDE = "Drück deine Taste und ZEUS sucht aus, wer als Nächstes einen Buff braucht.",
    esES = "Pulsa tu tecla y ZEUS elige quién necesita un buff.",
    esMX = "Pulsa tu tecla y ZEUS elige quién necesita un buff.",
    frFR = "Appuie sur ta touche et ZEUS choisit qui a besoin d'un buff.",
    ptBR = "Aperte sua tecla e o ZEUS escolhe quem precisa de buff.",
}
