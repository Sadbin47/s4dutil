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

# Display header with gradient effect
show_header() {
    clear
    printf "\n"
    printf "  %b╔═══════════════════════════════════════════════════════════════╗%b\n" "${PURPLE}" "${RC}"
    printf "  %b║%b   %b____  _  _   ____  _   _ _   _ _%b                            %b║%b\n" "${PURPLE}" "${RC}" "${GRAD1}${BOLD}" "${RC}" "${PURPLE}" "${RC}"
    printf "  %b║%b  %b/ ___|| || | |  _ \\| | | | |_(_) |%b                           %b║%b\n" "${PURPLE}" "${RC}" "${GRAD2}${BOLD}" "${RC}" "${PURPLE}" "${RC}"
    printf "  %b║%b  %b\\___ \\| || |_| | | | | | | __| | |%b                           %b║%b\n" "${PURPLE}" "${RC}" "${GRAD3}${BOLD}" "${RC}" "${PURPLE}" "${RC}"
    printf "  %b║%b   %b___) |__   _| |_| | |_| | |_| | |%b                           %b║%b\n" "${PURPLE}" "${RC}" "${GRAD4}${BOLD}" "${RC}" "${PURPLE}" "${RC}"
    printf "  %b║%b  %b|____/   |_| |____/ \\___/ \\__|_|_|%b                           %b║%b\n" "${PURPLE}" "${RC}" "${GRAD5}${BOLD}" "${RC}" "${PURPLE}" "${RC}"
    printf "  %b║%b                                                               %b║%b\n" "${PURPLE}" "${RC}" "${PURPLE}" "${RC}"
    printf "  %b║%b           %b✨ Arch Linux Installer%b %bv1.0.0%b                    %b║%b\n" "${PURPLE}" "${RC}" "${WHITE}${BOLD}" "${RC}" "${YELLOW}${BOLD}" "${RC}" "${PURPLE}" "${RC}"
    printf "  %b╚═══════════════════════════════════════════════════════════════╝%b\n" "${PURPLE}" "${RC}"
    printf "\n"
}

# Show system information
show_system_info() {
    show_header
    
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${CYAN}" "${RC}"
    printf "  %b│%b %b⚙  System Information%b                       %b│%b\n" "${CYAN}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${CYAN}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${CYAN}" "${RC}"
    printf "\n"
    
    # Boot mode
    if [ -d /sys/firmware/efi ]; then
        printf "    %b󰍛%b  Boot Mode      %b│%b  %b● UEFI%b\n" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${GREEN}${BOLD}" "${RC}"
        IS_UEFI=1
    else
        printf "    %b󰍛%b  Boot Mode      %b│%b  %b● BIOS (Legacy)%b\n" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${YELLOW}${BOLD}" "${RC}"
        IS_UEFI=0
    fi
    
    # Internet
    if ping -c 1 -W 2 archlinux.org >/dev/null 2>&1; then
        printf "    %b󰖩%b  Internet       %b│%b  %b● Connected%b\n" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${GREEN}${BOLD}" "${RC}"
    else
        printf "    %b󰖪%b  Internet       %b│%b  %b● Not Connected%b\n" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${RED}${BOLD}" "${RC}"
    fi
    
    # CPU
    CPU=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs | cut -c1-30)
    printf "    %b󰻠%b  CPU            %b│%b  %b%s%b\n" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "$CPU" "${RC}"
    
    # RAM
    RAM=$(awk '/MemTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)
    printf "    %b󰍛%b  RAM            %b│%b  %b%s%b\n" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "$RAM" "${RC}"
    
    # Architecture
    ARCH=$(uname -m)
    printf "    %b󰘚%b  Architecture   %b│%b  %b%s%b\n" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "$ARCH" "${RC}"
    
    printf "\n"
    draw_line 50
    printf "\n"
}

