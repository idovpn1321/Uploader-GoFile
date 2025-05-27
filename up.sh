#!/bin/bash

# GoFile Uploader with Fancy Progress Bar
# Requires: curl, jq, bc (for calculations)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Animation chars
SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# Function to display animated spinner
spinner() {
    while true; do
        for i in "${SPINNER[@]}"; do
            echo -ne "\r$1 ${CYAN}$i${NC} "
            sleep 0.1
        done
    done
}

# Function to draw progress bar
progress_bar() {
    local progress=$1
    local width=30
    local filled=$(printf "%.0f" $(echo "$progress*$width/100" | bc -l))
    local empty=$((width - filled))
    
    printf "${MAGENTA}["
    printf "%${filled}s" | tr ' ' '■'
    printf "%${empty}s" | tr ' ' ' '
    printf "]${NC} ${YELLOW}%3.0f%%${NC}" "$progress"
}

# Function to get file size in human readable format
human_filesize() {
    awk -v size=$1 'BEGIN {
        suffixes[0] = "B"
        suffixes[1] = "KB"
        suffixes[2] = "MB"
        suffixes[3] = "GB"
        count = 0
        while (size > 1024) {
            size /= 1024
            count++
        }
        printf "%.2f %s", size, suffixes[count]
    }'
}

# Main upload function
upload_to_gofile() {
    local file=$1
    local file_size=$(stat -c %s "$file")
    local file_size_human=$(human_filesize $file_size)
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found!${NC}"
        exit 1
    fi

    echo -e "${GREEN}• ${YELLOW}Preparing to upload: ${BLUE}$file${NC} (${CYAN}$file_size_human${NC})"
    
    # Start spinner
    spinner "Finding best GoFile server..." &
    spinner_pid=$!
    
    # Get server
    server=$(curl -s "https://api.gofile.io/getServer" | jq -r '.data.server' 2>/dev/null)
    
    # Stop spinner
    kill $spinner_pid 2>/dev/null
    wait $spinner_pid 2>/dev/null
    
    if [ -z "$server" ]; then
        echo -e "\r${RED}✖ Error: Could not get GoFile server${NC}"
        exit 1
    fi
    
    echo -e "\r${GREEN}✓ ${YELLOW}Best server: ${BLUE}$server.gofile.io${NC}"
    echo -e "${GREEN}• ${YELLOW}Starting upload...${NC}"
    
    # Upload with progress
    {
        uploaded=0
        while [ $uploaded -lt 100 ]; do
            sleep 0.5
            if [ -f curlprogress ]; then
                current=$(tail -n 1 curlprogress | awk '{print $1}')
                uploaded=$(echo "scale=2; $current/$file_size*100" | bc -l)
                if (( $(echo "$uploaded > 100" | bc -l) )); then
                    uploaded=100
                fi
                printf "\rUploading: "
                progress_bar $uploaded
                printf " (${CYAN}$(human_filesize $current)${NC}/${CYAN}$file_size_human${NC})"
            fi
        done
    } &
    progress_pid=$!
    
    # Actual upload
    response=$(curl --progress-bar -F "file=@$file" "https://$server.gofile.io/uploadFile" 2> curlprogress | jq)
    rm -f curlprogress
    
    wait $progress_pid
    echo -ne "\n"
    
    if [ $(echo "$response" | jq -r '.status') == "ok" ]; then
        echo -e "\n${GREEN}✓ Upload successful!${NC}"
        echo -e "${YELLOW}• Download page: ${BLUE}$(echo "$response" | jq -r '.data.downloadPage')${NC}"
        echo -e "${YELLOW}• Direct link: ${BLUE}$(echo "$response" | jq -r '.data.directLink')${NC}"
        echo -e "${YELLOW}• File code: ${BLUE}$(echo "$response" | jq -r '.data.code')${NC}"
    else
        echo -e "\n${RED}✖ Upload failed!${NC}"
        echo -e "${RED}Error: $(echo "$response" | jq -r '.status')${NC}"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl is required but not installed.${NC}"
        echo -e "Install with: ${BLUE}pkg install curl${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        echo -e "Install with: ${BLUE}pkg install jq${NC}"
        exit 1
    fi
    
    if ! command -v bc &> /dev/null; then
        echo -e "${RED}Error: bc is required but not installed.${NC}"
        echo -e "Install with: ${BLUE}pkg install bc${NC}"
        exit 1
    fi
}

# Main
clear
echo -e "${CYAN}"
echo "   ____       ______      __ "
echo "  / ___| ___ / _ \\ \\    / / "
echo " | |  _ / _ \\ | | \\ \\/\\/ /  "
echo " | |_| |  __/ |_| |\\  /\\  /  "
echo "  \\____|\\___|\\___/  \\/  \\/   "
echo -e "${NC}"

check_dependencies

if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage: ${BLUE}$0 <file>${NC}"
    exit 1
fi

upload_to_gofile "$1"
