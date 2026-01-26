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
FILESYSTEM="ext4"

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
    printf "  %b║%b           %b*  Arch Linux Installer%b %bv1.0.0%b                      %b║%b\n" "${PURPLE}" "${RC}" "${WHITE}${BOLD}" "${RC}" "${YELLOW}${BOLD}" "${RC}" "${PURPLE}" "${RC}"
    printf "  %b╚═══════════════════════════════════════════════════════════════╝%b\n" "${PURPLE}" "${RC}"
    printf "\n"
}

# Show system information
show_system_info() {
    show_header
    
    printf "  %b╭───────────────────────────────────────────╮%b\n" "${CYAN}" "${RC}"
    printf "  %b│%b  %bSystem Information%b                       %b│%b\n" "${CYAN}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${CYAN}" "${RC}"
    printf "  %b╰───────────────────────────────────────────╯%b\n" "${CYAN}" "${RC}"
    printf "\n"
    
    # Boot mode
    if [ -d /sys/firmware/efi ]; then
        printf "    %b󰍛%b  Boot Mode      %b│%b  %b● UEFI%b\n" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${GREEN}${BOLD}" "${RC}"
        IS_UEFI=1
    else
        printf "    %b󰍛%b  Boot Mode      %b│%b  %b● BIOS (Legacy)%b\n" "${PURPLE}" "${RC}" "${DIM}" "${RC}" "${YELLOW}${BOLD}" "${RC}"
        IS_UEFI=0
    fi
    
    # Internet check
    if ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
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
    printf "  %b│%b %b⚠  WARNING: ALL DATA WILL BE ERASED!  %b    %b%b\n" "${RED}" "${RC}" "${BOLD}${YELLOW}${BLINK}" "${RC}" "${RED}" "${RC}"
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
    printf "  %b│%b %bALL DATA ON %-12s WILL BE LOST!%b     %b%b\n" "${RED}" "${RC}" "${BOLD}${WHITE}" "$TARGET_DISK" "${RC}" "${RED}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${RED}" "${RC}"
    printf "\n  %bAre you sure?%b %b[y/N]%b: " "${WHITE}" "${RC}" "${DIM}" "${RC}"
    read -r confirm
    case "$confirm" in
        [Yy]*)
            ok "Selected: $TARGET_DISK"
            export S4D_TARGET_DISK="$TARGET_DISK"
            ;;
        *)
            select_disk
            return
            ;;
    esac
    
    # Filesystem selection
    printf "\n"
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${CYAN}" "${RC}"
    printf "  %b│%b %b10cb  Filesystem Selection%b                    %b│%b\n" "${CYAN}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${CYAN}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${CYAN}" "${RC}"
    printf "\n"
    printf "    %b󰉋%b  %bFilesystem%b %b[Default: ext4]%b\n" "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${DIM}${CYAN}" "${RC}"
    printf "\n"
    printf "      %b1%b) %bext4%b            %b(stable, recommended)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    printf "      %b2%b) %bxfs%b             %b(high performance)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    printf "\n       %b➜%b " "${CYAN}" "${RC}"
    read -r fs_choice
    case "$fs_choice" in
        2) FILESYSTEM="xfs" ;;
        *) FILESYSTEM="ext4" ;;
    esac
    export S4D_FILESYSTEM="$FILESYSTEM"
    ok "Filesystem: $FILESYSTEM"
    sleep 1
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
    
    # Timezone - try to auto-detect first
    printf "\n"
    DETECTED_TZ=""
    if [ -f /etc/localtime ] && command -v readlink >/dev/null 2>&1; then
        DETECTED_TZ=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')
    fi
    if [ -z "$DETECTED_TZ" ] && [ -f /etc/timezone ]; then
        DETECTED_TZ=$(cat /etc/timezone 2>/dev/null)
    fi
    
    if [ -n "$DETECTED_TZ" ]; then
        printf "    %b󰥔%b  %bSystem detected your timezone to be '%s'%b\n" "${PURPLE}" "${RC}" "${WHITE}" "$DETECTED_TZ" "${RC}"
        printf "       %bIs this correct?%b %b[Y/n]%b: " "${WHITE}" "${RC}" "${DIM}" "${RC}"
        read -r tz_confirm
        case "$tz_confirm" in
            [Nn]*)
                # Show timezone selection
                select_timezone
                ;;
            *)
                TIMEZONE="$DETECTED_TZ"
                ok "Timezone set to: $TIMEZONE"
                ;;
        esac
    else
        printf "    %b󰥔%b  %bTimezone%b %b[Default: %s]%b\n" "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${DIM}${CYAN}" "$TIMEZONE" "${RC}"
        select_timezone
    fi
    
    # Locale selection
    printf "\n"
    printf "    %b󰗊%b  %bLocale%b %b[Default: %s]%b\n" "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${DIM}${CYAN}" "$LOCALE" "${RC}"
    printf "\n"
    printf "      %b1%b) %ben_US.UTF-8%b       %b(English - US)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    printf "      %b2%b) %ben_GB.UTF-8%b       %b(English - UK)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    printf "      %b3%b) %bde_DE.UTF-8%b       %b(German)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    printf "      %b4%b) %bfr_FR.UTF-8%b       %b(French)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    printf "      %b5%b) %bes_ES.UTF-8%b       %b(Spanish)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    printf "      %b6%b) %bShow all available...%b\n" "${YELLOW}${BOLD}" "${RC}" "${YELLOW}" "${RC}"
    printf "\n       %b➜%b " "${CYAN}" "${RC}"
    read -r locale_choice
    
    case "$locale_choice" in
        1) LOCALE="en_US.UTF-8" ;;
        2) LOCALE="en_GB.UTF-8" ;;
        3) LOCALE="de_DE.UTF-8" ;;
        4) LOCALE="fr_FR.UTF-8" ;;
        5) LOCALE="es_ES.UTF-8" ;;
        6) 
            select_locale
            ;;
        *) LOCALE="en_US.UTF-8" ;;
    esac
    
    # Keyboard layout selection
    printf "\n"
    printf "    %b󰌌%b  %bKeyboard Layout%b %b[Default: %s]%b\n" "${PURPLE}" "${RC}" "${WHITE}" "${RC}" "${DIM}${CYAN}" "$KEYMAP" "${RC}"
    printf "\n"
    printf "      %b1%b) %bus%b      %b(US English)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    printf "      %b2%b) %buk%b      %b(UK English)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    printf "      %b3%b) %bde%b      %b(German)%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}" "${DIM}" "${RC}"
    printf "      %b4%b) %bShow all available...%b\n" "${YELLOW}${BOLD}" "${RC}" "${YELLOW}" "${RC}"
    printf "\n       %b➜%b " "${CYAN}" "${RC}"
    read -r keymap_choice
    
    case "$keymap_choice" in
        1) KEYMAP="us" ;;
        2) KEYMAP="uk" ;;
        3) KEYMAP="de" ;;
        4) 
            select_keymap
            ;;
        *) KEYMAP="us" ;;
    esac
    
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

