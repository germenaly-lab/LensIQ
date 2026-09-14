from __future__ import annotations

from typing import Dict, List, Optional
from app.models.detection import DetectionResult, DetectedObject
from app.models.roi import RegionOfInterest
from app.models.events import AIEvent
from app.rules.base import BaseRule, RuleContext
from app.rules.cashier_empty import CashierEmptyRule
from app.utils.roi_math import is_bbox_in_roi
from app.core.logging import logger

class RuleEngine:
    """
    Stateful Rule Engine managing active cameras, ROIs, and rule instances.
    """
    def __init__(self):
        # Key: (camera_id, roi_id) -> List[BaseRule]
        self.rules_registry: Dict[str, List[BaseRule]] = {}

    def _get_key(self, camera_id: str, roi_id: str) -> str:
        return f"{camera_id}:{roi_id}"

    def register_rule(self, camera_id: str, roi_id: str, rule: BaseRule) -> None:
        key = self._get_key(camera_id, roi_id)
        if key not in self.rules_registry:
            self.rules_registry[key] = []
        self.rules_registry[key].append(rule)
        logger.info(f"Registered rule '{rule.name}' for {key}")

    def get_or_create_default_cashier_rule(
        self,
        camera_id: str,
        roi_id: str,
        duration_seconds: float = 180.0
    ) -> BaseRule:
        key = self._get_key(camera_id, roi_id)
        if key in self.rules_registry and self.rules_registry[key]:
            return self.rules_registry[key][0]

        default_rule = CashierEmptyRule(
            rule_id=f"rule-cashier-{roi_id}",
            name="Cashier Area Empty",
            duration_seconds=duration_seconds,
        )
        self.register_rule(camera_id, roi_id, default_rule)
        return default_rule

    def process_frame_rules(
        self,
        camera_id: str,
        timestamp: float,
        detection_result: DetectionResult,
        rois: List[RegionOfInterest]
    ) -> List[AIEvent]:
        """
        Evaluates ROIs and rules for a single detection frame.
        Tags detected objects with ROI associations and returns triggered events.
        """
        events: List[AIEvent] = []

        for roi in rois:
            # 1. Calculate how many people are inside this ROI
            people_in_roi: List[DetectedObject] = []

            for obj in detection_result.objects:
                if obj.class_name == "person":
                    if is_bbox_in_roi(obj.bbox, roi):
                        if roi.id not in obj.in_roi_ids:
                            obj.in_roi_ids.append(roi.id)
                        people_in_roi.append(obj)

            people_count = len(people_in_roi)

            # 2. Retrieve or register rule for this ROI
            key = self._get_key(camera_id, roi.id)
            if key not in self.rules_registry:
                # Register default cashier rule if ROI implies cashier
                self.get_or_create_default_cashier_rule(camera_id, roi.id)

            active_rules = self.rules_registry.get(key, [])

            # 3. Evaluate each rule
            ctx = RuleContext(
                camera_id=camera_id,
                roi=roi,
                timestamp=timestamp,
                detections=people_in_roi,
                people_in_roi=people_count
            )

            for rule in active_rules:
                event = rule.evaluate(ctx)
                if event:
                    events.append(event)

        return events

    def get_all_states(self) -> Dict[str, List[Dict]]:
        states = {}
        for key, rules in self.rules_registry.items():
            states[key] = [r.get_state() for r in rules]
        return states

    def reset_all(self) -> None:
        for rules in self.rules_registry.values():
            for rule in rules:
                rule.reset()
