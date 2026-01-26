/*
 * S4DUtil - Arch Linux Installer
 * A modern C++ TUI-based minimal Arch Linux installer
 * 
 * Copyright (c) 2026 S4D
 * Licensed under MIT License
 */

#include "app.hpp"
#include "menu.hpp"

#include <iostream>
#include <cstring>

void print_usage(const char* program_name) {
    std::cout << "S4DUtil - Arch Linux Installer v1.0.0\n"
              << "\n"
              << "Usage: " << program_name << " [OPTIONS]\n"
              << "\n"
              << "Options:\n"
              << "  -h, --help     Show this help message\n"
              << "  -v, --version  Show version information\n"
              << "  --check        Run system checks only\n"
              << "\n"
              << "This tool provides a guided installation of Arch Linux.\n"
              << "It must be run from an Arch Linux Live ISO as root.\n"
              << "\n"
              << "Quick start:\n"
              << "  curl -fsSL https://your-url/install.sh | sh\n"
              << "\n";
}

void print_version() {
    std::cout << "S4DUtil version 1.0.0\n";
}

void run_checks(const s4d::App& app) {
    const auto& info = app.get_system_info();
    
    std::cout << "System Checks:\n"
              << "  Running as root:    " << (info.is_root ? "Yes ✓" : "No ✗") << "\n"
              << "  Arch Live ISO:      " << (info.is_live_iso ? "Yes ✓" : "No ✗") << "\n"
              << "  Internet:           " << (info.has_internet ? "Yes ✓" : "No ✗") << "\n"
              << "  Boot mode:          " << (info.is_uefi ? "UEFI" : "BIOS") << "\n"
              << "  Architecture:       " << info.arch << "\n"
              << "\n"
              << "Available disks:\n";
    
    for (const auto& disk : info.available_disks) {
        std::cout << "  " << disk << "\n";
    }
    
    bool all_ok = info.is_root && info.is_live_iso && info.has_internet;
    std::cout << "\n" << (all_ok ? "All checks passed!" : "Some checks failed.") << "\n";
}

int main(int argc, char* argv[]) {
    // Parse command line arguments
    for (int i = 1; i < argc; ++i) {
        if (std::strcmp(argv[i], "-h") == 0 || std::strcmp(argv[i], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        }
        if (std::strcmp(argv[i], "-v") == 0 || std::strcmp(argv[i], "--version") == 0) {
            print_version();
            return 0;
        }
        if (std::strcmp(argv[i], "--check") == 0) {
            s4d::App app;
            run_checks(app);
            return 0;
        }
    }
    
    try {
        // Create application
        s4d::App app;
        
        // Check basic requirements
        const auto& info = app.get_system_info();
        
        if (!info.is_root) {
            std::cerr << "Error: This program must be run as root.\n"
                      << "Try: sudo " << argv[0] << "\n";
            return 1;
        }
        
        // Create and run menu
        s4d::Menu menu(app);
        return menu.run();
        
    } catch (const std::exception& e) {
        std::cerr << "Fatal error: " << e.what() << "\n";
        return 1;
    }
}
