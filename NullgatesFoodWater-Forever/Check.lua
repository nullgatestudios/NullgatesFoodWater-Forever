-- Nullgate's Food & Water: /nfw check, the in-game self test (phase 0 of PLAN.md).
-- It answers what the addon depends on in this client and writes every result to
-- chat and to NullgatesFoodWaterDB.check, so the log can be copied from
-- WTF\Account\<account>\SavedVariables\NullgatesFoodWater-Forever.lua.
--
--   1. Which spell-knowledge and spell-info calls exist, and what they say per rank.
--   2. Whether each conjured item's required level matches the generated table.
--   3. Whether a secure button casts an exact rank, by spell ID and by "Name(Rank N)".
--   4. Whether one click can target a party member and cast (macro text button).
--   5. Whether an addon can open a trade and place items in it.
local _, ns = ...

local Check = {}
ns.Check = Check

local LOG_LIMIT = 400
local panel, castExpect

local function Log(text)
    local db = NullgatesFoodWaterDB
    if db then
        db.check = db.check or {}
        local log = db.check
        if #log >= LOG_LIMIT then table.remove(log, 1) end
        log[#log + 1] = text
    end
    print("|cff00c0ffNullgate's Food & Water check:|r " .. text)
    if NullgateReport then NullgateReport.Update("food-water") end
end
Check.Log = Log

-- Opens the report window every Nullgate addon shares (NullgateReport.lua) with this check's log,
-- ready to copy and paste into the report form on our website.
function Check.ShowReport()
    local L = ns.L
    return NullgateReport.Show({
        slug = "food-water", name = "Nullgate's Food & Water", addon = "NullgatesFoodWater-Forever", command = "/nfw check",
        lines = function() return NullgatesFoodWaterDB and NullgatesFoodWaterDB.check end,
        title = L["Bug report"], selectAll = L["Select all"], selectLink = L["Select link"],
        help = L["Press Ctrl+C to copy this report, then paste it into a new report at the link below, with a few words on what happened."],
    })
end

local function Exists(path)
    local value = _G
    for part in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return false end
        value = value[part]
    end
    return type(value) == "function"
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return "n/a" end
    local ok, a, b = pcall(fn, ...)
    if not ok then return "error: " .. tostring(a) end
    if b ~= nil then return tostring(a) .. ", " .. tostring(b) end
    return tostring(a)
end

local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return (GetSpellInfo(id)) end
    return nil
end

local function SpellSubtext(id)
    if C_Spell and C_Spell.GetSpellSubtext then return C_Spell.GetSpellSubtext(id) end
    if GetSpellSubtext then return GetSpellSubtext(id) end
    return nil
end

local function ItemMinLevel(id)
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if not info then return nil end
    local name, _, _, _, minLevel = info(id)
    return name, minLevel
end

-- The best known rank of a kind regardless of level (for the cast tests).
local function BestKnown(kind)
    return ns.Ranks.Pick(kind, 999)
end

-- --- 1 and 2: static checks -------------------------------------------------------

local function StaticChecks()
    local _, class = UnitClass("player")
    Log(string.format("client %s, build %s, interface %s; class %s, level %s; data build %s",
        tostring(GetBuildInfo and select(1, GetBuildInfo())), tostring(GetBuildInfo and select(2, GetBuildInfo())),
        tostring(GetBuildInfo and select(4, GetBuildInfo())), tostring(class), tostring(UnitLevel("player")),
        tostring(ns.CONJURE_DATA_BUILD)))
    local calls = {}
    for _, name in ipairs({ "IsSpellKnown", "IsPlayerSpell", "C_SpellBook.IsSpellKnown",
        "C_SpellBook.IsSpellInSpellBook", "C_Spell.GetSpellName", "GetSpellInfo", "C_Spell.GetSpellSubtext",
        "InitiateTrade", "ClickTradeButton", "PickupContainerItem", "C_Container.PickupContainerItem",
        "C_Container.GetContainerItemID", "GetTradePlayerItemInfo" }) do
        calls[#calls + 1] = name .. "=" .. (Exists(name) and "yes" or "no")
    end
    Log("calls: " .. table.concat(calls, " "))

    for _, kind in ipairs({ "food", "water" }) do
        for _, rank in ipairs(ns.CONJURE_RANKS[kind]) do
            local name, minLevel = ItemMinLevel(rank.item)
            local levelNote = minLevel == nil and "item not cached yet" or
                (minLevel == rank.itemLevel and "item level ok" or ("ITEM LEVEL " .. tostring(minLevel) .. " ~= table " .. rank.itemLevel))
            Log(string.format("%s %d %s %s | IsSpellKnown=%s IsPlayerSpell=%s C_SpellBook.IsSpellKnown=%s | %s (%s)",
                kind, rank.spell, tostring(SpellName(rank.spell)), tostring(SpellSubtext(rank.spell)),
                Call(IsSpellKnown, rank.spell), Call(IsPlayerSpell, rank.spell),
                Call(C_SpellBook and C_SpellBook.IsSpellKnown, rank.spell), tostring(name or rank.item), levelNote))
        end
        local best = BestKnown(kind)
        Log(kind .. ": best known rank by Ranks.Pick = " .. (best and (best.spell .. " (item " .. best.item .. ")") or "none"))
    end
end

-- --- 3, 4 and 5: interactive buttons -----------------------------------------------

local function SecureButton(label, y)
    local button = CreateFrame("Button", nil, panel, "SecureActionButtonTemplate, UIPanelButtonTemplate")
    button:SetSize(260, 22)
    button:SetPoint("TOP", panel, "TOP", 0, y)
    button:SetText(label)
    button:RegisterForClicks("AnyUp", "AnyDown")
    return button
end

local function PlainButton(label, y, onClick)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(260, 22)
    button:SetPoint("TOP", panel, "TOP", 0, y)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

local function FindInBags(itemID)
    local getID = (C_Container and C_Container.GetContainerItemID) or GetContainerItemID
    local slots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    if not getID or not slots then return nil end
    for bag = 0, 4 do
        for slot = 1, (slots(bag) or 0) do
            if getID(bag, slot) == itemID then return bag, slot end
        end
    end
    return nil
end

local function FillTrade()
    local water = BestKnown("water")
    local bag, slot = water and FindInBags(water.item)
    if not bag then
        Log("trade: no conjured water of your best rank in your bags; conjure some first")
        return
    end
    if not (TradeFrame and TradeFrame:IsShown()) then
        Log("trade: open a trade first")
        return
    end
    local pickup = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
    local ok1, err1 = pcall(pickup, bag, slot)
    local ok2, err2 = pcall(ClickTradeButton, 1)
    local name, _, count = GetTradePlayerItemInfo(1)
    Log(string.format("trade: pickup %s, ClickTradeButton %s, trade slot 1 now holds %s x%s",
        ok1 and "ok" or ("error " .. tostring(err1)), ok2 and "ok" or ("error " .. tostring(err2)), tostring(name), tostring(count)))
    if ClearCursor then ClearCursor() end
end

local function BuildPanel()
    panel = CreateFrame("Frame", "NullgatesFoodWaterCheck", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(300, 230)
    panel:SetPoint("TOPLEFT", NullgateReport.Frame(), "TOPRIGHT", 4, 0)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    -- The title lives in a different place on different client versions.
    local title = "Food & Water check"
    if type(panel.SetTitle) == "function" then
        panel:SetTitle(title)
    elseif type(panel.TitleText) == "table" then
        panel.TitleText:SetText(title)
    elseif panel.TitleContainer and panel.TitleContainer.TitleText then
        panel.TitleContainer.TitleText:SetText(title)
    end

    local water = BestKnown("water")
    local byID = SecureButton("1. Cast best water by spell ID", -34)
    local byName = SecureButton("2. Cast best water by name and rank", -62)
    local party = SecureButton("3. Target party1 and cast (one click)", -90)
    if water then
        local name, subtext = SpellName(water.spell), SpellSubtext(water.spell)
        local text = (subtext and subtext ~= "") and string.format("%s(%s)", name, subtext) or name
        byID:SetAttribute("type", "spell")
        byID:SetAttribute("spell", water.spell)
        byName:SetAttribute("type", "spell")
        byName:SetAttribute("spell", text)
        party:SetAttribute("type", "macro")
        party:SetAttribute("macrotext", "/target party1\n/cast " .. tostring(text))
        byID:HookScript("OnClick", function() castExpect = { test = "by spell ID", spell = water.spell } end)
        byName:HookScript("OnClick", function() castExpect = { test = "by name '" .. tostring(text) .. "'", spell = water.spell } end)
        party:HookScript("OnClick", function()
            castExpect = { test = "party1 macro", spell = water.spell }
            C_Timer.After(0.3, function()
                Log("party1 macro: target is now " .. tostring(UnitName("target")) .. " (party1 is " .. tostring(UnitName("party1")) .. ")")
            end)
        end)
    else
        Log("cast tests: you know no Conjure Water rank, so buttons 1 to 3 do nothing")
    end
    PlainButton("4. Open a trade with your target", -126, function()
        if not UnitExists("target") or not UnitIsPlayer("target") then
            Log("trade: target a player first")
            return
        end
        local ok, err = pcall(InitiateTrade, "target")
        Log("trade: InitiateTrade " .. (ok and "called" or ("error " .. tostring(err))))
    end)
    PlainButton("5. Put your water in the trade", -154, FillTrade)
    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("BOTTOM", panel, "BOTTOM", 0, 14)
    note:SetWidth(270)
    note:SetText("Results go to chat and are saved. Cancel the trade afterwards.")
end

-- Every cast and every blocked action is logged while the check is running.
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
watcher:RegisterEvent("ADDON_ACTION_BLOCKED")
watcher:RegisterEvent("ADDON_ACTION_FORBIDDEN")
watcher:RegisterEvent("TRADE_SHOW")
watcher:SetScript("OnEvent", function(_, event, a, b, c)
    if not (panel and panel:IsShown()) then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if a ~= "player" or not castExpect then return end
        local expect = castExpect
        castExpect = nil
        Log(string.format("cast %s: cast spell %s, expected %s -> %s", expect.test, tostring(c), tostring(expect.spell),
            c == expect.spell and "OK" or "DIFFERENT RANK"))
    elseif event == "TRADE_SHOW" then
        Log("trade: the trade window opened")
    else
        Log(event .. ": " .. tostring(a) .. " tried " .. tostring(b))
    end
end)

function Check.Run()
    if InCombatLockdown() then
        Log("leave combat first; secure buttons can't be made in combat")
        return
    end
    if NullgatesFoodWaterDB then NullgatesFoodWaterDB.check = {} end
    StaticChecks()
    if not panel then BuildPanel() end
    panel:Show()
    Log("now click buttons 1 to 5 in the check window (be in a party for 3, target a player for 4 and 5)")
    Check.ShowReport()
end
