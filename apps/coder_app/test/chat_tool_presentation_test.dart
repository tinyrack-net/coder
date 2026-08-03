import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/chat/chat_tool_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localization.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);

  ChatToolActivity activity(
    String name, {
    Map<String, dynamic> arguments = const <String, dynamic>{},
    ChatToolStatus status = ChatToolStatus.succeeded,
    String? output,
    String? error,
    bool isError = false,
  }) => ChatToolActivity(
    key: 'tool-call-1',
    turnId: 'turn-1',
    createdAt: now,
    callId: 'call-1',
    toolName: name,
    arguments: arguments,
    status: status,
    output: output,
    error: error,
    isError: isError,
  );

  test(
    'double-encoded tool output decodes without ever throwing',
    () {
      expect(
        decodeToolOutput('{"exitCode":1,"output":"boom"}'),
        isA<ChatToolJsonObject>().having(
          (value) => value.value['exitCode'],
          'exitCode',
          1,
        ),
      );
      expect(
        decodeToolOutput('[{"path":"a.dart"}]'),
        isA<ChatToolJsonArray>().having(
          (value) => value.value,
          'value',
          hasLength(1),
        ),
      );
      expect(
        decodeToolOutput('plain text'),
        isA<ChatToolPlainText>().having(
          (value) => value.value,
          'value',
          'plain text',
        ),
      );
      expect(decodeToolOutput('{'), isA<ChatToolPlainText>());
      expect(decodeToolOutput('  '), isA<ChatToolPlainText>());
      expect(decodeToolOutput('"quoted"'), isA<ChatToolPlainText>());
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );

  test(
    'built-in tools render CLI titles and Korean result lines',
    () {
      final read = describeToolActivity(
        testL10n,
        activity(
          'read_file',
          arguments: <String, dynamic>{'path': 'lib/main.dart'},
          output: 'void main() {}\nfinal a = 1;\nfinal b = 2;',
        ),
      );
      expect(read.title, 'Read(lib/main.dart)');
      expect(read.resultLine, '3줄 읽음');
      expect(read.glyph, ChatToolGlyph.read);

      expect(
        describeToolActivity(
          testL10n,
          activity(
            'read_file',
            arguments: <String, dynamic>{
              'path': 'lib/main.dart',
              'offset': 10,
              'limit': 40,
            },
            output: '',
          ),
        ),
        isA<ChatToolPresentation>()
            .having(
              (value) => value.title,
              'title',
              'Read(lib/main.dart @10+40)',
            )
            .having((value) => value.resultLine, 'result', '빈 파일'),
      );

      final list = describeToolActivity(
        testL10n,
        activity(
          'list_directory',
          arguments: <String, dynamic>{'path': 'lib'},
          output:
              '[{"name":"src","type":"directory"},'
              '{"name":"main.dart","type":"file"}]',
        ),
      );
      expect(list.title, 'List(lib)');
      expect(list.resultLine, '디렉터리 1 · 파일 1');

      final search = describeToolActivity(
        testL10n,
        activity(
          'search_text',
          arguments: <String, dynamic>{'query': 'TODO', 'path': 'lib'},
          output:
              '[{"path":"a.dart","line":1,"text":"TODO"},'
              '{"path":"a.dart","line":9,"text":"TODO"},'
              '{"path":"b.dart","line":2,"text":"TODO"}]',
        ),
      );
      expect(search.title, 'Search(TODO in lib)');
      expect(search.resultLine, '2개 파일에서 3건');
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'search_text',
            arguments: <String, dynamic>{'query': 'nothing'},
            output: '[]',
          ),
        ).resultLine,
        '일치 없음',
      );

      final edit = describeToolActivity(
        testL10n,
        activity(
          'apply_patch',
          arguments: <String, dynamic>{
            'patch':
                '--- a/lib/main.dart\n'
                '+++ b/lib/main.dart\n'
                '@@ -1,2 +1,3 @@\n'
                ' final a = 1;\n'
                '-final b = 2;\n'
                '+final b = 3;\n'
                '+final c = 4;\n',
          },
          output: '{"changedFiles":1}',
        ),
      );
      expect(edit.title, 'Edit(lib/main.dart)');
      expect(edit.resultLine, '+2 -1 · 1개 파일');

      final run = describeToolActivity(
        testL10n,
        activity(
          'run_command',
          arguments: <String, dynamic>{'command': 'flutter test'},
          output: r'{"exitCode":0,"output":"All tests passed!\ndone"}',
        ),
      );
      expect(run.title, 'Bash(flutter test)');
      expect(run.resultLine, '종료 코드 0 · 2줄');
      expect(run.isFailure, isFalse);
      expect(run.body, isA<ChatToolTextBody>());
      expect(
        (run.body as ChatToolTextBody).text,
        'All tests passed!\ndone',
      );

      final failedRun = describeToolActivity(
        testL10n,
        activity(
          'run_command',
          arguments: <String, dynamic>{'command': 'false'},
          output: '{"exitCode":3,"output":""}',
          isError: true,
        ),
      );
      expect(failedRun.resultLine, '종료 코드 3 · 0줄');
      expect(failedRun.isFailure, isTrue);

      final task = describeToolActivity(
        testL10n,
        activity(
          'delegate_agent',
          arguments: <String, dynamic>{
            'agentDefinitionId': 'reviewer',
            'prompt': 'Review the diff',
          },
          output:
              '{"childSessionId":"s","status":"completed",'
              '"finalText":"Looks good"}',
        ),
      );
      expect(task.title, 'Task(reviewer)');
      expect(task.resultLine, 'completed · Looks good');
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );

  test(
    'unknown tools and malformed output fall back to generic summaries',
    () {
      final unknown = describeToolActivity(
        testL10n,
        activity(
          'fetch_url',
          arguments: <String, dynamic>{
            'url': 'https://example.com',
            'depth': 2,
          },
          output: 'fetched 3 pages\nsecond line',
        ),
      );
      expect(unknown.title, 'fetch_url(https://example.com)');
      expect(unknown.resultLine, 'fetched 3 pages');
      expect(unknown.glyph, ChatToolGlyph.generic);

      expect(
        describeToolActivity(
          testL10n,
          activity('fetch_url', output: ''),
        ).resultLine,
        '완료',
      );
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'run_command',
            arguments: <String, dynamic>{'command': 'ls'},
            output: 'not json at all',
          ),
        ).resultLine,
        'not json at all',
      );
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'apply_patch',
            arguments: <String, dynamic>{'patch': 'not a diff'},
            output: '{"changedFiles":"two"}',
          ),
        ).resultLine,
        '+0 -0 · 1개 파일',
      );
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'list_directory',
            arguments: <String, dynamic>{'path': '.'},
            output: '{"unexpected":true}',
          ),
        ).resultLine,
        isNotNull,
      );
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );

  test(
    'running, denied, and failed activities describe their state',
    () {
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'read_file',
            arguments: <String, dynamic>{'path': 'a.dart'},
            status: ChatToolStatus.running,
          ),
        ).resultLine,
        '실행 중',
      );
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'run_command',
            arguments: <String, dynamic>{'command': 'rm -rf /'},
            status: ChatToolStatus.denied,
          ),
        ).resultLine,
        '거부됨',
      );
      final failed = describeToolActivity(
        testL10n,
        activity(
          'apply_patch',
          arguments: <String, dynamic>{'patch': 'diff'},
          status: ChatToolStatus.failed,
          error: 'context mismatch\nat line 3',
        ),
      );
      expect(failed.resultLine, 'context mismatch');
      expect(failed.isFailure, isTrue);
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );

  test(
    'long titles and summaries are truncated',
    () {
      final long = 'x' * 200;
      final run = describeToolActivity(
        testL10n,
        activity('run_command', arguments: <String, dynamic>{'command': long}),
      );
      expect(run.title.length, lessThanOrEqualTo('Bash()'.length + 60));
      final failed = describeToolActivity(
        testL10n,
        activity(
          'run_command',
          arguments: <String, dynamic>{'command': 'x'},
          status: ChatToolStatus.failed,
          error: long,
        ),
      );
      expect(failed.resultLine!.length, lessThanOrEqualTo(120));
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );
}