# Select disk
select_disk() {
    show_header
    
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${RED}" "${RC}"
    printf "  %b│%b %b⚠  WARNING: ALL DATA WILL BE ERASED!%b       %b│%b\n" "${RED}" "${RC}" "${BOLD}${YELLOW}${BLINK}" "${RC}" "${RED}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${RED}" "${RC}"
    printf "\n"
    
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${CYAN}" "${RC}"
    printf "  %b│%b %b󰋊  Available Disks%b                          %b│%b\n" "${CYAN}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${CYAN}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${CYAN}" "${RC}"
    printf "\n"
    
    # List disks and store in array-like format
    DISK_LIST=$(lsblk -d -n -o NAME,SIZE,MODEL 2>/dev/null | grep -E '^(sd|nvme|vd|hd)' || true)
    
    if [ -z "$DISK_LIST" ]; then
        err "No disks found!"
        sleep 2
        return 1
    fi
    
    i=1
    echo "$DISK_LIST" | while IFS= read -r line; do
        name=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $2}')
        model=$(echo "$line" | awk '{$1=$2=""; print $0}' | xargs | cut -c1-20)
        printf "    %b%b %d %b  %b/dev/%s%b  %b(%s)%b  %b%s%b\n" "${CYAN}${BOLD}" "󰋊" "$i" "${RC}" "${WHITE}${BOLD}" "$name" "${RC}" "${GREEN}" "$size" "${RC}" "${DIM}" "$model" "${RC}"
        i=$((i + 1))
    done
    
    disk_count=$(echo "$DISK_LIST" | wc -l)
    
    printf "\n"
    printf "    %b%b 0 %b  %bGo Back%b\n" "${YELLOW}${BOLD}" "󰁍" "${RC}" "${YELLOW}" "${RC}"
    printf "\n"
    
    draw_line 50
    printf "  %bSelect disk%b %b[1-%d]%b: " "${WHITE}" "${RC}" "${DIM}" "$disk_count" "${RC}"
    read -r choice
    
    if [ "$choice" = "0" ]; then
        return 1
    fi
    
    # Validate choice is a number
    if ! echo "$choice" | grep -qE '^[0-9]+$'; then
        err "Invalid selection!"
        sleep 2
        select_disk
        return
    fi
    
    # Get selected disk name from the list
    selected_line=$(echo "$DISK_LIST" | sed -n "${choice}p")
    disk_name=$(echo "$selected_line" | awk '{print $1}')
    TARGET_DISK="/dev/$disk_name"
    
    if [ -z "$disk_name" ] || [ ! -b "$TARGET_DISK" ]; then
        err "Invalid selection!"
        sleep 2
        select_disk
        return
    fi
    
    # Confirm
    printf "\n"
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${RED}" "${RC}"
    printf "  %b│%b  %bALL DATA ON %s WILL BE LOST!%b    %b│%b\n" "${RED}" "${RC}" "${BOLD}${WHITE}" "$TARGET_DISK" "${RC}" "${RED}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${RED}" "${RC}"
    printf "\n  %bAre you sure?%b %b[y/N]%b: " "${WHITE}" "${RC}" "${DIM}" "${RC}"
    read -r confirm
    case "$confirm" in
        [Yy]*)
            ok "Selected: $TARGET_DISK"
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
    
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${CYAN}" "${RC}"
    printf "  %b│%b %b󰒓  System Configuration%b                     %b│%b\n" "${CYAN}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${CYAN}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${CYAN}" "${RC}"
    printf "\n"
    
    # Hostname
    printf "    %b󰇄%b  %bHostname%b %b[Default: %s]%b\n" "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${DIM}${CYAN}" "$HOSTNAME" "${RC}"
    printf "       %b➜%b " "${CYAN}" "${RC}"
    read -r input
    [ -n "$input" ] && HOSTNAME="$input"
    
    # Timezone selection
    printf "\n"
    printf "    %b󰥔%b  %bTimezone%b %b[Default: %s]%b\n" "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${DIM}${CYAN}" "$TIMEZONE" "${RC}"
    printf "\n"
    printf "      %b1%b) %bUTC%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b2%b) %bAmerica/New_York%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b3%b) %bAmerica/Los_Angeles%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b4%b) %bEurope/London%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b5%b) %bEurope/Berlin%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b6%b) %bAsia/Tokyo%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b7%b) %bAsia/Shanghai%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b8%b) %bAsia/Kolkata%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b9%b) %bCustom...%b\n" "${YELLOW}${BOLD}" "${RC}" "${YELLOW}" "${RC}"
    printf "\n       %b➜%b " "${CYAN}" "${RC}"
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
            printf "       %bEnter timezone (e.g., America/New_York):%b " "${WHITE}" "${RC}"
            read -r TIMEZONE
            ;;
        *) TIMEZONE="UTC" ;;
    esac
    
    # Locale
    printf "\n"
    printf "    %b󰗊%b  %bLocale%b %b[Default: %s]%b\n" "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${DIM}${CYAN}" "$LOCALE" "${RC}"
    printf "       %b➜%b " "${CYAN}" "${RC}"
    read -r input
    [ -n "$input" ] && LOCALE="$input"
    
    # Keymap
    printf "\n"
    printf "    %b󰌌%b  %bKeyboard Layout%b %b[Default: %s]%b\n" "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${DIM}${CYAN}" "$KEYMAP" "${RC}"
    printf "       %b➜%b " "${CYAN}" "${RC}"
    read -r input
    [ -n "$input" ] && KEYMAP="$input"
    
    # Bootloader
    if [ "$IS_UEFI" = "1" ]; then
        printf "\n"
        printf "    %b󰋊%b  %bBootloader%b %b[Default: GRUB]%b\n" "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${DIM}${CYAN}" "${RC}"
        printf "\n"
        printf "      %b1%b) %bGRUB%b              %b(recommended)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
        printf "      %b2%b) %bsystemd-boot%b      %b(minimal)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
        printf "\n       %b➜%b " "${CYAN}" "${RC}"
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
    
    printf "\n"
    ok "Configuration saved!"
    sleep 1
}

