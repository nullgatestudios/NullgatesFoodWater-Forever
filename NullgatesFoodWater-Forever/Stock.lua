-- Nullgate's Food & Water: the low-stock warning. When your own conjured food or water
-- drops below the threshold you set, it reminds you once (chat line, short sound,
-- glow on the button), and not again until you've restocked. Quiet in combat.
local _, ns = ...

local L = ns.L
local Stock = {}
ns.Stock = Stock

local warned = {}

-- Pure decision: given the count, threshold and whether a warning is already out,
-- returns (isLow, shouldWarnNow).
function Stock.Decide(count, threshold, alreadyWarned)
    local low = threshold > 0 and count < threshold
    return low, low and not alreadyWarned
end

local function Warn(kind, count)
    local settings = ns.db.lowStock
    if settings.chat then
        ns.Print(string.format(kind == "food" and L["Low on conjured food: %d left."] or L["Low on conjured water: %d left."], count))
    end
    if settings.sound and PlaySound then
        PlaySound((SOUNDKIT and SOUNDKIT.TELL_MESSAGE) or 3081, "Master")
    end
end

function Stock.Check()
    local settings = ns.db and ns.db.lowStock
    if not settings then return end
    if InCombatLockdown() then
        ns.WhenSafe("stock", Stock.Check)
        return
    end
    for _, kind in ipairs({ "food", "water" }) do
        -- Only for kinds you can actually conjure at your level.
        local canConjure = settings.enabled and ns.Ranks.Pick(kind, UnitLevel("player")) ~= nil
        local count = ns.Items.TotalOf(kind)
        local low, warnNow = Stock.Decide(count, canConjure and (settings.threshold or 0) or 0, warned[kind])
        if warnNow then Warn(kind, count) end
        warned[kind] = low
        ns.Buttons.SetGlow(kind, low and settings.glow)
    end
end
