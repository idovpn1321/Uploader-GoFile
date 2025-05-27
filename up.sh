#!/bin/bash

# Script Uploader Bash dengan Progress Indicator
# Usage: ./uploader.sh [file_to_upload] [remote_server]

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cek dependensi
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl tidak ditemukan. Harap instal curl terlebih dahulu.${NC}"
        exit 1
    fi
    
    if ! command -v bc &> /dev/null; then
        echo -e "${RED}Error: bc tidak ditemukan. Harap instal bc terlebih dahulu.${NC}"
        exit 1
    fi
}

# Fungsi untuk menampilkan progress bar
progress_bar() {
    local progress=$1
    local width=50
    local filled=$(printf "%.0f" $(echo "$progress*$width/100" | bc -l))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] %3.0f%%" "$progress"
}

# Fungsi utama untuk upload
upload_file() {
    local file="$1"
    local server="$2"
    local file_size=$(stat -c %s "$file")
    local uploaded=0
    
    # Validasi file
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File '$file' tidak ditemukan.${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Mengunggah $file (size: $((file_size/1024)) KB) ke $server...${NC}"
    echo ""
    
    # Upload menggunakan curl dengan progress meter
    {
        # Background process untuk menghitung progress
        while [ $uploaded -lt 100 ]; do
            sleep 1
            if [ -f curlprogress ]; then
                current=$(tail -n 1 curlprogress | awk '{print $1}')
                uploaded=$(echo "scale=2; $current/$file_size*100" | bc -l)
                if [ $(echo "$uploaded > 100" | bc -l) -eq 1 ]; then
                    uploaded=100
                fi
                progress_bar $uploaded
            fi
        done
    } &
    progress_pid=$!
    
    # Eksekusi curl
    response=$(curl --progress-bar -F "file=@$file" "$server" 2> curlprogress)
    rm -f curlprogress
    
    wait $progress_pid
    printf "\n\n"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Upload berhasil!${NC}"
        echo "Response dari server:"
        echo "$response"
    else
        echo -e "${RED}Upload gagal!${NC}"
        exit 1
    fi
}

# Main program
main() {
    check_dependencies
    
    if [ $# -lt 2 ]; then
        echo -e "${YELLOW}Usage: $0 [file_to_upload] [remote_server]${NC}"
        exit 1
    fi
    
    upload_file "$1" "$2"
}

main "$@"
