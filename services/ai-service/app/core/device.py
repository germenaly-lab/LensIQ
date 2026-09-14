from __future__ import annotations

from typing import Tuple
from app.core.config import settings
from app.core.logging import logger

def detect_compute_device() -> Tuple[str, str]:
    """
    Detects the best available computing device (CUDA GPU, Apple Silicon MPS, or CPU).
    Returns a tuple of (device_string, device_description).
    """
    if settings.AI_DEVICE != "auto":
        requested = settings.AI_DEVICE.lower()
        return requested, f"User forced: {requested.upper()}"

    try:
        import torch

        if torch.cuda.is_available():
            device_name = torch.cuda.get_device_name(0)
            logger.info(f"NVIDIA CUDA GPU detected: {device_name} (cuda:0)")
            return "cuda:0", f"CUDA GPU: {device_name}"

        if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            logger.info("Apple Silicon Metal Performance Shaders (MPS) detected")
            return "mps", "Apple Silicon GPU (MPS)"

        logger.info("Using standard CPU inference mode")
        return "cpu", "CPU"

    except ImportError:
        logger.warning("PyTorch not installed or unavailable; falling back to CPU mode")
        return "cpu", "CPU (PyTorch not loaded)"
    except Exception as e:
        logger.warning(f"Error checking GPU availability: {e}; falling back to CPU")
        return "cpu", "CPU"
