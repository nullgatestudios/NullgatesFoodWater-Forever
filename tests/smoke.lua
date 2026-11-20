-- Nullgate's Food & Water: smoke test of the addon files with stand-in game API.
-- Loads the files in .toc order, runs /nfw check and fires the events it listens to.
-- Run from the repository root:  lua tests/smoke.lua

local source = debug.getinfo(1, "S").source or ""
local script = source:match("^@(.*)$") or "tests/smoke.lua"
local scriptDir = script:match("^(.*)[/\\][^/\\]*$") or "."
local repo = scriptDir:match("^(.*)[/\\][^/\\]*$") or "."
local folder = "NullgatesFoodWater-Forever"
local root = repo .. "/" .. folder .. "/"

local checks, failures = 0, 0
local function OK(cond, name)
    checks = checks + 1
    if not cond then failures = failures + 1; print("FAIL " .. name) end
end

-- --- Stand-in game API ----------------------------------------------------------
local frames, printed = {}, {}
local function NewFrame(kind, name, parent, template)
    local f = { kind = kind, name = name, template = template, scripts = {}, attributes = {}, events = {}, shown = false }
    setmetatable(f, { __index = function(_, key)
        return function(self, ...) return nil end -- any other widget method: no-op
    end })
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:HookScript(k, fn) local old = self.scripts[k]; self.scripts[k] = function(...) if old then old(...) end fn(...) end end
    function f:RegisterEvent(e) self.events[e] = true end
    function f:UnregisterAllEvents() self.events = {} end
    function f:SetAttribute(k, v) self.attributes[k] = v end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:IsShown() return self.shown end
    function f:CreateFontString() return NewFrame("FontString") end
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
CreateFrame = NewFrame
SlashCmdList = {}
UIParent = NewFrame("Frame", "UIParent")
print = function(text) printed[#printed + 1] = tostring(text) end
function UnitClass() return "Mage", "MAGE" end
function UnitLevel() return 60 end
function UnitName(unit) return unit == "party1" and "Bob" or "Target" end
function UnitExists() return true end
function UnitIsPlayer() return true end
function GetBuildInfo() return "1.60.1", "70532", "Nov 2026", 16001 end
function InCombatLockdown() return false end
local knownSpells = { [5504] = true, [5505] = true, [10140] = true, [587] = true }
C_SpellBook = { IsSpellKnown = function(id) return knownSpells[id] == true end }
C_Spell = {
    GetSpellName = function(id) return id >= 5504 and id ~= 587 and "Conjure Water" or "Conjure Food" end,
    GetSpellSubtext = function() return "Rank 7" end,
}
C_Item = { GetItemInfo = function(id) return "Item " .. id, nil, nil, nil, (id == 8079) and 55 or nil end }
C_Timer = { After = function(_, fn) fn() end }
C_Container = { GetContainerItemID = function() return nil end, GetContainerNumSlots = function() return 16 end }
function InitiateTrade() end
function ClickTradeButton() end
function GetTradePlayerItemInfo() return nil end

-- --- Load the files in .toc order -----------------------------------------------
local ns = {}
local toc = assert(io.open(root .. folder .. ".toc", "r")):read("*a")
for line in toc:gmatch("[^\r\n]+") do
    if not line:match("^##") and line:match("%.lua$") then
        local chunk = assert(loadfile(root .. line:gsub("\\", "/")))
        chunk(folder, ns)
    end
end
OK(SlashCmdList and SlashCmdList.NULLGATESFOODWATER ~= nil, "the slash command is registered")
OK(SLASH_NULLGATESFOODWATER1 == "/nfw" and SLASH_NULLGATESFOODWATER2 == "/foodwater", "as /nfw and /foodwater")

-- ADDON_LOADED creates the saved data.
for _, f in ipairs(frames) do
    if f.events.ADDON_LOADED and f.scripts.OnEvent then f.scripts.OnEvent(f, "ADDON_LOADED", folder) end
end
OK(type(NullgatesFoodWaterDB) == "table", "ADDON_LOADED creates the saved data")

-- --- /nfw check ---------------------------------------------------------------
SlashCmdList.NULLGATESFOODWATER("check")
local log = NullgatesFoodWaterDB.check
OK(type(log) == "table" and #log > 10, "the check writes its log to the saved data")
local text = table.concat(log, "\n")
OK(text:find("C_SpellBook.IsSpellKnown=yes", 1, true) ~= nil, "it reports which calls exist")
OK(text:find("water: best known rank by Ranks.Pick = 10140", 1, true) ~= nil, "it reports the best known rank")
OK(text:find("item level ok", 1, true) ~= nil, "it compares item levels with the table")
OK(NullgatesFoodWaterCheck and NullgatesFoodWaterCheck.shown, "the check window opens")

local byID, byName, party
for _, f in ipairs(frames) do
    if f.attributes.type == "spell" and f.attributes.spell == 10140 then byID = f end
    if f.attributes.type == "spell" and type(f.attributes.spell) == "string" then byName = f end
    if f.attributes.type == "macro" then party = f end
end
OK(byID ~= nil, "button 1 casts the best water by spell ID")
OK(byName and byName.attributes.spell == "Conjure Water(Rank 7)", "button 2 casts it by name and rank")
OK(party and party.attributes.macrotext == "/target party1\n/cast Conjure Water(Rank 7)", "button 3 targets party1 and casts")

-- A click followed by the cast event is logged as OK.
local watcher
for _, f in ipairs(frames) do if f.events.UNIT_SPELLCAST_SUCCEEDED then watcher = f end end
byID.scripts.OnClick(byID)
watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 10140)
OK(NullgatesFoodWaterDB.check[#NullgatesFoodWaterDB.check]:find("-> OK", 1, true) ~= nil, "a matching cast is logged as OK")
byName.scripts.OnClick(byName)
watcher.scripts.OnEvent(watcher, "UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 5505)
OK(NullgatesFoodWaterDB.check[#NullgatesFoodWaterDB.check]:find("DIFFERENT RANK", 1, true) ~= nil, "a wrong rank is logged")
watcher.scripts.OnEvent(watcher, "ADDON_ACTION_BLOCKED", "NullgatesFoodWater-Forever", "ClickTradeButton()")
OK(NullgatesFoodWaterDB.check[#NullgatesFoodWaterDB.check]:find("ADDON_ACTION_BLOCKED", 1, true) ~= nil, "blocked actions are logged")

-- The plain buttons run without errors.
for _, f in ipairs(frames) do
    if f.template == "UIPanelButtonTemplate" and f.scripts.OnClick then f.scripts.OnClick(f) end
end
OK(NullgatesFoodWaterDB.check[#NullgatesFoodWaterDB.check]:find("trade:", 1, true) ~= nil, "the trade buttons log their result")

SlashCmdList.NULLGATESFOODWATER("")
OK(printed[#printed]:find("/nfw check", 1, true) ~= nil, "a bare /nfw lists the commands")

print = function(...) io.write(table.concat({ ... }, " "), "\n") end
print(string.format("smoke: %d checks, %d failure(s)", checks, failures))
if failures > 0 then os.exit(1) end
