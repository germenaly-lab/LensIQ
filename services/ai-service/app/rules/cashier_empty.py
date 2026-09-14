from __future__ import annotations

from typing import Optional, Dict, Any
from datetime import datetime, timezone
from app.rules.base import BaseRule, RuleContext
from app.models.events import AIEvent
from app.core.logging import logger

class CashierEmptyRule(BaseRule):
    """
    Evaluates whether a Cashier ROI is empty for a continuous duration.
    Prevents duplicate storm alerts while empty; resets timer when a person enters.
    """
    def __init__(
        self,
        rule_id: str = "rule-cashier-empty-01",
        name: str = "Cashier Area Empty Rule",
        minimum_people: int = 0,
        duration_seconds: float = 180.0,
        cooldown_seconds: float = 300.0,
        enabled: bool = True,
    ):
        super().__init__(rule_id=rule_id, name=name, enabled=enabled)
        self.minimum_people = minimum_people
        self.duration_seconds = duration_seconds
        self.cooldown_seconds = cooldown_seconds

        # State over time
        self.empty_start_time: Optional[float] = None
        self.has_triggered: bool = False
        self.last_triggered_time: Optional[float] = None
        self.current_duration: float = 0.0

    def evaluate(self, ctx: RuleContext) -> Optional[AIEvent]:
        if not self.enabled:
            return None

        current_time = ctx.timestamp
        people_count = ctx.people_in_roi

        # Condition: people_count <= minimum_people (i.e. 0)
        if people_count <= self.minimum_people:
            if self.empty_start_time is None:
                # Empty starts -> timer starts
                self.empty_start_time = current_time
                self.current_duration = 0.0
                logger.info(
                    f"[{self.rule_id}] Cashier area '{ctx.roi.name}' is empty. Timer started at {current_time}."
                )
            else:
                self.current_duration = current_time - self.empty_start_time

            # Check if threshold reached
            if self.current_duration >= self.duration_seconds:
                # Check duplicate prevention
                if not self.has_triggered:
                    self.has_triggered = True
                    self.last_triggered_time = current_time

                    logger.warning(
                        f"[{self.rule_id}] CASHIER_EMPTY triggered! Area '{ctx.roi.name}' has been empty for "
                        f"{round(self.current_duration, 1)}s (threshold: {self.duration_seconds}s)."
                    )

                    event = AIEvent(
                        id=f"evt_{ctx.camera_id}_{int(current_time)}",
                        event_type="CASHIER_EMPTY",
                        camera_id=ctx.camera_id,
                        roi_id=ctx.roi.id,
                        rule_id=self.rule_id,
                        detected_at=datetime.now(timezone.utc).isoformat(),
                        confidence=1.0,
                        people_count=0,
                        duration=round(self.current_duration, 1),
                        metadata={
                            "rule_name": self.name,
                            "roi_name": ctx.roi.name,
                            "threshold_seconds": self.duration_seconds,
                            "empty_since": self.empty_start_time,
                        }
                    )
                    return event
                else:
                    # Already triggered for this continuous empty episode.
                    # Suppress duplicate alerts!
                    return None
        else:
            # Person enters -> timer resets completely!
            if self.empty_start_time is not None:
                logger.info(
                    f"[{self.rule_id}] Person detected in cashier area '{ctx.roi.name}'. "
                    f"Resetting empty timer (was empty for {round(self.current_duration, 1)}s)."
                )
            self.empty_start_time = None
            self.has_triggered = False
            self.current_duration = 0.0

        return None

    def reset(self) -> None:
        self.empty_start_time = None
        self.has_triggered = False
        self.last_triggered_time = None
        self.current_duration = 0.0

    def get_state(self) -> Dict[str, Any]:
        return {
            "rule_id": self.rule_id,
            "name": self.name,
            "enabled": self.enabled,
            "duration_seconds": self.duration_seconds,
            "is_empty": self.empty_start_time is not None,
            "current_duration": round(self.current_duration, 1),
            "has_triggered": self.has_triggered,
            "last_triggered_time": self.last_triggered_time,
        }
