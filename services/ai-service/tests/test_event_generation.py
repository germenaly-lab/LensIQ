from __future__ import annotations

import pytest
import numpy as np
from app.models.detection import BoundingBox
from app.models.roi import RegionOfInterest, ROIType
from app.detectors.mock_detector import MockDetector
from app.rules.rule_engine import RuleEngine
from app.rules.cashier_empty import CashierEmptyRule
from app.services.stream_processor import StreamProcessor
from app.services.backend_client import BackendClientService

@pytest.mark.asyncio
async def test_full_stream_pipeline_event_generation():
    # Setup mock detector with a person outside the ROI
    outside_box = BoundingBox(x_min=500.0, y_min=500.0, x_max=550.0, y_max=600.0)
    mock_detector = MockDetector(simulated_people_boxes=[outside_box])

    rule_engine = RuleEngine()
    backend_client = BackendClientService(enabled=False)
    processor = StreamProcessor(
        detector=mock_detector,
        rule_engine=rule_engine,
        backend_client=backend_client,
    )

    cashier_roi = RegionOfInterest(
        id="roi-cashier-ego",
        name="Ego MOA Cashier 01",
        roi_type=ROIType.RECTANGLE,
        points=[(50.0, 50.0), (300.0, 300.0)],
    )

    cashier_rule = CashierEmptyRule(
        rule_id="rule-cashier-ego-01",
        duration_seconds=180.0
    )
    rule_engine.register_rule("ego-cam-01", cashier_roi.id, cashier_rule)

    frame = np.zeros((640, 640, 3), dtype=np.uint8)

    # Step 1: At t=0s, empty inside ROI -> timer begins
    _, events_t0 = await processor.process_frame(
        frame=frame,
        camera_id="ego-cam-01",
        timestamp=1000.0,
        rois=[cashier_roi]
    )
    assert len(events_t0) == 0

    # Step 2: At t=185s, still empty inside ROI -> Event fires!
    _, events_t185 = await processor.process_frame(
        frame=frame,
        camera_id="ego-cam-01",
        timestamp=1185.0,
        rois=[cashier_roi]
    )
    assert len(events_t185) == 1
    event = events_t185[0]

    # Verify structured fields
    assert event.event_type == "CASHIER_EMPTY"
    assert event.camera_id == "ego-cam-01"
    assert event.roi_id == "roi-cashier-ego"
    assert event.rule_id == "rule-cashier-ego-01"
    assert event.confidence == 1.0
    assert event.people_count == 0
    assert event.duration >= 180.0
    assert "threshold_seconds" in event.metadata
