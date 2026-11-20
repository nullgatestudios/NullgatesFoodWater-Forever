-- Nullgate's Food & Water: tests for the rank data and the rank picker.
-- Run from the repository root:  lua tests/run.lua   (Lua 5.1 or newer)

local source = debug.getinfo(1, "S").source or ""
local script = source:match("^@(.*)$") or "tests/run.lua"
local scriptDir = script:match("^(.*)[/\\][^/\\]*$") or "."
local root = (scriptDir:match("^(.*)[/\\][^/\\]*$") or ".") .. "/NullgatesFoodWater-Forever/"

local ns = {}
local function Load(file) assert(loadfile(root .. file), "cannot load " .. file)("NullgatesFoodWater-Forever", ns) end
Load("Data/ConjureRanks.lua")
Load("Ranks.lua")

local checks, failures = 0, 0
local function EQ(got, want, name)
    checks = checks + 1
    if got ~= want then
        failures = failures + 1
        print(string.format("FAIL %s: expected %s, got %s", name, tostring(want), tostring(got)))
    end
end

local Ranks = ns.Ranks

-- Which spells the "player" knows; Ranks.IsKnown asks this.
local known = {}
Ranks.IsKnown = function(spell) return known[spell] == true end
local function Know(kind, uptoLearnLevel)
    for _, rank in ipairs(ns.CONJURE_RANKS[kind]) do
        if rank.learnLevel > 0 and rank.learnLevel <= uptoLearnLevel then known[rank.spell] = true end
    end
end
local function Item(kind, level)
    local rank = Ranks.Pick(kind, level)
    return rank and rank.item
end

-- --- The data ---------------------------------------------------------------
for _, kind in ipairs({ "food", "water" }) do
    local list = ns.CONJURE_RANKS[kind]
    EQ(#list >= 7, true, kind .. ": at least the seven trainer ranks")
    local sorted = true
    for i = 2, #list do
        if list[i].itemLevel < list[i - 1].itemLevel then sorted = false end
    end
    EQ(sorted, true, kind .. ": sorted by item level")
    for _, rank in ipairs(list) do
        EQ(type(rank.spell) == "number" and type(rank.item) == "number" and rank.itemLevel >= 1 and rank.count >= 1, true,
            kind .. ": rank " .. tostring(rank.spell) .. " is complete")
    end
end
EQ(type(ns.CONJURE_DATA_BUILD), "string", "the data names its client build")

-- --- A level 60 mage who knows every trainer rank ------------------------------
Know("food", 60)
Know("water", 60)
known[468766] = nil -- Mountain Spring Water does not come from the trainer
known[8736] = nil   -- nor does the 5-per-cast Muffin variant
local MUFFIN, BREAD, RYE, SWEET_ROLL, CINNAMON = 5349, 1113, 1114, 8076, 22895
local WATER, FRESH, SPRING, SPARKLING, CRYSTAL, MOUNTAIN = 5350, 2288, 3772, 8078, 8079, 231778
EQ(Item("food", 1), MUFFIN, "level 1 gets Muffin")
EQ(Item("food", 4), MUFFIN, "level 4 still gets Muffin")
EQ(Item("food", 5), BREAD, "level 5 gets Bread")
EQ(Item("food", 15), RYE, "level 15 gets Rye")
EQ(Item("food", 54), SWEET_ROLL, "level 54 gets Sweet Roll")
EQ(Item("food", 55), CINNAMON, "level 55 gets Cinnamon Roll")
EQ(Item("food", 60), CINNAMON, "level 60 gets Cinnamon Roll")
EQ(Item("water", 1), WATER, "level 1 gets Conjured Water")
EQ(Item("water", 14), FRESH, "level 14 gets Fresh Water")
EQ(Item("water", 25), SPRING, "level 25 gets Spring Water")
EQ(Item("water", 50), SPARKLING, "level 50 gets Sparkling Water")
EQ(Item("water", 60), CRYSTAL, "level 60 gets Crystal Water when Mountain Spring is not known")

-- Same item level: the rank that makes more per cast wins.
known[468766] = true
EQ(Item("water", 60), MOUNTAIN, "Mountain Spring Water (20 per cast) beats Crystal Water at the same level")
known[468766] = nil

-- --- A mage who only knows the lower ranks -------------------------------------
known = {}
Know("water", 30) -- up to Spring Water
EQ(Item("water", 60), SPRING, "a level 60 target gets the best rank the mage knows")
EQ(Item("water", 12), FRESH, "a level 12 target still gets the right lower rank")

-- --- Nothing to pick ---------------------------------------------------------
known = {}
EQ(Ranks.Pick("food", 40), nil, "no rank known: nothing")
Know("food", 60)
EQ(Ranks.Pick("food", 0), nil, "level 0: nothing")
EQ(Ranks.Pick("food", -1), nil, "level -1 (unknown): nothing")
EQ(Ranks.Pick("food", nil), nil, "no level: nothing")
EQ(Ranks.Pick("drink", 40), nil, "unknown kind: nothing")
EQ(Item("food", "30"), ns.CONJURE_RANKS.food[5].item, "a level given as text still works")

print(string.format("%d checks, %d failure(s)", checks, failures))
if failures > 0 then os.exit(1) end
