import 'dart:io';

/// Утилита для красивого отображения дерева папок в CLI
class FolderTreePrinter {
  static const String _folderProcessed = '✅';
  static const String _folderUnprocessed = '⏳';
  static const String _folderIcon = '📦';
  static const String _verticalLine = '│';
  static const String _horizontalLine = '├── ';
  static const String _lastItem = '└── ';
  static const String _spacing = '    ';

  /// Print tree. Принимает Map<String, dynamic> или Map<String, bool>
  static void printProjectTree(
    String basePath,
    Map<String, dynamic> results, {
    bool showStatus = true,
    bool colorOutput = true,
  }) {
    if (results.isEmpty) return;

    final tree = _buildTree(basePath, results);
    _printTree(tree, '', true,
        showStatus: showStatus, colorOutput: colorOutput);
  }

  /// Строит структуру дерева из результатов
  /// Важное: нормализуем любые встреченные Map в Map<String, dynamic>
  static Map<String, dynamic> _buildTree(
    String basePath,
    Map<String, dynamic> results,
  ) {
    final tree = <String, dynamic>{};
    final baseDirName = _getLastSegment(basePath);

    for (final entry in results.entries) {
      final relativePath = (entry.key ?? '').toString();
      final rawValue = entry.value;

      // получаем булево значение безопасно
      bool isSuccess = false;
      if (rawValue is bool) {
        isSuccess = rawValue;
      } else if (rawValue is Map) {
        final candidate = rawValue['__result'];
        if (candidate is bool) isSuccess = candidate;
      }

      // текущий курсор всегда содержит Map<String,dynamic>
      var current = tree;

      // корень как пустая строка
      if (relativePath.isEmpty) {
        final existing = current[baseDirName];
        if (existing is Map) {
          final normalized = _ensureMapStringDynamic(existing);
          current[baseDirName] = normalized;
          normalized['__result'] = isSuccess;
          normalized['__isProject'] = true;
        } else {
          current[baseDirName] = {
            '__result': isSuccess,
            '__isProject': true,
          };
        }
        continue;
      }

      final parts = relativePath.split(Platform.pathSeparator);

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        final isLast = i == parts.length - 1;

        if (isLast) {
          final existing = current[part];
          if (existing == null) {
            current[part] = {
              '__result': isSuccess,
              '__isProject': true,
            };
          } else if (existing is Map) {
            // Нормализуем и записываем результат
            final normalized = _ensureMapStringDynamic(existing);
            current[part] = normalized;
            normalized['__result'] = isSuccess;
            normalized['__isProject'] = true;
          } else {
            // Если тип неожиданный (например bool), заменяем новым узлом
            current[part] = {
              '__result': isSuccess,
              '__isProject': true,
            };
          }
        } else {
          // промежуточная папка — гарантируем, что в current[part] хранится Map<String,dynamic>
          final existing = current[part];
          if (existing == null) {
            final newNode = <String, dynamic>{'__isProject': false};
            current[part] = newNode;
            current = newNode;
          } else if (existing is Map) {
            // Нормализуем копию и **подменяем** в parent, чтобы избежать дальнейших проблем
            final normalized = _ensureMapStringDynamic(existing);
            // если existing и normalized — разные инстансы, подменяем
            if (!identical(existing, normalized)) {
              current[part] = normalized;
            }
            current = normalized;
          } else {
            // Если существующее значение — не Map (например bool), заменяем на Map и продолжаем
            final replacement = <String, dynamic>{'__isProject': false};
            current[part] = replacement;
            current = replacement;
          }
        }
      }
    }

    return tree;
  }

  /// Приводит любую Map к Map<String, dynamic> путём копирования.
  /// Это защищает от ситуаций, когда на вход приходят Map<String,bool> или другие generic-типы.
  static Map<String, dynamic> _ensureMapStringDynamic(Map existing) {
    try {
      // Попытка безопасного копирования через Map.from
      final copy = Map<String, dynamic>.from(existing as Map);
      return copy;
    } catch (_) {
      final result = <String, dynamic>{};
      existing.forEach((k, v) {
        try {
          result[k.toString()] = v;
        } catch (_) {
          // игнорируем ключи, которые не удаётся привести
        }
      });
      return result;
    }
  }

  /// Рекурсивный принт узла
  static void _printTree(
    Map<String, dynamic> node,
    String prefix,
    bool isRoot, {
    bool showStatus = true,
    bool colorOutput = true,
  }) {
    final entries = node.entries.where((e) => !e.key.startsWith('__')).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final key = entry.key;
      final value = entry.value;

      if (value is! Map<String, dynamic>) {
        // Пропускаем неожиданные типы
        continue;
      }

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

      if (colorOutput) resetColor = '\x1B[0m';

      if (isProject) {
        final success = (value['__result'] as bool?) ?? false;
        icon = showStatus
            ? (success ? _folderProcessed : _folderUnprocessed)
            : _folderIcon;
        if (colorOutput) color = success ? '\x1B[32m' : '\x1B[31m';
      } else {
        icon = _folderIcon;
        displayName = '$key/';
        if (colorOutput) color = '\x1B[34m';
      }

      print('$prefix$connector$color$icon $displayName$resetColor');

      final childNodes = <String, dynamic>{};
      for (final childEntry in value.entries) {
        if (!childEntry.key.startsWith('__') && childEntry.value is Map) {
          childNodes[childEntry.key] =
              _ensureMapStringDynamic(childEntry.value as Map);
        } else if (!childEntry.key.startsWith('__') &&
            childEntry.value is Map<String, dynamic>) {
          childNodes[childEntry.key] = childEntry.value;
        }
      }
      if (childNodes.isNotEmpty) {
        _printTree(childNodes, nextPrefix, false,
            showStatus: showStatus, colorOutput: colorOutput);
      }
    }
  }

  /// Получает последний сегмент пути
  static String _getLastSegment(String path) {
    final segments =
        path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.last : 'root';
  }

  /// Статистика
  static void printSummary(Map<String, dynamic> results) {
    final total = results.length;
    final successful = results.values.where((v) => v == true).length;
    final failed = total - successful;

    if (failed > 0) print('\x1B[31m❌ Failed: $failed\x1B[0m');

    print('');
    final percentage = total > 0 ? (successful * 100 / total).round() : 0;
    print('Success rate: $percentage%');

    if (failed == 0)
      print('\x1B[32m🎉 All projects processed successfully!\x1B[0m');
  }

  static void printProgress(
      String projectName, int current, int total, bool success) {
    final percentage = (current * 100 / total).round();
    final progressBar = _createProgressBar(current, total);
    final status = success ? '✅' : '❌';
    print(
        '\r\x1B[K$status [$current/$total] $progressBar $percentage% - $projectName');
  }

  static String _createProgressBar(int current, int total, {int width = 20}) {
    if (total == 0) return '░' * width;
    final filled = (current * width / total).round();
    final empty = width - filled;
    return '█' * filled + '░' * empty;
  }

  static void printSectionHeader(String title, {String emoji = '📋'}) {
    print('');
    print('\x1B[36m$emoji $title\x1B[0m');
    print('\x1B[36m${'─' * (title.length + 3)}\x1B[0m');
  }

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

  static String _getRelativePath(String fullPath, String basePath) {
    if (fullPath == basePath) return '';
    if (fullPath.startsWith(basePath)) {
      return fullPath.substring(basePath.length).replaceFirst(
            RegExp('^[${RegExp.escape(Platform.pathSeparator)}]+'),
            '',
          );
    }
    return fullPath;
  }
}
