from __future__ import annotations

import pytest
import numpy as np
from app.models.detection import BoundingBox, DetectedObject, DetectionResult
from app.detectors.mock_detector import MockDetector

def test_bounding_box_properties():
    bbox = BoundingBox(x_min=100.0, y_min=150.0, x_max=300.0, y_max=450.0)
    assert bbox.width == 200.0
    assert bbox.height == 300.0
    assert bbox.center == (200.0, 300.0)
    assert bbox.bottom_center == (200.0, 450.0)

def test_person_detection_parsing():
    boxes = [
        BoundingBox(x_min=50.0, y_min=50.0, x_max=150.0, y_max=250.0),
        BoundingBox(x_min=200.0, y_min=100.0, x_max=300.0, y_max=350.0),
    ]
    detector = MockDetector(simulated_people_boxes=boxes)
    detector.load()

    frame = np.zeros((640, 640, 3), dtype=np.uint8)
    res = detector.detect(frame=frame, camera_id="cam-01", timestamp=1000.0)

    assert res.camera_id == "cam-01"
    assert res.person_count == 2
    assert len(res.objects) == 2
    assert res.objects[0].class_name == "person"
    assert res.objects[0].confidence == 0.92
    assert res.objects[0].bbox.bottom_center == (100.0, 250.0)
    assert res.inference_time_ms >= 0.0
