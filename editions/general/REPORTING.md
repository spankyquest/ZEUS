# ZEUS: total buff-hours provided

Run `/zeus report` to see the lifetime total and today's UTC total, then each buff
with its ranks (strongest first) and group versions, such as Arcane Brilliance, apart.
Time measured before 0.5.2 isn't split by spell and is shown as one earlier line.
Unmeasured successful casts are shown separately and earn no guessed hours.

## Calculation
Each successful buff you give adds only the new lifetime granted, whether ZEUS
cast it or you cast it yourself:

`added seconds = max(0, new expiration - max(previous expiration, cast-success time))`

Credit is capped at the observed new buff duration, summed as seconds internally,
and divided by 3,600 for reporting. No per-cast rounding is applied. For a 30-minute
buff: missing/expired earns 0.5 hours, 99% remaining earns 0.005, 10% remaining earns
0.45. A higher-rank replacement earns only added time, not an extra strength bonus.
Refreshing a buff with more time left than the new duration adds zero time.

Before casting, ZEUS captures readable aura state. After the matching success, it
requires the matching spell's updated aura on the same GUID. When the aura supplies
a caster, that caster must be the player. It reads immediately, on UNIT_AURA, and
at 0.15/0.5/1 second. Unchanged stale auras wait for an update. Missing/restricted
metadata, another caster's aura, a recycled unit, or no confirmation within that
window yields an unmeasured cast. Starting another cast for that recipient/spell
settles or closes the previous observation so it cannot claim the next cast's time.
No nominal spell-duration fallback is used for reports. Existing buff memory still
uses its own fallback for queue operation; reporting does not change casting rules.

This measures **duration added at application**, not future uptime consumed. Later
death, dispels, logout, overwrites, and time spent offline do not subtract credit.
When caster metadata is absent, matching spell/recipient and the success event are
used; simultaneous casts by others cannot be perfectly attributed by this client.
Reports remain client-reported and editable by the player, not authenticated proof.

## Buffs you cast yourself
Casts ZEUS did not prepare (action bar, macros, click-casting) count when the
spell is one of your class's supported buffs. When the cast is sent, ZEUS finds
the recipient by name among readable units (target, mouseover, focus, party or
raid) and captures their current aura, then measures the cast exactly as above
once it succeeds. Group buffs (Arcane Brilliance, Prayer of Fortitude, Gift of the
Wild, Greater Blessings, Prayer of Spirit, Prayer of Shadow Protection) watch every
party or raid member: each member whose updated aura is confirmed is credited, and
members the buff did not reach are ignored. Such a cast is unmeasured only if no
recipient could be confirmed. Buffs on yourself are not counted. A recipient who
cannot be read, such as a player visible only as a nameplate, yields an unmeasured
cast. A send that is not followed by success within two seconds is discarded.

## API v3

```lua
local api = _G.ZEUSReportingAPI
if api and api.apiVersion == 3 then
    local report = api.GetDailyTotals()
    local today = report.days[math.floor(GetServerTime() / 86400)] or 0
    -- today and report.totalBuffHours are buff-hours, possibly fractional.
end
```

GetDailyTotals returns independent tables containing:
- schema: 3; trust: "client-reported"; timezone: "UTC"; unit: "buff-hours".
- metric: "total_buff_hours_provided"; label: "Total buff-hours provided".
- characterGUID, characterName, realm (when available after login).
- addonVersion and generatedAt (Unix seconds).
- days: numeric UTC epoch-day -> measured buff-hours. Missing days mean zero.
- totalBuffHours: sum of all measured daily totals.
- unmeasuredCasts: UTC epoch-day -> successful casts whose duration wasn't confirmed.
- spells: spell ID -> measured buff-hours, all days together (since 0.5.2). Each rank
  and group version has its own ID. Time measured before 0.5.2 is in `days` and
  totalBuffHours only, so the spells can add up to less than the total.

Day N covers [N*86400, (N+1)*86400). Credit belongs to the success day, including
when the aura is observed after midnight. It is not spread over the buff's future
lifetime. Consumers replace/upsert each (characterGUID, epoch-day) snapshot; never
add repeated snapshots. Small totals may display as 0.00 when rounded in chat;
the API retains their precision. Character identity is also a client assertion.

The same matching/deduplication rules still exclude other units, wrong spells or
cast GUIDs, failures, stale pending attempts, and duplicate success events. Clients
without cast GUIDs consume the matching pending attempt once. Each buff contributes
its duration independently; a multi-buff recipient can provide multiple additions.

## Saved history and upgrades
ZEUSDB.buffReports holds schema 2, daily `seconds` and `unmeasured` maps, and (since 0.5.2)
a `spells` map of seconds per spell ID. No roster or
per-recipient successful-cast history is added. Existing settings/macros are preserved.
There is no backfill. Existing schema-1 ZEUSDB.castReports is left untouched as an
archive; `api.GetLegacyCastTotals()` exports a copy with `unit="casts"`. These counts
are never converted or mixed into buff-hours because remaining durations were not
recorded. API version 3 is intentional: version-1 and version-2 consumers must update their units.
Existing schema-2 saved seconds are unchanged; export schema 3 describes hours, not a new storage format.
From 0.4.9, totals also include buffs cast without ZEUS; earlier days contain ZEUS casts only.

No messages or network reports are automatically sent. Future integrations may read
this API. Reloading during the one-second observation window can lose that pending
measurement; aggregates already recorded are saved normally. Client code, saves,
clock and reports can be modified; do not treat them as verified reward evidence.
