#!/bin/sh
# S4DUtil - Step 8: Install Bootloader
# Installs and configures GRUB or systemd-boot

. "$(dirname "$0")/common.sh"

check_root
validate_env

DISK="$S4D_TARGET_DISK"
BOOTLOADER="${S4D_BOOTLOADER:-grub}"

info "Installing bootloader: $BOOTLOADER"

if [ "$BOOTLOADER" = "systemd-boot" ]; then
    ###################
    # systemd-boot
    ###################
    if ! is_uefi; then
        error "systemd-boot requires UEFI. Falling back to GRUB."
        BOOTLOADER="grub"
    else
        info "Installing systemd-boot..."
        arch_chroot "bootctl install"
        
        # Create loader.conf
        cat > /mnt/boot/efi/loader/loader.conf << EOF
default arch-lqx.conf
timeout 3
console-mode max
editor no
EOF
        
        # Get root partition UUID
        ROOT_PART=$(get_partition "$DISK" 2)
        ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
        
        # Detect microcode
        INITRD_UCODE=""
        if [ -f /mnt/boot/intel-ucode.img ]; then
            INITRD_UCODE="initrd  /intel-ucode.img"
        elif [ -f /mnt/boot/amd-ucode.img ]; then
            INITRD_UCODE="initrd  /amd-ucode.img"
        fi
        
        # Create arch-lqx.conf entry for Liquorix kernel
        cat > /mnt/boot/efi/loader/entries/arch-lqx.conf << EOF
title   Arch Linux (Liquorix)
linux   /vmlinuz-linux-lqx
$INITRD_UCODE
initrd  /initramfs-linux-lqx.img
options root=UUID=$ROOT_UUID rw
EOF
        
        success "systemd-boot installed with Liquorix kernel"
    fi
fi

if [ "$BOOTLOADER" = "grub" ]; then
    ###################
    # GRUB
    ###################
    if is_uefi; then
        info "Installing GRUB for UEFI..."
        arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB"
    else
        info "Installing GRUB for BIOS..."
        arch_chroot "grub-install --target=i386-pc $DISK"
    fi
    
    # Generate GRUB config
    info "Generating GRUB configuration..."
    arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
    
    success "GRUB installed"
fi

success "Bootloader installation complete!"
