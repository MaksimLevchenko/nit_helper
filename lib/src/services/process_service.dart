import 'dart:io';

class ProcessService {
  Future<int> runCommand(
    List<String> cmd, {
    required bool useFvm,
  }) async {
    if (useFvm) {
      cmd = ['fvm', 'exec', ...cmd];
    }

    final directory = Directory.current.path.split('/').last;

    // Фиолетовая строка перед командой
    print('\x1B[35mRunning ${cmd.join(' ')} in $directory\x1B[0m');

    try {
      // Используем inheritStdio для прямого наследования TTY
      final process = await Process.start(
        cmd.first,
        cmd.sublist(1),
        mode: ProcessStartMode.inheritStdio,
      );

      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        // Для ненулевых кодов возврата просто возвращаем код, не бросаем исключение
        return exitCode;
      }

      return exitCode;
    } on ProcessException catch (e) {
      // Обрабатываем ошибку "файл не найден"
      if (e.toString().contains('Не удается найти указанный файл') ||
          e.toString().contains('No such file or directory')) {
        await _handleMissingCommand(cmd, useFvm);
        return 127; // Стандартный код для "command not found"
      }
      // Для других ProcessException просто возвращаем код ошибки
      return e.errorCode;
    }
  }

  Future<void> _handleMissingCommand(List<String> cmd, bool useFvm) async {
    final commandName = cmd.first;
    print('\n\x1B[31mError: Command "$commandName" not found\x1B[0m');

    // Предлагаем решения для различных команд
    final solutions = <String, String>{
      'fluttergen': 'dart pub global activate flutter_gen',
      'serverpod': 'dart pub global activate serverpod_cli',
      'fvm': 'curl -fsSL https://fvm.app/install.sh | bash',
      'dart': 'Install Dart SDK from https://dart.dev/get-dart',
      'flutter':
          'Install Flutter SDK from https://flutter.dev/docs/get-started/install',
      'build_runner': 'Add build_runner to dev_dependencies in pubspec.yaml',
    };

    if (solutions.containsKey(commandName)) {
      print('\x1B[33mSolution: ${solutions[commandName]}\x1B[0m');
    } else {
      print(
          '\x1B[33mSolution: Please install $commandName and ensure it\'s in your PATH\x1B[0m');
    }

    // Дополнительная информация для FVM
    if (useFvm && commandName == 'fvm') {
      print('\n\x1B[36mNote: FVM is required when using --fvm flag\x1B[0m');
      print('\x1B[36mInstall with: dart pub global activate fvm\x1B[0m');
    }
  }
}
