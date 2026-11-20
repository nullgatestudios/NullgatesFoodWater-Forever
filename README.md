# Nullgate's Food & Water - Forever

> **Status: beta** (1.0.0-beta.1). Looking for mages to test it. See [CHANGELOG.md](CHANGELOG.md).

**Nullgate's Food & Water** is a mage addon for **World of Warcraft: Forever**. Target a player, click **Food** or **Water**, and you conjure the highest rank they can use. You won't hand a level 20 rogue water they can't drink, or make a level 50 warrior settle for bread.

With no target, it conjures for your own level.

---

## How It Works

1. **Target a player**: a party member, a guildie, anyone friendly.
2. **Click Food or Water** (or press its key binding).
3. **You conjure the right rank**: the highest one you know whose food or water that player is high enough to use.

The buttons show the icon of what they'll make, how many you're carrying, and a tooltip such as *"Sweet Roll (rank 6), for Bob, level 47"*.

Spells can't be swapped in combat, so if your target changes mid-fight the buttons update as soon as combat ends.

---

## Features

- **Food and Water buttons** that follow your target's level, with key bindings, item counts and a movable bar.
- **Trade helper**: open a trade with your target and drop in the right food and water stacks in one click. You still press Accept yourself.
- **Group view**: see what every party or raid member needs, with batch hints like *"3 x Sweet Roll"*, and conjure or trade from each row.
- **Low-stock warning**: a gentle reminder when your own conjured food or water runs low.
- **Settings** in its own window or inside Nullgate's Addon Config.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/nfw` or `/foodwater` | Open the settings. |
| `/nfw group` | Show or hide the group view. |
| `/nfw lock` / `/nfw unlock` | Lock or unlock the bar. |
| `/nfw reset` | Reset the bar's position. |
| `/nfw check` | Test what the addon needs in your game client and save the results. |

---

## Installation

Not released yet. Once it is:

1. Download the latest release from CurseForge or the GitHub releases page.
2. Extract the `NullgatesFoodWater-Forever` folder into the `Interface\AddOns` folder of your World of Warcraft: Forever installation.
3. Log in on a mage and type `/nfw`.

---

## Part of the Nullgate Addon Suite

- **Nullgate's Addon Config**: one settings hub and profile manager for the whole suite.
- **Nullgate's Action Bars**, **Bags**, **Chat**, **Maps**, **Quest Tracker**, **Unit Toggles** and **Blacklist**.

---

## Development

| Task | Command |
| :--- | :--- |
| Refresh the rank data after a client patch | `python tools/generate_conjure_ranks.py` (reads the latest Forever build from wago.tools) |
| Run the tests | `lua tests/run.lua` and `lua tests/smoke.lua` |
| Build `zips/NullgatesFoodWater-Forever-<version>.zip` | `.\package.ps1` (or `.\package.ps1 -Version 0.2.0` to set the version first) |

Publishing a GitHub release uploads that version to CurseForge (`.github/workflows/curseforge.yml`); pushes only run the tests.

---

## License

Source-available, all rights reserved. See [LICENSE.md](LICENSE.md).
