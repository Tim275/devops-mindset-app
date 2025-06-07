"""
DevOps Study Tracker API

A FastAPI application for tracking study time for DevOps certifications.
"""

# Expose main app for ASGI servers
from .main import app
from .models import Stats, StudySession, StudySessionCreate
from .storage import get_all_sessions, get_sessions_by_tag, get_statistics, save_session

# Define public API
__all__ = [
    "StudySession",
    "StudySessionCreate",
    "Stats",
    "save_session",
    "get_all_sessions",
    "get_sessions_by_tag",
    "get_statistics",
    "app",
]
