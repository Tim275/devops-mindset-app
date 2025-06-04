#!/bin/bash

# Container bauen
docker build -t dev-container -f .devcontainer/Dockerfile .

# Host Git-Konfiguration auslesen
HOST_GIT_NAME=$(git config --get user.name)
HOST_GIT_EMAIL=$(git config --get user.email)

echo "Übertrage Git-Konfiguration: $HOST_GIT_NAME <$HOST_GIT_EMAIL>"

# Container mit Git-Konfiguration und Port-Weiterleitung starten
docker run -it --rm \
  -v "$(pwd):/workspaces/devops-projekt" \
  -v ~/.ssh:/home/vscode/.ssh \
  -p 22112:22112 \
  -e DEVPOD_WORKSPACE_ID=devops-projekt \
  -e DEVPOD=true \
  -e GIT_AUTHOR_NAME="$HOST_GIT_NAME" \
  -e GIT_AUTHOR_EMAIL="$HOST_GIT_EMAIL" \
  -e GIT_COMMITTER_NAME="$HOST_GIT_NAME" \
  -e GIT_COMMITTER_EMAIL="$HOST_GIT_EMAIL" \
  dev-container bash -c "cd /workspaces/devops-projekt && bash"