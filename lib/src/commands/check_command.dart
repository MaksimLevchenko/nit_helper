import 'dart:io';

class UnusedFileResult {
  final List<String> unusedFiles;
  final int totalFiles;
  final int usedFiles;
  final double totalSizeKb;

  UnusedFileResult({
    required this.unusedFiles,
    required this.totalFiles,
    required this.usedFiles,
    required this.totalSizeKb,
  });

  int get unusedCount => unusedFiles.length;
  String get formattedSize => '${totalSizeKb.toStringAsFixed(2)} KB';
}

class UnusedFileScanner {
  static const List<String> _defaultExcludePatterns = [
    '*.g.dart',
    '*.gr.dart',
    '*.freezed.dart',
    '*.mocks.dart',
    'generated_plugin_registrant.dart',
    'firebase_options.dart',
  ];

  static const List<String> _defaultExcludeFolders = [
    'generated',
    '.dart_tool',
    'build',
    '.fvm',
    '.git',
  ];

  /// Сканирует проект на наличие неиспользуемых Dart файлов
  Future<UnusedFileResult> scanProject({
    String? projectPath,
    List<String> excludePatterns = const [],
    List<String> excludeFolders = const [],
  }) async {
    final path = projectPath ?? Directory.current.path;
    final projectDir = Directory(path);

    if (!projectDir.existsSync()) {
      throw ArgumentError('Project directory does not exist: $path');
    }

    print('🔍 Scanning for unused Dart files...');

    // Собираем все Dart файлы
    final allDartFiles = await _collectDartFiles(
      projectDir,
      [..._defaultExcludePatterns, ...excludePatterns],
      [..._defaultExcludeFolders, ...excludeFolders],
    );

    print('📁 Analyzing ${allDartFiles.length} Dart files');

    // Читаем содержимое файлов
    print('📑 Reading Dart files...');
    final fileContents = await _readFileContents(allDartFiles);
    print('✅ Read ${fileContents.length} Dart files');

    // Анализируем зависимости
    final dependencyMap = _buildDependencyMap(fileContents);

    // Находим точки входа
    final entryPoints = _findEntryPoints(fileContents);

    // Определяем используемые файлы
    final usedFiles = _findUsedFiles(dependencyMap, entryPoints);

    // Находим неиспользуемые файлы
    final unusedFiles =
        allDartFiles.where((file) => !usedFiles.contains(file)).toList();

    // Подсчитываем размер неиспользуемых файлов
    final totalSize = await _calculateTotalSize(unusedFiles);

    return UnusedFileResult(
      unusedFiles: unusedFiles,
      totalFiles: allDartFiles.length,
      usedFiles: usedFiles.length,
      totalSizeKb: totalSize / 1024,
    );
  }

  /// Собирает все Dart файлы в проекте
  Future<List<String>> _collectDartFiles(
    Directory projectDir,
    List<String> excludePatterns,
    List<String> excludeFolders,
  ) async {
    final dartFiles = <String>[];

    await for (final entity in projectDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = entity.path.replaceFirst(projectDir.path, '');

        // Проверяем исключения по папкам
        if (_shouldExcludeByFolder(relativePath, excludeFolders)) continue;

        // Проверяем исключения по паттернам
        if (_shouldExcludeByPattern(entity.path, excludePatterns)) continue;

        dartFiles.add(entity.path);
      }
    }

