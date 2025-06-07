from fastapi import FastAPI
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Study Tracker API")


@app.get("/")
async def root():
    return {"message": "Backend running with UV!", "timestamp": datetime.now()}


@app.get("/health")
async def health():
    return {"status": "healthy", "timestamp": datetime.now()}


def main():
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=22112)


if __name__ == "__main__":
    main()
# Test change
