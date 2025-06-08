#!/bin/bash

# Dracula Theme Colors with enhanced variables
declare -A COLORS=(
    ["PINK"]='\033[38;2;255;121;198m'    # Pink
    ["PURPLE"]='\033[38;2;189;147;249m'   # Purple
    ["BLUE"]='\033[38;2;139;233;253m'     # Cyan
    ["GREEN"]='\033[38;2;80;250;123m'     # Green
    ["YELLOW"]='\033[38;2;241;250;140m'   # Yellow
    ["RED"]='\033[38;2;255;85;85m'        # Red
    ["ORANGE"]='\033[38;2;255;184;108m'   # Orange
    ["NC"]='\033[0m'                      # No Color
)

# Export colors for use in other scripts
for color in "${!COLORS[@]}"; do
    export "${color}=${COLORS[$color]}"
done
