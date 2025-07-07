#!/usr/bin/env dart

import 'package:args/args.dart';
import 'build_helper.dart';
import 'check_nit_rules.dart';

void _printHelp() {
  print('''
nit-helper - Unified build tool for Dart/Flutter/Serverpod projects

Usage:
  nit-helper build [--fvm]               Build Flutter module
  nit-helper build-server [--fvm] [--f]  Build Serverpod server and apply migrations
  nit-helper build-full [--fvm] [--f]    Build both frontend and backend
  nit-helper check [--type <name>] [--level <level>] [--dir <path>]
                                        Run static analysis checks

Options:
  --fvm   Run commands through "fvm exec" (only for build*, not check)
  --f     Force migration creation (for server build)

Examples:
  nit-helper build --fvm
  nit-helper build-server --f
  nit-helper build-full --fvm --f
  nit-helper check --type uiKitContainsText --level warning --dir lib/app_home
''');
}

Future<int> main(List<String> args) async {
  final parser = ArgParser()
    ..addCommand('build', ArgParser()..addFlag('fvm', negatable: false))
    ..addCommand(
      'build-server',
      ArgParser()
        ..addFlag('fvm', negatable: false)
        ..addFlag('force', abbr: 'f', negatable: false),
    )
    ..addCommand(
      'build-full',
      ArgParser()
        ..addFlag('fvm', negatable: false)
        ..addFlag('force', abbr: 'f', negatable: false),
    )
    ..addCommand(
      'check',
      ArgParser()
        ..addOption('type',
            help: 'Фильтр по типу проверки (например: uiKitPartMissing)')
        ..addOption('level',
            help: 'Фильтр по уровню серьёзности (info, warning, error)')
        ..addOption('dir', help: 'Папка, в которой запускать проверку'),
    );

  late ArgResults result;
  String? cmd;
  bool useFvm = false;
  bool force = false;

  try {
    result = parser.parse(args);
    cmd = result.command?.name;
  } catch (e) {
    print('Ошибка при разборе аргументов: $e');
    return 1;
  }

  final cmdArgs = result.command;

  // only check fvm for build* commands
  if (cmdArgs != null && cmd != 'check' && cmdArgs.wasParsed('fvm')) {
    useFvm = cmdArgs['fvm'] as bool;
  }

  // only check force for server-related commands
  if (cmdArgs != null && ['build-server', 'build-full'].contains(cmd)) {
    if (cmdArgs.wasParsed('force')) {
      force = cmdArgs['force'] as bool;
    }
  }

  switch (cmd) {
    case 'build':
      await BuildHelper.doBuild(useFvm);
      break;
    case 'build-server':
      await BuildHelper.doBuildServer(force, useFvm);
      break;
    case 'build-full':
      await BuildHelper.doBuild(useFvm);
      await BuildHelper.doBuildServer(force, useFvm);
      break;
    case 'check':
      print('Running static analysis checks...');
      final argsForCheck = <String>[];

      if (cmdArgs!.wasParsed('type')) {
        argsForCheck.add('--type');
        argsForCheck.add(cmdArgs['type']);
      }
      if (cmdArgs.wasParsed('level')) {
        argsForCheck.add('--level');
        argsForCheck.add(cmdArgs['level']);
      }
      if (cmdArgs.wasParsed('dir')) {
        argsForCheck.add('--dir');
        argsForCheck.add(cmdArgs['dir']);
      }

      await runCheckNitRules(argsForCheck);
      break;
    case '--help':
    case '-h':
    case '':
    case null:
      _printHelp();
      break;
    default:
      print('Неизвестная команда: $cmd');
      _printHelp();
  }

  return 0;
}
