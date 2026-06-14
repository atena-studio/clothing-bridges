-- atena-bridge-clothing — SERVER: fill `clothing`'s seams with atena's policy. NO permanent bail at load
-- (bridge-registration.md §5a): bind handlers ALWAYS, gate cross-resource calls at call-time, re-arm on
-- (re)start. pcall: a re-arm can fire while clothing's export host is mid-restart → swallow the transient.
-- (clothing v0.1 has no persistence → no dbMigrate yet; add when it stores data.)
local function arm()
    if GetResourceState('std-clothing') ~= 'started' then return end
    pcall(function()
        exports['std-clothing']:setAuthorizer(function(src, _action) return exports.atena:can(src, 'debug') end)
        exports['std-clothing']:setGuard(function(opts, src, args) return exports.atena:checkInbound(opts, src, args) end)
    end)
end
arm()
AddEventHandler('onResourceStart', function(res) if res == 'atena' or res == 'std-clothing' then arm() end end)

-- TODO (insulation seam): fill exports['std-clothing']:setInsulationProvider(fn) so worn-garment warmth
-- becomes server-authoritative. fn(src) must resolve src → the player's custodia → its worn garment ITEMS
-- (std-inventory graph) → sum each item's type insulation (exports['std-clothing']:itemTypes()[item.type]
-- .insulation), take the BEST waterproof, clamp the sum to Config.maxInsulation, and return (insulation,
-- bestWaterproof). Blocked on the player↔custodia binding (atena-bridge-custodia TODO: bind bodies to
-- Atena.Players). Until then the standalone default (0,0) applies — thermal runs on environment only, no
-- clothing warmth. Wire here once a src→custodia resolver exists.
