@Tags(<String>['feature_test__tool_exec_session__unit'])
library;

import 'dart:collection';
import 'dart:convert';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
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
        'command': 'echo hi',
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    final decoded = decode(result);
    expect(result.isError, isFalse);
    expect(decoded['output'], 'hi\n');
    expect(decoded['isRunning'], isFalse);
    expect(decoded['exitCode'], 0);
    // A finished command leaves nothing to drive, so no id is offered.
    expect(decoded.containsKey('sessionId'), isFalse);
    expect(host.started.single.command, 'echo hi');
    expect(host.started.single.workspaceRoot, '/workspace');
  });

  test('a nonzero exit is reported as a tool error', () async {
    host.script('false', <ExecSessionChunk>[
      const ExecSessionChunk(output: '', isRunning: false, exitCode: 1),
    ]);

    final result = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'command': 'false',
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    expect(result.isError, isTrue);
    expect(decode(result)['exitCode'], 1);
  });

  test('a still-running command is driven through write_stdin', () async {
    host.script('python3', <ExecSessionChunk>[
      const ExecSessionChunk(output: '>>> ', isRunning: true),
      const ExecSessionChunk(output: '4\n>>> ', isRunning: true),
    ]);

    final started = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'command': 'python3',
        'yield_time_ms': 250,
        'max_output_tokens': null,
      },
      context,
    );
    final sessionId = decode(started)['sessionId'] as String;
    expect(sessionId, isNotEmpty);
    expect(host.started.single.yieldTimes.single.inMilliseconds, 250);

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
    expect(decode(written)['sessionId'], sessionId);
  });

  test('an empty write polls without sending anything', () async {
    host.script('tail -f log', <ExecSessionChunk>[
      const ExecSessionChunk(output: '', isRunning: true),
      const ExecSessionChunk(output: 'new line\n', isRunning: true),
    ]);
    final started = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'command': 'tail -f log',
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    final polled = await WriteStdinTool(host: host).execute(
      <String, dynamic>{
        'session_id': decode(started)['sessionId'],
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
        'session_id': 'exec-gone',
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
        'command': '   ',
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
        'command': 'sleep 1',
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
        'command': 'sleep 2',
        'yield_time_ms': 0,
        'max_output_tokens': null,
      },
      context,
    );
    expect(host.started.last.yieldTimes.single, minExecYieldTime);
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
        'command': 'yes',
        'yield_time_ms': null,
        'max_output_tokens': minExecOutputTokens,
      },
      context,
    );

    final output = decode(result)['output'] as String;
    expect(decode(result)['truncated'], isTrue);
    expect(output, startsWith('[…'));
    expect(output, contains('line 399'));
    expect(output, isNot(contains('line 0\n')));
  });

  test('truncation is a no-op when the output already fits', () {
    expect(truncateToTokenBudget('short', 1000), 'short');
  });

  test('both tools publish a strict schema and a readable preview', () async {
    final exec = ExecCommandTool(host: host);
    expect(exec.name, 'exec_command');
    expect(exec.risk, ToolRisk.command);
    expect(exec.description, contains('pseudo-terminal'));
    final execSchema = exec.strictJsonSchema;
    expect(execSchema['additionalProperties'], isFalse);
    expect(execSchema['required'], <String>[
      'command',
      'yield_time_ms',
      'max_output_tokens',
    ]);
    // Optional values are nullable rather than absent, which is what a strict
    // provider schema requires.
    final execProperties = execSchema['properties']! as Map<String, dynamic>;
    expect(
      (execProperties['yield_time_ms']! as Map<String, dynamic>)['type'],
      <String>['integer', 'null'],
    );
    expect(
      await exec.preview(
        const <String, dynamic>{'command': 'dart test'},
        context,
      ),
      'dart test',
    );
    expect(await exec.preview(const <String, dynamic>{}, context), isNull);

    final stdin = WriteStdinTool(host: host);
    expect(stdin.name, 'write_stdin');
    expect(stdin.risk, ToolRisk.command);
    expect(stdin.description, contains('standard input'));
    expect(stdin.strictJsonSchema['required'], <String>[
      'session_id',
      'chars',
      'yield_time_ms',
      'max_output_tokens',
    ]);
    expect(
      await stdin.preview(
        const <String, dynamic>{'session_id': 'exec-1', 'chars': 'ls\n'},
        context,
      ),
      'exec-1 ← ls',
    );
    expect(await stdin.preview(const <String, dynamic>{}, context), isNull);
  });

  test('malformed write_stdin arguments are rejected', () async {
    final result = await WriteStdinTool(host: host).execute(
      <String, dynamic>{
        'session_id': 7,
        'chars': null,
        'yield_time_ms': null,
        'max_output_tokens': null,
      },
      context,
    );

    expect(result.isError, isTrue);
    expect(decode(result)['error'], contains('must both be strings'));
  });

  test('the output budget is clamped to the supported range', () async {
    host.script('yes', <ExecSessionChunk>[
      const ExecSessionChunk(output: 'x', isRunning: false, exitCode: 0),
    ]);
    final result = await ExecCommandTool(host: host).execute(
      <String, dynamic>{
        'command': 'yes',
        'yield_time_ms': null,
        'max_output_tokens': 1,
      },
      context,
    );
    // A one-token request still gets the floor, so nothing useful is lost.
    expect(decode(result)['output'], 'x');
    expect(decode(result)['truncated'], isFalse);
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
          'command': 'sleep 100',
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
          risk: ToolRisk.command,
          workspaceRoot: '/workspace',
        );

    test('a session is approved once, not per keystroke', () async {
      const inner = DefaultApprovalPolicy(PermissionMode.ask);
      final policy = ExecSessionApprovalPolicy(inner, host);
      host.script('python3', <ExecSessionChunk>[
        const ExecSessionChunk(output: '>>> ', isRunning: true),
      ]);

      // Starting a command always asks.
      expect(
        policy.evaluate(
          invocation(execCommandToolName, <String, dynamic>{
            'command': 'python3',
          }),
        ),
        ApprovalEvaluation.ask,
      );

      final started = await ExecCommandTool(host: host).execute(
        <String, dynamic>{
          'command': 'python3',
          'yield_time_ms': null,
          'max_output_tokens': null,
        },
        context,
      );
      final sessionId = decode(started)['sessionId'];

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
            'session_id': 'exec-other',
          }),
        ),
        ApprovalEvaluation.ask,
      );
    });

    test('a read-only session is never unlocked by an approved id', () {
      const inner = DefaultApprovalPolicy(PermissionMode.readOnly);
      final policy = ExecSessionApprovalPolicy(inner, host);
      host.markApproved('exec-1');

      expect(
        policy.evaluate(
          invocation(writeStdinToolName, <String, dynamic>{
            'session_id': 'exec-1',
          }),
        ),
        ApprovalEvaluation.deny,
      );
    });

    test('an allow from the inner policy passes straight through', () {
      const inner = DefaultApprovalPolicy(PermissionMode.workspaceWrite);
      final policy = ExecSessionApprovalPolicy(inner, host);

      expect(
        policy.evaluate(
          const ToolInvocation(
            callId: 'call',
            name: 'read_file',
            arguments: <String, dynamic>{},
            risk: ToolRisk.read,
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
  final Map<String, _ScriptedExecSession> _sessions =
      <String, _ScriptedExecSession>{};
  final Set<String> _approved = <String>{};
  final List<_ScriptedExecSession> started = <_ScriptedExecSession>[];

  /// Cancelled just before the next read completes, if set.
  CancellationToken? cancelBeforeRead;

  void script(String command, List<ExecSessionChunk> chunks) =>
      _scripts[command] = Queue<ExecSessionChunk>.of(chunks);

  @override
  Future<ExecSession> start(String command, String workspaceRoot) async {
    final session = _ScriptedExecSession(
      id: 'exec-${started.length + 1}',
      command: command,
      workspaceRoot: workspaceRoot,
      chunks: _scripts[command] ?? Queue<ExecSessionChunk>(),
      onRead: () => cancelBeforeRead?.cancel(),
    );
    started.add(session);
    _sessions[session.id] = session;
    return session;
  }

  @override
  ExecSession? lookup(String sessionId) => _sessions[sessionId];

  @override
  bool isApproved(String sessionId) => _approved.contains(sessionId);

  @override
  void markApproved(String sessionId) => _approved.add(sessionId);
}

final class _ScriptedExecSession implements ExecSession {
  _ScriptedExecSession({
    required this.id,
    required this.command,
    required this.workspaceRoot,
    required this.chunks,
    required this.onRead,
  });

  @override
  final String id;

  final String command;
  final String workspaceRoot;
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
