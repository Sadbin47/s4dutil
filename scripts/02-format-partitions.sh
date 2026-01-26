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
    ROOT_PART=$(get_partition "$DISK" 2)
    
    # Format EFI partition as FAT32
    info "Formatting EFI partition ($EFI_PART) as FAT32..."
    mkfs.fat -F 32 -n "EFI" "$EFI_PART"
    success "EFI partition formatted"
    
    # Format root partition as XFS
    info "Formatting root partition ($ROOT_PART) as XFS..."
    mkfs.xfs -f -L "root" "$ROOT_PART"
    success "Root partition formatted (XFS)"
    
else
    ###################
    # BIOS Formatting
    ###################
    ROOT_PART=$(get_partition "$DISK" 1)
    
    # Format root partition as XFS
    info "Formatting root partition ($ROOT_PART) as XFS..."
    mkfs.xfs -f -L "root" "$ROOT_PART"
    success "Root partition formatted (XFS)"
fi

success "All partitions formatted successfully!"
