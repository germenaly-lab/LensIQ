from __future__ import annotations

from abc import ABC, abstractmethod
from typing import List, Optional, Any
import numpy as np
from app.models.detection import DetectionResult

class BaseDetector(ABC):
    @abstractmethod
    def load(self) -> None:
        """Load and initialize model weights."""
        pass

    @abstractmethod
    def detect(
        self,
        frame: np.ndarray,
        camera_id: str,
        timestamp: float,
        target_classes: Optional[List[str]] = None,
        confidence_threshold: Optional[float] = None,
    ) -> DetectionResult:
        """Run object detection on a single frame."""
        pass
