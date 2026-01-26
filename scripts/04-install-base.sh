#!/bin/sh
# S4DUtil - Step 4: Install Base System
# Installs the base Arch Linux system using pacstrap

. "$(dirname "$0")/common.sh"

check_root
check_internet

info "Installing base system..."

# Base packages (no kernel - we'll install Liquorix after)
BASE_PACKAGES="base linux-firmware mkinitcpio"

# Essential packages
ESSENTIAL_PACKAGES="base-devel sudo networkmanager vim nano git curl wget xfsprogs"

# Bootloader packages
if [ "$S4D_BOOTLOADER" = "systemd-boot" ]; then
    BOOT_PACKAGES="efibootmgr"
else
    if is_uefi; then
        BOOT_PACKAGES="grub efibootmgr os-prober"
    else
        BOOT_PACKAGES="grub os-prober"
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

# Run pacstrap with --noconfirm equivalent (pacstrap doesn't have it but pacman inside does)
info "Running pacstrap (this may take a while)..."
pacstrap -K /mnt $ALL_PACKAGES </dev/null

# Install Liquorix Kernel (run non-interactively)
info "Installing Liquorix Kernel..."
arch_chroot "curl -s 'https://liquorix.net/install-liquorix.sh' | bash -s -- --noconfirm" </dev/null || \
    arch_chroot "pacman -S --noconfirm linux-lqx linux-lqx-headers" </dev/null || true
success "Liquorix kernel installed"

success "Base system installed successfully!"
