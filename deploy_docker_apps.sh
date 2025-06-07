#!/bin/bash

# Dracula Theme Colors
PINK='\033[38;2;255;121;198m'        # Pink
PURPLE='\033[38;2;189;147;249m'      # Purple
BLUE='\033[38;2;139;233;253m'        # Cyan
GREEN='\033[38;2;80;250;123m'        # Green
YELLOW='\033[38;2;241;250;140m'      # Yellow
RED='\033[38;2;255;85;85m'          # Red
ORANGE='\033[38;2;255;184;108m'     # Orange
NC='\033[0m'                        # No Color

# Nord Font Icons - Will be populated after font check
declare -A ICONS
CHECK_MARK=""  # Will be set after font verification
CROSS_MARK=""
GEAR=""
INFO=""
ROCKET=""
WRENCH=""
SERVER=""
GLOBE=""
SETTINGS=""
DOCKER=""

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
    7) Auto-detect
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
    *)  echo "Invalid choice. Using auto-detect..."
      detect_linux_distribution
      ;;
  esac

  # Log the selection
  echo "$(date): Selected distribution: $DISTRO" >> "$BASE_DIR/install_log.txt"
}

# Function to install Docker and Docker Compose based on the detected distribution
install_docker() {
  if ! command_exists docker; then
    echo -e "${BLUE}${DOCKER} Installing Docker...${NC}"
    case $DISTRO in
        ubuntu|debian)
            (
                sudo apt-get update && \
                sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common && \
                curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo apt-key add - && \
                sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" && \
                sudo apt-get update && \
                sudo apt-get install -y docker-ce
            ) &
            spinner $! "Installing Docker for $DISTRO..."
            ;;
        centos|rhel)
            (
                sudo yum install -y yum-utils && \
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
                sudo yum install -y docker-ce && \
                sudo systemctl start docker && \
                sudo systemctl enable docker
            ) &
            spinner $! "Installing Docker for $DISTRO..."
            ;;
        fedora)
            (
                sudo dnf -y install dnf-plugins-core && \
                sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && \
                sudo dnf install -y docker-ce docker-ce-cli containerd.io && \
                sudo systemctl start docker && \
                sudo systemctl enable docker
            ) &
            spinner $! "Installing Docker for Fedora..."
            ;;
        arch)
            (
                sudo pacman -Syu --noconfirm docker && \
                sudo systemctl start docker && \
                sudo systemctl enable docker
            ) &
            spinner $! "Installing Docker for Arch Linux..."
            ;;
        *)
            echo -e "${RED}${CROSS_MARK} Unsupported distribution.${NC}"
            exit 1
            ;;
    esac
    
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version)
        echo -e "\n${GREEN}${CHECK_MARK} Docker installation completed successfully${NC}"
        echo -e "${BLUE}${DOCKER} Version: ${GREEN}${DOCKER_VERSION}${NC}"
        log_message "Successfully installed Docker - $DOCKER_VERSION"
        pause_phase 2 "Docker installation complete"
    else
        echo -e "${RED}${CROSS_MARK} Docker installation failed${NC}"
        log_message "Docker installation failed"
        exit 1
    fi
  else
    DOCKER_VERSION=$(docker --version)
    echo -e "${YELLOW}${INFO} Docker is already installed: ${GREEN}${DOCKER_VERSION}${NC}"
  fi
}

# Install Docker Compose with progress
install_docker_compose() {
  if ! command_exists docker-compose; then
    echo -e "${BLUE}${DOCKER} Installing Docker Compose...${NC}"
    (
        COMPOSE_LATEST=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
        sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_LATEST}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    ) &
    spinner $! "Installing Docker Compose..."
    
    if command_exists docker-compose || docker compose version &>/dev/null; then
      COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || docker compose version)
      echo -e "\n${GREEN}${CHECK_MARK} Docker Compose installation completed successfully${NC}"
      echo -e "${BLUE}${DOCKER} Version: ${GREEN}${COMPOSE_VERSION}${NC}"
      log_message "Successfully installed Docker Compose - $COMPOSE_VERSION"
      pause_phase 2 "Docker Compose installation complete"
    else
      echo -e "${RED}${CROSS_MARK} Docker Compose installation failed${NC}"
      echo -e "${YELLOW}${INFO} Please ensure Docker Desktop is installed with Docker Compose${NC}"
      log_message "Docker Compose installation failed"
      exit 1
    fi
  else
    COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || docker compose version)
    echo -e "${YELLOW}${INFO} Docker Compose is already installed: ${GREEN}${COMPOSE_VERSION}${NC}"
  fi
}

