-- atena-bridge-clothing — SERVER: register clothing's garment item-types on the std-inventory ENGINE.
-- The standalone stays pure: it only EXPOSES its type defs as data (standalone-resource §2.0). The
-- cross-resource LINK (clothing ↔ inventory) lives here, in the bridge — the only resource allowed to
-- depend on more than one. No permanent bail (bridge-registration §2): bind the registration always,
-- gate the cross-resource calls at call-time, re-arm on (re)start of either side (an engine restart
-- resets its type registry). pcall: a re-arm can fire while an export host is mid-restart.
local function bothUp() return GetResourceState('std-clothing') == 'started' and GetResourceState('std-inventory') == 'started' end

local function register()
    if not bothUp() then return end
    pcall(function()
        local types = exports['std-clothing']:itemTypes() or {}
        for name, view in pairs(types) do
            exports['std-inventory']:inventoryRegisterType(name, view.def)
        end
    end)
end

-- (1) THREAD: bounded one-shot poll → first register, race-proof (BOTH std must be up). Exits when done.
CreateThread(function()
    while not bothUp() do Wait(250) end
    register()
end)

-- (2) EVENTS: either std (re)start resets/re-arms → re-register; our own start re-arms too.
AddEventHandler('onResourceStart', function(res)
    if res == 'std-clothing' or res == 'std-inventory' or res == GetCurrentResourceName() then register() end
end)

-- ── In-game self-test: exercises the cross-resource wiring this bridge owns (every garment sub-type
-- clothing exposes ends up registered on the engine with the right tags). Lives in the bridge, not the
-- standalone (the standalone can't reach the engine). Gated with atena's authority; console src=0 ok.
local function canDebug(src)
    if src == 0 then return true end
    return GetResourceState('atena') == 'started' and exports.atena:can(src, 'debug')
end
local function hasTag(tags, want)
    for _, t in ipairs(tags or {}) do if t == want then return true end end
    return false
end
local function runTest()
    if not bothUp() then print('[clothing test] SKIP std-clothing/std-inventory not started'); return end
    local inv = exports['std-inventory']
    local results = {}
    local function check(name, cond) results[#results + 1] = ((cond and 'PASS' or 'FAIL') .. ' ' .. name) end

    -- every garment sub-type is registered on the engine with the right tags
    local types = exports['std-clothing']:itemTypes() or {}
    for name, view in pairs(types) do
        local d = inv:inventoryTypeDef(name)
        check(('type %s registered'):format(name), d ~= nil)
        check(('type %s tagged garment+%s'):format(name, view.category),
            d ~= nil and hasTag(d.tags, 'garment') and hasTag(d.tags, view.category))
    end

    -- container features: jacket exposes a `pocket` slot (capacity), radio_vest a LOCKED `radio` slot
    local jdef = inv:inventoryTypeDef('jacket')
    check('jacket has pocket slot (capacity 2)', jdef and jdef.slots and jdef.slots.pocket
        and jdef.slots.pocket.capacity == 2.0)
    local vdef = inv:inventoryTypeDef('radio_vest')
    check('radio_vest has LOCKED radio slot accepting radio', vdef and vdef.slots and vdef.slots.radio
        and vdef.slots.radio.lock == true)

    -- functional: a small item goes INTO a jacket pocket (nested graph); a radio locked in the vest can't leave
    inv:inventoryRegisterType('test_small', { size = 0.5, tags = { 'small' } })
    inv:inventoryRegisterType('radio', { size = 0.5, tags = { 'radio' } })   -- temp stand-in for std-radio
    local jacket = inv:inventoryCreate('jacket', inv:inventoryLoc('owner', 'clothing_test'))
    local small  = inv:inventoryCreate('test_small', inv:inventoryLoc('owner', 'clothing_test'))
    check('item moved into jacket pocket', jacket and small
        and inv:inventoryMove(small.id, inv:inventoryLoc('container', jacket.id, 'pocket')) == true)
    local vest  = inv:inventoryCreate('radio_vest', inv:inventoryLoc('owner', 'clothing_test'))
    local radio = inv:inventoryCreate('radio', inv:inventoryLoc('owner', 'clothing_test'))
    check('radio locked into vest', vest and radio
        and inv:inventoryMove(radio.id, inv:inventoryLoc('container', vest.id, 'radio')) == true)
    check('locked radio cannot be removed', radio
        and inv:inventoryMove(radio.id, inv:inventoryLoc('owner', 'clothing_test')) == false)
    for _, e in ipairs({ jacket, small, vest, radio }) do if e then inv:inventoryDestroy(e.id) end end

    -- vestizione = an inventory MOVE: a garment goes onto a custodia worn slot that accepts its category;
    -- a wrong-category garment is refused. This is the 60.1 model — wearing passes through inventory move,
    -- not a clothing-owned worn state. (A minimal body type stands in for std-custodia, which may be down.)
    inv:inventoryRegisterType('test_body', { size = 0.0, tags = { 'body' },
        slots = { torso = { acceptTags = { 'topwear' } }, head = { acceptTags = { 'headwear' } } } })
    local body  = inv:inventoryCreate('test_body', inv:inventoryLoc('owner', 'clothing_test'))
    local coat  = inv:inventoryCreate('jacket', inv:inventoryLoc('owner', 'clothing_test'))
    local cap   = inv:inventoryCreate('hat', inv:inventoryLoc('owner', 'clothing_test'))
    check('garment worn via move (jacket -> torso)', body and coat
        and inv:inventoryMove(coat.id, inv:inventoryLoc('container', body.id, 'torso')) == true)
    check('wrong-category garment refused (hat -> torso)', body and cap
        and inv:inventoryMove(cap.id, inv:inventoryLoc('container', body.id, 'torso')) == false)
    for _, e in ipairs({ body, coat, cap }) do if e then inv:inventoryDestroy(e.id) end end

    for _, line in ipairs(results) do print('[clothing test] ' .. line) end
end
RegisterCommand('clothing_test', function(src) if canDebug(src) then runTest() end end, false)