# Select timezone from list
select_timezone() {
    printf "\n"
    printf "      %b1%b) %bUTC%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b2%b) %bAmerica/New_York%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b3%b) %bAmerica/Los_Angeles%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b4%b) %bEurope/London%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b5%b) %bAsia/Tokyo%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b6%b) %bAsia/Shanghai%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b7%b) %bAsia/Dhaka%b\n" "${CYAN}${BOLD}" "${RC}" "${WHITE}" "${RC}"
    printf "      %b8%b) %bEnter custom...%b\n" "${YELLOW}${BOLD}" "${RC}" "${YELLOW}" "${RC}"
    printf "\n       %b➜%b " "${CYAN}" "${RC}"
    read -r tz_choice
    
    case "$tz_choice" in
        1) TIMEZONE="UTC" ;;
        2) TIMEZONE="America/New_York" ;;
        3) TIMEZONE="America/Los_Angeles" ;;
        4) TIMEZONE="Europe/London" ;;
        5) TIMEZONE="Asia/Tokyo" ;;
        6) TIMEZONE="Asia/Shanghai" ;;
        7) TIMEZONE="Asia/Dhaka" ;;
        8) 
            printf "       %bEnter timezone (e.g., Europe/London):%b " "${WHITE}" "${RC}"
            read -r TIMEZONE
            ;;
        *) TIMEZONE="UTC" ;;
    esac
    ok "Timezone set to: $TIMEZONE"
}

