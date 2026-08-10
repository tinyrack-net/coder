@Tags(<String>['feature_test__tool_exec_session__unit'])
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;

import 'package:agent/agent.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/memory.dart';
import 'package:platform/platform.dart';
import 'package:test/test.dart';

void main() {
  late _ScriptedExecHost host;
  late ToolExecutionContext context;

  setUp(() {
    host = _ScriptedExecHost();
    context = ToolExecutionContext(
      workspaceRoot: '/workspace',
      cancellation: CancellationToken(),
    );
  });

  Map<String, dynamic> decode(ToolResult result) =>
      jsonDecode(result.output) as Map<String, dynamic>;

  test('a command that exits inside the wait returns no session', () async {
    host.script('echo hi', <ExecSessionChunk>[
      const ExecSessionChunk(output: 'hi\n', isRunning: false, exitCode: 0),
    ]);

    final result = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'echo hi',
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    final decoded = decode(result);
    expect(result.isError, isFalse);
    expect(decoded['output'], 'hi\n');
    expect(decoded, isNot(contains('is_running')));
    expect(decoded['exit_code'], 0);
    // A finished command leaves nothing to drive, so no id is offered.
    expect(decoded.containsKey('session_id'), isFalse);
    expect(host.started.single.command, 'echo hi');
    expect(host.started.single.workingDirectory, '/workspace');
    // Pipes are the default: an ordinary command wants its real output, not a
    // rendering of a screen.
    expect(host.started.single.tty, isFalse);
  });

  test('a nonzero exit is reported as a tool error', () async {
    host.script('false', <ExecSessionChunk>[
      const ExecSessionChunk(output: '', isRunning: false, exitCode: 1),
    ]);

    final result = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'false',
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    expect(result.isError, isTrue);
    expect(decode(result)['exit_code'], 1);
  });

  test('a still-running command is driven through write_stdin', () async {
    host.script('python3', <ExecSessionChunk>[
      const ExecSessionChunk(output: '>>> ', isRunning: true),
      const ExecSessionChunk(output: '4\n>>> ', isRunning: true),
    ]);

    final started = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'python3',
        'yield_time_ms': 250,
        'max_output_tokens': null,
      },
      context,
    );
    final sessionId = decode(started)['session_id'] as int;
    expect(sessionId, greaterThan(0));
    expect(
      host.started.single.yieldTimes.single,
      io.Platform.isWindows ? const Duration(seconds: 10) : minExecYieldTime,
    );

    final written = await WriteStdinTool(host: host).execute(
      <String, dynamic>{
        'session_id': sessionId,
        'chars': '2 + 2\n',
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    expect(host.started.single.writes, <String>['2 + 2\n']);
    expect(decode(written)['output'], '4\n>>> ');
    expect(decode(written)['session_id'], sessionId);
  });

  test('an empty write polls without sending anything', () async {
    host.script('tail -f log', <ExecSessionChunk>[
      const ExecSessionChunk(output: '', isRunning: true),
      const ExecSessionChunk(output: 'new line\n', isRunning: true),
    ]);
    final started = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'tail -f log',
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    final polled = await WriteStdinTool(host: host).execute(
      <String, dynamic>{
        'session_id': decode(started)['session_id'],
        'chars': '',
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    expect(host.started.single.writes, isEmpty);
    expect(decode(polled)['output'], 'new line\n');
  });

  test('an unknown session is a correctable error, not a failure', () async {
    final result = await WriteStdinTool(host: host).execute(
      <String, dynamic>{
        'session_id': 999,
        'chars': 'ls\n',
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    expect(result.isError, isTrue);
    expect(decode(result)['error'], 'exec session not found');
    expect(decode(result)['hint'], contains('exec_command'));
  });

  test('an empty command never reaches the host', () async {
    final result = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': '   ',
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    expect(result.isError, isTrue);
    expect(host.started, isEmpty);
  });

  test('the yield time is clamped to the supported range', () async {
    host.script('sleep 1', <ExecSessionChunk>[
      const ExecSessionChunk(output: '', isRunning: true),
    ]);
    await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'sleep 1',
        'yield_time_ms': 999999,
        'max_output_tokens': null,
      },
      context,
    );
    expect(host.started.single.yieldTimes.single, maxExecYieldTime);

    host.script('sleep 2', <ExecSessionChunk>[
      const ExecSessionChunk(output: '', isRunning: true),
    ]);
    await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'sleep 2',
        'yield_time_ms': 0,
        'max_output_tokens': null,
      },
      context,
    );
    expect(
      host.started.last.yieldTimes.single,
      io.Platform.isWindows ? const Duration(seconds: 10) : minExecYieldTime,
    );
  });

  test('the output budget keeps the tail and reports truncation', () async {
    final flood = List<String>.generate(
      400,
      (index) => 'line $index',
    ).join('\n');
    host.script('yes', <ExecSessionChunk>[
      ExecSessionChunk(output: flood, isRunning: false, exitCode: 0),
    ]);

    final result = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'yes',
        'yield_time_ms': null,
        'max_output_tokens': minExecOutputTokens,
      },
      context,
    );

    final output = decode(result)['output'] as String;
    expect(
      decode(result)['original_token_count'],
      greaterThan(minExecOutputTokens),
    );
    expect(output, startsWith('[…'));
    expect(output, contains('line 399'));
    expect(output, isNot(contains('line 0\n')));
  });

  test('truncation is a no-op when the output already fits', () {
    expect(truncateToTokenBudget('short', 1000), 'short');
  });

  test('a chunk reports what the budget hid and how long it waited', () async {
    final flood = List<String>.generate(
      400,
      (index) => 'line $index',
    ).join('\n');
    host.script('yes', <ExecSessionChunk>[
      ExecSessionChunk(
        output: flood,
        isRunning: false,
        exitCode: 0,
        wallTime: const Duration(milliseconds: 1500),
      ),
    ]);

    final result = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'yes',
        'workdir': null,
        'tty': null,
        'yield_time_ms': null,
        'max_output_tokens': minExecOutputTokens,
      },
      context,
    );

    final decoded = decode(result);
    // The count describes the output before the budget was applied, which is
    // how the model learns that raising the budget would show it more.
    expect(decoded['original_token_count'], estimateTokenCount(flood));
    expect(decoded['original_token_count'], greaterThan(minExecOutputTokens));
    expect(decoded['wall_time_seconds'], 1.5);
  });

  test('tty is opt-in and reaches the host', () async {
    host.script('python3', <ExecSessionChunk>[
      const ExecSessionChunk(output: '>>> ', isRunning: true),
    ]);

    await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'python3',
        'workdir': null,
        'tty': true,
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    expect(host.started.single.tty, isTrue);
  });

  group('workdir', () {
    late file_api.FileSystem fileSystem;
    late ToolExecutionContext rooted;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fileSystem
          .directory('/workspace/packages/app')
          .createSync(
            recursive: true,
          );
      fileSystem.file('/workspace/pubspec.yaml').createSync();
      fileSystem.directory('/outside').createSync(recursive: true);
      rooted = ToolExecutionContext(
        workspaceRoot: '/workspace',
        cancellation: CancellationToken(),
      );
    });

    Future<ToolResult> run(Object? workdir) {
      host.script('ls', <ExecSessionChunk>[
        const ExecSessionChunk(output: '', isRunning: false, exitCode: 0),
      ]);
      return ExecCommandTool(
        host: host,
        fileSystem: fileSystem,
        platform: FakePlatform(
          operatingSystem: 'linux',
          environment: const <String, String>{},
        ),
      ).execute(<String, dynamic>{
        'cmd': 'ls',
        'workdir': workdir,
        'tty': null,
        'yield_time_ms': null,
        'max_output_tokens': null,
      }, rooted);
    }

    test('a relative directory resolves against the workspace root', () async {
      final result = await run('packages/app');

      expect(result.isError, isFalse);
      expect(host.started.single.workingDirectory, '/workspace/packages/app');
    });

    test('null runs at the workspace root', () async {
      await run(null);

      expect(host.started.single.workingDirectory, '/workspace');
    });

    test('a directory outside the workspace is refused', () async {
      final result = await run('../outside');

      expect(result.isError, isTrue);
      expect(decode(result)['error'], contains('inside the workspace'));
      // Nothing runs, so an escape attempt cannot have a side effect.
      expect(host.started, isEmpty);
    });

    test('a file is refused rather than silently ignored', () async {
      final result = await run('pubspec.yaml');

      expect(result.isError, isTrue);
      expect(host.started, isEmpty);
    });

    test('the preview names the directory the user is approving', () async {
      expect(
        await ExecCommandTool(host: host).preview(
          const <String, dynamic>{'cmd': 'ls', 'workdir': 'packages/app'},
          rooted,
        ),
        'ls  (in packages/app)',
      );
    });
  });

  test('a write and a poll get different default waits', () async {
    host.script('sh', <ExecSessionChunk>[
      const ExecSessionChunk(output: r'$ ', isRunning: true),
      const ExecSessionChunk(output: 'hi\n', isRunning: true),
      const ExecSessionChunk(output: '', isRunning: true),
    ]);
    final started = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'sh',
        'workdir': null,
        'tty': true,
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );
    final sessionId = decode(started)['session_id'];

    await WriteStdinTool(host: host).execute(<String, dynamic>{
      'session_id': sessionId,
      'chars': 'echo hi\n',
      'yield_time_ms': null,
      'max_output_tokens': null,
    }, context);
    await WriteStdinTool(host: host).execute(<String, dynamic>{
      'session_id': sessionId,
      'chars': '',
      'yield_time_ms': null,
      'max_output_tokens': null,
    }, context);

    expect(host.started.single.yieldTimes, <Duration>[
      defaultExecYieldTime,
      // A warm program answers a write immediately; waiting the full window
      // would just idle.
      defaultWriteYieldTime,
      defaultExecYieldTime,
    ]);
  });

  test('a poll may not be shortened into a busy loop', () async {
    host.script('sh', <ExecSessionChunk>[
      const ExecSessionChunk(output: r'$ ', isRunning: true),
      const ExecSessionChunk(output: '', isRunning: true),
      const ExecSessionChunk(output: '', isRunning: true),
    ]);
    final started = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'sh',
        'workdir': null,
        'tty': true,
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );
    final sessionId = decode(started)['session_id'];

    await WriteStdinTool(host: host).execute(<String, dynamic>{
      'session_id': sessionId,
      'chars': '',
      'yield_time_ms': 10,
      'max_output_tokens': null,
    }, context);
    // A write may still ask for a short wait: it has something to send.
    await WriteStdinTool(host: host).execute(<String, dynamic>{
      'session_id': sessionId,
      'chars': 'x',
      'yield_time_ms': 10,
      'max_output_tokens': null,
    }, context);

    expect(host.started.single.yieldTimes.skip(1), <Duration>[
      minPollYieldTime,
      minExecYieldTime,
    ]);
  });

  test('both tools publish a strict schema and a readable preview', () async {
    final exec = ExecCommandTool(host: host);
    expect(exec.name, 'exec_command');
    expect(exec.risk, AgentToolRisk.command);
    expect(exec.description, contains('exit code'));
    final execSchema = exec.strictJsonSchema;
    expect(execSchema['additionalProperties'], isFalse);
    expect(execSchema['required'], <String>['cmd']);
    expect(exec.strict, isFalse);
    final execProperties = execSchema['properties']! as Map<String, dynamic>;
    expect(
      (execProperties['yield_time_ms']! as Map<String, dynamic>)['type'],
      'integer',
    );
    expect(
      await exec.preview(
        const <String, dynamic>{'cmd': 'dart test'},
        context,
      ),
      'dart test',
    );
    expect(await exec.preview(const <String, dynamic>{}, context), isNull);

    final stdin = WriteStdinTool(host: host);
    expect(stdin.name, 'write_stdin');
    expect(stdin.risk, AgentToolRisk.command);
    expect(stdin.description, contains('standard input'));
    expect(stdin.strictJsonSchema['required'], <String>['session_id']);
    expect(stdin.strict, isFalse);
    expect(
      await stdin.preview(
        const <String, dynamic>{'session_id': 1, 'chars': 'ls\n'},
        context,
      ),
      '1 ← ls',
    );
    expect(await stdin.preview(const <String, dynamic>{}, context), isNull);
  });

  test('malformed write_stdin arguments are rejected', () async {
    final result = await WriteStdinTool(host: host).execute(
      <String, dynamic>{
        'session_id': '7',
        'chars': null,
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    expect(result.isError, isTrue);
    expect(decode(result)['error'], contains('must be an integer'));
  });

  test('the output budget is clamped to the supported range', () async {
    host.script('yes', <ExecSessionChunk>[
      const ExecSessionChunk(output: 'x', isRunning: false, exitCode: 0),
    ]);
    final result = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'cmd': 'yes',
        'yield_time_ms': null,
        'max_output_tokens': 1,
      },
      context,
    );
    // A one-token request still gets the floor, so nothing useful is lost.
    expect(decode(result)['output'], 'x');
    expect(decode(result), isNot(contains('chunk_id')));
  });

  test('cancelling interrupts the command and aborts the call', () async {
    final cancellation = CancellationToken();
    host
      ..script('sleep 100', <ExecSessionChunk>[
        const ExecSessionChunk(output: '', isRunning: true),
      ])
      ..cancelBeforeRead = cancellation;

    await expectLater(
      ExecCommandTool(host: host).execute(
        <String, dynamic>{
          'cmd': 'sleep 100',
          'yield_time_ms': null,
          'max_output_tokens': null,
        },
        ToolExecutionContext(
          workspaceRoot: '/workspace',
          cancellation: cancellation,
        ),
      ),
      throwsA(isA<AgentCancelledException>()),
    );
    // The command stops, but the session survives so a REPL is not destroyed.
    expect(host.started.single.interrupts, 1);
  });

  group('approval', () {
    ToolInvocation invocation(String name, Map<String, dynamic> arguments) =>
        ToolInvocation(
          callId: 'call',
          name: name,
          arguments: arguments,
          risk: AgentToolRisk.command,
          workspaceRoot: '/workspace',
        );

    test('a session is approved once, not per keystroke', () async {
      const inner = DefaultApprovalPolicy(AgentPermissionMode.ask);
      final policy = ExecSessionApprovalPolicy(
        inner,
        host,
        toolName: writeStdinToolName,
      );
      host.script('python3', <ExecSessionChunk>[
        const ExecSessionChunk(output: '>>> ', isRunning: true),
      ]);

      // Starting a command always asks.
      expect(
        policy.evaluate(
          invocation(execCommandToolName, <String, dynamic>{
            'cmd': 'python3',
          }),
        ),
        ApprovalEvaluation.ask,
      );

      final started = await ExecCommandTool(host: host).execute(
        <String, dynamic>{
          'cmd': 'python3',
          'yield_time_ms': null,
          'max_output_tokens': null,
        },
        context,
      );
      final sessionId = decode(started)['session_id'];

      expect(
        policy.evaluate(
          invocation(writeStdinToolName, <String, dynamic>{
            'session_id': sessionId,
          }),
        ),
        ApprovalEvaluation.allow,
      );
      expect(
        policy.evaluate(
          invocation(writeStdinToolName, <String, dynamic>{
            'session_id': 999,
          }),
        ),
        ApprovalEvaluation.ask,
      );
    });

    test('a read-only session is never unlocked by an approved id', () {
      const inner = DefaultApprovalPolicy(AgentPermissionMode.readOnly);
      final policy = ExecSessionApprovalPolicy(
        inner,
        host,
        toolName: writeStdinToolName,
      );
      host.markApproved(1);

      expect(
        policy.evaluate(
          invocation(writeStdinToolName, <String, dynamic>{
            'session_id': 1,
          }),
        ),
        ApprovalEvaluation.deny,
      );
    });

    test('an allow from the inner policy passes straight through', () {
      const inner = DefaultApprovalPolicy(AgentPermissionMode.workspaceWrite);
      final policy = ExecSessionApprovalPolicy(
        inner,
        host,
        toolName: writeStdinToolName,
      );

      expect(
        policy.evaluate(
          const ToolInvocation(
            callId: 'call',
            name: 'read_file',
            arguments: <String, dynamic>{},
            risk: AgentToolRisk.read,
            workspaceRoot: '/workspace',
          ),
        ),
        ApprovalEvaluation.allow,
      );
    });
  });
}

