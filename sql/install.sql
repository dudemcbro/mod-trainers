-- One-step installer for mod-trainers world SQL.
-- Run from the AzerothCore source root:
--   mysql -u <user> -p acore_world < modules/mod-trainers/sql/install.sql

SOURCE modules/mod-trainers/sql/db_world/base/trainers_templates.sql;
