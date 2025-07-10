import 'dart:io';

void main() {
  final yaml = (File('pubspec.yaml').readAsStringSync());
  final versionMatch = RegExp(r'version:\s*(\d+\.\d+\.\d+)').firstMatch(yaml);
  if (versionMatch == null) {
    print('Version not found in pubspec.yaml');
    return;
  }
  final version = versionMatch.group(1);
  if (!File('lib/version.g.dart').existsSync()) {
    File('bin/generated/version.g.dart').createSync(recursive: true);
  }
  File('bin/generated/version.g.dart').writeAsStringSync('''
  // Generated file. Do not edit.
  const appVersion = '$version';
  ''');
  print('Version generated successfully: $version');
}
