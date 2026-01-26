# Contributing to S4DUtil

Thank you for your interest in contributing to S4DUtil!

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (Arch ISO version, hardware)

### Suggesting Features

1. Open an issue with the "feature request" label
2. Describe the feature and why it would be useful
3. Provide examples if possible

### Code Contributions

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test on an Arch Live ISO (use a VM!)
5. Commit with clear messages
6. Push and create a Pull Request

## Development Setup

### Requirements

- CMake 3.14+
- C++17 compiler (GCC 8+)
- Git

### Building

```bash
git clone https://github.com/Sadbin47/s4dutil.git
cd s4dutil
./build.sh
```

### Testing

**Always test in a virtual machine!** This tool formats disks.

1. Create a VM with Arch ISO
2. Build s4dutil
3. Run through the installation process

## Code Style

- Use 4 spaces for indentation
- Follow existing code patterns
- Comment complex logic
- Keep functions focused and small

## Shell Scripts

- Use POSIX sh for compatibility
- Source `common.sh` for shared functions
- Use `shellcheck` for linting
- Handle errors properly

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
