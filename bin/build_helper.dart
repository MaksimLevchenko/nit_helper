import 'dart:io';
import 'run_cmd.dart';

class BuildHelper {
  static Future<void> goToDir(String endsWith) async {
    var currentDir = Directory.current.path;
    final hasPubspec = File('pubspec.yaml').existsSync();
    if (hasPubspec) {
      // If pubspec.yaml exists, we are already in the right directory
      return;
    }
    if (!currentDir.contains(endsWith)) {
      var dirs = Directory.current.listSync().whereType<Directory>();
      var flutterDir = dirs.firstWhere(
        (dir) => dir.path.endsWith(endsWith),
        orElse: () =>
            throw Exception('No directory with "$endsWith" in name found'),
      );
      Directory.current = flutterDir;
    }
  }

  static Future<void> doBuild(bool useFvm) async {
    // await ensureDependenciesForBuild();
    final startDir = Directory.current.path;
    goToDir('_flutter');
    var cmds = [
      ['dart', 'run', 'build_runner', 'build'],
      ['fluttergen']
    ];
    for (var c in cmds) {
      await CmdHelper.runCmd(c, useFvm: useFvm);
    }
    Directory.current = startDir;
  }

  static Future<void> doBuildServer(bool forceMigration, bool useFvm) async {
    // generate, create-migration, apply
    final startDir = Directory.current.path;
    goToDir('_server');
    await CmdHelper.runCmd(['serverpod', 'generate'], useFvm: useFvm);
    if (forceMigration) {
      await CmdHelper.runCmd(['serverpod', 'create-migration', '-f'],
          useFvm: useFvm);
    } else {
      await CmdHelper.runCmd(['serverpod', 'create-migration'], useFvm: useFvm);
    }
    await CmdHelper.runCmd(
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
    Directory.current = startDir;
  }
}
