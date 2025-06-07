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

# Nord Font Icons
declare -A ICONS

# OS Icons (Using Nord Font)
UBUNTU_ICON=""   # Ubuntu logo
DEBIAN_ICON=""   # Debian logo
CENTOS_ICON=""   # CentOS logo
RHEL_ICON=""     # Red Hat logo
FEDORA_ICON=""   # Fedora logo
ARCH_ICON=""     # Arch Linux logo

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

# Network Configuration
NETWORK_NAME=""

# Function to configure network
configure_network() {
    echo -e "\n${BLUE}${GLOBE} Network Configuration${NC}"

    # Validate Docker is installed and running
    if ! command_exists docker; then
        echo -e "${RED}${CROSS_MARK} Docker must be installed before configuring network${NC}"
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}${CROSS_MARK} Docker daemon is not running${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}${INFO} Please configure the network settings:${NC}\n"
    
    # Get network name with validation
    echo -e "${BLUE}${INFO} Enter network name (default: proxy):${NC}"
    read -r network_input
    NETWORK_NAME=${network_input:-proxy}
    
    # Validate network name
    if [[ ! $NETWORK_NAME =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}${CROSS_MARK} Invalid network name. Use only letters, numbers, underscores, and hyphens${NC}"
        return 1
    fi
    
    # Export for other scripts
    export NETWORK_NAME
    
    # Log the configuration
    log_message "Network name set to: $NETWORK_NAME"
    echo -e "${GREEN}${CHECK_MARK} Network name set to: ${NETWORK_NAME}${NC}"
    
    return 0
}

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

# Install Odoo with progress
install_odoo() {
    echo -e "\n${BLUE}${GEAR} Setting up Odoo...${NC}"
    if ! docker container inspect odoo >/dev/null 2>&1; then
        echo -e "${BLUE}${INFO} Setting up Odoo configuration...${NC}"
        # Source Odoo configuration only when needed
        source "$ODOO_DIR/odoo_config.sh"
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
        # Initialize icons after successful installation
        initialize_icons
    else
        echo -e "${GREEN}${CHECK_MARK} Nord fonts already installed${NC}"
        # Initialize icons if fonts are already installed
        initialize_icons
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

# Function to verify installations
verify_installations() {
    echo -e "\n${BLUE}${GEAR} Verifying installations...${NC}"
    local all_good=true

    # Check each service based on user selection
    for APP in $APPS; do
        case $APP in
            1)  # Traefik
                if docker container inspect traefik >/dev/null 2>&1; then
                    echo -e "${GREEN}${CHECK_MARK} Traefik${NC} - Running"
                else
                    echo -e "${RED}${CROSS_MARK} Traefik${NC} - Not running"
                    all_good=false
                fi
                ;;
            2)  # Nginx
                if docker container inspect nginx >/dev/null 2>&1; then
                    echo -e "${GREEN}${CHECK_MARK} Nginx${NC} - Running"
                else
                    echo -e "${RED}${CROSS_MARK} Nginx${NC} - Not running"
                    all_good=false
                fi
                ;;
            3)  # Portainer
                if docker container inspect portainer >/dev/null 2>&1; then
                    echo -e "${GREEN}${CHECK_MARK} Portainer${NC} - Running"
                else
                    echo -e "${RED}${CROSS_MARK} Portainer${NC} - Not running"
                    all_good=false
                fi
                ;;
            4)  # Nginx Proxy Manager
                if docker container inspect nginx-proxy-manager >/dev/null 2>&1; then
                    echo -e "${GREEN}${CHECK_MARK} Nginx Proxy Manager${NC} - Running"
                else
                    echo -e "${RED}${CROSS_MARK} Nginx Proxy Manager${NC} - Not running"
                    all_good=false
                fi
                ;;
            5)  # Odoo
                if docker container inspect odoo >/dev/null 2>&1; then
                    echo -e "${GREEN}${CHECK_MARK} Odoo${NC} - Running"
                else
                    echo -e "${RED}${CROSS_MARK} Odoo${NC} - Not running"
                    all_good=false
                fi
                ;;
            6)  # Dolibarr
                if docker container inspect dolibarr >/dev/null 2>&1; then
                    echo -e "${GREEN}${CHECK_MARK} Dolibarr${NC} - Running"
                else
                    echo -e "${RED}${CROSS_MARK} Dolibarr${NC} - Not running"
                    all_good=false
                fi
                ;;
            7)  # Cloudflare
                if docker container inspect cloudflared >/dev/null 2>&1; then
                    echo -e "${GREEN}${CHECK_MARK} Cloudflare Tunnel${NC} - Running"
                else
                    echo -e "${RED}${CROSS_MARK} Cloudflare Tunnel${NC} - Not running"
                    all_good=false
                fi
                ;;
        esac
    done

    if $all_good; then
        echo -e "\n${GREEN}${CHECK_MARK} All selected services are running properly${NC}"
        return 0
    else
        echo -e "\n${RED}${CROSS_MARK} Some services are not running properly${NC}"
        return 1
    fi
}

