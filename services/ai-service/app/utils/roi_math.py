from __future__ import annotations

from typing import List, Tuple
import numpy as np
from app.models.detection import BoundingBox
from app.models.roi import RegionOfInterest, ROIType

def is_point_in_rectangle(point: Tuple[float, float], points: List[Tuple[float, float]]) -> bool:
    """
    Checks if a point (x, y) is inside a rectangle defined by 2 corner points or 4 vertices.
    """
    px, py = point
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return min(xs) <= px <= max(xs) and min(ys) <= py <= max(ys)

def is_point_in_polygon(point: Tuple[float, float], polygon_points: List[Tuple[float, float]]) -> bool:
    """
    Checks if point (x, y) is inside an arbitrary polygon using the Ray-Casting algorithm.
    Works natively in Python without requiring external C libraries.
    """
    px, py = point
    n = len(polygon_points)
    inside = False

    p1x, p1y = polygon_points[0]
    for i in range(1, n + 1):
        p2x, p2y = polygon_points[i % n]
        if py > min(p1y, p2y):
            if py <= max(p1y, p2y):
                if px <= max(p1x, p2x):
                    if p1y != p2y:
                        xinters = (py - p1y) * (p2x - p1x) / (p2y - p1y) + p1x
                    if p1x == p2x or px <= xinters:
                        inside = not inside
        p1x, p1y = p2x, p2y

    return inside

def is_bbox_in_roi(
    bbox: BoundingBox,
    roi: RegionOfInterest,
    evaluation_point: str = "bottom_center"
) -> bool:
    """
    Determines whether a detected bounding box is inside the ROI.
    By default in CCTV CV, the 'bottom_center' (footprint of the person) is used
    to accurately reflect real-world floor positioning.
    """
    if evaluation_point == "center":
        test_pt = bbox.center
    else:
        test_pt = bbox.bottom_center

    if roi.roi_type == ROIType.RECTANGLE:
        return is_point_in_rectangle(test_pt, roi.points)
    elif roi.roi_type == ROIType.POLYGON:
        return is_point_in_polygon(test_pt, roi.points)

    return False
