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
WRENCH="🔧"
SERVER="🖥"
GLOBE="🌐"
SETTINGS="⚡"
DOCKER="🐳"

# OS Icons
UBUNTU_ICON="🐧"
DEBIAN_ICON="🐧"
CENTOS_ICON="🖥️"
RHEL_ICON="🎩"
FEDORA_ICON="🎯"
ARCH_ICON="🏹"

# Log file location
LOG_FILE="$BASE_DIR/installation_log.txt"

# Function to log messages
log_message() {
    local message=$1
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "$timestamp: $message" >> "$LOG_FILE"
}

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
  echo -e "\n${BLUE}${SETTINGS} Select your Linux distribution:${NC}"
  echo -e "1) ${UBUNTU_ICON} Ubuntu"
  echo -e "2) ${DEBIAN_ICON} Debian"
  echo -e "3) ${CENTOS_ICON} CentOS"
  echo -e "4) ${RHEL_ICON} RHEL"
  echo -e "5) ${FEDORA_ICON} Fedora"
  echo -e "6) ${ARCH_ICON} Arch Linux"
  echo -e "7) ${GEAR} Auto-detect"
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
      echo -e "${BLUE}${DOCKER} Installing Docker for Ubuntu/Debian...${NC}"
      sudo apt-get update
      sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      sudo apt-get update
      sudo apt-get install -y docker-ce
    elif [[ $DISTRO == "centos" || $DISTRO == "rhel" ]]; then
      echo -e "${BLUE}${DOCKER} Installing Docker for CentOS/RHEL...${NC}"
      sudo yum install -y yum-utils
      sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
      sudo yum install -y docker-ce
      sudo systemctl start docker
      sudo systemctl enable docker
    elif [[ $DISTRO == "fedora" ]]; then
      echo -e "${BLUE}${DOCKER} Installing Docker for Fedora...${NC}"
      sudo dnf -y install dnf-plugins-core
      sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
      sudo dnf install -y docker-ce docker-ce-cli containerd.io
      sudo systemctl start docker
      sudo systemctl enable docker
    elif [[ $DISTRO == "arch" ]]; then
      echo -e "${BLUE}${DOCKER} Installing Docker for Arch Linux...${NC}"
      sudo pacman -Syu --noconfirm docker
      sudo systemctl start docker
      sudo systemctl enable docker
    else
      echo -e "${RED}${CROSS_MARK} Unsupported distribution.${NC}"
      exit 1
    fi
    
    # Check if installation was successful
    if command_exists docker; then
      DOCKER_VERSION=$(docker --version)
      echo -e "\n${GREEN}${CHECK_MARK} Docker installation completed successfully${NC}"
      echo -e "${BLUE}${DOCKER} Version: ${GREEN}${DOCKER_VERSION}${NC}"
      echo "$(date): Successfully installed Docker - $DOCKER_VERSION" >> "$BASE_DIR/install_log.txt"
    else
      echo -e "${RED}${CROSS_MARK} Docker installation failed${NC}"
      echo "$(date): Docker installation failed" >> "$BASE_DIR/install_log.txt"
      exit 1
    fi
  else
    DOCKER_VERSION=$(docker --version)
    echo -e "${YELLOW}${INFO} Docker is already installed: ${GREEN}${DOCKER_VERSION}${NC}"
  fi
}

# Install Docker Compose if not installed
install_docker_compose() {
  if ! command_exists docker-compose; then
    echo -e "${BLUE}${DOCKER} Installing Docker Compose...${NC}"
    
    # Linux/Unix installation
    COMPOSE_LATEST=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_LATEST}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Check if installation was successful
    if command_exists docker-compose || docker compose version &>/dev/null; then
      COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || docker compose version)
      echo -e "\n${GREEN}${CHECK_MARK} Docker Compose installation completed successfully${NC}"
      echo -e "${BLUE}${DOCKER} Version: ${GREEN}${COMPOSE_VERSION}${NC}"
      echo "$(date): Successfully installed Docker Compose - $COMPOSE_VERSION" >> "$BASE_DIR/install_log.txt"
    else
      echo -e "${RED}${CROSS_MARK} Docker Compose installation failed${NC}"
      echo -e "${YELLOW}${INFO} Please ensure Docker Desktop is installed with Docker Compose${NC}"
      echo "$(date): Docker Compose installation failed" >> "$BASE_DIR/install_log.txt"
      exit 1
    fi
  else
    COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || docker compose version)
    echo -e "${YELLOW}${INFO} Docker Compose is already installed: ${GREEN}${COMPOSE_VERSION}${NC}"
  fi
}

