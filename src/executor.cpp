#include "executor.hpp"

#include <array>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <sstream>
#include <unistd.h>
#include <sys/wait.h>
#include <fcntl.h>

namespace s4d {

int Executor::run_script(const std::string& script_path,
                         const std::map<std::string, std::string>& env,
                         std::string& output) {
    // Build command with environment variables
    std::stringstream cmd;
    
    // Export environment variables
    for (const auto& [key, value] : env) {
        cmd << "export " << key << "='" << value << "'; ";
    }
    
    // Run the script
    cmd << "sh '" << script_path << "' 2>&1";
    
    // Execute and capture output
    std::array<char, 4096> buffer;
    std::stringstream result;
    
    std::unique_ptr<FILE, decltype(&pclose)> pipe(
        popen(cmd.str().c_str(), "r"), pclose);
    
    if (!pipe) {
        output = "Failed to execute script";
        return -1;
    }
    
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result << buffer.data();
    }
    
    output = result.str();
    
    // Get exit code
    int status = pclose(pipe.release());
    return WEXITSTATUS(status);
}

int Executor::run_script_interactive(const std::string& script_path,
                                      const std::map<std::string, std::string>& env,
                                      OutputCallback callback) {
    int pipefd[2];
    if (pipe(pipefd) == -1) {
        return -1;
    }
    
    pid_t pid = fork();
    
    if (pid == -1) {
        return -1;
    }
    
    if (pid == 0) {
        // Child process
        close(pipefd[0]);  // Close read end
        
        // Redirect stdout and stderr to pipe
        dup2(pipefd[1], STDOUT_FILENO);
        dup2(pipefd[1], STDERR_FILENO);
        close(pipefd[1]);
        
        // Set environment variables
        for (const auto& [key, value] : env) {
            setenv(key.c_str(), value.c_str(), 1);
        }
        
        // Execute script
        execl("/bin/sh", "sh", script_path.c_str(), nullptr);
        _exit(127);  // exec failed
    }
    
    // Parent process
    close(pipefd[1]);  // Close write end
    
    // Set non-blocking
    int flags = fcntl(pipefd[0], F_GETFL, 0);
    fcntl(pipefd[0], F_SETFL, flags | O_NONBLOCK);
    
    // Read output
    char buffer[1024];
    ssize_t bytes_read;
    
    while (true) {
        bytes_read = read(pipefd[0], buffer, sizeof(buffer) - 1);
        
        if (bytes_read > 0) {
            buffer[bytes_read] = '\0';
            if (callback) {
                callback(std::string(buffer));
            }
        } else if (bytes_read == 0) {
            break;  // EOF
        } else if (errno != EAGAIN && errno != EWOULDBLOCK) {
            break;  // Error
        }
        
        // Check if child has exited
        int status;
        pid_t result = waitpid(pid, &status, WNOHANG);
        if (result == pid) {
            // Read any remaining output
            while ((bytes_read = read(pipefd[0], buffer, sizeof(buffer) - 1)) > 0) {
                buffer[bytes_read] = '\0';
                if (callback) {
                    callback(std::string(buffer));
                }
            }
            close(pipefd[0]);
            return WEXITSTATUS(status);
        }
        
        usleep(10000);  // 10ms
    }
    
    close(pipefd[0]);
    
    int status;
    waitpid(pid, &status, 0);
    return WEXITSTATUS(status);
}

std::string Executor::run_command(const std::string& command) {
    std::array<char, 4096> buffer;
    std::string result;
    
    std::unique_ptr<FILE, decltype(&pclose)> pipe(
        popen(command.c_str(), "r"), pclose);
    
    if (!pipe) {
        return "";
    }
    
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    
    return result;
}

bool Executor::command_exists(const std::string& command) {
    std::string check = "command -v " + command + " >/dev/null 2>&1";
    return system(check.c_str()) == 0;
}

std::vector<std::string> Executor::build_env(const std::map<std::string, std::string>& env) {
    std::vector<std::string> result;
    
    // Copy existing environment
    for (char** e = environ; *e != nullptr; ++e) {
        result.push_back(*e);
    }
    
    // Add custom variables
    for (const auto& [key, value] : env) {
        result.push_back(key + "=" + value);
    }
    
    return result;
}

} // namespace s4d
