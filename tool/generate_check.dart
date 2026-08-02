import 'dart:io';

/// Runs generators and fails when their outputs were not current beforehand.
Future<void> main() async {
  final before = _generatedSources(Directory.current);
  final process = await Process.start(
    'dart',
    const <String>['run', 'melos', 'generate'],
    mode: ProcessStartMode.inheritStdio,
  );
  final result = await process.exitCode;
  if (result != 0) {
    exitCode = result;
    return;
  }
  final after = _generatedSources(Directory.current);
  final changed =
      <String>{
          ...before.keys,
          ...after.keys,
        }.where((path) => before[path] != after[path]).toList(growable: false)
        ..sort();
  if (changed.isEmpty) {
    stdout.writeln('Generated sources are current.');
    return;
  }
  stderr.writeln('Generated sources were stale:');
  changed.forEach(stderr.writeln);
  exitCode = 1;
}

Map<String, String> _generatedSources(Directory root) => <String, String>{
  for (final entity in root.listSync(recursive: true))
    if (entity is File &&
        (entity.path.endsWith('.g.dart') ||
            entity.path.endsWith('.freezed.dart')))
      entity.path: entity.readAsStringSync(),
};
