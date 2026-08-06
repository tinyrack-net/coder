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
    'search and glob render counts, caps, and correctable errors',
    () {
      final search = describeToolActivity(
        testL10n,
        activity(
          'search_text',
          arguments: <String, dynamic>{'query': 'TODO', 'path': 'lib'},
          output:
              '{"matches":['
              '{"path":"a.dart","line":1,"text":"TODO"},'
              '{"path":"a.dart","line":9,"text":"TODO"},'
              '{"path":"b.dart","line":2,"text":"TODO"}],'
              '"matchCount":3,"filesSearched":9,"truncated":false}',
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
            output:
                '{"matches":[],"matchCount":0,"filesSearched":9,'
                '"truncated":false}',
          ),
        ).resultLine,
        '일치 없음',
      );
      // A capped run has to read as "at least", not as a total.
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'search_text',
            arguments: <String, dynamic>{'query': 'TODO'},
            output:
                '{"matches":[{"path":"a.dart","line":1,"text":"TODO"}],'
                '"matchCount":1,"filesSearched":9,"truncated":true}',
          ),
        ).resultLine,
        '1개 파일에서 1건 이상',
      );
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'search_text',
            arguments: <String, dynamic>{'query': '([', 'regex': true},
            output: '{"error":"query is not a valid regular expression."}',
          ),
        ),
        isA<ChatToolPresentation>()
            .having((value) => value.isFailure, 'isFailure', isTrue)
            .having(
              (value) => value.resultLine,
              'result',
              'query is not a valid regular expression.',
            ),
      );

      final globbed = describeToolActivity(
        testL10n,
        activity(
          'glob',
          arguments: <String, dynamic>{'pattern': '**/*.dart', 'path': 'lib'},
          output: '{"paths":["lib/a.dart","lib/b.dart"],"truncated":false}',
        ),
      );
      expect(globbed.title, 'Glob(**/*.dart in lib)');
      expect(globbed.resultLine, '파일 2개');
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'glob',
            arguments: <String, dynamic>{'pattern': '**/*.rs'},
            output: '{"paths":[],"truncated":false}',
          ),
        ).resultLine,
        '파일 없음',
      );
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'glob',
            arguments: <String, dynamic>{'pattern': '**/*.dart'},
            output: '{"paths":["lib/a.dart"],"truncated":true}',
          ),
        ).resultLine,
        '파일 1개 이상',
      );
    },
    tags: const <String>['feature_test__tool_search__widget'],
  );

  test(
    'skill tools render their catalog and loaded instructions',
    () {
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'list_skills',
            arguments: <String, dynamic>{'cursor': null},
            output:
                '{"skills":[{"name":"commit"},{"name":"review"}],'
                '"total":2}',
          ),
        ),
        isA<ChatToolPresentation>()
            .having((value) => value.title, 'title', 'Skills()')
            .having((value) => value.resultLine, 'result', '스킬 2개'),
      );
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'list_skills',
            arguments: <String, dynamic>{'cursor': null},
            output: '{"skills":[{"name":"commit"}],"total":9,"nextCursor":"1"}',
          ),
        ).resultLine,
        '스킬 1개 이상',
      );

      final skill = describeToolActivity(
        testL10n,
        activity(
          'skill',
          arguments: <String, dynamic>{'name': 'commit', 'resource': null},
          output: '{"name":"commit","instructions":"Stage related changes."}',
        ),
      );
      expect(skill.title, 'Skill(commit)');
      expect(skill.resultLine, 'commit 불러옴');
      expect(
        skill.body,
        isA<ChatToolTextBody>().having(
          (value) => value.text,
          'text',
          'Stage related changes.',
        ),
      );
      // A bundled file is part of what was asked for, so the title says so.
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'skill',
            arguments: <String, dynamic>{
              'name': 'commit',
              'resource': 'scripts/split.sh',
            },
            output: '{"name":"commit","content":"echo split"}',
          ),
        ).title,
        'Skill(commit:scripts/split.sh)',
      );
    },
    tags: const <String>['feature_test__skill_invocation__widget'],
  );

  test(
    'attachment and MCP tools no longer fall back to generic text',
    () {
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'attach_file',
            arguments: <String, dynamic>{'path': 'docs/spec.pdf'},
            output: '{"attachmentId":"a1","fileName":"spec.pdf"}',
          ),
        ),
        isA<ChatToolPresentation>()
            .having((value) => value.title, 'title', 'Attach(docs/spec.pdf)')
            .having((value) => value.resultLine, 'result', 'spec.pdf 첨부'),
      );

      expect(
        describeToolActivity(
          testL10n,
          activity(
            'read_attachment',
            arguments: <String, dynamic>{'id': 'a1'},
            output: '{"attachmentId":"a1","fileName":"spec.pdf"}',
          ),
        ),
        isA<ChatToolPresentation>()
            .having((value) => value.title, 'title', 'Attachment(a1)')
            .having((value) => value.resultLine, 'result', 'spec.pdf 첨부'),
      );

      // An MCP tool name is invented at runtime, so it cannot be in the spec
      // map; it still gets a readable title instead of the generic fallback.
      final mcp = describeToolActivity(
        testL10n,
        activity(
          'mcp__github__create_issue',
          arguments: <String, dynamic>{'title': 'Bug'},
          output: 'Created issue #1',
        ),
      );
      expect(mcp.title, 'github.create_issue');
      expect(mcp.isFailure, isFalse);
      expect(
        describeToolActivity(
          testL10n,
          activity(
            'mcp__github__create_issue',
            arguments: <String, dynamic>{'title': 'Bug'},
            output: r'{"error":"MCP server \"github\" is not connected."}',
          ),
        ),
        isA<ChatToolPresentation>()
            .having((value) => value.isFailure, 'isFailure', isTrue)
            .having(
              (value) => value.resultLine,
              'result',
              'MCP server "github" is not connected.',
            ),
      );
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
    'the clock tools read as time, and a finished sleep as a duration',
    tags: const <String>['feature_test__tool_clock__widget'],
    () {
      final now = describeToolActivity(
        testL10n,
        activity(
          'current_time',
          output: '{"utc":"2026-08-05T14:23:01.000Z","unixSeconds":1785508981}',
        ),
      );
      expect(now.glyph, ChatToolGlyph.clock);
      expect(chatToolIcon(now.glyph), CoderIcons.time);
      expect(now.title, 'Now()');
      expect(now.resultLine, '2026-08-05T14:23:01.000Z');

      // A running sleep is its own card; this spec only draws the leftovers.
      final slept = describeToolActivity(
        testL10n,
        activity(
          'sleep',
          arguments: const <String, dynamic>{'duration_ms': 2500},
          output: '{"sleptMs":2500,"outcome":"elapsed"}',
        ),
      );
      expect(slept.title, 'Sleep(2500ms)');
      expect(slept.resultLine, '3초 대기함');

      final rejected = describeToolActivity(
        testL10n,
        activity(
          'sleep',
          output: '{"error":"duration_ms must be an integer."}',
          isError: true,
        ),
      );
      expect(rejected.title, 'Sleep()');
      expect(rejected.isFailure, isTrue);
    },
  );

  test(
    'the context budget reads as tokens, not raw counters',
    tags: const <String>['feature_test__tool_context_budget__widget'],
    () {
      final remaining = describeToolActivity(
        testL10n,
        activity(
          'get_context_remaining',
          output:
              '{"usedTokens":32000,"contextWindowTokens":200000,'
              '"remainingTokens":168000}',
        ),
      );
      expect(remaining.glyph, ChatToolGlyph.context);
      expect(chatToolIcon(remaining.glyph), CoderIcons.gauge);
      expect(remaining.title, 'Context()');
      expect(remaining.resultLine, '토큰 168000/200000 남음');

      // Without an advertised window there is no fraction to report, so the
      // row falls back to what was actually spent.
      final unknown = describeToolActivity(
        testL10n,
        activity(
          'get_context_remaining',
          output:
              '{"usedTokens":900,"contextWindowTokens":null,'
              '"remainingTokens":null}',
        ),
      );
      expect(unknown.resultLine, '토큰 900개 사용');

      // A successful reset is the timeline divider; only a refusal draws here.
      final denied = describeToolActivity(
        testL10n,
        activity(
          'new_context',
          output: '{"error":"Denied."}',
          isError: true,
        ),
      );
      expect(denied.glyph, ChatToolGlyph.context);
      expect(denied.title, 'NewContext()');
      expect(denied.resultLine, 'Denied.');
      expect(denied.isFailure, isTrue);
    },
  );

  test(
    'tool_search reports what it loaded and what stays hidden',
    tags: const <String>['feature_test__tool_search_deferred__widget'],
    () {
      final searched = describeToolActivity(
        testL10n,
        activity(
          'tool_search',
          arguments: const <String, dynamic>{'query': 'open a pull request'},
          output:
              '{"tools":[{"name":"mcp__github__create_pull_request",'
              '"description":"Opens a PR.","parameters":{}}],"remaining":11}',
        ),
      );

      expect(searched.glyph, ChatToolGlyph.tools);
      expect(chatToolIcon(searched.glyph), CoderIcons.tool);
      expect(searched.title, 'Tools(open a pull request)');
      expect(searched.resultLine, contains('11'));
      // The body lists names, not the schemas the model needs.
      expect(
        (searched.body as ChatToolTextBody).text,
        'mcp__github__create_pull_request',
      );
      expect(searched.isFailure, isFalse);

      final empty = describeToolActivity(
        testL10n,
        activity(
          'tool_search',
          arguments: const <String, dynamic>{'query': 'nothing'},
          output: '{"tools":[],"remaining":12}',
        ),
      );
      expect(empty.body, isA<ChatToolEmptyBody>());
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
