# S4DUtil - Arch Linux Installer

A lightweight, interactive Arch Linux installer. No compilation needed - works directly on Live ISO!
![Image](https://github.com/user-attachments/assets/11b4d499-69e8-43b9-adb5-73883a466666)
## ⚠️ Disclaimer ⚠️
This tool will **format and partition your disk**. **Make sure you have backups of important data** before using this installer.

##  Quick Start

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

##  Features

- **Zero Dependencies** - Pure shell scripts, no compilation required
- **Lightweight** - Works on Live ISO with limited space
- **Interactive Menu** - Guided step-by-step installation
- **Disk Partitioning** - Full UEFI and BIOS support
- **Minimal Installation** - Clean, minimal Arch base system
- **Safe** - Confirmation prompts before destructive operations

##  Installation Steps

1.  Environment Check (Live ISO, Internet, UEFI/BIOS)
2.  Disk Selection & Partitioning
3.  Filesystem Formatting
4.  Mount Partitions
5.  Install Base System (pacstrap)
6.  System Configuration (locale, timezone, hostname)
7.  User Setup (root password, create user)
8.  Bootloader Installation (GRUB/systemd-boot)
9.  Finalize & Reboot

## 🛠️ Building from Source

### Requirements

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
