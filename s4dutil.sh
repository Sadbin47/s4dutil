#!/bin/sh
# S4DUtil - Main Installer Script (Pure Shell - No Dependencies!)
# This provides a text-based menu for Arch Linux installation

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/scripts/common.sh"

# Configuration variables (set during wizard)
TARGET_DISK=""
HOSTNAME="archlinux"
TIMEZONE="UTC"
LOCALE="en_US.UTF-8"
KEYMAP="us"
ROOT_PASSWORD=""
USERNAME=""
USER_PASSWORD=""
BOOTLOADER="grub"

# Display header
show_header() {
    clear
    printf "%b\n" "${CYAN}${BOLD}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║   ____  _  _   ____  _   _ _   _ _                            ║
║  / ___|| || | |  _ \| | | | |_(_) |                           ║
║  \___ \| || |_| | | | | | | __| | |                           ║
║   ___) |__   _| |_| | |_| | |_| | |                           ║
║  |____/   |_| |____/ \___/ \__|_|_|                           ║
║                                                               ║
║           Arch Linux Installer v1.0.0                         ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    printf "%b\n\n" "${RC}"
}

# Show system information
show_system_info() {
    show_header
    printf "%b\n" "${BOLD}System Information${RC}"
    printf "%b\n" "────────────────────────────────────────"
    
    # Boot mode
    if [ -d /sys/firmware/efi ]; then
        printf "  Boot Mode:    %b\n" "${GREEN}UEFI${RC}"
        IS_UEFI=1
    else
        printf "  Boot Mode:    %b\n" "${YELLOW}BIOS (Legacy)${RC}"
        IS_UEFI=0
    fi
    
    # Internet
    if ping -c 1 -W 2 archlinux.org >/dev/null 2>&1; then
        printf "  Internet:     %b\n" "${GREEN}Connected${RC}"
    else
        printf "  Internet:     %b\n" "${RED}Not Connected${RC}"
    fi
    
    # CPU
    CPU=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
    printf "  CPU:          %s\n" "$CPU"
    
    # RAM
    RAM=$(awk '/MemTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)
    printf "  RAM:          %s\n" "$RAM"
    
    # Architecture
    ARCH=$(uname -m)
    printf "  Architecture: %s\n" "$ARCH"
    
    printf "\n"
}

# Select disk
select_disk() {
    show_header
    printf "%b\n" "${BOLD}${RED}⚠ WARNING: ALL DATA ON SELECTED DISK WILL BE ERASED! ⚠${RC}"
    printf "%b\n\n" "────────────────────────────────────────"
    
    printf "%b\n\n" "${BOLD}Available Disks:${RC}"
    
    # List disks
    i=1
    DISKS=""
    while IFS= read -r line; do
        name=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $2}')
        DISKS="$DISKS /dev/$name"
        printf "  %b) /dev/%s (%s)\n" "${CYAN}$i${RC}" "$name" "$size"
        i=$((i + 1))
    done << EOF
$(lsblk -d -n -o NAME,SIZE | grep -E '^(sd|nvme|vd|hd)')
EOF
    
    printf "\n"
    printf "  %b) Go Back\n" "${YELLOW}0${RC}"
    printf "\n"
    
    printf "Select disk [1-%d]: " "$((i - 1))"
    read -r choice
    
    if [ "$choice" = "0" ]; then
        return 1
    fi
    
    # Get selected disk
    TARGET_DISK=$(echo "$DISKS" | tr ' ' '\n' | sed -n "${choice}p")
    
    if [ -z "$TARGET_DISK" ] || [ ! -b "$TARGET_DISK" ]; then
        printf "%b\n" "${RED}Invalid selection!${RC}"
        sleep 2
        select_disk
        return
    fi
    
    # Confirm
    printf "\n%b" "${RED}Are you sure you want to use $TARGET_DISK? ALL DATA WILL BE LOST! [y/N]: ${RC}"
    read -r confirm
    case "$confirm" in
        [Yy]*)
            printf "%b\n" "${GREEN}Selected: $TARGET_DISK${RC}"
            export S4D_TARGET_DISK="$TARGET_DISK"
            sleep 1
            ;;
        *)
            select_disk
            ;;
    esac
}

