#!/bin/sh
# S4DUtil - Step 1: Partition Disk
# Creates partitions on the target disk (No swap partition - uses swap file)

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
    # UEFI Partitioning (GPT: EFI + Root)
    ###################
    info "Creating GPT partition table for UEFI..."
    
    EFI_SIZE="${S4D_EFI_SIZE:-512}"
    
    info "EFI partition: ${EFI_SIZE}MB"
    info "Root partition: remaining space (XFS)"
    
    # Create partitions with sgdisk
    # 1. EFI System Partition
    sgdisk -n 1:0:+${EFI_SIZE}M -t 1:ef00 -c 1:"EFI" "$DISK"
    
    # 2. Root partition (remaining space)
    sgdisk -n 2:0:0 -t 2:8300 -c 2:"root" "$DISK"
    
else
    ###################
    # BIOS Partitioning (MBR: Root only)
    ###################
    info "Creating MBR partition table for BIOS..."
    info "Root partition: entire disk (XFS)"
    
    # Create single root partition with fdisk
    {
        echo o      # Create new MBR partition table
        echo n      # New partition (root)
        echo p      # Primary
        echo 1      # Partition number
        echo        # First sector (default)
        echo        # Last sector (default - use all)
        echo a      # Toggle bootable flag
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
    
    [ -b "$part1" ] || { error "EFI partition not found"; exit 1; }
    [ -b "$part2" ] || { error "Root partition not found"; exit 1; }
else
    part1=$(get_partition "$DISK" 1)
    
    [ -b "$part1" ] || { error "Root partition not found"; exit 1; }
fi

success "Disk partitioned successfully!"