# Install Portainer with progress
install_portainer() {
    echo -e "\n${BLUE}${GEAR} Setting up Portainer...${NC}"
    
    if ! docker container inspect portainer >/dev/null 2>&1; then
        echo -e "${BLUE}${ROCKET} Starting Portainer container...${NC}"
        (docker-compose -f $PORTAINER_DIR/docker-compose-portainer.yml up -d) &
        spinner $! "Deploying Portainer container..."
        if [ $? -eq 0 ]; then
            echo -e "\n${GREEN}${CHECK_MARK} Portainer installation completed${NC}"
            log_message "Portainer installation completed"
        else
            echo -e "\n${RED}${CROSS_MARK} Portainer installation failed${NC}"
            log_message "Portainer installation failed"
            return 1
        fi
    else
        echo -e "${YELLOW}${INFO} Portainer is already running${NC}"
        log_message "Portainer is already running"
    fi
    pause_phase 2 "Portainer setup complete"
}

# Install Nginx with progress
install_nginx() {
    echo -e "\n${BLUE}${GEAR} Setting up Nginx...${NC}"
    if ! docker container inspect nginx >/dev/null 2>&1; then
        (docker-compose -f $NGINX_DIR/docker-compose-nginx.yml up -d) &
        spinner $! "Deploying Nginx container..."
        if [ $? -eq 0 ]; then
            echo -e "\n${GREEN}${CHECK_MARK} Nginx installation completed${NC}"
            log_message "Nginx installation completed"
            pause_phase 2 "Nginx setup complete"
        else
            echo -e "\n${RED}${CROSS_MARK} Nginx installation failed${NC}"
            log_message "Nginx installation failed"
            return 1
        fi
    else
        echo -e "${YELLOW}${INFO} Nginx is already running${NC}"
        log_message "Nginx is already running"
    fi
}

# Install Nginx Proxy Manager with progress
install_nginx_proxy_manager() {
    echo -e "\n${BLUE}${GEAR} Setting up Nginx Proxy Manager...${NC}"
    if ! docker container inspect nginx-proxy-manager >/dev/null 2>&1; then
        (docker-compose -f $NGINX_PROXY_DIR/docker-compose-nginx-proxy.yml up -d) &
        spinner $! "Deploying Nginx Proxy Manager container..."
        if [ $? -eq 0 ]; then
            echo -e "\n${GREEN}${CHECK_MARK} Nginx Proxy Manager installation completed${NC}"
            log_message "Nginx Proxy Manager installation completed"
            pause_phase 2 "Nginx Proxy Manager setup complete"
        else
            echo -e "\n${RED}${CROSS_MARK} Nginx Proxy Manager installation failed${NC}"
            log_message "Nginx Proxy Manager installation failed"
            return 1
        fi
    else
        echo -e "${YELLOW}${INFO} Nginx Proxy Manager is already running${NC}"
        log_message "Nginx Proxy Manager is already running"
    fi
}

# Source Odoo configuration function
source "$ODOO_DIR/odoo_config.sh"

# Install Odoo with progress
install_odoo() {
    echo -e "\n${BLUE}${GEAR} Setting up Odoo...${NC}"
    if ! docker container inspect odoo >/dev/null 2>&1; then
        echo -e "${BLUE}${INFO} Setting up Odoo configuration...${NC}"
        get_odoo_config "$ODOO_DIR"
        (docker-compose -f $ODOO_DIR/docker-compose-odoo.yml up -d) &
        spinner $! "Deploying Odoo container..."
        if [ $? -eq 0 ]; then
            echo -e "\n${GREEN}${CHECK_MARK} Odoo installation completed${NC}"
            log_message "Odoo installation completed"
            pause_phase 2 "Odoo setup complete"
        else
            echo -e "\n${RED}${CROSS_MARK} Odoo installation failed${NC}"
            log_message "Odoo installation failed"
            return 1
        fi
    else
        echo -e "${YELLOW}${INFO} Odoo is already running${NC}"
        log_message "Odoo is already running"
    fi
}

# Install Dolibarr with progress
install_dolibarr() {
    echo -e "\n${BLUE}${GEAR} Setting up Dolibarr...${NC}"
    if ! docker container inspect dolibarr >/dev/null 2>&1; then
        (docker-compose -f $DOLIBARR_DIR/docker-compose-dolibarr.yml up -d) &
        spinner $! "Deploying Dolibarr container..."
        if [ $? -eq 0 ]; then
            echo -e "\n${GREEN}${CHECK_MARK} Dolibarr installation completed${NC}"
            log_message "Dolibarr installation completed"
            pause_phase 2 "Dolibarr setup complete"
        else
            echo -e "\n${RED}${CROSS_MARK} Dolibarr installation failed${NC}"
            log_message "Dolibarr installation failed"
            return 1
        fi
    else
        echo -e "${YELLOW}${INFO} Dolibarr is already running${NC}"
        log_message "Dolibarr is already running"
    fi
}

