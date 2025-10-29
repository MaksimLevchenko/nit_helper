import 'package:args/args.dart';
import '../commands/build_command.dart';
import '../commands/check_command.dart';
import '../services/update_service.dart';
import '../services/http_client.dart';
import '../services/process_service.dart';
import '../services/file_service.dart';
import 'help_printer.dart';
import 'error_handler.dart';

class CommandRunner {
  final BuildCommand _buildCommand;
  final CheckCommand _checkCommand;
  final UpdateService _updateService;
  final HelpPrinter _helpPrinter;
  final ErrorHandler _errorHandler;

  CommandRunner({
    required BuildCommand buildCommand,
    required CheckCommand checkCommand,
    required UpdateService updateService,
    required HelpPrinter helpPrinter,
    required ErrorHandler errorHandler,
  })  : _buildCommand = buildCommand,
        _checkCommand = checkCommand,
        _updateService = updateService,
        _helpPrinter = helpPrinter,
        _errorHandler = errorHandler;

  Future<int> run(List<String> args) async {
    return _errorHandler.handleErrors(() async {
      await _updateService.checkForUpdates();

      final parser = _buildParser();
      final command = _parseCommand(parser, args);

      return await _executeCommand(command);
    });
  }

  ArgParser _buildParser() {
    return ArgParser()
      ..addCommand('build', _buildBuildParser())
      ..addCommand('build-server', _buildBuildParser())
      ..addCommand('build-full', _buildBuildParser())
      ..addCommand('check', _buildCheckParser());
  }

  ArgParser _buildBuildParser() {
    return ArgParser()
      ..addFlag('fvm', negatable: false, help: 'Run commands through FVM')
      ..addFlag('force', abbr: 'f', negatable: false, help: 'Force operations');
  }

  ArgParser _buildCheckParser() {
    return ArgParser()
      ..addOption(
        'path',
        abbr: 'p',
        help: 'The path to the project directory to scan',
        defaultsTo: '.',
      )
      ..addMultiOption(
        'exclude-pattern',
        abbr: 'e',
        help: 'File patterns to exclude from the scan (e.g., "*.g.dart")',
      )
      ..addMultiOption(
        'exclude-folder',
        abbr: 'f',
        help: 'Folders to exclude from the scan (e.g., "generated")',
      )
      ..addFlag(
        'details',
        abbr: 'd',
        help: 'Show detailed list of unused files',
        defaultsTo: true,
      )
      ..addFlag(
        'interactive',
        abbr: 'i',
        help: 'Enable interactive cleanup mode',
        defaultsTo: false,
      );
  }

  ParsedCommand _parseCommand(ArgParser parser, List<String> args) {
    try {
      final result = parser.parse(args);
      final commandName = result.command?.name;
      final commandArgs = result.command;

      bool useFvm = false;
      bool force = false;

      // Параметры для команд build
      if (commandArgs != null && commandName != 'check') {
        useFvm = commandArgs['fvm'] as bool? ?? false;
        if (['build-server', 'build-full', 'build'].contains(commandName)) {
          force = commandArgs['force'] as bool? ?? false;
        }
      }

      // Параметры для команды check
      String? checkPath;
      List<String> excludePatterns = [];
      List<String> excludeFolders = [];
      bool showDetails = true;
      bool interactive = false;

      if (commandName == 'check' && commandArgs != null) {
        checkPath = commandArgs['path'] as String?;
        excludePatterns =
            (commandArgs['exclude-pattern'] as List<String>?) ?? [];
        excludeFolders = (commandArgs['exclude-folder'] as List<String>?) ?? [];
        showDetails = commandArgs['details'] as bool? ?? true;
        interactive = commandArgs['interactive'] as bool? ?? false;
      }

      return ParsedCommand(
        name: commandName,
        useFvm: useFvm,
        force: force,
        checkPath: checkPath,
        excludePatterns: excludePatterns,
        excludeFolders: excludeFolders,
        showDetails: showDetails,
        interactive: interactive,
      );
    } catch (e) {
      throw ArgumentError('Failed to parse arguments: $e');
    }
  }

  Future<int> _executeCommand(ParsedCommand command) async {
    switch (command.name) {
      case 'build':
        await _buildCommand.executeBuild(
            force: command.force, useFvm: command.useFvm);
        break;
      case 'build-server':
        await _buildCommand.executeBuildServer(
            forceMigration: command.force, useFvm: command.useFvm);
        break;
      case 'build-full':
        await _buildCommand.executeBuild(
            force: command.force, useFvm: command.useFvm);
        await _buildCommand.executeBuildServer(
            forceMigration: command.force, useFvm: command.useFvm);
        break;
      case 'check':
        final result = await _checkCommand.executeWithResult(
          projectPath: command.checkPath,
          excludePatterns: command.excludePatterns,
          excludeFolders: command.excludeFolders,
          showDetails: command.showDetails,
        );

        // Интерактивная очистка если включена
        if (command.interactive) {
          await _checkCommand.interactiveCleanup(result);
        }
        break;
      case null:
      case '--help':
      case '-h':
        _helpPrinter.printHelp();
        break;
      default:
        throw ArgumentError('Unknown command: ${command.name}');
    }

    return 0;
  }
}

class ParsedCommand {
  final String? name;
  final bool useFvm;
  final bool force;

  // Параметры для команды check
  final String? checkPath;
  final List<String> excludePatterns;
  final List<String> excludeFolders;
  final bool showDetails;
  final bool interactive;

  ParsedCommand({
    required this.name,
    required this.useFvm,
    required this.force,
    this.checkPath,
    this.excludePatterns = const [],
    this.excludeFolders = const [],
    this.showDetails = true,
    this.interactive = false,
  });
}

CommandRunner createCommandRunner() {
  final processService = ProcessService();
  final fileService = FileService();
  final buildCommand = BuildCommand(processService, fileService);
  final checkCommand = CheckCommand(fileService);
  final httpClient = HttpClient();
  final updateService = UpdateService(httpClient);
  final helpPrinter = HelpPrinter();
  final errorHandler = ErrorHandler();

  return CommandRunner(
    buildCommand: buildCommand,
    checkCommand: checkCommand,
    updateService: updateService,
    helpPrinter: helpPrinter,
    errorHandler: errorHandler,
  );
}

Future<int> runCli(List<String> args) {
  return createCommandRunner().run(args);
}
