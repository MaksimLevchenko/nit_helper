# nit-helper

**nit-helper** is a cross-platform Dart CLI tool designed to automate building Flutter and Serverpod projects.

The tool automatically detects the necessary directories (`*_flutter`, `*_server`) and executes the appropriate commands, with optional `fvm` support.

---

## ✨ Features

- 📦 Automatic Flutter module building  
- 🛠 Code generation and migrations for Serverpod  
- 🔁 Support for `fvm` (Flutter Version Management)  
- 🧠 Smart project structure navigation  
- 🔧 Commands unified in a single CLI: `nit-helper`  
- 🗑️ Unused files detection and cleanup

---

## 🚀 Installation

```bash
dart pub global activate nit_helper
```

Ensure that the Dart global utilities path is added to `PATH`:

* **Linux/macOS**:
  ```bash
  export PATH="$PATH:$HOME/.pub-cache/bin"
  ```
* **Windows**:
  Open **System Properties → Advanced → Environment Variables** and add
  ```
  %APPDATA%\Pub\Cache\bin
  ```
  to the `Path` variable.

---

## 🧪 Usage

### 🔨 `build`

Builds the Flutter project (searches for a directory ending with `_flutter`, or works in the current directory if it matches).

```bash
nit-helper build
```

With `fvm`:
```bash
nit-helper build --fvm
```

Executes commands:
* `dart run build_runner build`
* `fluttergen`

---

### 🖥 `build-server`

Generates Serverpod code and applies migrations. Searches for a directory ending with `_server`.

```bash
nit-helper build-server
```

Force migration creation:
```bash
nit-helper build-server --force
```

With `fvm`:
```bash
nit-helper build-server --fvm
```

Executes commands:
* `serverpod generate`
* `serverpod create-migration` (or `--force`)
* `dart run bin/main.dart --role maintenance --apply-migrations`

---

### 🔁 `build-full`

Combines `build` and `build-server`:

```bash
nit-helper build-full
```

With options:
```bash
nit-helper build-full --fvm --force
```

---

### 🔍 `check`

Analyzes the project for unused Dart files and provides cleanup options.

```bash
nit-helper check
```

With options:
```bash
# Scan specific project
nit-helper check --path ./my_project

# Exclude patterns and folders
nit-helper check --exclude-pattern "*.g.dart" --exclude-folder "generated"

# Interactive cleanup mode
nit-helper check --interactive

# Combine options
nit-helper check -p ./project -e "*.test.dart" -f "temp" -i
```

Features:
* Smart dependency analysis via import/export parsing
* Automatic exclusion of generated files (*.g.dart, *.freezed.dart, etc.)
* Interactive cleanup with confirmation prompts
* Cross-platform support
* Detailed size reporting

---

## 🧰 Arguments

| Argument | Command | Description |
| -------- | ------- | ----------- |
| `--fvm` | all commands | Execute through `fvm exec` |
| `--force` | `build-server`, `build-full` | Force create migrations |
| `--path`, `-p` | `check` | Path to project directory |
| `--exclude-pattern`, `-e` | `check` | File patterns to exclude |
| `--exclude-folder`, `-f` | `check` | Folders to exclude |
| `--interactive`, `-i` | `check` | Enable interactive cleanup |
| `--details`, `-d` | `check` | Show detailed file list |

---

## 💡 Examples

```bash
# Build Flutter with fvm
nit-helper build --fvm

# Build Serverpod with forced migration
nit-helper build-server --force

# Full project build
nit-helper build-full --fvm --force

# Check for unused files
nit-helper check

# Interactive cleanup with exclusions  
nit-helper check --exclude-pattern "*.g.dart" --interactive
```

---

## 📂 Project Structure

```text
project_root/
├── my_app_flutter/
│   └── main.dart
├── my_app_server/
│   └── bin/main.dart
```

`nit-helper` will automatically detect where `*_flutter` and `*_server` are located and execute the appropriate commands.

---

## 🙏 Acknowledgments

Special thanks to **[Emad Beltaje](https://github.com/EmadBeltaje)** for the original [dart_unused_files](https://github.com/EmadBeltaje/dart_unused_files) package, which inspired and provided the foundation for the unused files detection functionality in the `check` command.

---

## 📜 License

MIT License.
© 2025 Maksim Levchenko

---

## 📫 Feedback

Report bugs or suggestions:
[GitHub Issues](https://github.com/MaksimLevchenko/nit-helper/issues)