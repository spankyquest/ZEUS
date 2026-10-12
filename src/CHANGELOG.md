# 0.5.4

- **Buff them back.** Hover one of your own buffs and press your Buff Key or the Buff macro: ZEUS buffs whoever gave it, ahead of the queue, if they need one of your buffs and ZEUS could buff them anyway (in range, not skipped). It holds for three seconds after the mouse leaves the buff, time to click the Buff macro on an action bar, and once ZEUS starts on them it gives them all their buffs before going back to the queue. The queue window shows them on top meanwhile.
- **Instant buff-back.** A new box under Advanced (off by default). When another player buffs you, they go first in the queue for a minute, before your target: your next press of the Buff Key or the Buff macro buffs them back, if they need one of your buffs and ZEUS could buff them anyway. A buff read again at login doesn't count, a rebuff does. ZEUS can't change your target by itself, so the press does it (for a player only seen by their nameplate, the first press targets them and the next one buffs).
- **Fast presses finish the player.** Pressing the Buff Key or the Buff macro faster than the global cooldown no longer makes ZEUS skip a player's next buff (Thorns after Mark of the Wild, say) and move on to someone else. A press too early in the cooldown casts nothing; one close enough to its end is queued by the game as usual; and a cast the game still refuses for the cooldown is tried again on the same player.
- **Lower rank buffs.** A new box under Advanced, **Enable lower rank buffs** (off by default). With it ticked, click **Edit** next to a buff with more than one rank and its ranks are listed under the class tiles, weakest first: pick the one ZEUS casts, to save mana, say. Players too low for it still get the strongest rank they can take. Ranks you haven't learned yet are greyed out with the level your class trainer teaches them from, and when you learn a new rank there, ZEUS switches to it. With the box unticked ZEUS casts your strongest rank, as before.
- **Closes in combat.** The settings window closes when a fight starts, and can't be opened until it ends.
- **简体中文.** ZEUS now speaks Simplified Chinese, for WoW Forever's Chinese realms (魔兽世界：无限): the settings window, tooltips, chat lines and the addon list. The ZEUS download also carries a Chinese README.
- **Edit / Lock.** The class order buttons next to each buff are now just **Edit** and **Lock**.
- **Tooltips for the whole window.** Hover the **Buff Key**, **Macros** and **Buff Ordering** headings to see what each part is for. A paladin's note on how blessings are picked moved from under the buffs into the **Blessing Ordering** tooltip, so the paladin window is a little shorter. Every buff's box has a tooltip too (on its name as well), and one you haven't learned yet tells you the level your class trainer teaches it from, or that you can learn it now once you're that level.

# 0.5.3

