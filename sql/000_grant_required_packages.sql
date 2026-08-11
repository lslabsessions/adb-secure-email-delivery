-- ============================================================
-- Required privileges for the application schema
-- Run this script as ADMIN.
--
-- Replace <APP_SCHEMA> with the schema that sends the emails.
-- ============================================================

GRANT EXECUTE ON DBMS_CLOUD
TO <APP_SCHEMA>;

GRANT EXECUTE ON DBMS_CLOUD_NOTIFICATION
TO <APP_SCHEMA>;
