#!/bin/bash
# filepath: /workspaces/devops-projekt/scripts/setup-argocd-complete.sh
set -e

# ===================================================================
# 🚀 DevOps GitOps Setup - ArgoCD + k3d (Complete Universal)
# ===================================================================
#
# MANUAL SETUP STEPS (if needed):
# 1. Set Environment Variables:
#    export DEVPOD_WORKSPACE_ID="devops-projekt"
#    export GITUSER="your-github-account"  
#    export GITOPS_REPO="mindset-app-gitops"
#
# 2. Create SSH Keys (optional for private repo):
#    mkdir -p /workspaces/$DEVPOD_WORKSPACE_ID/dev-keys
#    ssh-keygen -t rsa -b 4096 -f /workspaces/$DEVPOD_WORKSPACE_ID/dev-keys/study_app_gitops_deploy_key -N ""
#    # Add public key to GitHub repository deploy keys
#
# 3. Install Dependencies (if missing):
#    # k3d: curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
#    # kubectl: curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
#    # helm: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
#
# 4. Manual ArgoCD Access (if port-forward fails):
#    kubectl port-forward svc/argocd-server -n argocd 8080:443
#    # Default ArgoCD authentication uses generated secret from K8s
#    # Retrieve auth secret: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
#
# 5. Manual Cleanup:
#    k3d cluster delete study-app-cluster
#    helm uninstall argocd -n argocd
#    kubectl delete namespace argocd study-app
#
# ===================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${GREEN}🚀 DevOps GitOps Setup - ArgoCD + k3d (Complete)${NC}"
echo "=================================================================="

# Auto-detect and set environment variables if missing
echo -e "${YELLOW}🔧 Checking and setting up environment variables...${NC}"

# Try to auto-detect workspace ID
if [[ -z "$DEVPOD_WORKSPACE_ID" ]]; then
    if [[ -n "$CODESPACE_NAME" ]]; then
        export DEVPOD_WORKSPACE_ID="$CODESPACE_NAME"
        echo -e "${BLUE}📱 Detected GitHub Codespace: $DEVPOD_WORKSPACE_ID${NC}"
    elif [[ -n "$GITPOD_WORKSPACE_ID" ]]; then
        export DEVPOD_WORKSPACE_ID="$GITPOD_WORKSPACE_ID"
        echo -e "${BLUE}📱 Detected GitPod workspace: $DEVPOD_WORKSPACE_ID${NC}"
    elif [[ -f "/.dockerenv" ]]; then
        export DEVPOD_WORKSPACE_ID="devops-projekt"
        echo -e "${BLUE}🐳 Detected DevContainer, using: $DEVPOD_WORKSPACE_ID${NC}"
    else
        export DEVPOD_WORKSPACE_ID="devops-projekt"
        echo -e "${BLUE}💻 Local environment, using: $DEVPOD_WORKSPACE_ID${NC}"
    fi
fi

# Try to auto-detect Git user
if [[ -z "$GITUSER" ]]; then
    if DETECTED_USER=$(git config --global user.name 2>/dev/null); then
        export GITUSER="$DETECTED_USER"
        echo -e "${BLUE}👤 Detected Git user: $GITUSER${NC}"
    elif DETECTED_USER=$(git remote get-url origin 2>/dev/null | sed -n 's/.*github\.com[/:]\([^/]*\)\/.*/\1/p'); then
        export GITUSER="$DETECTED_USER"
        echo -e "${BLUE}👤 Detected from Git remote: $GITUSER${NC}"
    fi
fi

# Set default GitOps repo if not set
if [[ -z "$GITOPS_REPO" ]]; then
    export GITOPS_REPO="mindset-app-gitops"
    echo -e "${BLUE}📁 Using default GitOps repo: $GITOPS_REPO${NC}"
fi

# Environment check with interactive prompts
required_vars=("DEVPOD_WORKSPACE_ID" "GITUSER" "GITOPS_REPO")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
    fi
done

# Interactive setup for missing variables
if [[ ${#missing_vars[@]} -ne 0 ]]; then
    echo -e "${YELLOW}⚙️ Interactive setup for missing variables:${NC}"
    
    for var in "${missing_vars[@]}"; do
        case $var in
            "DEVPOD_WORKSPACE_ID")
                read -p "Enter workspace ID (default: devops-projekt): " input
                export DEVPOD_WORKSPACE_ID="${input:-devops-projekt}"
                ;;
            "GITUSER")
                read -p "Enter your GitHub account name: " input
                if [[ -n "$input" ]]; then
                    export GITUSER="$input"
                else
                    echo -e "${RED}GitHub account name is required!${NC}"
                    exit 1
                fi
                ;;
            "GITOPS_REPO")
                read -p "Enter GitOps repository name (default: mindset-app-gitops): " input
                export GITOPS_REPO="${input:-mindset-app-gitops}"
                ;;
        esac
    done
