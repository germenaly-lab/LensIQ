# LensIQ Enterprise Platform Architecture

## 1. System Overview

LensIQ is an enterprise-grade, multi-tenant AI CCTV monitoring and analytics platform. It unifies video ingestion from diverse IP camera sources (traditional RTSP and Hikvision P2P Cloud Relay), processes live video feeds with YOLOv8 computer vision models, detects operational violations (such as unattended cashiers), and broadcasts instantaneous push notifications to targeted enterprise staff.

---

## 2. Multi-Tenant Data Hierarchy

```mermaid
erDiagram
    COMPANY ||--o{ BRAND : owns
    BRAND ||--o{ BRANCH : operates
    BRANCH ||--o{ CAMERA : contains
    CAMERA ||--o{ ROI : defines
    CAMERA ||--o{ AI_RULE : monitors
    AI_RULE ||--o{ INCIDENT : generates
    COMPANY ||--o{ APP_USER : employs
    APP_USER ||--o{ USER_BRANCH_ACCESS : assigned

    COMPANY {
        uuid id PK
        string name
        string slug
    }
    BRAND {
        uuid id PK
        uuid company_id FK
        string name
        string slug
    }
    BRANCH {
        uuid id PK
        uuid brand_id FK
        string name
        string code
        string address
    }
    CAMERA {
        uuid id PK
        uuid branch_id FK
        string name
        string source_type "rtsp | hikvision_p2p"
        string status "online | offline | warning"
        string rtsp_url
        string hik_device_id
        string credentials_reference
    }
    INCIDENT {
        uuid id PK
        uuid camera_id FK
        string rule_type "cashier_empty | loitering"
        string severity "critical | warning | info"
        string status "active | acknowledged | resolved"
        timestamp created_at
    }
```

---

## 3. Dual Video Source Ingestion Pipeline

```mermaid
flowchart TD
    subgraph Sources["Camera Sources Tier"]
        Cam1["Branch RTSP Camera<br/>(Local IP / NVR Channel)"]
        Cam2["Remote Branch Hikvision Camera<br/>(Behind NAT / Firewall)"]
    end

    subgraph Adapters["Source Ingestion & Protocol Normalization"]
        RTSPAdapter["RTSP Source Adapter<br/>- Direct TCP/UDP Demux<br/>- Keepalive ping"]
        HikAdapter["Hikvision P2P Adapter<br/>- Artemis Cloud Relay<br/>- Verification Code Handshake"]
    end

    subgraph SecurityVault["Credentials Vault (Encrypted)"]
        Vault["AES-256 Credentials Vault<br/>Stores Passwords & Verification Keys"]
    end

    subgraph Gateway["LensIQ Streaming Gateway (MediaMTX / WebRTC / HLS)"]
        Transcoder["FFmpeg WebRTC Transcoder<br/>H.264 Baseline / Low-Latency WHEP"]
        SessionMgr["Stream Session Manager<br/>- 1-Hour Ephemeral Tokens<br/>- Auto-Idle Cleanup (60s)"]
    end

    subgraph Clients["Presentation Tier"]
        FlutterDesktop["Flutter Web & Desktop Dashboard"]
        FlutterMobile["Flutter Mobile App (iOS / Android)"]
    end

    Cam1 -->|RTSP TCP 554| RTSPAdapter
    Cam2 -->|Hik-Connect Cloud| HikAdapter
    Vault -.->|Decrypts at Gateway Only| RTSPAdapter
    Vault -.->|Decrypts at Gateway Only| HikAdapter
    RTSPAdapter --> Transcoder
    HikAdapter --> Transcoder
    Transcoder --> SessionMgr
    SessionMgr -->|Sanitized WebRTC WHEP / HLS| FlutterDesktop
    SessionMgr -->|Sanitized WebRTC WHEP / HLS| FlutterMobile
```

---

## 4. AI Event Detection & Incident Lifecycle Pipeline

```mermaid
sequenceDiagram
    autonumber
    participant GW as Streaming Gateway
    participant AI as Python AI Microservice (YOLOv8)
    participant Engine as Cashier Empty Stateful Rule
    participant API as Node.js Backend API
    participant FCM as Firebase Cloud Messaging
    participant App as Flutter Mobile / Web

    GW->>AI: Pull live video frames (e.g. 5 fps sample)
    AI->>AI: Run YOLOv8 Person Detection on Defined ROI
    AI->>Engine: Feed Person Bounding Boxes & Frame Timestamp
    Note over Engine: Counter empty continuous duration >= 180s
    Engine->>AI: Trigger Event: CASHIER_EMPTY (duration: 180s)
    AI->>API: POST /api/v1/internal/events (x-internal-service-key)
    API->>API: Evaluate Multi-Tenant Target Recipients (Branch Security & Brand Mgr)
    API->>FCM: Dispatch Push Notification with Deep Link
    FCM->>App: Deliver Push Alert ("Cashier Area Empty - Cashier 01")
    App->>App: User Taps Notification -> Deep Links directly to /incidents?id=...
```

---

## 5. Client Localization & Arabization Engine

LensIQ provides seamless, zero-restart language switching:
* **Default Language**: English (`en`) with Left-to-Right (`TextDirection.ltr`) layout.
* **Secondary Language**: Arabic (`ar`) with Right-to-Left (`TextDirection.rtl`) layout.
* **Persistent Selection**: Persisted via `SharedPreferences` across browser reloads and app restarts.
* **Granular UI Coverage**: Sidebar, top app bars, status badges, camera filters, notification panel, and settings cards.
