#include "menu.hpp"
#include "utils.hpp"

#include <ftxui/component/component.hpp>
#include <ftxui/component/component_options.hpp>
#include <ftxui/dom/elements.hpp>
#include <ftxui/screen/screen.hpp>

using namespace ftxui;

namespace s4d {

// Color scheme
namespace colors {
    const Color primary = Color::RGB(87, 199, 255);      // Cyan
    const Color secondary = Color::RGB(255, 121, 198);   // Pink
    const Color success = Color::RGB(80, 250, 123);      // Green
    const Color warning = Color::RGB(255, 184, 108);     // Orange
    const Color error = Color::RGB(255, 85, 85);         // Red
    const Color muted = Color::GrayDark;
    const Color bg = Color::RGB(30, 30, 46);             // Dark background
}

// Common timezones
const std::vector<std::string> TIMEZONES = {
    "UTC",
    "America/New_York",
    "America/Chicago",
    "America/Denver",
    "America/Los_Angeles",
    "Europe/London",
    "Europe/Paris",
    "Europe/Berlin",
    "Asia/Tokyo",
    "Asia/Shanghai",
    "Asia/Kolkata",
    "Australia/Sydney",
};

// Common locales
const std::vector<std::string> LOCALES = {
    "en_US.UTF-8",
    "en_GB.UTF-8",
    "de_DE.UTF-8",
    "fr_FR.UTF-8",
    "es_ES.UTF-8",
    "it_IT.UTF-8",
    "pt_BR.UTF-8",
    "ja_JP.UTF-8",
    "zh_CN.UTF-8",
    "ko_KR.UTF-8",
};

Menu::Menu(App& app) : app_(app) {
    // Initialize form values from config
    hostname_input_ = app_.config().hostname;
}

int Menu::run() {
    // Main container that switches between pages
    auto main_container = Container::Tab({
        create_welcome_page(),
        create_system_info_page(),
        create_disk_selection_page(),
        create_configuration_page(),
        create_user_setup_page(),
        create_summary_page(),
        create_installation_page(),
        create_complete_page(),
    }, reinterpret_cast<int*>(&current_page_));
    
    // Main renderer with header and footer
    auto main_renderer = Renderer(main_container, [&] {
        return vbox({
            render_header(),
            separator(),
            main_container->Render() | flex,
            separator(),
            render_footer(),
        }) | border;
    });
    
    // Global key handler
    auto main_component = CatchEvent(main_renderer, [&](Event event) {
        if (event == Event::Escape || event == Event::Character('q')) {
            if (current_page_ == Page::Welcome) {
                screen_.ExitLoopClosure()();
                return true;
            }
        }
        return false;
    });
    
    screen_.Loop(main_component);
    return 0;
}

Element Menu::render_header() {
    std::string title = R"(
  ____  _  _   ____  _   _ _   _ _ 
 / ___|| || | |  _ \| | | | |_(_) |
 \___ \| || |_| | | | | | | __| | |
  ___) |__   _| |_| | |_| | |_| | |
 |____/   |_| |____/ \___/ \__|_|_|
)";
    
    return vbox({
        text(title) | color(colors::primary) | center,
        text("Arch Linux Installer v1.0.0") | color(colors::muted) | center,
    });
}

Element Menu::render_footer() {
    std::string help;
    
    switch (current_page_) {
        case Page::Welcome:
            help = "Press Enter to continue • Q to quit";
            break;
        case Page::Installation:
            help = "Please wait...";
            break;
        case Page::Complete:
            help = "Press Enter to reboot • Q to exit";
            break;
        default:
            help = "Tab/Arrow: Navigate • Enter: Select • Esc: Back • Q: Quit";
            break;
    }
    
    return hbox({
        render_progress_bar() | flex,
        text(help) | color(colors::muted),
    });
}

Element Menu::render_progress_bar() {
    int total_pages = 8;
    int current = static_cast<int>(current_page_) + 1;
    
    std::vector<Element> steps;
    for (int i = 1; i <= total_pages; ++i) {
        Color c = i < current ? colors::success : 
                  i == current ? colors::primary : colors::muted;
        steps.push_back(text(i < current ? "●" : i == current ? "◉" : "○") | color(c));
        if (i < total_pages) {
            steps.push_back(text("─") | color(colors::muted));
        }
    }
    
    return hbox(steps);
}

void Menu::next_page() {
    int next = static_cast<int>(current_page_) + 1;
    if (next <= static_cast<int>(Page::Complete)) {
        current_page_ = static_cast<Page>(next);
    }
}

