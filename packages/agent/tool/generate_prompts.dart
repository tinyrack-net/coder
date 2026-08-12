import 'dart:io';

import 'package:path/path.dart' as p;

/// Compiles the prompt asset tree into a Dart source of string constants.
///
/// The agent package is a plain Dart package that also runs inside the Flutter
/// app, so it cannot read files next to its own sources at runtime. Keeping the
/// prompts as Markdown and generating the constants gives the same authoring
/// experience as an asset directory without a runtime file dependency.
final _promptRoot = Directory('packages/agent/prompts');
final _generatedFile = File(
  'packages/agent/lib/src/prompts/prompt_assets.g.dart',
);

Future<void> main() async {
  if (!_promptRoot.existsSync()) {
    stderr.writeln('Missing ${_promptRoot.path}.');
    exitCode = 1;
    return;
  }
  final assets = <String, String>{};
  final sources =
      _promptRoot
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => _isAsset(file.path))
          .toList(growable: false)
        ..sort((a, b) => _relative(a).compareTo(_relative(b)));
  for (final source in sources) {
    final name = _identifier(_relative(source));
    final existing = assets[name];
    if (existing != null) {
      stderr.writeln('Duplicate prompt asset identifier: $name');
      exitCode = 1;
      return;
    }
    assets[name] = await source.readAsString();
  }

  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Source: ${_promptRoot.path}')
    ..writeln(
      '// Regenerate with '
      '`dart run packages/agent/tool/generate_prompts.dart`.',
    )
    ..writeln()
    ..writeln(
      '/// Prompt text compiled from the `packages/agent/prompts` tree.',
    )
    ..writeln('abstract final class PromptAssets {');
  for (final entry in assets.entries) {
    buffer
      ..writeln('  /// Contents of `${_pathFor(entry.key, sources)}`.')
      ..writeln('  static const String ${entry.key} =')
      ..writeln('${_literal(entry.value)};');
  }
  buffer.writeln('}');

  await _generatedFile.parent.create(recursive: true);
  await _generatedFile.writeAsString(buffer.toString());
  final format = await Process.run('dart', <String>[
    'format',
    _generatedFile.path,
  ]);
  if (format.exitCode != 0) {
    stderr.writeln(format.stderr);
    exitCode = format.exitCode;
    return;
  }
  stdout.writeln('Wrote ${assets.length} prompt assets.');
}

bool _isAsset(String path) =>
    path.endsWith('.md') || path.endsWith('.xml') || path.endsWith('.txt');

String _relative(File file) =>
    p.relative(file.path, from: _promptRoot.path).replaceAll(r'\', '/');

String _pathFor(String identifier, List<File> sources) => sources
    .map(_relative)
    .firstWhere((path) => _identifier(path) == identifier);

String _identifier(String relativePath) {
  final withoutExtension = p.withoutExtension(relativePath);
  final words = withoutExtension
      .split(RegExp(r'[/_\-.]'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  return <String>[
    words.first.toLowerCase(),
    for (final word in words.skip(1))
      word[0].toUpperCase() + word.substring(1).toLowerCase(),
  ].join();
}

/// Emits one adjacent string literal per source line so diffs stay readable.
///
/// Line endings are normalized first: an asset edited on Windows would
/// otherwise carry a `\r` into the prompt the model reads.
String _literal(String content) {
  final lines = content.replaceAll('\r\n', '\n').split('\n');
  // A trailing newline splits into a final empty element that carries no text.
  if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
  if (lines.isEmpty) return "    ''";
  return lines.map((line) => "    '${_escape(line)}\\n'").join('\n');
}

String _escape(String line) => line
    .replaceAll(r'\', r'\\')
    .replaceAll(r'$', r'\$')
    .replaceAll("'", r"\'")
    // A lone carriage return survives the newline split above.
    .replaceAll('\r', r'\r');
