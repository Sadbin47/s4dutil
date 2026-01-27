#!/bin/sh
# S4DUtil - Step 7: Setup Users
# Creates users and sets passwords

. "$(dirname "$0")/common.sh"

check_root

info "Setting up users..."

###################
# Root Password
###################
if [ -n "$S4D_ROOT_PASSWORD" ]; then
    info "Setting root password..."
    # Write password to a temp file in chroot to avoid shell escaping issues
    printf '%s:%s\n' "root" "$S4D_ROOT_PASSWORD" > /mnt/tmp/.passwd_root
    arch_chroot "chpasswd < /tmp/.passwd_root"
    rm -f /mnt/tmp/.passwd_root
    success "Root password set"
else
    warn "No root password specified!"
fi

###################
# Create User
###################
if [ -n "$S4D_USERNAME" ]; then
    info "Creating user: $S4D_USERNAME..."
    
    # Create user with home directory
    arch_chroot "useradd -m -G wheel -s /bin/bash $S4D_USERNAME"
    
    # Set user password
    if [ -n "$S4D_USER_PASSWORD" ]; then
        # Write password to a temp file in chroot to avoid shell escaping issues
        printf '%s:%s\n' "$S4D_USERNAME" "$S4D_USER_PASSWORD" > /mnt/tmp/.passwd_user
        arch_chroot "chpasswd < /tmp/.passwd_user"
        rm -f /mnt/tmp/.passwd_user
        success "User password set"
    fi
    
    # Enable sudo for wheel group
    info "Enabling sudo for wheel group..."
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
    
    success "User $S4D_USERNAME created"
else
    info "No additional user requested"
fi

success "User setup complete!"
