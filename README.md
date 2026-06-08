# clothing-bridges

Integration bridges for the `std-clothing` standalone resource, one per framework.

| Framework | Bridge | Status |
|-----------|--------|--------|
| atena     | `atena-bridge-clothing` | present |
| ESX       | `esx-bridge-clothing`   | planned |
| QBCore    | `qbcore-bridge-clothing`| planned |
| OX        | `ox-bridge-clothing`    | planned |

Each bridge is integration glue (calls `exports['std-clothing']:*` + the framework's API). The standalone
stays pure/agnostic; the bridge does the wiring. Advanced atena-only mechanics that a framework can't map
are left as a documented comment in that framework's bridge.

Install the standalone (`std-clothing`) + the ONE bridge matching your framework.

## Get the standalone (required)

This bridge is free integration glue and needs the **std-clothing** standalone resource (sold separately):

➡️ **https://github.com/atena-studio/std-clothing**
