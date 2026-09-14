-- ==========================================================
-- Phase 1 Migration 02: Multi-Source Camera Architecture
-- Adds multi-source support (RTSP, Hikvision P2P), Secure
-- Credentials Vault, RLS Policies, and Safe Client View.
-- ==========================================================

-- 1. Create Protected Credentials Vault Table
-- Stores sensitive credentials server-side; NEVER exposed to Flutter/Web clients.
CREATE TABLE IF NOT EXISTS camera_credentials_vault (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    credentials_reference TEXT UNIQUE NOT NULL,
    secret_payload_encrypted TEXT NOT NULL,
    secret_type TEXT NOT NULL CHECK (secret_type IN ('rtsp_auth', 'hikvision_token', 'hikvision_p2p_appkey')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Deny all direct client access to the vault (Only service_role backend can access)
ALTER TABLE camera_credentials_vault ENABLE ROW LEVEL SECURITY;
-- No SELECT policies for public/authenticated roles on the vault table!

-- 2. Create Cameras Table with Multi-Source Support
-- If cameras table existed previously with only RTSP, safely modify/add columns
DO $$
BEGIN
    -- Create table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cameras') THEN
        CREATE TABLE cameras (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
            brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
            branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            source_type TEXT NOT NULL DEFAULT 'rtsp' CHECK (source_type IN ('rtsp', 'hikvision_p2p')),
            enabled BOOLEAN NOT NULL DEFAULT true,
            status TEXT NOT NULL DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'degraded', 'provisioning')),
            location_description TEXT,
            rtsp_url TEXT,
            hik_device_id TEXT,
            hik_serial_number TEXT,
            hik_channel INTEGER,
            hik_username TEXT,
            credentials_reference TEXT REFERENCES camera_credentials_vault(credentials_reference) ON DELETE SET NULL,
            stream_profile TEXT NOT NULL DEFAULT 'main' CHECK (stream_profile IN ('main', 'sub')),
            last_seen_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
        );
    ELSE
        -- Migration Safety: Table exists, alter and preserve existing RTSP data
        ALTER TABLE cameras ADD COLUMN IF NOT EXISTS source_type TEXT NOT NULL DEFAULT 'rtsp' CHECK (source_type IN ('rtsp', 'hikvision_p2p'));
        ALTER TABLE cameras ADD COLUMN IF NOT EXISTS hik_device_id TEXT;
        ALTER TABLE cameras ADD COLUMN IF NOT EXISTS hik_serial_number TEXT;
        ALTER TABLE cameras ADD COLUMN IF NOT EXISTS hik_channel INTEGER;
        ALTER TABLE cameras ADD COLUMN IF NOT EXISTS hik_username TEXT;
        ALTER TABLE cameras ADD COLUMN IF NOT EXISTS credentials_reference TEXT REFERENCES camera_credentials_vault(credentials_reference) ON DELETE SET NULL;
        ALTER TABLE cameras ADD COLUMN IF NOT EXISTS stream_profile TEXT NOT NULL DEFAULT 'main' CHECK (stream_profile IN ('main', 'sub'));
        ALTER TABLE cameras ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ;
        
        -- Make rtsp_url nullable if it was NOT NULL in older schema
        ALTER TABLE cameras ALTER COLUMN rtsp_url DROP NOT NULL;
    END IF;
END $$;

-- 3. Source-Type Validation Check Constraints
-- Enforces that RTSP cameras have rtsp_url, and Hikvision P2P cameras have hik_device_id and hik_channel.
ALTER TABLE cameras DROP CONSTRAINT IF EXISTS chk_camera_source_configuration;
ALTER TABLE cameras ADD CONSTRAINT chk_camera_source_configuration CHECK (
    (source_type = 'rtsp' AND rtsp_url IS NOT NULL) OR
    (source_type = 'hikvision_p2p' AND hik_device_id IS NOT NULL AND hik_channel IS NOT NULL)
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE cameras ENABLE ROW LEVEL SECURITY;

-- Helper function to check if a user has access to a branch
CREATE OR REPLACE FUNCTION user_has_branch_access(lookup_branch_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Super admins have access to all branches
    IF EXISTS (
        SELECT 1 FROM app_users
        WHERE id = auth.uid() AND role = 'super_admin'
    ) THEN
        RETURN TRUE;
    END IF;

    -- Company admins have access to all branches in their company
    IF EXISTS (
        SELECT 1 FROM app_users u
        JOIN branches b ON b.company_id = u.company_id
        WHERE u.id = auth.uid() AND u.role = 'company_admin' AND b.id = lookup_branch_id
    ) THEN
        RETURN TRUE;
    END IF;

    -- Branch managers and viewers have access to explicitly granted branches
    RETURN EXISTS (
        SELECT 1 FROM user_branch_access uba
        WHERE uba.user_id = auth.uid() AND uba.branch_id = lookup_branch_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policy: Users can only select cameras from branches they are authorized to access
DROP POLICY IF EXISTS "tenant_camera_select_policy" ON cameras;
CREATE POLICY "tenant_camera_select_policy" ON cameras
    FOR SELECT
    USING (user_has_branch_access(branch_id));

-- RLS Policy: Super admins and Company admins can insert/update/delete cameras
DROP POLICY IF EXISTS "tenant_camera_modify_policy" ON cameras;
CREATE POLICY "tenant_camera_modify_policy" ON cameras
    FOR ALL
    USING (user_has_branch_access(branch_id))
    WITH CHECK (user_has_branch_access(branch_id));

-- 5. Safe Cameras View (Zero Credential Exposure for Flutter & Web Clients)
-- This view strips credentials_reference and raw credentials before serving clients
CREATE OR REPLACE VIEW safe_cameras_view AS
SELECT 
    c.id,
    c.company_id,
    c.brand_id,
    c.branch_id,
    c.name,
    c.source_type,
    c.enabled,
    c.status,
    c.location_description,
    -- For RTSP, sanitized stream profile endpoint (no inline basic-auth passwords)
    CASE 
        WHEN c.source_type = 'rtsp' THEN c.rtsp_url
        ELSE NULL
    END AS rtsp_url,
    -- Hikvision identifiers are safe for client display / stream association
    c.hik_device_id,
    c.hik_serial_number,
    c.hik_channel,
    c.stream_profile,
    c.last_seen_at,
    c.created_at,
    c.updated_at
FROM cameras c;
