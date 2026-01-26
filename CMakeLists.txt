cmake_minimum_required(VERSION 3.14)

project(s4dutil
    VERSION 1.0.0
    DESCRIPTION "S4D's Arch Linux Installer - A TUI-based minimal Arch installation tool"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Fetch FTXUI - Modern C++ TUI Library
include(FetchContent)

FetchContent_Declare(ftxui
    GIT_REPOSITORY https://github.com/ArthurSonzogni/ftxui
    GIT_TAG v5.0.0
)

FetchContent_GetProperties(ftxui)
if(NOT ftxui_POPULATED)
    FetchContent_Populate(ftxui)
    add_subdirectory(${ftxui_SOURCE_DIR} ${ftxui_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

# Fetch toml++ for config parsing
FetchContent_Declare(tomlplusplus
    GIT_REPOSITORY https://github.com/marzer/tomlplusplus.git
    GIT_TAG v3.4.0
)
FetchContent_MakeAvailable(tomlplusplus)

# Main executable
add_executable(s4dutil
    src/main.cpp
    src/app.cpp
    src/menu.cpp
    src/executor.cpp
    src/utils.cpp
    src/installer.cpp
)

target_include_directories(s4dutil PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(s4dutil
    PRIVATE ftxui::screen
    PRIVATE ftxui::dom
    PRIVATE ftxui::component
    PRIVATE tomlplusplus::tomlplusplus
)

# Install targets
install(TARGETS s4dutil DESTINATION bin)
install(DIRECTORY scripts/ DESTINATION share/s4dutil/scripts
    FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)
install(DIRECTORY config/ DESTINATION share/s4dutil/config)

# For development - copy scripts to build directory
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/scripts DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/config DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
