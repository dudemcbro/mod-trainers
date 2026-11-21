# GM commands

The `.trainer` command that spawns and removes class trainers.

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

Spawned trainers are saved to the world database and stay after a restart. Death
Knight trainers need mod-dk's SQL (see
[Requirements](installation.md#requirements)). To remove every spawned trainer at
once, see [Uninstall](installation.md#uninstall).
