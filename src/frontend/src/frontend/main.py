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
    except requests.RequestException:
        sessions = []

    return render_template("index.html", sessions=sessions)


@app.route("/add_session", methods=["POST"])
def add_session():
    """Add a new study session via backend API"""
    try:
        # Get form data (handle both 'duration' and 'minutes' field names)
        duration = request.form.get("duration") or request.form.get("minutes")
        tag = request.form.get("tag", "").strip()

        # Validate duration
        try:
            minutes = int(duration)
            if minutes <= 0:
                raise ValueError("Minutes must be positive")
        except (ValueError, TypeError):
            return redirect(url_for("index"))

        # Prepare data ###for backend
        session_data = {"minutes": minutes, "tag": tag if tag else "General Study"}

        # Send to backend
        requests.post(
            f"{API_URL}/sessions",
            json=session_data,
            timeout=5,
            headers={"Content-Type": "application/json"},
        )

        return redirect(url_for("index"))

    except Exception as e:
        logger.error(f"Error in add_session: {e}")
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


def main():
    app.run(host="0.0.0.0", port=22111, debug=True)


if __name__ == "__main__":
    main()
