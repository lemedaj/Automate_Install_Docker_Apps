#!/bin/bash

# Get script directory as base directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASE_DIR="$SCRIPT_DIR"

# Directories
ODOO_DIR="$BASE_DIR/odoo"
DOLIBARR_DIR="$BASE_DIR/dolibarr"
NGINX_DIR="$BASE_DIR/nginx"
NGINX_PROXY_DIR="$BASE_DIR/nginx-proxy-manager"
PORTAINER_DIR="$BASE_DIR/portainer"
CLOUDFLARE_DIR="$BASE_DIR/cloudflare"
TRAEFIK_DIR="$BASE_DIR/traefik"

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to detect the Linux distribution
detect_linux_distribution() {
  echo "Select your Linux distribution:"
  echo "1) Ubuntu"
  echo "2) Debian"
  echo "3) CentOS"
  echo "4) RHEL"
  echo "5) Fedora"
  echo "6) Arch Linux"
  echo "7) Auto-detect"
  read -r choice

  case $choice in
    1) DISTRO="ubuntu" ;;
    2) DISTRO="debian" ;;
    3) DISTRO="centos" ;;
    4) DISTRO="rhel" ;;
    5) DISTRO="fedora" ;;
    6) DISTRO="arch" ;;
    7) # Auto-detect
      if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
      elif command_exists lsb_release; then
        DISTRO=$(lsb_release -i | awk '{print tolower($3)}')
        DISTRO_VERSION=$(lsb_release -r | awk '{print $2}')
      elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        DISTRO_VERSION=$(cat /etc/debian_version)
      elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
        DISTRO_VERSION=$(sed 's/[^0-9.]*//g' /etc/redhat-release)
      else
        DISTRO="unknown"
      fi
      ;;
    *) 
      echo "Invalid choice. Using auto-detect..."
      detect_linux_distribution
      ;;
  esac

  # Log the selection
  echo "$(date): Selected distribution: $DISTRO" >> "$BASE_DIR/install_log.txt"
}

# Function to install Docker and Docker Compose based on the detected distribution
install_docker() {
  if ! command_exists docker; then
    if [[ $DISTRO == "ubuntu" || $DISTRO == "debian" ]]; then
      echo "Installing Docker for Ubuntu/Debian..."
      sudo apt-get update
      sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      sudo apt-get update
      sudo apt-get install -y docker-ce
    elif [[ $DISTRO == "centos" || $DISTRO == "rhel" ]]; then
      echo "Installing Docker for CentOS/RHEL..."
      sudo yum install -y yum-utils
      sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
      sudo yum install -y docker-ce
      sudo systemctl start docker
      sudo systemctl enable docker
    elif [[ $DISTRO == "fedora" ]]; then
      echo "Installing Docker for Fedora..."
      sudo dnf -y install dnf-plugins-core
      sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
      sudo dnf install -y docker-ce docker-ce-cli containerd.io
      sudo systemctl start docker
      sudo systemctl enable docker
    elif [[ $DISTRO == "arch" ]]; then
      echo "Installing Docker for Arch Linux..."
      sudo pacman -Syu --noconfirm docker
      sudo systemctl start docker
      sudo systemctl enable docker
    else
      echo "Unsupported distribution."
      exit 1
    fi
  else
    echo "Docker is already installed."
  fi
}

# Install Docker Compose if not installed
install_docker_compose() {
  if ! command_exists docker-compose; then
    echo "Docker Compose is not installed. Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION="latest"
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  else
    echo "Docker Compose is already installed."
  fi
}

# Install Portainer
install_portainer() {
  if ! docker container inspect portainer >/dev/null 2>&1; then
    echo "Installing Portainer..."
    echo "$(date): Installing Portainer..." >> "$BASE_DIR/install_log.txt"
    docker-compose -f $PORTAINER_DIR/docker-compose-portainer.yml up -d
    echo "$(date): Portainer installation completed" >> "$BASE_DIR/install_log.txt"
  else
    echo "Portainer is already running."
    echo "$(date): Portainer is already running" >> "$BASE_DIR/install_log.txt"
  fi
}