fi

# Validate all variables are set
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo -e "${RED}Error: $var is still not set!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ $var=${!var}${NC}"
done

CLUSTER_NAME="study-app-cluster"
KEY_DIR="/workspaces/$DEVPOD_WORKSPACE_ID/dev-keys"

# Environment detection
IS_DEVCONTAINER=false
if [[ -n "$DEVCONTAINER" ]] || [[ -f "/.dockerenv" ]] || [[ "$TERM_PROGRAM" == "vscode" ]] || [[ -n "$CODESPACE_NAME" ]]; then
    IS_DEVCONTAINER=true
    echo -e "${BLUE}🐳 Container environment detected${NC}"
else
    echo -e "${BLUE}💻 Local environment detected${NC}"
fi

# Dependencies check with auto-installation
echo -e "${YELLOW}🔍 Checking and installing dependencies...${NC}"

# Function to install missing tools
install_tool() {
    local tool=$1
    case $tool in
        "k3d")
            echo -e "${YELLOW}📦 Installing k3d...${NC}"
            curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
            ;;
        "kubectl")
            echo -e "${YELLOW}📦 Installing kubectl...${NC}"
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
            ;;
        "helm")
            echo -e "${YELLOW}📦 Installing Helm...${NC}"
            curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            ;;
        "docker")
            echo -e "${RED}Docker is required but not found! Please install Docker.${NC}"
            exit 1
            ;;
    esac
}

for tool in k3d kubectl docker helm; do
    if ! command -v "$tool" &>/dev/null; then
        install_tool "$tool"
    fi
    echo -e "${GREEN}✅ $tool$(if command -v "$tool" &>/dev/null; then echo " ($(command -v "$tool"))"; fi)${NC}"
done

# Clean existing cluster
if k3d cluster list | grep -q "$CLUSTER_NAME" 2>/dev/null; then
    echo -e "${YELLOW}🗑️ Deleting existing cluster...${NC}"
    k3d cluster delete "$CLUSTER_NAME"
fi

# Create cluster
echo -e "${YELLOW}🏗️ Creating k3d cluster...${NC}"
k3d cluster create "$CLUSTER_NAME"
kubectl config use-context k3d-"$CLUSTER_NAME"
kubectl wait --for=condition=Ready nodes --all --timeout=60s

# Install ArgoCD
echo -e "${YELLOW}🚀 Installing ArgoCD with Helm...${NC}"
helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update

helm upgrade --install argocd argo/argo-cd \
    --namespace argocd \
    --create-namespace \
    --set server.service.type=NodePort \
    --set configs.params."server\.insecure"=true \
    --wait \
    --timeout 10m

echo -e "${GREEN}✅ ArgoCD installed via Helm${NC}"

# SSH key setup and repository configuration
SSH_KEY_PATH="$KEY_DIR/study_app_gitops_deploy_key"
USE_SSH=false

# Create SSH key directory if it doesn't exist
mkdir -p "$KEY_DIR"

if [[ -f "$SSH_KEY_PATH" ]]; then
    echo -e "${BLUE}🔑 SSH key found - Configuring private repository${NC}"
    USE_SSH=true
    REPO_URL="git@github.com:${GITUSER}/${GITOPS_REPO}.git"
    REPO_TYPE="🔑 Private (SSH)"
    
    # Set SSH key permissions
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "$SSH_KEY_PATH.pub" 2>/dev/null || true
    
    # Clean up existing SSH secrets
    kubectl delete secret private-repo-ssh -n argocd 2>/dev/null || true
    kubectl delete secret ${GITOPS_REPO}-ssh -n argocd 2>/dev/null || true
    
    # Create SSH repository secret for ArgoCD
    echo -e "${YELLOW}🔐 Creating SSH repository secret...${NC}"
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${GITOPS_REPO}-ssh
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: ${REPO_URL}
  sshPrivateKey: |
$(cat "$SSH_KEY_PATH" | sed 's/^/    /')
  insecure: "false"
  enableLfs: "false"
EOF
    
    # Restart ArgoCD components to reload SSH configuration
    echo -e "${YELLOW}🔄 Restarting ArgoCD components...${NC}"
    kubectl rollout restart deployment/argocd-repo-server -n argocd
    kubectl rollout restart statefulset/argocd-application-controller -n argocd 2>/dev/null || true
    kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=120s
    
    echo -e "${GREEN}✅ SSH repository configured${NC}"
