-- mod-trainers: class trainer templates + trainer bindings
-- Apply to: acore_world

SET @MOD_TRAINERS_ENTRY_BASE := 900100;
SET @MOD_TRAINERS_NUM_RACES := 10;
SET @MOD_TRAINERS_NUM_CLASSES := 10;
SET @MOD_TRAINERS_ENTRY_MAX := @MOD_TRAINERS_ENTRY_BASE + (@MOD_TRAINERS_NUM_RACES * @MOD_TRAINERS_NUM_CLASSES) - 1;

-- Clean existing templates in our reserved range (re-runnable)
DELETE FROM creature_default_trainer WHERE CreatureId BETWEEN @MOD_TRAINERS_ENTRY_BASE AND @MOD_TRAINERS_ENTRY_MAX;
DELETE FROM creature_template_model WHERE CreatureID BETWEEN @MOD_TRAINERS_ENTRY_BASE AND @MOD_TRAINERS_ENTRY_MAX;
DELETE FROM creature_equip_template WHERE CreatureID BETWEEN @MOD_TRAINERS_ENTRY_BASE AND @MOD_TRAINERS_ENTRY_MAX;
DELETE FROM creature_template WHERE entry BETWEEN @MOD_TRAINERS_ENTRY_BASE AND @MOD_TRAINERS_ENTRY_MAX;

DROP TEMPORARY TABLE IF EXISTS tmp_mod_trainers_map;
CREATE TEMPORARY TABLE tmp_mod_trainers_map (
  entry INT UNSIGNED NOT NULL,
  base_entry INT UNSIGNED NOT NULL,
  trainer_id INT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (entry)
) ENGINE=MEMORY;

-- Base templates by race + role (to keep trainer visuals lore-appropriate).
-- Role groups:
--   0 = heavy (warrior/paladin/dk)
--   1 = medium (hunter/rogue/shaman)
--   2 = caster (priest/mage/warlock/druid)
--
-- Race indices:
--   0 human, 1 dwarf, 2 nightelf, 3 gnome, 4 draenei, 5 orc, 6 undead, 7 tauren, 8 troll, 9 bloodelf
--
-- NOTE: These are intentionally simple and resilient: we copy model + weapon equipment from the chosen base NPC.

INSERT INTO tmp_mod_trainers_map (entry, base_entry, trainer_id, name)
SELECT
  @MOD_TRAINERS_ENTRY_BASE + (c.class_idx * @MOD_TRAINERS_NUM_RACES) + r.race_idx AS entry,
  CASE c.role_group
    WHEN 0 THEN r.base_heavy
    WHEN 1 THEN r.base_medium
    ELSE r.base_caster
  END AS base_entry,
  c.trainer_id,
  c.name
FROM
(
  -- base_heavy / base_medium / base_caster
  SELECT 0 AS race_idx, 68    AS base_heavy, 18948 AS base_medium, 18949 AS base_caster UNION ALL -- Stormwind City Guard / Stormwind Soldier / Stormwind Mage
  SELECT 1,              5595,             727,                36858              UNION ALL -- Ironforge Guard / Ironforge Mountaineer / Dwarf Mage
  SELECT 2,              4262,             16332,              15634              UNION ALL -- Darnassus Sentinel / Darnassian Huntress / Priestess of the Moon
  SELECT 3,              21426,            4430,               19007              UNION ALL -- Gnome Defender / Gnome Pit Crewman / Gnomeregan Conjuror
  SELECT 4,              16733,            16996,              18815              UNION ALL -- Exodar Peacekeeper / Draenei Vindicator / Exodar Proselyte
  SELECT 5,              3296,             19425,              36863              UNION ALL -- Orgrimmar Grunt / Orgrimmar Peon / Orc Mage
  SELECT 6,              7980,             5624,               18971              UNION ALL -- Deathguard Elite / Undercity Guardian / Undercity Mage
  SELECT 7,              3212,             19407,              36865              UNION ALL -- Brave Ironhorn / Thunder Bluff Huntsman / Tauren Priest
  SELECT 8,              18970,            18970,              17935              UNION ALL -- Darkspear Axe Thrower / Darkspear Axe Thrower / Horde Witch Doctor
  SELECT 9,              16222,            18147,              19006                         -- Silvermoon City Guardian / Silvermoon Ranger / Silvermoon Magister
) r
CROSS JOIN
(
  -- trainer_id values come from `trainer` table (Type=0, Requirement=<ClassId>)
  SELECT 0 AS class_idx, 0 AS role_group, 1  AS trainer_id, 'Warrior Trainer'      AS name UNION ALL
  SELECT 1,              0,               3,                 'Paladin Trainer'      UNION ALL
  SELECT 2,              1,               7,                 'Hunter Trainer'       UNION ALL
  SELECT 3,              1,               9,                 'Rogue Trainer'        UNION ALL
  SELECT 4,              2,               11,                'Priest Trainer'       UNION ALL
  SELECT 5,              0,               13,                'Death Knight Trainer' UNION ALL
  SELECT 6,              1,               14,                'Shaman Trainer'       UNION ALL
  SELECT 7,              2,               16,                'Mage Trainer'         UNION ALL
  SELECT 8,              2,               31,                'Warlock Trainer'      UNION ALL
  SELECT 9,              2,               33,                'Druid Trainer'
) c;

-- Create templates
INSERT INTO creature_template (entry, name, minlevel, maxlevel, faction, npcflag, type)
SELECT entry, name, 80, 80, 35, 48, 7
FROM tmp_mod_trainers_map;

-- Copy models (gives race visuals; multiple models randomize)
INSERT INTO creature_template_model (CreatureID, Idx, CreatureDisplayID, DisplayScale, Probability, VerifiedBuild)
SELECT m.entry, ctm.Idx, ctm.CreatureDisplayID, ctm.DisplayScale, ctm.Probability, ctm.VerifiedBuild
FROM tmp_mod_trainers_map m
INNER JOIN creature_template_model ctm ON ctm.CreatureID = m.base_entry;

-- Copy equipment when the base NPC has it (optional)
INSERT INTO creature_equip_template (CreatureID, ID, ItemID1, ItemID2, ItemID3, VerifiedBuild)
SELECT m.entry, cet.ID, cet.ItemID1, cet.ItemID2, cet.ItemID3, cet.VerifiedBuild
FROM tmp_mod_trainers_map m
INNER JOIN creature_equip_template cet ON cet.CreatureID = m.base_entry;

-- Bind trainer spell lists
INSERT INTO creature_default_trainer (CreatureId, TrainerId)
SELECT entry, trainer_id
FROM tmp_mod_trainers_map;

DROP TEMPORARY TABLE tmp_mod_trainers_map;
