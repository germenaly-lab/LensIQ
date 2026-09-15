from __future__ import annotations

import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_health_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "device" in data
        assert "model_name" in data
        assert "target_classes" in data

@pytest.mark.asyncio
async def test_status_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/status")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "active"
        assert "active_camera_rules" in data

@pytest.mark.asyncio
async def test_process_test_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/process/test")
        assert response.status_code == 200
        data = response.json()
        assert data["camera_id"] == "test-cam-01"
        assert "detection" in data

@pytest.mark.asyncio
async def test_simulate_cashier_empty_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        payload = {
            "camera_id": "sim-cashier-cam",
            "roi_id": "sim-roi-01",
            "roi_name": "Demo Cashier Counter",
            "step_seconds": 60.0,
            "total_duration": 185.0
        }
        response = await ac.post("/simulate/cashier-empty", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["final_event_triggered"] is True
        assert len(data["steps"]) >= 3

@pytest.mark.asyncio
async def test_metrics_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/metrics")
        assert response.status_code == 200
        data = response.json()
        assert "processing_fps" in data
        assert "avg_inference_time_ms" in data
        assert "cpu_usage_percent" in data
        assert "memory_usage_mb" in data
        assert "detection_latency_ms" in data

@pytest.mark.asyncio
async def test_config_endpoint_and_auth():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 1. GET config
        get_res = await ac.get("/config")
        assert get_res.status_code == 200
        assert "max_fps" in get_res.json()
        assert "confidence_threshold" in get_res.json()

        # 2. PUT config with invalid key -> 401
        invalid_res = await ac.put(
            "/config",
            json={"max_fps": 15, "confidence_threshold": 0.55},
            headers={"X-API-Key": "wrong-secret-key"}
        )
        assert invalid_res.status_code == 401

        # 3. PUT config with valid key -> 200
        valid_res = await ac.put(
            "/config",
            json={"max_fps": 15, "confidence_threshold": 0.55},
            headers={"X-API-Key": "lensiq-internal-service-secret-change-in-prod"}
        )
        assert valid_res.status_code == 200
        assert valid_res.json()["config"]["max_fps"] == 15
        assert valid_res.json()["config"]["confidence_threshold"] == 0.55

