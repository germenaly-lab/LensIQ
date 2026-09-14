from __future__ import annotations

import time
from typing import List, Optional, Tuple, Dict
import numpy as np
from app.detectors.base import BaseDetector
from app.detectors.yolo_detector import YOLOv8Detector
from app.detectors.mock_detector import MockDetector
from app.rules.rule_engine import RuleEngine
from app.models.detection import DetectionResult
from app.models.roi import RegionOfInterest
from app.models.events import AIEvent
from app.services.backend_client import BackendClientService
from app.core.config import settings
from app.core.logging import logger

class StreamProcessor:
    """
    Central Video Stream Processing pipeline orchestrator.
    Manages detection, ROI calculations, rule evaluations, and event forwarding.
    """
    def __init__(
        self,
        detector: Optional[BaseDetector] = None,
        rule_engine: Optional[RuleEngine] = None,
        backend_client: Optional[BackendClientService] = None,
    ):
        if detector is not None:
            self.detector = detector
        elif settings.MOCK_DETECTION_MODE:
            self.detector = MockDetector()
        else:
            self.detector = YOLOv8Detector()

        self.rule_engine = rule_engine or RuleEngine()
        self.backend_client = backend_client or BackendClientService()
        self._last_processed_timestamps: Dict[str, float] = {}

    def should_process_frame(self, camera_id: str, current_time: float) -> bool:
        """
        FPS Rate Limiter: Enforces MAX_PROCESSING_FPS per camera stream
        to save GPU/CPU compute cycles.
        """
        min_interval = 1.0 / max(1, settings.MAX_PROCESSING_FPS)
        last_time = self._last_processed_timestamps.get(camera_id, 0.0)

        if current_time - last_time >= min_interval:
            self._last_processed_timestamps[camera_id] = current_time
            return True
        return False

    async def process_frame(
        self,
        frame: np.ndarray,
        camera_id: str,
        timestamp: Optional[float] = None,
        rois: Optional[List[RegionOfInterest]] = None,
        forward_events: bool = True,
    ) -> Tuple[DetectionResult, List[AIEvent]]:
        current_time = timestamp if timestamp is not None else time.time()
        active_rois = rois or []

        # 1. Run Object Detection
        detection_result = self.detector.detect(
            frame=frame,
            camera_id=camera_id,
            timestamp=current_time,
            target_classes=settings.TARGET_CLASSES,
            confidence_threshold=settings.CONFIDENCE_THRESHOLD,
        )

        # 2. Evaluate Stateful AI Rules
        events = self.rule_engine.process_frame_rules(
            camera_id=camera_id,
            timestamp=current_time,
            detection_result=detection_result,
            rois=active_rois,
        )

        # 3. Forward events to Node.js backend if enabled
        if forward_events and events:
            for event in events:
                await self.backend_client.forward_event(event)

        return detection_result, events
