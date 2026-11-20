**Nullgate's Food & Water** is a mage addon for **World of Warcraft: Forever**. Target a player, click **Food** or **Water**, and you conjure the best rank you know that they can actually use.

No more handing a level 20 rogue water they can't drink, or giving a level 50 warrior bread when you could make Sweet Rolls. With no target, it simply conjures for your own level.

> **Beta:** this is an early test version and we're looking for mages to try it. If something doesn't work, run `/nfw check`, then send us the results with a short description.

---

## Features

- **Food and Water buttons**: they pick the right rank for whoever you're targeting. Each button shows the icon of what it will make and how many you're carrying, and its tooltip says who it's for.
- **Every rank in WoW Forever**, read straight from the game client, including the Forever-only **Mountain Spring Water** (20 per cast).
- **Key bindings** for both buttons, under Key Bindings > AddOns.
- **Trade helper**: click Trade to open a trade with your target, then click again to put the right food and water stacks in. You always press Accept yourself.
- **Group view**: every party or raid member with the food and water they need, a summary such as "3 x Sweet Roll, 1 x Sourdough", and Food, Water and Trade buttons on each row.
- **Low-stock warning**: a gentle reminder when your own conjured food or water drops below a number you choose, as a chat line, a short sound or a glow on the button. It only warns once until you restock, and stays quiet in combat.
- **Simple settings**: lock and move the bar, vertical or horizontal layout, scale, item counts, how many stacks to trade, and the low-stock options.

---

## How It Works

1. **Target a player**: a party member, a guildmate, anyone friendly.
2. **Click Food or Water**, or press its key binding.
3. **You conjure the right rank**: the highest one you know whose food or water that player is high enough to use. If two ranks give the same level of item, it picks the one that makes more per cast.

Enemies, NPCs and no target all mean "conjure for my own level".

The game doesn't allow spells to be changed during combat. If your target changes mid-fight, the buttons show a small red mark and update as soon as combat ends.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/nfw` or `/foodwater` | Open the settings. |
| `/nfw group` | Show or hide the group view. |
| `/nfw lock` / `/nfw unlock` | Lock or unlock the bar. |
| `/nfw reset` | Reset the bar's position. |
| `/nfw check` | Test what the addon needs in your game client and save the results (for bug reports). |

---

## Installation

1. Download the latest file.
2. Extract the `NullgatesFoodWater-Forever` folder into the `Interface\AddOns` folder of your World of Warcraft: Forever installation.
3. Log in on a mage. The bar appears near the bottom of the screen; type `/nfw` for the settings.

---

## Good to Know

- The addon only runs for mages.
- It never accepts a trade for you.
- English only for now.
