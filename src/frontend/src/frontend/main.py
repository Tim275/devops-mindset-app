from flask import Flask, render_template, request, redirect, url_for, jsonify
import requests
import os
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Environment-based API URL
API_URL = os.getenv("API_URL", "http://localhost:22112")


@app.route("/")
def index():
    """Display study sessions from backend API"""
    try:
        response = requests.get(f"{API_URL}/sessions", timeout=5)
        if response.status_code == 200:
            sessions = response.json()
            # Format sessions for display
            for session in sessions:
                if "timestamp" in session:
                    timestamp_obj = datetime.fromisoformat(
                        session["timestamp"].replace("Z", "+00:00")
                    )
                    session["timestamp_obj"] = timestamp_obj
                    session["formatted_date"] = timestamp_obj.strftime("%Y-%m-%d %H:%M")
                else:
                    session["timestamp_obj"] = datetime.now()
                    session["formatted_date"] = "Unknown"

            # Sort by timestamp (newest first)
            sessions.sort(key=lambda x: x["timestamp_obj"], reverse=True)
        else:
            sessions = []
    except requests.RequestException as e:
        logger.error(f"Error fetching sessions: {e}")
        sessions = []

    return render_template("index.html", sessions=sessions)


@app.route("/add_session", methods=["POST"])
def add_session():
    """Add a new study session via backend API"""
    try:
        # Get form data (handle both 'duration' aannd 'minutes' field names)
        duration = request.form.get("duration") or request.form.get("minutes")
        tag = request.form.get("tag", "").strip()

        # Validate duration
        try:
            minutes = int(duration)
            if minutes <= 0:
                raise ValueError("Minutes must be positive")
        except (ValueError, TypeError):
            logger.error(f"Invalid duration: {duration}")
            return redirect(url_for("index"))

        # Prepare data for backend
        session_data = {"minutes": minutes, "tag": tag if tag else "General Study"}

        # Send to backend
        response = requests.post(
            f"{API_URL}/sessions",
            json=session_data,
            timeout=5,
            headers={"Content-Type": "application/json"},
        )

        if response.status_code == 200:
            logger.info(f"Session created successfully: {session_data}")
        else:
            logger.warning(f"Failed to create session: {response.status_code}")

        return redirect(url_for("index"))

    except Exception as e:
        logger.error(f"Error in add_session: {e}")
        return redirect(url_for("index"))


@app.route("/delete_session/<session_id>", methods=["POST"])
def delete_session(session_id):
    """Delete a study session via backend API"""
    logger.info("=== DELETE SESSION ROUTE TRIGGERED ===")
    logger.info(f"Session ID to delete: {session_id}")
    logger.info(f"Request method: {request.method}")
    logger.info(f"API URL: {API_URL}")

    try:
        # Call backend DELETE endpoint
        delete_url = f"{API_URL}/sessions/{session_id}"
        logger.info(f"Making DELETE request to: {delete_url}")

        response = requests.delete(delete_url, timeout=10)

        logger.info(f"Backend response status: {response.status_code}")
        logger.info(f"Backend response text: {response.text}")

        if response.status_code == 200:
            logger.info(f"Session {session_id} deleted successfully")
        elif response.status_code == 404:
            logger.warning(f"Session {session_id} not found in backend")
        else:
            logger.warning(
                f"Failed to delete session {session_id}: {response.status_code}"
            )

    except requests.RequestException as e:
        logger.error(f"Network error deleting session {session_id}: {e}")
    except Exception as e:
        logger.error(f"Unexpected error deleting session {session_id}: {e}")

    logger.info("=== REDIRECTING TO INDEX ===")
    return redirect(url_for("index"))


@app.route("/health")
def health():
    """Health endpoint with proper status codes"""
    try:
        response = requests.get(f"{API_URL}/health", timeout=5)
        api_connectivity = response.status_code == 200

        if api_connectivity:
            return jsonify({"status": "healthy", "api_connectivity": True}), 200
        else:
            return jsonify({"status": "unhealthy", "api_connectivity": False}), 503

    except requests.RequestException:
        return jsonify({"status": "unhealthy", "api_connectivity": False}), 503


def debug_routes():
    """Debug function to list all registered routes"""
    logger.info("=== REGISTERED FLASK ROUTES ===")
    for rule in app.url_map.iter_rules():
        logger.info(
            f"Route: {rule.rule} | Methods: {rule.methods} | Endpoint: {rule.endpoint}"
        )
    logger.info("=== END ROUTES ===")


def main():
    """Main entry point"""
    logger.info("Starting Flask application...")
    logger.info(f"API URL: {API_URL}")

    # Debug routes
    debug_routes()

    app.run(host="0.0.0.0", port=22111, debug=True)


if __name__ == "__main__":
    main()