# Function to initialize Nord Font icons
initialize_icons() {
    # Status icons
    CHECK_MARK=""   # Success checkmark
    CROSS_MARK=""  # Failure X mark
    GEAR=""        # Settings gear
    INFO=""        # Information
    ROCKET=""      # Launch/Start
    WRENCH=""      # Tools/Setup
    SERVER=""      # Server
    GLOBE=""       # Network/Web
    SETTINGS=""    # Advanced settings
    DOCKER=""      # Docker container
    WARNING=""     # Warning symbol
    CLOCK=""       # Time/Wait
    SHIELD=""      # Security
    DATABASE=""    # Database
    LOCK=""        # Authentication

    # OS Icons
    UBUNTU_ICON=""   # Ubuntu logo
    DEBIAN_ICON=""   # Debian logo
    CENTOS_ICON=""   # CentOS logo
    RHEL_ICON=""     # Red Hat logo
    FEDORA_ICON=""   # Fedora logo
    ARCH_ICON=""     # Arch Linux logo

    log_message "Icons initialized with Nord Font"
}

# Main function with corrected order
main() {
    clear
    echo -e "\n${BLUE}${ROCKET} Welcome to Docker Apps Installation${NC}\n"

    # Phase 1: Initial Setup
    echo -e "${BLUE}${GEAR} Phase 1: Initial Setup${NC}"
    
    # Create log file and base directory
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    log_message "Starting Docker Apps Installation"
    
    # Font Installation
    install_nord_fonts
    pause_phase 2 "Fonts configured"

    # Linux Distribution Selection
    echo -e "\n${BLUE}${GEAR} Distribution Detection${NC}"
    detect_linux_distribution
    log_message "Selected distribution: $DISTRO"
    pause_phase 2 "Distribution configured"

    # Phase 2: Prerequisites
    echo -e "\n${BLUE}${GEAR} Phase 2: Prerequisites Check${NC}"
    
    # Docker check and installation
    check_docker_installation
    if [ $? -eq 0 ]; then
        log_message "Docker check completed"
        pause_phase 2 "Docker configured"
    else
        echo -e "${RED}${CROSS_MARK} Docker configuration failed${NC}"
        exit 1
    fi

    # Docker Compose check and installation
    check_docker_compose
    if [ $? -eq 0 ]; then
        log_message "Docker Compose check completed"
        pause_phase 2 "Docker Compose configured"
    else
        echo -e "${RED}${CROSS_MARK} Docker Compose configuration failed${NC}"
        exit 1
    fi

    # Phase 3: Network Setup
    echo -e "\n${BLUE}${GEAR} Phase 3: Network Setup${NC}"
    
    # Network Configuration (must happen after Docker is installed)
    configure_network
    if [ $? -eq 0 ]; then
        # Create Docker network
        if ! docker network ls | grep -q "${NETWORK_NAME}"; then
            echo -e "${YELLOW}${INFO} Creating Docker network: ${NETWORK_NAME}${NC}"
            if docker network create ${NETWORK_NAME}; then
                log_message "Created Docker network: ${NETWORK_NAME}"
                echo -e "${GREEN}${CHECK_MARK} Docker network ${NETWORK_NAME} created successfully${NC}"
            else
                echo -e "${RED}${CROSS_MARK} Failed to create Docker network${NC}"
                exit 1
            fi
        else
            echo -e "${GREEN}${CHECK_MARK} Docker network ${NETWORK_NAME} already exists${NC}"
        fi
        pause_phase 2 "Network configuration complete"
    else
        echo -e "${RED}${CROSS_MARK} Network configuration failed${NC}"
        exit 1
    fi

    # Phase 4: Application Installation
    echo -e "\n${BLUE}${ROCKET} Phase 4: Application Installation${NC}"
    # Show application menu and get user selection
    ask_user
    if [ $? -eq 0 ]; then
        log_message "Applications installed successfully"
    else
        echo -e "${RED}${CROSS_MARK} Some applications failed to install${NC}"
        log_message "Some applications failed to install"
    fi

    # Phase 5: Verification
    echo -e "\n${BLUE}${GEAR} Phase 5: Verification${NC}"
    verify_installations
    
    echo -e "\n${GREEN}${CHECK_MARK} Installation Complete!${NC}"
    echo -e "${GREEN}${ROCKET} Successfully deployed services:${NC}"
    display_urls
    echo -e "\n${YELLOW}${INFO} Installation logs available at: $BASE_DIR/install_log.txt${NC}\n"
}

# Run the main function
main