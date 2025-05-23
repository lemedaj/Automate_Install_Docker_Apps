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
ODOO_VERSION="18.0"
ODOO_PORT="8069"
ODOO_DB_HOST="postgres"
POSTGRES_VERSION="17"
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

  echo -e "\n${GREEN}${CHECK_MARK} Configuration completed successfully${NC}"
}

# Function to update configuration files with user variables
update_config_files() {
    local ODOO_DIR="$1"
    echo -e "\n${BLUE}${GEAR} Updating configuration files...${NC}"

    # Update odoo.conf
    echo -e "${YELLOW}${INFO} Updating odoo.conf...${NC}"
    sed -i "s/\${ODOO_DB_HOST}/$ODOO_DB_HOST/g" "$ODOO_DIR/odoo.conf"
    sed -i "s/\${POSTGRES_USER}/$POSTGRES_USER/g" "$ODOO_DIR/odoo.conf"
    sed -i "s/\${POSTGRES_PASSWORD}/$POSTGRES_PASSWORD/g" "$ODOO_DIR/odoo.conf"
    sed -i "s/\${POSTGRES_DB}/$POSTGRES_DB/g" "$ODOO_DIR/odoo.conf"
    sed -i "s/\${ODOO_MASTER_PASSWORD}/$POSTGRES_PASSWORD/g" "$ODOO_DIR/odoo.conf"
    echo -e "${GREEN}${CHECK_MARK} odoo.conf updated${NC}"

    # Update odoo.env
    echo -e "${YELLOW}${INFO} Updating odoo.env...${NC}"
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

# Traefik Labels
TRAEFIK_ROUTER=odoo
TRAEFIK_ENTRYPOINT=websecure
TRAEFIK_CERT_RESOLVER=cloudflare
EOL
    echo -e "${GREEN}${CHECK_MARK} odoo.env updated${NC}"

    echo -e "${GREEN}${CHECK_MARK} All configuration files updated successfully${NC}"
}

# Validate that all required environment variables are set
validate_env_vars() {
    local required_vars=(
        "ODOO_VERSION"
        "ODOO_DB_HOST"
        "POSTGRES_USER"
        "POSTGRES_PASSWORD"
        "NETWORK_NAME"
        "DOMAIN_NAME"
        "ODOO_PORT"
        "POSTGRES_VERSION"
        "POSTGRES_DB"
        "PGADMIN_EMAIL"
        "PGADMIN_PASSWORD"
    )
    
    local missing_vars=()
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo -e "${RED}${CROSS_MARK} Error: The following required variables are not set:${NC}"
        printf '%s\n' "${missing_vars[@]}" | sed 's/^/  - /'
        return 1
    fi
    
    return 0
}

# Function to source environment file
safe_source_env() {
    local env_file="$1"
    source "$env_file"
}

# Function to update docker-compose-odoo.yml with configuration values
update_docker_compose() {
    local ODOO_DIR="$1"
    echo -e "\n${BLUE}${GEAR} Updating docker-compose-odoo.yml variables...${NC}"

    # Check if docker-compose-odoo.yml exists
    if [ ! -f "$ODOO_DIR/docker-compose-odoo.yml" ]; then
        echo -e "${RED}${CROSS_MARK} Error: docker-compose-odoo.yml not found in $ODOO_DIR${NC}"
        return 1
    fi

    # Create backup of original file
    cp "$ODOO_DIR/docker-compose-odoo.yml" "$ODOO_DIR/docker-compose-odoo.yml.bak"
    echo -e "${GREEN}${CHECK_MARK} Backup created: docker-compose-odoo.yml.bak${NC}"

    # Load environment variables using the safe_source_env function
    if [ -f "$ODOO_DIR/odoo.env" ]; then
        safe_source_env "$ODOO_DIR/odoo.env"
    else
        echo -e "${RED}${CROSS_MARK} Error: odoo.env not found${NC}"
        return 1
    fi

    # Validate environment variables
    echo -e "${YELLOW}${INFO} Validating environment variables...${NC}"
    if ! validate_env_vars; then
        echo -e "${RED}${CROSS_MARK} Environment validation failed${NC}"
        return 1
    fi

    # Create a temporary file with all variables expanded
    echo -e "${YELLOW}${INFO} Updating all configuration variables...${NC}"
    
    # Export all required variables
    export ODOO_VERSION ODOO_DB_HOST POSTGRES_USER POSTGRES_PASSWORD NETWORK_NAME DOMAIN_NAME ODOO_PORT POSTGRES_VERSION POSTGRES_DB PGADMIN_EMAIL PGADMIN_PASSWORD
    
    # Create a temporary file with variables substituted
    envsubst < "$ODOO_DIR/docker-compose-odoo.yml" > "$ODOO_DIR/docker-compose-odoo.yml.tmp"
    
    # Check if the temporary file is not empty and contains valid content
    if [ ! -s "$ODOO_DIR/docker-compose-odoo.yml.tmp" ] || ! grep -q "version:" "$ODOO_DIR/docker-compose-odoo.yml.tmp"; then
        echo -e "${RED}${CROSS_MARK} Error: Variable substitution failed (invalid output)${NC}"
        echo -e "${YELLOW}${INFO} Restoring backup...${NC}"
        mv "$ODOO_DIR/docker-compose-odoo.yml.bak" "$ODOO_DIR/docker-compose-odoo.yml"
        rm -f "$ODOO_DIR/docker-compose-odoo.yml.tmp"
        return 1
    fi

    # Replace the original with the updated version
    mv "$ODOO_DIR/docker-compose-odoo.yml.tmp" "$ODOO_DIR/docker-compose-odoo.yml"

    # Validate the docker-compose file
    echo -e "${YELLOW}${INFO} Validating docker-compose file...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}${CROSS_MARK} Error: docker is not installed or not in PATH${NC}"
        mv "$ODOO_DIR/docker-compose-odoo.yml.bak" "$ODOO_DIR/docker-compose-odoo.yml"
        return 1
    fi

    # Use docker compose config to validate the file
    if docker compose -f "$ODOO_DIR/docker-compose-odoo.yml" config --quiet; then
        echo -e "${GREEN}${CHECK_MARK} docker-compose-odoo.yml validation successful${NC}"
        rm "$ODOO_DIR/docker-compose-odoo.yml.bak"  # Remove backup if successful
        
        # Show preview of the changes
        echo -e "${YELLOW}${INFO} Preview of updated configuration:${NC}"
        docker compose -f "$ODOO_DIR/docker-compose-odoo.yml" config | grep -E "image:|container_name:|network:|NETWORK_NAME|DOMAIN_NAME"
        return 0
    else
        echo -e "${RED}${CROSS_MARK} Error: docker-compose-odoo.yml validation failed${NC}"
        echo -e "${YELLOW}${INFO} Restoring backup...${NC}"
        mv "$ODOO_DIR/docker-compose-odoo.yml.bak" "$ODOO_DIR/docker-compose-odoo.yml"
        echo -e "${GREEN}${CHECK_MARK} Backup restored${NC}"
        
        # Print debug info
        echo -e "${YELLOW}${INFO} Debug information:${NC}"
        env | grep -E "ODOO|POSTGRES|NETWORK|DOMAIN|PGADMIN"
        return 1
    fi
}

