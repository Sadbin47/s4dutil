#pragma once

#include <string>
#include <sstream>
#include <algorithm>

namespace s4d {
namespace utils {

// Execute a command and return output
inline std::string exec_command(const std::string& cmd) {
    std::array<char, 4096> buffer;
    std::string result;
    
    std::unique_ptr<FILE, decltype(&pclose)> pipe(
        popen(cmd.c_str(), "r"), pclose);
    
    if (!pipe) {
        return "";
    }
    
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    
    return result;
}

// Trim whitespace from string
inline void trim(std::string& s) {
    // Left trim
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](unsigned char ch) {
        return !std::isspace(ch);
    }));
    
    // Right trim
    s.erase(std::find_if(s.rbegin(), s.rend(), [](unsigned char ch) {
        return !std::isspace(ch);
    }).base(), s.end());
}

// Split string by delimiter
inline std::vector<std::string> split(const std::string& s, char delimiter) {
    std::vector<std::string> tokens;
    std::string token;
    std::istringstream tokenStream(s);
    
    while (std::getline(tokenStream, token, delimiter)) {
        tokens.push_back(token);
    }
    
    return tokens;
}

// Check if string starts with prefix
inline bool starts_with(const std::string& s, const std::string& prefix) {
    return s.size() >= prefix.size() && s.compare(0, prefix.size(), prefix) == 0;
}

// Check if string ends with suffix
inline bool ends_with(const std::string& s, const std::string& suffix) {
    return s.size() >= suffix.size() && 
           s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0;
}

// Get RAM size in MB
inline size_t get_ram_mb() {
    std::string meminfo = exec_command("grep MemTotal /proc/meminfo | awk '{print $2}'");
    trim(meminfo);
    
    if (meminfo.empty()) {
        return 4096;  // Default 4GB
    }
    
    return std::stoull(meminfo) / 1024;  // Convert KB to MB
}

// Get disk size in GB
inline size_t get_disk_size_gb(const std::string& disk) {
    std::string cmd = "lsblk -b -d -n -o SIZE " + disk + " 2>/dev/null";
    std::string size_str = exec_command(cmd);
    trim(size_str);
    
    if (size_str.empty()) {
        return 0;
    }
    
    return std::stoull(size_str) / (1024 * 1024 * 1024);  // Convert bytes to GB
}

// Format size for display
inline std::string format_size(size_t size_mb) {
    if (size_mb >= 1024) {
        return std::to_string(size_mb / 1024) + " GB";
    }
    return std::to_string(size_mb) + " MB";
}

} // namespace utils
} // namespace s4d
