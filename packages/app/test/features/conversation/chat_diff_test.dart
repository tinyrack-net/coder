import 'package:app/src/features/conversation/application/chat_diff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'unified diffs parse into per-file colored lines with numbers',
    () {
      final files = parseChatDiff(
        '--- a/lib/main.dart\n'
        '+++ b/lib/main.dart\n'
        '@@ -1,3 +1,4 @@\n'
        ' final a = 1;\n'
        '-final b = 2;\n'
        '+final b = 3;\n'
        '+final c = 4;\n'
        ' final d = 5;\n'
        '--- a/lib/other.dart\n'
        '+++ b/lib/other.dart\n'
        '@@ -10,1 +10,1 @@\n'
        '-old\n'
        '+new\n',
      );

      expect(files.map((file) => file.path), <String>[
        'lib/main.dart',
        'lib/other.dart',
      ]);
      expect(files.first.added, 2);
      expect(files.first.removed, 1);
      expect(files.last.added, 1);
      expect(files.last.removed, 1);

      final added = files.first.lines
          .where((line) => line.kind == ChatDiffLineKind.added)
          .toList(growable: false);
      expect(added.map((line) => line.text), <String>[
        'final b = 3;',
        'final c = 4;',
      ]);
      expect(added.map((line) => line.newLine), <int>[2, 3]);
      expect(added.every((line) => line.oldLine == null), isTrue);

      final removed = files.first.lines.singleWhere(
        (line) => line.kind == ChatDiffLineKind.removed,
      );
      expect(removed.oldLine, 2);
      expect(removed.newLine, isNull);

      final context = files.first.lines
          .where((line) => line.kind == ChatDiffLineKind.context)
          .toList(growable: false);
      expect(context.first.oldLine, 1);
      expect(context.first.newLine, 1);
      expect(context.last.oldLine, 3);
      expect(context.last.newLine, 4);
      expect(files.last.lines.first.kind, ChatDiffLineKind.hunkHeader);
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );

  test(
    'malformed diffs degrade to one readable context block',
    () {
      final files = parseChatDiff('just some text\nwithout a diff header');
      expect(files, hasLength(1));
      expect(files.single.path, isEmpty);
      expect(files.single.added, 0);
      expect(files.single.removed, 0);
      expect(
        files.single.lines.every(
          (line) => line.kind == ChatDiffLineKind.context,
        ),
        isTrue,
      );

      final brokenHunk = parseChatDiff(
        '--- a/a.dart\n+++ b/a.dart\n@@ nonsense @@\n+added\n',
      );
      expect(brokenHunk.single.path, 'a.dart');
      expect(brokenHunk.single.added, 1);

      expect(parseChatDiff(''), isEmpty);
      expect(parseChatDiff('   '), hasLength(1));
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );
}
