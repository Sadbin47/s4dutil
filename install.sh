#!/bin/sh
# S4DUtil - Arch Linux Installer
# Lightweight installer - no compilation needed!
# Usage: curl -fsSL https://raw.githubusercontent.com/Sadbin47/s4dutil/main/install.sh | sh

set -e

RC='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'

clear
printf "%b\n" "${CYAN}${BOLD}"
cat << 'EOF'
  ____  _  _   ____  _   _ _   _ _ 
 / ___|| || | |  _ \| | | | |_(_) |
 \___ \| || |_| | | | | | | __| | |
  ___) |__   _| |_| | |_| | |_| | |
 |____/   |_| |____/ \___/ \__|_|_|
                                   
    Arch Linux Installer v1.0.0
EOF
printf "%b\n\n" "${RC}"

INSTALL_DIR="/root/s4dutil"

# Check environment
check_environment() {
    printf "%b\n" "${YELLOW}Checking environment...${RC}"
    
    if [ "$(id -u)" -ne 0 ]; then
        printf "%b\n" "${RED}Error: Run as root!${RC}"
        exit 1
    fi
    
    if [ ! -f /etc/arch-release ]; then
        printf "%b\n" "${RED}Error: Run from Arch Linux Live ISO${RC}"
        exit 1
    fi
    
    if ! ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
        printf "%b\n" "${RED}Error: No internet connection${RC}"
        exit 1
    fi
    
    printf "%b\n" "${GREEN}Environment OK!${RC}"
}

# Download scripts only (no compilation!)
download_scripts() {
    printf "%b\n" "${YELLOW}Downloading installer scripts...${RC}"
    
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # Just download the scripts - no C++ needed!
    git clone --depth 1 https://github.com/Sadbin47/s4dutil.git "$INSTALL_DIR" 2>/dev/null || {
        # Fallback: download individual files if git fails
        printf "%b\n" "${YELLOW}Downloading files directly...${RC}"
        mkdir -p "$INSTALL_DIR/scripts"
        
        BASE_URL="https://raw.githubusercontent.com/Sadbin47/s4dutil/main"
        
        for script in common.sh 00-check-environment.sh 01-partition-disk.sh \
                      02-format-partitions.sh 03-mount-partitions.sh 04-install-base.sh \
                      05-generate-fstab.sh 06-configure-system.sh 07-setup-users.sh \
                      08-install-bootloader.sh 09-finalize.sh; do
            curl -fsSL "$BASE_URL/scripts/$script" -o "$INSTALL_DIR/scripts/$script"
        done
        
        curl -fsSL "$BASE_URL/s4dutil.sh" -o "$INSTALL_DIR/s4dutil.sh"
    }
    
    chmod +x "$INSTALL_DIR"/*.sh "$INSTALL_DIR"/scripts/*.sh 2>/dev/null || true
    
    printf "%b\n" "${GREEN}Download complete!${RC}"
}

# Run the main installer
run_installer() {
    cd "$INSTALL_DIR"
    # Use exec with proper TTY to allow user input
    exec sh ./s4dutil.sh < /dev/tty
}

main() {
    check_environment
    download_scripts
    run_installer
}

main "$@"
