#!/bin/bash

# Container bauen und starten
docker build -t dev-container -f .devcontainer/Dockerfile .

# Container mit korrekten Berechtigungen starten
docker run -it --rm \
  -v "$(pwd):/workspaces/devops-projekt" \
  -v ~/.ssh:/home/vscode/.ssh:ro \
  -e DEVPOD_WORKSPACE_ID=devops-projekt \
  -e DEVPOD=true \
  -e GIT_AUTHOR_NAME="$(git config user.name)" \
  -e GIT_AUTHOR_EMAIL="$(git config user.email)" \
  -e GIT_COMMITTER_NAME="$(git config user.name)" \
  -e GIT_COMMITTER_EMAIL="$(git config user.email)" \
  dev-container bash