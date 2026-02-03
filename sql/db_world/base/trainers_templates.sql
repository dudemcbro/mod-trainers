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

-- Race base templates (major city NPCs)
--  0 human     -> 68    Stormwind City Guard
--  1 dwarf     -> 5595  Ironforge Guard
--  2 nightelf  -> 4262  Darnassus Sentinel
--  3 gnome     -> 19172 Gnome Commoner
--  4 draenei   -> 16733 Exodar Peacekeeper
--  5 orc       -> 3296  Orgrimmar Grunt
--  6 undead    -> 7980  Deathguard Elite
--  7 tauren    -> 3212  Brave Ironhorn
--  8 troll     -> 18970 Darkspear Axe Thrower
--  9 bloodelf  -> 18799 Silvermoon Citizen

INSERT INTO tmp_mod_trainers_map (entry, base_entry, trainer_id, name)
SELECT
  @MOD_TRAINERS_ENTRY_BASE + (c.class_idx * @MOD_TRAINERS_NUM_RACES) + r.race_idx AS entry,
  r.base_entry,
  c.trainer_id,
  c.name
FROM
(
  SELECT 0 AS race_idx, 68 AS base_entry UNION ALL
  SELECT 1, 5595 UNION ALL
  SELECT 2, 4262 UNION ALL
  SELECT 3, 19172 UNION ALL
  SELECT 4, 16733 UNION ALL
  SELECT 5, 3296 UNION ALL
  SELECT 6, 7980 UNION ALL
  SELECT 7, 3212 UNION ALL
  SELECT 8, 18970 UNION ALL
  SELECT 9, 18799
) r
CROSS JOIN
(
  -- trainer_id values come from `trainer` table (Type=0, Requirement=<ClassId>)
  SELECT 0 AS class_idx, 1  AS trainer_id, 'Warrior Trainer'     AS name UNION ALL
  SELECT 1,              3,                 'Paladin Trainer'     UNION ALL
  SELECT 2,              7,                 'Hunter Trainer'      UNION ALL
  SELECT 3,              9,                 'Rogue Trainer'       UNION ALL
  SELECT 4,              11,                'Priest Trainer'      UNION ALL
  SELECT 5,              13,                'Death Knight Trainer' UNION ALL
  SELECT 6,              14,                'Shaman Trainer'      UNION ALL
  SELECT 7,              16,                'Mage Trainer'        UNION ALL
  SELECT 8,              31,                'Warlock Trainer'     UNION ALL
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

DROP TEMPORARY TABLE tmp_mod_trainers_map;
