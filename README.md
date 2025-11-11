# 🐳 DevOps Study Tracker -  Development Environment

**🔗 GitOps Repository**: [Tim275/mindset-app-gitops](https://github.com/Tim275/mindset-app-gitops) - Kubernetes manifests and deployment configurations

## 📋 Overview

A modern, containerized full-stack application demonstrating enterprise-grade DevOps practices with automated CI/CD, **GitOps deployment**, and **End-to-End Kubernetes testing**. This project serves as a **DevOps masterclass** showcasing cutting-edge technologies like **uv** (ultra-fast Python package manager), **mise** (universal tool version management), **k3d** (lightweight Kubernetes), **DevContainer environments**, **GitHub Actions CI/CD**, **Release Please** (automated versioning), **GitOps workflows**, **Trivy security scanning**, and **enterprise E2E testing pipelines**.

## 🚀 Quick Start

### **DevContainer (Recommended)**
```bash
# 1. Open in VS Code with DevContainer extension
# 2. Command Palette: "Dev Containers: Reopen in Container"
# 3. DevContainer auto-runs: mise install + uv sync

# Start services
docker compose up --build

# Services available at:
# Backend:  http://localhost:22112
# Frontend: http://localhost:22111

# Run E2E tests in local Kubernetes
cd kubernetes
uv run python e2e_test.py
```

### **Local Development**
```bash
# Install mise: https://mise.jdx.dev/getting-started.html
mise install        # Install Python 3.13, uv, k3d, kubectl
docker compose up --build
```

## 🛠️ Key Technologies

### **🐳 DevContainer + 🔧 mise.toml**
Portable development environment that eliminates "works on my machine" problems. The `mise.toml` ensures all developers use identical tool versions (Python 3.13, uv, k3d, kubectl).

### **🐍 Modern Python Stack**
- **uv**: Ultra-fast package manager (10-100x faster than pip)
- **Ruff**: Lightning-fast Python linting and formatting
- **FastAPI**: High-performance async backend
- **Flask**: Simple, flexible frontend framework

### **☸️ Enterprise E2E Testing**
- **k3d**: Lightweight Kubernetes cluster for testing
- **kubectl**: Kubernetes command-line tool
- **Complete User Journey**: 7-step validation pipeline

### **🔄 GitOps Architecture**
- **Source Repo**: Application code with CI/CD automation
- **GitOps Repo**: Kubernetes manifests with Kustomize overlays
- **Automated Updates**: CI/CD triggers GitOps deployments
- **Environment Separation**: Dev auto-deploy, Prod manual approval

### **Integration Workflow:**
```bash
mise install        # Consistent tool versions (auto-run in DevContainer)
uv sync --locked    # Exact dependency management
uv run python e2e_test.py  # Enterprise E2E testing
```