# Configure system settings
configure_system() {
    show_header
    printf "%b\n" "${BOLD}System Configuration${RC}"
    printf "%b\n\n" "────────────────────────────────────────"
    
    # Hostname
    printf "Hostname [%s]: " "$HOSTNAME"
    read -r input
    [ -n "$input" ] && HOSTNAME="$input"
    
    # Timezone selection
    printf "\n%b\n" "${BOLD}Common Timezones:${RC}"
    printf "  1) UTC\n"
    printf "  2) America/New_York\n"
    printf "  3) America/Los_Angeles\n"
    printf "  4) Europe/London\n"
    printf "  5) Europe/Berlin\n"
    printf "  6) Asia/Tokyo\n"
    printf "  7) Asia/Shanghai\n"
    printf "  8) Asia/Kolkata\n"
    printf "  9) Custom\n"
    printf "Select timezone [1]: "
    read -r tz_choice
    
    case "$tz_choice" in
        2) TIMEZONE="America/New_York" ;;
        3) TIMEZONE="America/Los_Angeles" ;;
        4) TIMEZONE="Europe/London" ;;
        5) TIMEZONE="Europe/Berlin" ;;
        6) TIMEZONE="Asia/Tokyo" ;;
        7) TIMEZONE="Asia/Shanghai" ;;
        8) TIMEZONE="Asia/Kolkata" ;;
        9) 
            printf "Enter timezone (e.g., America/New_York): "
            read -r TIMEZONE
            ;;
        *) TIMEZONE="UTC" ;;
    esac
    
    # Locale
    printf "\nLocale [%s]: " "$LOCALE"
    read -r input
    [ -n "$input" ] && LOCALE="$input"
    
    # Keymap
    printf "Keyboard layout [%s]: " "$KEYMAP"
    read -r input
    [ -n "$input" ] && KEYMAP="$input"
    
    # Bootloader
    if [ "$IS_UEFI" = "1" ]; then
        printf "\n%b\n" "${BOLD}Bootloader:${RC}"
        printf "  1) GRUB\n"
        printf "  2) systemd-boot\n"
        printf "Select [1]: "
        read -r boot_choice
        case "$boot_choice" in
            2) BOOTLOADER="systemd-boot" ;;
            *) BOOTLOADER="grub" ;;
        esac
    else
        BOOTLOADER="grub"
    fi
    
    # Export variables
    export S4D_HOSTNAME="$HOSTNAME"
    export S4D_TIMEZONE="$TIMEZONE"
    export S4D_LOCALE="$LOCALE"
    export S4D_KEYMAP="$KEYMAP"
    export S4D_BOOTLOADER="$BOOTLOADER"
    export S4D_IS_UEFI="$IS_UEFI"
}

# Setup users
setup_users() {
    show_header
    printf "%b\n" "${BOLD}User Setup${RC}"
    printf "%b\n\n" "────────────────────────────────────────"
    
    # Root password
    while true; do
        printf "Enter root password: "
        stty -echo
        read -r ROOT_PASSWORD
        stty echo
        printf "\n"
        
        printf "Confirm root password: "
        stty -echo
        read -r confirm
        stty echo
        printf "\n"
        
        if [ "$ROOT_PASSWORD" = "$confirm" ] && [ -n "$ROOT_PASSWORD" ]; then
            break
        else
            printf "%b\n\n" "${RED}Passwords don't match or empty. Try again.${RC}"
        fi
    done
    
    # Create user?
    printf "\nCreate a regular user? [Y/n]: "
    read -r create_user
    
    case "$create_user" in
        [Nn]*)
            USERNAME=""
            ;;
        *)
            printf "Username: "
            read -r USERNAME
            
            while true; do
                printf "Password for %s: " "$USERNAME"
                stty -echo
                read -r USER_PASSWORD
                stty echo
                printf "\n"
                
                printf "Confirm password: "
                stty -echo
                read -r confirm
                stty echo
                printf "\n"
                
                if [ "$USER_PASSWORD" = "$confirm" ] && [ -n "$USER_PASSWORD" ]; then
                    break
                else
                    printf "%b\n\n" "${RED}Passwords don't match or empty. Try again.${RC}"
                fi
            done
            ;;
    esac
    
    export S4D_ROOT_PASSWORD="$ROOT_PASSWORD"
    export S4D_USERNAME="$USERNAME"
    export S4D_USER_PASSWORD="$USER_PASSWORD"
}