void Menu::prev_page() {
    int prev = static_cast<int>(current_page_) - 1;
    if (prev >= 0) {
        current_page_ = static_cast<Page>(prev);
    }
}

void Menu::goto_page(Page page) {
    current_page_ = page;
}

Component Menu::create_welcome_page() {
    auto continue_button = Button("  Start Installation  ", [this] {
        next_page();
    }, ButtonOption::Animated(colors::primary));
    
    auto quit_button = Button("  Exit  ", [this] {
        screen_.ExitLoopClosure()();
    }, ButtonOption::Animated(colors::error));
    
    auto buttons = Container::Horizontal({
        continue_button,
        quit_button,
    });
    
    return Renderer(buttons, [=] {
        return vbox({
            text("") | flex,
            text("Welcome to S4DUtil!") | bold | color(colors::primary) | center,
            text("") ,
            text("This tool will guide you through a minimal") | center,
            text("Arch Linux installation step by step.") | center,
            text(""),
            hbox({
                text("⚠ ") | color(colors::warning),
                text("WARNING: This will format your disk!") | color(colors::warning),
            }) | center,
            text("Make sure you have backed up important data.") | color(colors::muted) | center,
            text("") | flex,
            hbox({
                continue_button->Render(),
                text("  "),
                quit_button->Render(),
            }) | center,
            text("") | flex,
        });
    });
}

Component Menu::create_system_info_page() {
    auto continue_button = Button("  Continue  ", [this] {
        next_page();
    }, ButtonOption::Animated(colors::primary));
    
    auto back_button = Button("  Back  ", [this] {
        prev_page();
    }, ButtonOption::Animated(colors::muted));
    
    auto buttons = Container::Horizontal({back_button, continue_button});
    
    return Renderer(buttons, [=, this] {
        const auto& info = app_.get_system_info();
        
        auto status_icon = [](bool ok) {
            return ok ? text("✓") | color(colors::success) 
                      : text("✗") | color(colors::error);
        };
        
        return vbox({
            text("System Information") | bold | color(colors::primary) | center,
            text(""),
            vbox({
                hbox({status_icon(info.is_root), text(" Running as root")}),
                hbox({status_icon(info.is_live_iso), text(" Arch Linux Live ISO")}),
                hbox({status_icon(info.has_internet), text(" Internet connection")}),
                hbox({status_icon(info.is_uefi), text(" UEFI mode ("), 
                      text(info.is_uefi ? "UEFI" : "BIOS") | bold, text(")")}),
                hbox({text("• "), text("Architecture: "), text(info.arch) | bold}),
            }) | border | center,
            text(""),
            text("Available Disks:") | bold | center,
            [&] {
                Elements disks;
                for (const auto& disk : info.available_disks) {
                    disks.push_back(text("  • " + disk));
                }
                return vbox(disks) | center;
            }(),
            text("") | flex,
            [&] {
                bool can_continue = info.is_root && info.is_live_iso && info.has_internet;
                if (!can_continue) {
                    return text("⚠ Please fix the issues above before continuing") 
                           | color(colors::warning) | center;
                }
                return text("All checks passed!") | color(colors::success) | center;
            }(),
            text(""),
            hbox({
                back_button->Render(),
                text("  "),
                continue_button->Render(),
            }) | center,
        });
    });
}

Component Menu::create_disk_selection_page() {
    const auto& disks = app_.get_system_info().available_disks;
    
    auto radiobox = Radiobox(&app_.get_system_info().available_disks, &selected_disk_);
    
    auto continue_button = Button("  Continue  ", [this, &disks] {
        if (selected_disk_ >= 0 && selected_disk_ < static_cast<int>(disks.size())) {
            // Extract disk path from display string (e.g., "/dev/sda (100G)" -> "/dev/sda")
            std::string disk = disks[selected_disk_];
            size_t space_pos = disk.find(' ');
            if (space_pos != std::string::npos) {
                disk = disk.substr(0, space_pos);
            }
            app_.config().target_disk = disk;
            next_page();
        }
    }, ButtonOption::Animated(colors::primary));
    
    auto back_button = Button("  Back  ", [this] {
        prev_page();
    }, ButtonOption::Animated(colors::muted));
    
    auto container = Container::Vertical({
        radiobox,
        Container::Horizontal({back_button, continue_button}),
    });
    
    return Renderer(container, [=, this] {
        return vbox({
            text("Select Target Disk") | bold | color(colors::primary) | center,
            text(""),
            hbox({
                text("⚠ ") | color(colors::error),
                text("ALL DATA ON THE SELECTED DISK WILL BE ERASED!") | color(colors::error),
            }) | center,
            text(""),
            vbox({
                text("Available disks:") | bold,
                radiobox->Render(),
            }) | border | center,
            text("") | flex,
            hbox({
                back_button->Render(),
                text("  "),
                continue_button->Render(),
            }) | center,
        });
    });
}

