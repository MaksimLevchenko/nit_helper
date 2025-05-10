#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';

/// Prefix and run a shell command, optionally via `fvm exec`.
Future<Process> runCmd(
  List<String> cmd, {
  required bool useFvm,
}) async {
  if (useFvm) {
    cmd = ['fvm', 'exec', ...cmd];
  }
  stdout.writeln(
      '\x1B[35m${cmd.join(' ')}\x1B[0m'); // magenta :contentReference[oaicite:2]{index=2}
  final result = await Process.start(cmd.first, cmd.sublist(1),
      runInShell: true, includeParentEnvironment: true);
  result.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
  });
  result.stderr.transform(utf8.decoder).listen((data) {
    stderr.write(data);
  });
  return result;
}

Future<void> doBuild(bool useFvm) async {
  await ensureDependenciesForBuild();
  var cmds = [
    ['dart', 'run', 'build_runner', 'build'],
    ['fluttergen']
  ];
  for (var c in cmds) {
    var result = await runCmd(c, useFvm: useFvm);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }
}

Future<void> doBuildServer(bool forceMigration, bool useFvm) async {
  // generate, create-migration, apply
  await runCmd(['serverpod', 'generate'], useFvm: useFvm);
  if (forceMigration) {
    await runCmd(['serverpod', 'create-migration', '-f'], useFvm: useFvm);
  } else {
    await runCmd(['serverpod', 'create-migration'], useFvm: useFvm);
  }
  await runCmd(
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
}

void _printHelp() {
  print('''
nit-helper - Unified build tool for Dart/Flutter/Serverpod projects

Usage:
  nit-helper build [--fvm]               Build Flutter module
  nit-helper build-server [--fvm] [--f]  Build Serverpod server and apply migrations
  nit-helper build-full [--fvm] [--f]    Build both frontend and backend

Options:
  --fvm   Run commands through "fvm exec"
  --f     Force migration creation (for server build)

Examples:
  nit-helper build --fvm
  nit-helper build-server --f
  nit-helper build-full --fvm --f
''');
}

Future<bool> isCommandAvailable(String command) async {
  try {
    final result = await Process.run(
      Platform.isWindows ? 'where' : 'which',
      [command],
      runInShell: true,
    );
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<void> ensureDependenciesForServer() async {
  await ensureDependenciesForBuild();
  final missing = <String>[];

  final hasServerpod = await isCommandAvailable('serverpod');

  if (!hasServerpod) {
    missing.add('serverpod');
  }

  if (missing.isNotEmpty) {
    print('\n🔧 Required tools not found: ${missing.join(', ')}');
    print('➡ Attempting to install them globally...');

    for (final tool in missing) {
      final result = await Process.start(
        'dart',
        ['pub', 'global', 'activate', tool],
        mode: ProcessStartMode.inheritStdio,
      );
      await result.exitCode;
    }

    print('\n✅ Dependencies installed. Restart your terminal if needed.\n');
  }
}

Future<void> ensureDependenciesForBuild() async {
  final missing = <String>[];

  final hasBuildRunner = await isCommandAvailable('dart run build_runner');
  final hasFluttergen = await isCommandAvailable('fluttergen');

  if (!hasBuildRunner) {
    missing.add('build_runner');
  }

  if (!hasFluttergen) {
    missing.add('fluttergen');
  }

  if (missing.isNotEmpty) {
    print('\n🔧 Required tools not found: ${missing.join(', ')}');
    print('➡ Attempting to install them globally...');

    for (final tool in missing) {
      final result = await Process.start(
        'dart',
        ['pub', 'global', 'activate', tool],
        mode: ProcessStartMode.inheritStdio,
      );
      await result.exitCode;
    }

    print('\n✅ Dependencies installed. Restart your terminal if needed.\n');
  }
}

Future<int> main(List<String> args) async {
  var parser = ArgParser()
    ..addFlag('fvm', negatable: false, help: 'Run commands via `fvm exec`')
    ..addFlag('force',
        abbr: 'f', negatable: false, help: 'Force create migration')
    ..addCommand('build')
    ..addCommand('build-server')
    ..addCommand('build-full');

  var result = parser.parse(args);
  var useFvm = result['fvm'] as bool;
  var force = result['force'] as bool;
  var cmd = result.command?.name;

  switch (cmd) {
    case 'build':
      await doBuild(useFvm);
      break;
    case 'build-server':
      await doBuildServer(force, useFvm);
      break;
    case 'build-full':
      await doBuild(useFvm);
      await doBuildServer(force, useFvm);
      break;
    case '--help':
    case '-h':
    default:
      _printHelp();
  }
  return 0;
}
