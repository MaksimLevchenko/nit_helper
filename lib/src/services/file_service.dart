import 'dart:io';
import '../utils/logger.dart';

class FileService {
  Future<void> changeToDirectory(String endsWith) async {
    final hasPubspec = File('pubspec.yaml').existsSync();
    if (hasPubspec) return;

    final currentDir = Directory.current.path;
    if (!currentDir.contains(endsWith)) {
      final dirs = Directory.current.listSync().whereType<Directory>();

      try {
        final targetDir = dirs.firstWhere(
          (dir) => dir.path.endsWith(endsWith),
        );
        Directory.current = targetDir;
      } on StateError {
        throw Exception('Directory "$endsWith" not found. '
            'Available directories: ${dirs.map((d) => d.path.split('/').last).join(', ')}');
      }
    }
  }

  bool fileExists(String path) => File(path).existsSync();

  String readFile(String path) => File(path).readAsStringSync();

  void writeFile(String path, String content) =>
      File(path).writeAsStringSync(content);
}
