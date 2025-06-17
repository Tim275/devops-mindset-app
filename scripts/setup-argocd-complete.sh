#!/bin/bash
# filepath: /workspaces/devops-projekt/scripts/setup-argocd-gitops.sh
set -e

# =============================================================================
# MANUAL ARGOCD INSTALLATION COMMANDS (Alternative to this script)
# =============================================================================
# If you want to install ArgoCD manually step by step, use these commands:
#
# 1. Setup Environment:
# export DEVPOD_WORKSPACE_ID="devops-projekt"
# export GITUSER="Tim275"
# export GITOPS_REPO="mindset-app-gitops"
#
# 2. Create k3d cluster:
# k3d cluster create study-app-cluster
#
# 3. Install ArgoCD:
# kubectl create namespace argocd
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
#
# 4. Get initial password:
# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
#
# 5. Port forward:
# kubectl port-forward svc/argocd-server -n argocd 8080:443
#
# 6. Create application:
# kubectl apply -f - <<EOF
# apiVersion: argoproj.io/v1alpha1
# kind: Application
# metadata:
#   name: mindset-app-dev
#   namespace: argocd
# spec:
#   project: default
#   source:
#     repoURL: ssh://git@github.com/$GITUSER/$GITOPS_REPO
#     targetRevision: HEAD
#     path: dev
#   destination:
#     server: https://kubernetes.default.svc
#     namespace: study-app
#   syncPolicy:
#     automated:
#       prune: true
#       selfHeal: true
# EOF
# =============================================================================

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
CLUSTER_NAME="study-app-cluster"

# Check if key exists (Mischa style)
if [ ! -f "$KEY_DIR/study_app_gitops_deploy_key" ]; then
  echo -e "${RED}Error: Deploy key not found at $KEY_DIR/study_app_gitops_deploy_key${NC}"
  exit 1
fi

echo -e "${GREEN}🚀 Setting up ArgoCD GitOps (Mischa-Style)...${NC}"

# Create k3d cluster if not exists
if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
  echo -e "${YELLOW}Creating k3d cluster...${NC}"
  k3d cluster create "$CLUSTER_NAME"
  echo -e "${GREEN}✅ k3d cluster created${NC}"
else
  echo -e "${BLUE}k3d cluster already exists${NC}"
  kubectl config use-context k3d-"$CLUSTER_NAME"
fi

# Install ArgoCD (Mischa style - minimalistisch)
echo -e "${YELLOW}Installing ArgoCD...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready (Mischa style)
echo -e "${YELLOW}Waiting for ArgoCD to be ready...${NC}"
kubectl -n argocd wait --for=condition=Available deployment/argocd-server --timeout=300s

# Create SSH repository secret
echo -e "${YELLOW}Creating SSH repository secret...${NC}"
kubectl create secret generic gitops-repo-secret \
  --from-file=sshPrivateKey="$KEY_DIR/study_app_gitops_deploy_key" \
  --namespace=argocd \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl label secret gitops-repo-secret argocd.argoproj.io/secret-type=repository -n argocd

# Create ArgoCD application (Mischa style)
echo -e "${YELLOW}Creating ArgoCD application...${NC}"
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${GITOPS_REPO%-gitops}-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ssh://git@github.com/$GITUSER/$GITOPS_REPO
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
EOF

echo -e "${GREEN}✅ ArgoCD GitOps setup completed!${NC}"

# Get initial password
echo -e "${YELLOW}Getting ArgoCD initial password...${NC}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Start port-forward in background
echo -e "${YELLOW}Starting port-forward...${NC}"
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!

# Wait a moment for port-forward to establish
sleep 3

# Open browser
echo -e "${BLUE}Opening ArgoCD in browser...${NC}"
"$BROWSER" https://localhost:8080 &

# Status check
echo -e "${GREEN}🔍 ArgoCD Status:${NC}"
kubectl get applications -n argocd
echo -e "${YELLOW}kubectl get pods -n argocd${NC}"
kubectl get pods -n argocd

echo ""
echo -e "${GREEN}🎉 GitOps ready! ArgoCD is monitoring your repository.${NC}"
echo -e "${BLUE}ArgoCD Web UI: https://localhost:8080${NC}"
echo -e "${BLUE}Username: admin${NC}"
echo -e "${BLUE}Password: $ARGOCD_PASSWORD${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop port-forward${NC}"

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Stopping port-forward...${NC}"
    kill $PORT_FORWARD_PID 2>/dev/null || true
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    exit 0
}

trap cleanup INT TERM

# Wait for interrupt
wait $PORT_FORWARD_PID 2>/dev/null || true