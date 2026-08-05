import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/chat/chat_tool_card.dart';
import 'package:coder_app/src/chat/chat_tool_presentation.dart';
import 'package:coder_app/src/coder_icons.dart';
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
          'exec_command',
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
          'exec_command',
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
            'exec_command',
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
            'exec_command',
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
    'a pseudo-terminal session reads as running until it exits',
    tags: const <String>['feature_test__tool_exec_session__widget'],
    () {
      final running = describeToolActivity(
        testL10n,
        activity(
          'exec_command',
          arguments: const <String, dynamic>{'command': 'python3'},
          output: '{"sessionId":"exec-1","output":">>> ","isRunning":true}',
        ),
      );
      expect(running.glyph, ChatToolGlyph.run);
      expect(running.title, 'Bash(python3)');
      // No exit code yet, so the summary says so rather than inventing one.
      expect(running.resultLine, contains('실행 중'));
      expect(running.isFailure, isFalse);

      final exited = describeToolActivity(
        testL10n,
        activity(
          'exec_command',
          arguments: const <String, dynamic>{'command': 'false'},
          output: '{"output":"","isRunning":false,"exitCode":1}',
        ),
      );
      expect(exited.resultLine, contains('1'));
      expect(exited.isFailure, isTrue);

      final written = describeToolActivity(
        testL10n,
        activity(
          'write_stdin',
          arguments: const <String, dynamic>{
            'session_id': 'exec-1',
            'chars': '2 + 2\n',
          },
          output: r'{"sessionId":"exec-1","output":"4\n","isRunning":true}',
        ),
      );
      expect(written.glyph, ChatToolGlyph.run);
      expect(written.title, 'Stdin(exec-1 ← 2 + 2)');

      final lost = describeToolActivity(
        testL10n,
        activity(
          'write_stdin',
          arguments: const <String, dynamic>{
            'session_id': 'exec-gone',
            'chars': '',
          },
          output: '{"error":"exec session not found"}',
          isError: true,
        ),
      );
      expect(lost.title, 'Stdin(exec-gone)');
      expect(lost.resultLine, 'exec session not found');
      expect(lost.isFailure, isTrue);
    },
  );

  test(
    'view_image and ask_user get their own glyphs and summaries',
    tags: const <String>['feature_test__tool_image_context__widget'],
    () {
      final viewed = describeToolActivity(
        testL10n,
        activity(
          'view_image',
          arguments: const <String, dynamic>{'path': 'design/mock.png'},
          output: '{"byteSize":2048,"detail":"high"}',
        ),
      );
      expect(viewed.glyph, ChatToolGlyph.image);
      expect(chatToolIcon(viewed.glyph), CoderIcons.image);
      expect(viewed.title, 'View(design/mock.png)');
      expect(viewed.resultLine, contains('2048'));
      expect(viewed.isFailure, isFalse);

      final rejected = describeToolActivity(
        testL10n,
        activity(
          'view_image',
          arguments: const <String, dynamic>{'path': 'notes.txt'},
          output: '{"error":"Not a supported image."}',
          isError: true,
        ),
      );
      expect(rejected.resultLine, 'Not a supported image.');
      expect(rejected.isFailure, isTrue);

      // An accepted plan renders as a card, but a rejected one stays visible.
      final plan = describeToolActivity(
        testL10n,
        activity(
          'update_plan',
          arguments: const <String, dynamic>{
            'plan': <Map<String, dynamic>>[
              <String, dynamic>{'step': 'One', 'status': 'pending'},
            ],
          },
          output: '{"error":"Duplicate step"}',
          isError: true,
        ),
      );
      expect(plan.glyph, ChatToolGlyph.plan);
      expect(plan.title, 'Plan(1)');
      expect(plan.isFailure, isTrue);

      final asked = describeToolActivity(
        testL10n,
        activity(
          'ask_user',
          arguments: const <String, dynamic>{
            'questions': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'store', 'header': 'Storage'},
              <String, dynamic>{'id': 'cache', 'header': 'Cache'},
            ],
          },
          output:
              '[{"questionId":"store","answer":"SQLite","isFreeForm":false},'
              '{"questionId":"cache","answer":"Redis","isFreeForm":true}]',
        ),
      );
      expect(asked.glyph, ChatToolGlyph.ask);
      expect(chatToolIcon(asked.glyph), CoderIcons.chat);
      expect(asked.title, 'Ask(Storage, Cache)');
      // The transcript records what the user actually chose.
      expect(asked.resultLine, 'SQLite, Redis');
      expect(asked.isFailure, isFalse);
    },
  );

  test(
    'MCP resource tools read as discovery, not raw JSON',
    tags: const <String>['feature_test__mcp_resource_access__widget'],
    () {
      final listed = describeToolActivity(
        testL10n,
        activity(
          'list_mcp_resources',
          arguments: const <String, dynamic>{'server': 'github'},
          output:
              '{"server":"github","resources":[{"uri":"file:///a.txt"}],'
              '"truncated":false}',
        ),
      );
      expect(listed.glyph, ChatToolGlyph.resource);
      expect(chatToolIcon(listed.glyph), CoderIcons.extension);
      expect(listed.title, 'Resources(github)');
      expect(listed.resultLine, contains('1'));
      expect(listed.isFailure, isFalse);

      // Fanning out over every server says so in the title.
      final fanned = describeToolActivity(
        testL10n,
        activity(
          'list_mcp_resources',
          output: '{"resources":[],"truncated":false}',
        ),
      );
      expect(fanned.title, 'Resources(all)');

      // A truncated page is marked so the model knows to page again.
      final truncated = describeToolActivity(
        testL10n,
        activity(
          'list_mcp_resource_templates',
          arguments: const <String, dynamic>{'server': 'github'},
          output:
              '{"resourceTemplates":[{"uriTemplate":"a"}],"truncated":true}',
        ),
      );
      expect(truncated.title, 'ResourceTemplates(github)');
      expect(truncated.resultLine, endsWith('…'));

      final read = describeToolActivity(
        testL10n,
        activity(
          'read_mcp_resource',
          arguments: const <String, dynamic>{
            'server': 'github',
            'uri': 'file:///a.txt',
          },
          output:
              '{"server":"github","uri":"file:///a.txt","contents":'
              '[{"uri":"file:///a.txt","mimeType":"text/plain",'
              '"text":"file body"}]}',
        ),
      );
      expect(read.title, 'Resource(github: file:///a.txt)');
      // The expanded body shows the text, not the JSON envelope.
      expect((read.body as ChatToolTextBody).text, 'file body');

      final offline = describeToolActivity(
        testL10n,
        activity(
          'read_mcp_resource',
          arguments: const <String, dynamic>{
            'server': 'gone',
            'uri': 'file:///a.txt',
          },
          output: '{"error":"MCP server gone is not connected."}',
          isError: true,
        ),
      );
      expect(offline.resultLine, contains('gone'));
      expect(offline.isFailure, isTrue);
    },
  );

  test(
    'long titles and summaries are truncated',
    () {
      final long = 'x' * 200;
      final run = describeToolActivity(
        testL10n,
        activity('exec_command', arguments: <String, dynamic>{'command': long}),
      );
      expect(run.title.length, lessThanOrEqualTo('Bash()'.length + 60));
      final failed = describeToolActivity(
        testL10n,
        activity(
          'exec_command',
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
