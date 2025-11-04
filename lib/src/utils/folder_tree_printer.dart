import 'dart:io';

/// Утилита для красивого отображения дерева папок в CLI
class FolderTreePrinter {
  static const String _folderProcessed = '✅';
  static const String _folderUnprocessed = '📁';
  static const String _folderIcon = '📦';
  static const String _verticalLine = '│';
  static const String _horizontalLine = '├── ';
  static const String _lastItem = '└── ';
  static const String _spacing = '    ';

  /// Выводит дерево папок с индикаторами обработки
  static void printProjectTree(
    String basePath,
    Map<String, bool> results, {
    bool showStatus = true,
    bool colorOutput = true,
  }) {
    if (results.isEmpty) return;

    final tree = _buildTree(basePath, results);
    _printTree(tree, '', true, showStatus: showStatus, colorOutput: colorOutput);
  }

  /// Строит структуру дерева из результатов
  static Map<String, dynamic> _buildTree(
    String basePath,
    Map<String, bool> results,
  ) {
    final tree = <String, dynamic>{};
    final baseDirName = _getLastSegment(basePath);

    for (final entry in results.entries) {
      final relativePath = entry.key;
      var current = tree;

      if (relativePath.isEmpty) {
        current[baseDirName] = {
          '__result': entry.value,
          '__isProject': true,
        };
        continue;
      }

      final parts = relativePath.split(Platform.pathSeparator);

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];

        if (i == parts.length - 1) {
          current[part] = {
            '__result': entry.value,
            '__isProject': true,
          };
        } else {
          if (!current.containsKey(part)) {
            current[part] = {'__isProject': false};
          }
          current = current[part] as Map<String, dynamic>;
        }
      }
    }

    return tree;
  }

  /// Выводит узел дерева рекурсивно
  static void _printTree(
    Map<String, dynamic> node,
    String prefix,
    bool isRoot, {
    bool showStatus = true,
    bool colorOutput = true,
  }) {
    final entries = node.entries
        .where((e) => !e.key.startsWith('__'))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final key = entry.key;
      final value = entry.value as Map<String, dynamic>;
      final isLast = i == entries.length - 1;
      final isProject = value['__isProject'] == true;

      String connector = '';
      String nextPrefix = prefix;

      if (!isRoot) {
        connector = isLast ? _lastItem : _horizontalLine;
        nextPrefix = prefix + (isLast ? _spacing : '$_verticalLine   ');
      }

      String icon;
      String displayName = key;
      String color = '';
      String resetColor = '';

      if (colorOutput) {
        resetColor = '\x1B[0m';
      }

      if (isProject) {
        final success = value['__result'] as bool? ?? false;
        icon = showStatus 
            ? (success ? _folderProcessed : _folderUnprocessed)
            : _folderIcon;
        
        if (colorOutput) {
          color = success ? '\x1B[32m' : '\x1B[31m'; // Зеленый/красный
        }
      } else {
        icon = _folderIcon;
        displayName = '$key/';
        if (colorOutput) {
          color = '\x1B[34m'; // Синий для папок
        }
      }

      print('$prefix$connector$color$icon $displayName$resetColor');

      // Рекурсивно выводим дочерние элементы
      if (!isProject || value.keys.any((k) => !k.startsWith('__'))) {
        final childNodes = <String, dynamic>{};
        for (final childEntry in value.entries) {
          if (!childEntry.key.startsWith('__')) {
            childNodes[childEntry.key] = childEntry.value;
          }
        }
        if (childNodes.isNotEmpty) {
          _printTree(childNodes, nextPrefix, false, 
              showStatus: showStatus, colorOutput: colorOutput);
        }
      }
    }
  }

  /// Получает последний сегмент пути
  static String _getLastSegment(String path) {
    final segments =
        path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.last : 'root';
  }

  /// Выводит статистику обработки
  static void printSummary(Map<String, bool> results) {
    final total = results.length;
    final successful = results.values.where((v) => v).length;
    final failed = total - successful;

    print('');
    print('=' * 50);
    print('📊 PROCESSING SUMMARY');
    print('=' * 50);
    print('');
    print('Total projects: $total');
    print('\x1B[32m✅ Successful: $successful\x1B[0m');
    
    if (failed > 0) {
      print('\x1B[31m❌ Failed: $failed\x1B[0m');
    }
    
    print('');
    final percentage = total > 0 ? (successful * 100 / total).round() : 0;
    print('Success rate: $percentage%');
    
    if (failed == 0) {
      print('\x1B[32m🎉 All projects processed successfully!\x1B[0m');
    }
  }

  /// Интерактивное отображение прогресса
  static void printProgress(
    String projectName,
    int current,
    int total,
    bool success,
  ) {
    final percentage = (current * 100 / total).round();
    final progressBar = _createProgressBar(current, total);
    final status = success ? '✅' : '❌';
    
    print('\r\x1B[K$status [$current/$total] $progressBar $percentage% - $projectName');
  }

  /// Создает прогресс-бар
  static String _createProgressBar(int current, int total, {int width = 20}) {
    final filled = (current * width / total).round();
    final empty = width - filled;
    return '█' * filled + '░' * empty;
  }

  /// Выводит заголовок раздела
  static void printSectionHeader(String title, {String emoji = '📋'}) {
    print('');
    print('\x1B[36m$emoji $title\x1B[0m');
    print('\x1B[36m${'─' * (title.length + 3)}\x1B[0m');
  }

  /// Выводит информацию о найденных проектах
  static void printFoundProjects(List<String> projects, String basePath) {
    print('\x1B[32m📁 Found ${projects.length} projects:\x1B[0m');
    
    for (int i = 0; i < projects.length; i++) {
      final project = projects[i];
      final relativePath = _getRelativePath(project, basePath);
      final isLast = i == projects.length - 1;
      final connector = isLast ? '└── ' : '├── ';
      print('   $connector📁 ${relativePath.isEmpty ? '.' : relativePath}');
    }
  }

  /// Получает относительный путь от базовой директории
  static String _getRelativePath(String fullPath, String basePath) {
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