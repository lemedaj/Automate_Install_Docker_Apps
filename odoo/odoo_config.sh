#!/bin/bash

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Icons for better visualization
CHECK_MARK="✓"
CROSS_MARK="✗"
GEAR="⚙"
INFO="ℹ"
ROCKET="🚀"
DATABASE="🗄"
LOCK="🔒"
SERVER="🖥"
SETTINGS="⚡"

# Function to check and create Docker resources
check_docker_resources() {
    echo -e "\n${BLUE}${GEAR} Checking Docker resources...${NC}"
    
    # Check network
    if ! docker network ls | grep -q "${NETWORK_NAME}"; then
        echo -e "${YELLOW}${INFO} Creating ${NETWORK_NAME} network...${NC}"
        docker network create ${NETWORK_NAME}
        echo -e "${GREEN}${CHECK_MARK} Network ${NETWORK_NAME} created${NC}"
    else
        echo -e "${GREEN}${CHECK_MARK} Network ${NETWORK_NAME} already exists${NC}"
    fi

    # Check volumes
    volumes=("odoo_data" "postgres_data" "pgadmin_data")
    for volume in "${volumes[@]}"; do
        if ! docker volume ls | grep -q "$volume"; then
            echo -e "${YELLOW}${INFO} Creating volume $volume...${NC}"
            docker volume create "$volume"
            echo -e "${GREEN}${CHECK_MARK} Volume $volume created${NC}"
        else
            echo -e "${GREEN}${CHECK_MARK} Volume $volume already exists${NC}"
        fi
    done
}

# Default configuration values
ODOO_VERSION="16.0"
ODOO_PORT="8069"
ODOO_DB_HOST="db"
POSTGRES_VERSION="15"
POSTGRES_DB="postgres"
POSTGRES_USER="odoo"
POSTGRES_PASSWORD="odoo"
DEFAULT_NETWORK="proxy"
PGADMIN_EMAIL="admin@\${DOMAIN_NAME}"
PGADMIN_PASSWORD="admin"

