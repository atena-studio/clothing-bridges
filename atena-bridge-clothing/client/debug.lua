-- atena-bridge-clothing — CLIENT: thermal debug card (atena window manager). READS the authoritative state
-- (LocalPlayer.state.clothingTemp) → body temp, status, target, insulation, activity, wetness. View-only.
-- ROBUST REGISTRATION (no permanent bail; thread + events).

local OPEN_ID, PANEL = 'std-clothing:open', 'std-clothing:panel'
local open = false
local function atenaUp()    return GetResourceState('atena') == 'started' end

local function rows()
    local st = LocalPlayer.state.clothingTemp or {}
    local t = st.t
    local status = (not t and '—')
        or (t < 0.0 and 'HYPOTHERMIA') or (t > 40.0 and 'HEATSTROKE')
        or (t < 12.0 and 'cold') or (t > 30.0 and 'hot') or 'comfort'
    local r = {
        { key = 'body temp',  value = t and ('%.1f°C'):format(t) or '—', tone = 'accent' },
        { key = 'status',     value = status,
          tone = ((status == 'HYPOTHERMIA' or status == 'HEATSTROKE') and 'warn') or (status == 'comfort' and 'green') or 'dim' },
        { key = 'target',     value = st.target and ('%.1f°C'):format(st.target) or '—', tone = 'dim' },
        { key = 'insulation', value = ('%.1f'):format(st.ins or 0.0), tone = 'dim' },
        { key = 'activity',   value = ('+%.1f°C'):format(st.act or 0.0), tone = 'dim' },
        { key = 'wetness',    value = ('%.0f%%'):format((st.wet or 0.0) * 100.0), tone = ((st.wet or 0) > 0.05 and 'warn' or 'dim') },
    }
    return r
end

local function push() if open and atenaUp() then exports.atena:uiDebugPanel(PANEL, { title = 'CLOTHING', rows = rows() }) end end
local function close() if atenaUp() then exports.atena:uiDebugPanel(PANEL, nil) end end

-- registration (robust: thread one-shot + events) — bridge-registration.md.
-- toggle entry: the launcher badge mirrors whether the card is open (debugSet keeps it true).
local function reg() if atenaUp() then exports.atena:debugAdd({ id = OPEN_ID, group = 'world', label = 'Clothing', icon = 'shirt', toggle = true, value = open, peekWin = PANEL }) end end
local function badge() if atenaUp() then exports.atena:debugSet(OPEN_ID, open) end end
CreateThread(function() while not atenaUp() do Wait(250) end; reg() end)
AddEventHandler('onResourceStart', function(res) if res == 'atena' then reg() end end)
AddEventHandler('atena:debug:ready', reg)
AddEventHandler('atena:debug:refresh', reg)

AddEventHandler('atena:debug:invoke', function(id)
    if id ~= OPEN_ID then return end
    open = not open
    if open then exports.atena:uiDebugArrange(true); push() else close() end
    badge()
end)
AddEventHandler('atena:debug:panelClosed', function(p) if p == PANEL then open = false; badge() end end)
CreateThread(function() while true do if open then push() end; Wait(2000) end end)

-- hover-PEEK (view-only): render the card content WITHOUT opening it for real (no open flag, no
-- badge); peekEnd clears it. The real open / live refresh belong to invoke (pin).
AddEventHandler('atena:debug:peek', function(win)
    if win == PANEL and not open and atenaUp() then exports.atena:uiDebugPanel(PANEL, { title = 'CLOTHING', rows = rows() }) end
end)
AddEventHandler('atena:debug:peekEnd', function(win)
    if win == PANEL and not open and atenaUp() then exports.atena:uiDebugPanel(PANEL, nil) end
end)

-- dev command: wear a visor helmet (prop slot 0) on the local ped, to test garment/insulation lookups.
-- /helmet [drawable] [texture] → wear (defaults: freemode-male visor helmet); /helmet off → remove.
RegisterCommand('helmet', function(_, args)
    local ped = PlayerPedId()
    if args[1] == 'off' then ClearPedProp(ped, 0) return end
    local drawable = tonumber(args[1]) or 91
    local texture  = tonumber(args[2]) or 0
    -- bound to the model's actual drawable count (model-dependent: ids differ per ped).
    if drawable < 0 or drawable >= GetNumberOfPedPropDrawableVariations(ped, 0) then return end
    SetPedPropIndex(ped, 0, drawable, texture, true)
end, false)

-- dev command: wear a mask — masks are a COMPONENT (slot 1, "berd"), not a prop like helmets.
-- /mask [drawable] [texture] → wear; /mask off → bare face (drawable 0).
RegisterCommand('mask', function(_, args)
    local ped = PlayerPedId()
    if args[1] == 'off' then SetPedComponentVariation(ped, 1, 0, 0, 0) return end
    local drawable = tonumber(args[1]) or 0
    local texture  = tonumber(args[2]) or 0
    -- bound to the model's actual drawable count (model-dependent: ids differ per ped).
    if drawable < 0 or drawable >= GetNumberOfPedDrawableVariations(ped, 1) then return end
    SetPedComponentVariation(ped, 1, drawable, texture, 0)
end, false)
