-- ==========================================================
-- Phase 10 Migration 05: Production Performance & RLS Query Optimization
-- Targeted, Justified Composite Indexes for High-Traffic CCTV Monitoring
-- ==========================================================

-- 1. Incidents Table Performance Indexes
-- Optimizes: Live Incident Feed, Branch Security filtering, and Dashboard aggregates
CREATE INDEX IF NOT EXISTS idx_incidents_branch_status_created 
    ON incidents(branch_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_incidents_brand_created 
    ON incidents(brand_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_incidents_severity_status 
    ON incidents(severity, status) 
    WHERE status = 'open';

-- 2. Cameras Table Performance Indexes
-- Optimizes: Camera health monitoring, grid layouts, and source type filtering
CREATE INDEX IF NOT EXISTS idx_cameras_branch_status 
    ON cameras(branch_id, status);

CREATE INDEX IF NOT EXISTS idx_cameras_source_type 
    ON cameras(source_type, status);

-- 3. Notification Records Table Performance Indexes
-- Optimizes: Unread count polling, notification drawer fetching, and batch read updates
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_unread 
    ON notification_records(recipient_id, sent_at DESC) 
    WHERE read_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_incident_id 
    ON notification_records(incident_id);

-- 4. Stream Sessions Table Performance Indexes
-- Optimizes: Session validation, concurrency limit enforcement, and stale session cleanup
CREATE INDEX IF NOT EXISTS idx_stream_sessions_camera_status 
    ON stream_sessions(camera_id, status);

CREATE INDEX IF NOT EXISTS idx_stream_sessions_user_expires 
    ON stream_sessions(user_id, expires_at) 
    WHERE status = 'active';

-- 5. User RBAC & Branch Access Table Indexes
-- Optimizes: RLS function evaluations (user_has_branch_access & user_has_brand_access)
CREATE INDEX IF NOT EXISTS idx_user_branch_access_composite 
    ON user_branch_access(user_id, branch_id);

CREATE INDEX IF NOT EXISTS idx_app_users_role_company 
    ON app_users(role, company_id);

-- 6. Audit Logs Table Performance Indexes
-- Optimizes: Security compliance queries and administrator audit views
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_created 
    ON audit_logs(user_id, created_at DESC);
