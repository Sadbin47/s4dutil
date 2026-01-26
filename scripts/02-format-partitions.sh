#!/bin/sh
# S4DUtil - Step 2: Format Partitions
# Creates filesystems on the partitions

. "$(dirname "$0")/common.sh"

check_root
validate_env

DISK="$S4D_TARGET_DISK"

info "Formatting partitions on $DISK..."

if is_uefi; then
    ###################
    # UEFI Formatting
    ###################
    EFI_PART=$(get_partition "$DISK" 1)
    SWAP_PART=$(get_partition "$DISK" 2)
    ROOT_PART=$(get_partition "$DISK" 3)
    
    # Format EFI partition as FAT32
    info "Formatting EFI partition ($EFI_PART) as FAT32..."
    mkfs.fat -F 32 -n "EFI" "$EFI_PART"
    success "EFI partition formatted"
    
    # Format swap partition
    info "Formatting swap partition ($SWAP_PART)..."
    mkswap -L "swap" "$SWAP_PART"
    success "Swap partition formatted"
    
    # Format root partition as ext4
    info "Formatting root partition ($ROOT_PART) as ext4..."
    mkfs.ext4 -L "root" -F "$ROOT_PART"
    success "Root partition formatted"
    
else
    ###################
    # BIOS Formatting
    ###################
    SWAP_PART=$(get_partition "$DISK" 1)
    ROOT_PART=$(get_partition "$DISK" 2)
    
    # Format swap partition
    info "Formatting swap partition ($SWAP_PART)..."
    mkswap -L "swap" "$SWAP_PART"
    success "Swap partition formatted"
    
    # Format root partition as ext4
    info "Formatting root partition ($ROOT_PART) as ext4..."
    mkfs.ext4 -L "root" -F "$ROOT_PART"
    success "Root partition formatted"
fi

success "All partitions formatted successfully!"
