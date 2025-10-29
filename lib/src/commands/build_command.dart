import 'dart:io';
import '../services/process_service.dart';
import '../services/file_service.dart';

class BuildCommand {
  final ProcessService _processService;
  final FileService _fileService;

  BuildCommand(this._processService, this._fileService);

  Future<int> executeBuild({required bool force, required bool useFvm}) async {
    return await _executeInFlutterDirectory(() async {
      // Проверяем наличие pubspec.yaml
      if (!_fileService.fileExists('pubspec.yaml')) {
        throw Exception(
            'pubspec.yaml not found. Are you in a Flutter project?');
      }

      final buildResult = await _processService.runCommand([
        'dart',
        'run',
        'build_runner',
        'build',
        if (force) '--delete-conflicting-outputs'
      ], useFvm: useFvm);

      if (buildResult != 0) {
        return buildResult;
      }

      final fluttergenResult =
          await _processService.runCommand(['fluttergen'], useFvm: useFvm);
      return fluttergenResult;
    });
  }

  Future<int> executeBuildServer(
      {required bool forceMigration, required bool useFvm}) async {
    return await _executeInServerDirectory(() async {
      // Проверяем наличие serverpod.yaml
      if (!_fileService.fileExists('serverpod.yaml')) {
        throw Exception(
            'serverpod.yaml not found. Are you in a Serverpod project?');
      }

      final generateResult = await _processService
          .runCommand(['serverpod', 'generate'], useFvm: useFvm);
      if (generateResult != 0) {
        return generateResult;
      }

      final migrationResult = await _processService.runCommand(
        ['serverpod', 'create-migration', if (forceMigration) '-f'],
        useFvm: useFvm,
      );
      if (migrationResult != 0) {
        return migrationResult;
      }

      final applyResult = await _processService.runCommand(
        [
          'dart',
          'run',
          'bin/main.dart',
          '--role',
          'maintenance',
          '--apply-migrations'
        ],
        useFvm: useFvm,
      );
      return applyResult;
    });
  }

  Future<int> _executeInFlutterDirectory(Future<int> Function() action) async =>
      await _executeInDirectory('_flutter', action);

  Future<int> _executeInServerDirectory(Future<int> Function() action) async =>
      await _executeInDirectory('_server', action);

  Future<int> _executeInDirectory(
      String directory, Future<int> Function() action) async {
    final startDir = Directory.current.path;
    try {
      await _fileService.changeToDirectory(directory);
      return await action();
    } finally {
      Directory.current = startDir;
    }
  }
}
