# mod-trainers

An [AzerothCore](https://www.azerothcore.org/) (WotLK 3.3.5a) module that adds a GM
command to spawn permanent class trainer NPCs wherever you stand.

## Features

- `.trainer <class> [race] add` spawns a class trainer at your position and saves it
  to the world database, so it stays after a restart.
- One creature template per class and race (10 classes x 10 races, creature entries
  900100 to 900199). Models keep the chosen race and look like the class; weapons are
  chosen by class.
- Trainers are level 80, use faction 35 (friendly to everyone) and the stock class
  trainer spell lists (Death Knights: see [Requirements](#requirements)).
- `.trainer <class> [race] del` removes a targeted trainer, but only one this module
  spawned.

## Requirements

- AzerothCore WotLK (3.3.5a). Developed on the
  [mod-playerbots AzerothCore fork](https://github.com/mod-playerbots/azerothcore-wotlk)
  (`Playerbot` branch) and also works on stock
  [azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk) `master`. The SQL
  handles both the older `creature.id1` column and the `creature.id` column that
  AzerothCore uses since its 2026_06_16_00 update. No core patches are needed.
- [mod-dk](https://github.com/dudemcbro/mod-dk) for the Death Knight trainers. They
  use TrainerId 1013, which mod-dk creates (`mod_dk_03_trainer_spawns.sql`), so install
  mod-dk's SQL first. Without it those ten templates point at a trainer list that does
  not exist and offer no spells. To use the stock Death Knight trainer list instead,
  change `1013` to `13` in `data/sql/world/mod_trainers_templates.sql`. The
  worldserver applies the changed file on its next start.

## Installation

1. Clone the module into the core's `modules` directory:

   ```sh
   cd <azerothcore>/modules
   git clone https://github.com/dudemcbro/mod-trainers.git
   ```

2. Re-run CMake and rebuild the core.
3. Restart `worldserver`. It installs the module's SQL on start (see
   [Database setup](#database-setup)).

The module has no configuration file.

## Database setup

The module's SQL is in `data/sql/world/` (there is no characters or auth SQL).
`worldserver` imports it into the world database (usually `acore_world`) on start when
`Updates.EnableDatabases` in `worldserver.conf` includes the world database (flag `4`,
part of the default `7`). The updater records each file in that database's `updates`
table and applies it again when the file changes. The install can be run again safely.
Trainers that are already spawned pick up new models and equipment after a
`worldserver` restart.

The folder is called `world` rather than the skeleton module's `db-world` on purpose:
cores built before AzerothCore's April 2026 change to module SQL folder matching
([azerothcore-wotlk#25372](https://github.com/azerothcore/azerothcore-wotlk/pull/25372))
only import folders named exactly `world`, `characters` and `auth`, and newer cores
import both.

To apply the SQL by hand instead (for example when the updater is off for the world
database), run the files in `data/sql/world/` against the world database in name
order. There is only one, `mod_trainers_templates.sql`. From the root of your
AzerothCore source tree:

```sh
mysql -u <user> -p acore_world < modules/mod-trainers/data/sql/world/mod_trainers_templates.sql
```

## Usage

GM command (security level 2 or higher, in game only):

```
.trainer <class> [race] <add|del>
```

| Example | Result |
| --- | --- |
| `.trainer mage add` | Spawns a Mage trainer of a random race at your position |
| `.trainer warrior human add` | Spawns a human Warrior trainer |
| `.trainer mage del` | Removes the targeted Mage trainer |

- Classes: `warrior`, `paladin`, `hunter`, `rogue`, `priest`, `deathknight` (or `dk`),
  `shaman`, `mage`, `warlock`, `druid`.
- Races are single words: `human`, `dwarf`, `nightelf`, `gnome`, `draenei`, `orc`,
  `undead`, `tauren`, `troll`, `bloodelf`.
- `del` needs a targeted NPC of that class that this module spawned (its spawn comment
  starts with `mod-trainers:`). With a race given, the race has to match too.

## Updating

```sh
cd <azerothcore>/modules/mod-trainers
git pull
```

Re-run CMake, rebuild and restart `worldserver`. It applies new or changed SQL on
start. If you apply the SQL by hand, run the files in `data/sql/world/` again as
above before the restart.

### Upgrading from a manual install

Older versions kept the SQL in `sql/` and installed it by hand with `install.sql`. The
updater has no record of that, so `worldserver` runs `mod_trainers_templates.sql` once
on its next start. That is safe: it rebuilds the templates and keeps every trainer
spawned with `.trainer ... add`. To skip that run, mark the file as applied in the
world database before you start `worldserver`:

```sql
INSERT INTO updates (name, hash, state) VALUES ('mod_trainers_templates.sql', '', 'MODULE');
```

`worldserver` then only stores the file's hash (with `Updates.AllowRehash = 1`, the
default). Only do this if your database already has the current version of the SQL,
because a file marked this way is not applied again until it changes.

## Uninstall

Stop `worldserver`, then remove the templates and every trainer spawned with
`.trainer ... add` (from the root of your AzerothCore source tree):

```sh
mysql -u <user> -p acore_world < modules/mod-trainers/data/sql/rollback/world/mod_trainers_rollback.sql
```

`worldserver` never runs the rollback itself. The rollback also deletes the install's
row from the `updates` table, so the templates are installed again if you add the
module back later. Delete `modules/mod-trainers`, re-run CMake and rebuild before you
start `worldserver` again, or it installs them again right away.

## Contributing

Issues and pull requests are welcome. Work on a feature branch and open the pull
request against `main`. Commit messages follow
[Conventional Commits](https://www.conventionalcommits.org/) (`fix: ...`,
`feat: ...`, `docs: ...`).

## License

GNU General Public License v3.0, see [LICENSE](LICENSE).
