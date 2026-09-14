from __future__ import annotations

import os
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

    # Server Networking
    HOST: str = Field(default="0.0.0.0", description="Bind host")
    PORT: int = Field(default=8000, description="Bind port")
    ENVIRONMENT: str = Field(default="development", description="development | staging | production")
    LOG_LEVEL: str = Field(default="INFO", description="DEBUG | INFO | WARNING | ERROR")

    # Hardware & Model
    AI_DEVICE: str = Field(default="auto", description="auto | cpu | cuda | mps")
    MODEL_NAME: str = Field(default="yolov8n.pt", description="YOLOv8 weights file or name")
    CONFIDENCE_THRESHOLD: float = Field(default=0.45, ge=0.0, le=1.0)
    IOU_THRESHOLD: float = Field(default=0.45, ge=0.0, le=1.0)
    MOCK_DETECTION_MODE: bool = Field(default=False, description="Use mock detector for testing/offline")

    # Processing limits
    MAX_PROCESSING_FPS: int = Field(default=10, ge=1, le=60)
    INPUT_RESOLUTION_WIDTH: int = Field(default=640, ge=160)
    INPUT_RESOLUTION_HEIGHT: int = Field(default=640, ge=160)

    # Extensible Target Classes (COCO label mapping)
    TARGET_CLASSES: List[str] = Field(
        default=["person", "bag", "car", "chair", "cell phone"],
        description="Supported object detection classes"
    )

    # Integration with Node.js backend
    NODE_BACKEND_URL: str = Field(default="http://localhost:3000")
    INTERNAL_API_SECRET: str = Field(default="lensiq-internal-service-secret-change-in-prod")
    EVENT_FORWARDING_ENABLED: bool = Field(default=True)

settings = Settings()
