import 'dart:io';
import '../services/process_service.dart';

class GetAllCommand {
  final ProcessService _processService;

  GetAllCommand(this._processService);

  /// Рекурсивно выполняет dart pub get во всех подпапках с pubspec.yaml
  Future<int> execute({String? path, bool useFvm = false}) async {
    final startDir = Directory.current.path;
    final searchDir = path != null ? Directory(path).absolute.path : startDir;

    try {
      print(
          '\x1B[36m🔍 Searching for Dart/Flutter projects in: $searchDir\x1B[0m');

      // Находим все подпапки с pubspec.yaml (включая стартовую папку)
      final projects = await _findDartProjects(Directory(searchDir));

      if (projects.isEmpty) {
        print('\x1B[33m⚠ No Dart/Flutter projects found\x1B[0m');
        return 0;
      }

      print('\x1B[32m📁 Found ${projects.length} projects:\x1B[0m');
      for (final project in projects) {
        final relativePath = _getRelativePath(project, searchDir);
        print('   - $relativePath');
      }

      print('');

      // Выполняем dart pub get в каждом проекте
      final projectResults = <String, bool>{};

      for (final projectPath in projects) {
        final result =
            await _runPubGetInProject(projectPath, searchDir, useFvm);
        final relativePath = _getRelativePath(projectPath, searchDir);
        projectResults[relativePath] = result == 0;
      }

      // Вывод итогов с красивой структурой
      print('');
      print('=' * 50);
      print('📊 GET ALL SUMMARY');
      print('=' * 50);
      print('');
      _printProjectTree(searchDir, projectResults);
      print('');

      final successCount = projectResults.values.where((v) => v).length;
      final failCount = projectResults.values.where((v) => !v).length;

      print('Total projects: ${projectResults.length}');
      print('\x1B[32mSuccessful: $successCount\x1B[0m');

      if (failCount > 0) {
        print('\x1B[31mFailed: $failCount\x1B[0m');
        return 1;
      } else {
        print('\x1B[32mAll projects processed successfully! 🎉\x1B[0m');
        return 0;
      }
    } catch (e) {
      print('\x1B[31m❌ Error during get-all execution: $e\x1B[0m');
      return 1;
    } finally {
      Directory.current = startDir;
    }
  }

  /// Рекурсивно находит все папки с pubspec.yaml, начиная с указанной директории
  Future<List<String>> _findDartProjects(Directory directory) async {
    final projects = <String>[];
    final excludedFolders = _getExcludedFolders();
    final visited = <String>{};

    Future<void> searchRecursively(Directory dir) async {
      try {
        final canonicalPath = dir.absolute.path;

        // Избегаем бесконечных циклов (симлинки)
        if (visited.contains(canonicalPath)) {
          return;
        }
        visited.add(canonicalPath);

        // Получаем список сущностей в текущей директории
        final List<FileSystemEntity> entities;
        try {
          entities = await dir.list().toList();
        } catch (e) {
          // Пропускаем директории, в которые нет доступа
          return;
        }

        // Проверяем есть ли pubspec.yaml в текущей папке
        final pubspecFile =
            File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
        if (await pubspecFile.exists()) {
          projects.add(dir.absolute.path);
          // Продолжаем искать в подпапках этого проекта
        }

        // Рекурсивно ищем в подпапках
        for (final entity in entities) {
          if (entity is Directory) {
            final dirName = entity.path.split(Platform.pathSeparator).last;

            // Пропускаем исключенные папки (но не если это подпапка проекта с pubspec.yaml)
            if (excludedFolders.contains(dirName)) continue;

            // Рекурсивно ищем в подпапках
            await searchRecursively(entity);
          }
        }
      } catch (e) {
        // Игнорируем ошибки доступа к некоторым папкам
      }
    }

    await searchRecursively(directory);
    return projects;
  }

