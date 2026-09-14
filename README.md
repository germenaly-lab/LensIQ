# LensIQ — Enterprise CCTV Monitoring Platform

## Phase 1: Multi-Source Camera Architecture

LensIQ is an enterprise-grade CCTV monitoring platform designed with a clean multi-tenant structure (`Company` ➔ `Brand` ➔ `Branch` ➔ `Camera`).

In **Phase 1**, the core camera architecture and database have been restructured to decouple the system from hard-coded RTSP dependencies and support multiple video source types, specifically introducing **Hikvision P2P / Hik-Connect** alongside existing **RTSP** sources.

---

### 1. Architecture Overview

```
                      +-----------------------------+
                      |   Client Tier (Web / App)   |
                      |  - Safe Camera Projections  |
                      |  - Zero Secret Exposure     |
                      +--------------+--------------+
                                     |
                                     v
                      +-----------------------------+
                      |      Streaming Gateway      |
                      |  - Decoupled from transport |
                      +--------------+--------------+
                                     |
                    +----------------+----------------+
                    |                                 |
                    v                                 v
        +-----------------------+         +-----------------------+
        |      RTSPSource       |         |   HikvisionP2PSource  |
        |  - Direct TCP/UDP     |         |  - Cloud P2P Relay    |
        |  - URL verification   |         |  - Device ID / Ch     |
        +-----------+-----------+         +-----------+-----------+
                    |                                 |
                    +----------------+----------------+
                                     |
                                     v
                      +-----------------------------+
                      |   Camera Credentials Vault  |
                      |  - Protected Secrets        |
                      |  - AES-256-GCM / Reference  |
                      +-----------------------------+
```

---

### 2. Supported Camera Source Types

| Source Type | Key Database Columns | Protocol Transport | Description |
| :--- | :--- | :--- | :--- |
| `rtsp` | `rtsp_url`, `credentials_reference`, `stream_profile` | Direct RTSP over TCP/UDP | Traditional IP camera or NVR RTSP stream. |
| `hikvision_p2p` | `hik_device_id`, `hik_serial_number`, `hik_channel`, `hik_username`, `credentials_reference` | Hik-Connect Cloud Relay | Cloud-assisted P2P streaming bypassing local NAT/firewalls. |

---

### 3. Logical Abstraction (`VideoSource`)

The application and the Streaming Gateway operate on the abstract `VideoSource` class instead of hardcoding raw RTSP URLs:

- **`VideoSource` (Base Class)**: Defines common camera traits, validation routines, stream descriptor generation, and gateway pipeline directives.
- **`RTSPSource`**: Encapsulates RTSP connection strings and direct demuxing pipelines.
- **`HikvisionP2PSource`**: Encapsulates Hikvision device identifiers, channel indices, and Hik-Connect cloud relay directives.
- **`VideoSourceFactory`**: Polymorphically instantiates concrete sources based on `source_type`.
- **`StreamingGateway`**: Consumes `VideoSource` objects to instantiate WebRTC/HLS pipelines.

---

### 4. Database Schema & Migration Safety

Database migrations are located in `supabase/migrations/`:

1. **`20260915000001_initial_multitenant_cctv.sql`**:
   - Creates `companies`, `brands`, `branches`, `app_users`, and `user_branch_access`.
   - Enables Row-Level Security (RLS).
2. **`20260915000002_multi_source_camera_schema.sql`**:
   - Creates the `camera_credentials_vault` table with restricted access.
   - Modifies or creates `cameras` table safely without dropping existing RTSP data:
     - Adds `source_type` (`rtsp` | `hikvision_p2p`).
     - Adds nullable `hik_device_id`, `hik_serial_number`, `hik_channel`, `hik_username`.
     - Makes `rtsp_url` nullable for non-RTSP sources.
     - Adds `chk_camera_source_configuration` check constraint.
     - Establishes RLS policies ensuring tenant and branch-level isolation.
     - Creates `safe_cameras_view` preventing credential exposure to client tiers.
3. **`20260915000003_seed_ego_demo_data.sql`**:
   - Seeds the demo tenant **Ego Fashion Group** (`Ego Mall of Arabia Branch`).
   - Seeds RTSP Camera: **Cashier 01** (`source_type = 'rtsp'`).
   - Seeds Hikvision P2P Camera: **Main Entrance** (`source_type = 'hikvision_p2p'`).

---

### 5. Zero-Credential Leakage Guarantee

- Plaintext passwords and API secrets are **never** stored in normal database columns.
- The `cameras` table only holds a `credentials_reference` (e.g. `vault-ref-xxx`).
- The `camera_credentials_vault` is protected server-side with AES-256 encryption.
- The `CameraSerializer` and `safe_cameras_view` automatically strip secret tokens and inline basic-auth credentials before transmitting records to Web or Flutter mobile clients.

---

### 6. Admin Dynamic Configuration UI

Located at `/admin/cameras`:
- Multi-tenant tenant switcher (`Ego` ➔ `Ego Fashion` ➔ `Ego Mall of Arabia Branch`).
- Dynamic Form modal toggling fields between `RTSP` and `Hikvision P2P`.
- Live pipeline testing against the `StreamingGateway`.

---

### 7. Automated Testing

Run the test suite:
```bash
npm test
```

The test suite covers:
1. **Existing RTSP cameras continue working**: Verifies backward compatibility for `Cashier 01`.
2. **Hikvision P2P camera records can be created**: Verifies creation and initialization of `Main Entrance`.
3. **Camera source_type validation works**: Strict Zod runtime validation of both types.
4. **Invalid source configurations are rejected**: Rejects missing URLs, invalid channels, or unrecognized source types.
5. **RLS prevents unauthorized camera access**: Ensures multi-tenant isolation across branches and companies.
6. **Sensitive credentials are not returned to frontend/Flutter clients**: Confirms serialization removes all secret keys and inline passwords.
7. **Existing dashboard queries continue working**: Validates branch filtering, company grouping, and count statistics.
