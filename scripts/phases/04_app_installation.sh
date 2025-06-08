#!/bin/bash

# Phase 4: Application Installation
source "./utils/ui.sh"
source "./utils/logging.sh"

# Function to install Portainer
install_portainer() {
    show_section "Installing Portainer"
    
    cd portainer
    if docker-compose -f docker-compose-portainer.yml up -d; then
        log_message "SUCCESS" "Portainer installed successfully"
        return 0
    else
        log_message "ERROR" "Failed to install Portainer"
        return 1
    fi
}

# Function to install Nginx
install_nginx() {
    show_section "Installing Nginx"
    
    cd nginx
    if docker-compose -f docker-compose-nginx.yml up -d; then
        log_message "SUCCESS" "Nginx installed successfully"
        return 0
    else
        log_message "ERROR" "Failed to install Nginx"
        return 1
    fi
}

# Function to install Nginx Proxy Manager
install_nginx_proxy_manager() {
    show_section "Installing Nginx Proxy Manager"
    
    cd nginx-proxy-manager
    if docker-compose -f docker-compose-nginx-proxy.yml up -d; then
        log_message "SUCCESS" "Nginx Proxy Manager installed successfully"
        return 0
    else
        log_message "ERROR" "Failed to install Nginx Proxy Manager"
        return 1
    fi
}

# Function to install Odoo
install_odoo() {
    show_section "Installing Odoo"
    
    cd odoo
    chmod +x odoo_config.sh
    ./odoo_config.sh
    
    if docker-compose -f docker-compose-odoo.yml up -d; then
        log_message "SUCCESS" "Odoo installed successfully"
        return 0
    else
        log_message "ERROR" "Failed to install Odoo"
        return 1
    fi
}

# Function to install Dolibarr
install_dolibarr() {
    show_section "Installing Dolibarr"
    
    cd dolibarr
    if docker-compose -f docker-compose-dolibarr.yml up -d; then
        log_message "SUCCESS" "Dolibarr installed successfully"
        return 0
    else
        log_message "ERROR" "Failed to install Dolibarr"
        return 1
    fi
}

# Function to install Cloudflare Tunnel
install_cloudflare() {
    show_section "Installing Cloudflare Tunnel"
    
    cd cloudflare
    if docker-compose -f docker-compose-cloudflare.yml up -d; then
        log_message "SUCCESS" "Cloudflare Tunnel installed successfully"
        return 0
    else
        log_message "ERROR" "Failed to install Cloudflare Tunnel"
        return 1
    fi
}

# Function to install Traefik
install_traefik() {
    show_section "Installing Traefik"
    
    cd traefik
    chmod +x traefik_config.sh
    ./traefik_config.sh
    
    chmod 600 data/acme.json
    if docker-compose -f docker-compose-traefik.yaml up -d; then
        log_message "SUCCESS" "Traefik installed successfully"
        return 0
    else
        log_message "ERROR" "Failed to install Traefik"
        return 1
    fi
}

# Function to handle user service selection
ask_user() {
    local failed_services=()
    local services_up=0
    local total_services=7
    
    while true; do
        read -p "${COLORS[YELLOW]}Enter the number of the service to install (1-7) or 'q' to quit: ${COLORS[NC]}" choice
        case $choice in
            1) install_traefik && ((services_up++)) || failed_services+=("Traefik") ;;
            2) install_nginx && ((services_up++)) || failed_services+=("Nginx") ;;
            3) install_portainer && ((services_up++)) || failed_services+=("Portainer") ;;
            4) install_nginx_proxy_manager && ((services_up++)) || failed_services+=("Nginx Proxy Manager") ;;
            5) install_odoo && ((services_up++)) || failed_services+=("Odoo") ;;
            6) install_dolibarr && ((services_up++)) || failed_services+=("Dolibarr") ;;
            7) install_cloudflare && ((services_up++)) || failed_services+=("Cloudflare Tunnel") ;;
            q|Q) break ;;
            *) echo "Invalid option" ;;
        esac
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

install_applications() {
    show_header "Phase 4: Application Installation"
    
    show_section "Service Selection"
    # Enhanced service menu with icons and descriptions
    local services=(
        "${ICONS[GEAR]} Traefik|Reverse Proxy and SSL Manager"
        "${ICONS[SERVER]} Nginx|Web Server"
        "${ICONS[DOCKER]} Portainer|Container Management UI"
        "${ICONS[SERVER]} Nginx Proxy Manager|Visual Proxy Management"
        "${ICONS[DATABASE]} Odoo|Business Management Suite"
        "${ICONS[DATABASE]} Dolibarr|ERP & CRM"
        "${ICONS[SHIELD]} Cloudflare Tunnel|Secure Tunnel"
    )
    
    # Display services in a fancy table
    show_table "Available Services" "${services[@]}"
    
    ask_user
    if [ $? -eq 0 ]; then
        log_message "SUCCESS" "Applications installed successfully"
        show_section "Installation Summary"
        show_progress $services_up ${#services[@]}
    else
        log_message "ERROR" "Some applications failed to install"
        show_section "Failed Services"
        for app in "${failed_services[@]}"; do
            echo -e "${ICONS[CROSS_MARK]} $app"
        done
    fi
}
