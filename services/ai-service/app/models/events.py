from __future__ import annotations

from typing import Any, Dict, Optional
from datetime import datetime, timezone
from pydantic import BaseModel, Field

class AIEvent(BaseModel):
    id: Optional[str] = Field(default=None, description="Unique event identifier")
    event_type: str = Field(..., description="e.g. 'CASHIER_EMPTY'")
    camera_id: str = Field(..., description="Camera UUID or ID")
    roi_id: str = Field(..., description="ROI ID where rule fired")
    rule_id: str = Field(..., description="Rule identifier")
    detected_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat(),
        description="ISO 8601 UTC timestamp"
    )
    confidence: float = Field(default=1.0, ge=0.0, le=1.0)
    people_count: int = Field(default=0, ge=0)
    duration: float = Field(default=0.0, ge=0.0, description="Duration in seconds of condition")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional contextual data")
