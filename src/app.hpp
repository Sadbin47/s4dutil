#pragma once

#include <string>
#include <vector>
#include <functional>
#include <memory>

namespace s4d {

// Forward declarations
class Menu;
class Executor;

// Installation step status
enum class StepStatus {
    Pending,
    InProgress,
    Completed,
    Failed,
    Skipped
};

// System information
struct SystemInfo {
    bool is_uefi = false;
    bool has_internet = false;
    bool is_live_iso = false;
    bool is_root = false;
    std::string arch;
    std::vector<std::string> available_disks;
};

// Installation configuration
struct InstallConfig {
    // Disk configuration
    std::string target_disk;
    bool use_encryption = false;
    std::string encryption_password;
    
    // Partition sizes (in MB, 0 = remaining space)
    size_t efi_size = 512;      // EFI partition (UEFI only)
    size_t swap_size = 0;       // Swap partition (0 = auto based on RAM)
    size_t root_size = 0;       // Root partition (0 = remaining space)
    
    // System configuration
    std::string hostname = "archlinux";
    std::string timezone = "UTC";
    std::string locale = "en_US.UTF-8";
    std::string keymap = "us";
    
    // User configuration
    std::string root_password;
    std::string username;
    std::string user_password;
    
    // Bootloader
    enum class Bootloader { Grub, SystemdBoot } bootloader = Bootloader::Grub;
    
    // Extra packages
    std::vector<std::string> extra_packages;
};

// Installation step
struct InstallStep {
    std::string id;
    std::string name;
    std::string description;
    std::string script;
    StepStatus status = StepStatus::Pending;
    std::string output;
    bool requires_confirmation = false;
};

// Application state
class App {
public:
    App();
    ~App();
    
    // Run the application
    int run();
    
    // Get system information
    const SystemInfo& get_system_info() const { return system_info_; }
    
    // Get/set installation config
    InstallConfig& config() { return config_; }
    const InstallConfig& config() const { return config_; }
    
    // Get installation steps
    std::vector<InstallStep>& steps() { return steps_; }
    const std::vector<InstallStep>& steps() const { return steps_; }
    
    // Execute a step
    bool execute_step(size_t index);
    
    // Execute all pending steps
    bool execute_all();
    
    // Get script directory
    const std::string& script_dir() const { return script_dir_; }

private:
    void detect_system_info();
    void initialize_steps();
    void find_script_dir();
    
    SystemInfo system_info_;
    InstallConfig config_;
    std::vector<InstallStep> steps_;
    std::string script_dir_;
    std::unique_ptr<Executor> executor_;
};

} // namespace s4d
