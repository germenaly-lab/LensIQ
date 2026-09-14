# LensIQ Multi-Source Backend API Documentation (Phase 3)

The **LensIQ Express Backend** decouples the platform from RTSP, enabling transparent streaming and administration across multiple video source types (**RTSP** and **Hikvision P2P / Hik-Connect**).

---

## 1. Camera Management API

### List Cameras
* **Endpoint:** `GET /api/v1/cameras`
* **Query Parameters:**
  - `companyId` (string, optional)
  - `branchId` (string, optional)
  - `sourceType` (`rtsp` | `hikvision_p2p`, optional)
* **Response (200 OK):**
```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "id": "44444444-4444-4444-4444-444444444441",
      "company_id": "11111111-1111-1111-1111-111111111111",
      "name": "Cashier 01",
      "source_type": "rtsp",
      "enabled": true,
      "status": "online",
      "rtsp_url": "rtsp://stream.ego-store.demo/live/cashier01",
      "stream_profile": "main"
    },
    {
      "id": "44444444-4444-4444-4444-444444444442",
      "company_id": "11111111-1111-1111-1111-111111111111",
      "name": "Main Entrance",
      "source_type": "hikvision_p2p",
      "enabled": true,
      "status": "online",
      "hik_device_id": "HIK-DS-2CD2143G2-DEMO-01",
      "hik_channel": 1,
      "stream_profile": "main"
    }
  ]
}
```

---

### Create Camera
* **Endpoint:** `POST /api/v1/cameras`

#### RTSP Payload Example:
```json
{
  "name": "Drive-Thru Lane 1",
  "company_id": "11111111-1111-1111-1111-111111111111",
  "brand_id": "22222222-2222-2222-2222-222222222222",
  "branch_id": "33333333-3333-3333-3333-333333333333",
  "source_type": "rtsp",
  "rtsp_url": "rtsp://camera.local:554/live/ch1",
  "stream_profile": "main",
  "credentials_payload": {
    "username": "admin",
    "password": "secret_password"
  }
}
```

#### Hikvision P2P Payload Example:
```json
{
  "name": "Warehouse Loading Bay",
  "company_id": "11111111-1111-1111-1111-111111111111",
  "brand_id": "22222222-2222-2222-2222-222222222222",
  "branch_id": "33333333-3333-3333-3333-333333333333",
  "source_type": "hikvision_p2p",
  "hik_device_id": "HIK-BAY-4491-IS",
  "hik_serial_number": "SER-BAY-99182",
  "hik_channel": 1,
  "stream_profile": "main",
  "credentials_payload": {
    "app_key": "hik_app_key_secret_123",
    "app_secret": "hik_app_secret_xyz"
  }
}
```

---

## 2. Streaming Session API

### Initiate Streaming Session
* **Endpoint:** `POST /api/v1/streams/:cameraId/session`
* **Delegation Concept:**
  `camera` ➔ `source_type` ➔ `RTSPSourceService` OR `HikvisionP2PSourceService` ➔ `Streaming Gateway` ➔ `WebRTC/HLS`
* **Response (201 Created):**
```json
{
  "success": true,
  "message": "Streaming session initiated successfully.",
  "data": {
    "sessionId": "sess_hik_44444444_1789428000",
    "cameraId": "44444444-4444-4444-4444-444444444442",
    "sourceType": "hikvision_p2p",
    "connectionStatus": "configured",
    "streamProfile": "main",
    "playbackProtocol": "webrtc",
    "streamEndpoint": "https://stream.lensiq.cloud/live/p2p/HIK-DS-2CD2143G2-DEMO-01/ch1.whip",
    "aiNormalizedStreamUrl": "https://stream.lensiq.cloud/internal/raw-feed/44444444-4444-4444-4444-444444444442/h264",
    "isP2P": true,
    "createdAt": "2026-09-15T02:20:00.000Z",
    "expiresAt": "2026-09-15T06:20:00.000Z"
  }
}
```

---

## 3. AI Vision Compatibility
The **Python AI Microservice (Phase 2)** consumes `aiNormalizedStreamUrl`, allowing seamless computer vision inference regardless of whether the physical feed is RTSP direct or Hik-Connect P2P relay.
