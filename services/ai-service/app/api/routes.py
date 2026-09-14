from __future__ import annotations

import base64
import time
from typing import List, Optional
import cv2
import numpy as np
from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Depends
from pydantic import BaseModel, Field

from app.core.config import settings
from app.core.device import detect_compute_device
from app.models.detection import DetectionResult
from app.models.roi import RegionOfInterest, ROIType
from app.models.events import AIEvent
from app.services.stream_processor import StreamProcessor
from app.detectors.mock_detector import MockDetector
from app.models.detection import BoundingBox

router = APIRouter()

# Global StreamProcessor instance
stream_processor = StreamProcessor()

class ProcessFrameRequest(BaseModel):
    camera_id: str
    image_base64: str
    timestamp: Optional[float] = None
    rois: Optional[List[RegionOfInterest]] = None

class ProcessFrameResponse(BaseModel):
    camera_id: str
    detection: DetectionResult
    events: List[AIEvent]
    fps_limited: bool = False

class SimulateCashierEmptyRequest(BaseModel):
    camera_id: str = Field(default="cam-cashier-01")
    roi_id: str = Field(default="roi-cashier-zone")
    roi_name: str = Field(default="Cashier 01 Area")
    step_seconds: float = Field(default=60.0, description="Seconds to jump between simulation steps")
    total_duration: float = Field(default=185.0, description="Total empty duration to simulate")

class SimulationStepResult(BaseModel):
    elapsed_seconds: float
    people_detected: int
    rule_state: dict
    event_generated: Optional[AIEvent] = None

class SimulateCashierEmptyResponse(BaseModel):
    message: str
    camera_id: str
    steps: List[SimulationStepResult]
    final_event_triggered: bool

@router.get("/health", summary="Service Health & Hardware Check")
async def health_check():
    device, device_desc = detect_compute_device()
    return {
        "status": "healthy",
        "service": "LensIQ AI Computer Vision Microservice",
        "version": "1.0.0",
        "device": device,
        "device_description": device_desc,
        "model_name": settings.MODEL_NAME,
        "mock_mode": settings.MOCK_DETECTION_MODE,
        "target_classes": settings.TARGET_CLASSES,
        "timestamp": time.time(),
    }

@router.get("/status", summary="Runtime Metrics and Rule States")
async def get_status():
    device, device_desc = detect_compute_device()
    rule_states = stream_processor.rule_engine.get_all_states()
    return {
        "status": "active",
        "device": device_desc,
        "active_camera_rules": rule_states,
        "settings": {
            "max_fps": settings.MAX_PROCESSING_FPS,
            "confidence_threshold": settings.CONFIDENCE_THRESHOLD,
            "backend_url": settings.NODE_BACKEND_URL,
            "event_forwarding": settings.EVENT_FORWARDING_ENABLED,
        },
    }

@router.post("/process/frame", response_model=ProcessFrameResponse, summary="Analyze Video Frame")
async def process_frame(payload: ProcessFrameRequest):
    current_time = payload.timestamp or time.time()

    # Rate limiting check
    if not stream_processor.should_process_frame(payload.camera_id, current_time):
        return ProcessFrameResponse(
            camera_id=payload.camera_id,
            detection=DetectionResult(camera_id=payload.camera_id, frame_timestamp=current_time),
            events=[],
            fps_limited=True,
        )

    # Decode base64 image
    try:
        raw_data = base64.b64decode(payload.image_base64)
        np_arr = np.frombuffer(raw_data, np.uint8)
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        if frame is None:
            raise ValueError("cv2.imdecode returned None")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid base64 image data: {str(e)}")

    detection_result, events = await stream_processor.process_frame(
        frame=frame,
        camera_id=payload.camera_id,
        timestamp=current_time,
        rois=payload.rois or [],
    )

    return ProcessFrameResponse(
        camera_id=payload.camera_id,
        detection=detection_result,
        events=events,
        fps_limited=False,
    )

@router.post("/process/test", response_model=ProcessFrameResponse, summary="Process Synthetic Test Frame")
async def process_test_frame():
    # Generate synthetic 640x640 black frame with mock cashier ROI
    test_frame = np.zeros((settings.INPUT_RESOLUTION_HEIGHT, settings.INPUT_RESOLUTION_WIDTH, 3), dtype=np.uint8)
    camera_id = "test-cam-01"
    now = time.time()

    cashier_roi = RegionOfInterest(
        id="test-cashier-roi-01",
        name="Test Cashier Counter",
        roi_type=ROIType.RECTANGLE,
        points=[(100.0, 100.0), (400.0, 400.0)],
    )

    detection_result, events = await stream_processor.process_frame(
        frame=test_frame,
        camera_id=camera_id,
        timestamp=now,
        rois=[cashier_roi],
    )

    return ProcessFrameResponse(
        camera_id=camera_id,
        detection=detection_result,
        events=events,
        fps_limited=False,
    )

@router.post("/simulate/cashier-empty", response_model=SimulateCashierEmptyResponse, summary="Simulate Cashier Empty Over Time")
async def simulate_cashier_empty(req: SimulateCashierEmptyRequest):
    """
    Simulates the Cashier Empty Rule over time (0s -> 180s) to demonstrate
    incident detection without needing a real live CCTV stream.
    """
    dummy_frame = np.zeros((640, 640, 3), dtype=np.uint8)
    sim_processor = StreamProcessor(detector=MockDetector(simulated_people_boxes=[]))

    roi = RegionOfInterest(
        id=req.roi_id,
        name=req.roi_name,
        roi_type=ROIType.RECTANGLE,
        points=[(50.0, 50.0), (350.0, 350.0)],
    )

    start_timestamp = 1000.0
    steps: List[SimulationStepResult] = []
    final_event: Optional[AIEvent] = None

    # Step through time from t=0 to total_duration
    elapsed = 0.0
    while elapsed <= req.total_duration:
        sim_time = start_timestamp + elapsed

        # Empty frame, so 0 people in ROI
        _, events = await sim_processor.process_frame(
            frame=dummy_frame,
            camera_id=req.camera_id,
            timestamp=sim_time,
            rois=[roi],
            forward_events=False
        )

        event_for_step = events[0] if events else None
        if event_for_step:
            final_event = event_for_step

        rule_state = sim_processor.rule_engine.get_all_states().get(f"{req.camera_id}:{req.roi_id}", [{}])[0]

        steps.append(
            SimulationStepResult(
                elapsed_seconds=elapsed,
                people_detected=0,
                rule_state=rule_state,
                event_generated=event_for_step,
            )
        )

        elapsed += req.step_seconds

    return SimulateCashierEmptyResponse(
        message=f"Simulation complete for {req.total_duration}s empty duration.",
        camera_id=req.camera_id,
        steps=steps,
        final_event_triggered=final_event is not None,
    )
