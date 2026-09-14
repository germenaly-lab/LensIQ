# LensIQ — AI Computer Vision Microservice (Phase 2)

The **LensIQ AI Service** is a dedicated Computer Vision microservice built with **Python 3.11+**, **FastAPI**, **YOLOv8 (Ultralytics)**, **OpenCV**, and **NumPy**. It analyzes live video streams, extracts detected objects (primarily people, but extensible to cars, bags, phones, etc.), evaluates region-of-interest (ROI) containment, runs stateful temporal rules, and forwards structured security incidents to the Node.js backend.

---

## 🏗️ Architecture

```
                                +---------------------------+
                                |  CCTV Frame / Mock Source |
                                +-------------+-------------+
                                              |
                                              v
                                +---------------------------+
                                |      StreamProcessor      |
                                | - Configurable FPS Limit  |
                                +-------------+-------------+
                                              |
                     +------------------------+------------------------+
                     |                                                 |
                     v                                                 v
        +-------------------------+                       +-------------------------+
        |     YOLOv8 Detector     |                       |    ROI Math Utility     |
        | - Auto GPU/MPS/CPU      |                       | - Rectangular ROIs      |
        | - Extensible Classes    |                       | - Polygon ROIs (Raycast)|
        +------------+------------+                       +------------+------------+
                     |                                                 |
                     +------------------------+------------------------+
                                              |
                                              v
                                +---------------------------+
                                |     Rule Engine (State)   |
                                | - CashierEmptyRule (180s) |
                                | - Duplicate Suppression   |
                                +-------------+-------------+
                                              | (Event triggered)
                                              v
                                +---------------------------+
                                |   BackendClientService    |
                                | -> Node.js /api/v1/events |
                                +---------------------------+
```

---

## 🎯 Core Features

1. **YOLOv8 Detection Engine**:
   - Primary: `person` detection.
   - Extensible classes: `bag`, `car`, `chair`, `cell phone`, etc.
   - Automatic compute device selection: NVIDIA CUDA GPU ➔ Apple Silicon MPS ➔ CPU.
2. **ROI Containment**:
   - Supports both `rectangle` and `polygon` geometries.
   - Accurately checks the ground contact point (`bottom_center`) of detected people against ROI boundaries.
3. **Cashier Area Empty Rule**:
   - Rule parameters: `minimum_people = 0`, `duration_seconds = 180` (3 minutes).
   - Stateful lifecycle:
     - Empty starts ➔ timer starts.
     - Person enters ➔ timer resets.
     - Empty again ➔ timer starts again from 0.
     - 180 seconds continuous empty ➔ triggers `CASHIER_EMPTY` event.
     - Prevents duplicate incident flooding while remaining empty.
4. **Mock / Demo Mode**:
   - Run complete tests and live simulations (`/simulate/cashier-empty`) without needing a physical CCTV camera or GPU.
5. **Secure Internal Integration**:
   - Events are forwarded to the Node.js backend via internal secret key header (`X-Internal-Service-Key`), never exposing database credentials.

---

## 📡 API Endpoints

| Method | Path | Description |
| :--- | :--- | :--- |
| `GET` | `/health` | Hardware check (GPU/MPS/CPU), version, model status. |
| `GET` | `/status` | Active cameras, active rule states, and metric counters. |
| `POST` | `/process/frame` | Ingests a frame (base64) with ROIs, returns detections and triggered events. |
| `POST` | `/process/test` | Processes a synthetic test frame. |
| `POST` | `/simulate/cashier-empty` | Simulates a 180s empty cashier episode over time. |

---

## 🛠️ Quick Start

### 1. Local Setup

```bash
cd services/ai-service

# Create and activate virtualenv
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest
```

### 2. Start the Service

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Interactive API Swagger documentation is available at:
👉 `http://localhost:8000/docs`

---

## 🐳 Docker Deployment

```bash
docker build -t lensiq-ai-service .
docker run -p 8000:8000 --env-file .env lensiq-ai-service
```
