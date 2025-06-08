#!/bin/bash

# Main Installation Script
# Author: Your Name
# Date: June 8, 2025
# Description: Automated Docker Apps Installation Script

# Import utilities
source "./scripts/utils/colors.sh"
source "./scripts/utils/ui.sh"
source "./scripts/utils/logging.sh"

# Import phase scripts
source "./scripts/phases/01_initial_setup.sh"
source "./scripts/phases/02_prerequisites.sh"
source "./scripts/phases/03_network_setup.sh"
source "./scripts/phases/04_app_installation.sh"
source "./scripts/phases/05_verification.sh"

# Script Variables
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
export BASE_DIR="$SCRIPT_DIR"
export LOG_FILE="$BASE_DIR/installation_log.txt"

# Directory paths
export ODOO_DIR="$BASE_DIR/odoo"
export DOLIBARR_DIR="$BASE_DIR/dolibarr"
export NGINX_DIR="$BASE_DIR/nginx"
export NGINX_PROXY_DIR="$BASE_DIR/nginx-proxy-manager"
export PORTAINER_DIR="$BASE_DIR/portainer"
export CLOUDFLARE_DIR="$BASE_DIR/cloudflare"
export TRAEFIK_DIR="$BASE_DIR/traefik"

# Main function
main() {
    clear
    show_header "Docker Apps Installation Script"
    
    # Execute phases
    initial_setup || exit 1
    check_prerequisites || exit 1
    setup_network || exit 1
    install_applications || exit 1
    verify_setup || exit 1
}

# Run main function
main
