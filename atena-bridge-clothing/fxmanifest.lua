-- atena-bridge-clothing — glue between the standalone `clothing` and atena + `weather`. Feeds clothing's
-- ENVIRONMENT seam from weather:environment (the contact point), fills its auth/guard seams with atena's
-- policy, and hosts the thermal debug card. Inert unless the resources are up (runtime-detection, no hard
-- deps). atena-framework §6 (bridge doctrine) — bridge is EXEMPT from vouch anti-bias.

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'atena-bridge-clothing'
author 'SirTheo'
description 'Bridge: clothing ↔ atena (+ weather environment). Seams + thermal debug.'
version '0.0.1'

server_scripts {
    'server/main.lua',          -- seams: authorizer + inbound guard (atena's policy)
    'server/register.lua',      -- register clothing's garment item-types on the std-inventory engine
}
client_scripts {
    'client/env.lua',           -- feed clothing's environment seam from weather:environment
    'client/debug.lua',         -- thermal debug card (atena window manager)
}
