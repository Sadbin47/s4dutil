#!/bin/sh
# S4DUtil - Common functions for installation scripts
# This file is sourced by all installation scripts

set -e

# Colors for output
RC='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'

# Print functions
info() {
    printf "%b\n" "${CYAN}[INFO]${RC} $1"
}

success() {
    printf "%b\n" "${GREEN}[OK]${RC} $1"
}

warn() {
    printf "%b\n" "${YELLOW}[WARN]${RC} $1"
}

error() {
    printf "%b\n" "${RED}[ERROR]${RC} $1"
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root"
        exit 1
    fi
}

# Check if on Arch Live ISO
check_live_iso() {
    if [ ! -f /etc/arch-release ]; then
        error "This script must be run on Arch Linux"
        exit 1
    fi
}

# Check internet connection
check_internet() {
    if ! ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
        error "No internet connection"
        exit 1
    fi
}

# Check if UEFI or BIOS
is_uefi() {
    [ -d /sys/firmware/efi ]
}

# Get RAM size in MB
get_ram_mb() {
    awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo
}

# Calculate swap size based on RAM
calculate_swap_size() {
    ram_mb=$(get_ram_mb)
    
    if [ "$ram_mb" -le 2048 ]; then
        # RAM <= 2GB: swap = 2x RAM
        echo $((ram_mb * 2))
    elif [ "$ram_mb" -le 8192 ]; then
        # RAM <= 8GB: swap = RAM
        echo "$ram_mb"
    else
        # RAM > 8GB: swap = 8GB
        echo 8192
    fi
}

# Wait for disk to be ready
wait_for_disk() {
    disk="$1"
    info "Waiting for disk $disk to be ready..."
    sleep 1
    partprobe "$disk" 2>/dev/null || true
    sleep 1
}

# Arch-chroot wrapper
arch_chroot() {
    arch-chroot /mnt /bin/bash -c "$1"
}

# Get partition suffix (handles nvme disks)
get_part_suffix() {
    disk="$1"
    case "$disk" in
        /dev/nvme*|/dev/mmcblk*)
            echo "p"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Get partition path
get_partition() {
    disk="$1"
    num="$2"
    suffix=$(get_part_suffix "$disk")
    echo "${disk}${suffix}${num}"
}

# Unmount all partitions from a disk
unmount_disk() {
    disk="$1"
    info "Unmounting any existing partitions on $disk..."
    
    # Unmount /mnt subdirectories first
    umount -R /mnt 2>/dev/null || true
    
    # Unmount all partitions on the disk
    for part in "${disk}"*; do
        if [ -b "$part" ] && [ "$part" != "$disk" ]; then
            umount "$part" 2>/dev/null || true
        fi
    done
    
    # Disable any swap on the disk
    for part in "${disk}"*; do
        if [ -b "$part" ]; then
            swapoff "$part" 2>/dev/null || true
        fi
    done
}

# Validate environment variables
validate_env() {
    required_vars="S4D_TARGET_DISK S4D_HOSTNAME S4D_TIMEZONE S4D_LOCALE"
    
    for var in $required_vars; do
        eval "value=\$$var"
        if [ -z "$value" ]; then
            error "Required environment variable $var is not set"
            exit 1
        fi
    done
}
