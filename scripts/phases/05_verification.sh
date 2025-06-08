#!/bin/bash

# Phase 5: Verification
source "./utils/ui.sh"
source "./utils/logging.sh"

verify_setup() {
    show_header "Phase 5: Verification"
    
    if verify_installations; then
        show_section "Success Summary"
        echo -e "${ICONS[CHECK_MARK]} Installation Complete!"
        
        # Show running services in a table
        local running_services=()
        for APP in $APPS; do
            case $APP in
                1) docker container inspect traefik >/dev/null 2>&1 && \
                   running_services+=("${ICONS[CHECK_MARK]} Traefik") ;;
                2) docker container inspect nginx >/dev/null 2>&1 && \
                   running_services+=("${ICONS[CHECK_MARK]} Nginx") ;;
                3) docker container inspect portainer >/dev/null 2>&1 && \
                   running_services+=("${ICONS[CHECK_MARK]} Portainer") ;;
                4) docker container inspect nginx-proxy-manager >/dev/null 2>&1 && \
                   running_services+=("${ICONS[CHECK_MARK]} Nginx Proxy Manager") ;;
                5) docker container inspect odoo >/dev/null 2>&1 && \
                   running_services+=("${ICONS[CHECK_MARK]} Odoo") ;;
                6) docker container inspect dolibarr >/dev/null 2>&1 && \
                   running_services+=("${ICONS[CHECK_MARK]} Dolibarr") ;;
                7) docker container inspect cloudflared >/dev/null 2>&1 && \
                   running_services+=("${ICONS[CHECK_MARK]} Cloudflare Tunnel") ;;
            esac
        done
        
        show_table "Running Services" "${running_services[@]}"
        
        # Display URLs with enhanced formatting
        show_section "Service URLs"
        display_urls
        
        show_section "Installation Complete"
        echo -e "${ICONS[INFO]} Installation logs available at: $BASE_DIR/install_log.txt"
    else
        show_section "Installation Failed"
        echo -e "${ICONS[CROSS_MARK]} Some services failed to start"
        
        # Show failed services in a table
        local failed_services=()
        for APP in $APPS; do
            case $APP in
                1) docker container inspect traefik >/dev/null 2>&1 || \
                   failed_services+=("${ICONS[CROSS_MARK]} Traefik") ;;
                2) docker container inspect nginx >/dev/null 2>&1 || \
                   failed_services+=("${ICONS[CROSS_MARK]} Nginx") ;;
                3) docker container inspect portainer >/dev/null 2>&1 || \
                   failed_services+=("${ICONS[CROSS_MARK]} Portainer") ;;
                4) docker container inspect nginx-proxy-manager >/dev/null 2>&1 || \
                   failed_services+=("${ICONS[CROSS_MARK]} Nginx Proxy Manager") ;;
                5) docker container inspect odoo >/dev/null 2>&1 || \
                   failed_services+=("${ICONS[CROSS_MARK]} Odoo") ;;
                6) docker container inspect dolibarr >/dev/null 2>&1 || \
                   failed_services+=("${ICONS[CROSS_MARK]} Dolibarr") ;;
                7) docker container inspect cloudflared >/dev/null 2>&1 || \
                   failed_services+=("${ICONS[CROSS_MARK]} Cloudflare Tunnel") ;;
            esac
        done
        
        show_table "Failed Services" "${failed_services[@]}"
        echo -e "${ICONS[INFO]} Check logs at: $BASE_DIR/install_log.txt for details"
    fi
}

# Function to verify all installations
verify_installations() {
    local success=true
    
    show_section "Service Status"
    
    # Count running services
    local total=$(echo "$APPS" | wc -w)
    local current=0
    
    for APP in $APPS; do
        case $APP in
            1) verify_container "traefik" && ((current++)) ;;
            2) verify_container "nginx" && ((current++)) ;;
            3) verify_container "portainer" && ((current++)) ;;
            4) verify_container "nginx-proxy-manager" && ((current++)) ;;
            5) verify_container "odoo" && ((current++)) ;;
            6) verify_container "dolibarr" && ((current++)) ;;
            7) verify_container "cloudflared" && ((current++)) ;;
        esac
        show_progress $current $total
    done
    
    return $success
}

# Function to verify a specific container
verify_container() {
    local container_name=$1
    local status=$(docker container inspect -f '{{.State.Status}}' $container_name 2>/dev/null)
    
    if [ "$status" = "running" ]; then
        log_message "SUCCESS" "$container_name is running"
        return 0
    else
        log_message "ERROR" "$container_name is not running"
        return 1
    fi
}

# Function to count running services
count_running_services() {
    local running=0
    local services=($@)
    
    for service in "${services[@]}"; do
        if docker container inspect $service >/dev/null 2>&1; then
            ((running++))
        fi
    done
    
    return $running
}