    return dartFiles;
  }

  /// Проверяет, нужно ли исключить файл по папке
  bool _shouldExcludeByFolder(String path, List<String> excludeFolders) {
    for (final folder in excludeFolders) {
      if (path.contains(
              Platform.pathSeparator + folder + Platform.pathSeparator) ||
          path.startsWith(
              Platform.pathSeparator + folder + Platform.pathSeparator)) {
        return true;
      }
    }
    return false;
  }

  /// Проверяет, нужно ли исключить файл по паттерну
  bool _shouldExcludeByPattern(String path, List<String> excludePatterns) {
    final fileName = path.split(Platform.pathSeparator).last;

    for (final pattern in excludePatterns) {
      if (pattern.startsWith('*') && fileName.endsWith(pattern.substring(1))) {
        return true;
      } else if (pattern.endsWith('*') &&
          fileName.startsWith(pattern.substring(0, pattern.length - 1))) {
        return true;
      } else if (fileName == pattern) {
        return true;
      }
    }
    return false;
  }

  /// Читает содержимое всех файлов
  Future<Map<String, String>> _readFileContents(List<String> files) async {
    final contents = <String, String>{};

    for (final filePath in files) {
      try {
        final file = File(filePath);
        final content = await file.readAsString();
        contents[filePath] = content;
      } catch (e) {
        print('⚠️ Failed to read file: $filePath');
      }
    }

    return contents;
  }

  /// Строит карту зависимостей между файлами
  Map<String, Set<String>> _buildDependencyMap(
      Map<String, String> fileContents) {
    final dependencyMap = <String, Set<String>>{};

    for (final entry in fileContents.entries) {
      final filePath = entry.key;
      final content = entry.value;
      final dependencies = <String>{};

      // Анализируем импорты
      final importRegex = RegExp("import\\s+['\"]([^'\"]+)['\"]");
      final exportRegex = RegExp("export\\s+['\"]([^'\"]+)['\"]");

      // Найти все импорты
      for (final match in importRegex.allMatches(content)) {
        final importPath = match.group(1);
        if (importPath != null &&
            !importPath.startsWith('dart:') &&
            !importPath.startsWith('package:')) {
          final resolvedPath = _resolveImportPath(filePath, importPath);
          if (resolvedPath != null) {
            dependencies.add(resolvedPath);
          }
        }
      }

      // Найти все экспорты
      for (final match in exportRegex.allMatches(content)) {
        final exportPath = match.group(1);
        if (exportPath != null &&
            !exportPath.startsWith('dart:') &&
            !exportPath.startsWith('package:')) {
          final resolvedPath = _resolveImportPath(filePath, exportPath);
          if (resolvedPath != null) {
            dependencies.add(resolvedPath);
          }
        }
      }

      dependencyMap[filePath] = dependencies;
    }

    return dependencyMap;
  }

  /// Разрешает относительный путь импорта
  String? _resolveImportPath(String currentFile, String importPath) {
    try {
      final currentDir = Directory(currentFile).parent;
      final targetFile =
          File.fromUri(currentDir.uri.resolve('$importPath.dart'));

      if (targetFile.existsSync()) {
        return targetFile.path;
      }

      // Попробуем без добавления .dart
      final targetFileWithoutExt =
          File.fromUri(currentDir.uri.resolve(importPath));
      if (targetFileWithoutExt.existsSync()) {
        return targetFileWithoutExt.path;
      }
    } catch (e) {
      // Игнорируем ошибки разрешения путей
    }

    return null;
  }

  /// Находит точки входа в приложении
  Set<String> _findEntryPoints(Map<String, String> fileContents) {
    final entryPoints = <String>{};

    for (final entry in fileContents.entries) {
      final filePath = entry.key;
      final content = entry.value;

      // main.dart всегда точка входа
      if (filePath.endsWith('main.dart')) {
        entryPoints.add(filePath);
      }

      // Файлы с функцией main
      if (content.contains(RegExp(r'void\s+main\s*\('))) {
        entryPoints.add(filePath);
      }

      // Тестовые файлы
      if (filePath.contains('test') && content.contains('testWidgets(')) {
        entryPoints.add(filePath);
      }
    }

    return entryPoints;
  }

  /// Находит все используемые файлы через анализ достижимости
  Set<String> _findUsedFiles(
      Map<String, Set<String>> dependencyMap, Set<String> entryPoints) {
    final usedFiles = <String>{};
    final queue = <String>[];

    // Начинаем с точек входа
    queue.addAll(entryPoints);
    usedFiles.addAll(entryPoints);

    // BFS для поиска всех достижимых файлов
    while (queue.isNotEmpty) {
      final currentFile = queue.removeAt(0);
      final dependencies = dependencyMap[currentFile] ?? <String>{};

      for (final dependency in dependencies) {
        if (!usedFiles.contains(dependency)) {
          usedFiles.add(dependency);
          queue.add(dependency);
        }
      }
    }

    return usedFiles;
  }

  /// Подсчитывает общий размер файлов
  Future<int> _calculateTotalSize(List<String> files) async {
    int totalSize = 0;

    for (final filePath in files) {
      try {
        final file = File(filePath);
        final stat = await file.stat();
        totalSize += stat.size;
      } catch (e) {
        // Игнорируем ошибки получения размера
      }
    }

    return totalSize;
  }
}

