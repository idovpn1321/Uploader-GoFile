#!/bin/bash

# ==============================================
#  ____       ______      __   _____      _     
# / ___| ___ / _ \ \    / /  / / _ \____| |___ 
#| |  _ / _ \ | | \ \/\/ /  / / | |/ _` | / __|
#| |_| |  __/ |_| |\  /\ \ / /| | | (_| | \__ \
# \____|\___|\___/  \/  \_/_/ |_|_|\__,_|_|___/
#                                              
# GoFile Premium Uploader
# ==============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Borders
BORDER="${PURPLE}══════════════════════════════════════════${NC}"

# Check if file argument is provided
if [[ "$#" == '0' ]]; then
    echo -e "\n$BORDER"
    echo -e "${RED}✖ ERROR:${NC} No File Specified!"
    echo -e "Usage: ${YELLOW}$0 <file>${NC}"
    echo -e "$BORDER\n"
    exit 1
fi

# Store the file path
FILE="$1"

# Check if file exists
if [[ ! -f "$FILE" ]]; then
    echo -e "\n$BORDER"
    echo -e "${RED}✖ ERROR:${NC} File ${BLUE}$FILE${NC} not found!"
    echo -e "$BORDER\n"
    exit 1
fi

# Show file info
echo -e "\n$BORDER"
echo -e "${GREEN}🚀 Preparing to upload:${NC} ${BLUE}$FILE${NC}"
echo -e "${GREEN}📦 File size:${NC} ${YELLOW}$(du -h "$FILE" | cut -f1)${NC}"
echo -e "$BORDER"

# Query GoFile API to find the best server
echo -ne "${CYAN}🔍 Finding best server...${NC}"
SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')

if [[ -z "$SERVER" ]]; then
    echo -e "\r${RED}✖ ERROR:${NC} Could not get server from GoFile API"
    exit 1
fi
echo -e "\r${GREEN}✓ Best server found:${NC} ${YELLOW}$SERVER${NC}"

# Upload the file with progress bar
echo -e "\n${CYAN}⬆️  Uploading file...${NC}"
echo -e "$BORDER"
LINK=$(curl -# -F "file=@$FILE" "https://${SERVER}.gofile.io/uploadFile" | jq -r '.data|.downloadPage') 2>&1
echo -e "$BORDER"

# Check if upload was successful
if [[ "$LINK" == "null" || -z "$LINK" ]]; then
    echo -e "\n${RED}✖ Upload failed!${NC}"
    exit 1
fi

# Display results
echo -e "\n${GREEN}✅ Upload successful!${NC}"
echo -e "$BORDER"
echo -e "${YELLOW}🔗 Download link:${NC}"
echo -e "${BLUE}$LINK${NC}"
echo -e "$BORDER"

# Try to copy to clipboard
if command -v termux-clipboard-set &> /dev/null; then
    echo "$LINK" | termux-clipboard-set
    echo -e "${CYAN}📋 Link copied to clipboard!${NC}"
elif command -v xclip &> /dev/null; then
    echo "$LINK" | xclip -selection clipboard
    echo -e "${CYAN}📋 Link copied to clipboard!${NC}"
fi

echo -e "\n${PURPLE}✨ Upload completed successfully!${NC}\n"
