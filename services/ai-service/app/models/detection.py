from __future__ import annotations

from typing import List, Optional, Tuple
from pydantic import BaseModel, Field

class BoundingBox(BaseModel):
    x_min: float = Field(..., description="Top-left X coordinate")
    y_min: float = Field(..., description="Top-left Y coordinate")
    x_max: float = Field(..., description="Bottom-right X coordinate")
    y_max: float = Field(..., description="Bottom-right Y coordinate")

    @property
    def width(self) -> float:
        return max(0.0, self.x_max - self.x_min)

    @property
    def height(self) -> float:
        return max(0.0, self.y_max - self.y_min)

    @property
    def center(self) -> Tuple[float, float]:
        return ((self.x_min + self.x_max) / 2.0, (self.y_min + self.y_max) / 2.0)

    @property
    def bottom_center(self) -> Tuple[float, float]:
        """Footprint / ground contact point of the detected person."""
        return ((self.x_min + self.x_max) / 2.0, self.y_max)

class DetectedObject(BaseModel):
    class_id: int
    class_name: str
    confidence: float
    bbox: BoundingBox
    track_id: Optional[int] = None
    in_roi_ids: List[str] = Field(default_factory=list)

class DetectionResult(BaseModel):
    camera_id: str
    frame_timestamp: float
    objects: List[DetectedObject] = Field(default_factory=list)
    person_count: int = 0
    inference_time_ms: float = 0.0
