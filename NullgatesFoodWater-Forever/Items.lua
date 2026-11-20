-- Nullgate's Food & Water: item and bag helpers (the only file that reads bags or item info).
local _, ns = ...

local Items = {}
ns.Items = Items

function Items.Count(itemID)
    local count = (C_Item and C_Item.GetItemCount) or GetItemCount
    return (count and count(itemID)) or 0
end

function Items.Icon(itemID)
    local icon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    return icon and icon(itemID) or nil
end

-- The item's name, or nil while the client hasn't loaded it yet.
function Items.Name(itemID)
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    return info and (info(itemID)) or nil
end

-- How many conjured items of a kind are in the bags, over every rank.
function Items.TotalOf(kind)
    local total, seen = 0, {}
    for _, rank in ipairs((ns.CONJURE_RANKS and ns.CONJURE_RANKS[kind]) or {}) do
        if not seen[rank.item] then
            seen[rank.item] = true
            total = total + Items.Count(rank.item)
        end
    end
    return total
end

local function SlotInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then return info.itemID, info.stackCount or 1, info.isLocked end
        return nil
    end
    if GetContainerItemInfo then
        local _, count, locked, _, _, _, _, _, _, itemID = GetContainerItemInfo(bag, slot)
        return itemID, count or 1, locked
    end
    return nil
end

-- The stacks of an item in the bags that can be picked up: { bag =, slot =, count = },
-- biggest first. Stacks already placed in a trade are locked and left out.
function Items.Stacks(itemID)
    local numSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    local stacks = {}
    if not numSlots then return stacks end
    for bag = 0, 4 do
        for slot = 1, (numSlots(bag) or 0) do
            local id, count, locked = SlotInfo(bag, slot)
            if id == itemID and not locked then stacks[#stacks + 1] = { bag = bag, slot = slot, count = count } end
        end
    end
    table.sort(stacks, function(a, b) return a.count > b.count end)
    return stacks
end

function Items.Pickup(bag, slot)
    local pickup = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
    if pickup then pickup(bag, slot) end
end