# Install Nginx
install_nginx() {
  if ! docker container inspect nginx >/dev/null 2>&1; then
    echo "Installing Nginx..."
    echo "$(date): Installing Nginx..." >> "$BASE_DIR/install_log.txt"
    docker-compose -f $NGINX_DIR/docker-compose-nginx.yml up -d
    echo "$(date): Nginx installation completed" >> "$BASE_DIR/install_log.txt"
  else
    echo "Nginx is already running."
    echo "$(date): Nginx is already running" >> "$BASE_DIR/install_log.txt"
  fi
}

# Install Nginx Proxy Manager
install_nginx_proxy_manager() {
  if ! docker container inspect nginx-proxy-manager >/dev/null 2>&1; then
    echo "Installing Nginx Proxy Manager..."
    echo "$(date): Installing Nginx Proxy Manager..." >> "$BASE_DIR/install_log.txt"
    docker-compose -f $NGINX_PROXY_DIR/docker-compose-nginx-proxy.yml up -d
    echo "$(date): Nginx Proxy Manager installation completed" >> "$BASE_DIR/install_log.txt"
  else
    echo "Nginx Proxy Manager is already running."
    echo "$(date): Nginx Proxy Manager is already running" >> "$BASE_DIR/install_log.txt"
  fi
}

# Source Odoo configuration function
source "$ODOO_DIR/odoo_config.sh"

# Install Odoo
install_odoo() {
  if ! docker container inspect odoo >/dev/null 2>&1; then
    echo "Setting up Odoo configuration..."
    echo "$(date): Setting up Odoo configuration..." >> "$BASE_DIR/install_log.txt"
    get_odoo_config "$ODOO_DIR"
    echo "Installing Odoo..."
    docker-compose -f $ODOO_DIR/docker-compose-odoo.yml up -d
    echo "$(date): Odoo installation completed" >> "$BASE_DIR/install_log.txt"
  else
    echo "Odoo is already running."
    echo "$(date): Odoo is already running" >> "$BASE_DIR/install_log.txt"
  fi
}

# Install Dolibarr
install_dolibarr() {
  if ! docker container inspect dolibarr >/dev/null 2>&1; then
    echo "Installing Dolibarr..."
    echo "$(date): Installing Dolibarr..." >> "$BASE_DIR/install_log.txt"
    docker-compose -f $DOLIBARR_DIR/docker-compose-dolibarr.yml up -d
    echo "$(date): Dolibarr installation completed" >> "$BASE_DIR/install_log.txt"
  else
    echo "Dolibarr is already running."
    echo "$(date): Dolibarr is already running" >> "$BASE_DIR/install_log.txt"
  fi
}

# Install Cloudflare Tunnel
install_cloudflare() {
  if ! docker container inspect cloudflared >/dev/null 2>&1; then
    echo "Installing Cloudflare Tunnel..."
    echo "$(date): Installing Cloudflare Tunnel..." >> "$BASE_DIR/install_log.txt"
    docker-compose -f $CLOUDFLARE_DIR/docker-compose-cloudflare.yml up -d
    echo "$(date): Cloudflare Tunnel installation completed" >> "$BASE_DIR/install_log.txt"
  else
    echo "Cloudflare is already running."
    echo "$(date): Cloudflare is already running" >> "$BASE_DIR/install_log.txt"
  fi
}

# Install Traefik
install_traefik() {
  if ! docker container inspect traefik >/dev/null 2>&1; then
    echo "Installing Traefik..."
    echo "$(date): Installing Traefik..." >> "$BASE_DIR/install_log.txt"
    docker-compose -f $TRAEFIK_DIR/docker-compose-traefik.yml up -d
    echo "$(date): Traefik installation completed" >> "$BASE_DIR/install_log.txt"
  else
    echo "Traefik is already running."
    echo "$(date): Traefik is already running" >> "$BASE_DIR/install_log.txt"
  fi
}

# Function to get network configuration
get_network_config() {
  echo "Please enter the network name to use across all services (default: proxy):"
  read -r NETWORK_NAME
  NETWORK_NAME=${NETWORK_NAME:-proxy}
  echo "$(date): Network name set to: $NETWORK_NAME" >> "$BASE_DIR/install_log.txt"
  export NETWORK_NAME
}

