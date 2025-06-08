#!/bin/bash

# Import colors
source "./utils/colors.sh"

# Nord Font Icons with enhanced organization
declare -A ICONS=(
    # Status Icons
    ["CHECK_MARK"]=""    # Success checkmark
    ["CROSS_MARK"]=""   # Failure X mark
    ["GEAR"]=""         # Settings gear
    ["INFO"]=""         # Information
    ["ROCKET"]=""       # Launch/Start
    ["WRENCH"]=""       # Tools/Setup
    ["SERVER"]=""       # Server
    ["GLOBE"]=""        # Network/Web
    ["SETTINGS"]=""     # Advanced settings
    ["DOCKER"]=""       # Docker container
    ["WARNING"]=""      # Warning symbol
    ["CLOCK"]=""        # Time/Wait
    ["SHIELD"]=""       # Security
    ["DATABASE"]=""     # Database
    ["LOCK"]=""         # Authentication

    # OS Icons
    ["UBUNTU"]=""       # Ubuntu logo
    ["DEBIAN"]=""       # Debian logo
    ["CENTOS"]=""       # CentOS logo
    ["RHEL"]=""         # Red Hat logo
    ["FEDORA"]=""       # Fedora logo
    ["ARCH"]=""         # Arch Linux logo
)

# Export icons for use in other scripts
for icon in "${!ICONS[@]}"; do
    export "${icon}=${ICONS[$icon]}"
done

# Function to show fancy headers
show_header() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title}) / 2 ))
    
    echo -e "\n${COLORS[BLUE]}╔═${'═' * width}═╗${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}║${' ' * padding}${COLORS[GREEN]}${title}${' ' * (width - ${#title} - padding)}${COLORS[BLUE]}║${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}╚═${'═' * width}═╝${COLORS[NC]}\n"
}

# Function to show section dividers
show_section() {
    local title="$1"
    echo -e "\n${COLORS[PURPLE]}━━━ ${COLORS[YELLOW]}${title} ${COLORS[PURPLE]}${'━' * (50 - ${#title})}${COLORS[NC]}\n"
}

# Function to show tabulated output
show_table() {
    local header="$1"
    shift
    local items=("$@")
    local max_length=0
    
    # Find the longest item
    for item in "${items[@]}"; do
        (( ${#item} > max_length )) && max_length=${#item}
    done
    
    # Print header
    echo -e "\n${COLORS[BLUE]}┌─${'─' * (max_length + 2)}─┐${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}│ ${COLORS[GREEN]}${header}${' ' * (max_length - ${#header})} ${COLORS[BLUE]}│${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}├─${'─' * (max_length + 2)}─┤${COLORS[NC]}"
    
    # Print items
    for item in "${items[@]}"; do
        echo -e "${COLORS[BLUE]}│ ${COLORS[NC]}${item}${' ' * (max_length - ${#item})} ${COLORS[BLUE]}│${COLORS[NC]}"
    done
    
    # Print footer
    echo -e "${COLORS[BLUE]}└─${'─' * (max_length + 2)}─┘${COLORS[NC]}"
}

# Spinner animation function
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null; do
        for i in ${spinstr}; do
            printf "${COLORS[CYAN]}${ICONS[CLOCK]} Processing %s\r${COLORS[NC]}" "$i"
            sleep $delay
        done
    done
    printf "\r"
}

# Progress indicator
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${COLORS[BLUE]}[${COLORS[GREEN]}"
    printf "%${filled}s" '' | tr ' ' '='
    printf "%${empty}s" '' | tr ' ' ' '
    printf "${COLORS[BLUE]}] ${COLORS[YELLOW]}%d%%${COLORS[NC]}" $percentage
}

# Function to pause between phases
pause_phase() {
    local message="${1:-Press ENTER to continue...}"
    echo -e "\n${COLORS[YELLOW]}${ICONS[INFO]} $message${COLORS[NC]}"
    read -r
}
