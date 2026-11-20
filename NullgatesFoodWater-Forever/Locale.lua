-- Nullgate's Food & Water: text lookup. Every user-facing string goes through ns.L["English text"].
-- This beta ships English only; a missing key falls back to the English text, so
-- language packs can be added later without touching the code.
local _, ns = ...

ns.L = setmetatable({}, { __index = function(_, key) return key end })
