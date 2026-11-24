# Changelog - Nullgate's Food & Water (Forever)

All notable changes to **Nullgate's Food & Water - Forever** are documented below.

## [1.0.0-beta.2] - 2026-11-24

### New

- **Bug report window.** `/nfw check` now opens a window with its report, ready to copy.
- Press Ctrl+C to copy the report, then paste it into the report form at nullgatestudios.com/report?addon=food-water, which opens with this addon already picked. You can report without an account.
- Every Nullgate addon now uses the same report window.

### Good to know

- The game doesn't let addons open a web browser, so type or copy the link into your browser yourself. The **Select link** button selects it for copying.

## [1.0.0-beta.1] - 2026-11-20: First Beta

The first test version, looking for mages to try it out. Everything below is built and tested outside the game, but not yet on a real mage, so please report anything that doesn't work.

### Added
- **Food and Water buttons**: target a player and click to conjure the best rank of food or water you know that they can use. With no target, or an enemy or NPC targeted, it conjures for your own level.
- The buttons show the icon of what they'll make and how many you're carrying, and their tooltip says who it's for.
- **Key bindings** for both buttons (Key Bindings > AddOns).
- **Trade button**: click it to open a trade with your target, then click again to put the right food and water stacks in. You still confirm the trade yourself.
- **Group view** (`/nfw group`): every party or raid member with the rank they need, a summary such as "3 x Sweet Roll", and Food, Water and Trade buttons on each row.
- **Low-stock warning**: a reminder when your own conjured food or water drops below a number you choose, as a chat line, a short sound or a glow on the button.
- **Settings** (`/nfw`): lock or move the bar, vertical layout, scale, item counts, how many stacks to trade, and the low-stock options. They also appear in Nullgate's Addon Config when installed.
- **Every rank in WoW Forever**, read straight from the game client, including the Forever-only **Mountain Spring Water** (20 per cast).
- `/nfw check`: a self test that records what the addon needs in your game client, for reporting problems.

### Good to know
- Spells can't be changed in combat. If your target changes mid-fight, the buttons show a small red mark and update as soon as combat ends.
- The addon only runs for mages.
- **10 languages**: English, Deutsch, Español, Français, Italiano, Português (Brasil), Русский, 한국어, 简体中文 and 繁體中文 (every language the game client runs in). The game's language is used automatically; pick another in the settings (it applies after /reload). Translations were made with machine assistance.

## [0.1.0] - Unreleased: Rank data

### Added
- The table of every Conjure Food and Conjure Water rank in WoW Forever, read straight from the game client: which food or water each rank makes, the level needed to use it, and how many it makes per cast.
- The logic that picks the best rank you know for a given level. This is the groundwork for the Food and Water buttons, which come next.
- `/nfw check` (also `/foodwater check`): a self test that checks what the addon needs in your game client, such as which ranks you know and whether a button can cast an exact rank, and saves the results.
