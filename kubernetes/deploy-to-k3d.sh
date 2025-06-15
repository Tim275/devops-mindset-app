#!/bin/bash
set -e

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Script directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
CLUSTER_NAME="study-app-cluster"

echo -e "${GREEN}DevOps Study App - Kubernetes Deployment Helper${NC}"
echo -e "${YELLOW}This script will set up a k3d cluster and deploy the study app.${NC}"
echo ""

# Dependency checker function
check_dependency() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}Error: $1 is not installed. Please install it before proceeding.${NC}"
    exit 1
  fi
}

echo "🔍 Checking dependencies..."
check_dependency k3d
check_dependency kubectl  
check_dependency docker
echo -e "${GREEN}✅ All dependencies are installed.${NC}"
echo ""

# Cluster existence check
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
  echo -e "${YELLOW}⚠️  Cluster $CLUSTER_NAME already exists.${NC}"
  read -p "Do you want to delete and recreate it? (y/n): " -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Deleting existing cluster..."
    k3d cluster delete "$CLUSTER_NAME"
  else
    echo "📋 Using existing cluster."
  fi
fi

# Cluster creation
if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
  echo "🏗️  Creating k3d cluster using config file..."
  k3d cluster create --config "$SCRIPT_DIR/k3d-config.yaml"
  echo -e "${GREEN}✅ Cluster created successfully!${NC}"
fi

# Configure kubectl context
echo "⚙️  Configuring kubectl to use the cluster..."
kubectl config use-context k3d-"$CLUSTER_NAME"

# Build Docker images
echo "🐳 Building Docker images..."
echo "Building backend image..."
docker build -t backend:dev -f "$BASE_DIR/src/backend/Dockerfile" "$BASE_DIR/src/backend"

echo "Building frontend image..."
docker build -t frontend:dev -f "$BASE_DIR/src/frontend/Dockerfile" "$BASE_DIR/src/frontend"

# Import images into k3d
echo "📦 Importing images into k3d..."
k3d image import backend:dev -c "$CLUSTER_NAME"
k3d image import frontend:dev -c "$CLUSTER_NAME"

# Deploy with kustomize
echo "🚀 Deploying application using kustomize..."
kubectl apply -k "$SCRIPT_DIR/manifests/dev"

# Wait for pods
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n study-app --timeout=120s

# Success message
echo -e "${GREEN}🎉 Application deployed successfully!${NC}"
echo ""
echo "📋 Getting service information..."
kubectl get services -n study-app

# Port-forward instructions  
FRONTEND_PORT=$(kubectl get svc frontend -n study-app -o=jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "22111")
BACKEND_PORT=$(kubectl get svc backend -n study-app -o=jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "22112")

echo -e "\n${GREEN}🌐 Access your application:${NC}"
echo -e "Run these commands in separate terminals:"
echo -e "${YELLOW}kubectl port-forward svc/frontend -n study-app $FRONTEND_PORT:$FRONTEND_PORT${NC}"
echo -e "${YELLOW}kubectl port-forward svc/backend -n study-app $BACKEND_PORT:$BACKEND_PORT${NC}"
echo ""
echo -e "Then access:"
echo -e "Frontend:  ${YELLOW}http://localhost:$FRONTEND_PORT${NC}"
echo -e "Backend:   ${YELLOW}http://localhost:$BACKEND_PORT${NC}"
echo -e "Health:    ${YELLOW}http://localhost:$BACKEND_PORT/health${NC}"

echo -e "\n🛑 To delete the cluster when finished:"
echo -e "${YELLOW}k3d cluster delete $CLUSTER_NAME${NC}"
