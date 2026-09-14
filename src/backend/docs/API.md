# LensIQ Streaming Gateway & Multi-Source Backend API

The **LensIQ Streaming Gateway** decouples Flutter mobile apps, Web dashboards, and the Python AI Computer Vision microservice from physical camera protocols. It transparently ingests both **RTSP** and **Hikvision P2P / Hik-Connect** cameras, transcoding/relaying them into authenticated **WebRTC** and **HLS** streams.

---

## Architecture Overview

```
RTSP Camera ───► RTSPSourceAdapter ─────────┐
                                            ├──► Streaming Gateway ──► WebRTC / HLS ──► Flutter App
Hikvision ─────► HikvisionP2PSourceAdapter ─┘         │
                                                      └──► Normalized Stream ──► Python AI Service
```

> [!IMPORTANT]
> The Flutter application **NEVER** connects directly to RTSP or Hikvision P2P hardware.
> All client playback streams are mediated by the Streaming Gateway using signed ephemeral tokens.

---

## 1. Streaming Gateway Endpoints

### 1.1 Initiate or Attach to a Streaming Session
* **Method & Route:** `POST /api/v1/streams/:cameraId/session`
* **Description:** Initiates or attaches to a live streaming session.
* **Process Lifecycle & Performance:** If multiple viewers in a branch watch the same camera, the gateway **deduplicates** the ingest pipeline—only **ONE** underlying FFmpeg / adapter stream runs, while viewer reference counts increment.
* **Request Body:**
```json
{
  "streamProfile": "main", // "main" | "sub" (default: "main")
  "protocol": "webrtc",    // "webrtc" | "hls" (default: "webrtc")
  "demoMode": true         // optional boolean
}
```
* **Response (201 Created):**
```json
{
  "success": true,
  "message": "Streaming session initiated successfully.",
  "data": {
    "session_id": "sess_44444444_1789428000_a9f1b",
    "camera_id": "44444444-4444-4444-4444-444444444441",
    "source_type": "rtsp",
    "stream_url": "https://stream.lensiq.cloud/api/v1/streams/playback/44444444-4444-4444-4444-444444444441/sess_44444444_1789428000_a9f1b/webrtc?token=ey...",
    "token": "eyJzZXNzaW9uSWQiOiJzZXNzXzQ0NDQ0NDQ0...",
    "protocol": "webrtc",
    "status": "active",
    "created_at": "2026-09-15T02:25:00.000Z",
    "expires_at": "2026-09-15T03:25:00.000Z",
    "viewer_count": 1,
    "demo_mode": true,
    "stream_info": {
      "resolution": "1920x1080",
      "fps": 30,
      "codec": "h264",
      "profile": "main"
    },
    "monitoring": {
      "connection_status": "streaming",
      "latency_ms": 42,
      "reconnect_count": 0,
      "last_error": null,
      "last_successful_frame": "2026-09-15T02:25:01.120Z",
      "stream_start_time": "2026-09-15T02:25:00.000Z",
      "uptime_seconds": 12,
      "viewer_count": 1
    },
    "aiNormalizedStreamUrl": "https://stream.lensiq.cloud/api/v1/internal/raw-feed/44444444-4444-4444-4444-444444444441?token=ey..."
  }
}
```

---

### 1.2 Verify Playback Token (Flutter Media Player)
* **Method & Route:** `GET /api/v1/streams/playback/:token`
* **Description:** Called by Flutter video player to validate ephemeral cryptographic token and retrieve active playback descriptor.
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Playback token verified.",
  "data": {
    "session_id": "sess_44444444_1789428000_a9f1b",
    "camera_id": "44444444-4444-4444-4444-444444444441",
    "source_type": "rtsp",
    "stream_url": "https://stream.lensiq.cloud/api/v1/streams/playback/44444444-4444-4444-4444-444444444441/sess_44444444_1789428000_a9f1b/webrtc?token=ey...",
    "status": "active"
  }
}
```

---

### 1.3 Trigger Explicit Camera Reconnection
* **Method & Route:** `POST /api/v1/streams/:cameraId/reconnect`
* **Description:** Triggers immediate reconnection sequence with exponential backoff on the underlying video source adapter.
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Camera reconnection executed successfully.",
  "data": {
    "connection_status": "streaming",
    "latency_ms": 45,
    "reconnect_count": 1,
    "last_error": null,
    "last_successful_frame": "2026-09-15T02:26:10.000Z",
    "stream_start_time": "2026-09-15T02:25:00.000Z",
    "uptime_seconds": 70,
    "viewer_count": 1
  }
}
```

---

### 1.4 Leave or Stop Stream Session
* **Method & Route:** `POST /api/v1/streams/:cameraId/stop`
* **Description:** Decrements viewer count. When `viewer_count == 0`, enters idle grace period before stopping ingest pipeline and releasing memory/process resources.
* **Request Body:**
```json
{
  "sessionId": "sess_44444444_1789428000_a9f1b"
}
```
* **Response (200 OK):**
```json
{
  "success": true,
  "message": "Stream session released successfully.",
  "data": {
    "released": true,
    "remainingViewers": 0,
    "pipelineState": "idle"
  }
}
```

---

### 1.5 Real-time Health Telemetry
* **Method & Route:** `GET /api/v1/streams/:cameraId/status`
* **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "connection_status": "streaming",
    "latency_ms": 42,
    "reconnect_count": 0,
    "last_error": null,
    "last_successful_frame": "2026-09-15T02:27:00.000Z",
    "stream_start_time": "2026-09-15T02:25:00.000Z",
    "uptime_seconds": 120,
    "viewer_count": 2
  }
}
```

---

## 2. Camera Management APIs

* `GET /api/v1/cameras` — List cameras with multi-tenant filtering.
* `POST /api/v1/cameras` — Register new camera (`source_type: "rtsp"` or `"hikvision_p2p"`).
* `GET /api/v1/cameras/:id` — Retrieve camera configuration (guaranteed zero raw credential exposure).

---

## 3. Hikvision Integration Policy
Consult [`HIKVISION_INTEGRATION_ASSESSMENT.md`](file:///Users/POM/Developer/personel/lensIQ/src/backend/streaming/docs/HIKVISION_INTEGRATION_ASSESSMENT.md) for official Hik-Connect Open Platform and ISUP 5.0 evaluation.
