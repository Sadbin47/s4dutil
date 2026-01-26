#pragma once

#include "app.hpp"
#include "executor.hpp"
#include <functional>

namespace s4d {

// Handles the actual installation process
class Installer {
public:
    using ProgressCallback = std::function<void(int step, const std::string& message)>;
    using OutputCallback = std::function<void(const std::string& output)>;
    
    explicit Installer(App& app);
    
    // Run the full installation
    bool run(ProgressCallback on_progress = nullptr,
             OutputCallback on_output = nullptr);
    
    // Run a specific step
    bool run_step(size_t step_index,
                  OutputCallback on_output = nullptr);
    
    // Get last error
    const std::string& last_error() const { return last_error_; }

private:
    App& app_;
    Executor executor_;
    std::string last_error_;
};

} // namespace s4d
