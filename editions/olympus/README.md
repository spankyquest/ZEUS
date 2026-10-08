# ZEUS — Zero Effort Utility Spamming

**By SpankyQuest · 0.4.9 Beta · World of Warcraft: Forever · Interface 16001**

**Power your allies. Crush your enemies.** ZEUS turns your class buffs into
an advantage for the players you pass across Azeroth. Gear up
your side between fights. Send them back into battle stronger.

Choose your buffs, enable friendly nameplates, and press your Buff Key or action-bar
macro repeatedly. ZEUS queues nearby eligible players and prepares the next action
outside combat. Every selection and cast requires your input; it never casts on its own.
ZEUS follows your chosen class priorities when choosing who to buff next.

This edition buffs members of eligible Olympus guilds. It works without the
Olympus addon, using a bundled policy snapshot. Live approvals and moderation
require the optional host adapter; see [INTEGRATION.md](INTEGRATION.md).

## Features

- Choose a Buff Key or drag the Buff macro from settings to your action bar. While choosing,
  press a key, or click any mouse button or scroll anywhere on screen to bind it.
- Bind Mouse Wheel Up or Down to buff as you scroll. While ZEUS is enabled, reverse scrolling is blocked to prevent camera zoom. Turning ZEUS off restores your normal wheel bindings.
- Select learned spells and customize class priority with draggable tiles.
- Set the refresh threshold from 0% to 99%; upgrade known lower-rank buffs sooner.
- Attempt all selected eligible buffs for a recipient before moving on.
- Keep PvP protection enabled to skip flagged players while you are unflagged.
- Track the buff-hours you give with `/zeus report`, counting only the time each buff adds, whether ZEUS or your own spell button cast it.

## Install

1. Use one active edition. If both updated editions are enabled, Olympus runs and
   General stays inactive; a dialog asks you to disable or uninstall one.
2. Replace the entire ZEUS_Olympus folder in your Forever installation's `Interface/AddOns`.
3. Confirm the path is `Interface/AddOns/ZEUS_Olympus/ZEUS_Olympus.toc`.
4. Restart the client or use `/reload` when updating an already installed copy.
5. Type `/zeus`, select your buffs, and bind a key or drag Buff to your action bar.

## Controls

| Control | Action |
| --- | --- |
| `/zeus` or minimap left-click | Open settings |
| `/zeus toggle` or minimap right-click | Enable or disable ZEUS |
| `/zeus report` | Total buff-hours provided and today's UTC total |
| `/zeus debug` | Input and casting diagnostics |
| Minimap drag | Reposition the button |
| Unlock beside a spell | Edit its class tiles |
| Drag a class tile | Change its priority; leftmost is first |
| Right-click an unlocked tile | Enable or disable that target class |
| Reset beside Buff Key | Clear ZEUS's key override |

Friendly nameplates are required for the world queue. Shift+V controls their
visibility independently. ZEUS only hides nameplates it enabled. Using Buff while
ZEUS is disabled starts a temporary run; keep pressing until the queue empties,
then it switches off. If ZEUS is enabled but nameplates are hidden, Buff prints a
reminder to use Shift+V. Combat restrictions can defer key-binding restoration.

## Buff-hour reports

`/zeus report` shows the hours of buffs you've given. Only the time a cast adds
counts: refreshing a 30-minute buff at 99% remaining adds **0.005 buff-hours**
(18 seconds); at 10% remaining it adds **0.45** (27 minutes).
Buffs you cast yourself on Olympus guild members count too, including group
buffs such as Arcane Brilliance (each eligible member who receives it). Buffs on yourself don't count.
ZEUS credits only duration confirmed by the updated aura. Unmeasured
successful casts are shown separately. This measures time added at application,
not uptime retained after death or dispels. Reports are client-reported.
Old raw cast counts are archived separately. See [REPORTING.md](REPORTING.md).

## Compatibility and support

Targets Forever interface 16001. Do not assume compatibility with Retail, Classic
Era, or other flavors. ZEUS is in beta: casting, aura timing, and interface
behavior are still being verified in game on the release client.

For bug reports, include the ZEUS version and variant, game build, class, selected
buffs, reproduction steps, `/zeus debug` output, and any Lua error. Never include
your complete saved variables unless you have checked them for private data.

## License and credits

ZEUS code and project artwork: MIT, copyright 2026 SpankyQuest. Bundled libraries
retain their original terms and author notices; see [THIRD_PARTY.md](THIRD_PARTY.md).
The guild classifier includes MIT-licensed Olympus code; its original copyright
notice is retained in OLYMPUS-LICENSE.txt.

## Both editions installed

Update both editions to 0.4.3 or newer for supported coexistence. The Olympus
edition wins regardless of which files load first. General creates no active
casting buttons or bindings. Dismiss the dialog with OK, then disable or uninstall
one edition and reload. Dismissing it does not switch the active edition. A
disabled addon does not count as an active conflict.

## Upgrading from the old directory

The old Olympus build was installed in ZEUS. Remove that old addon folder before
installing this release into ZEUS_Olympus, unless replacing it with the updated
General release. Do not keep an older General/old-directory build active alongside
this release; those versions do not implement arbitration.

Olympus now saves per-character settings to ZEUSOlympusDB. When a legacy ZEUSDB
is already loaded and no Olympus save exists, settings/history are copied once.
Existing Olympus saves always win, and General's saved table is never modified.

For an Olympus-only upgrade that must retain the old save: exit the game and back
up the character's WTF/Account/.../<realm>/<character>/SavedVariables folder. Copy
ZEUS.lua to ZEUS_Olympus.lua, then change its top-level assignment from ZEUSDB =
to ZEUSOlympusDB =. Do not overwrite an existing ZEUS_Olympus.lua. This rename is
needed because the client will not load an uninstalled addon's saved file.

Wheel bindings also support modifiers. ZEUS blocks the opposite direction both without modifiers and with the matching modifier combination. Changing to a keyboard binding or clearing the Buff Key removes the wheel block. Binding changes and toggles require leaving combat.
