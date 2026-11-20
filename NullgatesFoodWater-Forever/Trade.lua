-- Nullgate's Food & Water: the trade helper. Opens a trade with a player and, once the
-- trade window is open, puts the right food and water stacks in. It never accepts
-- a trade; the player always presses Accept.
local _, ns = ...

local L = ns.L
local Trade = {}
ns.Trade = Trade

local TRADE_SLOTS = 6 -- slot 7 is "will not be traded"

function Trade.IsOpen()
    return TradeFrame ~= nil and TradeFrame:IsShown()
end

-- Opens a trade with a unit (the target by default).
function Trade.Open(unit)
    unit = unit or "target"
    if not (UnitExists(unit) and UnitIsPlayer(unit)) or UnitIsUnit(unit, "player") then
        ns.Print(L["Target a player to trade with first."])
        return false
    end
    if InitiateTrade then InitiateTrade(unit) end
    return true
end

-- The level of the player you're trading with ("NPC" is the trade partner's unit).
function Trade.PartnerLevel()
    if UnitExists("NPC") and UnitIsPlayer("NPC") then
        local level = UnitLevel("NPC")
        if level and level > 0 then return level, UnitName("NPC") end
    end
    return UnitLevel("player"), UnitName("player")
end

-- Puts up to db.tradeStacks stacks each of the right food and water into free trade slots.
function Trade.Fill()
    if not Trade.IsOpen() then return false end
    local level, name = Trade.PartnerLevel()
    local used, placed, missing = {}, {}, {}
    for s = 1, TRADE_SLOTS do
        if GetTradePlayerItemInfo and GetTradePlayerItemInfo(s) then used[s] = true end
    end
    local function FreeSlot()
        for s = 1, TRADE_SLOTS do
            if not used[s] then used[s] = true; return s end
        end
        return nil
    end
    for _, kind in ipairs({ "water", "food" }) do
        local rank = ns.Ranks.Pick(kind, level)
        if rank then
            local stacks = ns.Items.Stacks(rank.item)
            if #stacks == 0 then
                missing[#missing + 1] = ns.Items.Name(rank.item) or L[kind == "food" and "food" or "water"]
            end
            for i = 1, math.min(ns.db.tradeStacks or 1, #stacks) do
                local slot = FreeSlot()
                if not slot then break end
                if ClearCursor then ClearCursor() end
                ns.Items.Pickup(stacks[i].bag, stacks[i].slot)
                ClickTradeButton(slot)
                placed[#placed + 1] = stacks[i].count .. " " .. (ns.Items.Name(rank.item) or "")
            end
        end
    end
    if ClearCursor then ClearCursor() end
    if #placed > 0 then
        ns.Print(string.format(L["Put in the trade for %s (level %d): %s. Click Trade when you're ready."], tostring(name), level, table.concat(placed, ", ")))
    end
    if #missing > 0 then
        ns.Print(string.format(L["None in your bags: %s. Conjure some first."], table.concat(missing, ", ")))
    end
    return #placed > 0
end

-- One button for both steps: open a trade with the target, or fill the open one.
function Trade.Click(unit)
    if Trade.IsOpen() then return Trade.Fill() end
    return Trade.Open(unit)
end