- **Choose who goes first.** Two new boxes under **Advanced** set the order of the buffing queue. By default the players around you are now lined up by level, lowest first, with the class tiles only breaking ties. Tick **Sort by class** to let the class tiles decide first, as ZEUS did before, and untick **Lower-level players first** to start with the highest levels. Your target still always comes first.
- **Rebuffs at 25%.** A new install, and Restore Defaults, now tops a buff up when a quarter of it is left (it was a fifth). The rebuff slider you already have keeps its setting.
- **Every buff starts ticked.** Water Walking, Shadow Protection and Thorns used to start unticked. Now every buff is ticked on a new install and after Restore Defaults. If you already use ZEUS, your ticks stay as they are.
- **Restore Defaults.** A new button at the top right of the settings window puts every setting back the way it was at install, locks any class order left open and closes Advanced (click it twice to confirm). Your buff-hours are kept, and so is what ZEUS has learned about blocking buffs.
- **Buff Ordering.** The buff rows and their class tiles now sit in one box under a **Buff Ordering** title. The help lines moved into tooltips: hover **Choose a key...** for the key and mouse wheel tips, and **Edit Order** for how to arrange the class tiles. The window is a little shorter for it, and the two macros now have their own **Macros** pane beside the Buff Key.
- **Advanced.** A new button in the top right corner, beside Restore Defaults, opens a drawer beside the settings window with the boxes you set once: the two queue order boxes, **Skip AFK players**, **Skip level 1 players**, **PvP protection** (with its warning under it while it's off), **Minimap button**, **Track buffs given to me**, **Protect buffs from right-click** and **Show queue window**. Click it again, or close the window, to put them away. The window itself keeps your buffs, their class orders and the rebuff slider, so it's shorter and quicker to read.
- **Queue window.** Tick **Show queue window** under Advanced for a see-through window, like the chat window, that lists who ZEUS buffs next, from the top down: each player's class icon, level and name in class colour, in the same font and size as your chat window. Drag it anywhere and drag its corner to resize it: a taller window shows more of the queue. It remembers where you put it.
- **Out of mana.** ZEUS no longer says nobody needs a buff when you're out of mana. The status line says you're out of mana, the queue window keeps listing who's waiting under an "Out of mana" line, and when you have the mana for some buffs but not others, ZEUS buffs the ones you can first and keeps the rest in line.
- **Givers remembered.** The "Given by" line on your buffs now survives a `/reload` and logging out and back in: ZEUS saves the givers it knows when you leave and matches them to the same buffs when you're back, even with nobody in sight. A buff someone gave you again in the meantime isn't matched.
- **Protect buffs from right-click.** A new box under Advanced (off by default). With it on, a right-click on one of your buffs or weapon enchants no longer removes it at once: its tooltip says **Right-click to confirm removal**, and a second right-click within 5 seconds removes it. Wait 5 seconds and the tooltip goes back to normal. The removal itself is still the game's own, so it works in combat too.
- **Edit Order / Lock Order.** The class order buttons next to each buff are now called **Edit Order** and **Lock Order**, with tooltips that explain them. Closing the settings window locks any order you left open, and right-clicking a class while editing updates its tooltip at once (buffed or skipped).
- **Enable / Disable ZEUS.** The main button, the minimap tooltip and messages say enable and disable again, instead of turning ZEUS on and off.

# 0.5.2

- **Smarter blessings.** Paladins now get a blessing too: Kings first, like the other hybrids (a blessing row you saved in an older version gets paladins switched on once). Blessings from different paladins stack, so when another paladin already gave someone the blessing ZEUS would pick, ZEUS gives them the next one on their class's list instead. For a stranger it sees this as soon as it targets them, on the same press. A blessing you already gave someone, with ZEUS or by hand, stays: ZEUS refreshes that one instead of swapping in another. One their class doesn't get from ZEUS (Might on a priest, say) is left alone until it's due for a refresh. And when the blessing ZEUS would pick can't land on someone (they carry something that blocks it), they get the next one instead of none.
- **Water Walking knocked off by a hit.** Any damage cancels Water Walking. If it's gone while that player is in a fight, ZEUS gives it again once the fight ends, instead of waiting as it does for a buff someone clicked off.
- **Skips AFK and level 1 players.** Players flagged AFK are left alone until they're back, and level 1 characters (fresh alts, bank characters) are left alone too. Two new boxes in settings, **Skip AFK players** and **Skip level 1 players** (both on by default), turn each off.
- **Buff-hours per buff and rank.** `/zeus report` now lists each buff under the total, with its ranks (strongest first) and group versions like Arcane Brilliance apart. Time measured before this version wasn't split by spell, so it shows as one "earlier" line. The reporting API gains a matching `spells` table.
- **`/zeus auras`** lists every buff on your target (or on you), with its spell ID, time left and who cast it. Handy for spotting a buff that keeps one of yours from landing.
- **See who buffed you.** Your own buffs' tooltips get a "Given by" line with the player who cast them (first name and surname), in their class colour. When someone rebuffs you or a paladin swaps your blessing for a better one, the line follows the new giver; a buff whose caster the game never showed says "someone out of sight". Left-click one of your buffs to whisper whoever gave it (not while you're typing in chat). Right-click still removes a buff. The game only knows the caster while it can see them (in your group, targeted, or by their nameplate), so ZEUS notes them as the buff lands and remembers them after they walk away. A "Track buffs given to me" box in settings turns all of this off and on.
- **Minimap button on or off.** A new box in the settings window hides the minimap button or brings it back. The choice is saved (where minimap-button addons look for it too), and `/zeus` still opens settings without the button.

# 0.5.1

