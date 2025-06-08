#!/bin/bash

# Phase 3: Network Setup
source "./utils/ui.sh"
source "./utils/logging.sh"

# Configure Docker network settings
configure_network() {
    if [ -z "$NETWORK_NAME" ]; then
        NETWORK_NAME="apps_network"
        export NETWORK_NAME
    fi
    
    # Check if Docker service is running
    if ! systemctl is-active --quiet docker; then
        log_message "INFO" "Starting Docker service..."
        sudo systemctl start docker
    fi
    
    # Verify Docker daemon is responsive
    if ! docker info &>/dev/null; then
        log_message "ERROR" "Docker daemon is not responding"
        return 1
    fi
    
    return 0
}

setup_network() {
    show_header "Phase 3: Network Setup"
    
    show_section "Docker Network Configuration"
    configure_network
    if [ $? -eq 0 ]; then
        # Create Docker network with visual feedback
        if ! docker network ls | grep -q "${NETWORK_NAME}"; then
            show_section "Creating Network"
            echo -e "${ICONS[INFO]} Creating Docker network: ${NETWORK_NAME}"
            
            if docker network create ${NETWORK_NAME}; then
                log_message "SUCCESS" "Created Docker network: ${NETWORK_NAME}"
                show_table "Network Details" \
                    "Name: ${NETWORK_NAME}" \
                    "Status: Active" \
                    "Type: bridge"
            else
                log_message "ERROR" "Failed to create Docker network"
                exit 1
            fi
        else
            show_table "Network Status" \
                "Network: ${NETWORK_NAME}" \
                "Status: Already exists"
        fi
        pause_phase 2 "Network configuration complete"
    else
        log_message "ERROR" "Network configuration failed"
        exit 1
    fi
}