  /// Выводит структуру проектов с результатами
  void _printProjectTree(String basePath, Map<String, bool> results) {
    if (results.isEmpty) return;

    // Строим древовидную структуру
    final tree = <String, dynamic>{};
    final baseDirName = _getLastSegment(basePath);

    for (final entry in results.entries) {
      final relativePath = entry.key;
      var current = tree;

      // Если это корневой проект (пустой путь), используем имя базовой директории
      if (relativePath.isEmpty) {
        current[baseDirName] = {'__result': entry.value};
        continue;
      }

      final parts = relativePath.split(Platform.pathSeparator);

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];

        if (i == parts.length - 1) {
          // Это конечный проект
          current[part] = {'__result': entry.value};
        } else {
          // Это промежуточная папка
          if (!current.containsKey(part)) {
            current[part] = {};
          }
          current = current[part] as Map<String, dynamic>;
        }
      }
    }

    _printTreeNode(tree, '', true);
  }

  /// Получает последний сегмент пути
  String _getLastSegment(String path) {
    final segments =
        path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.last : 'root';
  }

  /// Рекурсивно выводит узлы дерева
  void _printTreeNode(
    Map<String, dynamic> node,
    String prefix,
    bool isRoot,
  ) {
    final entries = node.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final key = entry.key;
      final value = entry.value;
      final isLast = i == entries.length - 1;

      final connector = isRoot ? '' : (isLast ? '└── ' : '├── ');
      final nextPrefix = prefix + (isRoot ? '' : (isLast ? '    ' : '│   '));

      if (value is Map && value.containsKey('__result')) {
        // Это проект
        final success = value['__result'] as bool;
        final icon = success ? '✅' : '❌';

        // Если это корневой узел и есть другие проекты, показываем его как папку
        if (isRoot && entries.length > 1) {
          print('$prefix$icon $key/');

          // Рекурсивно выводим остальные узлы
          final remainingNodes = <String, dynamic>{};
          for (int j = 0; j < entries.length; j++) {
            if (j != i) {
              remainingNodes[entries[j].key] = entries[j].value;
            }
          }
          _printTreeNode(remainingNodes, nextPrefix, false);
          break;
        } else {
          print('$prefix$connector$icon $key');
        }
      } else {
        // Это папка с подпапками
        print('$prefix$connector📦 $key/');
        _printTreeNode(value as Map<String, dynamic>, nextPrefix, false);
      }
    }
  }

  /// Возвращает список папок для исключения из поиска
  List<String> _getExcludedFolders() {
    return [
      // Стандартные Flutter папки
      'build',
      'ios',
      'android',
      'web',
      'linux',
      'macos',
      'windows',
      'bin',
      'lib',
      // Системные папки
      '.dart_tool',
      '.git',
      '.github',
      '.vscode',
      '.idea',
      'node_modules',
      // Кэш и временные файлы
      '.pub-cache', '.gradle', '.m2', 'DerivedData', 'Pods',
      // Документация
      'doc', 'docs', 'documentation',
    ];
  }

  /// Выполняет dart pub get в указанной папке проекта
  Future<int> _runPubGetInProject(
    String projectPath,
    String basePath,
    bool useFvm,
  ) async {
    final projectName = projectPath.split(Platform.pathSeparator).last;
    final relativePath = _getRelativePath(projectPath, basePath);

    print('');
    print('\x1B[34m🔄 Processing: $projectName\x1B[0m');
    print('\x1B[90m  Path: $relativePath\x1B[0m');

    try {
      // Сохраняем текущую директорию
      final currentDir = Directory.current.path;

      // Переходим в папку проекта
      Directory.current = projectPath;

      // Выполняем dart pub get
      final result = await _processService.runCommand(
        ['dart', 'pub', 'get'],
        useFvm: useFvm,
      );

      // Возвращаемся обратно
      Directory.current = currentDir;

      if (result == 0) {
        print('\x1B[32m  ✅ Success: $projectName\x1B[0m');
      } else {
        print('\x1B[31m  ❌ Failed: $projectName\x1B[0m');
      }

      return result;
    } catch (e) {
      print('\x1B[31m  ❌ Error in $projectName: $e\x1B[0m');
      return 1;
    }
  }

  /// Получает относительный путь от базовой директории
  String _getRelativePath(String fullPath, String basePath) {
    if (fullPath == basePath) {
      return ''; // Корневой проект
    }

    if (fullPath.startsWith(basePath)) {
      return fullPath.substring(basePath.length).replaceFirst(
            RegExp('^[${RegExp.escape(Platform.pathSeparator)}]+'),
            '',
          );
    }
    return fullPath;
  }
}
