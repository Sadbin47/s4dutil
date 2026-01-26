#include "app.hpp"
#include "executor.hpp"
#include "utils.hpp"

#include <fstream>
#include <filesystem>
#include <cstdlib>
#include <unistd.h>
#include <sys/stat.h>

namespace fs = std::filesystem;

namespace s4d {

App::App() : executor_(std::make_unique<Executor>()) {
    find_script_dir();
    detect_system_info();
    initialize_steps();
}

App::~App() = default;

void App::find_script_dir() {
    // Look for scripts directory in common locations
    std::vector<std::string> search_paths = {
        "./scripts",
        "../scripts",
        "/usr/share/s4dutil/scripts",
        "/usr/local/share/s4dutil/scripts",
    };
    
    // Also check relative to executable
    char exe_path[PATH_MAX];
    ssize_t len = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
    if (len != -1) {
        exe_path[len] = '\0';
        fs::path exe_dir = fs::path(exe_path).parent_path();
        search_paths.insert(search_paths.begin(), (exe_dir / "scripts").string());
        search_paths.insert(search_paths.begin(), (exe_dir.parent_path() / "scripts").string());
    }
    
    for (const auto& path : search_paths) {
        if (fs::exists(path) && fs::is_directory(path)) {
            script_dir_ = fs::absolute(path).string();
            return;
        }
    }
    
    // Default to current directory
    script_dir_ = "./scripts";
}

void App::detect_system_info() {
    // Check if running as root
    system_info_.is_root = (geteuid() == 0);
    
    // Check if UEFI
    system_info_.is_uefi = fs::exists("/sys/firmware/efi");
    
    // Check if Arch Live ISO
    system_info_.is_live_iso = fs::exists("/etc/arch-release") && 
                                fs::exists("/run/archiso");
    
    // Check internet connection
    system_info_.has_internet = (system("ping -c 1 -W 2 archlinux.org >/dev/null 2>&1") == 0);
    
    // Get architecture
    system_info_.arch = utils::exec_command("uname -m");
    utils::trim(system_info_.arch);
    
    // Get available disks
    std::string lsblk_output = utils::exec_command(
        "lsblk -d -n -o NAME,SIZE,TYPE | grep disk | awk '{print \"/dev/\" $1 \" (\" $2 \")\"}'");
    
    std::istringstream iss(lsblk_output);
    std::string line;
    while (std::getline(iss, line)) {
        utils::trim(line);
        if (!line.empty()) {
            system_info_.available_disks.push_back(line);
        }
    }
}

void App::initialize_steps() {
    steps_ = {
        {
            "check_env",
            "Check Environment",
            "Verify system requirements (root, live ISO, internet)",
            "00-check-environment.sh",
            StepStatus::Pending,
            "",
            false
        },
        {
            "partition",
            "Partition Disk",
            "Create partitions on the target disk",
            "01-partition-disk.sh",
            StepStatus::Pending,
            "",
            true  // Requires confirmation - destructive!
        },
        {
            "format",
            "Format Partitions",
            "Create filesystems on partitions",
            "02-format-partitions.sh",
            StepStatus::Pending,
            "",
            true  // Requires confirmation - destructive!
        },
        {
            "mount",
            "Mount Partitions",
            "Mount partitions to /mnt",
            "03-mount-partitions.sh",
            StepStatus::Pending,
            "",
            false
        },
        {
            "pacstrap",
            "Install Base System",
            "Install base packages with pacstrap",
            "04-install-base.sh",
            StepStatus::Pending,
            "",
            false
        },
        {
            "genfstab",
            "Generate fstab",
            "Generate filesystem table",
            "05-generate-fstab.sh",
            StepStatus::Pending,
            "",
            false
        },
        {
            "configure",
            "Configure System",
            "Set locale, timezone, hostname",
            "06-configure-system.sh",
            StepStatus::Pending,
            "",
            false
        },
        {
            "users",
            "Setup Users",
            "Set root password and create user",
            "07-setup-users.sh",
            StepStatus::Pending,
            "",
            false
        },
        {
            "bootloader",
            "Install Bootloader",
            "Install and configure GRUB or systemd-boot",
            "08-install-bootloader.sh",
            StepStatus::Pending,
            "",
            false
        },
        {
            "finalize",
            "Finalize Installation",
            "Unmount and prepare for reboot",
            "09-finalize.sh",
            StepStatus::Pending,
            "",
            false
        }
    };
}

bool App::execute_step(size_t index) {
    if (index >= steps_.size()) {
        return false;
    }
    
    auto& step = steps_[index];
    step.status = StepStatus::InProgress;
    
    // Build environment variables from config
    std::map<std::string, std::string> env;
    env["S4D_TARGET_DISK"] = config_.target_disk;
    env["S4D_HOSTNAME"] = config_.hostname;
    env["S4D_TIMEZONE"] = config_.timezone;
    env["S4D_LOCALE"] = config_.locale;
    env["S4D_KEYMAP"] = config_.keymap;
    env["S4D_ROOT_PASSWORD"] = config_.root_password;
    env["S4D_USERNAME"] = config_.username;
    env["S4D_USER_PASSWORD"] = config_.user_password;
    env["S4D_IS_UEFI"] = system_info_.is_uefi ? "1" : "0";
    env["S4D_EFI_SIZE"] = std::to_string(config_.efi_size);
    env["S4D_SWAP_SIZE"] = std::to_string(config_.swap_size);
    env["S4D_BOOTLOADER"] = config_.bootloader == InstallConfig::Bootloader::Grub ? "grub" : "systemd-boot";
    env["S4D_SCRIPT_DIR"] = script_dir_;
    
    std::string script_path = script_dir_ + "/" + step.script;
    
    int exit_code = executor_->run_script(script_path, env, step.output);
    
    if (exit_code == 0) {
        step.status = StepStatus::Completed;
        return true;
    } else {
        step.status = StepStatus::Failed;
        return false;
    }
}

bool App::execute_all() {
    for (size_t i = 0; i < steps_.size(); ++i) {
        if (steps_[i].status == StepStatus::Pending) {
            if (!execute_step(i)) {
                return false;
            }
        }
    }
    return true;
}

int App::run() {
    // This is called from menu.cpp which handles the TUI
    return 0;
}

} // namespace s4d
