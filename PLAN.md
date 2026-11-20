# Nullgate's Food & Water - Forever: Plan

Status: planning, with no code written yet. Planned on 2026-11-19.

- **Folder:** `NullgatesFoodWater-Forever`
- **Saved variables:** `NullgatesFoodWaterDB`
- **Commands:** `/nfw` and `/foodwater`

## What it does

Target a player and click **Food** or **Water**. The addon casts the highest rank of Conjure Food or Conjure Water that you know and that player can use. With no friendly player targeted, it conjures for your own level.

## The constraint that shapes the design

WoW blocks addon code from choosing and casting a spell at the moment you click. The click has to land on a **secure action button** whose spell was set in advance, and that spell can only be changed **out of combat**.

- **Before the click:** the addon works out the right rank whenever the target changes, and sets it on the button.
- **During combat:** a change waits until combat ends, and the button shows a combat marker meanwhile.
- **Precedent:** Quest Tracker's quest item button already works this way in this client.

## Decisions made

- Two buttons: **Food** and **Water**.
- No target (or a target that isn't a friendly player) means conjure for your own level.
- Mage only: the addon stays off for other classes.
- The rank table is generated from Forever client data (wago.tools), never typed by hand.
- The addon never completes a trade. The player always confirms the trade.

---

## Phase 0: Check in the game (about 1 day)

**Status:** built as `/nfw check`; no mage available, so beta testers run it. The code shows a numeric spell ID casts that exact rank (`CastSpellByID`), and conjuring needs no target.

Confirm in the Forever client:

- A secure button set to a specific rank (for example `Conjure Water(Rank 5)`) casts that rank on click.
- What `IsSpellKnown` reports for each rank.
- The actual rank levels and item required levels in Forever.
- **For phase 4:** whether `InitiateTrade` plus placing items (`PickupContainerItem`, `ClickTradeButton`) works from a normal click.
- **For phase 5:** whether a click can target a party member and cast in one press, like a `[@party1]` macro.

**Done when:** a notes file lists which calls work and which don't. Phases 4 and 5 are adjusted to match.

## Phase 1: Rank data (done, v0.1.0)

- **Generator:** a script in `tools/` reads the Forever client tables (spells, what each spell creates, each item's required level) and writes `Data/ConjureRanks.lua`, like Quest Tracker's `generate_forever_quests.py`.
- **Pick function:** from a level, choose the highest rank you know whose item that level can use.
- **Tests:** each level band, knowing only lower ranks, a level-1 target, and knowing no ranks.

**Done when:** the generated table matches the phase 0 notes and the tests pass.

## Phase 2: The buttons (built, in 1.0.0-beta.1)

- **Two secure buttons**, Food and Water, on a small movable bar.
- **Whose level:** a friendly player target uses that player's level. Anyone or anything else uses your own.
- **When the spell updates:** on target change, level-up and learning a new rank, out of combat only. Changes during combat wait until it ends.
- **What each button shows:** the icon of the item it will make, the count you're carrying, and a tooltip such as "Sweet Roll (rank 6), for Bob, level 47".
- **Key bindings:** click bindings for both buttons.
- **Mage only:** off for other classes.

**Done when:** in game, targeting players of different levels changes the buttons, the right rank is cast, and nothing errors in combat.

## Phase 3: Settings and first release (v1.0) (built, in 1.0.0-beta.1)

- **Settings:** lock or move the bar, its scale, show counts, horizontal or vertical layout, hide when not a mage.
- **Suite fit:** it appears in Nullgate's Addon Config when installed, and uses the suite's look.
- **Commands:** `/nfw` and `/foodwater` (open settings, reset position).
- **Release:** translations for the suite's 11 languages, README, DESCRIPTION, CHANGELOG, a GitHub repo under nullgatestudios, the CurseForge project and the shared CurseForge release workflow.

**Done when:** the zip installs clean and passes in-game testing. Release only when the owner says so.

## Phase 4: Trade helper (v1.1) (built, in 1.0.0-beta.1)

- **Trade button:** a third button opens a trade with your target.
- **Filling the window:** when the trade window opens, one click puts the right food and water stacks in. The default is one stack of each, and the number of stacks is a setting.
- **Accept:** the player still presses Accept. The addon never completes a trade.
- **If phase 0 shows the client blocks placing items:** the button only opens the trade and highlights the right stacks in your bags.

**Done when:** trading a party member puts the correct items in the window, and nothing is traded without the player's click.

## Phase 5: Group view (v1.2) (built, in 1.0.0-beta.1)

- **Panel:** lists party or raid members, each with the food and water rank they need and their level.
- **Clicking a row:** conjures for that member, if phase 0 confirms one-press target-and-cast. Otherwise it targets them, and the Food and Water buttons update.
- **Batch hint:** for example "3 players need Sweet Roll, 1 needs Sourdough".
- **Live updates:** it refreshes on roster changes and level-ups.

**Done when:** in a group with mixed levels, the panel shows the right items for everyone and clicking works.

## Phase 6: Low-stock warning (v1.3) (built, in 1.0.0-beta.1)

- **Reminder:** fires when your own conjured food or water drops below a number you set. Choose a chat line, a short sound, or a glow on the button.
- **Quiet times:** it stays quiet in combat.

**Done when:** the warning fires once at the threshold, and not again until you restock.
