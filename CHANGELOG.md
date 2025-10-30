# Changelog

## [1.5.2] 

### 🐛 Fixed
- **Build-server**: Fix error when build-server returns "serverpod.yaml" not found

---

## [1.5.1]

### 🐛 Changed
- **Cleanup**: Removed unused exports from `lib/nit_helper.dart` to streamline the library interface

## [1.5.0]

### ✨ Added
- **Get All Dependencies**: New `get-all` command that recursively finds all subprojects with `pubspec.yaml` and runs `dart pub get` in each
- **Smart Folder Exclusion**: Automatically excludes standard Flutter folders (build, ios, android, web, windows, macos, linux) when scanning for subprojects
- 
---

## [1.4.0]

### ✨ Added
- **Unused Files Detection**: Complete implementation of `check` command inspired by [dart_unused_files](https://github.com/EmadBeltaje/dart_unused_files) package
- **Interactive Cleanup**: Added interactive mode for unused files removal with user confirmation
- **Smart File Analysis**: Dependency graph analysis via import/export parsing to accurately detect unused files
- **Flexible Exclusions**: Support for custom file patterns and folder exclusions via command-line options
- **Test Project**: Added comprehensive test project with freezed models to validate nit-helper functionality

### 🔧 Changed  
- **Project Structure**: Refactored entire codebase to separate models into individual files for improved maintainability
- **Command Output**: Enhanced output formatting with better visual presentation and progress indicators
- **Process Execution**: Improved command execution with `ProcessStartMode.inheritStdio` to preserve interactive terminal features
- **Error Handling**: Completely redesigned error handling system with better user feedback and recovery options

### 📚 Updated
- **Documentation**: Comprehensive updates to README.md with detailed usage examples and feature descriptions  
- **Help System**: Enhanced help printer with complete documentation for all commands and options

---

## [1.3.6] 

### 🔧 Changed
- **Build Commands**: Refactored build and check commands to include `--force` option for migration handling
- **Directory Navigation**: Streamlined directory detection and navigation logic

---

## [1.3.5]

### 🐛 Fixed
- **Version Checking**: Resolved bug where nit-helper incorrectly validated current version information

---

## [1.3.1] 

### ✨ Added
- **Auto-Updates**: Implemented version checking and automatic update functionality
- **Update Notifications**: Added notifications when newer versions are available

---

## [1.3.0]

### ✨ Added
- **Static Analysis**: Introduced `check` command for static code analysis
- **Version Bump**: Updated to version 1.3.0 with enhanced stability

### 🔧 Changed
- **Build Commands**: Refactored build command structure for better modularity

---

## [1.2.0]

### 🔧 Changed
- **Output Enhancement**: Enhanced `runCmd` to display current directory in command output
- **Navigation**: Streamlined directory navigation logic for build commands
- **User Experience**: Improved command feedback with better context information

---

## [1.1.31]

### 🔧 Changed
- **Process Handling**: Refactored `runCmd` to use `Process.start` for improved real-time streaming of stdout and stderr
- **Performance**: Better handling of long-running processes with live output

---

## [1.1.3]

### 🔧 Changed
- **Encoding Support**: Enhanced `runCmd` with proper UTF-8 encoding support for stdout and stderr
- **Internationalization**: Improved support for non-ASCII characters in command output

---

## [1.1.2]

### 📚 Updated
- **Documentation**: Updated README.md with improved installation instructions and usage examples

---

## [1.1.1]

### ✨ Added
- **Dependency Detection**: Automatic checking for required system commands availability
- **Auto-Installation**: Intelligent installation of missing dependencies with user guidance
- **Error Prevention**: Proactive detection of missing tools before command execution

---

## [1.0.0]

### 🎉 Initial Release
- **Flutter Build**: Automated Flutter project building with `dart run build_runner build` and `fluttergen`
- **Serverpod Support**: Complete Serverpod integration with code generation and migration support  
- **FVM Integration**: Full support for Flutter Version Management (FVM)
- **Smart Navigation**: Automatic detection of `*_flutter` and `*_server` directories
- **Cross-Platform**: Support for Windows, macOS, and Linux
- **CLI Interface**: Unified command-line interface with intuitive commands

---

## Legend

- 🎉 **Major Features** - Significant new functionality
- ✨ **Added** - New features and capabilities  
- 🔧 **Changed** - Changes in existing functionality
- 🐛 **Fixed** - Bug fixes and error corrections
- 📚 **Updated** - Documentation and README updates
- ⚡ **Performance** - Performance improvements
- 🔒 **Security** - Security-related changes
