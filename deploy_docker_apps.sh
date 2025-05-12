#!/bin/bash

# Get current directory as base directory
BASE_DIR=$(pwd)

# Directories
ODOO_DIR="$BASE_DIR/odoo"
DOLIBARR_DIR="$BASE_DIR/dolibarr"
NGINX_DIR="$BASE_DIR/nginx"
NGINX_PROXY_DIR="$BASE_DIR/nginx-proxy-manager"
PORTAINER_DIR="$BASE_DIR/portainer"
CLOUDFLARE_DIR="$BASE_DIR/cloudflare"
TRAEFIK_DIR="$BASE_DIR/traefik"
DOCKER_APPS_DIR="/mnt/docker-apps"

REPO_URL="https://github.com/your-repo/docker-apps.git"  # Replace with your repository URL

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to detect the Linux distribution
detect_linux_distribution() {
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
    docker-compose -f $PORTAINER_DIR/docker-compose-portainer.yml up -d
  else
    echo "Portainer is already running."
  fi
}

# Install Nginx
install_nginx() {
  if ! docker container inspect nginx >/dev/null 2>&1; then
    echo "Installing Nginx..."
    docker-compose -f $NGINX_DIR/docker-compose-nginx.yml up -d
  else
    echo "Nginx is already running."
  fi
}

# Install Nginx Proxy Manager
install_nginx_proxy_manager() {
  if ! docker container inspect nginx-proxy-manager >/dev/null 2>&1; then
    echo "Installing Nginx Proxy Manager..."
    docker-compose -f $NGINX_PROXY_DIR/docker-compose-nginx-proxy.yml up -d
  else
    echo "Nginx Proxy Manager is already running."
  fi
}

# Install Odoo
install_odoo() {
  if ! docker container inspect odoo >/dev/null 2>&1; then
    echo "Installing Odoo..."
    docker-compose -f $ODOO_DIR/docker-compose-odoo.yml up -d
  else
    echo "Odoo is already running."
  fi
}

# Install Dolibarr
install_dolibarr() {
  if ! docker container inspect dolibarr >/dev/null 2>&1; then
    echo "Installing Dolibarr..."
    docker-compose -f $DOLIBARR_DIR/docker-compose-dolibarr.yml up -d
  else
    echo "Dolibarr is already running."
  fi
}

# Install Cloudflare Tunnel
install_cloudflare() {
  if ! docker container inspect cloudflared >/dev/null 2>&1; then
    echo "Installing Cloudflare Tunnel..."
    docker-compose -f $CLOUDFLARE_DIR/docker-compose-cloudflare.yml up -d
  else
    echo "Cloudflare is already running."
  fi
}

# Install Traefik
install_traefik() {
  if ! docker container inspect traefik >/dev/null 2>&1; then
    echo "Installing Traefik..."
    docker-compose -f $TRAEFIK_DIR/docker-compose.yml up -d
  else
    echo "Traefik is already running."
  fi
}

# Create Traefik network
create_traefik_network() {
  if ! docker network ls | grep -q traefik_proxy; then
    echo "Creating Traefik network..."
    docker network create traefik_proxy
  else
    echo "Traefik network already exists."
  fi
}

