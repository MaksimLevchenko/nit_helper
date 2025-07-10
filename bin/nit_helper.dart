#!/usr/bin/env dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'generated/version.g.dart'; // Ensure this file exists

import 'package:args/args.dart';
import 'build_helper.dart';
import 'check_nit_rules.dart';
import 'version.dart';

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

void _checkUpdate() async {
  final currentVersion = await _getCurrentVersion();
  // final currentVersion = Version(major: 1, minor: 0, patch: 0);
  final latestVersion = await _getLatestVersion();
  // final latestVersion = null;

  if (latestVersion == null) {
    print(
        '\x1B[31mFailed to check for updates. Please check your internet connection.\x1B[0m');
    return;
  }

  if (currentVersion < latestVersion) {
    print(
        '\x1B[33mA new version of nit-helper is available: $latestVersion (current: $currentVersion)\x1B[0m');
    print('Please update using "dart pub global activate nit_helper"');
  } else {
    print('\x1B[32mYou are using the latest version: $currentVersion\x1B[0m');
  }
}

Future<Version> _getCurrentVersion() async {
  try {
    return Version.parse(appVersion) ?? Version(major: 0, minor: 0, patch: 0);
  } catch (_) {
    return Version(major: 0, minor: 0, patch: 0);
  }
}

Future<Version?> _getLatestVersion() async {
  const packageName = 'nit_helper';
  final url = Uri.parse('https://pub.dev/api/packages/$packageName');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final latest = json['latest']['version'] as String?;
      if (latest != null) {
        return Version.parse(latest);
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<int> main(List<String> args) async {
  _checkUpdate();
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
