#pragma once

#include <string>
#include <map>
#include <functional>

namespace s4d {

// Callback for real-time output
using OutputCallback = std::function<void(const std::string&)>;

class Executor {
public:
    Executor() = default;
    ~Executor() = default;
    
    // Run a script with environment variables
    // Returns exit code, output is captured in output parameter
    int run_script(const std::string& script_path,
                   const std::map<std::string, std::string>& env,
                   std::string& output);
    
    // Run a script with real-time output callback
    int run_script_interactive(const std::string& script_path,
                               const std::map<std::string, std::string>& env,
                               OutputCallback callback);
    
    // Run a simple command and return output
    static std::string run_command(const std::string& command);
    
    // Check if a command exists
    static bool command_exists(const std::string& command);

private:
    // Build environment string for execve
    std::vector<std::string> build_env(const std::map<std::string, std::string>& env);
};

} // namespace s4d
