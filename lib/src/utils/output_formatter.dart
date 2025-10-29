class OutputFormatter {
  static String success(String text) => '\x1B[32m$text\x1B[0m';
  static String warning(String text) => '\x1B[33m$text\x1B[0m';
  static String error(String text) => '\x1B[31m$text\x1B[0m';
  static String info(String text) => '\x1B[36m$text\x1B[0m';
  static String command(String text) => '\x1B[35m$text\x1B[0m';
}
