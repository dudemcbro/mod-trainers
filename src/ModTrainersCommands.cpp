#include "Chat.h"
#include "CommandScript.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "StringConvert.h"
#include "Tokenize.h"

#include <cctype>
#include <string>
#include <string_view>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
    enum class TrainerClass : uint8
    {
        Warrior = 0,
        Paladin = 1,
        Hunter = 2,
        Rogue = 3,
        Priest = 4,
        DeathKnight = 5,
        Shaman = 6,
        Mage = 7,
        Warlock = 8,
        Druid = 9,
        Max = 10
    };

    enum class TrainerRace : uint8
    {
        Human = 0,
        Dwarf = 1,
        NightElf = 2,
        Gnome = 3,
        Draenei = 4,
        Orc = 5,
        Undead = 6,
        Tauren = 7,
        Troll = 8,
        BloodElf = 9,
        Max = 10
    };

    constexpr uint32 MOD_TRAINERS_ENTRY_BASE = 900100;
    constexpr uint32 MOD_TRAINERS_NUM_RACES = static_cast<uint32>(TrainerRace::Max);
    constexpr uint32 MOD_TRAINERS_NUM_CLASSES = static_cast<uint32>(TrainerClass::Max);
    constexpr uint32 MOD_TRAINERS_ENTRY_MAX = MOD_TRAINERS_ENTRY_BASE + (MOD_TRAINERS_NUM_RACES * MOD_TRAINERS_NUM_CLASSES) - 1;

    std::string NormalizeToken(std::string_view input)
    {
        std::string out;
        out.reserve(input.size());
        for (char c : input)
        {
            unsigned char uc = static_cast<unsigned char>(c);
            if (std::isalnum(uc))
                out.push_back(static_cast<char>(std::tolower(uc)));
        }
        return out;
    }

    bool TryParseTrainerClass(std::string_view token, TrainerClass& outClass)
    {
        std::string key = NormalizeToken(token);

        if (key == "warrior" || key == "war")
        {
            outClass = TrainerClass::Warrior;
            return true;
        }
        if (key == "paladin" || key == "pala" || key == "pal")
        {
            outClass = TrainerClass::Paladin;
            return true;
        }
        if (key == "hunter" || key == "hunt" || key == "hun")
        {
            outClass = TrainerClass::Hunter;
            return true;
        }
        if (key == "rogue" || key == "rog")
        {
            outClass = TrainerClass::Rogue;
            return true;
        }
        if (key == "priest" || key == "pri")
        {
            outClass = TrainerClass::Priest;
            return true;
        }
        if (key == "deathknight" || key == "deathk" || key == "dk")
        {
            outClass = TrainerClass::DeathKnight;
            return true;
        }
        if (key == "shaman" || key == "sham" || key == "sha")
        {
            outClass = TrainerClass::Shaman;
            return true;
        }
        if (key == "mage" || key == "mag")
        {
            outClass = TrainerClass::Mage;
            return true;
        }
        if (key == "warlock" || key == "lock" || key == "wl")
        {
            outClass = TrainerClass::Warlock;
            return true;
        }
        if (key == "druid" || key == "drood" || key == "dr")
        {
            outClass = TrainerClass::Druid;
            return true;
        }

        return false;
    }

    bool TryParseTrainerRace(std::string_view token, TrainerRace& outRace)
    {
        std::string key = NormalizeToken(token);

        if (key == "human")
        {
            outRace = TrainerRace::Human;
            return true;
        }
        if (key == "dwarf")
        {
            outRace = TrainerRace::Dwarf;
            return true;
        }
        if (key == "nightelf" || key == "ne")
        {
            outRace = TrainerRace::NightElf;
            return true;
        }
        if (key == "gnome")
        {
            outRace = TrainerRace::Gnome;
            return true;
        }
        if (key == "draenei" || key == "draenai")
        {
            outRace = TrainerRace::Draenei;
            return true;
        }
        if (key == "orc")
        {
            outRace = TrainerRace::Orc;
            return true;
        }
        if (key == "undead" || key == "forsaken" || key == "ud")
        {
            outRace = TrainerRace::Undead;
            return true;
        }
        if (key == "tauren")
        {
            outRace = TrainerRace::Tauren;
            return true;
        }
        if (key == "troll")
        {
            outRace = TrainerRace::Troll;
            return true;
        }
        if (key == "bloodelf" || key == "be")
        {
            outRace = TrainerRace::BloodElf;
            return true;
        }

        return false;
    }

    std::string_view TrainerClassDisplayName(TrainerClass trainerClass)
    {
        switch (trainerClass)
        {
            case TrainerClass::Warrior: return "Warrior";
            case TrainerClass::Paladin: return "Paladin";
            case TrainerClass::Hunter: return "Hunter";
            case TrainerClass::Rogue: return "Rogue";
            case TrainerClass::Priest: return "Priest";
            case TrainerClass::DeathKnight: return "Death Knight";
            case TrainerClass::Shaman: return "Shaman";
            case TrainerClass::Mage: return "Mage";
            case TrainerClass::Warlock: return "Warlock";
            case TrainerClass::Druid: return "Druid";
            case TrainerClass::Max: break;
        }
        return "Unknown";
    }

    uint32 GetTrainerTemplateEntry(TrainerClass trainerClass, TrainerRace trainerRace)
    {
        return MOD_TRAINERS_ENTRY_BASE + (static_cast<uint32>(trainerClass) * MOD_TRAINERS_NUM_RACES) + static_cast<uint32>(trainerRace);
    }

    bool TryDecodeTrainerEntry(uint32 entry, TrainerClass& outClass, TrainerRace& outRace)
    {
        if (entry < MOD_TRAINERS_ENTRY_BASE || entry > MOD_TRAINERS_ENTRY_MAX)
            return false;

        uint32 offset = entry - MOD_TRAINERS_ENTRY_BASE;
        outClass = static_cast<TrainerClass>(offset / MOD_TRAINERS_NUM_RACES);
        outRace = static_cast<TrainerRace>(offset % MOD_TRAINERS_NUM_RACES);
        return true;
    }

    bool IsModTrainersSpawn(ObjectGuid::LowType spawnId)
    {
        QueryResult result = WorldDatabase.Query("SELECT Comment FROM creature WHERE guid={}", spawnId);
        if (!result)
            return false;

        Field* fields = result->Fetch();
        if (!fields)
            return false;

        std::string comment = fields[0].Get<std::string>();
        return comment.rfind("mod-trainers:", 0) == 0;
    }

    float SnapToGroundZ(Map* map, uint32 phaseMask, float x, float y, float z)
    {
        if (!map)
            return z;

        float height = map->GetHeight(phaseMask, x, y, z, true);
        if (height > -50000.0f)
            return height;

        return z;
    }

    bool SpawnTrainerAtPlayer(Player* player, uint32 creatureEntry, std::string const& comment, ObjectGuid::LowType& outSpawnId)
    {
        if (!player)
            return false;

        if (!sObjectMgr->GetCreatureTemplate(creatureEntry))
            return false;

        Map* map = player->GetMap();
        if (!map)
            return false;

        float x = player->GetPositionX();
        float y = player->GetPositionY();
        float z = player->GetPositionZ();
        float o = player->GetOrientation();

        z = SnapToGroundZ(map, player->GetPhaseMask(), x, y, z);

        Creature* creature = new Creature();
        if (!creature->Create(map->GenerateLowGuid<HighGuid::Unit>(), map, player->GetPhaseMaskForSpawn(), creatureEntry, 0, x, y, z, o))
        {
            delete creature;
            return false;
        }

        creature->SaveToDB(map->GetId(), (1 << map->GetSpawnMode()), player->GetPhaseMaskForSpawn());
        ObjectGuid::LowType spawnId = creature->GetSpawnId();

        creature->CleanupsBeforeDelete();
        delete creature;

        creature = new Creature();
        if (!creature->LoadCreatureFromDB(spawnId, map, true, true))
        {
            delete creature;
            return false;
        }

        sObjectMgr->AddCreatureToGrid(spawnId, sObjectMgr->GetCreatureData(spawnId));
        WorldDatabase.Execute("UPDATE creature SET Comment='{}' WHERE guid={}", comment, spawnId);

        outSpawnId = spawnId;
        return true;
    }

    void SendUsage(ChatHandler* handler)
    {
        if (!handler)
            return;

        handler->SendSysMessage("Usage: .trainer <class> <race?> <add|del>");
        handler->SendSysMessage("Example: .trainer mage add");
        handler->SendSysMessage("Example: .trainer warrior human add");
        handler->SendSysMessage("Delete: target the spawned trainer, then: .trainer mage del");
    }

    bool HandleTrainerCommand(ChatHandler* handler, char const* args)
    {
        Player* player = handler ? handler->GetPlayer() : nullptr;
        if (!player)
            return false;

        std::vector<std::string_view> tokens = Acore::Tokenize(args ? args : "", ' ', false);
        if (tokens.size() < 2 || tokens.size() > 3)
        {
            SendUsage(handler);
            handler->SetSentErrorMessage(true);
            return false;
        }

        TrainerClass trainerClass = TrainerClass::Max;
        if (!TryParseTrainerClass(tokens[0], trainerClass))
        {
            handler->PSendSysMessage("Trainer: unknown class '{}'.", tokens[0]);
            handler->SetSentErrorMessage(true);
            SendUsage(handler);
            return false;
        }

        std::string action = NormalizeToken(tokens.back());
        bool isAdd = (action == "add" || action == "a");
        bool isDel = (action == "del" || action == "delete" || action == "remove" || action == "rm");
        if (!isAdd && !isDel)
        {
            handler->PSendSysMessage("Trainer: unknown action '{}'. Use add or del.", tokens.back());
            handler->SetSentErrorMessage(true);
            SendUsage(handler);
            return false;
        }

        TrainerRace trainerRace = TrainerRace::Max;
        bool raceSpecified = (tokens.size() == 3);
        if (raceSpecified)
        {
            if (!TryParseTrainerRace(tokens[1], trainerRace))
            {
                handler->PSendSysMessage("Trainer: unknown race '{}'.", tokens[1]);
                handler->SetSentErrorMessage(true);
                SendUsage(handler);
                return false;
            }
        }
        else if (isAdd)
        {
            trainerRace = static_cast<TrainerRace>(urand(0, MOD_TRAINERS_NUM_RACES - 1));
        }

        if (isAdd)
        {
            uint32 entry = GetTrainerTemplateEntry(trainerClass, trainerRace);
            std::string_view className = TrainerClassDisplayName(trainerClass);
            std::string comment = Acore::StringFormat("mod-trainers: class={} race={} entry={}", className, static_cast<uint32>(trainerRace), entry);

            ObjectGuid::LowType spawnId = 0;
            if (!SpawnTrainerAtPlayer(player, entry, comment, spawnId))
            {
                handler->PSendSysMessage("Trainer: failed to spawn (template {} missing? did you apply SQL?).", entry);
                handler->SetSentErrorMessage(true);
                return false;
            }

            handler->PSendSysMessage("{} Trainer: spawned (entry={}, guid={}).", className, entry, spawnId);
            return true;
        }

        // del
        Creature* selected = handler->getSelectedCreature();
        if (!selected)
        {
            handler->SendSysMessage("Trainer: you must target a trainer spawned by mod-trainers.");
            handler->SetSentErrorMessage(true);
            return false;
        }

        uint32 entry = selected->GetEntry();
        TrainerClass selectedClass = TrainerClass::Max;
        TrainerRace selectedRace = TrainerRace::Max;
        if (!TryDecodeTrainerEntry(entry, selectedClass, selectedRace))
        {
            handler->SendSysMessage("Trainer: selected creature is not a mod-trainers trainer.");
            handler->SetSentErrorMessage(true);
            return false;
        }

        if (selectedClass != trainerClass)
        {
            handler->PSendSysMessage("Trainer: selected trainer is not a {} Trainer.", TrainerClassDisplayName(trainerClass));
            handler->SetSentErrorMessage(true);
            return false;
        }

        if (raceSpecified && selectedRace != trainerRace)
        {
            handler->SendSysMessage("Trainer: selected trainer race does not match the command.");
            handler->SetSentErrorMessage(true);
            return false;
        }

        ObjectGuid::LowType spawnId = selected->GetSpawnId();
        if (!spawnId)
        {
            handler->SendSysMessage("Trainer: selected creature does not have a DB spawn id.");
            handler->SetSentErrorMessage(true);
            return false;
        }

        if (!IsModTrainersSpawn(spawnId))
        {
            handler->SendSysMessage("Trainer: selected creature is not tagged as mod-trainers (was it spawned with this mod?).");
            handler->SetSentErrorMessage(true);
            return false;
        }

        selected->CombatStop();
        selected->DeleteFromDB();
        selected->AddObjectToRemoveList();

        handler->SendSysMessage("Trainer: removed selected trainer.");
        return true;
    }
}

class mod_trainers_commandscript : public CommandScript
{
public:
    mod_trainers_commandscript() : CommandScript("mod_trainers_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable rootTable =
        {
            { "trainer", HandleTrainerCommand, SEC_GAMEMASTER, Console::No }
        };

        return rootTable;
    }
};

void Addmod_trainersCommands()
{
    new mod_trainers_commandscript();
}
