# shed Internals: Session Implementation

## Session Propagation Flow

shed daemon (parent)
├─ parse $1 (session name)
├─ is_str_valid check
├─ export SHED_SESSION
├─ write shed.session file
├─ source libshed.sh
│ └─ SESSBASE="${SHED_SESSION}" (if set)
│ └─ ServicesDir uses SESSBASE
│ └─ ComponentsDir uses SESSBASE
│ └─ ... all dirs use SESSBASE
└─ exec services/components
└─ inherit SHED_SESSION ✓
└─ shedc also inherits ✓

shedc client (child/descendant)
├─ requires shed daemon ancestor (SHED_SESSION must be in env)
├─ source libshed.sh
│ └─ SHED_SESSION already set → skip recovery
│ └─ SESSBASE computed from inherited value
│ └─ all paths align with daemon
└─ communicate via session socket

## Key Invariants

- `SHED_SESSION` flows down process tree only (parent → children)
- `SESSBASE` computed identically in shed.sh and libshed.sh
- "default" session = empty SESSBASE (backward compat)
- shed.session file persists value across daemon reloads