/// A host that replays scripted chunks instead of starting a real PTY.
final class _ScriptedExecHost implements ExecSessionHost {
  final Map<String, Queue<ExecSessionChunk>> _scripts =
      <String, Queue<ExecSessionChunk>>{};
  final Map<int, _ScriptedExecSession> _sessions =
      <int, _ScriptedExecSession>{};
  final Set<int> _approved = <int>{};
  final List<_ScriptedExecSession> started = <_ScriptedExecSession>[];

  /// Cancelled just before the next read completes, if set.
  CancellationToken? cancelBeforeRead;

  void script(String command, List<ExecSessionChunk> chunks) =>
      _scripts[command] = Queue<ExecSessionChunk>.of(chunks);

  @override
  Future<ExecSession> start({
    required String command,
    required String workingDirectory,
    required bool tty,
    String? shell,
    bool login = false,
  }) async {
    final session = _ScriptedExecSession(
      id: started.length + 1,
      command: command,
      workingDirectory: workingDirectory,
      tty: tty,
      chunks: _scripts[command] ?? Queue<ExecSessionChunk>(),
      onRead: () => cancelBeforeRead?.cancel(),
    );
    started.add(session);
    _sessions[session.id] = session;
    return session;
  }

  @override
  ExecSession? lookup(int sessionId) => _sessions[sessionId];

  @override
  bool isApproved(int sessionId) => _approved.contains(sessionId);

  @override
  void markApproved(int sessionId) => _approved.add(sessionId);
}

final class _ScriptedExecSession implements ExecSession {
  _ScriptedExecSession({
    required this.id,
    required this.command,
    required this.workingDirectory,
    required this.tty,
    required this.chunks,
    required this.onRead,
  });

  @override
  final int id;

  final String command;
  final String workingDirectory;
  final bool tty;
  final Queue<ExecSessionChunk> chunks;
  final void Function() onRead;
  final List<String> writes = <String>[];
  final List<Duration> yieldTimes = <Duration>[];
  int interrupts = 0;

  @override
  Future<void> write(String chars) async => writes.add(chars);

  @override
  Future<ExecSessionChunk> read(Duration yieldTime) async {
    yieldTimes.add(yieldTime);
    onRead();
    return chunks.isEmpty
        ? const ExecSessionChunk(output: '', isRunning: true)
        : chunks.removeFirst();
  }

  @override
  Future<void> interrupt() async => interrupts += 1;
}
