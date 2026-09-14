from __future__ import annotations

import time
from typing import List, Optional
import numpy as np
from app.detectors.base import BaseDetector
from app.models.detection import BoundingBox, DetectedObject, DetectionResult
from app.core.logging import logger

class MockDetector(BaseDetector):
    """
    Mock Detector for offline testing, CI/CD pipelines, and demo environments.
    Operates without PyTorch, CUDA, or downloading YOLO weights.
    """
    def __init__(self, simulated_people_boxes: Optional[List[BoundingBox]] = None):
        self.simulated_people_boxes = simulated_people_boxes or []
        self._loaded = False

    def set_simulated_boxes(self, boxes: List[BoundingBox]) -> None:
        self.simulated_people_boxes = boxes

    def load(self) -> None:
        self._loaded = True
        logger.info("MockDetector loaded successfully (Mock Mode active)")

    def detect(
        self,
        frame: np.ndarray,
        camera_id: str,
        timestamp: float,
        target_classes: Optional[List[str]] = None,
        confidence_threshold: Optional[float] = None,
    ) -> DetectionResult:
        start_time = time.perf_counter()
        objects: List[DetectedObject] = []

        for idx, bbox in enumerate(self.simulated_people_boxes):
            objects.append(
                DetectedObject(
                    class_id=0,
                    class_name="person",
                    confidence=0.92,
                    bbox=bbox,
                    track_id=idx + 1,
                    in_roi_ids=[]
                )
            )

        inference_time_ms = (time.perf_counter() - start_time) * 1000.0

        return DetectionResult(
            camera_id=camera_id,
            frame_timestamp=timestamp,
            objects=objects,
            person_count=len(objects),
            inference_time_ms=round(inference_time_ms, 2)
        )