# Create Docker network with user-provided name
create_docker_network() {
  if ! docker network ls | grep -q "$NETWORK_NAME"; then
    echo "Creating Docker network: $NETWORK_NAME..."
    echo "$(date): Creating Docker network: $NETWORK_NAME" >> "$BASE_DIR/install_log.txt"
    docker network create "$NETWORK_NAME"
    echo "$(date): Docker network created: $NETWORK_NAME" >> "$BASE_DIR/install_log.txt"
  else
    echo "Network $NETWORK_NAME already exists."
    echo "$(date): Network $NETWORK_NAME already exists" >> "$BASE_DIR/install_log.txt"
  fi
}

# Function to check required repositories and guide user for cloning
setup_service_directories() {
  echo "$(date): Checking required repositories..." >> "$BASE_DIR/install_log.txt"
  
  local missing_repos=()
  
  # Check if required directories exist
  [[ ! -d "$TRAEFIK_DIR" ]] && missing_repos+=("traefik")
  [[ ! -d "$NGINX_DIR" ]] && missing_repos+=("nginx")
  [[ ! -d "$PORTAINER_DIR" ]] && missing_repos+=("portainer")
  [[ ! -d "$NGINX_PROXY_DIR" ]] && missing_repos+=("nginx-proxy-manager")
  [[ ! -d "$ODOO_DIR" ]] && missing_repos+=("odoo")
  [[ ! -d "$DOLIBARR_DIR" ]] && missing_repos+=("dolibarr")
  [[ ! -d "$CLOUDFLARE_DIR" ]] && missing_repos+=("cloudflare")

  if [ ${#missing_repos[@]} -gt 0 ]; then
    echo "The following repositories are missing and need to be cloned:"
    echo "$(date): Missing repositories detected:" >> "$BASE_DIR/install_log.txt"
    
    for repo in "${missing_repos[@]}"; do
      echo "- $repo"
      echo "$(date): Missing: $repo" >> "$BASE_DIR/install_log.txt"
    done
    
    echo -e "\nPlease clone the missing repositories from GitHub:"
    echo "1. Visit: https://github.com/YOUR_USERNAME/docker-apps-repo"
    echo "2. Clone the repository:"
    echo "   git clone https://github.com/YOUR_USERNAME/docker-apps-repo.git"
    echo "3. Make sure the following directory structure exists:"
    echo "   - traefik/"
    echo "   - nginx/"
    echo "   - portainer/"
    echo "   - nginx-proxy-manager/"
    echo "   - odoo/"
    echo "   - dolibarr/"
    echo "   - cloudflare/"
    
    echo "Would you like to continue without the missing repositories? (y/N):"
    read -r continue_setup
    
    if [[ ! "$continue_setup" =~ ^[Yy]$ ]]; then
      echo "$(date): Setup cancelled - missing repositories" >> "$BASE_DIR/install_log.txt"
      exit 1
    fi
  fi

  # Check and set permissions for existing directories
  if [ -d "$TRAEFIK_DIR/data" ]; then
    if [ -f "$TRAEFIK_DIR/data/acme.json" ]; then
      chmod 600 "$TRAEFIK_DIR/data/acme.json"
    fi
  fi
  
  # Make Odoo configuration script executable if it exists
  if [ -f "$ODOO_DIR/odoo_config.sh" ]; then
    chmod +x "$ODOO_DIR/odoo_config.sh"
  fi
  
  echo "$(date): Repository check completed" >> "$BASE_DIR/install_log.txt"
}

# Function to get domain name from user and Cloudflare email and API key
get_domain_name() {
  echo "$(date): Getting domain and Cloudflare configuration..." >> "$BASE_DIR/install_log.txt"
  
  echo "Please enter your domain name (e.g., example.com):"
  read -r DOMAIN_NAME
  echo "$(date): Domain name set to: $DOMAIN_NAME" >> "$BASE_DIR/install_log.txt"

  echo "Please enter your Cloudflare email:"
  read -r CF_EMAIL
  echo "$(date): Cloudflare email configured" >> "$BASE_DIR/install_log.txt"

  echo "Please enter your Cloudflare API key:"
  read -r CF_API_KEY
  echo "$(date): Cloudflare API key configured" >> "$BASE_DIR/install_log.txt"

  echo "Please enter Traefik dashboard port (default: 8080):"
  read -r TRAEFIK_PORT
  TRAEFIK_PORT=${TRAEFIK_PORT:-8080}
  echo "$(date): Traefik dashboard port set to: $TRAEFIK_PORT" >> "$BASE_DIR/install_log.txt"
  
  # Get Traefik dashboard credentials
  echo "Please enter username for Traefik dashboard (default: admin):"
  read -r TRAEFIK_USER
  TRAEFIK_USER=${TRAEFIK_USER:-admin}
  
  echo "Please enter password for Traefik dashboard (default: admin):"
  read -r TRAEFIK_PASSWORD
  TRAEFIK_PASSWORD=${TRAEFIK_PASSWORD:-admin}
  echo "$(date): Traefik dashboard credentials configured" >> "$BASE_DIR/install_log.txt"
  
  # Generate htpasswd for Traefik dashboard
  TRAEFIK_AUTH=$(docker run --rm httpd:2.4-alpine htpasswd -nbB "$TRAEFIK_USER" "$TRAEFIK_PASSWORD" | sed -e s/\\$/\\$\\$/g)
  
  # Update Traefik .env file with all settings
  cat > "$TRAEFIK_DIR/.env" << EOL
TRAEFIK_VERSION=latest
TRAEFIK_PORT=$TRAEFIK_PORT
DOMAIN_NAME=$DOMAIN_NAME
CF_API_EMAIL=$CF_EMAIL
CF_API_KEY=$CF_API_KEY
TRAEFIK_DASHBOARD_AUTH="$TRAEFIK_AUTH"  # Generated credentials
EOL

  echo "$(date): Created Traefik .env file" >> "$BASE_DIR/install_log.txt"
}

# Function to ask user which apps to install
ask_user() {
  echo "Which applications would you like to install?"
  echo "1) Traefik"
  echo "2) Nginx"
  echo "3) Portainer"
  echo "4) Nginx Proxy Manager"
  echo "5) Odoo"
  echo "6) Dolibarr"
  echo "7) Cloudflare Tunnel"
  echo "8) Install all applications"
  echo "Enter the number of the applications separated by spaces (e.g., 1 2 4) or enter 8 for all: "
  read -r APPS

  echo "$(date): User selected applications: $APPS" >> "$BASE_DIR/install_log.txt"

  # If the user selects 8, install all applications
  if [[ " $APPS " == *"8"* ]]; then
    APPS="1 2 3 4 5 6 7"
    echo "$(date): Installing all applications" >> "$BASE_DIR/install_log.txt"
  fi

  for APP in $APPS; do
    case $APP in
      1) 
        echo "$(date): Starting Traefik installation" >> "$BASE_DIR/install_log.txt"
        install_traefik 
        ;;
      2) 
        echo "$(date): Starting Nginx installation" >> "$BASE_DIR/install_log.txt"
        install_nginx 
        ;;
      3) 
        echo "$(date): Starting Portainer installation" >> "$BASE_DIR/install_log.txt"
        install_portainer 
        ;;
      4) 
        echo "$(date): Starting Nginx Proxy Manager installation" >> "$BASE_DIR/install_log.txt"
        install_nginx_proxy_manager 
        ;;
      5)
        echo "$(date): Starting Odoo configuration" >> "$BASE_DIR/install_log.txt" 
        get_odoo_config
        echo "$(date): Starting Odoo installation" >> "$BASE_DIR/install_log.txt"
        install_odoo 
        ;;
      6) 
        echo "$(date): Starting Dolibarr installation" >> "$BASE_DIR/install_log.txt"
        install_dolibarr 
        ;;
      7) 
        echo "$(date): Starting Cloudflare Tunnel installation" >> "$BASE_DIR/install_log.txt"
        install_cloudflare 
        ;;
      *) 
        echo "Invalid option: $APP"
        echo "$(date): Invalid option selected: $APP" >> "$BASE_DIR/install_log.txt"
        ;;
    esac
  done
}



