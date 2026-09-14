from __future__ import annotations

import logging
import re
import sys
from typing import Any, Dict
from app.core.config import settings

# Regex to mask passwords in URLs (e.g. rtsp://user:pass@host)
PASSWORD_MASK_REGEX = re.compile(r"(:\/\/[^:]+:)([^@]+)(@)")

class SafeFormatter(logging.Formatter):
    """Custom log formatter that strips credentials and sensitive secrets."""
    def format(self, record: logging.LogRecord) -> str:
        original = super().format(record)
        return PASSWORD_MASK_REGEX.sub(r"\1****\3", original)

def setup_logger(name: str = "lensiq.ai") -> logging.Logger:
    logger = logging.getLogger(name)
    logger.setLevel(getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO))
    
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO))
        formatter = SafeFormatter(
            fmt="%(asctime)s [%(levelname)s] [%(name)s] %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.propagate = False
        
    return logger

logger = setup_logger()