# Function to start the containers
start_containers() {
    local ODOO_DIR="$1"
    
    echo -e "\n${YELLOW}${INFO} Would you like to start the containers now? (y/N):${NC}"
    read -r start_containers

    if [[ "$start_containers" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}${ROCKET} Starting Odoo containers...${NC}"
        docker compose -f "$ODOO_DIR/docker-compose-odoo.yml" --env-file "$ODOO_DIR/odoo.env" up -d
        echo -e "${GREEN}${CHECK_MARK} Containers are starting${NC}"
        echo -e "${YELLOW}${INFO} You can check their status with: ${GREEN}docker ps${NC}"
    else
        echo -e "\n${YELLOW}${INFO} To start the containers later, run:${NC}"
        echo -e "${GREEN}cd $ODOO_DIR${NC}"
        echo -e "${GREEN}docker compose -f docker-compose-odoo.yml --env-file odoo.env up -d${NC}"
    fi
}

# Check if envsubst is available
check_dependencies() {
    if ! command -v envsubst &> /dev/null; then
        echo -e "${RED}${CROSS_MARK} Error: envsubst is not installed. Please install gettext package.${NC}"
        echo -e "${YELLOW}${INFO} On Windows with Chocolatey: choco install gettext${NC}"
        echo -e "${YELLOW}${INFO} On Ubuntu/Debian: sudo apt-get install gettext-base${NC}"
        return 1
    fi
    return 0
}

# Main function to orchestrate the configuration process
main() {
    local ODOO_DIR="$1"
    
    echo -e "\n${BLUE}${GEAR} Starting Odoo configuration process...${NC}"
    
    # Step 1: Get configuration from user
    echo -e "\n${BLUE}${SETTINGS} Step 1: Getting user configuration...${NC}"
    if ! get_odoo_config "$ODOO_DIR"; then
        echo -e "${RED}${CROSS_MARK} Configuration failed. Exiting.${NC}"
        return 1
    fi
    
    # Step 2: Update configuration files
    echo -e "\n${BLUE}${SETTINGS} Step 2: Updating configuration files...${NC}"
    if ! update_config_files "$ODOO_DIR"; then
        echo -e "${RED}${CROSS_MARK} Failed to update configuration files. Exiting.${NC}"
        return 1
    fi
    
    # Step 3: Update docker-compose file
    echo -e "\n${BLUE}${SETTINGS} Step 3: Updating docker-compose file...${NC}"
    if ! update_docker_compose "$ODOO_DIR"; then
        echo -e "${RED}${CROSS_MARK} Failed to update docker-compose file. Exiting.${NC}"
        return 1
    fi
    
    # Step 4: Check and create Docker resources
    echo -e "\n${BLUE}${SETTINGS} Step 4: Checking Docker resources...${NC}"
    echo -e "\n${YELLOW}${INFO} Would you like to check and create Docker resources? (y/N):${NC}"
    read -r create_resources

    if [[ "$create_resources" =~ ^[Yy]$ ]]; then
        if ! check_docker_resources; then
            echo -e "${RED}${CROSS_MARK} Failed to set up Docker resources. Exiting.${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}${INFO} Skipping Docker resources setup${NC}"
    fi
    
    # Step 5: Start containers
    echo -e "\n${BLUE}${SETTINGS} Step 5: Container management...${NC}"
    start_containers "$ODOO_DIR"
    
    echo -e "\n${GREEN}${CHECK_MARK} Odoo configuration process completed successfully${NC}"
}

# Use current directory as ODOO_DIR
ODOO_DIR="."

# Start the configuration process
if ! check_dependencies; then
    exit 1
fi
main "$ODOO_DIR"
