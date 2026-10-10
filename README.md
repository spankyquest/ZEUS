# ZEUS

**Zero Effort Utility Spamming · by SpankyQuest · MIT**

**Power your allies. Crush your enemies.**

One-button buffing for World of Warcraft: Forever. Press your Buff Key (or scroll
the mouse wheel, or spam the macro) and ZEUS finds the next player nearby who's
missing your buff, targets them and casts it. It's as close to auto-buffing as the
game allows: every buff still takes a press, and ZEUS handles the targeting, the
ranks and who already has what.

<img width="795" height="759" alt="Screenshot 2026-10-09 130744" src="https://github.com/user-attachments/assets/fc4c232e-74b1-402b-af30-750b541dccfd" />

## Pick your edition

| Edition | Who it buffs | Read more |
| --- | --- | --- |
| ZEUS | Every friendly player around you | [README](editions/general/README.md) |
| ZEUS Olympus | Only members of Olympus guilds (no Olympus addon needed) | [README](editions/olympus/README.md) |

Install just one. If both are turned on, ZEUS Olympus runs and the other sits out.

## Download

Grab the ZIP for your edition from the [Releases](https://github.com/spankyquest/ZEUS/releases) page (or get it from
CurseForge) and unzip it into `Interface/AddOns`. The green **Code → Download ZIP**
button gives you the source code instead, which the game can't load.

## The source

| Path | What's in it |
| --- | --- |
| `src/` | Code and libraries both editions share |
| `editions/general/` | ZEUS's TOC, edition settings and docs |
| `editions/olympus/` | ZEUS Olympus's TOC, edition settings, docs, guild check and integration files |
| `src/Locales/` | Translations. English lives in `src/Locales.lua`; any line a language leaves out stays English |
| `build.py` | Builds the installable ZIPs into `dist/` (`python3 build.py`, nothing else needed) |

What changed in each version: [src/CHANGELOG.md](src/CHANGELOG.md).

## License

MIT, © 2026 SpankyQuest; see [LICENSE](LICENSE). Bundled libraries keep their own
licenses (each edition's THIRD_PARTY.md), and the Olympus guild check keeps its
original MIT notice in [editions/olympus/OLYMPUS-LICENSE.txt](editions/olympus/OLYMPUS-LICENSE.txt).
