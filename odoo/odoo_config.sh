#!/bin/bash

# Function to check and create Docker resources
check_docker_resources() {
  if [ -n "$PWSH_EXECUTION" ]; then
    # PowerShell commands for Windows
    if ! docker network ls | Select-String -Pattern "${NETWORK_NAME}" -Quiet; then
      Write-Host "Creating ${NETWORK_NAME} network..."
      docker network create ${NETWORK_NAME}
    else
      Write-Host "Network ${NETWORK_NAME} already exists."
    fi

    # Check volumes
    volumes=("odoo_data" "postgres_data")
    for volume in "${volumes[@]}"; do
      if ! docker volume ls | grep -q "$volume"; then
        echo "Creating volume $volume..."
        docker volume create "$volume"
      else
        echo "Volume $volume already exists."
      fi
      fi
    }
  else
    # Bash commands for Linux/Unix
    # Check if network exists
    if ! docker network ls | grep -q "${NETWORK_NAME}"; then
      echo "Creating ${NETWORK_NAME} network..."
      docker network create ${NETWORK_NAME}
    else
      echo "Network ${NETWORK_NAME} already exists."
    fi

    # Check if volumes exist
    for volume in "odoo_data" "postgres_data"; do
      if ! docker volume ls | grep -q "$volume"; then
        echo "Creating volume $volume..."
        docker volume create "$volume"
      else
        echo "Volume $volume already exists."
      fi
    done
  fi
}

# Default values for Odoo configuration
ODOO_DEFAULTS=(
  ["ODOO_VERSION"]="latest"      # Default Odoo version
  ["ODOO_PORT"]="8069"          # Default Odoo port
  ["ODOO_DB_HOST"]="db"         # Default database host
  ["POSTGRES_VERSION"]="latest"  # Default PostgreSQL version
  ["POSTGRES_DB"]="postgres"     # Default database name
  ["POSTGRES_USER"]="odoo"      # Default database user
  ["POSTGRES_PASSWORD"]="odoo"       # Must be set by user
  ["DOMAIN_NAME"]="example.com"            # Must be set by user
)

# Function to get Odoo configuration from user
get_odoo_config() {
  local ODOO_DIR="$1"

  # Check if ODOO_DIR is provided
  if [ -z "$ODOO_DIR" ]; then
    echo "Error: ODOO_DIR path is required"
    return 1
  fi

  # Check and create required Docker resources
  check_docker_resources

  # Odoo Configuration
  echo "Please enter Odoo version (default: ${ODOO_DEFAULTS[ODOO_VERSION]}):"
  read -r ODOO_VERSION
  ODOO_VERSION=${ODOO_VERSION:-${ODOO_DEFAULTS[ODOO_VERSION]}}

  echo "Please enter Odoo port (default: ${ODOO_DEFAULTS[ODOO_PORT]}):"
  read -r ODOO_PORT
  ODOO_PORT=${ODOO_PORT:-${ODOO_DEFAULTS[ODOO_PORT]}}

  # Database Configuration
  echo "Please enter database host (default: ${ODOO_DEFAULTS[ODOO_DB_HOST]}):"
  read -r ODOO_DB_HOST
  ODOO_DB_HOST=${ODOO_DB_HOST:-${ODOO_DEFAULTS[ODOO_DB_HOST]}}

  echo "Please enter PostgreSQL version (default: ${ODOO_DEFAULTS[POSTGRES_VERSION]}):"
  read -r POSTGRES_VERSION
  POSTGRES_VERSION=${POSTGRES_VERSION:-${ODOO_DEFAULTS[POSTGRES_VERSION]}}

  echo "Please enter PostgreSQL database name (default: ${ODOO_DEFAULTS[POSTGRES_DB]}):"
  read -r POSTGRES_DB
  POSTGRES_DB=${POSTGRES_DB:-${ODOO_DEFAULTS[POSTGRES_DB]}}

  echo "Please enter database user (default: ${ODOO_DEFAULTS[POSTGRES_USER]}):"
  read -r POSTGRES_USER
  POSTGRES_USER=${POSTGRES_USER:-${ODOO_DEFAULTS[POSTGRES_USER]}}

  # Required fields with validation
  echo "Please enter database password (required):"
  read -r POSTGRES_PASSWORD
  while [ -z "$POSTGRES_PASSWORD" ]; do
    echo "Password cannot be empty. Please enter database password:"
    read -r POSTGRES_PASSWORD
  done

  echo "Please enter domain name (required, e.g., example.com):"
  read -r DOMAIN_NAME
  while [ -z "$DOMAIN_NAME" ]; do
    echo "Domain name cannot be empty. Please enter domain name:"
    read -r DOMAIN_NAME
  done

  # Create Odoo configuration directory if it doesn't exist
  mkdir -p "$(dirname "$ODOO_DIR/.env")"

  # Update Odoo .env file with all settings
  cat > "$ODOO_DIR/.env" << EOL
# Odoo Configuration
ODOO_VERSION=$ODOO_VERSION
ODOO_PORT=$ODOO_PORT
ODOO_DB_HOST=$ODOO_DB_HOST

# PostgreSQL Configuration
POSTGRES_VERSION=$POSTGRES_VERSION
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Network and Domain Configuration
NETWORK_NAME=$NETWORK_NAME
DOMAIN_NAME=$DOMAIN_NAME
EOL

  echo "Odoo configuration has been saved to $ODOO_DIR/.env"
}
