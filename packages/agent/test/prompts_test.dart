import 'package:agent/agent.dart';
import 'package:test/test.dart';

void main() {
  group('renderPromptTemplate', () {
    test(
      'substitutes every declared variable',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        expect(
          renderPromptTemplate('a {{one}} b {{two}}', const <String, String>{
            'one': '1',
            'two': '2',
          }),
          'a 1 b 2',
        );
      },
    );

    test(
      'drops placeholders no variable supplies',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        expect(
          renderPromptTemplate('a {{missing}}b', const <String, String>{}),
          'a b',
        );
      },
    );

    test(
      'leaves text without placeholders untouched',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        expect(
          renderPromptTemplate('plain', const <String, String>{'x': 'y'}),
          'plain',
        );
      },
    );
  });
}