# Show summary
show_summary() {
    show_header
    printf "%b\n" "${BOLD}Installation Summary${RC}"
    printf "%b\n\n" "────────────────────────────────────────"
    
    printf "  Target Disk:   %b\n" "${CYAN}$TARGET_DISK${RC}"
    printf "  Boot Mode:     %s\n" "$([ "$IS_UEFI" = "1" ] && echo "UEFI" || echo "BIOS")"
    printf "  Bootloader:    %s\n" "$BOOTLOADER"
    printf "  ────────────────────────────────────\n"
    printf "  Hostname:      %s\n" "$HOSTNAME"
    printf "  Timezone:      %s\n" "$TIMEZONE"
    printf "  Locale:        %s\n" "$LOCALE"
    printf "  Keymap:        %s\n" "$KEYMAP"
    printf "  ────────────────────────────────────\n"
    printf "  Root Password: ********\n"
    printf "  Username:      %s\n" "${USERNAME:-"(none)"}"
    printf "\n"
    
    printf "%b\n\n" "${RED}${BOLD}⚠ WARNING: This will ERASE ALL DATA on $TARGET_DISK!${RC}"
    printf "Proceed with installation? [y/N]: "
    read -r confirm
    
    case "$confirm" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

# Run installation
run_installation() {
    show_header
    printf "%b\n" "${BOLD}Installing Arch Linux...${RC}"
    printf "%b\n\n" "────────────────────────────────────────"
    
    SCRIPTS_DIR="$SCRIPT_DIR/scripts"
    
    steps="00-check-environment.sh
01-partition-disk.sh
02-format-partitions.sh
03-mount-partitions.sh
04-install-base.sh
05-generate-fstab.sh
06-configure-system.sh
07-setup-users.sh
08-install-bootloader.sh
09-finalize.sh"
    
    total=$(echo "$steps" | wc -l)
    current=0
    
    for step in $steps; do
        current=$((current + 1))
        step_name=$(echo "$step" | sed 's/[0-9]*-//;s/\.sh//;s/-/ /g')
        
        printf "[%d/%d] %s...\n" "$current" "$total" "$step_name"
        
        if sh "$SCRIPTS_DIR/$step"; then
            printf "%b\n\n" "${GREEN}✓ Done${RC}"
        else
            printf "%b\n" "${RED}✗ Failed!${RC}"
            printf "\nInstallation failed at step: %s\n" "$step"
            printf "Check the error above and try again.\n"
            exit 1
        fi
    done
    
    printf "\n"
    printf "%b\n" "${GREEN}${BOLD}════════════════════════════════════════${RC}"
    printf "%b\n" "${GREEN}${BOLD}   Installation Complete!${RC}"
    printf "%b\n" "${GREEN}${BOLD}════════════════════════════════════════${RC}"
    printf "\n"
    printf "You can now reboot into your new system.\n"
    printf "%b\n\n" "${YELLOW}Remember to remove the installation media!${RC}"
    
    printf "Reboot now? [Y/n]: "
    read -r reboot_choice
    case "$reboot_choice" in
        [Nn]*) ;;
        *) reboot ;;
    esac
}

# Main menu
main_menu() {
    while true; do
        show_header
        show_system_info
        
        printf "%b\n" "${BOLD}Main Menu${RC}"
        printf "%b\n\n" "────────────────────────────────────────"
        printf "  %b) Start Installation\n" "${CYAN}1${RC}"
        printf "  %b) View System Info\n" "${CYAN}2${RC}"
        printf "  %b) Open Shell\n" "${CYAN}3${RC}"
        printf "  %b) Exit\n" "${CYAN}0${RC}"
        printf "\n"
        printf "Select option: "
        read -r choice
        
        case "$choice" in
            1)
                if select_disk; then
                    configure_system
                    setup_users
                    if show_summary; then
                        run_installation
                        exit 0
                    fi
                fi
                ;;
            2)
                show_system_info
                printf "\nPress Enter to continue..."
                read -r _
                ;;
            3)
                printf "\nType 'exit' to return to installer.\n\n"
                /bin/sh
                ;;
            0)
                printf "\nExiting...\n"
                exit 0
                ;;
        esac
    done
}

# Entry point
main() {
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        printf "%b\n" "${RED}Error: This script must be run as root${RC}"
        exit 1
    fi
    
    main_menu
}

main "$@"
