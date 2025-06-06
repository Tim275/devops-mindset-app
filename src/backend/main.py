import logging
from datetime import datetime, timezone
from typing import List

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="DevOps Study Tracker", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage (like Mischa's simple approach)
sessions_db = []


# Pydantic models (like Mischa)
class SessionCreate(BaseModel):
    minutes: int
    tag: str


class Session(BaseModel):
    id: int
    minutes: int
    tag: str
    date: datetime


@app.get("/")
async def root():
    return {"message": "DevOps Study Tracker API", "status": "running"}


@app.get("/health")
async def health():
    return {"status": "healthy", "service": "backend"}


@app.get("/sessions", response_model=List[Session])
async def get_sessions():
    """Get all study sessions"""
    logger.info(f"Returning {len(sessions_db)} sessions")
    return sessions_db


@app.post("/sessions", response_model=Session)
async def create_session(session: SessionCreate):
    """Create a new study session"""
    new_session = Session(
        id=len(sessions_db) + 1,
        minutes=session.minutes,
        tag=session.tag,
        date=datetime.now(timezone.utc),
    )
    sessions_db.append(new_session)
    logger.info(f"Created session: {session.minutes} minutes, tag: {session.tag}")
    return new_session


@app.delete("/sessions/{session_id}")
async def delete_session(session_id: int):
    """Delete a study session"""
    global sessions_db
    original_length = len(sessions_db)
    sessions_db = [s for s in sessions_db if s.id != session_id]

    if len(sessions_db) == original_length:
        raise HTTPException(status_code=404, detail="Session not found")

    logger.info(f"Deleted session with id: {session_id}")
    return {"message": "Session deleted successfully"}


if __name__ == "__main__":
    logger.info("Starting DevOps Study Tracker Backend")
    uvicorn.run("main:app", host="0.0.0.0", port=22112, reload=True)
