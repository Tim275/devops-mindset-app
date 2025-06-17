#!/bin/bash
# filepath: /workspaces/devops-projekt/scripts/setup-flux-gitops.sh
set -e

# =============================================================================
# MANUAL FLUX INSTALLATION COMMANDS (Alternative to this script)
# =============================================================================
# If you want to install Flux manually step by step, use these commands:
#
# 1. Setup Environment:
# export DEVPOD_WORKSPACE_ID="devops-projekt"
# export GITUSER="Tim275"
# export GITOPS_REPO="mindset-app-gitops"
#
# 2. Install Flux CLI:
# curl -s https://fluxcd.io/install.sh | sudo bash
#
# 3. Bootstrap Flux:
# flux bootstrap git \
#   --url=ssh://git@github.com/$GITUSER/$GITOPS_REPO \
#   --branch=main \
#   --private-key-file="/workspaces/$DEVPOD_WORKSPACE_ID/dev-keys/study_app_gitops_deploy_key" \
#   --path=clusters/dev
#
# 4. Check status:
# flux get all
# kubectl get pods -n flux-system
# =============================================================================

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for required environment variables (Mischa style)
required_vars=("DEVPOD_WORKSPACE_ID" "GITUSER" "GITOPS_REPO")
missing_vars=()

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    missing_vars+=("$var")
  fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
  echo -e "${RED}Error: The following required environment variables are not set:${NC}"
  for var in "${missing_vars[@]}"; do
    echo "  - $var"
  done
  echo "Please set these variables before running this script."
  exit 1
fi

KEY_DIR="/workspaces/$DEVPOD_WORKSPACE_ID/dev-keys"

# Check if key exists (Mischa style)
if [ ! -f "$KEY_DIR/study_app_gitops_deploy_key" ]; then
  echo -e "${RED}Error: Deploy key not found at $KEY_DIR/study_app_gitops_deploy_key${NC}"
  exit 1
fi

echo -e "${GREEN}🚀 Setting up Flux GitOps (Mischa-Style)...${NC}"

# Install Flux CLI if not present (deine Verbesserung)
if ! command -v flux &>/dev/null; then
  echo -e "${YELLOW}Installing Flux CLI...${NC}"
  curl -s https://fluxcd.io/install.sh | sudo bash
  echo -e "${GREEN}✅ Flux CLI installed${NC}"
fi

# Bootstrap Flux (Mischa style - minimalistisch)
echo -e "${YELLOW}Bootstrapping Flux...${NC}"
flux bootstrap git \
  --url=ssh://git@github.com/"$GITUSER"/"$GITOPS_REPO" \
  --branch=main \
  --private-key-file="$KEY_DIR"/study_app_gitops_deploy_key \
  --path=clusters/dev

echo -e "${GREEN}✅ Flux GitOps setup completed!${NC}"

# Wait for Flux to be ready (Mischa style)
echo -e "${YELLOW}Waiting for Flux controllers to be ready...${NC}"
kubectl -n flux-system wait --for=condition=Ready pods --all --timeout=120s

# Status check (deine Verbesserung)
echo -e "${GREEN}🔍 Flux Status:${NC}"
flux get all
echo -e "${YELLOW}kubectl get pods -n flux-system${NC}"
kubectl get pods -n flux-system

echo -e "${GREEN}🎉 GitOps ready! Flux is monitoring your repository.${NC}"