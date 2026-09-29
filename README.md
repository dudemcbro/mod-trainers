mod-trainers
===========

Overview
--------
Spawns permanent, DB-backed class trainer NPCs at your current location.

The trainers are neutral-friendly to everyone and persist across restarts.
Trainer visuals are race-preserving and class-appropriate; equipped weapons are class-based.

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

Requirements
------------
- The Death Knight trainers use TrainerId 1013, which is created by
  [mod-dk](https://github.com/dudemcbro/mod-dk) (`dk_trainer_spawns.sql`).
  Install mod-dk's SQL first. Without it those ten templates point at a
  trainer that does not exist and offer no spells. To use the stock DK
  trainer list instead, change `1013` to `13` in
  `sql/db_world/base/trainers_templates.sql`.

Install (world DB)
------------------
The SQL lives in `sql/db_world/base/` and is NOT picked up by the AzerothCore
DB auto-updater (it only reads `data/sql/db-world/` inside a module), so apply
it manually. Run this from the root of your AzerothCore source tree (the file
uses `SOURCE` with paths relative to it) and name the world database:

```
mysql -u <user> -p acore_world < modules/mod-trainers/sql/install.sql
```

The install is re-runnable. Templates use creature entries 900100-900199.

For already-spawned mod trainers, restart `worldserver` (or reload creature templates) so live NPCs pick up the new visual/equipment templates.

Rollback
--------

Removes the templates and every trainer spawned with `.trainer ... add`:

```
mysql -u <user> -p acore_world < modules/mod-trainers/sql/rollback.sql
```
