#!/bin/bash

# GoFile Uploader Enhanced
# Features: Progress bar, error handling, server selection, colorful output

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if file argument is provided
if [[ "$#" == '0' ]]; then
    echo -e "${RED}ERROR:${NC} No File Specified!"
    echo -e "Usage: ${YELLOW}$0 <file>${NC}"
    exit 1
fi

# Store the file path
FILE="$1"

# Check if file exists
if [[ ! -f "$FILE" ]]; then
    echo -e "${RED}ERROR:${NC} File '${BLUE}$FILE${NC}' not found!"
    exit 1
fi

# Show file info
echo -e "${GREEN}• Preparing to upload:${NC} ${BLUE}$FILE${NC}"
echo -e "${GREEN}• File size:${NC} ${YELLOW}$(du -h "$FILE" | cut -f1)${NC}"

# Query GoFile API to find the best server
echo -ne "${CYAN}Finding best server...${NC}"
SERVER=$(curl -s https://api.gofile.io/getServer | jq -r '.data.server' 2>/dev/null)

if [[ -z "$SERVER" ]]; then
    echo -e "\r${RED}✖ ERROR:${NC} Could not get server from GoFile API"
    exit 1
fi
echo -e "\r${GREEN}✓ Best server found:${NC} ${YELLOW}$SERVER${NC}"

# Upload the file with progress bar
echo -e "${CYAN}Uploading file...${NC}"
LINK=$(curl --progress-bar -F "file=@$FILE" "https://${SERVER}.gofile.io/uploadFile" | jq -r '.data.downloadPage' 2>&1)

# Check if upload was successful
if [[ "$LINK" == "null" || -z "$LINK" ]]; then
    echo -e "${RED}✖ Upload failed!${NC}"
    exit 1
fi

# Display results
echo -e "\n${GREEN}✓ Upload successful!${NC}"
echo -e "${YELLOW}Download link:${NC} ${BLUE}$LINK${NC}"
echo -e "${CYAN}Link copied to clipboard!${NC}"

# Try to copy to clipboard (works in Termux)
if command -v termux-clipboard-set &> /dev/null; then
    echo "$LINK" | termux-clipboard-set
elif command -v xclip &> /dev/null; then
    echo "$LINK" | xclip -selection clipboard
fi
