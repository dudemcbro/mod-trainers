# mod-trainers

<img src="icon.png" alt="" width="64" align="right">

An [AzerothCore](https://www.azerothcore.org/) (WotLK 3.3.5a) module that adds a GM
command to spawn permanent class trainer NPCs wherever you stand. Trainers are saved
to the world database, so they stay after a restart, and can be removed again with
the same command.

- **Author:** [dudemcbro](https://github.com/dudemcbro)
- **License:** [GNU GPL v3.0](LICENSE)
- **Works with:** AzerothCore WotLK (3.3.5a): the
  [mod-playerbots AzerothCore fork](https://github.com/mod-playerbots/azerothcore-wotlk)
  (`Playerbot` branch) and stock
  [azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk) `master`.
  No core patches are needed. Death Knight trainers need
  [mod-dk](https://github.com/dudemcbro/mod-dk).

## Features

- **Spawn a trainer where you stand.** `.trainer <class> [race] add` spawns a class
  trainer at your position and saves it to the world database, so it stays after a
  restart.
- **Every class and race.** One creature template per class and race (10 classes x
  10 races, creature entries 900100 to 900199). Models keep the chosen race and look
  like the class; weapons are chosen by class.
- **Stock trainer lists.** Trainers are level 80, use faction 35 (friendly to
  everyone) and the stock class trainer spell lists (Death Knights: see
  [Requirements](docs/installation.md#requirements)).
- **Safe removal.** `.trainer <class> [race] del` removes a targeted trainer, but only
  one this module spawned.

## Quick start

1. Clone into your AzerothCore `modules/` folder (keep the name `mod-trainers`):
   ```sh
   cd <azerothcore>/modules
   git clone https://github.com/dudemcbro/mod-trainers.git
   ```
2. Re-run CMake, build and install the core.
3. Restart `worldserver`. It installs the module's SQL on start (see
   [Database setup](docs/installation.md#database-setup)). For Death Knight
   trainers, install mod-dk's SQL first.

The module has no configuration file. The full steps, updating and uninstalling are
in [docs/installation.md](docs/installation.md); the command is in
[docs/gm-commands.md](docs/gm-commands.md).

## Documentation

| Page | What's in it |
| --- | --- |
| [Installation](docs/installation.md) | Requirements (including mod-dk), install, database setup, updating, upgrading from a manual install, uninstalling |
| [GM commands](docs/gm-commands.md) | The `.trainer` command, its classes, races and examples |

## Contributing

Issues and pull requests are welcome. Work on a feature branch and open the pull
request against `main`. Commit messages follow
[Conventional Commits](https://www.conventionalcommits.org/) (`fix: ...`,
`feat: ...`, `docs: ...`).

## License

GNU General Public License v3.0. See [LICENSE](LICENSE).
