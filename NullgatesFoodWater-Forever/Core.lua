-- Nullgate's Food & Water: saved data and slash commands.
local addonName, ns = ...

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterAllEvents()
    if type(NullgatesFoodWaterDB) ~= "table" then NullgatesFoodWaterDB = {} end
end)

local function Help()
    print("|cff00c0ffNullgate's Food & Water|r commands:")
    print("  /nfw check - test what the addon needs in this client (results are saved)")
end

SLASH_NULLGATESFOODWATER1 = "/nfw"
SLASH_NULLGATESFOODWATER2 = "/foodwater"
SlashCmdList["NULLGATESFOODWATER"] = function(msg)
    local command = string.lower((msg or ""):match("^%s*(%S*)") or "")
    if command == "check" then
        ns.Check.Run()
    else
        Help()
    end
end