# Function to create service directories and configurations
setup_service_directories() {
  # Create directories if they don't exist
  mkdir -p "$TRAEFIK_DIR/data"
  mkdir -p "$NGINX_DIR"
  mkdir -p "$PORTAINER_DIR"
  mkdir -p "$NGINX_PROXY_DIR"
  mkdir -p "$ODOO_DIR/custom-addons"
  mkdir -p "$DOLIBARR_DIR"
  mkdir -p "$CLOUDFLARE_DIR"

  # Create necessary files with proper permissions
  touch "$TRAEFIK_DIR/data/acme.json"
  chmod 600 "$TRAEFIK_DIR/data/acme.json"

  # Create .env files for each service if they don't exist
  if [ ! -f "$TRAEFIK_DIR/.env" ]; then
    echo "Creating Traefik .env file..."
    cat > "$TRAEFIK_DIR/.env" << EOL
TRAEFIK_PORT=8080
DOMAIN_NAME=example.com
CF_API_EMAIL=your-email@example.com
CF_DNS_API_TOKEN=your-cloudflare-api-token
EOL
  fi

  if [ ! -f "$NGINX_DIR/.env" ]; then
    echo "Creating Nginx .env file..."
    cat > "$NGINX_DIR/.env" << EOL
NGINX_PORT=80
DOMAIN_NAME=example.com
NETWORK_NAME=business-network
EOL
  fi

  if [ ! -f "$PORTAINER_DIR/.env" ]; then
    echo "Creating Portainer .env file..."
    cat > "$PORTAINER_DIR/.env" << EOL
PORTAINER_PORT=9000
DOMAIN_NAME=example.com
NETWORK_NAME=business-network
EOL
  fi

  if [ ! -f "$NGINX_PROXY_DIR/.env" ]; then
    echo "Creating Nginx Proxy Manager .env file..."
    cat > "$NGINX_PROXY_DIR/.env" << EOL
NPM_PORT=81
DOMAIN_NAME=example.com
NETWORK_NAME=business-network
EOL
  fi

  if [ ! -f "$ODOO_DIR/.env" ]; then
    echo "Creating Odoo .env file..."
    cat > "$ODOO_DIR/.env" << EOL
ODOO_VERSION=17.0
ODOO_PORT=8069
ODOO_DB_HOST=db
ODOO_DB_USER=odoo
ODOO_DB_PASSWORD=odoo_password
POSTGRES_VERSION=16
POSTGRES_DB=postgres
DOMAIN_NAME=example.com
NETWORK_NAME=business-network
EOL
  fi

  if [ ! -f "$DOLIBARR_DIR/.env" ]; then
    echo "Creating Dolibarr .env file..."
    cat > "$DOLIBARR_DIR/.env" << EOL
DOLIBARR_VERSION=17
DOLIBARR_PORT=8080
DOLIBARR_DB_HOST=db
DOLIBARR_DB_NAME=dolibarr
DOLIBARR_DB_USER=dolibarr
DOLIBARR_DB_PASSWORD=dolibarr_password
MYSQL_VERSION=8.0
DOMAIN_NAME=example.com
NETWORK_NAME=business-network
EOL
  fi

  if [ ! -f "$CLOUDFLARE_DIR/.env" ]; then
    echo "Creating Cloudflare .env file..."
    cat > "$CLOUDFLARE_DIR/.env" << EOL
TUNNEL_TOKEN=your-cloudflare-tunnel-token
DOMAIN_NAME=example.com
NETWORK_NAME=business-network
EOL
  fi
}

# Function to get domain name from user and Cloudflare email and API key
get_domain_name() {
  echo "Please enter your domain name (e.g., example.com):"
  read -r DOMAIN_NAME
  echo "Please enter your Cloudflare email:"
  read -r CF_EMAIL
  echo "Please enter your Cloudflare API key:"
  read -r CF_API_KEY
  
  # Update Traefik .env file with credentials
  sed -i "s/DOMAIN_NAME=.*/DOMAIN_NAME=$DOMAIN_NAME/" "$TRAEFIK_DIR/.env"
  sed -i "s/CF_API_EMAIL=.*/CF_API_EMAIL=$CF_EMAIL/" "$TRAEFIK_DIR/.env"
  sed -i "s/CF_API_KEY=.*/CF_API_KEY=$CF_API_KEY/" "$TRAEFIK_DIR/.env"
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

# If the user selects 8, install all applications
  if [[ " $APPS " == *"8"* ]]; then
    APPS="1 2 3 4 5 6 7"
  fi

  for APP in $APPS; do
    case $APP in
      1) install_traefik ;;
      2) install_nginx ;;
      3) install_portainer ;;
      4) install_nginx_proxy_manager ;;
      5) install_odoo ;;
      6) install_dolibarr ;;
      7) install_cloudflare ;;
      *) echo "Invalid option: $APP" ;;
    esac
  done
}

# Function to clone or update repo
clone_or_update_repo() {
  if [ ! -d "$DOCKER_APPS_DIR" ]; then
    echo "Cloning repository..."
    git clone "$REPO_URL" "$DOCKER_APPS_DIR"
  else
    echo "Updating repository..."
    cd "$DOCKER_APPS_DIR" && git pull
  fi
}

# Create the Docker Apps directory if it doesn't exist
create_docker_apps_dir() {
  if [ ! -d "$DOCKER_APPS_DIR" ]; then
    echo "Creating $DOCKER_APPS_DIR directory..."
    mkdir -p "$DOCKER_APPS_DIR"
  else
    echo "$DOCKER_APPS_DIR already exists"
  fi
}

# Function to read the environment variable values
load_env_vars() {
  set -o allexport
  source $ODOO_DIR/.env
  source $DOLIBARR_DIR/.env
  source $NGINX_DIR/.env
  source $PORTAINER_DIR/.env
  source $NGINX_PROXY_DIR/.env
  source $CLOUDFLARE_DIR/.env
  source $TRAEFIK_DIR/.env
  set +o allexport
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

# Main function
main() {
  # Automatically detect the Linux distribution
  detect_linux_distribution
  echo "Detected Linux distribution: $DISTRO"

  # Install Docker and Docker Compose first
  install_docker
  install_docker_compose

  # Create Docker Apps directory
  create_docker_apps_dir

  # Create Traefik network
  create_traefik_network

  # Setup service directories and configurations
  setup_service_directories

  # Get domain name and Cloudflare credentials from user
  get_domain_name

  # Clone or update repo
  clone_or_update_repo

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