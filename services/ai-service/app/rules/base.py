from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Optional, Dict, Any, List
from app.models.detection import DetectionResult, DetectedObject
from app.models.roi import RegionOfInterest
from app.models.events import AIEvent

class RuleContext:
    def __init__(
        self,
        camera_id: str,
        roi: RegionOfInterest,
        timestamp: float,
        detections: List[DetectedObject],
        people_in_roi: int,
    ):
        self.camera_id = camera_id
        self.roi = roi
        self.timestamp = timestamp
        self.detections = detections
        self.people_in_roi = people_in_roi

class BaseRule(ABC):
    def __init__(self, rule_id: str, name: str, enabled: bool = True):
        self.rule_id = rule_id
        self.name = name
        self.enabled = enabled

    @abstractmethod
    def evaluate(self, ctx: RuleContext) -> Optional[AIEvent]:
        """Evaluates rule logic on current frame context."""
        pass

    @abstractmethod
    def reset(self) -> None:
        """Resets internal state."""
        pass

    @abstractmethod
    def get_state(self) -> Dict[str, Any]:
        """Returns serialized state for status inspections."""
        pass
