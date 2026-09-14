from __future__ import annotations

from typing import Optional, Dict, Any
import httpx
from app.models.events import AIEvent
from app.core.config import settings
from app.core.logging import logger

class BackendClientService:
    """
    HTTP Client service to forward structured AI events to the Node.js backend
    using an internal authenticated API endpoint.
    """
    def __init__(
        self,
        base_url: Optional[str] = None,
        api_secret: Optional[str] = None,
        enabled: Optional[bool] = None
    ):
        self.base_url = (base_url or settings.NODE_BACKEND_URL).rstrip("/")
        self.api_secret = api_secret or settings.INTERNAL_API_SECRET
        self.enabled = enabled if enabled is not None else settings.EVENT_FORWARDING_ENABLED

    async def forward_event(self, event: AIEvent) -> bool:
        if not self.enabled:
            logger.debug(f"Event forwarding disabled; skipped event {event.id} ({event.event_type})")
            return True

        target_url = f"{self.base_url}/api/v1/internal/events"
        headers = {
            "Content-Type": "application/json",
            "X-Internal-Service-Key": self.api_secret,
        }

        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.post(
                    target_url,
                    headers=headers,
                    json=event.model_dump()
                )
                if response.status_code in (200, 201, 202):
                    logger.info(
                        f"Successfully forwarded event {event.id} ({event.event_type}) to Node.js backend"
                    )
                    return True
                else:
                    logger.warning(
                        f"Failed to forward event to Node.js backend: HTTP {response.status_code} - {response.text}"
                    )
                    return False
        except Exception as e:
            logger.error(f"Error connecting to Node.js backend at {target_url}: {e}")
            return False