Component Menu::create_configuration_page() {
    auto hostname_input = Input(&hostname_input_, "archlinux");
    
    auto timezone_dropdown = Dropdown({
        .radiobox = {.entries = &TIMEZONES, .selected = &selected_timezone_},
    });
    
    auto locale_dropdown = Dropdown({
        .radiobox = {.entries = &LOCALES, .selected = &selected_locale_},
    });
    
    std::vector<std::string> bootloader_options = {"GRUB", "systemd-boot"};
    auto bootloader_toggle = Toggle(&bootloader_options, &selected_bootloader_);
    
    auto continue_button = Button("  Continue  ", [this] {
        app_.config().hostname = hostname_input_.empty() ? "archlinux" : hostname_input_;
        app_.config().timezone = TIMEZONES[selected_timezone_];
        app_.config().locale = LOCALES[selected_locale_];
        app_.config().bootloader = selected_bootloader_ == 0 
            ? InstallConfig::Bootloader::Grub 
            : InstallConfig::Bootloader::SystemdBoot;
        next_page();
    }, ButtonOption::Animated(colors::primary));
    
    auto back_button = Button("  Back  ", [this] {
        prev_page();
    }, ButtonOption::Animated(colors::muted));
    
    auto container = Container::Vertical({
        hostname_input,
        timezone_dropdown,
        locale_dropdown,
        bootloader_toggle,
        Container::Horizontal({back_button, continue_button}),
    });
    
    return Renderer(container, [=, this] {
        return vbox({
            text("System Configuration") | bold | color(colors::primary) | center,
            text(""),
            vbox({
                hbox({text("Hostname:    "), hostname_input->Render() | flex}) | size(WIDTH, EQUAL, 50),
                text(""),
                hbox({text("Timezone:    "), timezone_dropdown->Render() | flex}),
                text(""),
                hbox({text("Locale:      "), locale_dropdown->Render() | flex}),
                text(""),
                hbox({text("Bootloader:  "), bootloader_toggle->Render()}),
            }) | border | center,
            text("") | flex,
            hbox({
                back_button->Render(),
                text("  "),
                continue_button->Render(),
            }) | center,
        });
    });
}

Component Menu::create_user_setup_page() {
    InputOption password_option;
    password_option.password = true;
    
    auto root_password = Input(&root_password_input_, "root password", password_option);
    auto root_confirm = Input(&root_password_confirm_, "confirm password", password_option);
    auto username = Input(&username_input_, "username");
    auto user_password = Input(&user_password_input_, "user password", password_option);
    auto user_confirm = Input(&user_password_confirm_, "confirm password", password_option);
    
    auto continue_button = Button("  Continue  ", [this] {
        // Validate passwords
        if (root_password_input_.empty()) {
            return;  // TODO: Show error
        }
        if (root_password_input_ != root_password_confirm_) {
            return;  // TODO: Show error
        }
        if (!username_input_.empty()) {
            if (user_password_input_.empty() || user_password_input_ != user_password_confirm_) {
                return;  // TODO: Show error
            }
        }
        
        app_.config().root_password = root_password_input_;
        app_.config().username = username_input_;
        app_.config().user_password = user_password_input_;
        next_page();
    }, ButtonOption::Animated(colors::primary));
    
    auto back_button = Button("  Back  ", [this] {
        prev_page();
    }, ButtonOption::Animated(colors::muted));
    
    auto container = Container::Vertical({
        root_password,
        root_confirm,
        username,
        user_password,
        user_confirm,
        Container::Horizontal({back_button, continue_button}),
    });
    
    return Renderer(container, [=, this] {
        bool passwords_match = root_password_input_ == root_password_confirm_;
        bool user_passwords_match = user_password_input_ == user_password_confirm_;
        
        return vbox({
            text("User Setup") | bold | color(colors::primary) | center,
            text(""),
            vbox({
                text("Root Password") | bold,
                root_password->Render() | size(WIDTH, EQUAL, 40),
                root_confirm->Render() | size(WIDTH, EQUAL, 40),
                passwords_match || root_password_confirm_.empty() 
                    ? text("") 
                    : text("Passwords do not match!") | color(colors::error),
                text(""),
                text("Create User (optional)") | bold,
                username->Render() | size(WIDTH, EQUAL, 40),
                user_password->Render() | size(WIDTH, EQUAL, 40),
                user_confirm->Render() | size(WIDTH, EQUAL, 40),
                user_passwords_match || user_password_confirm_.empty()
                    ? text("")
                    : text("Passwords do not match!") | color(colors::error),
            }) | border | center,
            text("") | flex,
            hbox({
                back_button->Render(),
                text("  "),
                continue_button->Render(),
            }) | center,
        });
    });
}