# Function to read the environment variable values
load_env_vars() {
  # Export network name for all services
  export NETWORK_NAME=${NETWORK_NAME:-proxy}

  # Load all service environment files
  set -o allexport
  source $ODOO_DIR/.env
  source $DOLIBARR_DIR/.env
  source $NGINX_DIR/.env
  source $PORTAINER_DIR/.env
  source $NGINX_PROXY_DIR/.env
  source $CLOUDFLARE_DIR/.env
  source $TRAEFIK_DIR/.env
  set +o allexport

  # Update network name in .env files if they exist
  for env_file in "$ODOO_DIR/.env" "$DOLIBARR_DIR/.env" "$NGINX_DIR/.env" \
                  "$PORTAINER_DIR/.env" "$NGINX_PROXY_DIR/.env" \
                  "$CLOUDFLARE_DIR/.env" "$TRAEFIK_DIR/.env"; do
    if [ -f "$env_file" ]; then
      # Add or update NETWORK_NAME in .env files
      if grep -q "^NETWORK_NAME=" "$env_file"; then
        sed -i "s/^NETWORK_NAME=.*/NETWORK_NAME=$NETWORK_NAME/" "$env_file"
      else
        echo "NETWORK_NAME=$NETWORK_NAME" >> "$env_file"
      fi
    fi
  done
}

