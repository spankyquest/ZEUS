# ZEUS

**Zero Effort Utility Spamming · by SpankyQuest · MIT**

**Power your allies. Crush your enemies.**

One-button buffing for World of Warcraft: Forever. Press your Buff Key (or scroll
the mouse wheel, or spam the macro) and ZEUS finds the next player nearby who's
missing your buff, targets them and casts it. It's as close to auto-buffing as the
game allows: every buff still takes a press, and ZEUS handles the targeting, the
ranks and who already has what. It's made for buffing out of combat and does nothing
while you're in combat. Works for any class that can buff: Mages, Priests, Druids, Paladins,
Warlocks, and Shamans.

<img width="795" height="759" alt="Screenshot 2026-10-09 130744" src="https://github.com/user-attachments/assets/fc4c232e-74b1-402b-af30-750b541dccfd" />

## In your language

- **Deutsch · deDE (German):** Buffen auf Knopfdruck für WoW Forever: Drück deine
  Taste, und ZEUS schnappt sich den nächsten Spieler in der Nähe, dem dein Buff fehlt,
  nimmt ihn ins Ziel und bufft ihn. Ideal in der Stadt, beim Flugmeister oder vor dem
  Dungeon – und nur außerhalb des Kampfes. Klassen: Magier, Priester, Druide, Paladin,
  Hexenmeister, Schamane.
- **Español · esES (Spanish, Spain):** Bufea a todo el mundo con un solo botón en
  WoW Forever: pulsas tu tecla y ZEUS pilla al siguiente jugador cercano que no tenga
  tu buff, lo selecciona y se lo lanza. Perfecto en la ciudad, en el maestro de vuelo
  o antes de una mazmorra, y solo fuera de combate. Clases: Mago, Sacerdote, Druida,
  Paladín, Brujo, Chamán.
- **Español · esMX (Spanish, Latin America):** Buffea a todos con un solo botón en
  WoW Forever: presionas tu tecla y ZEUS encuentra al siguiente jugador cercano que no
  tenga tu buff, lo selecciona y se lo lanza. Súper práctico en la ciudad, con el
  maestro de vuelo o antes de entrar a un calabozo, y solo funciona fuera de combate.
  Clases: Mago, Sacerdote, Druida, Paladín, Brujo, Chamán.
- **Français · frFR (French):** Buffer tout le monde en un seul bouton sur WoW
  Forever : tu appuies sur ta touche et ZEUS trouve le prochain joueur à côté qui n'a
  pas ton buff, le cible et le lui lance. Parfait en ville, chez le maître de vol ou
  avant un donjon, et seulement hors combat. Classes : Mage, Prêtre, Druide, Paladin,
  Démoniste, Chaman.
- **Português · ptBR (Portuguese, Brazil):** Buff pra galera toda com um botão só no
  WoW Forever: aperta sua tecla e o ZEUS acha o próximo jogador por perto que está sem
  o seu buff, seleciona e já manda o buff. Perfeito na cidade, no mestre de voo ou
  antes da masmorra, e só fora de combate. Classes: Mago, Sacerdote, Druida, Paladino,
  Bruxo, Xamã.
- **简体中文 · zhCN (Simplified Chinese):** 《魔兽世界：无限》（WoW Forever）一键上Buff：按下按键，ZEUS（宙斯）就会找到附近下一位缺你Buff的玩家，自动选中并施放。主城、飞行点、进本前都超好用，只在脱战时工作。支持职业：法师、牧师、德鲁伊、圣骑士、术士、萨满祭司。

## Pick your edition

| Edition | Who it buffs | Read more |
| --- | --- | --- |
| ZEUS | Every friendly player around you | [README](editions/general/README.md) |
| ZEUS Olympus | Only members of Olympus guilds (no Olympus addon needed) | [README](editions/olympus/README.md) |

Install just one. If both are turned on, ZEUS Olympus runs and the other sits out.

简体中文说明：[README.zh-CN](editions/general/README.zh-CN.md)

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
