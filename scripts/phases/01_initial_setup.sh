#!/bin/bash

# Phase 1: Initial Setup
source "./utils/ui.sh"
source "./utils/logging.sh"

# Install Nord fonts for better UI
install_nord_fonts() {
    log_message "INFO" "Installing Nord fonts..."
    
    local font_dir="$HOME/.local/share/fonts/NerdFonts"
    mkdir -p "$font_dir"
    
    # Download and install fonts
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
    unzip -q JetBrainsMono.zip -d "$font_dir"
    rm JetBrainsMono.zip
    
    # Refresh font cache
    fc-cache -f
    
    check_fonts
}

# Check if fonts are properly installed
check_fonts() {
    if fc-list | grep -i "JetBrainsMono Nerd Font" > /dev/null; then
        log_message "SUCCESS" "Nord fonts installed successfully"
        return 0
    else
        log_message "ERROR" "Font installation failed"
        return 1
    fi
}

# Detect Linux distribution for package management
detect_linux_distribution() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
    else
        DISTRO="unknown"
    fi
    
    case "$DISTRO" in
        "ubuntu"|"debian")
            PKG_MANAGER="apt-get"
            ;;
        "fedora"|"rhel"|"centos")
            PKG_MANAGER="dnf"
            ;;
        *)
            log_message "ERROR" "Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac
}

# Configure domain for services
configure_domain() {
    if [ -z "$DOMAIN" ]; then
        read -p "${COLORS[YELLOW]}${ICONS[GLOBE]} Enter your domain name: ${COLORS[NC]}" DOMAIN
        if [ -z "$DOMAIN" ]; then
            log_message "ERROR" "Domain name cannot be empty"
            return 1
        fi
        export DOMAIN
    fi
    return 0
}

initial_setup() {
    show_header "Phase 1: Initial Setup"
    
    # Create log file and base directory
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    log_message "INFO" "Starting Docker Apps Installation"
    
    # Setup sections in organized blocks
    show_section "Font Installation"
    install_nord_fonts
    pause_phase 2 "Fonts configured"

    show_section "Distribution Detection"
    detect_linux_distribution
    log_message "INFO" "Selected distribution: $DISTRO"
    pause_phase 2 "Distribution configured"

    show_section "Domain Configuration"
    configure_domain
    if [ $? -eq 0 ]; then
        pause_phase 2 "Domain configured"
        log_message "SUCCESS" "Domain configuration completed"
    else
        log_message "ERROR" "Domain configuration failed"
        exit 1
    fi
}
