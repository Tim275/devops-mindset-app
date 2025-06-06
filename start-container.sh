#!/bin/bash

# Container bauen
docker build -t dev-container -f .devcontainer/Dockerfile .

# Host Git-Konfiguration auslesen
HOST_GIT_NAME=$(git config --get user.name || echo "Tim275")
HOST_GIT_EMAIL=$(git config --get user.email || echo "sagichdirnicht259@outlook.de")

echo "🚀 Starte Container mit Backend (22112) + Frontend (22111)"
echo "👤 Git: $HOST_GIT_NAME <$HOST_GIT_EMAIL>"

# ✅ Container starten mit Auto-Git-Setup
docker run -it --rm \
  --user vscode \
  -v "$(pwd):/workspaces/devops-projekt" \
  -v ~/.ssh:/home/vscode/.ssh:ro \
  -p 22111:22111 \
  -p 22112:22112 \
  -e DEVPOD_WORKSPACE_ID=devops-projekt \
  -e DEVPOD=true \
  -e GIT_AUTHOR_NAME="$HOST_GIT_NAME" \
  -e GIT_AUTHOR_EMAIL="$HOST_GIT_EMAIL" \
  -e GIT_COMMITTER_NAME="$HOST_GIT_NAME" \
  -e GIT_COMMITTER_EMAIL="$HOST_GIT_EMAIL" \
  dev-container bash -c "
    cd /workspaces/devops-projekt && \
    git config --global --add safe.directory /workspaces/devops-projekt && \
    mise trust && \
    eval \"\$(mise activate bash)\" && \
    echo '✅ Git safe directory configured' && \
    echo '✅ mise trusted and activated' && \
    bash
  "