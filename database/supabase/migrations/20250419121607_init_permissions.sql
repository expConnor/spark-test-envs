-- Creator Schema Permissions =====================================================

-- 1. Reset schema ownership to postgres (which is a member of all needed roles)
ALTER SCHEMA creators OWNER TO postgres;

-- 2. Grant schema usage and create permissions
GRANT USAGE, CREATE ON SCHEMA creators TO anon, authenticated, service_role;

-- 3. Grant table permissions (run AFTER creating all tables)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA creators TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA creators TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA creators TO anon, authenticated, service_role;

-- 4. Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA creators 
GRANT ALL ON TABLES TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA creators
GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- 5. Ensure authenticator has the right role memberships
GRANT anon, authenticated, service_role TO authenticator;

-- Utils Schema Permissions ======================================================

-- 1. Reset schema ownership
ALTER SCHEMA utils OWNER TO postgres;

-- 2. Grant schema usage
GRANT USAGE ON SCHEMA utils TO anon, authenticated;

-- 3. Grant table and function permissions
GRANT SELECT ON ALL TABLES IN SCHEMA utils TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA utils TO anon, authenticated;

-- 4. Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA utils
GRANT SELECT ON TABLES TO anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA utils
GRANT EXECUTE ON FUNCTIONS TO anon, authenticated;
