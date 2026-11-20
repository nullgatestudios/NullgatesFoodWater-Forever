-- Nullgate's Food & Water: the bar with the Food, Water and Trade buttons.
-- Food and Water are secure action buttons: the rank to cast is chosen ahead of the
-- click (on target change, level-up, learning a rank) and set as the button's spell ID.
-- Spells can only be changed out of combat, so changes made in combat wait for it to end.
local _, ns = ...

local L = ns.L
local Buttons = {}
ns.Buttons = Buttons

local SIZE, GAP = 36, 4
local KINDS = { "food", "water" }
local FALLBACK_ICON = { food = "Interface\\Icons\\INV_Misc_Food_08", water = "Interface\\Icons\\INV_Drink_18" }
local TRADE_ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local bar
local buttons = {}
Buttons.buttons = buttons

-- Whose level to conjure for: a friendly player you're targeting, otherwise you.
function Buttons.LevelFor()
    if UnitExists("target") and UnitIsPlayer("target") and UnitIsFriend("player", "target")
        and not UnitIsUnit("target", "player") then
        local level = UnitLevel("target")
        if level and level > 0 then return level, UnitName("target") end
    end
    return UnitLevel("player"), UnitName("player")
end

local function ShowTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if button.kind == "trade" then
        GameTooltip:AddLine(L["Trade Food & Water"], 1, 0.82, 0)
        GameTooltip:AddLine(ns.Trade.IsOpen() and L["Click to put the right food and water in the trade."]
            or L["Click to open a trade with your target, then click again to fill it."], 1, 1, 1, true)
    elseif button.rank then
        local item = ns.Items.Name(button.rank.item) or L["Conjured item"]
        GameTooltip:AddLine(item, 1, 0.82, 0)
        GameTooltip:AddLine(string.format(L["For %s (level %d)"], tostring(button.forName), button.forLevel or 0), 1, 1, 1)
        GameTooltip:AddLine(string.format(L["In your bags: %d"], ns.Items.Count(button.rank.item)), 0.8, 0.8, 0.8)
        if button.stale then
            GameTooltip:AddLine(L["In combat: updates when combat ends."], 1, 0.3, 0.3, true)
        end
    else
        GameTooltip:AddLine(button.kind == "food" and L["Conjure Food"] or L["Conjure Water"], 1, 0.82, 0)
        GameTooltip:AddLine(L["You don't know a rank that this player can use yet."], 1, 0.3, 0.3, true)
    end
    GameTooltip:Show()
end

local function NewButton(name, kind, template)
    local button = CreateFrame("Button", name, bar, template)
    button.kind = kind
    button:SetSize(SIZE, SIZE)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    button.icon = icon
    local glow = button:CreateTexture(nil, "OVERLAY")
    glow:SetPoint("TOPLEFT", -4, 4)
    glow:SetPoint("BOTTOMRIGHT", 4, -4)
    glow:SetColorTexture(1, 0.6, 0.1, 0.35)
    glow:Hide()
    button.glow = glow
    local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", -2, 2)
    button.count = count
    local stale = button:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    stale:SetPoint("TOPLEFT", 2, -2)
    stale:SetText("*")
    stale:Hide()
    button.staleMark = stale
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetColorTexture(1, 1, 1, 0.15)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    buttons[kind] = button
    return button
end

local function SavePosition()
    local point, _, relativePoint, x, y = bar:GetPoint()
    ns.db.point = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function RestorePosition()
    bar:ClearAllPoints()
    local p = ns.db.point
    if p and p.point then
        bar:SetPoint(p.point, UIParent, p.relativePoint or p.point, p.x or 0, p.y or 0)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
    end
end

function Buttons.Create()
    if bar then return end
    bar = CreateFrame("Frame", "NullgatesFoodWaterBar", UIParent)
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self)
        if not ns.db.locked and not InCombatLockdown() then self:StartMoving() end
    end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(bar)
    background:SetColorTexture(0.08, 0.1, 0.13, 0.75)
    bar.background = background

    for _, kind in ipairs(KINDS) do
        local button = NewButton(kind == "food" and "NullgatesFoodWaterFood" or "NullgatesFoodWaterWater", kind,
            "SecureActionButtonTemplate")
        button:RegisterForClicks("AnyUp", "AnyDown")
        button:RegisterForDrag("LeftButton")
        button:SetScript("OnDragStart", function() bar:GetScript("OnDragStart")(bar) end)
        button:SetScript("OnDragStop", function() bar:GetScript("OnDragStop")(bar) end)
    end
    local trade = NewButton("NullgatesFoodWaterTrade", "trade")
    trade.icon:SetTexture(TRADE_ICON)
    trade:RegisterForClicks("LeftButtonUp")
    trade:SetScript("OnClick", function(self)
        ns.Trade.Click("target")
        if GameTooltip:IsOwned(self) then ShowTooltip(self) end
    end)

    RestorePosition()
    Buttons.Layout()
    Buttons.UpdateSpells()
end

function Buttons.Layout()
    if not bar then return end
    ns.WhenSafe("layout", function()
        local order = { buttons.food, buttons.water, buttons.trade }
        local vertical = ns.db.vertical
        for i, button in ipairs(order) do
            button:ClearAllPoints()
            local offset = GAP + (i - 1) * (SIZE + GAP)
            if vertical then
                button:SetPoint("TOP", bar, "TOP", 0, -offset)
            else
                button:SetPoint("LEFT", bar, "LEFT", offset, 0)
            end
        end
        local long, short = GAP + #order * (SIZE + GAP), SIZE + 2 * GAP
        if vertical then bar:SetSize(short, long) else bar:SetSize(long, short) end
        bar:SetScale(ns.db.scale or 1)
        bar.background:SetShown(not ns.db.locked)
        bar:Show()
    end)
    Buttons.UpdateCounts()
end

-- Chooses each button's rank for the current target and sets it as the button's spell.
function Buttons.UpdateSpells()
    if not bar then return end
    local applied = ns.WhenSafe("spells", function()
        local level, name = Buttons.LevelFor()
        for _, kind in ipairs(KINDS) do
            local button = buttons[kind]
            local rank = ns.Ranks.Pick(kind, level)
            button.rank, button.forLevel, button.forName = rank, level, name
            button:SetAttribute("type", rank and "spell" or nil)
            button:SetAttribute("spell", rank and rank.spell or nil)
            button.icon:SetTexture((rank and ns.Items.Icon(rank.item)) or FALLBACK_ICON[kind])
            button.icon:SetDesaturated(rank == nil)
            button.stale = false
            button.staleMark:Hide()
        end
        Buttons.UpdateCounts()
    end)
    if not applied then
        for _, kind in ipairs(KINDS) do
            buttons[kind].stale = true
            buttons[kind].staleMark:Show()
        end
    end
end

-- Item counts can change at any time, even in combat (they aren't protected).
function Buttons.UpdateCounts()
    if not bar then return end
    for _, kind in ipairs(KINDS) do
        local button = buttons[kind]
        local show = ns.db.showCount and button.rank
        button.count:SetText(show and ns.Items.Count(button.rank.item) or "")
    end
end

function Buttons.SetGlow(kind, on)
    if buttons[kind] then buttons[kind].glow:SetShown(on and true or false) end
end

function Buttons.ResetPosition()
    if not bar then return end
    ns.db.point = nil
    ns.WhenSafe("position", RestorePosition)
end
