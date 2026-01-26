#!/bin/bash
# Build script for s4dutil

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

echo "=== S4DUtil Build Script ==="
echo ""

# Check for required tools
check_requirements() {
    local missing=()
    
    command -v cmake >/dev/null 2>&1 || missing+=("cmake")
    command -v g++ >/dev/null 2>&1 || missing+=("g++")
    command -v git >/dev/null 2>&1 || missing+=("git")
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo "Missing required tools: ${missing[*]}"
        echo ""
        echo "Install with:"
        echo "  Arch: sudo pacman -S cmake gcc git"
        echo "  Ubuntu: sudo apt install cmake g++ git"
        echo "  Fedora: sudo dnf install cmake gcc-c++ git"
        exit 1
    fi
}

# Build the project
build() {
    echo "Creating build directory..."
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    echo "Running CMake..."
    cmake ..
    
    echo ""
    echo "Building..."
    make -j"$(nproc)"
    
    echo ""
    echo "=== Build Complete ==="
    echo "Binary: $BUILD_DIR/s4dutil"
    echo ""
    echo "Run with: ./build/s4dutil"
}

# Clean build directory
clean() {
    echo "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    echo "Done!"
}

# Show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build   - Build the project (default)"
    echo "  clean   - Remove build directory"
    echo "  rebuild - Clean and build"
    echo "  help    - Show this help"
}

case "${1:-build}" in
    build)
        check_requirements
        build
        ;;
    clean)
        clean
        ;;
    rebuild)
        clean
        check_requirements
        build
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
