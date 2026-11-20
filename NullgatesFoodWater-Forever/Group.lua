-- Nullgate's Food & Water: the group view. Lists your party or raid members with the
-- food and water rank each one needs. Each row's Food and Water buttons conjure that
-- member's rank (conjuring doesn't need a target), and Trade opens a trade with them.
-- Rows are secure buttons, so the list only changes out of combat.
local _, ns = ...

local L = ns.L
local Group = {}
ns.Group = Group

local ROW_HEIGHT, MAX_ROWS = 26, 40
local panel, content, summary
local rows = {}

-- The other members of your group: { unit =, name =, level =, class = }.
function Group.Members()
    local list = {}
    local raid = IsInRaid and IsInRaid()
    local count = raid and GetNumGroupMembers() or (GetNumSubgroupMembers and GetNumSubgroupMembers() or 0)
    for i = 1, count do
        local unit = (raid and "raid" or "party") .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            local _, class = UnitClass(unit)
            list[#list + 1] = { unit = unit, name = UnitName(unit), level = UnitLevel(unit), class = class }
        end
    end
    table.sort(list, function(a, b) return (a.level or 0) > (b.level or 0) end)
    return list
end

-- How many members need each item: { food = { { item =, count = } }, water = { ... } }, most needed first.
function Group.Summary(members)
    local result = {}
    for _, kind in ipairs({ "food", "water" }) do
        local byItem, list = {}, {}
        for _, member in ipairs(members) do
            local rank = ns.Ranks.Pick(kind, member.level)
            if rank then byItem[rank.item] = (byItem[rank.item] or 0) + 1 end
        end
        for item, count in pairs(byItem) do list[#list + 1] = { item = item, count = count } end
        table.sort(list, function(a, b)
            if a.count ~= b.count then return a.count > b.count end
            return a.item < b.item
        end)
        result[kind] = list
    end
    return result
end

local function SummaryText(members)
    if #members == 0 then return L["You're not in a group."] end
    local parts = {}
    for _, kind in ipairs({ "food", "water" }) do
        local items = {}
        for _, entry in ipairs(Group.Summary(members)[kind]) do
            items[#items + 1] = string.format("%d x %s", entry.count, ns.Items.Name(entry.item) or ("#" .. entry.item))
        end
        parts[#parts + 1] = (kind == "food" and L["Food: "] or L["Water: "]) .. (#items > 0 and table.concat(items, ", ") or "-")
    end
    return table.concat(parts, "\n")
end

local function RowButton(row, kind, x)
    local template = kind ~= "trade" and "SecureActionButtonTemplate" or nil
    local button = CreateFrame("Button", nil, row, template)
    button:SetSize(22, 22)
    button:SetPoint("RIGHT", row, "RIGHT", x, 0)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    button.icon = icon
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetColorTexture(1, 1, 1, 0.2)
    if template then button:RegisterForClicks("AnyUp", "AnyDown") end
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if kind == "trade" then
            GameTooltip:AddLine(string.format(L["Trade with %s"], tostring(row.member and row.member.name)), 1, 0.82, 0)
        elseif self.rank then
            GameTooltip:AddLine(ns.Items.Name(self.rank.item) or L["Conjured item"], 1, 0.82, 0)
            GameTooltip:AddLine(string.format(L["In your bags: %d"], ns.Items.Count(self.rank.item)), 0.8, 0.8, 0.8)
        else
            GameTooltip:AddLine(L["You don't know a rank that this player can use yet."], 1, 0.3, 0.3, true)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

local function NewRow(index)
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(280, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.name:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.name:SetWidth(150)
    row.name:SetJustifyH("LEFT")
    row.level = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.level:SetPoint("LEFT", row, "LEFT", 158, 0)
    row.food = RowButton(row, "food", -56)
    row.water = RowButton(row, "water", -30)
    row.trade = RowButton(row, "trade", -4)
    row.trade.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
    row.trade:SetScript("OnClick", function()
        if row.member then ns.Trade.Click(row.member.unit) end
    end)
    rows[index] = row
    return row
end

local function SetRowSpell(button, kind, level)
    local rank = ns.Ranks.Pick(kind, level)
    button.rank = rank
    button:SetAttribute("type", rank and "spell" or nil)
    button:SetAttribute("spell", rank and rank.spell or nil)
    button.icon:SetTexture((rank and ns.Items.Icon(rank.item)) or
        (kind == "food" and "Interface\\Icons\\INV_Misc_Food_08" or "Interface\\Icons\\INV_Drink_18"))
    button.icon:SetDesaturated(rank == nil)
end

function Group.Refresh()
    if not (panel and panel:IsShown()) then return end
    local members = Group.Members()
    summary:SetText(SummaryText(members))
    ns.WhenSafe("group", function()
        for i = 1, math.min(#members, MAX_ROWS) do
            local row = rows[i] or NewRow(i)
            local member = members[i]
            row.member = member
            local color = member.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[member.class]
            row.name:SetText(member.name or "?")
            if color then row.name:SetTextColor(color.r, color.g, color.b) else row.name:SetTextColor(1, 1, 1) end
            row.level:SetText(string.format(L["Lv %d"], member.level or 0))
            SetRowSpell(row.food, "food", member.level)
            SetRowSpell(row.water, "water", member.level)
            row:Show()
        end
        for i = #members + 1, #rows do
            rows[i].member = nil
            rows[i]:Hide()
        end
        content:SetHeight(math.max(1, math.min(#members, MAX_ROWS) * ROW_HEIGHT))
    end)
end

local function Build()
    panel = CreateFrame("Frame", "NullgatesFoodWaterGroup", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(320, 340)
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        ns.db.groupPoint = { point = point, relativePoint = relativePoint, x = x, y = y }
    end)
    panel:SetScript("OnHide", function() ns.db.groupShown = false end)
    local p = ns.db.groupPoint
    if p and p.point then panel:SetPoint(p.point, UIParent, p.relativePoint or p.point, p.x or 0, p.y or 0)
    else panel:SetPoint("CENTER", UIParent, "CENTER", 300, 0) end
    local title = L["Food & Water: Group"]
    if type(panel.SetTitle) == "function" then panel:SetTitle(title)
    elseif type(panel.TitleText) == "table" then panel.TitleText:SetText(title) end

    summary = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    summary:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -32)
    summary:SetWidth(290)
    summary:SetJustifyH("LEFT")
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -66)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 10)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(280, 1)
    scroll:SetScrollChild(content)
end

function Group.Show()
    if not ns.WhenSafe("groupShow", function()
        if not panel then Build() end
        panel:Show()
        ns.db.groupShown = true
        Group.Refresh()
    end) then
        ns.Print(L["The group view opens when combat ends."])
    end
end

function Group.Toggle()
    if panel and panel:IsShown() then
        ns.WhenSafe("groupShow", function() panel:Hide() end)
    else
        Group.Show()
    end
end

function Group.Init()
    if ns.db.groupShown then Group.Show() end
end