# Function to get Odoo configuration from user
get_odoo_config() {
  local ODOO_DIR="$1"

  # Check if ODOO_DIR is provided
  if [ -z "$ODOO_DIR" ]; then
    echo -e "${RED}${CROSS_MARK} Error: ODOO_DIR path is required${NC}"
    return 1
  fi

  # Create directory if it doesn't exist
  mkdir -p "$ODOO_DIR"

  # Check if odoo.env exists and is writable
  if [ -f "$ODOO_DIR/odoo.env" ]; then
    echo -e "${YELLOW}${INFO} Found existing odoo.env file${NC}"
    if [ ! -w "$ODOO_DIR/odoo.env" ]; then
      echo -e "${RED}${CROSS_MARK} Error: Cannot write to $ODOO_DIR/odoo.env${NC}"
      echo -e "${YELLOW}${INFO} Try running: sudo chown $USER:$USER $ODOO_DIR/odoo.env${NC}"
      return 1
    fi
  fi

  echo -e "\n${BLUE}${SETTINGS} Current Configuration Values:${NC}"
  echo -e "${YELLOW}${SERVER} Odoo Configuration:${NC}"
  echo -e "   Version: ${GREEN}$ODOO_VERSION${NC}"
  echo -e "   Port: ${GREEN}$ODOO_PORT${NC}"
  echo -e "   Database Host: ${GREEN}$ODOO_DB_HOST${NC}"
  
  echo -e "\n${YELLOW}${DATABASE} PostgreSQL Configuration:${NC}"
  echo -e "   Version: ${GREEN}$POSTGRES_VERSION${NC}"
  echo -e "   Database: ${GREEN}$POSTGRES_DB${NC}"
  echo -e "   Username: ${GREEN}$POSTGRES_USER${NC}"
  echo -e "   Password: ${GREEN}$POSTGRES_PASSWORD${NC}"
  
  echo -e "\n${YELLOW}${GEAR} pgAdmin Configuration:${NC}"
  echo -e "   Email: ${GREEN}$PGADMIN_EMAIL${NC}"
  echo -e "   Password: ${GREEN}$PGADMIN_PASSWORD${NC}"

  echo -e "\n${YELLOW}${INFO} Please configure the following settings:${NC}"
  
  # Only prompt for required values
  echo -e "\n${YELLOW}${SETTINGS} Network Configuration:${NC}"
  read -p "Enter network name (default: proxy): " NETWORK_NAME
  NETWORK_NAME=${NETWORK_NAME:-$DEFAULT_NETWORK}
  echo -e "${GREEN}${CHECK_MARK} Network name set to: $NETWORK_NAME${NC}"
  
  read -p "Enter domain name (default: localhost): " DOMAIN_NAME
  DOMAIN_NAME=${DOMAIN_NAME:-localhost}
  echo -e "${GREEN}${CHECK_MARK} Domain name set to: $DOMAIN_NAME${NC}"
  
  echo -e "\n${YELLOW}${GEAR} pgAdmin Configuration:${NC}"
  # Set default pgAdmin email using the domain name
  DEFAULT_PGADMIN_EMAIL="admin@$DOMAIN_NAME"
  read -p "Enter pgAdmin email (default: $DEFAULT_PGADMIN_EMAIL): " PGADMIN_EMAIL
  PGADMIN_EMAIL=${PGADMIN_EMAIL:-$DEFAULT_PGADMIN_EMAIL}
  echo -e "${GREEN}${CHECK_MARK} pgAdmin email set to: $PGADMIN_EMAIL${NC}"
  
  read -p "Enter pgAdmin password (default: admin): " PGADMIN_PASSWORD
  PGADMIN_PASSWORD=${PGADMIN_PASSWORD:-admin}
  echo -e "${GREEN}${CHECK_MARK} pgAdmin password set${NC}"

  # Create odoo.env file with configuration
  cat > "$ODOO_DIR/odoo.env" << EOL
# Network Configuration
NETWORK_NAME=$NETWORK_NAME
DOMAIN_NAME=$DOMAIN_NAME

# Odoo Configuration
ODOO_VERSION=$ODOO_VERSION
ODOO_PORT=$ODOO_PORT
ODOO_DB_HOST=$ODOO_DB_HOST

# PostgreSQL Configuration
POSTGRES_VERSION=$POSTGRES_VERSION
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# pgAdmin Configuration
PGADMIN_EMAIL=$PGADMIN_EMAIL
PGADMIN_PASSWORD=$PGADMIN_PASSWORD
EOL

  # Create symbolic link for backward compatibility
  ln -sf "$ODOO_DIR/.env" "$ODOO_DIR/odoo.env"
  
  echo -e "${BLUE}${INFO} Environment variables configured${NC}"

  echo -e "\n${GREEN}${CHECK_MARK} Configuration has been saved to $ODOO_DIR/odoo.env${NC}"
  
  # Display the contents of odoo.env
  echo -e "\n${BLUE}${INFO} Current configuration in odoo.env:${NC}"
  echo -e "${YELLOW}----------------------------------------${NC}"
  while IFS= read -r line; do
    if [[ $line == \#* ]]; then
      # Print section headers in blue
      echo -e "${BLUE}$line${NC}"
    elif [[ $line == *"="* ]]; then
      # Split the line into variable and value
      var_name=$(echo "$line" | cut -d'=' -f1)
      var_value=$(echo "$line" | cut -d'=' -f2)
      # Print variable in yellow and value in green
      echo -e "${YELLOW}$var_name${NC}=${GREEN}$var_value${NC}"
    else
      echo "$line"
    fi
  done < "$ODOO_DIR/odoo.env"
  echo -e "${YELLOW}----------------------------------------${NC}"

  # Prompt user to continue with Docker resources setup
  echo -e "\n${YELLOW}${INFO} Would you like to check and create Docker resources? (y/N):${NC}"
  read -r create_resources

  if [[ "$create_resources" =~ ^[Yy]$ ]]; then
    # Check Docker resources
    check_docker_resources
  else
    echo -e "${YELLOW}${INFO} Skipping Docker resources setup${NC}"
  fi

  echo -e "\n${YELLOW}${INFO} Would you like to start the containers now? (y/N):${NC}"
  read -r start_containers

  if [[ "$start_containers" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}${ROCKET} Starting Odoo containers...${NC}"
    docker compose -f "$ODOO_DIR/docker-compose-odoo.yml" up -d
    echo -e "${GREEN}${CHECK_MARK} Containers are starting${NC}"
    echo -e "${YELLOW}${INFO} You can check their status with: ${GREEN}docker ps${NC}"
  else
    echo -e "\n${YELLOW}${INFO} To start the containers later, run:${NC}"
    echo -e "${GREEN}cd $ODOO_DIR${NC}"
    echo -e "${GREEN}docker compose -f docker-compose-odoo.yml up -d${NC}"
  fi
}

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Main execution
get_odoo_config "$SCRIPT_DIR"
