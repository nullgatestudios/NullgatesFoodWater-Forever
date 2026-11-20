-- Nullgate's Food & Water: saved data, events, the out-of-combat queue and slash commands.
local addonName, ns = ...

local L = ns.L

ns.DEFAULTS = {
    locked = false,
    vertical = false,
    showCount = true,
    scale = 1,
    tradeStacks = 1,
    groupShown = false,
    lowStock = { enabled = true, threshold = 10, chat = true, sound = false, glow = true },
}

local function Merge(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            Merge(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function ns.Print(text)
    print("|cff00c0ffFood & Water:|r " .. tostring(text))
end

function ns.IsMage()
    local _, class = UnitClass("player")
    return class == "MAGE"
end

-- Runs fn now when out of combat; in combat it runs once combat ends (the latest fn per
-- key wins). Returns true when fn ran now.
local pending = {}
function ns.WhenSafe(key, fn)
    if InCombatLockdown() then
        pending[key] = fn
        return false
    end
    pending[key] = nil
    fn()
    return true
end

-- Key bindings (Bindings.xml) for the secure buttons.
BINDING_HEADER_NULLGATESFOODWATER = "Nullgate's Food & Water"
_G["BINDING_NAME_CLICK NullgatesFoodWaterFood:LeftButton"] = L["Conjure food for your target"]
_G["BINDING_NAME_CLICK NullgatesFoodWaterWater:LeftButton"] = L["Conjure water for your target"]

local events = CreateFrame("Frame")
local active = false -- the bar and its events run for mages only

local function OnEvent(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            if type(NullgatesFoodWaterDB) ~= "table" then NullgatesFoodWaterDB = {} end
            Merge(NullgatesFoodWaterDB, ns.DEFAULTS)
            ns.db = NullgatesFoodWaterDB
        end
        if arg1 == addonName or arg1 == "NullgatesAddonConfig-Forever" then ns.Options.RegisterHub() end
    elseif event == "PLAYER_LOGIN" then
        active = ns.IsMage()
        if active then
            ns.Buttons.Create()
            ns.Group.Init()
            ns.Stock.Check()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        for key, fn in pairs(pending) do
            pending[key] = nil
            fn()
        end
    elseif not active then
        return
    elseif event == "BAG_UPDATE_DELAYED" then
        ns.Buttons.UpdateCounts()
        ns.Stock.Check()
    elseif event == "GROUP_ROSTER_UPDATE" then
        ns.Group.Refresh()
    elseif event == "UNIT_LEVEL" then
        if arg1 == "target" then ns.Buttons.UpdateSpells() end
        ns.Group.Refresh()
    else -- target change, level-up, new spells
        ns.Buttons.UpdateSpells()
        ns.Group.Refresh()
    end
end

events:SetScript("OnEvent", OnEvent)
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "PLAYER_TARGET_CHANGED",
    "PLAYER_LEVEL_UP", "SPELLS_CHANGED", "UNIT_LEVEL", "BAG_UPDATE_DELAYED", "GROUP_ROSTER_UPDATE" }) do
    events:RegisterEvent(event)
end

local function Help()
    ns.Print(L["commands:"])
    print("  /nfw - " .. L["open the settings"])
    print("  /nfw group - " .. L["show or hide the group view"])
    print("  /nfw lock | unlock - " .. L["lock or unlock the bar"])
    print("  /nfw reset - " .. L["reset the bar's position"])
    print("  /nfw check - " .. L["test what the addon needs in this client (results are saved)"])
end

SLASH_NULLGATESFOODWATER1 = "/nfw"
SLASH_NULLGATESFOODWATER2 = "/foodwater"
SlashCmdList["NULLGATESFOODWATER"] = function(msg)
    local command = string.lower((msg or ""):match("^%s*(%S*)") or "")
    if command == "check" then
        ns.Check.Run()
    elseif command == "help" then
        Help()
    elseif not active then
        ns.Print(L["This addon is for mages; only /nfw check works on other classes."])
    elseif command == "" or command == "options" or command == "config" then
        ns.Options.Open()
    elseif command == "group" then
        ns.Group.Toggle()
    elseif command == "lock" or command == "unlock" then
        ns.db.locked = command == "lock"
        ns.Buttons.Layout()
    elseif command == "reset" then
        ns.Buttons.ResetPosition()
    else
        Help()
    end
end
