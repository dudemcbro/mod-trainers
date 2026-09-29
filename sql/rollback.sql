-- Rollback helper for mod-trainers.
-- Run from the AzerothCore source root:
--   mysql -u <user> -p acore_world < modules/mod-trainers/sql/rollback.sql

SOURCE modules/mod-trainers/sql/db_world/base/trainers_rollback.sql;
