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
  model_base_entry INT UNSIGNED NOT NULL,
  equip_base_entry INT UNSIGNED NOT NULL,
  trainer_id INT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (entry)
) ENGINE=MEMORY;

-- Model/equipment bases by race + class.
-- Visual models are race-preserving and class-appropriate.
-- Weapons are class-based for consistent class fantasy.
-- For race/class combos without a native trainer, same-race fallback templates are used.
--
-- Race indices:
--   0 human, 1 dwarf, 2 nightelf, 3 gnome, 4 draenei, 5 orc, 6 undead, 7 tauren, 8 troll, 9 bloodelf
--
-- Class indices:
--   0 warrior, 1 paladin, 2 hunter, 3 rogue, 4 priest, 5 death knight, 6 shaman, 7 mage, 8 warlock, 9 druid

INSERT INTO tmp_mod_trainers_map (entry, model_base_entry, equip_base_entry, trainer_id, name)
SELECT
  @MOD_TRAINERS_ENTRY_BASE + (c.class_idx * @MOD_TRAINERS_NUM_RACES) + r.race_idx AS entry,
  CASE c.class_idx
    WHEN 0 THEN r.model_warrior
    WHEN 1 THEN r.model_paladin
    WHEN 2 THEN r.model_hunter
    WHEN 3 THEN r.model_rogue
    WHEN 4 THEN r.model_priest
    WHEN 5 THEN r.model_death_knight
    WHEN 6 THEN r.model_shaman
    WHEN 7 THEN r.model_mage
    WHEN 8 THEN r.model_warlock
    ELSE r.model_druid
  END AS model_base_entry,
  CASE c.class_idx
    WHEN 0 THEN 3353  -- warrior
    WHEN 1 THEN 927   -- paladin
    WHEN 2 THEN 4138  -- hunter
    WHEN 3 THEN 3401  -- rogue
    WHEN 4 THEN 376   -- priest
    WHEN 5 THEN 29195 -- death knight
    WHEN 6 THEN 3032  -- shaman
    WHEN 7 THEN 5144  -- mage
    WHEN 8 THEN 461   -- warlock
    ELSE 4217         -- druid
  END AS equip_base_entry,
  c.trainer_id,
  c.name
FROM
(
  -- race_idx, model_warrior..model_druid (all race-preserving)
  SELECT
    0 AS race_idx,
    18948 AS model_warrior,  928 AS model_paladin,  918 AS model_hunter,  918 AS model_rogue,  376 AS model_priest, 18948 AS model_death_knight,  918 AS model_shaman,  331 AS model_mage,   461 AS model_warlock,  918 AS model_druid
  UNION ALL SELECT
    1,
    5113,                   5147,                5115,               5165,                5141,                       5113,                     5115,              36858,                5141,                5165
  UNION ALL SELECT
    2,
    4087,                   4087,                4138,               4214,                4090,                       4087,                     4138,               4090,                4090,                4217
  UNION ALL SELECT
    3,
    5114,                   5114,                5167,               5167,                5144,                       5114,                     5167,               5144,                5612,                5167
  UNION ALL SELECT
    4,
    16996,                 35281,               17110,              17110,               16502,                      16996,                    17089,              17105,               16502,               17110
  UNION ALL SELECT
    5,
    3353,                   3353,                3352,               3401,                3324,                       3353,                     3344,               3324,                3324,                3401
  UNION ALL SELECT
    6,
    4593,                   4593,                4584,               4584,                4608,                       4593,                     4584,               4566,                4563,                4584
  UNION ALL SELECT
    7,
    3042,                   3042,                3039,               3034,                3034,                       3042,                     3032,               3034,                3034,                3034
  UNION ALL SELECT
    8,
    3171,                   3171,                3171,               3170,                5994,                       3171,                    17519,               5994,               23534,                3170
  UNION ALL SELECT
    9,
   17480,                  16679,               16672,              16684,               16658,                      17480,                    16672,              16652,               16646,               16684
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

-- Copy models from class-specific source (keeps class visual identity)
INSERT INTO creature_template_model (CreatureID, Idx, CreatureDisplayID, DisplayScale, Probability, VerifiedBuild)
SELECT m.entry, ctm.Idx, ctm.CreatureDisplayID, ctm.DisplayScale, ctm.Probability, ctm.VerifiedBuild
FROM tmp_mod_trainers_map m
INNER JOIN creature_template_model ctm ON ctm.CreatureID = m.model_base_entry;

-- Copy equipment from class-specific source (keeps class gear fantasy)
INSERT INTO creature_equip_template (CreatureID, ID, ItemID1, ItemID2, ItemID3, VerifiedBuild)
SELECT m.entry, cet.ID, cet.ItemID1, cet.ItemID2, cet.ItemID3, cet.VerifiedBuild
FROM tmp_mod_trainers_map m
INNER JOIN creature_equip_template cet ON cet.CreatureID = m.equip_base_entry;

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
