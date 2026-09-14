from __future__ import annotations

from enum import Enum
from typing import List, Tuple
from pydantic import BaseModel, Field

class ROIType(str, Enum):
    RECTANGLE = "rectangle"
    POLYGON = "polygon"

class RegionOfInterest(BaseModel):
    id: str = Field(..., description="Unique ROI identifier")
    name: str = Field(..., description="Human readable name, e.g. 'Cashier 01 Zone'")
    roi_type: ROIType = Field(default=ROIType.RECTANGLE)
    # For RECTANGLE: [[x_min, y_min], [x_max, y_max]] or 4 points
    # For POLYGON: [[x1, y1], [x2, y2], [x3, y3], ...]
    points: List[Tuple[float, float]] = Field(
        ...,
        description="Vertices of the ROI. Rectangles require 2 or 4 points, Polygons require >= 3 points."
    )
