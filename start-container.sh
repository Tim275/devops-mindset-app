#!/bin/bash

# Container bauen
docker build -t dev-container -f .devcontainer/Dockerfile .

# Host Git Config lesen
HOST_GIT_NAME=$(git config --get user.name)
HOST_GIT_EMAIL=$(git config --get user.email)

echo "🚀 Starte Container mit Backend (22112) + Frontend (22111)"
echo "👤 Git: $HOST_GIT_NAME <$HOST_GIT_EMAIL>"

docker run -it --rm \
  --user vscode \
  -v "$(pwd):/workspaces/devops-projekt" \
  -v ~/.ssh:/home/vscode/.ssh:ro \
  -p 22111:22111 \
  -p 22112:22112 \
  -e DEVPOD_WORKSPACE_ID=devops-projekt \
  -e DEVPOD=true \
  dev-container bash -c "
    cd /workspaces/devops-projekt && \
    git config --global --add safe.directory /workspaces/devops-projekt && \
    git config --global user.name '$HOST_GIT_NAME' && \
    git config --global user.email '$HOST_GIT_EMAIL' && \
    mise trust && \
    eval \"\$(mise activate bash)\" && \
    echo '✅ Git configured: $HOST_GIT_NAME <$HOST_GIT_EMAIL>' && \
    bash
  "