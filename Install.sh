#!/usr/bin/bash
set -e  # Exit on any error

INFRA_DIR="$(dirname "$0")"
# APP_NAME="atcha"
# DOCKER_IMAGE="${APP_NAME}:latest"
PROJECT_NAME="ATCHA-backend"
TF_DIR="${INFRA_DIR}/backend/terraform"
# Default configuration of buildable modules
ENABLE_APP="true"
ENABLE_PROMETHEUS="true"
ENABLE_GRAFANA="true"
ENABLE_GRAYLOG="false"

# Function to print colored output (cool factor: colors!)
print_colored() {
    local color=$1
    local message=$2
    case $color in
        "green") echo -e "\033[0;32m$message\033[0m" ;;
        "yellow") echo -e "\033[1;33m$message\033[0m" ;;
        "red") echo -e "\033[0;31m$message\033[0m" ;;
        *) echo "$message" ;;
    esac
}

# Function to ask if a module should be deployed
ask_module_include(){
  local module=$1
  local module_display=""
  case $module in
    "app") module_display="ATC Home Assistant (The controller and API)" ;;
    "prom") module_display="Prometheus (For metrics collection)" ;;
    "grafana") module_display="Grafana (For data visualization)" ;;
    "graylog") module_display="Graylog (For logging services)" ;;
  esac
  print_colored "green" "Would you like to include the $module_display module in the system build??}"
  echo
  # shellcheck disable=SC2162
  read -n1 -p $'[Y]es / [N]o (Y): ' choice
  echo
  local c="${choice:-D}"
  c=$(echo "$c" | tr '[:lower]', '[:upper]')

  case $c in
    Y|"") ;;
  esac

  case $module in
    "app") ENABLE_APP="true" ;;
    "prom") ENABLE_PROMETHEUS="true" ;;
    "grafana") ENABLE_GRAFANA="true" ;;
    "graylog")ENABLE_GRAYLOG="true" ;;
  esac
}

echo "========================================"
print_colored "green" "🚀 ATC Home Assistant Deployment Tool"
echo "========================================"

# -------------------------------
# 1⃣ Terraform commands
# -------------------------------
cd "${TF_DIR}"

# Cool prompt with ASCII flair and timeout
print_colored "yellow" "📐 By default the application and metrics collection is built (prometheus + grafana)"
echo "   Default config (fast & safe) or customize (pro mode)?"
echo
# shellcheck disable=SC2162
read -n1 -p $'Modify config? [D]efault / [C]ustomize (D): ' choice
echo  # Newline after input

choice="${choice:-D}"
choice=$(echo "$choice" | tr '[:lower]', '[:upper]')

case $choice in
    D|"")
        print_colored "green" "🔥 Building with default config..."
        # Here we just keep going
        ;;
    M)
        print_colored "yellow" "⚡ Entering customization mode..."
        # Interactive config editor, e.g., make menuconfig or nano config file
        ask_module_include "app"
        ask_module_include "prom"
        ask_module_include "grafana"
        ask_module_include "graylog"
        # Build with custom_opts, e.g., make $custom_opts && make -j$(nproc)
        ;;
    *)
        print_colored "red" "❌ Invalid choice. Aborting..."
        exit 1
        ;;
esac

print_colored "green" "========================================"
print_colored "yellow" "📌 Initializing Terraform..."
print_colored "green" "========================================"
terraform init -upgrade

print_colored "green" "========================================"
print_colored "yellow" "🔍 Validating Terraform configuration..."
print_colored "green" "========================================"
terraform validate || {
    print_colored "red" "❌ Terraform validation failed!"
    exit 1
}

print_colored "green" "========================================"
print_colored "yellow" "📐 Planning infrastructure changes..."
print_colored "green" "========================================"
terraform plan -out tfplan \
  -var="enable_app=$ENABLE_APP"                \
    -var="enable_prometheus=$ENABLE_PROMETHEUS"  \
    -var="enable_grafana=$ENABLE_GRAFANA"        \
    -var="enable_graylog=$ENABLE_GRAYLOG"        \

print_colored "green" "========================================"
print_colored "yellow" "⚡ Applying infrastructure..."
print_colored "green" "========================================"
terraform apply -auto-approve tfplan

# Extract container name for logs
CONTAINER_ID=$(docker ps -aqf "name=^${PROJECT_NAME}$")

print_colored "green" "========================================"
print_colored "green" "📡 Active Services & Endpoints"
print_colored "green" "========================================"

# Show terraform status
terraform show --json | python3 parse_terraform_output.py


if [ -z "$CONTAINER_ID" ]; then
    print_colored "yellow" "⚠ No running Rust app container found. Did Terraform start it?"
else
    print_colored "green" "========================================"
    print_colored "green" "📝 Showing Rust app logs (Ctrl+C to stop)"
    print_colored "green" "========================================"
    docker logs -f "$CONTAINER_ID"
fi

print_colored "green" "🎉 Deployment Complete!"
print_colored "red" "Press ENTER to exit..."
read -r
