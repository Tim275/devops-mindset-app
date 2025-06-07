from flask import Flask, render_template_string
import requests
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Environment-basierte API URL
API_URL = os.getenv("API_URL", "http://localhost:22112")


@app.route("/")
def index():
    try:
        # Backend connectivity test
        response = requests.get(f"{API_URL}/", timeout=5)
        backend_data = response.json()

        html = """
        <h1>🌐 Frontend running with UV!</h1>
        <p><strong>Backend Connection:</strong> ✅ Connected</p>
        <p><strong>Backend Message:</strong> {{ backend_message }}</p>
        <p><strong>API URL:</strong> {{ api_url }}</p>
        <hr>
        <h2>Study Tracker</h2>
        <p>Ready for your DevOps journey!</p>
        """
        return render_template_string(
            html,
            backend_message=backend_data.get("message", "No message"),
            api_url=API_URL,
        )
    except requests.RequestException as e:
        html = """
        <h1>🌐 Frontend running with UV!</h1>
        <p><strong>Backend Connection:</strong> ❌ Failed</p>
        <p><strong>Error:</strong> {{ error }}</p>
        <p><strong>API URL:</strong> {{ api_url }}</p>
        """
        return render_template_string(html, error=str(e), api_url=API_URL)


@app.route("/health")
def health():
    try:
        response = requests.get(f"{API_URL}/health", timeout=5)
        api_connectivity = response.status_code == 200
        return {
            "status": "healthy" if api_connectivity else "unhealthy",
            "api_connectivity": api_connectivity,
        }
    except requests.RequestException:
        return {"status": "unhealthy", "api_connectivity": False}


def main():
    app.run(host="0.0.0.0", port=22111, debug=True)


if __name__ == "__main__":
    main()
