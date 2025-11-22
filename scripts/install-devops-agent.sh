#!/bin/bash
set -e

# Azure DevOps Agent Installation Script
# This script downloads, installs, and configures the Azure DevOps agent on a Linux VM
# Must be run as root, but config.sh must be run as a non-root user

# Parameters
POOL_NAME="${1}"
ORG_URL="${2}"
PAT="${3}"
AGENT_PREFIX="${4}"

if [ -z "$POOL_NAME" ] || [ -z "$ORG_URL" ] || [ -z "$PAT" ] || [ -z "$AGENT_PREFIX" ]; then
  echo "Usage: $0 <POOL_NAME> <ORG_URL> <PAT> <AGENT_PREFIX>"
  exit 1
fi

# Agent directory
AGENT_DIR="/azagent"
AGENT_USER="azureuser"
AGENT_HOME="/home/${AGENT_USER}"

# Install Docker if not already installed
echo "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  # Remove old versions
  sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

  # Install prerequisites
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg lsb-release

  # Add Docker's official GPG key
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  # Set up Docker repository
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Install Docker Engine
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Start and enable Docker service
  sudo systemctl enable docker
  sudo systemctl start docker
else
  echo "Docker is already installed"
fi

# Add azureuser to docker group (allows running docker without sudo)
if ! groups ${AGENT_USER} | grep -q docker; then
  echo "Adding ${AGENT_USER} to docker group..."
  sudo usermod -aG docker ${AGENT_USER}
else
  echo "${AGENT_USER} is already in docker group"
fi

# Verify Docker installation
echo "Verifying Docker installation..."
if sudo docker --version > /dev/null 2>&1; then
  echo "Docker installed successfully: $(sudo docker --version)"
else
  echo "Warning: Docker installation verification failed"
  exit 1
fi

# Create agent directory with proper permissions
echo "Creating agent directory..."
sudo mkdir -p "$AGENT_DIR"
sudo chmod 755 "$AGENT_DIR"
sudo chown -R ${AGENT_USER}:${AGENT_USER} "$AGENT_DIR"

# Download and extract agent
echo "Downloading Azure DevOps agent..."
# Use a fixed version as fallback
AGENT_VERSION="4.265.1"  # Latest stable version as fallback
AGENT_TAR="${AGENT_DIR}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz"

# Download agent from the official Azure DevOps download URL
echo "Downloading agent version ${AGENT_VERSION}..."
sudo curl -L -f -o "$AGENT_TAR" "https://download.agent.dev.azure.com/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz" || {
  echo "Error: Failed to download agent from download.agent.dev.azure.com"
  exit 1
}

# Verify download
if [ ! -f "$AGENT_TAR" ]; then
  echo "Error: Failed to download agent"
  exit 1
fi

# Extract agent
echo "Extracting agent..."
cd "$AGENT_DIR"
sudo tar zxvf "$AGENT_TAR"
sudo chown -R ${AGENT_USER}:${AGENT_USER} "$AGENT_DIR"

# Generate unique agent name using hostname (already unique for VMSS instances)
HOSTNAME=$(hostname)
AGENT_NAME="${AGENT_PREFIX}-${HOSTNAME}"

# Configure agent as azureuser (must not run with sudo)
echo "Configuring agent as ${AGENT_USER}..."
cd "$AGENT_DIR"

# Remove existing configuration if it exists (check multiple indicators)
if [ -f "${AGENT_DIR}/.agent" ] || [ -f "${AGENT_DIR}/.credentials" ] || [ -d "${AGENT_DIR}/_diag" ]; then
  echo "Removing existing agent configuration..."
  # Remove configuration using runuser (this will handle service cleanup)
  runuser -l ${AGENT_USER} -c "cd '${AGENT_DIR}' && ./config.sh remove --unattended || true" 2>/dev/null || true
  # Force cleanup of agent directory
  rm -rf "${AGENT_DIR}/.agent" "${AGENT_DIR}/.credentials" "${AGENT_DIR}/_diag" 2>/dev/null || true
  # Wait a moment for cleanup
  sleep 2
fi

# Run config.sh as azureuser using runuser (no sudo detection)
# runuser creates a clean environment without sudo context
runuser -l ${AGENT_USER} -c "\
  cd '${AGENT_DIR}' && \
  ./config.sh \
    --unattended \
    --url '${ORG_URL}' \
    --auth pat \
    --token '${PAT}' \
    --pool '${POOL_NAME}' \
    --agent '${AGENT_NAME}' \
    --replace \
    --acceptTeeEula \
    --work '_work'"

# Verify Docker works for azureuser (using newgrp to activate docker group)
echo "Verifying Docker access for ${AGENT_USER}..."
runuser -l ${AGENT_USER} -c "newgrp docker <<EOF
docker ps > /dev/null 2>&1 && echo 'Docker access verified for ${AGENT_USER}' || echo 'Warning: Docker access may need session restart'
EOF
" || echo "Note: Docker group will be active after agent restart"

# Install and start service
echo "Installing agent service..."
cd "$AGENT_DIR"
# Try to uninstall any existing service first (ignore errors)
sudo ./svc.sh uninstall 2>/dev/null || true
# Remove service file manually if it still exists (handles escaped characters in filename)
# Use glob to match the actual filename with escaped characters
for service_file in /etc/systemd/system/vsts.agent.*; do
  [ -f "$service_file" ] && sudo rm -f "$service_file" 2>/dev/null || true
done
# Reload systemd to clear any cached service definitions
sudo systemctl daemon-reload 2>/dev/null || true
# Install service
sudo ./svc.sh install ${AGENT_USER}

echo "Starting agent service..."
sudo ./svc.sh start

echo "Azure DevOps agent installed and started successfully!"
echo "Agent name: ${AGENT_NAME}"
echo "Pool: ${POOL_NAME}"
echo "Docker installed and configured for ${AGENT_USER}"