# Install Portainer
install_portainer() {
  echo -e "\n${BLUE}${GEAR} Setting up Portainer...${NC}"
  
  if ! docker container inspect portainer >/dev/null 2>&1; then
    echo -e "${BLUE}${ROCKET} Starting Portainer container...${NC}"
    echo "$(date): Installing Portainer..." >> "$BASE_DIR/install_log.txt"
    docker-compose -f $PORTAINER_DIR/docker-compose-portainer.yml up -d
    echo -e "${GREEN}${CHECK_MARK} Portainer installation completed${NC}"
    echo "$(date): Portainer installation completed" >> "$BASE_DIR/install_log.txt"
  else
    echo -e "${YELLOW}${INFO} Portainer is already running${NC}"
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

# Configure and install Traefik
install_traefik() {
  echo -e "${BLUE}${GEAR} Setting up Traefik...${NC}"
  
  # Check if Traefik is already running
  if docker container inspect traefik >/dev/null 2>&1; then
    echo -e "${YELLOW}${INFO} Traefik is already running${NC}"
    echo "$(date): Traefik is already running" >> "$BASE_DIR/install_log.txt"
    return 0
  fi
  
  # Run Traefik configuration script which will also start the container
  if [ -f "$TRAEFIK_DIR/traefik_config.sh" ]; then
    chmod +x "$TRAEFIK_DIR/traefik_config.sh"
    if bash "$TRAEFIK_DIR/traefik_config.sh"; then
      echo -e "${GREEN}${CHECK_MARK} Traefik configuration completed${NC}"
      echo "$(date): Traefik configuration completed" >> "$BASE_DIR/install_log.txt"
      return 0
    else
      echo -e "${RED}${CROSS_MARK} Traefik configuration failed${NC}"
      echo "$(date): Traefik configuration failed" >> "$BASE_DIR/install_log.txt"
      return 1
    fi
  else
    echo -e "${RED}${CROSS_MARK} Error: traefik_config.sh not found${NC}"
    return 1
  fi
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
    echo -e "${BLUE}${DOCKER} Docker is already installed: ${GREEN}$DOCKER_VERSION${NC}"
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
    COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || docker compose version)
    echo -e "${BLUE}${DOCKER} Docker Compose is already installed: ${GREEN}$COMPOSE_VERSION${NC}"
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
  echo -e "\n${BLUE}${ROCKET} Starting Docker Apps Installation${NC}\n"

  # Phase 1: Environment Setup
  echo -e "${BLUE}${GEAR} Phase 1: Environment Setup${NC}"
  touch "$LOG_FILE"
  log_message "Starting Docker Apps Installation"

  # Linux Distribution Detection
  echo -e "\n${YELLOW}${INFO} Checking system requirements...${NC}"
  detect_linux_distribution
  echo -e "${GREEN}${CHECK_MARK} Selected Linux distribution: $DISTRO${NC}"

  # Phase 2: Docker Environment
  echo -e "\n${BLUE}${GEAR} Phase 2: Docker Environment${NC}"
  check_docker_installation
  check_docker_compose

  # Phase 3: Application Installation
  echo -e "\n${BLUE}${ROCKET} Phase 3: Application Installation${NC}"
  ask_user

  # Phase 4: Completion
  echo -e "\n${GREEN}${CHECK_MARK} Installation Complete!${NC}"

  echo -e "\n${GREEN}${ROCKET} All services have been deployed successfully!${NC}"
  echo -e "${YELLOW}${INFO} Check the logs at: $BASE_DIR/install_log.txt for details${NC}\n"
}

# Run the main function
main