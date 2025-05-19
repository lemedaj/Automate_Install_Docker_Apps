#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Icons
CHECK_MARK="✓"
CROSS_MARK="✗"
GEAR="⚙"
INFO="ℹ"

echo -e "${BLUE}${GEAR} Configuring Traefik...${NC}"

# Function to validate input
validate_input() {
    local input=$1
    local type=$2
    local name=$3

    case $type in
        "port")
            if ! [[ $input =~ ^[0-9]+$ ]] || [ "$input" -lt 1 ] || [ "$input" -gt 65535 ]; then
                echo -e "${RED}${CROSS_MARK} Error: Invalid port number for $name${NC}"
                return 1
            fi
            ;;
        "email")
            if ! [[ $input =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                echo -e "${RED}${CROSS_MARK} Error: Invalid email format for $name${NC}"
                return 1
            fi
            ;;
        *)
            if [ -z "$input" ]; then
                echo -e "${RED}${CROSS_MARK} Error: Empty input for $name${NC}"
                return 1
            fi
            ;;
    esac
    return 0
}

# Function to get Traefik configuration from user
get_traefik_config() {
    echo -e "\n${BLUE}${INFO} Configuring Traefik Settings${NC}"
    
    # Get Traefik dashboard port
    while true; do
        echo -e "\n${YELLOW}${INFO} Enter Traefik dashboard port (default: 8080):${NC}"
        read -r TRAEFIK_PORT
        TRAEFIK_PORT=${TRAEFIK_PORT:-8080}
        if validate_input "$TRAEFIK_PORT" "port" "Traefik dashboard port"; then
            break
        fi
    done
    
    # Get Cloudflare credentials
    while true; do
        echo -e "\n${YELLOW}${INFO} Enter your Cloudflare email:${NC}"
        read -r CF_EMAIL
        if validate_input "$CF_EMAIL" "email" "Cloudflare email"; then
            break
        fi
    done
    
    echo -e "\n${YELLOW}${INFO} Enter your Cloudflare API key:${NC}"
    read -r CF_API_KEY
    
    # Get Traefik dashboard credentials
    echo -e "\n${YELLOW}${INFO} Enter username for Traefik dashboard (default: admin):${NC}"
    read -r TRAEFIK_USER
    TRAEFIK_USER=${TRAEFIK_USER:-admin}
    
    echo -e "\n${YELLOW}${INFO} Enter password for Traefik dashboard (default: admin):${NC}"
    read -r TRAEFIK_PASSWORD
    TRAEFIK_PASSWORD=${TRAEFIK_PASSWORD:-admin}
    
    # Generate htpasswd for Traefik dashboard
    TRAEFIK_AUTH=$(docker run --rm httpd:2.4-alpine htpasswd -nbB "$TRAEFIK_USER" "$TRAEFIK_PASSWORD" | sed -e s/\\$/\\$\\$/g)
    
    # Create Traefik env file
    cat > "$SCRIPT_DIR/traefik.env" << EOL
TRAEFIK_VERSION=latest
TRAEFIK_PORT=$TRAEFIK_PORT
CF_API_EMAIL=$CF_EMAIL
CF_API_KEY=$CF_API_KEY
TRAEFIK_DASHBOARD_AUTH="$TRAEFIK_AUTH"
EOL
    echo -e "${GREEN}${CHECK_MARK} Created traefik.env file${NC}"
}

# Function to update configuration files with environment variables
update_config_files() {
    local config_file="$SCRIPT_DIR/data/config.yml"
    local traefik_file="$SCRIPT_DIR/data/traefik.yml"

    echo -e "${BLUE}${GEAR} Updating configuration files with environment variables...${NC}"

    # Escape special characters in variables
    local domain_escaped=$(printf '%s\n' "$DOMAIN_NAME" | sed 's/[[\.*^$/]/\\&/g')
    local email_escaped=$(printf '%s\n' "$CF_EMAIL" | sed 's/[[\.*^$/]/\\&/g')

    # Create backup of files if they exist
    for file in "$config_file" "$traefik_file"; do
        if [ -f "$file" ]; then
            cp "$file" "${file}.backup"
            echo -e "${BLUE}${INFO} Created backup of $(basename "$file")${NC}"
        else
            echo -e "${RED}${CROSS_MARK} Warning: $(basename "$file") not found${NC}"
            return 1
        fi
    done

    # Update config.yml
    if [ -f "$config_file" ]; then
        sed -i "s/\${DOMAIN_NAME}/$domain_escaped/g" "$config_file"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}${CHECK_MARK} Updated domain in config.yml${NC}"
        else
            echo -e "${RED}${CROSS_MARK} Error updating config.yml${NC}"
            mv "${config_file}.backup" "$config_file"
            return 1
        fi
    fi

    # Update traefik.yml
    if [ -f "$traefik_file" ]; then
        sed -i "s/\${DOMAIN_NAME}/$domain_escaped/g" "$traefik_file"
        sed -i "s/\${CF_API_EMAIL}/$email_escaped/g" "$traefik_file"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}${CHECK_MARK} Updated variables in traefik.yml${NC}"
        else
            echo -e "${RED}${CROSS_MARK} Error updating traefik.yml${NC}"
            mv "${traefik_file}.backup" "$traefik_file"
            return 1
        fi
    fi

    # Remove backup files if everything succeeded
    rm -f "${config_file}.backup" "${traefik_file}.backup"
}

# Function to configure Traefik
configure_traefik() {
    echo -e "\n${BLUE}${GEAR} Starting Traefik configuration...${NC}"

    # Get configuration from user
    if ! get_traefik_config; then
        echo -e "${RED}${CROSS_MARK} Failed to get Traefik configuration${NC}"
        return 1
    fi
    
    # Source the environment variables
    if [ -f "$SCRIPT_DIR/traefik.env" ]; then
        source "$SCRIPT_DIR/traefik.env"
    else
        echo -e "${RED}${CROSS_MARK} Error: traefik.env file not found${NC}"
        return 1
    fi
    
    # Verify required environment variables
    local required_vars=(DOMAIN_NAME CF_EMAIL CF_API_KEY TRAEFIK_PORT TRAEFIK_DASHBOARD_AUTH)
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo -e "${RED}${CROSS_MARK} Error: $var is not set${NC}"
            return 1
        fi
    done

    # Create data directory if it doesn't exist
    if ! mkdir -p "$SCRIPT_DIR/data"; then
        echo -e "${RED}${CROSS_MARK} Error: Failed to create data directory${NC}"
        return 1
    fi

    # Create and set permissions for acme.json
    if [ ! -f "$SCRIPT_DIR/data/acme.json" ]; then
        if ! touch "$SCRIPT_DIR/data/acme.json" || ! chmod 600 "$SCRIPT_DIR/data/acme.json"; then
            echo -e "${RED}${CROSS_MARK} Error: Failed to create or set permissions for acme.json${NC}"
            return 1
        fi
        echo -e "${GREEN}${CHECK_MARK} Created acme.json with correct permissions${NC}"
    fi

    # Update configuration files with environment variables
    if ! update_config_files; then
        echo -e "${RED}${CROSS_MARK} Failed to update configuration files${NC}"
        return 1
    fi

    echo -e "${GREEN}${CHECK_MARK} Traefik configuration completed successfully${NC}"
    return 0

    # Rest of the configuration...
    # ...
}

# Run configuration
configure_traefik
