#pragma once

#include "app.hpp"
#include <ftxui/component/component.hpp>
#include <ftxui/component/screen_interactive.hpp>
#include <ftxui/dom/elements.hpp>

namespace s4d {

class Menu {
public:
    explicit Menu(App& app);
    
    // Run the TUI
    int run();

private:
    // Screen pages
    enum class Page {
        Welcome,
        SystemInfo,
        DiskSelection,
        Configuration,
        UserSetup,
        Summary,
        Installation,
        Complete
    };
    
    // Create components for each page
    ftxui::Component create_welcome_page();
    ftxui::Component create_system_info_page();
    ftxui::Component create_disk_selection_page();
    ftxui::Component create_configuration_page();
    ftxui::Component create_user_setup_page();
    ftxui::Component create_summary_page();
    ftxui::Component create_installation_page();
    ftxui::Component create_complete_page();
    
    // Navigation
    void next_page();
    void prev_page();
    void goto_page(Page page);
    
    // Helpers
    ftxui::Element render_header();
    ftxui::Element render_footer();
    ftxui::Element render_progress_bar();
    
    // State
    App& app_;
    Page current_page_ = Page::Welcome;
    ftxui::ScreenInteractive screen_ = ftxui::ScreenInteractive::Fullscreen();
    
    // Form state
    int selected_disk_ = 0;
    int selected_timezone_ = 0;
    int selected_locale_ = 0;
    int selected_bootloader_ = 0;
    std::string hostname_input_;
    std::string root_password_input_;
    std::string root_password_confirm_;
    std::string username_input_;
    std::string user_password_input_;
    std::string user_password_confirm_;
    
    // Installation state
    int current_step_ = 0;
    bool installation_running_ = false;
    bool installation_complete_ = false;
    std::string installation_output_;
};

} // namespace s4d
