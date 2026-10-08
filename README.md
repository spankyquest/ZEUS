# ZEUS

**Zero Effort Utility Spamming · by SpankyQuest · MIT**

**Power your allies. Crush your enemies.** ZEUS hands out your class buffs to
players you pass across Azeroth in World of Warcraft: Forever.
Strengthen your side between fights. Choose your buffs, enable friendly nameplates,
and press your Buff Key or macro to send nearby players back into battle stronger.

Bind Mouse Wheel Up or Down to buff as you scroll. While ZEUS is enabled, the
opposite direction is blocked to prevent camera zoom. Toggle ZEUS off to restore
your normal wheel controls.

ZEUS prepares nearby eligible recipients in priority order. Every selection and
cast requires player input, outside combat. Reports measure net buff-hours added.

## Editions

| Edition | Who it buffs | Details |
| --- | --- | --- |
| ZEUS | Eligible friendly players regardless of guild | [README](editions/general/README.md) |
| ZEUS Olympus | Members of Olympus guilds; works without the Olympus addon | [README](editions/olympus/README.md) |

Install one edition. ZEUS installs as `Interface/AddOns/ZEUS`; ZEUS Olympus installs
as `Interface/AddOns/ZEUS_Olympus`. If both are enabled, Olympus runs, the other
stays inactive, and a dialog asks you to remove one. The editions save settings
separately.

## Download

Download the ZIP for your edition from this repository's **Releases** page and
extract it into `Interface/AddOns`. The green **Code → Download ZIP** button gives
you the source layout below, which the game cannot load directly.

## Source layout

| Path | Contents |
| --- | --- |
| `src/` | Addon code and libraries shared by both editions |
| `editions/general/` | ZEUS's TOC, edition settings, and documentation |
| `editions/olympus/` | ZEUS Olympus's TOC, edition settings, documentation, guild policy, and integration files |
| `build.py` | Combines `src/` with each edition and writes the installable ZIPs to `dist/` |

To build the ZIPs yourself, run `python3 build.py` (Python 3, no other
dependencies). Release history is in [src/CHANGELOG.md](src/CHANGELOG.md).

## License

ZEUS-owned code and artwork are MIT licensed, copyright 2026 SpankyQuest; see
[LICENSE](LICENSE). Bundled third-party libraries keep their own terms; see each
edition's THIRD_PARTY.md. The Olympus guild classifier keeps its original MIT
notice in [editions/olympus/OLYMPUS-LICENSE.txt](editions/olympus/OLYMPUS-LICENSE.txt).
