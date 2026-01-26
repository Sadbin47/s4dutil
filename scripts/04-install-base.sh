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
ESSENTIAL_PACKAGES="base-devel sudo networkmanager vim nano git curl wget"

# Filesystem tools based on selection
FS="${S4D_FILESYSTEM:-ext4}"
case "$FS" in
    xfs)
        FS_PACKAGES="xfsprogs"
        ;;
    btrfs)
        FS_PACKAGES="btrfs-progs"
        ;;
    *)
        FS_PACKAGES="e2fsprogs"
        ;;
esac

# Bootloader packages based on selection
BOOTLOADER="${S4D_BOOTLOADER:-grub}"
info "Selected bootloader: $BOOTLOADER"

if [ "$BOOTLOADER" = "systemd-boot" ]; then
    # systemd-boot only needs efibootmgr (and only works on UEFI)
    if is_uefi; then
        BOOT_PACKAGES="efibootmgr"
        info "systemd-boot selected (UEFI mode)"
    else
        warn "systemd-boot requires UEFI - will fallback to GRUB"
        BOOT_PACKAGES="grub os-prober"
    fi
else
    # GRUB bootloader
    if is_uefi; then
        BOOT_PACKAGES="grub efibootmgr os-prober"
        info "GRUB selected (UEFI mode)"
    else
        BOOT_PACKAGES="grub os-prober"
        info "GRUB selected (BIOS mode)"
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
ALL_PACKAGES="$BASE_PACKAGES $ESSENTIAL_PACKAGES $FS_PACKAGES $BOOT_PACKAGES $MICROCODE"

info "Packages to install:"
echo "  Base:       $BASE_PACKAGES"
echo "  Essential:  $ESSENTIAL_PACKAGES"
echo "  Filesystem: $FS_PACKAGES"
echo "  Bootloader: $BOOT_PACKAGES"
[ -n "$MICROCODE" ] && echo "  Microcode:  $MICROCODE"

# Update mirrorlist for faster downloads (optional)
info "Updating mirror list..."
if command -v reflector >/dev/null 2>&1; then
    reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || true
fi

# Run pacstrap with --noconfirm equivalent (pacstrap doesn't have it but pacman inside does)
info "Running pacstrap (this may take a while)..."
pacstrap -K /mnt $ALL_PACKAGES </dev/null

# ═══════════════════════════════════════════════════════════════
#                    INSTALL LIQUORIX KERNEL
# ═══════════════════════════════════════════════════════════════

info "Installing Liquorix Kernel..."

# Method 1: Try the official Liquorix installer script
install_liquorix_script() {
    arch_chroot "curl -fsSL 'https://liquorix.net/install-liquorix.sh' | bash -s -- --noconfirm" </dev/null
}

# Method 2: Install from chaotic-aur (has pre-built Liquorix packages)
install_liquorix_chaotic() {
    info "Setting up Chaotic-AUR for Liquorix kernel..."
    
    # Add chaotic-aur keyring and mirrorlist
    arch_chroot "pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com" </dev/null
    arch_chroot "pacman-key --lsign-key 3056513887B78AEB" </dev/null
    arch_chroot "pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'" </dev/null
    arch_chroot "pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'" </dev/null
    
    # Add chaotic-aur to pacman.conf
    if ! grep -q "chaotic-aur" /mnt/etc/pacman.conf; then
        cat >> /mnt/etc/pacman.conf << 'EOF'

# Chaotic-AUR repository
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
    fi
    
    # Sync and install
    arch_chroot "pacman -Sy --noconfirm linux-lqx linux-lqx-headers" </dev/null
}

# Method 3: Install standard Linux kernel as fallback
install_linux_fallback() {
    warn "Installing standard Linux kernel as fallback..."
    arch_chroot "pacman -S --noconfirm linux linux-headers" </dev/null
}

# Try installation methods in order
if install_liquorix_script 2>/dev/null; then
    success "Liquorix kernel installed via official script"
elif install_liquorix_chaotic 2>/dev/null; then
    success "Liquorix kernel installed via Chaotic-AUR"
else
    warn "Could not install Liquorix kernel, installing standard Linux kernel..."
    install_linux_fallback
    success "Standard Linux kernel installed as fallback"
fi

# Verify kernel installation
info "Verifying kernel installation..."
if [ -f /mnt/boot/vmlinuz-linux-lqx ]; then
    success "Liquorix kernel verified: /mnt/boot/vmlinuz-linux-lqx"
elif [ -f /mnt/boot/vmlinuz-linux ]; then
    success "Standard kernel verified: /mnt/boot/vmlinuz-linux"
else
    warn "No kernel found in /mnt/boot - this may cause boot issues!"
fi

# List installed kernels
info "Installed kernels:"
ls -la /mnt/boot/vmlinuz-* 2>/dev/null || warn "No kernel vmlinuz files found"

success "Base system installed successfully!"