# Select locale from all available
select_locale() {
    printf "\n"
    printf "       %bAvailable locales:%b\n" "${WHITE}${BOLD}" "${RC}"
    printf "\n"
    
    # Common locales list
    LOCALES="aa_DJ.UTF-8
aa_ER.UTF-8
aa_ET.UTF-8
af_ZA.UTF-8
am_ET.UTF-8
an_ES.UTF-8
ar_AE.UTF-8
ar_BH.UTF-8
ar_DZ.UTF-8
ar_EG.UTF-8
ar_IQ.UTF-8
ar_JO.UTF-8
ar_KW.UTF-8
ar_LB.UTF-8
ar_LY.UTF-8
ar_MA.UTF-8
ar_OM.UTF-8
ar_QA.UTF-8
ar_SA.UTF-8
ar_SD.UTF-8
ar_SY.UTF-8
ar_TN.UTF-8
ar_YE.UTF-8
az_AZ.UTF-8
be_BY.UTF-8
bg_BG.UTF-8
bn_BD.UTF-8
bn_IN.UTF-8
bs_BA.UTF-8
ca_ES.UTF-8
cs_CZ.UTF-8
cy_GB.UTF-8
da_DK.UTF-8
de_AT.UTF-8
de_BE.UTF-8
de_CH.UTF-8
de_DE.UTF-8
de_LU.UTF-8
el_GR.UTF-8
en_AU.UTF-8
en_BW.UTF-8
en_CA.UTF-8
en_DK.UTF-8
en_GB.UTF-8
en_HK.UTF-8
en_IE.UTF-8
en_IN.UTF-8
en_NZ.UTF-8
en_PH.UTF-8
en_SG.UTF-8
en_US.UTF-8
en_ZA.UTF-8
en_ZW.UTF-8
es_AR.UTF-8
es_BO.UTF-8
es_CL.UTF-8
es_CO.UTF-8
es_CR.UTF-8
es_DO.UTF-8
es_EC.UTF-8
es_ES.UTF-8
es_GT.UTF-8
es_HN.UTF-8
es_MX.UTF-8
es_NI.UTF-8
es_PA.UTF-8
es_PE.UTF-8
es_PR.UTF-8
es_PY.UTF-8
es_SV.UTF-8
es_US.UTF-8
es_UY.UTF-8
es_VE.UTF-8
et_EE.UTF-8
eu_ES.UTF-8
fa_IR.UTF-8
fi_FI.UTF-8
fr_BE.UTF-8
fr_CA.UTF-8
fr_CH.UTF-8
fr_FR.UTF-8
fr_LU.UTF-8
ga_IE.UTF-8
gl_ES.UTF-8
gu_IN.UTF-8
he_IL.UTF-8
hi_IN.UTF-8
hr_HR.UTF-8
hu_HU.UTF-8
hy_AM.UTF-8
id_ID.UTF-8
is_IS.UTF-8
it_CH.UTF-8
it_IT.UTF-8
ja_JP.UTF-8
ka_GE.UTF-8
kk_KZ.UTF-8
km_KH.UTF-8
kn_IN.UTF-8
ko_KR.UTF-8
lt_LT.UTF-8
lv_LV.UTF-8
mk_MK.UTF-8
ml_IN.UTF-8
mn_MN.UTF-8
mr_IN.UTF-8
ms_MY.UTF-8
mt_MT.UTF-8
nb_NO.UTF-8
ne_NP.UTF-8
nl_BE.UTF-8
nl_NL.UTF-8
nn_NO.UTF-8
pa_IN.UTF-8
pl_PL.UTF-8
pt_BR.UTF-8
pt_PT.UTF-8
ro_RO.UTF-8
ru_RU.UTF-8
ru_UA.UTF-8
si_LK.UTF-8
sk_SK.UTF-8
sl_SI.UTF-8
sq_AL.UTF-8
sr_RS.UTF-8
sv_FI.UTF-8
sv_SE.UTF-8
ta_IN.UTF-8
te_IN.UTF-8
th_TH.UTF-8
tr_TR.UTF-8
uk_UA.UTF-8
ur_PK.UTF-8
vi_VN.UTF-8
zh_CN.UTF-8
zh_HK.UTF-8
zh_SG.UTF-8
zh_TW.UTF-8"

    # Display locales in columns
    i=1
    echo "$LOCALES" | while IFS= read -r loc; do
        printf "      %b%2d%b) %b%-20s%b" "${CYAN}${BOLD}" "$i" "${RC}" "${WHITE}" "$loc" "${RC}"
        if [ $((i % 3)) -eq 0 ]; then
            printf "\n"
        fi
        i=$((i + 1))
    done
    printf "\n\n       %b➜%b Enter number or locale name: " "${CYAN}" "${RC}"
    read -r loc_input
    
    # Check if input is a number
    if echo "$loc_input" | grep -qE '^[0-9]+$'; then
        LOCALE=$(echo "$LOCALES" | sed -n "${loc_input}p")
        [ -z "$LOCALE" ] && LOCALE="en_US.UTF-8"
    else
        # Assume it's a locale name
        if echo "$LOCALES" | grep -q "^${loc_input}$"; then
            LOCALE="$loc_input"
        elif echo "$LOCALES" | grep -q "^${loc_input}"; then
            LOCALE=$(echo "$LOCALES" | grep "^${loc_input}" | head -1)
        else
            LOCALE="en_US.UTF-8"
        fi
    fi
    ok "Locale set to: $LOCALE"
}

