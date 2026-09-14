from __future__ import annotations

from abc import ABC, abstractmethod
from typing import List
from app.models.detection import DetectedObject

class BaseTracker(ABC):
    """
    Abstract Base Class for Multi-Object Trackers (e.g. ByteTrack / BoT-SORT).
    Prepares Phase 2 architecture for persistent object track IDs across frames.
    """
    @abstractmethod
    def update(self, detections: List[DetectedObject]) -> List[DetectedObject]:
        """Update tracker state with new frame detections and assign track IDs."""
        pass
