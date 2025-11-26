#!/usr/bin/bash
set -e  # Exit on any error

INFRA_DIR="$(dirname "$0")"
# APP_NAME="atcha"
# DOCKER_IMAGE="${APP_NAME}:latest"
PROJECT_NAME="ATCHA-backend"
TF_DIR="${INFRA_DIR}"

echo "🚀 ATC Home Assistant Deployment Tool"
echo "========================================"

# -------------------------------
# 1⃣ Terraform commands
# -------------------------------
cd "${TF_DIR}"

echo "🔍 Validating Terraform configuration..."
terraform validate || {
    echo "❌ Terraform validation failed!"
    exit 1
}

echo "📌 Initializing Terraform..."
terraform init -upgrade

echo "📐 Planning infrastructure changes..."
terraform plan -out tfplan

echo "⚡ Applying infrastructure..."
terraform apply -auto-approve tfplan

# Extract container name for logs
CONTAINER_ID=$(docker ps -aqf "name=^${PROJECT_NAME}$")
echo "Docker container ID for ATCHA: ${CONTAINER_ID}"

echo "========================================"
echo "📡 Active Services & Endpoints"
echo "========================================"

# Show terraform status
terraform show --json | python3 parse_terraform_output.py


if [ -z "$CONTAINER_ID" ]; then
    echo "⚠ No running Rust app container found. Did Terraform start it?"
else
    echo "📝 Showing Rust app logs (Ctrl+C to stop)"
    echo "========================================"
    docker logs -f "$CONTAINER_ID"
fi

echo "🎉 Deployment Complete!"
echo "Press ENTER to exit..."
read -r
