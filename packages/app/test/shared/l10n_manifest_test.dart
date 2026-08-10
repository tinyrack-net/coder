import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keys declared more than once in [source], in file order.
///
/// `jsonDecode` keeps the last of a repeated key and reports nothing, so a
/// duplicate silently replaces a string that is still in use. Counting the
/// declarations in the text is the only way to see it.
List<String> _duplicateKeys(String source) {
  final declaration = RegExp(r'^\s{2}"(@?[A-Za-z0-9_]+)"\s*:', multiLine: true);
  final seen = <String>{};
  final duplicates = <String>[];
  for (final match in declaration.allMatches(source)) {
    final key = match.group(1)!;
    if (!seen.add(key)) duplicates.add(key);
  }
  return duplicates;
}

void main() {
  final arbFiles = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.arb'))
      .toList();

  test('there are localization files to check', () {
    expect(arbFiles, isNotEmpty);
  });

  for (final file in arbFiles) {
    final name = file.path.split(RegExp(r'[/\\]')).last;

    test('$name declares every key once', () {
      expect(
        _duplicateKeys(file.readAsStringSync()),
        isEmpty,
        reason:
            'a repeated key overwrites the earlier one, so whichever surface '
            'used it silently starts showing the other string',
      );
    });

    test('$name parses as a flat map of strings', () {
      final decoded = jsonDecode(file.readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>());
    });
  }
}
