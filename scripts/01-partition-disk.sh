#!/bin/sh
# S4DUtil - Step 1: Partition Disk
# Creates partitions on the target disk

. "$(dirname "$0")/common.sh"

check_root
validate_env

DISK="$S4D_TARGET_DISK"

info "Partitioning disk: $DISK"
warn "This will ERASE ALL DATA on $DISK!"

# Unmount any existing partitions
unmount_disk "$DISK"

# Wipe existing partition table
info "Wiping existing partition table..."
wipefs -af "$DISK" >/dev/null 2>&1 || true
sgdisk --zap-all "$DISK" >/dev/null 2>&1 || true

if is_uefi; then
    ###################
    # UEFI Partitioning
    ###################
    info "Creating GPT partition table for UEFI..."
    
    # Calculate partition sizes
    EFI_SIZE="${S4D_EFI_SIZE:-512}"
    SWAP_SIZE="${S4D_SWAP_SIZE:-0}"
    
    if [ "$SWAP_SIZE" -eq 0 ]; then
        SWAP_SIZE=$(calculate_swap_size)
    fi
    
    info "EFI partition: ${EFI_SIZE}MB"
    info "Swap partition: ${SWAP_SIZE}MB"
    info "Root partition: remaining space"
    
    # Create partitions with sgdisk
    # 1. EFI System Partition
    sgdisk -n 1:0:+${EFI_SIZE}M -t 1:ef00 -c 1:"EFI" "$DISK"
    
    # 2. Swap partition
    sgdisk -n 2:0:+${SWAP_SIZE}M -t 2:8200 -c 2:"swap" "$DISK"
    
    # 3. Root partition (remaining space)
    sgdisk -n 3:0:0 -t 3:8300 -c 3:"root" "$DISK"
    
else
    ###################
    # BIOS Partitioning
    ###################
    info "Creating MBR partition table for BIOS..."
    
    # Calculate swap size
    SWAP_SIZE="${S4D_SWAP_SIZE:-0}"
    if [ "$SWAP_SIZE" -eq 0 ]; then
        SWAP_SIZE=$(calculate_swap_size)
    fi
    
    info "Swap partition: ${SWAP_SIZE}MB"
    info "Root partition: remaining space"
    
    # Create partitions with fdisk
    {
        echo o      # Create new MBR partition table
        echo n      # New partition (swap)
        echo p      # Primary
        echo 1      # Partition number
        echo        # First sector (default)
        echo "+${SWAP_SIZE}M"
        echo t      # Change type
        echo 82     # Linux swap
        echo n      # New partition (root)
        echo p      # Primary
        echo 2      # Partition number
        echo        # First sector (default)
        echo        # Last sector (default - use remaining)
        echo a      # Toggle bootable flag
        echo 2      # On partition 2
        echo w      # Write changes
    } | fdisk "$DISK" >/dev/null 2>&1
fi

# Wait for kernel to recognize partitions
wait_for_disk "$DISK"

# Verify partitions were created
info "Verifying partitions..."
lsblk "$DISK"

if is_uefi; then
    part1=$(get_partition "$DISK" 1)
    part2=$(get_partition "$DISK" 2)
    part3=$(get_partition "$DISK" 3)
    
    [ -b "$part1" ] || { error "EFI partition not found"; exit 1; }
    [ -b "$part2" ] || { error "Swap partition not found"; exit 1; }
    [ -b "$part3" ] || { error "Root partition not found"; exit 1; }
else
    part1=$(get_partition "$DISK" 1)
    part2=$(get_partition "$DISK" 2)
    
    [ -b "$part1" ] || { error "Swap partition not found"; exit 1; }
    [ -b "$part2" ] || { error "Root partition not found"; exit 1; }
fi

success "Disk partitioned successfully!"
