# S4DUtil - Arch Linux Installer

A lightweight, interactive Arch Linux installer. No compilation needed - works directly on Live ISO!

## 🚀 Quick Start

Boot into Arch Linux Live ISO, then run:

```bash
curl -fsSL https://raw.githubusercontent.com/Sadbin47/s4dutil/main/install.sh | sh
```

Or clone manually:

```bash
git clone https://github.com/Sadbin47/s4dutil.git
cd s4dutil
./s4dutil.sh
```

## ✨ Features

- **Zero Dependencies** - Pure shell scripts, no compilation required
- **Lightweight** - Works on Live ISO with limited space
- **Interactive Menu** - Guided step-by-step installation
- **Disk Partitioning** - Full UEFI and BIOS support
- **Minimal Installation** - Clean, minimal Arch base system
- **Safe** - Confirmation prompts before destructive operations

## 📋 Installation Steps

1. ✅ Environment Check (Live ISO, Internet, UEFI/BIOS)
2. 💾 Disk Selection & Partitioning
3. 📁 Filesystem Formatting
4. 📂 Mount Partitions
5. 📦 Install Base System (pacstrap)
6. ⚙️ System Configuration (locale, timezone, hostname)
7. 🔐 User Setup (root password, create user)
8. 🚀 Bootloader Installation (GRUB/systemd-boot)
9. ✨ Finalize & Reboot

## 🛠️ Building from Source

### Requirements

## 📁 Project Structure

```
s4dutil/
├── install.sh              # One-liner installer (curl | sh)
├── s4dutil.sh              # Main interactive menu
├── scripts/                # Installation step scripts
│   ├── common.sh           # Shared functions
│   ├── 00-check-environment.sh
│   ├── 01-partition-disk.sh
│   ├── 02-format-partitions.sh
│   ├── 03-mount-partitions.sh
│   ├── 04-install-base.sh
│   ├── 05-generate-fstab.sh
│   ├── 06-configure-system.sh
│   ├── 07-setup-users.sh
│   ├── 08-install-bootloader.sh
│   └── 09-finalize.sh
└── src/                    # Optional C++ TUI (for development)
```

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## ⚠️ Disclaimer

This tool will **format and partition your disk**. Make sure you have backups of important data before using this installer.
