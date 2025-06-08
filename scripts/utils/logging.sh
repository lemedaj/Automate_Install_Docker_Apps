# Main Logger and Spinner functions
spinner() {
    local pid=$1
    local message=$2
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r${COLORS[BLUE]}%s${COLORS[NC]} %s" "${spin:$i:1}" "$message"
        sleep .1
    done
    printf "\r"
}

# Enhanced logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_line=""
    
    case "$level" in
        "INFO")
            log_line="${timestamp} [${COLORS[BLUE]}INFO${COLORS[NC]}] ${message}"
            ;;
        "WARN")
            log_line="${timestamp} [${COLORS[YELLOW]}WARN${COLORS[NC]}] ${message}"
            ;;
        "ERROR")
            log_line="${timestamp} [${COLORS[RED]}ERROR${COLORS[NC]}] ${message}"
            ;;
        "SUCCESS")
            log_line="${timestamp} [${COLORS[GREEN]}SUCCESS${COLORS[NC]}] ${message}"
            ;;
        *)
            log_line="${timestamp} [${level}] ${message}"
            ;;
    esac
    
    echo -e "$log_line" | tee -a "$LOG_FILE"
}

# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${COLORS[BLUE]}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%${COLORS[NC]}" $percentage
}

# Function to display service URLs in a table format
display_urls() {
    local services=("$@")
    local max_length=0
    
    # Find longest service name for formatting
    for service in "${services[@]}"; do
        if [[ ${#service} -gt $max_length ]]; then
            max_length=${#service}
        fi
    done
    
    # Print header
    echo -e "\n${COLORS[GREEN]}${ICONS[GLOBE]} Available Services:${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}┌─${'─' * (max_length + 2)}─┬─${'─' * 40}─┐${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}│ Service${' ' * (max_length - 7)} │ URL${' ' * 37}│${COLORS[NC]}"
    echo -e "${COLORS[BLUE]}├─${'─' * (max_length + 2)}─┼─${'─' * 40}─┤${COLORS[NC]}"
    
    # Print each service URL
    for service in "${services[@]}"; do
        local url="https://${service,,}.${DOMAIN}"
        echo -e "${COLORS[BLUE]}│${COLORS[NC]} ${service}${' ' * (max_length - ${#service})} ${COLORS[BLUE]}│${COLORS[NC]} ${url}${' ' * $(( 40 - ${#url} ))}${COLORS[BLUE]}│${COLORS[NC]}"
    done
    
    # Print footer
    echo -e "${COLORS[BLUE]}└─${'─' * (max_length + 2)}─┴─${'─' * 40}─┘${COLORS[NC]}"
}
