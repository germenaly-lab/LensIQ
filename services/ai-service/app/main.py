from __future__ import annotations

import time
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.logging import logger
from app.core.device import detect_compute_device
from app.api.routes import router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup lifecycle
    device, device_desc = detect_compute_device()
    logger.info("=" * 60)
    logger.info("Starting LensIQ AI Computer Vision Microservice")
    logger.info(f"Environment: {settings.ENVIRONMENT}")
    logger.info(f"Compute Hardware: {device_desc} ({device})")
    logger.info(f"YOLO Model: {settings.MODEL_NAME}")
    logger.info(f"Mock Mode: {settings.MOCK_DETECTION_MODE}")
    logger.info(f"Target Classes: {settings.TARGET_CLASSES}")
    logger.info(f"Node.js Backend Target: {settings.NODE_BACKEND_URL}")
    logger.info("=" * 60)
    yield
    # Shutdown lifecycle
    logger.info("LensIQ AI Microservice shutting down...")

app = FastAPI(
    title="LensIQ AI Computer Vision Microservice",
    description="Enterprise CCTV Edge/Cloud Vision Engine with YOLOv8 & Stateful Rule Evaluation",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=False)
