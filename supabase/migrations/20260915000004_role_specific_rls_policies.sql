-- ==========================================================
-- Phase 7 Migration 04: Role-Specific Row Level Security (RLS)
-- Roles: Super Admin, Company Admin, Brand Manager, Branch Security
-- ==========================================================

-- 1. Extend app_users role check to include 'brand_manager' and 'branch_security'
ALTER TABLE app_users DROP CONSTRAINT IF EXISTS app_users_role_check;
ALTER TABLE app_users ADD CONSTRAINT app_users_role_check 
    CHECK (role IN ('super_admin', 'company_admin', 'brand_manager', 'branch_manager', 'branch_security', 'viewer'));

-- 2. Add brand_id column to app_users for Brand Managers
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS brand_id UUID REFERENCES brands(id) ON DELETE SET NULL;

-- 3. Database RLS Helper: user_has_brand_access
CREATE OR REPLACE FUNCTION user_has_brand_access(lookup_brand_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Super Admin has access to all brands
    IF EXISTS (
        SELECT 1 FROM app_users
        WHERE id = auth.uid() AND role = 'super_admin'
    ) THEN
        RETURN TRUE;
    END IF;

    -- Company Admin has access to all brands within their company
    IF EXISTS (
        SELECT 1 FROM app_users u
        JOIN brands b ON b.company_id = u.company_id
        WHERE u.id = auth.uid() AND u.role = 'company_admin' AND b.id = lookup_brand_id
    ) THEN
        RETURN TRUE;
    END IF;

    -- Brand Manager has access strictly to their assigned brand
    IF EXISTS (
        SELECT 1 FROM app_users
        WHERE id = auth.uid() AND role = 'brand_manager' AND brand_id = lookup_brand_id
    ) THEN
        RETURN TRUE;
    END IF;

    -- Branch Security has read access to their branch's brand
    RETURN EXISTS (
        SELECT 1 FROM user_branch_access uba
        JOIN branches br ON br.id = uba.branch_id
        WHERE uba.user_id = auth.uid() AND br.brand_id = lookup_brand_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Database RLS Helper: user_has_branch_access
CREATE OR REPLACE FUNCTION user_has_branch_access(lookup_branch_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Super Admin has access to all branches
    IF EXISTS (
        SELECT 1 FROM app_users
        WHERE id = auth.uid() AND role = 'super_admin'
    ) THEN
        RETURN TRUE;
    END IF;

    -- Company Admin has access to all branches in their company
    IF EXISTS (
        SELECT 1 FROM app_users u
        JOIN branches b ON b.company_id = u.company_id
        WHERE u.id = auth.uid() AND u.role = 'company_admin' AND b.id = lookup_branch_id
    ) THEN
        RETURN TRUE;
    END IF;

    -- Brand Manager has access to all branches belonging to their assigned brand
    IF EXISTS (
        SELECT 1 FROM app_users u
        JOIN branches b ON b.brand_id = u.brand_id
        WHERE u.id = auth.uid() AND u.role = 'brand_manager' AND b.id = lookup_branch_id
    ) THEN
        RETURN TRUE;
    END IF;

    -- Branch Security has access strictly to explicitly assigned branches
    RETURN EXISTS (
        SELECT 1 FROM user_branch_access uba
        WHERE uba.user_id = auth.uid() AND uba.branch_id = lookup_branch_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Brands Table RLS Policies
DROP POLICY IF EXISTS "tenant_brand_select_policy" ON brands;
CREATE POLICY "tenant_brand_select_policy" ON brands
    FOR SELECT
    USING (user_has_brand_access(id));

-- 6. Branches Table RLS Policies
DROP POLICY IF EXISTS "tenant_branch_select_policy" ON branches;
CREATE POLICY "tenant_branch_select_policy" ON branches
    FOR SELECT
    USING (user_has_branch_access(id));

-- 7. Cameras Table RLS Policies
DROP POLICY IF EXISTS "tenant_camera_select_policy" ON cameras;
CREATE POLICY "tenant_camera_select_policy" ON cameras
    FOR SELECT
    USING (user_has_branch_access(branch_id));

DROP POLICY IF EXISTS "tenant_camera_modify_policy" ON cameras;
CREATE POLICY "tenant_camera_modify_policy" ON cameras
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE id = auth.uid() AND role IN ('super_admin', 'company_admin', 'brand_manager')
        ) AND user_has_branch_access(branch_id)
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE id = auth.uid() AND role IN ('super_admin', 'company_admin', 'brand_manager')
        ) AND user_has_branch_access(branch_id)
    );