# Function to display URLs and ports for installed apps
display_urls() {
  echo "Installed applications and their URLs:"
  
  for APP in $APPS; do
    case $APP in
      1) echo "Traefik Dashboard: https://traefik.${DOMAIN_NAME}" ;;
      2) echo "Nginx: https://nginx.${DOMAIN_NAME}" ;;
      3) echo "Portainer: https://portainer.${DOMAIN_NAME}" ;;
      4) echo "Nginx Proxy Manager: https://npm.${DOMAIN_NAME}" ;;
      5) echo "Odoo: https://odoo.${DOMAIN_NAME}" ;;
      6) echo "Dolibarr: https://dolibarr.${DOMAIN_NAME}" ;;
      7) echo "Cloudflare Tunnel: https://tunnel.${DOMAIN_NAME}" ;;
    esac
  done
}

# Function to check and install Docker
check_docker_installation() {
  if command_exists docker; then
    DOCKER_VERSION=$(docker --version)
    echo "Docker is already installed: $DOCKER_VERSION"
    echo "$(date): $DOCKER_VERSION" >> "$BASE_DIR/install_log.txt"
    
    echo "Would you like to reinstall Docker? (y/N):"
    read -r reinstall
    if [[ "$reinstall" =~ ^[Yy]$ ]]; then
      install_docker
    fi
  else
    echo "Docker is not installed."
    echo "Would you like to install Docker? (Y/n):"
    read -r install
    if [[ ! "$install" =~ ^[Nn]$ ]]; then
      install_docker
    else
      echo "Docker installation skipped."
      echo "$(date): Docker installation skipped by user" >> "$BASE_DIR/install_log.txt"
      exit 1
    fi
  fi
}

# Function to check and install Docker Compose
check_docker_compose() {
  if command_exists docker-compose; then
    COMPOSE_VERSION=$(docker-compose --version)
    echo "Docker Compose is already installed: $COMPOSE_VERSION"
    echo "$(date): $COMPOSE_VERSION" >> "$BASE_DIR/install_log.txt"
    
    echo "Would you like to reinstall Docker Compose? (y/N):"
    read -r reinstall
    if [[ "$reinstall" =~ ^[Yy]$ ]]; then
      install_docker_compose
    fi
  else
    echo "Docker Compose is not installed."
    echo "Would you like to install Docker Compose? (Y/n):"
    read -r install
    if [[ ! "$install" =~ ^[Nn]$ ]]; then
      install_docker_compose
    else
      echo "Docker Compose installation skipped."
      echo "$(date): Docker Compose installation skipped by user" >> "$BASE_DIR/install_log.txt"
      exit 1
    fi
  fi
}

# Main function
main() {
  # Create log file
  touch "$BASE_DIR/install_log.txt"
  echo "$(date): Starting installation" >> "$BASE_DIR/install_log.txt"

  # Detect Linux distribution
  detect_linux_distribution
  echo "Selected Linux distribution: $DISTRO"

  # Check and install Docker if needed
  check_docker_installation

  # Check and install Docker Compose if needed
  check_docker_compose

  # Get network configuration from user
  get_network_config

  # Create Docker network
  create_docker_network

  # Setup service directories and configurations
  setup_service_directories

  # Get domain name and Cloudflare credentials from user
  get_domain_name

  # Load environment variables
  load_env_vars

  # Install Traefik first as it's needed for routing
  install_traefik

  # Ask user which apps to install
  ask_user

  # Display the URLs with subdomains
  display_urls
}

# Run the main function
main