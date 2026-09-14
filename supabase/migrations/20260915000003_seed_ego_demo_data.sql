-- ==========================================================
-- Phase 1 Migration 03: Seed Ego Demo Company & Multi-Source Cameras
-- ==========================================================

DO $$
DECLARE
    v_company_id UUID;
    v_brand_id UUID;
    v_branch_id UUID;
    v_super_admin_id UUID;
    v_rtsp_vault_ref TEXT := 'vault-rtsp-cashier01-demo';
    v_hik_vault_ref TEXT := 'vault-hik-mainentrance-demo';
BEGIN
    -- 1. Create Ego Demo Company
    INSERT INTO companies (id, name, slug)
    VALUES ('11111111-1111-1111-1111-111111111111', 'Ego', 'ego')
    ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO v_company_id;

    -- 2. Create Ego Retail Brand
    INSERT INTO brands (id, company_id, name, slug)
    VALUES ('22222222-2222-2222-2222-222222222222', v_company_id, 'Ego Fashion', 'ego-fashion')
    ON CONFLICT (company_id, slug) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO v_brand_id;

    -- 3. Create Ego Main Branch
    INSERT INTO branches (id, company_id, brand_id, name, code, address)
    VALUES (
        '33333333-3333-3333-3333-333333333333',
        v_company_id,
        v_brand_id,
        'Ego Mall of Arabia Branch',
        'EGO-MOA-01',
        'Mall of Arabia, Gate 4, 6th of October'
    )
    ON CONFLICT (company_id, code) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO v_branch_id;

    -- 4. Seed Protected Vault Credentials (No plaintext passwords stored in cameras table)
    INSERT INTO camera_credentials_vault (credentials_reference, secret_payload_encrypted, secret_type)
    VALUES 
    (
        v_rtsp_vault_ref,
        'enc_aes256:v1:fake_rtsp_user:fake_rtsp_pass_demo',
        'rtsp_auth'
    ),
    (
        v_hik_vault_ref,
        'enc_aes256:v1:fake_hik_app_key_abc:fake_hik_app_secret_xyz:fake_verif_code_123',
        'hikvision_p2p_appkey'
    )
    ON CONFLICT (credentials_reference) DO NOTHING;

    -- 5. Seed RTSP Camera: Cashier 01
    INSERT INTO cameras (
        id,
        company_id,
        brand_id,
        branch_id,
        name,
        source_type,
        enabled,
        status,
        location_description,
        rtsp_url,
        credentials_reference,
        stream_profile,
        last_seen_at
    )
    VALUES (
        '44444444-4444-4444-4444-444444444441',
        v_company_id,
        v_brand_id,
        v_branch_id,
        'Cashier 01',
        'rtsp',
        true,
        'online',
        'Counter 1 - Main Checkout Area',
        'rtsp://stream.ego-store.demo/live/cashier01',
        v_rtsp_vault_ref,
        'main',
        now()
    )
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        source_type = EXCLUDED.source_type,
        rtsp_url = EXCLUDED.rtsp_url,
        credentials_reference = EXCLUDED.credentials_reference;

    -- 6. Seed Hikvision P2P Camera: Main Entrance
    INSERT INTO cameras (
        id,
        company_id,
        brand_id,
        branch_id,
        name,
        source_type,
        enabled,
        status,
        location_description,
        hik_device_id,
        hik_serial_number,
        hik_channel,
        hik_username,
        credentials_reference,
        stream_profile,
        last_seen_at
    )
    VALUES (
        '44444444-4444-4444-4444-444444444442',
        v_company_id,
        v_brand_id,
        v_branch_id,
        'Main Entrance',
        'hikvision_p2p',
        true,
        'online',
        'Customer Entrance & Glass Gates',
        'HIK-DS-2CD2143G2-DEMO-01',
        'D12345678FakeSerial',
        1,
        'admin',
        v_hik_vault_ref,
        'main',
        now()
    )
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        source_type = EXCLUDED.source_type,
        hik_device_id = EXCLUDED.hik_device_id,
        hik_serial_number = EXCLUDED.hik_serial_number,
        hik_channel = EXCLUDED.hik_channel,
        credentials_reference = EXCLUDED.credentials_reference;

END $$;
