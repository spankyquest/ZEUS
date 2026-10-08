# ZEUS Olympus edition 0.4.9

## Standalone installation
Install this edition into ZEUS_Olympus, then /reload. Do not install two
copies. Olympus is not required. Existing ZEUS settings and macros are preserved.
The buff key, macro input, minimap, batching, and nameplate ownership behavior
are unchanged. Only members of eligible, same-faction guilds enter the queue.
Unknown/secret guild data is rejected until it becomes readable. No guild-data
fallback from a claimed addon message, player name, or cached roster is used.

## What standalone eligibility means
Olympus source pin: 5825ed41843cd9b303276975a92b752cd48daa69 (supplied ZIP).
Olympus Data.Summary uses IsFederation and not Data.NetOff when listing reports.
Census warning marks describe disputed reports; they do not exclude a guild.
This edition uses the *membership criteria*, not a requirement that the local
client has already received a fresh Census report about the guild.

OlympusPolicy.lua contains the original name classifier, the Alliance approvals
OLYMPIAN and OLYMPIANS, Horde king guild Mudhutters, and the exclusion of Olympus
Defense Force on ClassicBetaPvP and ClassicBetaPvP2. No member list is shipped or
persisted. Unit membership is read from GetGuildInfo and rechecked at cast time.
The classifier is permissive by design, exactly as Olympus's name rule is;
it is not an authoritative registration of guild ownership.

**Standalone is a pinned policy snapshot, not a live Census replica.** It cannot
know new signed approvals, dynamic network removals, or newly learned realm links
without a data source. It does not join Olympus channels, copy its saved database,
or pretend those updates were verified. Update this small module alongside
Olympus releases, or use the provided host adapter for live policy. This is the
explicit tradeoff for avoiding Olympus's census/comms/signature machinery.

## Read daily buff-hour totals

See REPORTING.md for API v3, units, history migration, and measurement limits.
ZEUSReportingAPI and ZEUSOlympusAPI refer to the same API object in this edition.
Call GetDailyTotals().days[UTC_epoch_day] for hours, not cast counts. Update any
v1/v2 consumer's units and version check; do not combine archived counts with hours.

## Use Olympus live policy without embedding
Add ZEUS_Olympus to Olympus's OptionalDeps (preserving its existing dependencies). Copy
integration/OlympusAdapter.lua into Olympus and load it after Olympus's modules.
The adapter supplies ns.IsFederation and ns.Data.NetOff, including live signed
approvals and moderator removals. Provider errors or unknowns deny eligibility;
they never silently revert to bundled rules. Registration requires no reload once
both APIs exist. Its result is checked on scans and every cast attempt.

```lua
api.SetGuildEligibilityProvider(function(unit, guild, faction)
    return true -- only when the host policy accepts this guild
end, "host-policy-revision")
-- Passing nil restores the bundled snapshot.
```

## Embed in Olympus
1. Copy this ZEUS directory beneath Olympus (e.g. Olympus/ZEUS_Olympus).
2. Add ZEUSOlympusDB to Olympus's SavedVariablesPerCharacter.
3. Append ZEUS_Olympus/integration/Embedded.xml after Olympus's modules in its TOC.
4. Disable/remove the separately installed ZEUS to avoid duplicate secure frames,
   slash handlers, macros, and the ZEUS broker. Preserve global frame names so
   existing player macros continue to work.

EmbeddedNamespace keeps module locals under ns.ZEUSModule rather than overwriting
Olympus's ns.Print, ns.db, ns.frame, or other fields. The adapter uses host data
without copying it. Vendored libraries use their existing LibStub version checks.
Olympus can later replace ZEUS UI entry points with its own while keeping this API.

The XML is a merge starting point, **not a completed Olympus release integration**.
Olympus requires all game UI interactions to be registered and gated by its gamepad
system. Its developer must register ZEUS's secure buttons, key overrides, settings,
macros, slash command and minimap launcher, supply park/restore handling, tag their
sites, and add gamepad coverage before shipping the embedded build. Run Olympus's
scripts/check.sh after that work. Those host policy changes are deliberately not
made to the supplied Olympus project here. Standalone ZEUS keeps its existing UI.

## Validation
Embedded.xml loads the same files in the same order as ZEUS_Olympus.toc; keep the
two in step when ZEUS adds modules. In game, test both macro and key against eligible, non-Olympus, removed, unguilded,
and newly visible players. Change guild eligibility between scan and click. Verify
successful and failed casts, reload persistence, and UTC rollover. With the host
adapter, verify signed approval and moderator removal updates stop/start eligibility.
Test embedding in a separate install, including gamepad transitions, before release.

Olympus-derived classification code is MIT licensed; see OLYMPUS-LICENSE.txt.
