from __future__ import annotations

import time
from typing import List, Optional, Dict
import numpy as np
from app.detectors.base import BaseDetector
from app.models.detection import BoundingBox, DetectedObject, DetectionResult
from app.core.config import settings
from app.core.device import detect_compute_device
from app.core.logging import logger

class YOLOv8Detector(BaseDetector):
    """
    Production detector wrapping Ultralytics YOLOv8.
    Supports auto-detected CUDA/MPS/CPU inference and extensible COCO classes.
    """
    def __init__(self, model_name: Optional[str] = None):
        self.model_name = model_name or settings.MODEL_NAME
        self.model = None
        self.device, self.device_desc = detect_compute_device()
        self.target_classes = settings.TARGET_CLASSES

    def load(self) -> None:
        try:
            from ultralytics import YOLO
            logger.info(f"Loading YOLOv8 model '{self.model_name}' on {self.device_desc}...")
            self.model = YOLO(self.model_name)
            logger.info(f"YOLOv8 model loaded successfully on {self.device}")
        except Exception as e:
            logger.error(f"Failed to load YOLOv8 model '{self.model_name}': {e}")
            raise e

    def detect(
        self,
        frame: np.ndarray,
        camera_id: str,
        timestamp: float,
        target_classes: Optional[List[str]] = None,
        confidence_threshold: Optional[float] = None,
    ) -> DetectionResult:
        if self.model is None:
            self.load()

        conf = confidence_threshold if confidence_threshold is not None else settings.CONFIDENCE_THRESHOLD
        classes_to_filter = target_classes or self.target_classes

        start_time = time.perf_counter()

        # Run inference
        results = self.model.predict(
            source=frame,
            conf=conf,
            iou=settings.IOU_THRESHOLD,
            device=self.device,
            verbose=False,
            imgsz=(settings.INPUT_RESOLUTION_HEIGHT, settings.INPUT_RESOLUTION_WIDTH)
        )

        detected_objects: List[DetectedObject] = []
        person_count = 0

        for r in results:
            boxes = r.boxes
            if boxes is None:
                continue

            for box in boxes:
                cls_id = int(box.cls[0].item())
                cls_name = r.names.get(cls_id, str(cls_id))

                # Filter target classes if specified
                if classes_to_filter and cls_name not in classes_to_filter:
                    continue

                confidence = float(box.conf[0].item())
                coords = box.xyxy[0].tolist()  # [x1, y1, x2, y2]

                bbox = BoundingBox(
                    x_min=float(coords[0]),
                    y_min=float(coords[1]),
                    x_max=float(coords[2]),
                    y_max=float(coords[3]),
                )

                if cls_name == "person":
                    person_count += 1

                detected_objects.append(
                    DetectedObject(
                        class_id=cls_id,
                        class_name=cls_name,
                        confidence=round(confidence, 3),
                        bbox=bbox,
                        track_id=None,
                        in_roi_ids=[]
                    )
                )

        inference_time_ms = (time.perf_counter() - start_time) * 1000.0

        return DetectionResult(
            camera_id=camera_id,
            frame_timestamp=timestamp,
            objects=detected_objects,
            person_count=person_count,
            inference_time_ms=round(inference_time_ms, 2)
        )