Component Menu::create_summary_page() {
    auto install_button = Button("  Begin Installation  ", [this] {
        next_page();
        // Start installation in the next page
    }, ButtonOption::Animated(colors::success));
    
    auto back_button = Button("  Back  ", [this] {
        prev_page();
    }, ButtonOption::Animated(colors::muted));
    
    auto buttons = Container::Horizontal({back_button, install_button});
    
    return Renderer(buttons, [=, this] {
        const auto& cfg = app_.config();
        const auto& info = app_.get_system_info();
        
        return vbox({
            text("Installation Summary") | bold | color(colors::primary) | center,
            text(""),
            text("Please review your settings:") | center,
            text(""),
            vbox({
                hbox({text("Target Disk:   ") | bold, text(cfg.target_disk)}),
                hbox({text("Boot Mode:     ") | bold, text(info.is_uefi ? "UEFI" : "BIOS")}),
                hbox({text("Bootloader:    ") | bold, 
                      text(cfg.bootloader == InstallConfig::Bootloader::Grub ? "GRUB" : "systemd-boot")}),
                separator(),
                hbox({text("Hostname:      ") | bold, text(cfg.hostname)}),
                hbox({text("Timezone:      ") | bold, text(cfg.timezone)}),
                hbox({text("Locale:        ") | bold, text(cfg.locale)}),
                separator(),
                hbox({text("Root Password: ") | bold, text("********")}),
                hbox({text("Username:      ") | bold, 
                      text(cfg.username.empty() ? "(none)" : cfg.username)}),
            }) | border | center,
            text(""),
            hbox({
                text("⚠ ") | color(colors::warning),
                text("This will ERASE ALL DATA on ") | color(colors::warning),
                text(cfg.target_disk) | bold | color(colors::error),
            }) | center,
            text("") | flex,
            hbox({
                back_button->Render(),
                text("  "),
                install_button->Render(),
            }) | center,
        });
    });
}

Component Menu::create_installation_page() {
    // This runs the installation
    auto renderer = Renderer([this] {
        const auto& steps = app_.steps();
        
        Elements step_elements;
        for (size_t i = 0; i < steps.size(); ++i) {
            const auto& step = steps[i];
            
            Color c;
            std::string icon;
            switch (step.status) {
                case StepStatus::Pending:
                    c = colors::muted;
                    icon = "○";
                    break;
                case StepStatus::InProgress:
                    c = colors::primary;
                    icon = "◉";
                    break;
                case StepStatus::Completed:
                    c = colors::success;
                    icon = "✓";
                    break;
                case StepStatus::Failed:
                    c = colors::error;
                    icon = "✗";
                    break;
                case StepStatus::Skipped:
                    c = colors::warning;
                    icon = "○";
                    break;
            }
            
            step_elements.push_back(
                hbox({
                    text(icon + " ") | color(c),
                    text(step.name) | color(c),
                })
            );
        }
        
        return vbox({
            text("Installing Arch Linux") | bold | color(colors::primary) | center,
            text(""),
            text("Please wait while the system is being installed...") | center,
            text(""),
            vbox(step_elements) | border | center,
            text(""),
            text(installation_output_) | color(colors::muted) | size(HEIGHT, LESS_THAN, 10),
            text("") | flex,
        });
    });
    
    return renderer;
}

Component Menu::create_complete_page() {
    auto reboot_button = Button("  Reboot Now  ", [this] {
        system("reboot");
    }, ButtonOption::Animated(colors::success));
    
    auto exit_button = Button("  Exit  ", [this] {
        screen_.ExitLoopClosure()();
    }, ButtonOption::Animated(colors::muted));
    
    auto buttons = Container::Horizontal({exit_button, reboot_button});
    
    return Renderer(buttons, [=] {
        return vbox({
            text("") | flex,
            text("🎉") | center,
            text("Installation Complete!") | bold | color(colors::success) | center,
            text(""),
            text("Arch Linux has been successfully installed.") | center,
            text(""),
            text("You can now reboot into your new system.") | center,
            text(""),
            text("Remember to remove the installation media!") | color(colors::warning) | center,
            text("") | flex,
            hbox({
                exit_button->Render(),
                text("  "),
                reboot_button->Render(),
            }) | center,
            text("") | flex,
        });
    });
}

} // namespace s4d
