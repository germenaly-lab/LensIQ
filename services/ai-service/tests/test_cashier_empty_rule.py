from __future__ import annotations

import pytest
from app.models.roi import RegionOfInterest, ROIType
from app.rules.base import RuleContext
from app.rules.cashier_empty import CashierEmptyRule

def test_cashier_empty_rule_lifecycle_and_timer():
    roi = RegionOfInterest(
        id="roi-cashier-01",
        name="Cashier 01",
        roi_type=ROIType.RECTANGLE,
        points=[(100.0, 100.0), (300.0, 300.0)]
    )

    rule = CashierEmptyRule(
        rule_id="rule-cashier-01",
        duration_seconds=180.0
    )

    # 1. At t=0s: Cashier becomes empty (people_in_roi = 0)
    ctx_t0 = RuleContext(camera_id="cam-01", roi=roi, timestamp=1000.0, detections=[], people_in_roi=0)
    event_t0 = rule.evaluate(ctx_t0)
    assert event_t0 is None
    assert rule.empty_start_time == 1000.0
    assert rule.current_duration == 0.0

    # 2. At t=60s: Still empty (60s elapsed < 180s)
    ctx_t60 = RuleContext(camera_id="cam-01", roi=roi, timestamp=1060.0, detections=[], people_in_roi=0)
    event_t60 = rule.evaluate(ctx_t60)
    assert event_t60 is None
    assert rule.current_duration == 60.0

    # 3. At t=120s: A person enters the Cashier area! (people_in_roi = 1)
    # MUST RESET TIMER!
    ctx_t120 = RuleContext(camera_id="cam-01", roi=roi, timestamp=1120.0, detections=[None], people_in_roi=1)
    event_t120 = rule.evaluate(ctx_t120)
    assert event_t120 is None
    assert rule.empty_start_time is None
    assert rule.current_duration == 0.0
    assert rule.has_triggered is False

    # 4. At t=130s: Person leaves, Cashier is empty again!
    # Timer starts FRESH at 1130.0!
    ctx_t130 = RuleContext(camera_id="cam-01", roi=roi, timestamp=1130.0, detections=[], people_in_roi=0)
    event_t130 = rule.evaluate(ctx_t130)
    assert event_t130 is None
    assert rule.empty_start_time == 1130.0

    # 5. At t=300s: 170s have elapsed from 1130.0 (170 < 180s) -> No event yet
    ctx_t300 = RuleContext(camera_id="cam-01", roi=roi, timestamp=1300.0, detections=[], people_in_roi=0)
    event_t300 = rule.evaluate(ctx_t300)
    assert event_t300 is None
    assert rule.current_duration == 170.0

    # 6. At t=310s: 180s reached! (1130 + 180 = 1310.0) -> EVENT TRIGGERED!
    ctx_t310 = RuleContext(camera_id="cam-01", roi=roi, timestamp=1310.0, detections=[], people_in_roi=0)
    event_t310 = rule.evaluate(ctx_t310)
    assert event_t310 is not None
    assert event_t310.event_type == "CASHIER_EMPTY"
    assert event_t310.camera_id == "cam-01"
    assert event_t310.roi_id == "roi-cashier-01"
    assert event_t310.duration >= 180.0
    assert rule.has_triggered is True

    # 7. At t=320s & t=350s: Still empty -> DUPLICATE EVENT SUPPRESSION!
    # Must NOT generate hundreds of duplicate incidents!
    ctx_t320 = RuleContext(camera_id="cam-01", roi=roi, timestamp=1320.0, detections=[], people_in_roi=0)
    event_t320 = rule.evaluate(ctx_t320)
    assert event_t320 is None

    ctx_t350 = RuleContext(camera_id="cam-01", roi=roi, timestamp=1350.0, detections=[], people_in_roi=0)
    event_t350 = rule.evaluate(ctx_t350)
    assert event_t350 is None