# Setup users
setup_users() {
    show_header
    
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${CYAN}" "${RC}"
    printf "  %b│%b %b󰀄  User Setup%b                                %b│%b\n" "${CYAN}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${CYAN}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${CYAN}" "${RC}"
    printf "\n"
    
    # Root password
    printf "    %b󰌋%b  %bRoot Password%b\n" "${PURPLE}" "${RC}" "${WHITE}${BOLD}" "${RC}"
    while true; do
        printf "       %b➜%b Enter password: " "${RED}" "${RC}"
        stty -echo
        read -r ROOT_PASSWORD
        stty echo
        printf "\n"
        
        printf "       %b➜%b Confirm password: " "${RED}" "${RC}"
        stty -echo
        read -r confirm
        stty echo
        printf "\n"
        
        if [ "$ROOT_PASSWORD" = "$confirm" ] && [ -n "$ROOT_PASSWORD" ]; then
            ok "Root password set!"
            break
        else
            err "Passwords don't match or empty. Try again."
            printf "\n"
        fi
    done
    
    # Create user?
    printf "\n"
    printf "    %b󰀄%b  %bCreate a regular user?%b %b[Y/n]%b: " "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    read -r create_user
    
    case "$create_user" in
        [Nn]*)
            USERNAME=""
            ;;
        *)
            printf "\n"
            printf "    %b󰀄%b  %bUsername%b\n" "${PURPLE}" "${RC}" "${WHITE}${BOLD}" "${RC}"
            printf "       %b➜%b " "${CYAN}" "${RC}"
            read -r USERNAME
            
            printf "\n"
            printf "    %b󰌋%b  %bPassword for %s%b\n" "${PURPLE}" "${RC}" "${WHITE}${BOLD}" "$USERNAME" "${RC}"
            while true; do
                printf "       %b➜%b Enter password: " "${CYAN}" "${RC}"
                stty -echo
                read -r USER_PASSWORD
                stty echo
                printf "\n"
                
                printf "       %b➜%b Confirm password: " "${CYAN}" "${RC}"
                stty -echo
                read -r confirm
                stty echo
                printf "\n"
                
                if [ "$USER_PASSWORD" = "$confirm" ] && [ -n "$USER_PASSWORD" ]; then
                    ok "User password set!"
                    break
                else
                    err "Passwords don't match or empty. Try again."
                    printf "\n"
                fi
            done
            ;;
    esac
    
    # Swap file configuration
    printf "\n"
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${CYAN}" "${RC}"
    printf "  %b│%b %b󰾴  Swap Configuration%b                        %b│%b\n" "${CYAN}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${CYAN}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${CYAN}" "${RC}"
    printf "\n"
    
    # Get RAM size in GB for suggestion
    RAM_GB=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
    SUGGESTED_SWAP=$((RAM_GB > 0 ? RAM_GB : 4))
    
    printf "    %b󰾴%b  %bEnable swap file?%b %b[Y/n]%b: " "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    read -r enable_swap
    
    case "$enable_swap" in
        [Nn]*)
            SWAP_SIZE=0
            info "Swap disabled"
            ;;
        *)
            printf "\n"
            printf "    %b󰾴%b  %bSwap File Size (GB)%b %b[Default: %d GB]%b\n" "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${GREEN}${BOLD}" "$SUGGESTED_SWAP" "${RC}"
            printf "       %bBased on your RAM: %s GB%b\n" "${DIM}" "$RAM_GB" "${RC}"
            printf "       %b➜%b " "${CYAN}" "${RC}"
            read -r swap_input
            
            if [ -n "$swap_input" ] && echo "$swap_input" | grep -qE '^[0-9]+$'; then
                SWAP_SIZE="$swap_input"
            else
                SWAP_SIZE="$SUGGESTED_SWAP"
            fi
            ok "Swap size: ${SWAP_SIZE} GB"
            ;;
    esac
    
    export S4D_ROOT_PASSWORD="$ROOT_PASSWORD"
    export S4D_USERNAME="$USERNAME"
    export S4D_USER_PASSWORD="$USER_PASSWORD"
    export S4D_SWAP_SIZE="$SWAP_SIZE"
    
    sleep 1
}