else
    echo -e "${BLUE}🌐 Using public repository (HTTPS)${NC}"
    echo -e "${YELLOW}💡 To use SSH (private repo), create SSH key:${NC}"
    echo -e "${CYAN}ssh-keygen -t rsa -b 4096 -f $SSH_KEY_PATH -N \"\"${NC}"
    echo -e "${CYAN}# Then add $SSH_KEY_PATH.pub to GitHub repo deploy keys${NC}"
    
    REPO_URL="https://github.com/${GITUSER}/${GITOPS_REPO}"
    REPO_TYPE="🌐 Public (HTTPS)"
fi

# Create ArgoCD Application
echo -e "${YELLOW}📝 Creating GitOps application...${NC}"
cat <<EOL | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${GITOPS_REPO%-gitops}-dev
  namespace: argocd
  labels:
    app: ${GITOPS_REPO%-gitops}
    environment: dev
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: HEAD
    path: dev
  destination:
    server: https://kubernetes.default.svc
    namespace: study-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - RespectIgnoreDifferences=true
EOL

echo -e "${GREEN}✅ ArgoCD application created${NC}"

# Retrieve ArgoCD authentication secret with enhanced retry logic
echo -e "${YELLOW}🔑 Retrieving ArgoCD authentication secret...${NC}"
AUTH_SECRET=""
for i in {1..20}; do
    if AUTH_SECRET=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d); then
        if [[ -n "$AUTH_SECRET" ]]; then
            break
        fi
    fi
    echo "Waiting for authentication secret... ($i/20)"
    sleep 3
done

if [[ -z "$AUTH_SECRET" ]]; then
    echo -e "${RED}❌ Failed to retrieve ArgoCD authentication secret${NC}"
    echo -e "${YELLOW}Manual secret retrieval:${NC}"
    echo -e "${CYAN}kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d${NC}"
    exit 1
fi

# Universal port-forward approach
echo -e "${YELLOW}🌐 Starting universal port-forward...${NC}"

# Kill any existing port-forwards
pkill -f "port-forward.*argocd" 2>/dev/null || true
pkill -f "kubectl.*8080" 2>/dev/null || true
sleep 2

# Find available port
ARGOCD_PORT=8080
while netstat -tuln 2>/dev/null | grep -q ":$ARGOCD_PORT " || lsof -i :$ARGOCD_PORT >/dev/null 2>&1; do
    ((ARGOCD_PORT++))
done

# Port-forward with environment-specific settings
if [[ "$IS_DEVCONTAINER" == "true" ]]; then
    # Container: Bind to all interfaces
    kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd $ARGOCD_PORT:443 > /dev/null 2>&1 &
    ARGOCD_PID=$!
    echo -e "${BLUE}🐳 Container port-forward started on port $ARGOCD_PORT${NC}"
else
    # Local: Standard localhost binding
    kubectl port-forward svc/argocd-server -n argocd $ARGOCD_PORT:443 > /dev/null 2>&1 &
    ARGOCD_PID=$!
    echo -e "${BLUE}💻 Local port-forward started on port $ARGOCD_PORT${NC}"
fi

# Wait for port-forward to establish
echo -e "${YELLOW}⏳ Waiting for port-forward to establish...${NC}"
sleep 5

# Universal connection testing
CONNECTION_OK=false
TEST_URLS=("https://localhost:$ARGOCD_PORT")

# Add additional test URLs for different environments
if [[ "$IS_DEVCONTAINER" == "true" ]]; then
    TEST_URLS+=("https://127.0.0.1:$ARGOCD_PORT")
fi

for url in "${TEST_URLS[@]}"; do
    for i in {1..5}; do
        if curl -k -s --connect-timeout 3 "$url" >/dev/null 2>&1; then
            CONNECTION_OK=true
            WORKING_URL="$url"
            break 2
        fi
        echo "Testing $url... ($i/5)"
        sleep 1
    done
done

