# nit-helper

A command-line tool to build Flutter and Serverpod projects with optional fvm support.

## Installation

```bash
dart pub global activate nit_helper

# Usage

nit-helper build --fvm
nit-helper build-server --f
nit-helper build-full --fvm --f


---

### 📄 `CHANGELOG.md`

```md
## 0.1.0

- Initial release with `build`, `build-server`, and `build-full` commands.
- Added optional `--fvm` flag for Flutter version management.
- Support for building Serverpod projects.
- Basic error handling and user feedback.
```