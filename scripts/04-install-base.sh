#!/bin/sh
# S4DUtil - Step 4: Install Base System
# Installs the base Arch Linux system using pacstrap

. "$(dirname "$0")/common.sh"

check_root
check_internet

info "Installing base system..."

# Base packages
BASE_PACKAGES="base linux linux-firmware"

# Essential packages
ESSENTIAL_PACKAGES="base-devel sudo networkmanager vim nano"

# Bootloader packages
if [ "$S4D_BOOTLOADER" = "systemd-boot" ]; then
    BOOT_PACKAGES="efibootmgr"
else
    if is_uefi; then
        BOOT_PACKAGES="grub efibootmgr"
    else
        BOOT_PACKAGES="grub"
    fi
fi

# CPU microcode
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
case "$CPU_VENDOR" in
    GenuineIntel)
        MICROCODE="intel-ucode"
        info "Intel CPU detected, adding intel-ucode"
        ;;
    AuthenticAMD)
        MICROCODE="amd-ucode"
        info "AMD CPU detected, adding amd-ucode"
        ;;
    *)
        MICROCODE=""
        warn "Unknown CPU vendor, skipping microcode"
        ;;
esac

# Combine all packages
ALL_PACKAGES="$BASE_PACKAGES $ESSENTIAL_PACKAGES $BOOT_PACKAGES $MICROCODE"

info "Packages to install:"
echo "  $ALL_PACKAGES"

# Update mirrorlist for faster downloads (optional)
info "Updating mirror list..."
if command -v reflector >/dev/null 2>&1; then
    reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || true
fi

# Run pacstrap
info "Running pacstrap (this may take a while)..."
pacstrap -K /mnt $ALL_PACKAGES

success "Base system installed successfully!"
