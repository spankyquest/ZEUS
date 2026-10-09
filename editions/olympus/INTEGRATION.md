# ZEUS Olympus and Olympus Guild

ZEUS Olympus is a separate addon that works with or without Olympus Guild. This
page is for Olympus's developers: how ZEUS Olympus behaves next to Olympus, and the
ways to connect the two, from no code at all to embedding.

## How ZEUS Olympus keeps to Olympus's rules

- **Gamepad UI.** ZEUS follows Olympus's gamepad gate (Olympus/Gamepad.lua): the
  same test (`C_InputInterfaceStyle.GetCurrentStyle()` against
  `Enum.InputDeviceInterfaceType.Gamepad`), the same rule, and the same registry
  shape. With the gamepad UI on, ZEUS pauses. It sets no key overrides, arms no
  buttons, edits no macros, opens no game popup or settings, writes nothing on
  `UISpecialFrames`, and registers no `/zeus` at a gamepad login. Its key
  overrides go back to the game in the `INPUT_DEVICE_INTERFACE_TRANSITION` event
  itself. Switching back to mouse and keyboard restores everything. Every reach
  into the game's UI is listed in `GamepadRegistry.lua` with pins to Forever's UI
  source, tagged `-- gp:<id>` at each site, and audited.
- **Forever's client.** Every global, `C_` function, event and template ZEUS uses
  was checked against Forever's UI source (1.60.1, build 70291). Older functions
  are read only behind a check for the modern `C_` one.
- **Read-only.** ZEUS sends no addon messages, joins no channels, and never reads
  or writes Olympus's saved data or `ns`, except through the adapter Olympus
  chooses to load.
- **Same guild rule.** The bundled snapshot in `OlympusPolicy.lua` is Olympus's
  name rule with its King's guilds, built-in approvals (OLYMPIAN, OLYMPIANS) and
  removal (Olympus Defense Force on the King's realm group). It was checked
  unchanged against Olympus commit 783e758 and gives the answers Olympus's own
  tests expect for its 250 misspellings and 400 look-alike names.
- **Two copies.** If ZEUS Olympus is installed twice (for example, standalone and
  embedded), only the first copy runs, and the player is told once in chat.

## Connecting the two

### 1. A CurseForge relation (no code)

On the Olympus project, add ZEUS Olympus under Related Projects:

- **Optional Dependency** (recommended): players see ZEUS Olympus as a companion
  and install it if they want it.
- **Required Dependency**: the CurseForge app installs it with Olympus.

ZEUS Olympus then uses its bundled snapshot. That snapshot cannot know signed
approvals or network removals made after its release; options 2 and 3 give it
Olympus's live answer.

### 2. Olympus answers through its bridge (recommended, a few lines)

Olympus already offers a read-only `OlympusBridge` to companion addons. If it adds:

```lua
-- In Olympus/Bridge.lua (it uses that file's `ns`).
function OlympusBridge.IsOlympusGuild(guild)
	if type(guild) ~= "string" or guild == "" or not ns.rdb then return false end
	local D = ns.Data
	if type(ns.IsFederation) ~= "function" or type(D) ~= "table" or type(D.NetOff) ~= "function" then return false end
	local ok, yes = pcall(function() return ns.IsFederation(guild) == true and not D.NetOff(guild) end)
	return ok and yes == true
end
```

then ZEUS Olympus uses it automatically whenever Olympus is loaded, with no other
change and nothing to keep in step. That includes live signed approvals and
moderator removals. ZEUS checks the unit's faction against the player's before
asking. A `false`, a non-boolean, or an error denies eligibility and never falls
back to the snapshot. Exports then report `policy = "olympus-bridge"`.

### 3. The adapter file (works with Olympus as it is today)

Add `ZEUS_Olympus` to Olympus's `## OptionalDeps`, copy
`integration/OlympusAdapter.lua` into Olympus, and load it after Olympus's
modules. It installs the same live answer through
`ZEUSOlympusAPI.SetGuildEligibilityProvider`, using `ns.IsFederation`,
`ns.Data.NetOff`, `ns.rdb` and `ns.faction` (checked against Olympus commit
783e758). An installed provider takes priority over the bridge. Passing `nil`
removes it.

```lua
api.SetGuildEligibilityProvider(function(unit, guild, faction)
    return true -- only when the host policy accepts this guild
end, "host-policy-revision")
```

### 4. Embedding (not recommended)

1. Copy this addon folder beneath Olympus (for example `Olympus/ZEUS_Olympus`).
2. Add `ZEUSOlympusDB` to Olympus's `SavedVariablesPerCharacter`.
3. Add `ZEUS_Olympus/integration/Embedded.xml` after Olympus's modules in its TOC.

`EmbeddedNamespace.lua` keeps ZEUS under `ns.ZEUSModule`, so Olympus's own `ns`
fields are untouched. If a standalone copy is installed as well, only one runs. Embedded
code becomes Olympus's to audit: Olympus's `scripts/gamepad-audit.lua` would need
ZEUS's registry entries in `Olympus/GamepadRegistry.lua`, and each ZEUS release
would have to be copied in again. The CurseForge relation plus option 2 avoids
both.

## Buff-hours

`ZEUSOlympusAPI.GetDailyTotals()` returns this character's buff-hours by UTC day.
Only buffs on guild-eligible players count, whether ZEUS cast them or the player
did. See REPORTING.md. The API reads local totals only; ZEUS sends nothing, so
showing other members' totals would mean Olympus carrying the number in its own
messages. The totals are client-reported and editable by the player.

## In-game checks

Test the key and the macro against eligible, non-Olympus, removed, unguilded and
newly visible players, and change guild eligibility between a scan and a click.
With the bridge or adapter, check that signed approvals and moderator removals
start and stop eligibility. Switch between mouse and keyboard and the gamepad UI,
including in combat, and confirm the Buff Key returns to the game and comes back.

Olympus-derived classification code is MIT licensed; see OLYMPUS-LICENSE.txt.
