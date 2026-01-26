#!/bin/sh
# S4DUtil - Step 6: Configure System
# Configures timezone, locale, hostname, etc.

. "$(dirname "$0")/common.sh"

check_root
validate_env

info "Configuring system..."

###################
# Timezone
###################
info "Setting timezone to $S4D_TIMEZONE..."
arch_chroot "ln -sf /usr/share/zoneinfo/$S4D_TIMEZONE /etc/localtime"
arch_chroot "hwclock --systohc"
success "Timezone set"

###################
# Locale
###################
info "Configuring locale ($S4D_LOCALE)..."

# Uncomment the locale in locale.gen
sed -i "s/^#$S4D_LOCALE/$S4D_LOCALE/" /mnt/etc/locale.gen

# Also enable en_US.UTF-8 as fallback
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /mnt/etc/locale.gen

# Generate locales
arch_chroot "locale-gen"

# Set default locale
echo "LANG=$S4D_LOCALE" > /mnt/etc/locale.conf

success "Locale configured"

###################
# Keyboard
###################
if [ -n "$S4D_KEYMAP" ]; then
    info "Setting keyboard layout to $S4D_KEYMAP..."
    echo "KEYMAP=$S4D_KEYMAP" > /mnt/etc/vconsole.conf
    success "Keyboard layout set"
fi

###################
# Hostname
###################
info "Setting hostname to $S4D_HOSTNAME..."
echo "$S4D_HOSTNAME" > /mnt/etc/hostname

# Configure hosts file
cat > /mnt/etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $S4D_HOSTNAME.localdomain $S4D_HOSTNAME
EOF

success "Hostname configured"

###################
# Network
###################
info "Enabling NetworkManager..."
arch_chroot "systemctl enable NetworkManager"
success "NetworkManager enabled"

###################
# Initramfs
###################
info "Regenerating initramfs..."
arch_chroot "mkinitcpio -P"
success "Initramfs regenerated"

success "System configuration complete!"
