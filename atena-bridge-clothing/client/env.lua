-- atena-bridge-clothing — CLIENT: feed clothing's ENVIRONMENT seam from `weather` (the contact point). weather is
-- soft: if it's down the provider returns nil → clothing falls back to its neutral default (works alone).
-- No permanent bail; inject when clothing is up, re-inject on (re)start of clothing/weather.
local function arm()
    if GetResourceState('std-clothing') ~= 'started' then return end
    pcall(function()
        exports['std-clothing']:setEnvironmentProvider(function()
            if GetResourceState('std-weather') ~= 'started' then return nil end
            local ok, e = pcall(function() return exports['std-weather']:environment() end)
            return (ok and e) or nil
        end)
    end)
end
arm()
AddEventHandler('onResourceStart', function(res) if res == 'std-clothing' or res == 'std-weather' then arm() end end)
