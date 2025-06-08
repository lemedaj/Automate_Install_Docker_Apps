#!/bin/bash

# Phase 2: Prerequisites Check
source "./utils/ui.sh"
source "./utils/logging.sh"

check_prerequisites() {
    show_header "Phase 2: Prerequisites Check"
    
    show_section "Docker Installation"
    check_docker_installation
    if [ $? -eq 0 ]; then
        log_message "SUCCESS" "Docker check completed"
        pause_phase 2 "Docker configured"
    else
        log_message "ERROR" "Docker configuration failed"
        exit 1
    fi

    show_section "Docker Compose Installation"
    check_docker_compose
    if [ $? -eq 0 ]; then
        log_message "SUCCESS" "Docker Compose check completed"
        pause_phase 2 "Docker Compose configured"
    else
        log_message "ERROR" "Docker Compose configuration failed"
        exit 1
    fi
    
    return 0
}

# Docker Functions
install_docker() {
    if ! command_exists docker; then
        echo -e "${ICONS[DOCKER]} Installing Docker..."
        case $DISTRO in
            ubuntu|debian)
                show_progress_spinner "Installing Docker for $DISTRO" \
                "sudo apt-get update && 
                 sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common &&
                 curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo apt-key add - &&
                 sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable\" &&
                 sudo apt-get update &&
                 sudo apt-get install -y docker-ce"
                ;;
            centos|rhel)
                show_progress_spinner "Installing Docker for $DISTRO" \
                "sudo yum install -y yum-utils &&
                 sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &&
                 sudo yum install -y docker-ce &&
                 sudo systemctl start docker &&
                 sudo systemctl enable docker"
                ;;
            fedora)
                show_progress_spinner "Installing Docker for Fedora" \
                "sudo dnf -y install dnf-plugins-core &&
                 sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo &&
                 sudo dnf install -y docker-ce docker-ce-cli containerd.io &&
                 sudo systemctl start docker &&
                 sudo systemctl enable docker"
                ;;
            arch)
                show_progress_spinner "Installing Docker for Arch Linux" \
                "sudo pacman -Syu --noconfirm docker &&
                 sudo systemctl start docker &&
                 sudo systemctl enable docker"
                ;;
            *)
                log_message "ERROR" "Unsupported distribution"
                return 1
                ;;
        esac
        
        if command_exists docker; then
            DOCKER_VERSION=$(docker --version)
            log_message "SUCCESS" "Docker installed successfully - $DOCKER_VERSION"
            return 0
        else
            log_message "ERROR" "Docker installation failed"
            return 1
        fi
    else
        DOCKER_VERSION=$(docker --version)
        log_message "INFO" "Docker already installed: $DOCKER_VERSION"
        return 0
    fi
}

install_docker_compose() {
    if ! command_exists docker-compose && ! docker compose version &>/dev/null; then
        show_section "Installing Docker Compose"
        
        show_progress_spinner "Downloading Docker Compose" \
        "COMPOSE_LATEST=\$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '\"tag_name\": \"[^\"]*' | cut -d'\"' -f4) &&
         sudo curl -L \"https://github.com/docker/compose/releases/download/\${COMPOSE_LATEST}/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose &&
         sudo chmod +x /usr/local/bin/docker-compose"
        
        if command_exists docker-compose || docker compose version &>/dev/null; then
            COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || docker compose version)
            log_message "SUCCESS" "Docker Compose installed successfully - $COMPOSE_VERSION"
            return 0
        else
            log_message "ERROR" "Docker Compose installation failed"
            return 1
        fi
    else
        COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || docker compose version)
        log_message "INFO" "Docker Compose already installed: $COMPOSE_VERSION"
        return 0
    fi
}
    check_docker_installation
    if [ $? -eq 0 ]; then
        log_message "SUCCESS" "Docker check completed"
        pause_phase 2 "Docker configured"
    else
        log_message "ERROR" "Docker configuration failed"
        exit 1
    fi

    # Docker Compose Check
    show_section "Docker Compose Setup"
    check_docker_compose
    if [ $? -eq 0 ]; then
        log_message "SUCCESS" "Docker Compose check completed"
        pause_phase 2 "Docker Compose configured"
    else
        log_message "ERROR" "Docker Compose configuration failed"
        exit 1
    fi
}