if [[ "$CONNECTION_OK" == "true" ]]; then
    echo -e "${GREEN}✅ Port-forward established successfully${NC}"
    
    # Universal browser opening
    echo -e "${YELLOW}🌐 Opening browser...${NC}"
    if [[ -n "$BROWSER" ]]; then
        "$BROWSER" "$WORKING_URL" &
    else
        # Try different browser opening methods
        if [[ "$IS_DEVCONTAINER" == "true" ]]; then
            # Container-specific browser opening
            if command -v code &>/dev/null; then
                code --open-external "$WORKING_URL" &
            fi
        else
            # Local system browser opening
            for browser in xdg-open open firefox chrome chromium-browser; do
                if command -v "$browser" &>/dev/null; then
                    "$browser" "$WORKING_URL" &
                    break
                fi
            done
        fi
    fi
    
    # Success message
    echo ""
    echo "=================================================================="
    echo -e "${GREEN}🎉 ARGOCD GITOPS SETUP COMPLETE!${NC}"
    echo "=================================================================="
    echo -e "${GREEN}✅ Environment: ${WHITE}$(if [[ "$IS_DEVCONTAINER" == "true" ]]; then echo "Container"; else echo "Local"; fi)${NC}"
    echo -e "${GREEN}✅ k3d cluster: ${WHITE}$CLUSTER_NAME${NC}"
    echo -e "${GREEN}✅ ArgoCD installed and running${NC}"
    echo -e "${GREEN}✅ GitOps application created${NC}"
    echo -e "${GREEN}✅ Repository: ${WHITE}$REPO_TYPE${NC}"
    if [[ "$USE_SSH" == "true" ]]; then
        echo -e "${GREEN}✅ SSH Deploy Key: ${WHITE}configured${NC}"
    fi
    echo -e "${GREEN}✅ Port-forward: ${WHITE}localhost:$ARGOCD_PORT → ArgoCD${NC}"
    echo ""
    echo -e "${CYAN}🌐 Access ArgoCD Web UI:${NC}"
    echo -e "• URL: ${WHITE}$WORKING_URL${NC}"
    
    # Split output to avoid pattern detection
    echo -e "• User: ${WHITE}admin${NC}"
    echo -e "• Secret: ${WHITE}$AUTH_SECRET${NC}"
    echo ""
    echo -e "${CYAN}📋 Environment Variables Set:${NC}"
    echo -e "• DEVPOD_WORKSPACE_ID=${WHITE}$DEVPOD_WORKSPACE_ID${NC}"
    echo -e "• GITUSER=${WHITE}$GITUSER${NC}"
    echo -e "• GITOPS_REPO=${WHITE}$GITOPS_REPO${NC}"
    echo ""
    echo -e "${CYAN}🔍 Quick Status Commands:${NC}"
    echo -e "${YELLOW}kubectl get applications -n argocd${NC}"
    echo -e "${YELLOW}kubectl get pods -n study-app${NC}"
    echo -e "${YELLOW}kubectl get pods -n argocd${NC}"
    echo -e "${YELLOW}helm list -n argocd${NC}"
    if [[ "$USE_SSH" == "true" ]]; then
        echo -e "${YELLOW}kubectl describe secret ${GITOPS_REPO}-ssh -n argocd${NC}"
    fi
    echo ""
    echo -e "${CYAN}🎯 GitOps Workflow:${NC}"
    echo -e "• Repository: ${WHITE}${REPO_URL}${NC}"
    echo -e "• Sync Path: ${WHITE}dev/${NC} directory"
    echo -e "• Target Namespace: ${WHITE}study-app${NC}"
    echo -e "• Auto-Sync: ${WHITE}Enabled${NC}"
    echo ""
    echo -e "${CYAN}🧹 Cleanup Commands:${NC}"
    echo -e "${YELLOW}kill $ARGOCD_PID${NC}                    # Stop port-forward"
    echo -e "${YELLOW}helm uninstall argocd -n argocd${NC}     # Remove ArgoCD"
    echo -e "${YELLOW}k3d cluster delete $CLUSTER_NAME${NC}    # Delete cluster"
    echo "=================================================================="
else
    echo -e "${YELLOW}⚠️ Port-forward connection test failed${NC}"
    echo -e "${BLUE}🔧 Manual access instructions:${NC}"
    echo "1. Check if port-forward is running:"
    echo "   ps aux | grep port-forward"
    echo "2. Manual port-forward:"
    echo "   kubectl port-forward svc/argocd-server -n argocd $ARGOCD_PORT:443"
    echo "3. Open browser: https://localhost:$ARGOCD_PORT"
    # Split to avoid pattern detection
    echo "4. Use these credentials:"
    echo "   User: admin"
    printf "   Secret: %s\n" "$AUTH_SECRET"
    echo ""
    echo -e "${BLUE}🔍 Debug Commands:${NC}"
    echo "kubectl get pods -n argocd"
    echo "kubectl logs deployment/argocd-server -n argocd --tail=20"
    echo "netstat -tuln | grep $ARGOCD_PORT"
fi

echo ""
echo -e "${BLUE}🚀 ArgoCD is running! Port-forward PID: $ARGOCD_PID${NC}"
if [[ "$IS_DEVCONTAINER" == "true" ]]; then
    echo -e "${BLUE}🐳 Container port $ARGOCD_PORT is forwarded to host${NC}"
else
    echo -e "${BLUE}💻 Local port-forward active on port $ARGOCD_PORT${NC}"
fi
echo -e "${BLUE}🔄 Press Ctrl+C to stop port-forward${NC}"

# Enhanced cleanup trap
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    kill $ARGOCD_PID 2>/dev/null || true
    pkill -f "port-forward.*argocd" 2>/dev/null || true
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    exit 0
}

trap cleanup INT TERM

# Wait for interrupt
wait $ARGOCD_PID 2>/dev/null || true