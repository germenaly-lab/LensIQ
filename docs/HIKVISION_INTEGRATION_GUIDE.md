# Hikvision Camera Integration Guide — LensIQ Enterprise Platform

## 1. Overview & Architecture
LensIQ supports dual-ingestion video sources:
1. **Direct RTSP over TCP/UDP** (Standard IP cameras, NVR channels, ONVIF Profile S).
2. **Hikvision P2P & Hik-Connect Cloud Relay** (Remote branch cameras operating behind strict NAT/firewalls without port forwarding or dynamic DNS).

```
+-----------------------------------------------------------------------------------+
|                              Branch Local Network                                  |
|                                                                                   |
|   +-----------------------+                    +------------------------------+   |
|   | Hikvision IP Cameras  |                    | Hikvision NVR                |   |
|   | (DS-2CD2xxx / 7xxx)   |                    | (DS-76xx / DS-77xx)          |   |
|   +-----------+-----------+                    +--------------+---------------+   |
|               |                                               |                   |
+---------------|-----------------------------------------------|-------------------+
                |                                               |
                v                                               v
    [Local ISAPI / RTSP]                            [Local ISAPI / RTSP]
                |                                               |
                +-----------------------+-----------------------+
                                        |
                 +----------------------+----------------------+
                 | (Option A: Direct)   | (Option B: Cloud P2P)
                 v                      v
      +---------------------+   +-------------------------------+
      | LensIQ Edge Gateway |   | Hik-Connect Cloud Platform    |
      | (MediaMTX / Docker) |   | (Artemis OpenAPI / P2P Relay) |
      +----------+----------+   +---------------+---------------+
                 |                              |
                 +--------------+---------------+
                                |
                                v
               +----------------------------------+
               |  LensIQ Core Cloud & AI Pipeline |
               |  - Ephemeral WHEP/WebRTC streams |
               |  - YOLOv8 Cashier Empty Rule     |
               |  - Zero-Credential Client HUD    |
               +----------------------------------+
```

---

## 2. Supported Protocols & Integration Methods

### A. Hik-Connect / Artemis OpenAPI (Recommended for Multi-Branch WAN)
* **Use Case**: Connecting retail branches (e.g. Mall of Arabia, Cairo Festival City) without public static IPs or inbound router firewall openings.
* **Mechanism**: Cameras connect outbound to the Hikvision Cloud Broker. The LensIQ backend requests ephemeral streaming tokens using signed Artemis API headers (`AppKey`, `AppSecret`, `HMAC-SHA256`).
* **Endpoints**:
  * Device registration: `/artemis/api/v1/netp/device/add`
  * Live URL extraction: `/artemis/api/v1/video/cameras/previewURLs`
* **Transport**: Ephemeral HLS/WebSockets/WebRTC proxy.

### B. ISAPI (Intelligent Security API) & Direct RTSP
* **Use Case**: On-premise installations, LAN-connected edge servers, or sites with site-to-site VPNs.
* **Mechanism**: Direct HTTP digest authentication and RTSP stream negotiation (`rtsp://username:password@camera-ip:554/Streaming/Channels/101`).
* **Endpoints**:
  * System Capabilities: `GET /ISAPI/System/deviceInfo`
  * Stream Channels: `GET /ISAPI/Streaming/channels`
  * Analytics Events: `GET /ISAPI/Event/notification/alertStream`

### C. Native C/C++ SDK (`HCNetSDK`) Considerations
* **Linux (Ubuntu / Debian x86_64 / arm64)**: Supported via vendor `.so` libraries (`libhcnetsdk.so`). Best suited for edge micro-appliances (NVIDIA Jetson, Intel NUC).
* **macOS (Darwin)**: Hikvision does not supply production-grade macOS ARM64 `.dylib` binaries.
* **LensIQ Abstraction Guarantee**: The LensIQ architecture abstracts camera connection behind `CameraSourceFactory` and `StreamingGatewayService`. The Flutter Web/Mobile client and the Python AI pipeline communicate exclusively through standard sanitized WebRTC/HLS protocols and REST event buses.

---

## 3. Supported Hardware Models & Series

| Series | Model Families | Tested Firmware | Capabilities Verified |
| :--- | :--- | :--- | :--- |
| **DeepinView** | DS-2CD7xxx, iDS-2CD7xxx | V5.7.12+ | Dual Streams, AcuSense, On-board Face & Vehicle Detection |
| **Ultra Series** | DS-2CD5xxx | V5.6.80+ | 4K Main Stream, Sub-stream RTSP, WDR |
| **Pro / AcuSense** | DS-2CD20xx, DS-2CD21xx, DS-2CD23xx | V5.5.800+ | RTSP, Hik-Connect P2P, Line Crossing, Intrusion Detection |
| **ColorVu** | DS-2CD2347G2-LU, DS-2CD2047G2-LU | V5.7.2+ | 24/7 Full Color, High Sensitivity in Low Light (Cashier counters) |
| **Embedded NVRs** | DS-7608NI-I2, DS-7716NI-I4, DS-9632NI-I8 | V4.61+ | Multi-channel RTSP bypass (`/Streaming/Channels/{channel}01`) |

---

## 4. Camera Configuration Checklist

Before registering a camera into LensIQ:
1. **Enable Hik-Connect**:
   * Navigate to `Configuration` ➔ `Network` ➔ `Advanced Settings` ➔ `Platform Access`.
   * Access Type: `Hik-Connect`.
   * Enable Status: `Online`.
   * Create a strong **Verification Code** (6–12 alphanumeric characters).
2. **Video Stream Settings**:
   * **Video Encoding**: H.264 (Baseline or Main Profile). H.265 is supported for storage, but H.264 offers ultra-low latency WebRTC browser decoding.
   * **Resolution**: Main stream 1080p (1920x1080) @ 20–25 fps. Sub-stream 720p or 360p for mobile grid multi-view.
   * **Bitrate Type**: VBR (Variable) or CBR (Constant) at 2048–4096 Kbps.
3. **Security Isolation**:
   * Place cameras on an isolated CCTV VLAN.
   * Restrict management access to the LensIQ Edge Gateway IP.

---

## 5. Security & Zero-Credential Exposure

LensIQ enforces strict data privacy:
* Camera passwords and Hikvision verification codes are stored in `camera_credentials_vault` encrypted using AES-256-GCM.
* Clients (Web browsers, iOS, Android) **never** receive raw passwords, RTSP URLs, or P2P master keys.
* The backend generates ephemeral, time-bounded tokens (`stream_token`) valid for 1 hour.
* Token renewal and disconnect cleanups are managed automatically.
