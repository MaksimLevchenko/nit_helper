// ignore_for_file: avoid_print

import 'dart:io';

Future<void> runCheckNitRules(List<String> args) async {
  _checkNitRules(args);
}

void _checkNitRules(List<String> args) async {
  final errors = <String>[];
  final errorStats = <CheckType, int>{};

  CheckType? filterType;
  CheckSeverity? filterSeverity;
  String? dirPath;

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--type' && i + 1 < args.length) {
      final typeArg = args[i + 1].toLowerCase();
      // print('Получен параметр --type = $typeArg');

      final match = CheckType.values.where(
        (e) => e.toString().split('.').last.toLowerCase() == typeArg,
      );
      if (match.isEmpty) {
        print('❌ Неизвестный тип проверки: $typeArg');
        print('Доступные типы:');
        for (var t in CheckType.values) {
          print(' - ${t.toString().split('.').last}');
        }
        exit(1);
      }
      filterType = match.first;
      i++;
    } else if (args[i] == '--level' && i + 1 < args.length) {
      final levelArg = args[i + 1];
      final match = CheckSeverity.values.where(
        (e) => e.toString().split('.').last == levelArg,
      );
      if (match.isEmpty) {
        print('❌ Неизвестный уровень критичности: $levelArg');
        print('Доступные уровни: info, warning, error');
        exit(1);
      }
      filterSeverity = match.first;
      i++;
    } else if (args[i] == '--dir' && i + 1 < args.length) {
      dirPath = args[i + 1];
      i++;
    }
  }

  final activeTypes = CheckType.values.where((t) {
    if (filterType != null) return t == filterType;
    if (filterSeverity != null) return t.severity == filterSeverity;
    return true;
  }).toSet();

  print("Checking for $activeTypes");

  if (dirPath != null) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      print('❌ Указанная папка не найдена: $dirPath');
      exit(1);
    }
    await _validateFeatureRecursively(dir, errors, errorStats, activeTypes);
  } else {
    await _checkUiKitParts(errors, errorStats, activeTypes);
    await _checkFeatureCodeRules(errors, errorStats, activeTypes);
  }

  if (errors.isEmpty) {
    print('✅ Архитектура проекта корректна');
  } else {
    print('\n❌ Обнаружены ошибки (${errors.length}):\n');
    for (final error in errors) {
      print('- $error');
    }

    print('\n📊 Статистика по типам ошибок:');
    for (final entry in errorStats.entries) {
      final type = entry.key;
      final count = entry.value;
      final label = type.toString().split('.').last;
      final severity = type.severity.name.toUpperCase();
      print('• [$severity] $label — $count');
    }

    print('\n🔴 Всего ошибок: ${errors.length}');
    exit(1);
  }
}

enum CheckSeverity { info, warning, error }

enum CheckType {
  uiKitPartMissing,
  uiKitContainsText, // Новая проверка
  forbiddenUiUsage,
  forbiddenUiKitImport,
  invalidFeatureStructure,
  forbiddenFeatureImport;

  CheckSeverity get severity {
    switch (this) {
      case CheckType.uiKitContainsText:
        return CheckSeverity.warning; // Мягкое предупреждение
      default:
        return CheckSeverity.error;
    }
  }
}

void report(CheckType type, String message, List<String> errors,
    Map<CheckType, int> stats) {
  String label;
  switch (type.severity) {
    case CheckSeverity.info:
      label = 'ℹ️ INFO';
      break;
    case CheckSeverity.warning:
      label = '⚠️ WARNING';
      break;
    case CheckSeverity.error:
      label = '❌ ERROR';
      break;
  }
  errors.add('$label: $message');
  stats[type] = (stats[type] ?? 0) + 1;
}

Future<void> _checkUiKitParts(List<String> errors, Map<CheckType, int> stats,
    Set<CheckType> activeTypes) async {
  final uiKitDir = Directory('lib/ui_kit');
  if (!uiKitDir.existsSync()) return;

  final files = uiKitDir.listSync(recursive: true).whereType<File>().where(
      (f) => f.path.endsWith('.dart') && !f.path.endsWith('ui_kit.dart'));

  for (final file in files) {
    final content = await file.readAsString();
    if (activeTypes.contains(CheckType.uiKitPartMissing)) {
      if (!content.contains("part of '../ui_kit.dart';")) {
        report(CheckType.uiKitPartMissing,
            'Файл ${file.path} в ui_kit не содержит part of', errors, stats);
      }
    }

    if (activeTypes.contains(CheckType.uiKitContainsText)) {
      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        final match = RegExp(r'''["']([^"']{3,})["']''').firstMatch(line);

        if (match != null) {
          final value = match.group(1);

          // Игнорируем строки, которые похожи на пути, переводы, переменные и т.п.
          final isException = value == null ||
              value.contains(RegExp(r'\.svg$|\.png$|\.dart$|\.json$')) ||
              value.startsWith('../') ||
              value.startsWith(r'$') ||
              value.startsWith(r'r$') ||
              value.contains('i18n') ||
              value.contains('.tr') ||
              value.contains('assets') ||
              value.contains('path') ||
              value.contains('svg') ||
              value.contains('AppText.') ||
              // value.length > 100 ||
              RegExp(r'^[dMyHms.:/\-\s]+$')
                  .hasMatch(value); // формат даты или времени

          if (!isException) {
            report(
              CheckType.uiKitContainsText,
              'Файл ${file.path} содержит текстовую константу: "$value" (строка ${i + 1})',
              errors,
              stats,
            );
            break;
          }
        }
      }
    }

    // if (activeTypes.contains(CheckType.uiKitContainsText)) {
    //   // Найдёт строки, содержащие хотя бы одну букву (русскую или латинскую) и пробел
    //   final textPattern = RegExp(r'''["']([^"']{3,})["']''');

    //   for (final match in textPattern.allMatches(content)) {
    //     final value = match.group(1);
    //     if (value != null &&
    //         value.contains(RegExp(
    //             r'[а-яА-Яa-zA-Z]')) && // чтобы отсеять пути, цифры и спецсимволы
    //         !value.contains(RegExp(r'\.tr\(|\.i18n')) &&
    //         !value.startsWith(r'$') &&
    //         !value.startsWith('../')) {
    //       report(
    //         CheckType.uiKitContainsText,
    //         'Файл ${file.path} содержит текстовую константу: "$value"',
    //         errors,
    //         stats,
    //       );
    //       break;
    //     }
    //   }
    // }
  }
}

