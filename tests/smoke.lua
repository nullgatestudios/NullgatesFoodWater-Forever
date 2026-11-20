-- Nullgate's Food & Water: smoke test of the whole addon with stand-in game API.
-- Loads the files in .toc order, logs in as a mage and drives the buttons, combat,
-- trading, the group view, the low-stock warning and /nfw check.
-- Run from the repository root:  lua tests/smoke.lua

local source = debug.getinfo(1, "S").source or ""
local script = source:match("^@(.*)$") or "tests/smoke.lua"
local scriptDir = script:match("^(.*)[/\\][^/\\]*$") or "."
local repo = scriptDir:match("^(.*)[/\\][^/\\]*$") or "."
local folder = "NullgatesFoodWater-Forever"
local root = repo .. "/" .. folder .. "/"
local write = io.write

local checks, failures = 0, 0
local function OK(cond, name)
    checks = checks + 1
    if not cond then failures = failures + 1; write("FAIL " .. name .. "\n") end
end

-- --- Stand-in game API ----------------------------------------------------------
local frames, printed = {}, {}
local function NewFrame(kind, name, parent, template)
    local f = { kind = kind, name = name, template = template, scripts = {}, attributes = {}, events = {}, shown = false }
    -- Unknown methods (capitalized) are no-ops; unset fields are nil, like real frames
    setmetatable(f, { __index = function(_, key) if type(key) == "string" and key:match("^%u") then return function() return nil end end end })
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:GetScript(k) return self.scripts[k] end
    function f:HookScript(k, fn) local old = self.scripts[k]; self.scripts[k] = function(...) if old then old(...) end fn(...) end end
    function f:RegisterEvent(e) self.events[e] = true end
    function f:UnregisterAllEvents() self.events = {} end
    function f:SetAttribute(k, v) self.attributes[k] = v end
    function f:GetAttribute(k) return self.attributes[k] end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:SetShown(v) self.shown = v and true or false end
    function f:IsShown() return self.shown end
    function f:SetText(t) self.text = t end
    function f:GetText() return self.text end
    function f:CreateFontString() return NewFrame("FontString") end
    function f:CreateTexture() return NewFrame("Texture") end
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
CreateFrame = NewFrame
SlashCmdList = {}
UIParent = NewFrame("Frame", "UIParent")
GameTooltip = NewFrame("GameTooltip", "GameTooltip")
TradeFrame = NewFrame("Frame", "TradeFrame")
RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
print = function(text) printed[#printed + 1] = tostring(text) end
local function LastPrint() return printed[#printed] or "" end

-- The world: units, combat, spells, bags and the trade window.
local units = {
    player = { name = "Me", level = 60, class = "MAGE", friend = true, isPlayer = true },
}
local inCombat = false
local function U(unit) return units[unit] end
function UnitExists(unit) return U(unit) ~= nil end
function UnitIsPlayer(unit) return U(unit) ~= nil and U(unit).isPlayer end
function UnitIsFriend(_, unit) return U(unit) ~= nil and U(unit).friend end
function UnitIsUnit(a, b) return a == b or (U(a) ~= nil and U(a) == U(b)) end
function UnitLevel(unit) return U(unit) and U(unit).level or 0 end
function UnitName(unit) return U(unit) and U(unit).name or nil end
function UnitClass(unit) local u = U(unit); return u and u.class, u and u.class end
function InCombatLockdown() return inCombat end
function GetBuildInfo() return "1.60.1", "70532", "Nov 2026", 16001 end
function IsInRaid() return false end
function GetNumSubgroupMembers() local n = 0; for i = 1, 4 do if units["party" .. i] then n = i end end; return n end
function GetNumGroupMembers() return GetNumSubgroupMembers() + 1 end
local known = {}
for _, id in ipairs({ 587, 597, 990, 6129, 10144, 10145, 28612, 5504, 5505, 5506, 6127, 10138, 10139, 10140 }) do known[id] = true end
C_SpellBook = { IsSpellKnown = function(id) return known[id] == true end }
C_Spell = { GetSpellName = function() return "Conjure Water" end, GetSpellSubtext = function() return "Rank 7" end }
local bags = {} -- [bag][slot] = { itemID =, stackCount = }
C_Container = {
    GetContainerNumSlots = function() return 4 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
    GetContainerItemID = function(bag, slot) local i = bags[bag] and bags[bag][slot]; return i and i.itemID end,
}
local picked, clicked = {}, {}
function PickupContainerItem(bag, slot) picked[#picked + 1] = bags[bag][slot].itemID end
C_Container.PickupContainerItem = PickupContainerItem
function ClickTradeButton(slot) clicked[#clicked + 1] = slot end
function ClearCursor() end
function GetTradePlayerItemInfo() return nil end
local traded
function InitiateTrade(unit) traded = unit end
C_Item = {
    GetItemCount = function(id)
        local n = 0
        for _, bag in pairs(bags) do for _, item in pairs(bag) do if item.itemID == id then n = n + item.stackCount end end end
        return n
    end,
    GetItemIconByID = function(id) return "icon" .. id end,
    GetItemInfo = function(id) return "Item" .. id, nil, nil, nil, (id == 8079) and 55 or nil end,
}
C_Timer = { After = function(_, fn) fn() end }
function PlaySound() end

-- --- Load the files in .toc order -----------------------------------------------
local ns = {}
local toc = assert(io.open(root .. folder .. ".toc", "r")):read("*a")
for line in toc:gmatch("[^\r\n]+") do
    if not line:match("^##") and line:match("%.lua$") then
        assert(loadfile(root .. line:gsub("\\", "/")))(folder, ns)
    end
end
local core
for _, f in ipairs(frames) do if f.events.PLAYER_LOGIN then core = f end end
local function Fire(event, ...) core.scripts.OnEvent(core, event, ...) end
for _, f in ipairs(frames) do -- every ADDON_LOADED listener (core and /nfw check)
    if f.events.ADDON_LOADED and f.scripts.OnEvent then f.scripts.OnEvent(f, "ADDON_LOADED", folder) end
end
OK(type(NullgatesFoodWaterDB) == "table" and NullgatesFoodWaterDB.lowStock.threshold == 10, "saved data gets its defaults")
OK(SLASH_NULLGATESFOODWATER1 == "/nfw" and SLASH_NULLGATESFOODWATER2 == "/foodwater", "slash commands /nfw and /foodwater")
OK(_G["BINDING_NAME_CLICK NullgatesFoodWaterFood:LeftButton"] ~= nil, "the Food key binding has a name")

-- --- Logging in as a mage --------------------------------------------------------
Fire("PLAYER_LOGIN")
local food, water = NullgatesFoodWaterFood, NullgatesFoodWaterWater
OK(food and water and NullgatesFoodWaterTrade, "the Food, Water and Trade buttons exist")
OK(food.template == "SecureActionButtonTemplate", "Food is a secure action button")
OK(food.attributes.type == "spell" and food.attributes.spell == 28612, "no target: food for your own level (Cinnamon Roll)")
OK(water.attributes.spell == 10140, "no target: water for your own level (Crystal Water)")

-- --- Targeting --------------------------------------------------------------------
units.target = { name = "Low", level = 20, class = "WARRIOR", friend = true, isPlayer = true }
Fire("PLAYER_TARGET_CHANGED")
OK(food.attributes.spell == 990 and water.attributes.spell == 5506, "a level 20 friend gets Rye and Purified Water")
units.target = { name = "Foe", level = 20, class = "WARRIOR", friend = false, isPlayer = true }
Fire("PLAYER_TARGET_CHANGED")
OK(food.attributes.spell == 28612, "an enemy target: back to your own level")
units.target = { name = "Wolf", level = 20, friend = true, isPlayer = false }
Fire("PLAYER_TARGET_CHANGED")
OK(food.attributes.spell == 28612, "a non-player target: your own level")

-- --- Combat: changes wait until it ends ---------------------------------------------
inCombat = true
units.target = { name = "Mid", level = 47, class = "WARRIOR", friend = true, isPlayer = true }
Fire("PLAYER_TARGET_CHANGED")
OK(food.attributes.spell == 28612 and food.stale, "in combat the spell doesn't change and the button is marked")
inCombat = false
Fire("PLAYER_REGEN_ENABLED")
OK(food.attributes.spell == 10145 and not food.stale, "after combat the queued change applies (Sweet Roll)")

-- --- Trade helper -------------------------------------------------------------------
units.target = { name = "Buddy", level = 30, class = "WARRIOR", friend = true, isPlayer = true }
Fire("PLAYER_TARGET_CHANGED")
NullgatesFoodWaterTrade.scripts.OnClick(NullgatesFoodWaterTrade)
OK(traded == "target", "Trade opens a trade with the target")
TradeFrame.shown = true
units.NPC = units.target
bags[0] = { [1] = { itemID = 3772, stackCount = 20 }, [2] = { itemID = 1487, stackCount = 20 }, [3] = { itemID = 1487, stackCount = 5 } }
NullgatesFoodWaterTrade.scripts.OnClick(NullgatesFoodWaterTrade)
OK(#clicked == 2 and clicked[1] == 1 and clicked[2] == 2, "the open trade gets one stack each in slots 1 and 2")
OK(picked[1] == 3772 and picked[2] == 1487, "Spring Water and Pumpernickel for a level 30 partner")
OK(LastPrint():find("Accept", 1, true) ~= nil, "it reminds you to press Accept yourself")
picked, clicked = {}, {}
bags[0] = {}
NullgatesFoodWaterTrade.scripts.OnClick(NullgatesFoodWaterTrade)
OK(#clicked == 0 and LastPrint():find("Conjure some first", 1, true) ~= nil, "empty bags: nothing placed, and it says so")
TradeFrame.shown = false
units.NPC = nil

-- --- Group view -----------------------------------------------------------------------
units.party1 = { name = "Tank", level = 47, class = "WARRIOR", friend = true, isPlayer = true }
units.party2 = { name = "Twink", level = 12, class = "WARRIOR", friend = true, isPlayer = true }
SlashCmdList.NULLGATESFOODWATER("group")
OK(NullgatesFoodWaterGroup and NullgatesFoodWaterGroup.shown, "/nfw group opens the group view")
local spells = {}
for _, f in ipairs(frames) do
    if f.template == "SecureActionButtonTemplate" and f ~= food and f ~= water and f.attributes.spell then
        spells[#spells + 1] = f.attributes.spell
    end
end
table.sort(spells)
OK(table.concat(spells, ",") == "597,5505,10139,10145", "rows conjure Sweet Roll and Sparkling Water for 47, Bread and Fresh Water for 12")
local summary = ns.Group.Summary(ns.Group.Members())
OK(#summary.food == 2 and summary.food[1].count == 1, "the summary counts what each member needs")

-- --- Low-stock warning ------------------------------------------------------------------
bags[1] = { [1] = { itemID = 8079, stackCount = 20 }, [2] = { itemID = 22895, stackCount = 20 } }
Fire("BAG_UPDATE_DELAYED") -- well stocked: clears the warning that fired at login (empty bags)
printed = {}
bags[1] = { [1] = { itemID = 8079, stackCount = 4 } } -- 4 Crystal Water, no food
Fire("BAG_UPDATE_DELAYED")
local warnings = 0
for _, line in ipairs(printed) do if line:find("Low on conjured", 1, true) then warnings = warnings + 1 end end
OK(warnings == 2, "low on food and water: one warning each")
OK(water.glow.shown, "the Water button glows while low")
Fire("BAG_UPDATE_DELAYED")
OK(#printed == 2, "no repeat warning until you restock")
bags[1][1].stackCount = 20
Fire("BAG_UPDATE_DELAYED")
OK(not water.glow.shown, "restocked water: the glow goes away")
local low, warn = ns.Stock.Decide(3, 10, false)
OK(low and warn, "Decide: below the threshold warns")
low, warn = ns.Stock.Decide(3, 0, false)
OK(not low and not warn, "Decide: threshold 0 never warns")

-- --- Settings -------------------------------------------------------------------------
SlashCmdList.NULLGATESFOODWATER("")
OK(NullgatesFoodWaterOptions and NullgatesFoodWaterOptions.shown, "/nfw opens the settings window")
SlashCmdList.NULLGATESFOODWATER("lock")
OK(NullgatesFoodWaterDB.locked == true, "/nfw lock locks the bar")

-- --- /nfw check -------------------------------------------------------------------------
SlashCmdList.NULLGATESFOODWATER("check")
local text = table.concat(NullgatesFoodWaterDB.check or {}, "\n")
OK(text:find("C_SpellBook.IsSpellKnown=yes", 1, true) ~= nil, "check reports which calls exist")
OK(text:find("water: best known rank by Ranks.Pick = 10140", 1, true) ~= nil, "check reports the best known rank")
OK(NullgatesFoodWaterCheck and NullgatesFoodWaterCheck.shown, "the check window opens")

io.write(string.format("smoke: %d checks, %d failure(s)\n", checks, failures))
if failures > 0 then os.exit(1) end
