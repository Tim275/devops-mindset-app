#!/usr/bin/env python3
"""
🎯 MINIMAL K3D CLUSTER SETUP - Nur Phase 1
Verstehe setup_cluster() Funktion isoliert
"""

import os
import sys
import subprocess
import logging
import shutil

# Setup logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("e2e-tests")


class K8sTestEnvironment:
    def __init__(self, cluster_name="study-app-cluster", skip_cluster_creation=False):
        """
        🏗️ E2E TEST ENVIRONMENT SETUP - NUR FÜR PHASE 1
        """
        self.cluster_name = cluster_name
        self.skip_cluster_creation = skip_cluster_creation
        self.base_dir = os.path.dirname(os.path.abspath(__file__))

        # Check if kubectl is installed
        self.check_kubectl_installed()

    def check_kubectl_installed(self):
        """
        ✅ PREREQUISITE CHECK
        """
        if shutil.which("kubectl") is None:
            logger.error("kubectl is not installed or not in PATH.")
            sys.exit(1)
        logger.info("kubectl is installed and available.")

        if shutil.which("k3d") is None:
            logger.error("k3d is not installed or not in PATH.")
            sys.exit(1)
        logger.info("k3d is installed and available.")

    def run_command(self, cmd, cwd=None, shell=False, check=True, capture_output=False):
        """
        🔧 COMMAND EXECUTOR
        """
        logger.info(f"Running command: {cmd}")
        if shell:
            result = subprocess.run(
                cmd, shell=True, check=check, cwd=cwd, capture_output=capture_output
            )
        else:
            result = subprocess.run(
                cmd.split(), check=check, cwd=cwd, capture_output=capture_output
            )
        return result

    def setup_cluster(self):
        """
        🏗️ KUBERNETES CLUSTER SETUP
        Phase 1: Infrastructure bereitstellen
        """
        if self.skip_cluster_creation:
            logger.info("Skipping cluster creation as requested")
            return

        # Check if cluster already exists and delete it if it does
        result = self.run_command(
            "k3d cluster list", shell=True, check=False, capture_output=True
        )

        # Safely check if cluster exists in the output
        cluster_exists = False
        if hasattr(result, "stdout") and result.stdout is not None:
            cluster_exists = self.cluster_name in result.stdout.decode("utf-8")

        if cluster_exists:
            logger.info(f"Cluster {self.cluster_name} exists, deleting it")
            self.run_command(f"k3d cluster delete {self.cluster_name}")

        # Create the k3d cluster using our config
        config_path = os.path.join(self.base_dir, "k3d-config.yaml")
        if os.path.exists(config_path):
            logger.info(f"Using config: {config_path}")
            self.run_command(f"k3d cluster create --config {config_path}")
        else:
            logger.warning(f"Config not found: {config_path}")
            logger.info("Creating basic cluster...")
            self.run_command(f"k3d cluster create {self.cluster_name}")

        # Configure kubectl to use the new cluster
        self.run_command("kubectl config use-context k3d-study-app-cluster")

        # Wait for cluster to be ready
        logger.info("Waiting for cluster to be ready...")
        self.run_command("kubectl wait --for=condition=Ready nodes --all --timeout=60s")


if __name__ == "__main__":
    """
    🎯 NUR PHASE 1 AUSFÜHREN
    """
    # Initialize
    test_env = K8sTestEnvironment()

    try:
        # Phase 1: Setup infrastructure
        logger.info("🏗️ Phase 1: Setting up infrastructure...")
        test_env.setup_cluster()

        logger.info("✅ Phase 1 Complete: k3d cluster ready!")

    except Exception as e:
        logger.error(f"❌ Phase 1 failed: {e}")
        sys.exit(1)
