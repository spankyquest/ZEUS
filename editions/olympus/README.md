# ZEUS Olympus — Zero Effort Utility Spamming

**By SpankyQuest · 0.5.2 · World of Warcraft: Forever**

**Power your allies. Crush your enemies.**

ZEUS Olympus turns buffing your guildmates into one button. Press your Buff Key (or
scroll the mouse wheel, or spam the macro) and it finds the next Olympus guild
member nearby who's missing your buff, targets them and casts it. Keep pressing and
everyone in the city walks away buffed. It's a nice perk for being in an Olympus guild.

It's as close to auto-buffing as the game allows. Blizzard doesn't let addons cast
by themselves, so each buff still takes a press. ZEUS does the rest: the targeting,
picking the right rank, and remembering who already has it.

It knows which guilds belong to Olympus by itself, so you don't need the Olympus
Guild addon installed, but it works alongside it.

## What it does

- **Auto-targeting.** Your target or mouseover comes first, then the Olympus
  members around you, in the class order you set. Arcane Intellect goes to casters
  before hunters, Might goes to warriors and rogues, and so on.
- **Olympus members only.** Players outside Olympus guilds are skipped.
- **The right rank.** Low-level players get a rank they can take, and anyone with
  a weaker rank of your buff gets an upgrade.
- **All your buffs at once.** A player gets everything you've ticked before ZEUS
  moves on.
- **Rebuffs on time.** You pick how low a buff gets before ZEUS tops it up.
- **Doesn't get stuck.** Players behind a wall wait until everyone in sight is done.
  If the game says "A more powerful spell is already active", ZEUS works out which
  buff got in the way and leaves that player alone until it's gone.
- **Stays out of PvP trouble.** Skips PvP-flagged players while you're not flagged.
- **Buff-hours.** `/zeus report` adds up how much buff time you've handed out to
  your guildmates.
- **See who buffed you.** Hover one of your own buffs to see who gave it.
  Left-click it to whisper them a thank-you.
- **Your language.** English, Deutsch, Español, Français and Português (Brasil).

Paladins hand out one blessing per player, picked by class: Might for warriors and
rogues, Wisdom for casters, Kings for hunters, druids, shamans and other paladins.
Blessings from different paladins stack, so if someone already gave that one, ZEUS
gives the next one instead. A blessing you gave yourself, by hand or with ZEUS,
stays put and gets refreshed.

## Getting started

1. Install ZEUS Olympus with the CurseForge app, or unzip it into
   `Interface/AddOns` so you end up with
   `Interface/AddOns/ZEUS_Olympus/ZEUS_Olympus.toc`.
2. In game, type `/zeus`.
3. Click **Choose a key...** and press the key you want, or click a mouse button or
   scroll the wheel. (Or drag the **Buff** icon onto your action bar.)
4. Click **Turn ZEUS on**. It switches on friendly nameplates (the game's Shift+V,
   unless you've changed that key), because that's how it sees the players around you.
5. Head somewhere your guild hangs out and press your key.

**Tip:** bind the mouse wheel and you can buff a whole town just by scrolling.
While ZEUS is on, scrolling the other way won't zoom your camera; turn ZEUS off to
get your zoom back.

**Tip:** the Buff macro works with ZEUS off too. Spam it and ZEUS (and friendly
nameplates) switch on while you're pressing, then off again a few seconds after you
stop. Your Buff Key keeps its normal job the whole time.

## Commands

| Command | What it does |
| --- | --- |
| `/zeus` | Settings (or left-click the minimap button) |
| `/zeus toggle` | Turn ZEUS on or off (or right-click the minimap button) |
| `/zeus report` | Your buff-hours: total, today, and per buff and rank |
| `/zeus blockers` | Buffs ZEUS has learned get in the way of yours; `/zeus blockers clear` forgets them |
| `/zeus auras` | Every buff on your target (or on you), with its spell ID and who cast it |
| `/zeus debug` | Info for bug reports |

## Settings

- **Buffs:** tick the ones you want handed out.
- **Class order:** click **Unlock** next to a buff, then drag the class tiles
  (leftmost goes first) or right-click one to skip that class.
- **Rebuff slider:** how much of a buff should be left before ZEUS refreshes it.
  At 0% it waits until the buff runs out.
- **PvP protection:** on by default.
- **Minimap button:** untick it to hide the button; `/zeus` still opens settings.
- **Track buffs given to me:** the "Given by" line on your buffs and the left-click
  whisper. Untick it to turn both off. The game only says who cast a buff while
  it can see them, so strangers are only named with friendly nameplates on (ZEUS
  turns them on while it's on).

## Buff-hours

`/zeus report` shows how many hours of buffs you've given your guildmates. Only the
time a cast actually adds counts: topping up a 30-minute buff that still has 99%
left adds 18 seconds, not 30 minutes. Buffs you cast yourself count too, and a group
buff counts once for each Olympus member it reaches. Buffs on yourself don't. The
numbers are kept on your computer only. It also breaks them down by buff and by rank. The details are in [REPORTING.md](REPORTING.md).

## Good to know

- ZEUS is made for WoW Forever. It isn't built for Retail or Classic Era.
- It never casts by itself, and it pauses in combat.
- ZEUS starts off each time you log in. Nameplates it switched on go back off;
  nameplates you turned on yourself stay on.
- With the gamepad UI on, ZEUS takes a break and comes back when you switch to
  mouse and keyboard.
- Installed both ZEUS and ZEUS Olympus? Only ZEUS Olympus runs, and a popup reminds
  you to remove one.
- Found a bug? Open an issue with your ZEUS version, your class, what happened, the
  `/zeus debug` output and any Lua error.
- Olympus Guild developers: [INTEGRATION.md](INTEGRATION.md) explains how the two
  addons fit together.

## License

MIT, © 2026 SpankyQuest. The guild check includes MIT-licensed code from Olympus
Guild, with its original notice in OLYMPUS-LICENSE.txt. The bundled libraries keep
their own licenses; see [THIRD_PARTY.md](THIRD_PARTY.md).
