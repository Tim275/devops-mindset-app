#!/bin/bash
# filepath: /workspaces/devops-projekt/scripts/setup-commitizen.sh
set -e

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Setting up Commitizen & Git Configuration...${NC}"

# Git config für DevPod/DevContainer environments
if [ "$DEVPOD" = "true" ] || [ "$DEVCONTAINER" = "true" ]; then
  echo -e "${YELLOW}📝 Configuring Git for dev environment...${NC}"
  git config --global push.autoSetupRemote true
  git config --global --add safe.directory /workspaces/devops-projekt/
  echo -e "${GREEN}✅ Git configuration updated${NC}"
fi

# Install commitizen if not present
if ! command -v cz >/dev/null; then
  echo -e "${YELLOW}📦 Installing Commitizen...${NC}"
  
  # Use pip instead of pipx for DevContainer compatibility
  pip install --user commitizen
  
  # Add user bin to PATH if not already there
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"
  fi
  
  echo -e "${GREEN}✅ Commitizen installed${NC}"
else
  echo -e "${GREEN}✅ Commitizen already installed${NC}"
fi

# Setup pre-commit hooks
if [ -f ".pre-commit-config.yaml" ]; then
  echo -e "${YELLOW}🔧 Installing pre-commit hooks...${NC}"
  pre-commit install
  pre-commit install --hook-type commit-msg
  echo -e "${GREEN}✅ Pre-commit hooks installed${NC}"
else
  echo -e "${YELLOW}⚠️  No .pre-commit-config.yaml found, skipping pre-commit setup${NC}"
fi

echo -e "${GREEN}🎉 Commitizen setup completed!${NC}"
echo -e "${YELLOW}💡 Usage:${NC}"
echo -e "  ${GREEN}cz commit${NC}    # Interactive commit with conventional commits"
echo -e "  ${GREEN}cz changelog${NC} # Generate changelog"
echo -e "  ${GREEN}cz bump${NC}      # Bump version"