Future<void> _checkFeatureCodeRules(List<String> errors,
    Map<CheckType, int> stats, Set<CheckType> activeTypes) async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) return;

  final rootDirs = libDir.listSync().whereType<Directory>().where((d) {
    final name = d.path.split(Platform.pathSeparator).last;
    return name.startsWith('app') ||
        name.startsWith('auth') ||
        name.startsWith('common') ||
        name.startsWith('admin');
  }).toList();

  for (final dir in rootDirs) {
    await _validateFeatureRecursively(dir, errors, stats, activeTypes);
  }
}

Future<void> _validateFeatureRecursively(Directory dir, List<String> errors,
    Map<CheckType, int> stats, Set<CheckType> activeTypes) async {
  final pathParts = dir.path.split(Platform.pathSeparator);
  final name =
      pathParts.isNotEmpty ? pathParts.lastWhere((e) => e.isNotEmpty) : '';

  if (name == 'state' || name == 'widgets') {
    final dartFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    for (final file in dartFiles) {
      final content = await file.readAsString();
      _validateFileContent(file.path, content, errors, stats, activeTypes);
    }
    return;
  }

  final entries = dir.listSync();
  final rootDartFiles =
      entries.whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  final subDirs = entries.whereType<Directory>().toList();

  if (activeTypes.contains(CheckType.invalidFeatureStructure)) {
    if (rootDartFiles.length > 1) {
      report(
        CheckType.invalidFeatureStructure,
        '${dir.path} может содержать только один .dart-файл (корневой виджет / extension, через который осуществляется доступ к фиче)',
        errors,
        stats,
      );
    } else if (rootDartFiles.length == 1) {
      final invalidSubfolders = subDirs
          .map((d) => d.path
              .split(Platform.pathSeparator)
              .lastWhere((e) => e.isNotEmpty))
          .where((n) => n != 'widgets' && n != 'state')
          .toList();

      if (invalidSubfolders.isNotEmpty) {
        report(
            CheckType.invalidFeatureStructure,
            '${dir.path} содержит недопустимые папки: ${invalidSubfolders.join(', ')}',
            errors,
            stats);
      }
    }
  }

  for (final file in rootDartFiles) {
    final content = await file.readAsString();
    _validateFileContent(file.path, content, errors, stats, activeTypes);
  }

  for (final sub in subDirs) {
    await _validateFeatureRecursively(sub, errors, stats, activeTypes);
  }
}

void _validateFileContent(String filePath, String content, List<String> errors,
    Map<CheckType, int> stats, Set<CheckType> activeTypes) {
  if (activeTypes.contains(CheckType.forbiddenUiUsage)) {
    final forbiddenPatterns = {
      'Color(': 'Color напрямую',
      'TextStyle(': 'TextStyle напрямую',
      'BorderRadius.': 'BorderRadius напрямую',
      'context.textTheme': 'context.textTheme напрямую',
      'context.colorTheme': 'context.colorTheme напрямую',
    };

    for (final entry in forbiddenPatterns.entries) {
      if (content.contains(entry.key)) {
        report(CheckType.forbiddenUiUsage,
            '$filePath использует ${entry.value}', errors, stats);
      }
    }
  }

  if (activeTypes.contains(CheckType.forbiddenUiKitImport)) {
    final uiKitImportRegex =
        RegExp(r"import 'package:[^']*/ui_kit/([^']+)'", multiLine: true);
    for (final match in uiKitImportRegex.allMatches(content)) {
      final imported = match.group(1);
      if (imported != 'ui_kit.dart') {
        report(
            CheckType.forbiddenUiKitImport,
            '$filePath импортирует ui_kit/$imported - этот файл должен импортироваться только через ui_kit.dart',
            errors,
            stats);
      }
    }
  }

  if (activeTypes.contains(CheckType.forbiddenFeatureImport)) {
    final forbiddenImportPattern = RegExp(
        r"import\s+'package:[^']*/(app|auth|common)/([^/]+)/(widgets|state)/");

    for (final match in forbiddenImportPattern.allMatches(content)) {
      final targetFeature = match.group(2);
      final segment = match.group(3);
      if (!filePath.contains('/$targetFeature/')) {
        report(
            CheckType.forbiddenFeatureImport,
            '$filePath импортирует $segment из другой фичи $targetFeature',
            errors,
            stats);
      }
    }
  }
}
