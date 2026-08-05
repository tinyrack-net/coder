import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tinyrack_pty/tinyrack_pty.dart';

void main() {
  test('reports its native ABI version', () {
    expect(tinyrackPtyVersion, '0.1.0');
  });

  test('creates sequential PTYs without blocking the caller isolate', () async {
    if (Platform.isWindows) return;
    for (var index = 0; index < 2; index += 1) {
      final process = await PtyProcess.start(
        '/bin/sh',
        workingDirectory: Directory.systemTemp.path,
      );
      final output = process.output.transform(utf8.decoder);
      final marker = 'tinyrack-pty-$index';
      final expected =
          '$marker:${Directory.systemTemp.resolveSymbolicLinksSync()}';
      final received = StringBuffer();
      final found = Completer<void>();
      final subscription = output.listen((chunk) {
        received.write(chunk);
        if (!found.isCompleted && received.toString().contains(expected)) {
          found.complete();
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await process.write(utf8.encode('printf "$marker:%s\\n" "\$PWD"\n'));

      await found.future.timeout(const Duration(seconds: 2));
      expect(received.toString(), contains(expected));
      await process.terminate();
      await subscription.cancel();
    }
  });

  test(
    'passes arguments and environment and reports exact exit code',
    () async {
      if (Platform.isWindows) return;
      final process = await PtyProcess.start(
        '/bin/sh',
        arguments: const <String>[
          '-c',
          r'printf "%s" "$PTY_VALUE"; exit 7',
        ],
        environment: const <String, String>{'PTY_VALUE': 'expected'},
      );

      expect(await process.output.transform(utf8.decoder).join(), 'expected');
      expect(await process.exitCode, 7);
    },
  );

  test('creates independent concurrent terminals', () async {
    if (Platform.isWindows) return;
    final processes = await Future.wait(
      List<Future<PtyProcess>>.generate(
        2,
        (_) => PtyProcess.start('/bin/sh'),
      ),
    );
    for (var index = 0; index < processes.length; index += 1) {
      final marker = 'concurrent-$index';
      final found = processes[index].output
          .transform(utf8.decoder)
          .firstWhere((chunk) => chunk.contains(marker));
      await processes[index].write(utf8.encode('printf "$marker\\n"\n'));
      expect(await found.timeout(const Duration(seconds: 2)), contains(marker));
    }
    await Future.wait(processes.map((process) => process.terminate()));
  });

  test('resizes the native terminal', () async {
    if (Platform.isWindows) return;
    final process = await PtyProcess.start('/bin/sh');
    final received = StringBuffer();
    final resized = Completer<void>();
    final subscription = process.output.transform(utf8.decoder).listen((chunk) {
      received.write(chunk);
      if (!resized.isCompleted && received.toString().contains('41 123')) {
        resized.complete();
      }
    });

    process.resize(columns: 123, rows: 41);
    await process.write(utf8.encode('stty size\n'));
    await resized.future.timeout(const Duration(seconds: 2));
    await process.terminate();
    await subscription.cancel();
  });

  test('forces an uncooperative process group to exit', () async {
    if (Platform.isWindows) return;
    final process = await PtyProcess.start(
      '/bin/sh',
      arguments: <String>[
        '-c',
        <String>[
          r'''sleep 30 & child=$!; printf '%s\n' "$child";''',
          r'''trap '' TERM HUP; wait "$child"''',
        ].join(' '),
      ],
    );
    final childPid = int.parse(
      (await process.output.transform(utf8.decoder).first).trim(),
    );

    await process.terminate(
      gracePeriod: const Duration(milliseconds: 50),
    );

    expect(await process.exitCode, isNonZero);
    expect(process.status, PtyStatus.exited);
    expect(
      (await Process.run('kill', <String>['-0', '$childPid'])).exitCode,
      1,
    );
    await process.terminate();
    await expectLater(
      process.write(const <int>[1]),
      throwsA(isA<StateError>()),
    );
    expect(
      () => process.resize(columns: 80, rows: 24),
      throwsStateError,
    );
  });

  test('rejects an invalid executable with a typed error', () async {
    await expectLater(
      PtyProcess.start('/definitely/missing-tinyrack-shell'),
      throwsA(
        isA<PtyException>()
            .having((error) => error.operation, 'operation', 'start')
            .having((error) => error.errorCode, 'errorCode', isNonZero),
      ),
    );
  });

  test('rejects a non-executable file before returning a process', () async {
    if (Platform.isWindows) return;
    final directory = await Directory.systemTemp.createTemp(
      'tinyrack-pty-not-executable-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/shell.sh');
    await file.writeAsString('#!/bin/sh\nexit 0\n');

    await expectLater(
      PtyProcess.start(file.path),
      throwsA(
        isA<PtyException>()
            .having((error) => error.operation, 'operation', 'start')
            .having((error) => error.errorCode, 'errorCode', isNonZero)
            .having((error) => error.message, 'message', isNotEmpty),
      ),
    );
  });

  test('preserves a large ordered input write', () async {
    if (Platform.isWindows) return;
    final process = await PtyProcess.start(
      '/bin/sh',
      arguments: const <String>[
        '-c',
        'stty raw -echo; printf READY; head -c 1048576 | wc -c',
      ],
    );
    final received = StringBuffer();
    final ready = Completer<void>();
    final subscription = process.output.transform(utf8.decoder).listen((chunk) {
      received.write(chunk);
      if (!ready.isCompleted && received.toString().contains('READY')) {
        ready.complete();
      }
    });
    await ready.future.timeout(const Duration(seconds: 2));
    final payload = List<int>.filled(1024 * 1024, 65);
    await process.write(payload);
    expect(await process.exitCode, 0);
    await subscription.cancel();
    expect(received.toString(), contains('${payload.length}'));
  });

  test('fails a queued write when the child exits early', () async {
    if (Platform.isWindows) return;
    final process = await PtyProcess.start(
      '/bin/sh',
      arguments: const <String>['-c', 'exit 0'],
    );

    await expectLater(
      process.write(List<int>.filled(8 * 1024 * 1024, 65)),
      throwsA(anyOf(isA<StateError>(), isA<PtyException>())),
    );
    expect(await process.exitCode, anyOf(0, -1));
  });

  test('validates dimensions and working directory', () async {
    await expectLater(
      PtyProcess.start('/bin/sh', columns: 0),
      throwsArgumentError,
    );
    await expectLater(
      PtyProcess.start(
        '/bin/sh',
        workingDirectory: '/definitely/missing-tinyrack-directory',
      ),
      throwsA(isA<PtyException>()),
    );
    final process = await PtyProcess.start(
      Platform.isWindows ? 'cmd.exe' : 'sh',
    );
    expect(
      () => process.resize(columns: -1, rows: 24),
      throwsArgumentError,
    );
    await process.terminate();
    expect(
      const PtyException(
        operation: 'test',
        errorCode: 5,
        message: 'failure',
      ).toString(),
      'PtyException(test, 5): failure',
    );
  });

  test(
    'Windows ConPTY exchanges input, resizes, and returns exit code',
    () async {
      if (!Platform.isWindows) return;
      final process = await PtyProcess.start(
        'cmd.exe',
        arguments: const <String>['/d', '/q'],
        environment: const <String, String>{'PTY_VALUE': 'windows-ready'},
      );
      addTearDown(process.terminate);
      final received = StringBuffer();
      final marker = Completer<void>();
      final subscription = process.output.transform(utf8.decoder).listen((
        chunk,
      ) {
        received.write(chunk);
        if (!marker.isCompleted &&
            received.toString().contains('windows-ready')) {
          marker.complete();
        }
      });

      process.resize(columns: 111, rows: 37);
      await process.write(
        utf8.encode('echo %PTY_VALUE% & exit /b 9\r'),
      );

      await marker.future.timeout(const Duration(seconds: 15));
      expect(await process.exitCode, 9);
      await subscription.cancel();
    },
  );

  test('Windows Job Object terminates child processes', () async {
    if (!Platform.isWindows) return;
    final directory = await Directory.systemTemp.createTemp(
      'tinyrack-pty-job-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final script = File('${directory.path}\\job.ps1');
    await script.writeAsString(
      <String>[
        r'$p=Start-Process -FilePath powershell.exe `',
        "  -ArgumentList @('-NoProfile','-Command','Start-Sleep 30') `",
        '  -PassThru',
        r"Write-Output ('CHILD:'+$p.Id)",
        'Start-Sleep 30',
      ].join('\r\n'),
    );
    final process = await PtyProcess.start(
      'powershell.exe',
      arguments: <String>[
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-File',
        script.path,
      ],
    );
    addTearDown(process.terminate);
    final received = StringBuffer();
    final childPid = Completer<int>();
    final subscription = process.output.transform(utf8.decoder).listen((chunk) {
      received.write(chunk);
      final match = RegExp(r'^CHILD:(\d+)\r?$', multiLine: true).firstMatch(
        received.toString(),
      );
      if (match != null && !childPid.isCompleted) {
        childPid.complete(int.parse(match.group(1)!));
      }
    });
    final pid = await childPid.future.timeout(const Duration(seconds: 15));

    await process.terminate(
      gracePeriod: const Duration(milliseconds: 50),
    );
    await subscription.cancel();
    final check = await Process.run('powershell.exe', <String>[
      '-NoProfile',
      '-Command',
      <String>[
        'if (Get-Process -Id $pid -ErrorAction SilentlyContinue)',
        '{ exit 1 } else { exit 0 }',
      ].join(' '),
    ]);
    expect(check.exitCode, 0);
  });

  test('Windows queues a large write without blocking the isolate', () async {
    if (!Platform.isWindows) return;
    const length = 1024 * 1024;
    final process = await PtyProcess.start(
      'powershell.exe',
      arguments: <String>[
        '-NoLogo',
        '-NoProfile',
        '-Command',
        <String>[
          r'$s=[Console]::OpenStandardInput();',
          r'$b=New-Object byte[] 65536;$t=0;',
          r'while($t -lt 1048576){',
          r'$n=$s.Read($b,0,[Math]::Min($b.Length,1048576-$t));',
          r'if($n -eq 0){break};$t+=$n};',
          r'[Console]::Write($t);if($t -eq 1048576){exit 0}else{exit 2}',
        ].join(),
      ],
    );
    addTearDown(process.terminate);
    var isolateWasResponsive = false;
    final heartbeat = Timer(
      const Duration(milliseconds: 10),
      () => isolateWasResponsive = true,
    );
    addTearDown(heartbeat.cancel);

    await process.write(<int>[...List<int>.filled(length, 65), 13]);
    final output = await process.output.transform(utf8.decoder).join();

    expect(await process.exitCode, 0);
    expect(output, contains('$length'));
    expect(isolateWasResponsive, isTrue);
  });
}
