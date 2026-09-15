# LensIQ — Enterprise AI CCTV Monitoring Platform

[![CI/CD Tests](https://img.shields.io/badge/Vitest%20Tests-64%2F64%20Passing-brightgreen.svg)]()
[![Python Tests](https://img.shields.io/badge/Pytest-12%2F12%20Passing-brightgreen.svg)]()
[![Flutter Tests](https://img.shields.io/badge/Flutter%20Tests-35%2F35%20Passing-brightgreen.svg)]()
[![Production Status](https://img.shields.io/badge/Production-Ready-blue.svg)]()

LensIQ is an enterprise-grade AI CCTV video surveillance and operational intelligence platform. Designed with strict multi-tenancy (`Company` ➔ `Brand` ➔ `Branch` ➔ `Camera`), LensIQ supports diverse camera ingestion protocols (Direct RTSP and Hikvision P2P Cloud Relay), real-time YOLOv8 computer vision analytics, role-based access control (RBAC), and instantaneous push notifications with full English and Arabic localization.

---

## 🌟 Key Capabilities

1. **Multi-Source Camera Support**:
   - **RTSP Streams**: Standard IP cameras and NVR channels with TCP/UDP transport.
   - **Hikvision P2P / Hik-Connect**: Direct cloud-assisted relay bypassing strict branch firewalls and NAT without port forwarding.
2. **Zero-Credential Exposure**:
   - Camera passwords and P2P verification keys are stored in an AES-256 encrypted server-side vault.
   - Clients only receive ephemeral, time-bounded WebRTC / HLS stream tokens.
3. **Computer Vision & AI Rules**:
   - Integrated YOLOv8 inference microservice with custom Region-of-Interest (ROI) support.
   - Stateful operational rules (e.g., **Cashier Empty detection** triggering an incident after 180 continuous seconds of an unattended checkout desk).
4. **Targeted Push Notifications**:
   - Firebase Cloud Messaging (FCM) integration with role-based scoping (Branch Security receives branch incidents; Brand Manager receives brand-wide alerts; Super Admin receives global alerts).
   - Instant foreground notifications and deep linking directly to incident reviews.
5. **Full Arabic & English Localization**:
   - Default English with Left-to-Right (LTR) layout.
   - One-tap switch (`🌐 EN` / `🌐 عربي`) in top header and settings.
   - Automatic Right-to-Left (RTL) mirroring and comprehensive Arabic translation dictionary.
6. **Production-Hardened Security**:
   - Helmet HTTP headers with cross-origin resource policy for live streams.
   - Rate limiting (500 requests per 15 minutes per IP with internal microservice bypass).
   - Row-Level Security (RLS) and multi-column optimized database indexes.

---

## 🏗️ Architecture

```
+-------------------------------------------------------------------------------+
|                       Flutter Multi-Platform Client Tier                      |
|                (Web / Desktop / iOS / Android / Arabization)                  |
+---------------------------------------+---------------------------------------+
                                        |
                 +----------------------+----------------------+
                 | (REST API / Auth / Tokens)                  | (WebRTC WHEP / HLS)
                 v                                             v
+-----------------------------------------------+   +---------------------------+
|             LensIQ Backend API                |   |     Streaming Gateway     |
|   - Express / TypeScript / Helmet / Limiter   |   |   - MediaMTX / WebRTC     |
|   - Multi-Tenant RBAC & Vault                 |   |   - Transcoding           |
|   - Notification Dispatcher (FCM)             |   |   - Stream Session Mgr    |
+-----------------------+-----------------------+   +-------------+-------------+
                        |                                         |
     +------------------+------------------+                      |
     |                                     |                      |
     v                                     v                      v
+-----------------------+       +---------------------+   +---------------+
|   Supabase Database   |       |  Python AI Service  |   | Camera Sources|
|   - Multi-tenant RLS  |       |  - YOLOv8 Inference |   | - RTSP Streams|
|   - Composite Indexes |       |  - Cashier Rule     |   | - Hikvision   |
|   - Audit Logging     |       |  - Prometheus /met  |   |   P2P Cloud   |
+-----------------------+       +---------------------+   +---------------+
```

Detailed architectural diagrams and sequence flows are available in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## 🧪 Comprehensive Test Suites

LensIQ maintains high test coverage across all layers:

### 1. Node.js Backend & E2E Vitest Tests
```bash
npm test
```
- **64 / 64 passing** across 7 test suites:
  - `phase1-multi-source.test.ts` (7 tests): Multi-source polymorphism & factory validation.
  - `phase3-backend-multi-source.test.ts` (9 tests): Zero-credential serialization & vault encryption.
  - `phase4-streaming-gateway.test.ts` (10 tests): WebRTC/HLS session management & lifecycle.
  - `phase7-role-permissions.test.ts` (10 tests): RBAC isolation across Super Admin, Brand Manager, and Branch Security.
  - `phase8-live-streaming.test.ts` (12 tests): Stream negotiation, token expiry, and reconnect resilience.
  - `phase9-notifications.test.ts` (8 tests): FCM token registration, preferences, and targeting.
  - `phase10-audit-e2e.test.ts` (8 tests): Full system security audit & multi-source E2E verification.

### 2. Python AI Microservice Tests
```bash
services/ai-service/.venv/bin/pytest services/ai-service/tests/ -v
```
- **12 / 12 passing**: ROI polygon containment, detection parsing, stateful cashier-empty evaluation, `/metrics`, `/config`, and service token authentication.

### 3. Flutter Client Tests & Static Analysis
```bash
cd apps/flutter_app
flutter analyze
flutter test
```
- **`flutter analyze`**: 0 issues found!
- **`flutter test`**: **35 / 35 passing** including localization, language toggle, and multi-source failure recovery.

---

## 🚀 Deployment & DevOps

### Local / On-Premise (Docker Compose)
Run the entire platform locally or on an edge appliance:
```bash
# 1. Copy environment configurations
cp .env.example .env

# 2. Start all microservices in the background
docker-compose up -d --build

# 3. Verify health
curl http://localhost:3001/api/v1/health
curl http://localhost:8000/health
```

### Production Cloud Deployment
- **Web App**: Hosted on Vercel (`https://lensiq-ebon.vercel.app/app/`)
- **Database & Auth**: Supabase PostgreSQL with RLS and Point-in-Time Recovery (PITR).
- **Video & AI Services**: Deployable via Docker container to AWS ECS, GCP Cloud Run, or on-prem edge servers.

---

## 📚 Technical Documentation

- [docs/HIKVISION_INTEGRATION_GUIDE.md](docs/HIKVISION_INTEGRATION_GUIDE.md): Protocols (ISAPI, OpenAPI, Artemis), tested hardware models, and OS requirements.
- [docs/MONITORING_AND_RECOVERY.md](docs/MONITORING_AND_RECOVERY.md): Prometheus/Grafana setup, health checks, stream reconnect backoff, and database backups.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): Multi-tenant entity-relationship and sequence diagrams.
