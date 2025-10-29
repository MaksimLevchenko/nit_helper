import 'dart:io';

class PathResolver {
  static Future<void> changeToDirectory(String endsWith) async {
    final hasPubspec = File('pubspec.yaml').existsSync();
    if (hasPubspec) return;

    final currentDir = Directory.current.path;
    if (!currentDir.contains(endsWith)) {
      final dirs = Directory.current.listSync().whereType<Directory>();
      final targetDir = dirs.firstWhere(
        (dir) => dir.path.endsWith(endsWith),
        orElse: () =>
            throw Exception('Directory "$endsWith" not found in current path'),
      );
      Directory.current = targetDir;
    }
  }
}
