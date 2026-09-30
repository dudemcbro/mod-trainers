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
  use TrainerId 1013, which mod-dk creates (`dk_trainer_spawns.sql`), so install
  mod-dk's SQL first. Without it those ten templates point at a trainer list that does
  not exist and offer no spells. To use the stock Death Knight trainer list instead,
  change `1013` to `13` in `sql/db_world/base/trainers_templates.sql` before applying
  it.

## Installation

1. Clone the module into the core's `modules` directory:

   ```sh
   cd <azerothcore>/modules
   git clone https://github.com/dudemcbro/mod-trainers.git
   ```

2. Re-run CMake and rebuild the core.
3. Set up the database (below) and restart `worldserver`.

The module has no configuration file.

## Database setup

The worldserver's updater only imports a module's `data/sql/world`,
`data/sql/characters` and `data/sql/auth` folders. This module keeps its SQL in
`sql/db_world/base/`, so apply it by hand to the world database (usually
`acore_world`). Run this from the root of your AzerothCore source tree, because
`install.sql` uses `SOURCE` with paths relative to it:

```sh
mysql -u <user> -p acore_world < modules/mod-trainers/sql/install.sql
```

The install can be run again safely. Trainers that are already spawned pick up new
models and equipment after a `worldserver` restart.

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

Re-run CMake, rebuild, run `install.sql` again as above and restart `worldserver`.

## Uninstall

Remove the templates and every trainer spawned with `.trainer ... add` (from the root
of your AzerothCore source tree):

```sh
mysql -u <user> -p acore_world < modules/mod-trainers/sql/rollback.sql
```

Then delete `modules/mod-trainers`, re-run CMake and rebuild.

## Contributing

Issues and pull requests are welcome. Work on a feature branch and open the pull
request against `main`. Commit messages follow
[Conventional Commits](https://www.conventionalcommits.org/) (`fix: ...`,
`feat: ...`, `docs: ...`).

## License

GNU General Public License v3.0, see [LICENSE](LICENSE).
