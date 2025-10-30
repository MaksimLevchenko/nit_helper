import 'dart:io';

void main() {
  final yaml = File('pubspec.yaml').readAsStringSync();
  final versionMatch = RegExp(r'version:\s*(\d+\.\d+\.\d+)').firstMatch(yaml);

  if (versionMatch == null) {
    throw Exception('Version not found in pubspec.yaml');
  }

  final version = versionMatch.group(1);
  final file = File('lib/src/generated/version.g.dart');

  file.createSync(recursive: true);
  file.writeAsStringSync('''
// Generated file. Do not edit.
const appVersion = '$version';
''');

  print('Version generated: $version');
}