# Install Cloudflare Tunnel with progress
install_cloudflare() {
    echo -e "\n${BLUE}${GEAR} Setting up Cloudflare Tunnel...${NC}"
    if ! docker container inspect cloudflared >/dev/null 2>&1; then
        (docker-compose -f $CLOUDFLARE_DIR/docker-compose-cloudflare.yml up -d) &
        spinner $! "Deploying Cloudflare Tunnel container..."
        if [ $? -eq 0 ]; then
            echo -e "\n${GREEN}${CHECK_MARK} Cloudflare Tunnel installation completed${NC}"
            log_message "Cloudflare Tunnel installation completed"
            pause_phase 2 "Cloudflare Tunnel setup complete"
        else
            echo -e "\n${RED}${CROSS_MARK} Cloudflare Tunnel installation failed${NC}"
            log_message "Cloudflare Tunnel installation failed"
            return 1
        fi
    else
        echo -e "${YELLOW}${INFO} Cloudflare Tunnel is already running${NC}"
        log_message "Cloudflare Tunnel is already running"
    fi
}

# Function to show a spinner
spinner() {
    local pid=$1
    local message=$2
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r${BLUE}%s${NC} %s" "${spin:$i:1}" "$message"
        sleep .1
    done
    printf "\r"
}

# Function to add pauses between phases
pause_phase() {
    local seconds=$1
    local message=$2
    echo -e "\n${YELLOW}${INFO} $message${NC}"
    for ((i=seconds; i>0; i--)); do
        printf "\r${BLUE}Continuing in ${GREEN}%d${BLUE} seconds...${NC}" $i
        sleep 1
    done
    printf "\r%$(tput cols)s\r"
}

# Function to check font installation
check_fonts() {
    local font_name=$1
    if command -v fc-list >/dev/null 2>&1; then
        if ! fc-list | grep -i "$font_name" >/dev/null; then
            return 1
        fi
        return 0
    else
        echo -e "${YELLOW}${INFO} fontconfig not found, installing...${NC}"
        if [[ $DISTRO == "ubuntu" || $DISTRO == "debian" ]]; then
            sudo apt-get update && sudo apt-get install -y fontconfig
        elif [[ $DISTRO == "centos" || $DISTRO == "rhel" || $DISTRO == "fedora" ]]; then
            sudo dnf install -y fontconfig
        elif [[ $DISTRO == "arch" ]]; then
            sudo pacman -S --noconfirm fontconfig
        fi
        return 1
    fi
}

# Function to install Nord fonts
install_nord_fonts() {
    if ! check_fonts "Nord"; then
        echo -e "${YELLOW}${INFO} Nord fonts not found. Installing...${NC}"
        local temp_dir=$(mktemp -d)
        (
            cd "$temp_dir" && \
            curl -OL https://github.com/arcticicestudio/nord-font/releases/latest/download/nord-font.zip && \
            unzip nord-font.zip -d ~/.local/share/fonts/ && \
            fc-cache -f -v
        ) &
        spinner $! "Installing Nord fonts..."
        rm -rf "$temp_dir"
        echo -e "\n${GREEN}${CHECK_MARK} Nord fonts installed successfully${NC}"
        # Reload font cache to use new icons
        source "$0"
    else
        echo -e "${GREEN}${CHECK_MARK} Nord fonts already installed${NC}"
    fi
}

# Function to show installation progress
show_progress() {
    local command=$1
    local message=$2
    echo -e "\n${BLUE}${GEAR} $message${NC}"
    eval "$command" &
    spinner $! "$message"
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}${CHECK_MARK} $message - Completed${NC}"
    else
        echo -e "\n${RED}${CROSS_MARK} $message - Failed${NC}"
        return 1
    fi
}

# Update the main function to include pauses and progress indicators
main() {
    echo -e "\n${BLUE}${ROCKET} Starting Docker Apps Installation${NC}\n"

    # Font Installation
    install_nord_fonts
    pause_phase 3 "Preparing environment..."

    # Phase 1: Environment Setup
    echo -e "${BLUE}${GEAR} Phase 1: Environment Setup${NC}"
    touch "$LOG_FILE"
    log_message "Starting Docker Apps Installation"

    # Linux Distribution Detection
    show_progress "detect_linux_distribution" "Detecting Linux distribution..."
    echo -e "${GREEN}${CHECK_MARK} Selected Linux distribution: $DISTRO${NC}"
    pause_phase 3 "Moving to Docker installation phase..."

    # Phase 2: Docker Environment
    echo -e "\n${BLUE}${GEAR} Phase 2: Docker Environment${NC}"
    show_progress "check_docker_installation" "Checking Docker installation..."
    show_progress "check_docker_compose" "Checking Docker Compose installation..."
    pause_phase 3 "Preparing to install applications..."

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