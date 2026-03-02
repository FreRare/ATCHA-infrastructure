#!/bin/bash
# deploy-api.sh - Automated API container rebuild and deployment

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/infrastructure"  # Adjust path as needed
DOCKERFILE_PATH="${SCRIPT_DIR}/Dockerfile"
CONTEXT_PATH="${SCRIPT_DIR}"
IMAGE_NAME="atcha-backend"
IMAGE_TAG="latest"

# Logging setup
LOG_FILE="${SCRIPT_DIR}/deploy-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "🚀 Starting automated deployment at $(date)"
echo "📋 Log file: $LOG_FILE"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check prerequisites
log "🔍 Checking prerequisites..."
for cmd in docker terraform; do
    if ! command_exists "$cmd"; then
        log "❌ Error: $cmd is not installed or not in PATH"
        exit 1
    fi
done
log "✅ Prerequisites check passed"

# Step 1: Build Docker image
log "🔨 Building Docker image..."
cd "$CONTEXT_PATH"
if docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f "$DOCKERFILE_PATH" .; then
    log "✅ Docker image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
else
    log "❌ Docker build failed"
    exit 1
fi

# Step 2: Initialize Terraform (if needed)
log "🏗️  Initializing Terraform..."
cd "$TERRAFORM_DIR"
if terraform init; then
    log "✅ Terraform initialized"
else
    log "❌ Terraform initialization failed"
    exit 1
fi

# Step 3: Plan Terraform changes
log "📋 Planning Terraform changes..."
if terraform plan -out=tfplan -var="image_tag=${IMAGE_TAG}"; then
    log "✅ Terraform plan created successfully"
else
    log "❌ Terraform plan failed"
    exit 1
fi

# Step 4: Review plan (optional - you can remove this for full automation)
log "🔍 Reviewing Terraform plan..."
terraform show -no-color tfplan

# Ask for confirmation (remove for full automation)
read -p "🤔 Do you want to apply these changes? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "❌ Deployment cancelled by user"
    exit 0
fi

# Step 5: Apply Terraform changes
log "🚀 Applying Terraform changes..."
if terraform apply tfplan; then
    log "✅ Terraform apply completed successfully"
else
    log "❌ Terraform apply failed"
    exit 1
fi

# Step 6: Verify deployment
log "🔍 Verifying deployment..."
CONTAINER_NAME=$(terraform output -raw container_name 2>/dev/null || echo "atcha-backend")
if docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "${CONTAINER_NAME}"; then
    log "✅ Container is running successfully"
    docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    log "⚠️  Container verification failed - check logs manually"
fi

# Cleanup
rm -f tfplan

log "🎉 Deployment completed successfully at $(date)"
log "📊 Summary:"
log "   - Image: ${IMAGE_NAME}:${IMAGE_TAG}"
log "   - Container: ${CONTAINER_NAME}"
log "   - Log file: $LOG_FILE"
