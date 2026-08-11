import 'dart:io';

import 'package:daemon/src/features/terminals/application/terminal_service.dart';
import 'package:daemon/src/features/terminals/domain/terminal.dart';
import 'package:daemon/src/features/terminals/infrastructure/portable_terminal.dart';
import 'package:test/test.dart';

void main() {
  test(
    'portable terminal maps shell launch failures to a typed reason',
    () async {
      await expectLater(
        const PtyworldTerminalGateway().start(
          shell: const TerminalShell(
            executable: 'tinest-definitely-missing-terminal-shell',
          ),
          workingDirectory: Directory.systemTemp.path,
          columns: 80,
          rows: 24,
        ),
        throwsA(
          isA<TerminalCreationException>().having(
            (error) => error.reason,
            'reason',
            TerminalCreationFailureReason.startFailed,
          ),
        ),
      );
    },
    tags: const <String>['feature_test__terminal_lifecycle__unit'],
  );
}
