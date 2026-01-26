#include "installer.hpp"

#include <filesystem>

namespace s4d {

Installer::Installer(App& app) : app_(app) {}

bool Installer::run(ProgressCallback on_progress, OutputCallback on_output) {
    auto& steps = app_.steps();
    
    for (size_t i = 0; i < steps.size(); ++i) {
        auto& step = steps[i];
        
        if (step.status == StepStatus::Completed || 
            step.status == StepStatus::Skipped) {
            continue;
        }
        
        if (on_progress) {
            on_progress(static_cast<int>(i), "Running: " + step.name);
        }
        
        step.status = StepStatus::InProgress;
        
        if (!run_step(i, on_output)) {
            step.status = StepStatus::Failed;
            last_error_ = "Step '" + step.name + "' failed: " + step.output;
            return false;
        }
        
        step.status = StepStatus::Completed;
    }
    
    return true;
}

bool Installer::run_step(size_t step_index, OutputCallback on_output) {
    if (step_index >= app_.steps().size()) {
        last_error_ = "Invalid step index";
        return false;
    }
    
    auto& step = app_.steps()[step_index];
    std::string script_path = app_.script_dir() + "/" + step.script;
    
    // Check if script exists
    if (!std::filesystem::exists(script_path)) {
        last_error_ = "Script not found: " + script_path;
        step.output = last_error_;
        return false;
    }
    
    // Build environment
    std::map<std::string, std::string> env;
    const auto& cfg = app_.config();
    const auto& info = app_.get_system_info();
    
    env["S4D_TARGET_DISK"] = cfg.target_disk;
    env["S4D_HOSTNAME"] = cfg.hostname;
    env["S4D_TIMEZONE"] = cfg.timezone;
    env["S4D_LOCALE"] = cfg.locale;
    env["S4D_KEYMAP"] = cfg.keymap;
    env["S4D_ROOT_PASSWORD"] = cfg.root_password;
    env["S4D_USERNAME"] = cfg.username;
    env["S4D_USER_PASSWORD"] = cfg.user_password;
    env["S4D_IS_UEFI"] = info.is_uefi ? "1" : "0";
    env["S4D_EFI_SIZE"] = std::to_string(cfg.efi_size);
    env["S4D_SWAP_SIZE"] = std::to_string(cfg.swap_size);
    env["S4D_BOOTLOADER"] = cfg.bootloader == InstallConfig::Bootloader::Grub 
                            ? "grub" : "systemd-boot";
    env["S4D_SCRIPT_DIR"] = app_.script_dir();
    
    // Run with output callback
    if (on_output) {
        int exit_code = executor_.run_script_interactive(script_path, env, on_output);
        return exit_code == 0;
    } else {
        int exit_code = executor_.run_script(script_path, env, step.output);
        return exit_code == 0;
    }
}

} // namespace s4d
