-- Nullgate's Food & Water: picks the Conjure Food or Conjure Water rank for a level.
-- Pure module: the rank table comes from Data/ConjureRanks.lua and whether a spell
-- is known is asked through Ranks.IsKnown, which tests replace.
local _, ns = ...

local Ranks = {}
ns.Ranks = Ranks

-- True when the player knows this exact rank. Classic clients report each rank's
-- spell ID separately; IsPlayerSpell is the fallback on clients without IsSpellKnown.
function Ranks.IsKnown(spellID)
    local known = IsSpellKnown or IsPlayerSpell
    return known ~= nil and known(spellID) == true
end

-- Whether rank a beats rank b: the better item first, then more items per cast.
local function Better(a, b)
    if a.itemLevel ~= b.itemLevel then return a.itemLevel > b.itemLevel end
    if a.count ~= b.count then return a.count > b.count end
    return a.learnLevel > b.learnLevel
end

-- The best rank of kind ("food" or "water") that the player knows and whose item a
-- character of `level` can use, or nil (unknown kind, no usable level, or no rank known).
function Ranks.Pick(kind, level)
    local list = ns.CONJURE_RANKS and ns.CONJURE_RANKS[kind]
    level = tonumber(level)
    if not list or not level or level < 1 then return nil end
    local best
    for _, rank in ipairs(list) do
        if rank.itemLevel <= level and Ranks.IsKnown(rank.spell) and (not best or Better(rank, best)) then
            best = rank
        end
    end
    return best
end
