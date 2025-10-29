class HelpPrinter {
  void printHelp() {
    print('''
nit-helper - Unified build tool for Dart/Flutter/Serverpod projects

Usage:
  nit-helper build [--fvm] [--force]       Build Flutter module
  nit-helper build-server [--fvm] [--force] Build Serverpod server
  nit-helper build-full [--fvm] [--force]   Build both frontend and backend
  nit-helper check [options]               Analyze project for unused files

Options:
  --fvm    Run commands through "fvm exec"
  --force  Force operations (migrations, etc.)

Check Command Options:
  -p, --path <directory>           Path to project directory (default: current)
  -e, --exclude-pattern <pattern>  File patterns to exclude (e.g., "*.g.dart")
  -f, --exclude-folder <folder>    Folders to exclude (e.g., "generated")
  -d, --[no-]details              Show detailed list of unused files (default: on)
  -i, --interactive                Enable interactive cleanup mode
  -h, --help                       Show help for check command

Examples:
  nit-helper build --fvm
  nit-helper build-server --force
  nit-helper build-full --fvm --force
  
  nit-helper check
  nit-helper check --path ./my_project
  nit-helper check --exclude-pattern "*.g.dart" --exclude-pattern "*.freezed.dart"
  nit-helper check --exclude-folder "generated" --exclude-folder "build"
  nit-helper check --interactive --no-details
  nit-helper check -p ./project -e "*.test.dart" -f "temp" -i

Check Command Features:
  • Unused Dart files detection and removal
  • Smart dependency analysis via import/export parsing
  • Automatic exclusion of generated files (*.g.dart, *.freezed.dart, etc.)
  • Interactive cleanup with confirmation prompts
  • Cross-platform support (Windows, macOS, Linux)
  • Detailed size reporting of unused files

Automatically Excluded:
  Files: *.g.dart, *.gr.dart, *.freezed.dart, *.mocks.dart, firebase_options.dart
  Folders: generated, .dart_tool, build, .fvm, .git
''');
  }
}
