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

-- Base templates by race + class (class-accurate visuals/equipment).
-- Each base entry is a class-appropriate NPC template from core data.
-- If a race lacks a reliable high-level native class trainer with equipment,
-- a class-consistent fallback trainer entry is used.
--
-- Race indices:
--   0 human, 1 dwarf, 2 nightelf, 3 gnome, 4 draenei, 5 orc, 6 undead, 7 tauren, 8 troll, 9 bloodelf
--
-- Class indices:
--   0 warrior, 1 paladin, 2 hunter, 3 rogue, 4 priest, 5 death knight, 6 shaman, 7 mage, 8 warlock, 9 druid

INSERT INTO tmp_mod_trainers_map (entry, base_entry, trainer_id, name)
SELECT
  @MOD_TRAINERS_ENTRY_BASE + (c.class_idx * @MOD_TRAINERS_NUM_RACES) + r.race_idx AS entry,
  CASE c.class_idx
    WHEN 0 THEN r.base_warrior
    WHEN 1 THEN r.base_paladin
    WHEN 2 THEN r.base_hunter
    WHEN 3 THEN r.base_rogue
    WHEN 4 THEN r.base_priest
    WHEN 5 THEN r.base_death_knight
    WHEN 6 THEN r.base_shaman
    WHEN 7 THEN r.base_mage
    WHEN 8 THEN r.base_warlock
    ELSE r.base_druid
  END AS base_entry,
  c.trainer_id,
  c.name
FROM
(
  -- race_idx, warrior, paladin, hunter, rogue, priest, death knight, shaman, mage, warlock, druid
  SELECT 0 AS race_idx, 18948 AS base_warrior,  928 AS base_paladin, 4138 AS base_hunter,  918 AS base_rogue,  376 AS base_priest, 29195 AS base_death_knight, 17204 AS base_shaman, 18949 AS base_mage,   461 AS base_warlock, 4217 AS base_druid UNION ALL
  SELECT 1,             5113,                5147,               5115,              5165,              5141,              29195,                     17204,             36858,                461,               4217 UNION ALL
  SELECT 2,             4087,                 928,               4138,              4214,              4090,              29195,                     17204,               331,                461,               4217 UNION ALL
  SELECT 3,            39252,                 928,               4138,              5167,               376,              29195,                     17204,              5144,               5612,               4217 UNION ALL
  SELECT 4,            16996,               35281,               4138,               918,               376,              29195,                     17204,             17105,                461,               4217 UNION ALL
  SELECT 5,             3353,                 928,               3352,              3401,               376,              29195,                      3344,               331,               3324,               4217 UNION ALL
  SELECT 6,             4593,                 928,               4138,              4584,              4608,              29195,                     17204,              4566,               4563,               4217 UNION ALL
  SELECT 7,             3042,                 928,               3039,               918,               376,              29195,                      3032,               331,                461,               3034 UNION ALL
  SELECT 8,             3171,                 928,               4138,              3170,              5994,              29195,                     17519,               331,              23534,               4217 UNION ALL
  SELECT 9,              914,                 928,               4138,               918,               376,              29195,                     17204,               331,                461,               4217
) r
CROSS JOIN
(
  -- trainer_id values come from `trainer` table (Type=0, Requirement=<ClassId>)
  SELECT 0 AS class_idx, 1  AS trainer_id, 'Warrior Trainer'      AS name UNION ALL
  SELECT 1,              3,                 'Paladin Trainer'      UNION ALL
  SELECT 2,              7,                 'Hunter Trainer'       UNION ALL
  SELECT 3,              9,                 'Rogue Trainer'        UNION ALL
  SELECT 4,              11,                'Priest Trainer'       UNION ALL
  SELECT 5,              13,                'Death Knight Trainer' UNION ALL
  SELECT 6,              14,                'Shaman Trainer'       UNION ALL
  SELECT 7,              16,                'Mage Trainer'         UNION ALL
  SELECT 8,              31,                'Warlock Trainer'      UNION ALL
  SELECT 9,              33,                'Druid Trainer'
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

-- Existing DB spawns created by mod-trainers: force template equipment selection refresh.
-- (Visual model/equipment updates are fully applied when creatures are reloaded/spawned in world.)
UPDATE creature
SET equipment_id = 1
WHERE Comment LIKE 'mod-trainers:%'
  AND id1 BETWEEN @MOD_TRAINERS_ENTRY_BASE AND @MOD_TRAINERS_ENTRY_MAX;

DROP TEMPORARY TABLE tmp_mod_trainers_map;