# Show summary
show_summary() {
    show_header
    
    printf "  %b╔═════════════════════════════════════════════════╗%b\n" "${GREEN}" "${RC}"
    printf "  %b║%b      %b📋  Installation Summary%b                   %b║%b\n" "${GREEN}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${GREEN}" "${RC}"
    printf "  %b╠═════════════════════════════════════════════════╣%b\n" "${GREEN}" "${RC}"
    printf "  %b║%b                                                 %b║%b\n" "${GREEN}" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b󰋊  Target Disk%b     %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${CYAN}${BOLD}" "$TARGET_DISK" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b󰍛  Boot Mode%b       %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "$([ "$IS_UEFI" = "1" ] && echo "UEFI" || echo "BIOS")" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b󰋊  Bootloader%b      %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "$BOOTLOADER" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b󰉋  Filesystem%b      %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "XFS" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b󰌽  Kernel%b          %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${YELLOW}${BOLD}" "Liquorix" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b────────────────────────────────────────%b   %b║%b\n" "${GREEN}" "${RC}" "${DIM}" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b󰇄  Hostname%b        %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "$HOSTNAME" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b󰥔  Timezone%b        %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "$TIMEZONE" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b󰗊  Locale%b          %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "$LOCALE" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b󰌌  Keymap%b          %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "$KEYMAP" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b────────────────────────────────────────%b   %b║%b\n" "${GREEN}" "${RC}" "${DIM}" "${RC}" "${GREEN}" "${RC}"
    if [ "$S4D_SWAP_SIZE" -gt 0 ] 2>/dev/null; then
        printf "  %b║%b  %b󰾴  Swap File%b       %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "${S4D_SWAP_SIZE} GB" "${RC}" "${GREEN}" "${RC}"
    else
        printf "  %b║%b  %b󰾴  Swap File%b       %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${DIM}" "Disabled" "${RC}" "${GREEN}" "${RC}"
    fi
    printf "  %b║%b  %b󰌋  Root Password%b   %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${GREEN}" "********" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b  %b󰀄  Username%b        %b│%b  %b%-22s%b  %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${WHITE}" "${USERNAME:-"(none)"}" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b                                                 %b║%b\n" "${GREEN}" "${RC}" "${GREEN}" "${RC}"
    printf "  %b╚═════════════════════════════════════════════════╝%b\n" "${GREEN}" "${RC}"
    
    printf "\n"
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${RED}" "${RC}"
    printf "  %b│%b  %b⚠  WARNING: This will ERASE ALL DATA on%b   %b│%b\n" "${RED}" "${RC}" "${BOLD}${YELLOW}" "${RC}" "${RED}" "${RC}"
    printf "  %b│%b     %b%-38s%b  %b│%b\n" "${RED}" "${RC}" "${WHITE}${BOLD}" "$TARGET_DISK" "${RC}" "${RED}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${RED}" "${RC}"
    
    printf "\n  %bProceed with installation?%b %b[y/N]%b: " "${WHITE}${BOLD}" "${RC}" "${DIM}" "${RC}"
    read -r confirm
    
    case "$confirm" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

# Run installation
run_installation() {
    show_header
    
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${CYAN}" "${RC}"
    printf "  %b│%b %b󰚰  Installing Arch Linux...%b                  %b│%b\n" "${CYAN}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${CYAN}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${CYAN}" "${RC}"
    printf "\n"
    
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
        
        # Show progress bar
        progress_bar "$current" "$total"
        printf "%b%s%b" "${WHITE}" "$step_name" "${RC}"
        
        if sh "$SCRIPTS_DIR/$step"; then
            printf "\r"
            progress_bar "$current" "$total"
            printf "%b%s%b %b✓%b\n" "${WHITE}" "$step_name" "${RC}" "${GREEN}${BOLD}" "${RC}"
        else
            printf "\r"
            progress_bar "$current" "$total"
            printf "%b%s%b %b✗%b\n" "${WHITE}" "$step_name" "${RC}" "${RED}${BOLD}" "${RC}"
            printf "\n"
            err "Installation failed at step: $step"
            printf "  %bCheck the error above and try again.%b\n" "${DIM}" "${RC}"
            exit 1
        fi
    done
    
    # Installation complete - fancy summary
    printf "\n\n"
    printf "  %b╔═══════════════════════════════════════════════════╗%b\n" "${GREEN}" "${RC}"
    printf "  %b║%b                                                   %b║%b\n" "${GREEN}" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b       %b✨  Installation Complete!  ✨%b              %b║%b\n" "${GREEN}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b                                                   %b║%b\n" "${GREEN}" "${RC}" "${GREEN}" "${RC}"
    printf "  %b╠═══════════════════════════════════════════════════╣%b\n" "${GREEN}" "${RC}"
    printf "  %b║%b                                                   %b║%b\n" "${GREEN}" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b    %b󰇄  Hostname:%b      %b%-24s%b   %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${WHITE}${BOLD}" "$HOSTNAME" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b    %b󰌽  Kernel:%b        %b%-24s%b   %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${YELLOW}${BOLD}" "Liquorix" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b    %b󰋊  Bootloader:%b    %b%-24s%b   %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${WHITE}" "$BOOTLOADER" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b    %b󰉋  Filesystem:%b    %b%-24s%b   %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${WHITE}" "XFS" "${RC}" "${GREEN}" "${RC}"
    printf "  %b║%b                                                   %b║%b\n" "${GREEN}" "${RC}" "${GREEN}" "${RC}"
    printf "  %b╚═══════════════════════════════════════════════════╝%b\n" "${GREEN}" "${RC}"
    printf "\n"
    
    printf "  %bYou can now reboot into your new system.%b\n" "${WHITE}" "${RC}"
    warn "Remember to remove the installation media!"
    printf "\n"
    
    printf "  %bReboot now?%b %b[Y/n]%b: " "${WHITE}${BOLD}" "${RC}" "${DIM}" "${RC}"
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
        
        printf "  %b╭─────────────────────────────────────────────╮%b\n" "${PURPLE}" "${RC}"
        printf "  %b│%b %b󰍜  Main Menu%b                                 %b│%b\n" "${PURPLE}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${PURPLE}" "${RC}"
        printf "  %b╰─────────────────────────────────────────────╯%b\n" "${PURPLE}" "${RC}"
        printf "\n"
        printf "    %b1%b  %b󰚰%b  %bStart Installation%b\n" "${CYAN}${BOLD}" "${RC}" "${GREEN}" "${RC}" "${WHITE}" "${RC}"
        printf "    %b2%b  %b󰆍%b  %bOpen Shell%b\n" "${CYAN}${BOLD}" "${RC}" "${YELLOW}" "${RC}" "${WHITE}" "${RC}"
        printf "    %b0%b  %b󰗼%b  %bExit%b\n" "${RED}${BOLD}" "${RC}" "${RED}" "${RC}" "${DIM}" "${RC}"
        printf "\n"
        draw_line 50
        printf "  %bSelect option%b: " "${WHITE}" "${RC}"
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
                printf "\n"
                info "Type 'exit' to return to installer."
                printf "\n"
                /bin/sh
                ;;
            0)
                printf "\n"
                info "Exiting..."
                printf "\n"
                exit 0
                ;;
        esac
    done
}

# Entry point
main() {
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        printf "\n"
        printf "  %b╭─────────────────────────────────────────────╮%b\n" "${RED}" "${RC}"
        printf "  %b│%b  %b✗  Error: This script must be run as root%b  %b│%b\n" "${RED}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${RED}" "${RC}"
        printf "  %b╰─────────────────────────────────────────────╯%b\n" "${RED}" "${RC}"
        printf "\n"
        exit 1
    fi
    
    # Ensure we have a proper TTY for user input
    # This is needed when running via curl | sh
    exec < /dev/tty
    
    main_menu
}

main "$@"
