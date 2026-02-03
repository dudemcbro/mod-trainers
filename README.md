mod-trainers
===========

Overview
--------
Spawns permanent, DB-backed class trainer NPCs at your current location.

The trainers are neutral-friendly to everyone and persist across restarts.
Class visuals are based on lore-appropriate major-city NPCs (casters look like casters, etc.).

Commands
--------
GM-only:

- `.trainer <class> <race?> <add|del>`

Examples:
- `.trainer mage add` (random race)
- `.trainer warrior human add`
- Target a spawned trainer, then: `.trainer mage del`

Notes
-----
- `del` only works on a targeted NPC, and only if it was spawned by this module.
- Race names are single tokens (use `bloodelf`, `nightelf`, etc.).

Install (world DB)
------------------
Apply to `acore_world`:

```
mysql < modules/mod-trainers/sql/install.sql
```

Rollback
--------

```
mysql < modules/mod-trainers/sql/rollback.sql
```