class CheckCommand {
  final UnusedFileScanner _scanner = UnusedFileScanner();

  CheckCommand();

  // Оригинальный метод для обратной совместимости
  Future<int> execute() async {
    try {
      await executeWithResult();
      return 0;
    } catch (e) {
      return 1;
    }
  }

  // Новый метод с полным функционалом
  Future<UnusedFileResult> executeWithResult({
    String? projectPath,
    List<String> excludePatterns = const [],
    List<String> excludeFolders = const [],
    bool showDetails = true,
  }) async {
    try {
      final path = projectPath ?? Directory.current.path;

      print('🚀 Starting unused files analysis...');
      print('📂 Project path: $path');
      print('');

      final result = await _scanner.scanProject(
        projectPath: path,
        excludePatterns: excludePatterns,
        excludeFolders: excludeFolders,
      );

      _printResults(result, showDetails);

      return result;
    } catch (e) {
      print('❌ Error during analysis: $e');
      rethrow;
    }
  }

  void _printResults(UnusedFileResult result, bool showDetails) {
    print('============================================================');
    print('📊 UNUSED FILES ANALYSIS');
    print('============================================================');
    print('Total files scanned: ${result.totalFiles}');
    print('Files definitely used: ${result.usedFiles}');
    print('Files definitely unused: ${result.unusedCount}');
    print('============================================================');

    if (result.unusedCount > 0) {
      print('🗑️ UNUSED FILES (safe to remove) 🔻');

      if (showDetails) {
        for (final file in result.unusedFiles) {
          final relativePath = file.replaceFirst(Directory.current.path, '');
          print('   - 📄 $relativePath');
        }
      } else {
        print('   ${result.unusedCount} files found');
      }

      print('--------------------------------------------------');
      print('💡 These files are NOT imported/exported/referenced anywhere.');
      print('💡 They are safe to delete after a final manual review.');
      print('💾 Total size of unused files: ${result.formattedSize}');
      print('--------------------------------------------------');
    } else {
      print('🎉 No unused files found! Your project is clean.');
    }

    print('');
  }

  /// Дополнительный метод для интерактивного удаления файлов
  Future<void> interactiveCleanup(UnusedFileResult result) async {
    if (result.unusedCount == 0) {
      print('🎉 No files to clean up!');
      return;
    }

    print('');
    print('🤔 Would you like to delete these unused files? (y/N): ');

    final input = stdin.readLineSync();
    if (input?.toLowerCase() == 'y' || input?.toLowerCase() == 'yes') {
      await _deleteUnusedFiles(result.unusedFiles);
    } else {
      print('👍 Files kept. You can review and delete them manually.');
    }
  }

  Future<void> _deleteUnusedFiles(List<String> unusedFiles) async {
    print('🗑️ Deleting unused files...');

    int deletedCount = 0;
    for (final filePath in unusedFiles) {
      try {
        final file = File(filePath);
        await file.delete();
        print(
            '   ✅ Deleted: ${filePath.replaceFirst(Directory.current.path, '')}');
        deletedCount++;
      } catch (e) {
        print(
            '   ❌ Failed to delete: ${filePath.replaceFirst(Directory.current.path, '')} - $e');
      }
    }

    print('');
    print(
        '🎉 Cleanup completed! Deleted $deletedCount out of ${unusedFiles.length} files.');
  }
}
