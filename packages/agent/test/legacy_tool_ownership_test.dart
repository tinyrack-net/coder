@Tags(<String>['feature_test__tool_harness_parity__unit'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('production Dart owns no model-visible tool implementation', () {
    final root = Directory(p.join(Directory.current.path, 'lib'));
    final violations = <String>[];
    for (final file
        in root
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      final relative = p.relative(file.path, from: Directory.current.path);
      if (RegExp(r'\bextends\s+AgentTool\b').hasMatch(source)) {
        violations.add('$relative extends AgentTool');
      }
      if (RegExp(
        r'\b(?:AgentToolRegistry|AgentToolProvider|SelectableToolProvider|ToolSearchIndex)\b',
      ).hasMatch(source)) {
        violations.add('$relative owns a legacy Dart tool registry or policy');
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
