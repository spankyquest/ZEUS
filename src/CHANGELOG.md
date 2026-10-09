# 0.5.1

- **Spam-friendly.** ZEUS acts on up to four presses a second, shared by the Buff Key, the wheel and the macro, so hammering them no longer redoes the work every frame. Buffs share the 1.5-second global cooldown, so you won't buff any slower. A held key still finishes its press when you let go.
- **The Buff macro, with ZEUS off, works as a quick run.** Spamming it turns ZEUS and friendly nameplates on while you press and back off three seconds after you stop, whether or not anyone nearby still needs a buff (in a busy town someone always does, so the old "once everyone's buffed" rule could leave ZEUS on). Your Buff Key isn't taken over during these runs; it only buffs when you turn ZEUS on yourself.
- **Languages.** ZEUS speaks Deutsch, Español, Français and Português (Brasil), the same languages as Olympus Guild, and uses the same scheme: any line a language leaves out stays English. Buff and class names come from the game in your language, and the addon list shows a translated description.
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
