class Logger {
  static void info(String message) =>
      _printWithPrefix('INFO', message, '\x1B[36m'); // Cyan

  static void success(String message) =>
      _printWithPrefix('SUCCESS', message, '\x1B[32m'); // Green

  static void warning(String message) =>
      _printWithPrefix('WARNING', message, '\x1B[33m'); // Yellow

  static void error(String message) =>
      _printWithPrefix('ERROR', message, '\x1B[31m'); // Red

  static void command(String message) =>
      _printWithPrefix('CMD', message, '\x1B[35m'); // Magenta

  static void _printWithPrefix(String prefix, String message, String color) {
    final timestamp = _getTimestamp();
    print('$color[$timestamp] [$prefix]\x1B[0m $message');
  }

  static String _getTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
}