- **Spam-friendly.** ZEUS acts on up to four presses a second, shared by the Buff Key, the wheel and the macro, so hammering them no longer redoes the work every frame. Buffs share the 1.5-second global cooldown, so you won't buff any slower. A held key still finishes its press when you let go.
- **The Buff macro, with ZEUS off, works as a quick run.** Spamming it turns ZEUS and friendly nameplates on while you press and back off three seconds after you stop, whether or not anyone nearby still needs a buff (in a busy town someone always does, so the old "once everyone's buffed" rule could leave ZEUS on). Your Buff Key isn't taken over during these runs; it only buffs when you turn ZEUS on yourself.
- **Languages.** ZEUS speaks Deutsch, Español, Français and Português (Brasil), the same languages as Olympus Guild, and uses the same scheme: any line a language leaves out stays English. Buff and class names come from the game in your language, and the addon list shows a translated description.
- **Starts off at login.** Each time you log in (a `/reload` doesn't count), ZEUS starts off and turns off the friendly nameplates it switched on. Nameplates you turned on yourself, with your key or the game's options, stay on. A fresh install starts off and leaves your nameplates as they are.
- **Names your nameplate key.** When ZEUS needs friendly nameplates, it tells you the key you've actually bound to the game's "Show Friendly Name Plates" (Shift-V unless you changed it), or where to set one if nothing is bound.
- **Friendlier wording** throughout the settings window, tooltips and chat.
- **Fix:** hiding friendly nameplates during a Buff-macro run now ends the run instead of leaving ZEUS on, and a `/reload` in the middle of one no longer leaves ZEUS on for good.

# 0.5.0

- **Line of sight.** Players behind a wall are set aside (2, 4, 8, then 15 seconds) and come after everyone ZEUS can see, even your target, so it buffs who it can reach instead of bouncing between players it can't. Out of sight also ends that player's turn at once instead of trying their other buffs.
- **"A more powerful spell is already active."** ZEUS no longer tries to cover another caster's stronger rank. When a buff does get refused, ZEUS works out which buff was in the way, leaves that player alone until it wears off, and remembers it for other players. Group buffs like Arcane Brilliance are learned right away. Something like a scroll is learned as a guess once three players within ten minutes all had it, and ZEUS double-checks a guess every five minutes. Untimed auras, ZEUS's own buffs and buffs seen beside a successful cast are never suspects, a hold on one blessing never stops another, and learned buffs are forgotten after a week unseen. `/zeus blockers` shows the list; `/zeus blockers clear` wipes it and frees anyone held.
- **No re-checking the same nameplate.** If ZEUS targets someone from their nameplate and they're already buffed (or carry a blocker), it remembers that and doesn't target them again on the next press.
- 0.5.0 is a Release. The ZIPs are now named `ZEUS-0.5.0.zip` and `ZEUS-0.5.0-olympus.zip`.

# 0.4.9 Beta

- Choosing a Buff Key: the dialog now opens over the "Choose a key..." button, and while it is open a dimmed full-screen layer accepts mouse buttons and the wheel anywhere on screen, so binding a mouse input no longer requires hovering the dialog. Escape, Cancel, the close button, or entering combat removes the layer.
- Performance: frequent world events (aura changes, nameplates, mouseover, group roster, settings) mark the queue stale and rebuild once on the next frame instead of once per event. Input right after such an event still rescans immediately. Other players' spellcast events no longer cause rescans.
- Performance: each scan checks a player once and reads their buffs once, shared by all of your buffs, instead of once per buff.
- Performance: the secure buttons and the Buff macro are rewritten only when the next recipient or spell changes. Idle and disabled refreshes no longer touch them or scan your macros. A macro update blocked by combat is retried after combat.
- Wording: ZEUS now says it buffs players "across Azeroth" instead of "in the overworld and hub cities", in the settings window, the addon list, and the descriptions.
- Buff-hours now also count buffs you cast yourself (action bar, macro, click-casting), measured the same way as ZEUS casts. Group buffs credit each party or raid member who receives them. Buffs on yourself are not counted, and the Olympus edition counts guild-eligible recipients only. Earlier days are unchanged.
- Fix: the README's report example showed minutes as hours. A 30-minute buff refreshed at 99% adds 0.005 buff-hours, not 0.3.
- Gamepad UI: following Olympus Guild's rules, ZEUS pauses while Blizzard's gamepad UI is on. It sets no key overrides, arms no buttons, edits no macros, and opens no game popup or settings window; `/zeus` is not registered at a gamepad login. Its keys go back to the game the moment you switch, and everything resumes when you switch back to mouse and keyboard. Buffs you cast yourself still count toward buff-hours.
- Olympus edition: when Olympus Guild offers `OlympusBridge.IsOlympusGuild`, ZEUS uses Olympus's live answer for guild membership. The bundled rule was rechecked against current Olympus and gives the answers Olympus's own tests expect for 650 guild names.
- If the same edition is installed twice (for example inside another addon), only one copy runs and you are told once. The "Choose a Buff Key" hint now shows once per character instead of at every login.
- The refresh slider uses the game's current slider template; the old one is deprecated in Forever.
- Fix: startup no longer creates a global `_` variable, a potential source of UI taint.
- Maintenance: both editions build from one shared source. Edition differences are limited to Edition.lua, the TOC, documentation, and the Olympus-only OlympusPolicy.lua and OlympusAPI.lua. Core.lua is split into Core, Auras, Queue and Buttons. Player packages no longer include developer test notes. Saved settings, macros, bindings and the reporting API are unchanged.

# 0.4.8 Beta

- Apply the 100 ms input-driven queue-scan limit to populated and empty queues, including post-click callbacks. Target changes and client events remain responsive; each cast still validates its recipient.
- Report total buff-hours provided in chat, GUI labels, and API v3. One hour equals 3,600 accumulated buff-seconds. Existing saved seconds are preserved without rounding or migration.
- API exports use schema 3, unit buff-hours, and totalBuffHours. Integrations must update from v2 minutes. Update the supplied Olympus adapter alongside this version.

# 0.4.7 Beta

- Coalesce rapid key/macro post-click refreshes into one callback per frame.
- Limit input-driven scans of an empty queue to once per 100 ms. Client events still refresh immediately, and ready casts still recheck eligibility on input.
- Back off for two seconds after acquiring a player who cannot be safely buffed, instead of immediately repeating nameplate inspection.

# 0.4.6 Beta

- Replace the friendly marketing copy with a battle-focused description: Power your allies. Crush your enemies.
- Restore the settings tip for binding Mouse Wheel Up or Down.
- While ZEUS is enabled with a wheel binding, consume the opposite wheel direction without casting or changing camera distance. Modifier bindings also block the matching reverse chord and unmodified reverse scroll.
- Restore normal wheel controls when ZEUS is disabled, the Buff Key is cleared, or a keyboard binding is selected. Saved camera bindings are never overwritten. Binding changes and toggles remain unavailable in combat.

# 0.4.5 Beta

- Explain ZEUS's purpose upfront: sharing buffs with players you pass in the overworld and hub cities, using your Buff Key or macro.
- Update both addon-list tooltips, edition READMEs, and publication descriptions.
- Use the native portrait window and dark inset panels used by Olympus Guild, with a circular Zeus portrait, slim title bar, and bottom-row action buttons. No side tabs.
- Restore the original lightning minimap icon; keep the Zeus portrait in settings.

# 0.4.4 Beta

- Avoid restricted nameplate aura queries. Measure buff-minute extensions through readable player aliases; unavailable measurements remain unmeasured.
- Keep the Buff Key active for a nameplate reminder while ZEUS is enabled and friendly nameplates are hidden. Both key and macro explain how to enable nameplates; no cast is attempted. Disabling ZEUS releases its key override.
- Restyle settings with bronze borders, warm dark panels, alternating buff rows, and the Zeus portrait. Add Enable/Disable and Report buttons.
- Preserve Olympus-only runtime behavior when both editions are installed.

# 0.4.3 Beta

- Olympus installs into ZEUS_Olympus with a matching TOC and distinct saved variables.
- When both updated editions are enabled, Olympus is the sole active runtime.
- A once-per-login dialog asks the player to disable or uninstall one edition.
- General remains inactive; existing macro and secure-button names are preserved.
- Includes the updated Zeus portrait in publication assets.

# Changelog

## 0.4.2 Beta
- Publication metadata: author SpankyQuest, MIT license, and refreshed documentation.
- Preserves 0.4.1 casting and buff-minute reporting behavior.

## 0.4.1 Beta
- Report confirmed net buff-minutes provided instead of equally weighted casts.
- Add /zeus report, UTC daily totals, unmeasured casts, and reporting API v2.
- Preserve old raw cast counts separately without converting them to minutes.

## 0.4.0 Beta
- Add daily client-reported statistics and separate General and guild-filtered editions.

## Earlier development
- Class-aware queue, per-recipient buff batches, configurable priority tiles.
- Buff and toggle macros, key binding reset, and independent nameplate ownership.
- Thresholds through 99%, lower-rank upgrades, and standard minimap integration.
