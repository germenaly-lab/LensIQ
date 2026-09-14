from __future__ import annotations

import pytest
from app.models.detection import BoundingBox
from app.models.roi import RegionOfInterest, ROIType
from app.utils.roi_math import (
    is_point_in_rectangle,
    is_point_in_polygon,
    is_bbox_in_roi,
)

def test_rectangular_roi_containment():
    rect_roi = RegionOfInterest(
        id="roi-rect-01",
        name="Cashier Zone Rect",
        roi_type=ROIType.RECTANGLE,
        points=[(100.0, 100.0), (300.0, 400.0)]
    )

    # Person inside (bottom_center: (200, 350))
    inside_bbox = BoundingBox(x_min=150.0, y_min=150.0, x_max=250.0, y_max=350.0)
    assert is_bbox_in_roi(inside_bbox, rect_roi) is True

    # Person outside (bottom_center: (500, 500))
    outside_bbox = BoundingBox(x_min=450.0, y_min=400.0, x_max=550.0, y_max=500.0)
    assert is_bbox_in_roi(outside_bbox, rect_roi) is False

def test_polygon_roi_containment():
    # Triangle / Pentagon polygon
    poly_roi = RegionOfInterest(
        id="roi-poly-01",
        name="Cashier Counter Polygon",
        roi_type=ROIType.POLYGON,
        points=[
            (100.0, 100.0),
            (300.0, 100.0),
            (350.0, 300.0),
            (250.0, 450.0),
            (100.0, 400.0),
        ]
    )

    # Point clearly inside polygon
    assert is_point_in_polygon((200.0, 200.0), poly_roi.points) is True

    # Point outside polygon
    assert is_point_in_polygon((50.0, 50.0), poly_roi.points) is False
    assert is_point_in_polygon((400.0, 200.0), poly_roi.points) is False

    # Person with bottom-center inside polygon
    person_inside = BoundingBox(x_min=180.0, y_min=150.0, x_max=220.0, y_max=250.0)
    assert is_bbox_in_roi(person_inside, poly_roi) is True

    # Person with bottom-center outside polygon
    person_outside = BoundingBox(x_min=400.0, y_min=100.0, x_max=460.0, y_max=200.0)
    assert is_bbox_in_roi(person_outside, poly_roi) is False