# Select keymap from all available
select_keymap() {
    printf "\n"
    printf "       %bAvailable keyboard layouts:%b\n" "${WHITE}${BOLD}" "${RC}"
    printf "\n"
    
    KEYMAPS="us
uk
by
ca
cf
cz
de
de-latin1
dk
dvorak
es
et
fa
fi
fr
gr
hu
il
it
jp106
la-latin1
lt
lv
mk
nl
no
pl
pt-latin1
ro
ru
se
sg
sk
tr
ua
us-acentos"

    # Display keymaps in columns
    i=1
    echo "$KEYMAPS" | while IFS= read -r km; do
        printf "      %b%2d%b) %b%-15s%b" "${CYAN}${BOLD}" "$i" "${RC}" "${WHITE}" "$km" "${RC}"
        if [ $((i % 4)) -eq 0 ]; then
            printf "\n"
        fi
        i=$((i + 1))
    done
    printf "\n\n       %b➜%b Enter number or keymap name: " "${CYAN}" "${RC}"
    read -r km_input
    
    # Check if input is a number
    if echo "$km_input" | grep -qE '^[0-9]+$'; then
        KEYMAP=$(echo "$KEYMAPS" | sed -n "${km_input}p")
        [ -z "$KEYMAP" ] && KEYMAP="us"
    else
        # Assume it's a keymap name
        if echo "$KEYMAPS" | grep -q "^${km_input}$"; then
            KEYMAP="$km_input"
        else
            KEYMAP="us"
        fi
    fi
    ok "Keyboard layout set to: $KEYMAP"
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
    
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${CYAN}" "${RC}"
    printf "  %b│%b  %bInstallation Summary%b                       %b│%b\n" "${CYAN}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${CYAN}" "${RC}"
    printf "  %b╰─────────────────────────────────────────────╯%b\n" "${CYAN}" "${RC}"
    printf "\n"
    
    # System section
    printf "    %b󰋊%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Target Disk" "${CYAN}${BOLD}" "$TARGET_DISK" "${RC}"
    printf "    %b󰍛%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Boot Mode" "${WHITE}" "$([ "$IS_UEFI" = "1" ] && echo "UEFI" || echo "BIOS")" "${RC}"
    printf "    %b󰋊%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Bootloader" "${WHITE}" "$BOOTLOADER" "${RC}"
    printf "    %b󰉋%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Filesystem" "${WHITE}" "$FILESYSTEM" "${RC}"
    printf "    %b󰌽%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Kernel" "${YELLOW}${BOLD}" "Liquorix" "${RC}"
    printf "\n"
    draw_line 47
    printf "\n"
    
    # Configuration section
    printf "    %b󰇄%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Hostname" "${WHITE}" "$HOSTNAME" "${RC}"
    printf "    %b󰥔%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Timezone" "${WHITE}" "$TIMEZONE" "${RC}"
    printf "    %b󰗊%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Locale" "${WHITE}" "$LOCALE" "${RC}"
    printf "    %b󰌌%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Keymap" "${WHITE}" "$KEYMAP" "${RC}"
    printf "\n"
    draw_line 47
    printf "\n"
    
    # User section
    if [ "$S4D_SWAP_SIZE" -gt 0 ] 2>/dev/null; then
        printf "    %b󰾴%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Swap File" "${WHITE}" "${S4D_SWAP_SIZE} GB" "${RC}"
    else
        printf "    %b󰾴%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Swap File" "${DIM}" "Disabled" "${RC}"
    fi
    printf "    %b󰌋%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Root Password" "${CYAN}" "********" "${RC}"
    printf "    %b󰀄%b  %-18s %b%s%b\n" "${PURPLE}" "${RC}" "Username" "${WHITE}" "${USERNAME:-"(none)"}" "${RC}"
    
    printf "\n"
    printf "  %b╭─────────────────────────────────────────────╮%b\n" "${RED}" "${RC}"
    printf "  %b│%b  %b⚠  WARNING: This will ERASE ALL DATA on %b   %b│%b\n" "${RED}" "${RC}" "${BOLD}${YELLOW}" "${RC}" "${RED}" "${RC}"
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
        printf "\r"
        progress_bar "$current" "$total"
        printf " %b%s%b..." "${WHITE}" "$step_name" "${RC}"
        
        # Run script with stdin from /dev/null to prevent it from waiting for input
        if sh "$SCRIPTS_DIR/$step" </dev/null >/dev/null 2>&1; then
            printf "\r"
            progress_bar "$current" "$total"
            printf " %b%-25s%b %b✓%b\n" "${WHITE}" "$step_name" "${RC}" "${GREEN}${BOLD}" "${RC}"
        else
            printf "\r"
            progress_bar "$current" "$total"
            printf " %b%-25s%b %b✗%b\n" "${WHITE}" "$step_name" "${RC}" "${RED}${BOLD}" "${RC}"
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
    printf "  %b║%b    %b󰉋  Filesystem:%b    %b%-24s%b   %b║%b\n" "${GREEN}" "${RC}" "${PURPLE}" "${RC}" "${WHITE}" "$FILESYSTEM" "${RC}" "${GREEN}" "${RC}"
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
        
        printf "  %b╭───────────────────────────────────────────╮%b\n" "${PURPLE}" "${RC}"
        printf "  %b│%b  %bMain Menu%b                                %b│%b\n" "${PURPLE}" "${RC}" "${BOLD}${WHITE}" "${RC}" "${PURPLE}" "${RC}"
        printf "  %b╰───────────────────────────────────────────╯%b\n" "${PURPLE}" "${RC}"
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
