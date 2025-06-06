import logging

import requests
from flask import Flask, jsonify, redirect, render_template, request, url_for

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
BACKEND_URL = "http://localhost:22112"


@app.route("/")
def index():
    """Main page showing all study sessions"""
    try:
        # Fetch sessions from backend
        response = requests.get(f"{BACKEND_URL}/sessions")
        sessions = response.json() if response.status_code == 200 else []
        logger.info(f"Fetched {len(sessions)} sessions from backend")
    except requests.exceptions.ConnectionError:
        logger.error("Could not connect to backend")
        sessions = []
    except Exception as e:
        logger.error(f"Error fetching sessions: {e}")
        sessions = []

    return render_template("index.html", sessions=sessions)


@app.route("/health")
def health():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "frontend"})


@app.route("/add_session", methods=["POST"])
def add_session():
    """Add a new study session"""
    try:
        minutes = int(request.form.get("minutes", 0))
        tag = request.form.get("tag", "").strip()

        if minutes <= 0:
            logger.warning("Invalid minutes value received")
            return redirect(url_for("index"))

        # Send to backend
        session_data = {"minutes": minutes, "tag": tag}

        response = requests.post(f"{BACKEND_URL}/sessions", json=session_data)

        if response.status_code == 200:
            logger.info(f"Successfully added session: {minutes} mins, tag='{tag}'")
        else:
            logger.error(f"Failed to add session: {response.status_code}")

    except requests.exceptions.ConnectionError:
        logger.error("Error creating session: Could not connect to backend")
        logger.error(f"Failed to add session: {minutes} mins, tag='{tag}'")
    except Exception as e:
        logger.error(f"Error creating session: {e}")
        logger.error(f"Failed to add session: {minutes} mins, tag='{tag}'")

    return redirect(url_for("index"))


@app.route("/delete_session/<int:session_id>", methods=["POST"])
def delete_session(session_id):
    """Delete a study session"""
    try:
        response = requests.delete(f"{BACKEND_URL}/sessions/{session_id}")

        if response.status_code == 200:
            logger.info(f"Successfully deleted session {session_id}")
        else:
            logger.error(
                f"Failed to delete session {session_id}: {response.status_code}"
            )

    except Exception as e:
        logger.error(f"Error deleting session {session_id}: {e}")

    return redirect(url_for("index"))


if __name__ == "__main__":
    logger.info("Starting DevOps Study Timer Frontend")
    app.run(host="0.0.0.0", port=22111, debug=True)
