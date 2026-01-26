#!/bin/sh
# S4DUtil - Arch Linux Installer
# Quick installer script for use with: curl -fsSL <url> | sh

set -e

RC='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'

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

# Check if running on Arch Live ISO
check_environment() {
    printf "%b\n" "${YELLOW}Checking environment...${RC}"
    
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        printf "%b\n" "${RED}Error: This script must be run as root${RC}"
        printf "%b\n" "${YELLOW}Run: sudo sh install.sh${RC}"
        exit 1
    fi
    
    # Check if on Arch Live ISO
    if [ ! -f /etc/arch-release ]; then
        printf "%b\n" "${RED}Error: This script must be run from Arch Linux Live ISO${RC}"
        exit 1
    fi
    
    # Check for internet connection
    if ! ping -c 1 archlinux.org >/dev/null 2>&1; then
        printf "%b\n" "${RED}Error: No internet connection${RC}"
        printf "%b\n" "${YELLOW}Please connect to the internet first${RC}"
        exit 1
    fi
    
    printf "%b\n" "${GREEN}Environment check passed!${RC}"
}

# Install build dependencies
install_dependencies() {
    printf "%b\n" "${YELLOW}Installing build dependencies...${RC}"
    pacman -Sy --noconfirm --needed cmake gcc git make
    printf "%b\n" "${GREEN}Dependencies installed!${RC}"
}

# Clone and build s4dutil
build_s4dutil() {
    printf "%b\n" "${YELLOW}Downloading S4DUtil...${RC}"
    
    INSTALL_DIR="/tmp/s4dutil"
    
    # Clean previous installation
    rm -rf "$INSTALL_DIR"
    
    # Clone repository
    git clone --depth 1 https://github.com/YOUR_USERNAME/s4dutil.git "$INSTALL_DIR"
    
    cd "$INSTALL_DIR"
    
    printf "%b\n" "${YELLOW}Building S4DUtil...${RC}"
    
    mkdir -p build
    cd build
    cmake ..
    make -j"$(nproc)"
    
    printf "%b\n" "${GREEN}Build complete!${RC}"
}

# Run the installer
run_installer() {
    printf "%b\n" "${CYAN}Starting S4DUtil Installer...${RC}\n"
    /tmp/s4dutil/build/s4dutil
}

# Check for pre-built binary first
check_prebuilt() {
    BINARY_URL="https://github.com/YOUR_USERNAME/s4dutil/releases/latest/download/s4dutil-linux-x86_64"
    
    printf "%b\n" "${YELLOW}Checking for pre-built binary...${RC}"
    
    if curl -fsSL -o /tmp/s4dutil_bin "$BINARY_URL" 2>/dev/null; then
        chmod +x /tmp/s4dutil_bin
        printf "%b\n" "${GREEN}Downloaded pre-built binary!${RC}"
        
        # Download scripts
        SCRIPTS_URL="https://github.com/YOUR_USERNAME/s4dutil/releases/latest/download/scripts.tar.gz"
        mkdir -p /tmp/s4dutil_scripts
        if curl -fsSL "$SCRIPTS_URL" 2>/dev/null | tar -xz -C /tmp/s4dutil_scripts; then
            printf "%b\n" "${CYAN}Starting S4DUtil Installer...${RC}\n"
            cd /tmp/s4dutil_scripts
            /tmp/s4dutil_bin
            exit 0
        fi
    fi
    
    printf "%b\n" "${YELLOW}Pre-built binary not available, building from source...${RC}"
    return 1
}

main() {
    check_environment
    
    # Try pre-built binary first, fall back to building from source
    if ! check_prebuilt; then
        install_dependencies
        build_s4dutil
        run_installer
    fi
}

main "$@"
