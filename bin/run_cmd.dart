import 'dart:convert';
import 'dart:io';

class CmdHelper {
  /// Prefix and run a shell command, optionally via `fvm exec`.
  static Future<Process> runCmd(
    List<String> cmd, {
    required bool useFvm,
    bool runInShell = true,
  }) async {
    if (useFvm) {
      cmd = ['fvm', 'exec', ...cmd];
    }
    stdout.writeln(
        '\x1B[35m${cmd.join(' ')} at dir: ${Directory.current.path}\x1B[0m'); // magenta :contentReference[oaicite:2]{index=2}
    final result = await Process.start(
      cmd.first,
      cmd.sublist(1),
      runInShell: runInShell,
      includeParentEnvironment: true,
    );
    result.stdout.transform(utf8.decoder).listen((data) {
      stdout.write(data);
    });
    result.stderr.transform(utf8.decoder).listen((data) {
      stderr.write(data);
    });
    await result.exitCode;
    return result;
  }
}
