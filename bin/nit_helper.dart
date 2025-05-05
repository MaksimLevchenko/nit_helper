#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';

/// Prefix and run a shell command, optionally via `fvm exec`.
Future<ProcessResult> runCmd(
  List<String> cmd, {
  required bool useFvm,
}) {
  if (useFvm) {
    cmd = ['fvm', 'exec', ...cmd];
  }
  stdout.writeln(
      '\x1B[35m${cmd.join(' ')}\x1B[0m'); // magenta :contentReference[oaicite:2]{index=2}
  return Process.run(cmd.first, cmd.sublist(1), runInShell: true);
}

Future<void> doBuild(bool useFvm) async {
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
    default:
      stdout.writeln(parser.usage);
      exit(64);
  }
  return 0;
}
