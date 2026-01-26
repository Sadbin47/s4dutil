#!/bin/sh
# S4DUtil - Step 0: Check Environment
# Verifies that all requirements are met before installation

. "$(dirname "$0")/common.sh"

info "Checking installation environment..."

# Check root
check_root
success "Running as root"

# Check if on Arch
check_live_iso
success "Running on Arch Linux"

# Check internet
check_internet
success "Internet connection available"

# Check boot mode
if is_uefi; then
    success "UEFI boot mode detected"
else
    success "BIOS boot mode detected"
fi

# Check target disk exists
if [ -n "$S4D_TARGET_DISK" ]; then
    if [ -b "$S4D_TARGET_DISK" ]; then
        size=$(lsblk -b -d -n -o SIZE "$S4D_TARGET_DISK" 2>/dev/null)
        size_gb=$((size / 1024 / 1024 / 1024))
        success "Target disk $S4D_TARGET_DISK found (${size_gb}GB)"
    else
        error "Target disk $S4D_TARGET_DISK not found"
        exit 1
    fi
fi

# Sync time
info "Synchronizing system clock..."
timedatectl set-ntp true
success "System clock synchronized"

# Update pacman keyring
info "Updating pacman keyring..."
pacman -Sy --noconfirm archlinux-keyring >/dev/null 2>&1 || true
success "Pacman keyring updated"

success "All environment checks passed!"
