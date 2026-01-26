# S4DUtil - Arch Linux Installer

A modern C++ TUI-based minimal Arch Linux installer.

![Preview](assets/preview.png)

## 🚀 Quick Start

Boot into Arch Linux Live ISO, then run:

```bash
curl -fsSL https://raw.githubusercontent.com/Sadbin47/s4dutil/main/install.sh | sh
```

Or clone and build manually:

```bash
git clone https://github.com/Sadbin47/s4dutil.git
cd s4dutil
./build.sh
./build/s4dutil
```

## ✨ Features

- **Interactive TUI** - Modern terminal interface powered by FTXUI
- **Step-by-step installation** - Guided Arch Linux installation
- **Disk partitioning** - Support for UEFI and BIOS systems
- **Minimal installation** - Clean, minimal Arch base system
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

- CMake 3.14+
- C++17 compatible compiler (GCC 8+, Clang 7+)
- Git

### Build

```bash
mkdir build && cd build
cmake ..
make -j$(nproc)
```

### Install System-wide

```bash
sudo make install
```

## 📁 Project Structure

```
s4dutil/
├── CMakeLists.txt          # Build configuration
├── install.sh              # One-liner installer
├── build.sh                # Build script
├── src/                    # C++ source files
│   ├── main.cpp            # Entry point
│   ├── app.cpp/hpp         # Application state
│   ├── menu.cpp/hpp        # Menu system
│   ├── executor.cpp/hpp    # Script execution
│   ├── installer.cpp/hpp   # Installation logic
│   └── utils.cpp/hpp       # Utility functions
├── scripts/                # Shell scripts for installation
│   ├── common.sh           # Shared functions
│   └── *.sh                # Individual step scripts
└── config/
    └── menu.toml           # Menu configuration
```

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## ⚠️ Disclaimer

This tool will **format and partition your disk**. Make sure you have backups of important data before using this installer.
