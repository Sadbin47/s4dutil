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
timedatectl set-ntp true 2>/dev/null || true

# Update pacman keyring (with timeout to prevent hanging)
pacman -Sy --noconfirm archlinux-keyring >/dev/null 2>&1 &
PACMAN_PID=$!
sleep 30 && kill -0 $PACMAN_PID 2>/dev/null && kill $PACMAN_PID 2>/dev/null &
wait $PACMAN_PID 2>/dev/null || true

success "All environment checks passed!"
