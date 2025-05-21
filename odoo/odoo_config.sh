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
    if ! docker network ls | grep -q "odoo_network"; then
        echo -e "${YELLOW}${INFO} Creating odoo_network...${NC}"
        docker network create odoo_network
        echo -e "${GREEN}${CHECK_MARK} Network created${NC}"
    else
        echo -e "${GREEN}${CHECK_MARK} Network odoo_network already exists${NC}"
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
PGADMIN_EMAIL="admin@example.com"
PGADMIN_PASSWORD="admin"

# Function to get Odoo configuration from user
get_odoo_config() {
  local ODOO_DIR="$1"

  # Check if ODOO_DIR is provided
  if [ -z "$ODOO_DIR" ]; then
    echo -e "${RED}${CROSS_MARK} Error: ODOO_DIR path is required${NC}"
    return 1
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

  echo -e "\nWould you like to modify any of these values? (y/N):"
  read -r modify_config

  if [[ "$modify_config" =~ ^[Yy]$ ]]; then
    echo "Enter new values (press Enter to keep default):"

    # Prompt for new values if requested
    echo "Odoo Version [$ODOO_VERSION]:"
    read -r input; [ -n "$input" ] && ODOO_VERSION=$input

    echo "Odoo Port [$ODOO_PORT]:"
    read -r input; [ -n "$input" ] && ODOO_PORT=$input

    echo "Database Host [$ODOO_DB_HOST]:"
    read -r input; [ -n "$input" ] && ODOO_DB_HOST=$input

    echo "PostgreSQL Version [$POSTGRES_VERSION]:"
    read -r input; [ -n "$input" ] && POSTGRES_VERSION=$input

    echo "Database Name [$POSTGRES_DB]:"
    read -r input; [ -n "$input" ] && POSTGRES_DB=$input

    echo "Database User [$POSTGRES_USER]:"
    read -r input; [ -n "$input" ] && POSTGRES_USER=$input

    echo "Database Password [$POSTGRES_PASSWORD]:"
    read -r input; [ -n "$input" ] && POSTGRES_PASSWORD=$input

    echo "pgAdmin Email [$PGADMIN_EMAIL]:"
    read -r input; [ -n "$input" ] && PGADMIN_EMAIL=$input

    echo "pgAdmin Password [$PGADMIN_PASSWORD]:"
    read -r input; [ -n "$input" ] && PGADMIN_PASSWORD=$input
  fi

  # Create odoo.env file with configuration
  cat > "$ODOO_DIR/odoo.env" << EOL
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

  # Check Docker resources
  check_docker_resources

  echo -e "\n${YELLOW}${INFO} Would you like to start the containers now? (y/N):${NC}"
  read -r start_containers

  if [[ "$start_containers" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}${ROCKET} Starting Odoo containers...${NC}"
    docker-compose -f "$ODOO_DIR/docker-compose-odoo.yml" up -d
    echo -e "${GREEN}${CHECK_MARK} Containers are starting${NC}"
    echo -e "${YELLOW}${INFO} You can check their status with: ${GREEN}docker ps${NC}"
  else
    echo -e "\n${YELLOW}${INFO} To start the containers later, run:${NC}"
    echo -e "${GREEN}cd $ODOO_DIR${NC}"
    echo -e "${GREEN}docker-compose -f docker-compose-odoo.yml up -d${NC}"
  fi
}
