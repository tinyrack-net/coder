import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/session_composer.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import 'support/fake_coder_api.dart';
import 'support/localization.dart';

void main() {
  const inputKey = ValueKey<String>('session-composer-input');
  const sendKey = ValueKey<String>('session-composer-send');

  testWidgets(
    'Enter sends, Shift+Enter opens a line, and touch platforms only tap',
    tags: const <String>['feature_test__turn_execution__widget'],
    (tester) async {
      for (final platform in <TargetPlatform>[
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.android,
      ]) {
        final sends = platform != TargetPlatform.android;
        final submitted = <String>[];
        await tester.pumpWidget(
          _harness(
            platform: platform,
            composer: SessionComposer(
              // A fresh composer per platform, so no text or focus carries
              // over from the previous run.
              key: ValueKey<TargetPlatform>(platform),
              enabled: true,
              onSubmit: (submission) => submitted.add(submission.text),
              bar: _bar(),
            ),
          ),
        );
        // MaterialApp animates between themes and only swaps `platform` at
        // the halfway point, so the new platform is not in effect until the
        // transition finishes.
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(inputKey), 'first');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(
          submitted,
          sends ? <String>['first'] : isEmpty,
          reason: 'Enter on $platform',
        );

        // Shift+Enter belongs to the text field on every platform.
        await tester.enterText(find.byKey(inputKey), 'second');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(
          submitted,
          sends ? <String>['first'] : isEmpty,
          reason: 'Shift+Enter on $platform',
        );

        // The button is the way in on a touch keyboard, and still works
        // everywhere else.
        await tester.tap(find.byKey(sendKey));
        await tester.pumpAndSettle();
        expect(
          submitted.last,
          'second',
          reason: 'send button on $platform',
        );
      }
    },
  );

  testWidgets(
    'an unfinished composition never sends on the Enter that ends it',
    tags: const <String>['feature_test__turn_execution__widget'],
    (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        _harness(
          composer: SessionComposer(
            enabled: true,
            onSubmit: (submission) => submitted.add(submission.text),
            bar: _bar(),
          ),
        ),
      );

      await tester.tap(find.byKey(inputKey));
      await tester.pump();
      final state =
          tester.state<EditableTextState>(
            find.byType(EditableText),
          )..updateEditingValue(
            const TextEditingValue(
              text: '한글',
              selection: TextSelection.collapsed(offset: 2),
              composing: TextRange(start: 0, end: 2),
            ),
          );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(submitted, isEmpty);

      state.updateEditingValue(
        const TextEditingValue(
          text: '한글',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(submitted, <String>['한글']);
    },
  );

  testWidgets(
    'a running turn queues instead of locking the input',
    tags: const <String>['feature_test__conversation_turn_queue__widget'],
    (tester) async {
      final queued = <QueuedTurn>[];
      final sent = <String>[];
      final interrupted = <String>[];
      late StateSetter refresh;
      await tester.pumpWidget(
        _harness(
          composer: StatefulBuilder(
            builder: (context, setState) {
              refresh = setState;
              return SessionComposer(
                enabled: true,
                busy: true,
                queued: List<QueuedTurn>.of(queued),
                onSubmit: (submission) => sent.add(submission.text),
                onSubmitAndInterrupt: (submission) =>
                    interrupted.add(submission.text),
                onQueue: (submission) => setState(
                  () => queued.add(
                    QueuedTurn(
                      id: 'q${queued.length}',
                      text: submission.text,
                      attachments: submission.attachments,
                    ),
                  ),
                ),
                onQueuedEdit: (id) {
                  final item = queued.where((q) => q.id == id).firstOrNull;
                  if (item != null) setState(() => queued.remove(item));
                  return item;
                },
                onQueuedSendNow: (id) => setState(
                  () => queued.removeWhere((q) => q.id == id),
                ),
                bar: _bar(),
              );
            },
          ),
        ),
      );

      // Typing is never taken away, and the button says what it will do.
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
      expect(
        findAccessibleAction(testL10n.composerQueueLabel),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(inputKey), 'follow up');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(queued.map((item) => item.text), <String>['follow up']);
      expect(sent, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.byKey(const ValueKey('queued-turn-0')), findsOneWidget);

      // Editing brings the prompt back so it can be changed or dropped.
      await tester.tap(find.byKey(const ValueKey('queued-turn-0-edit')));
      await tester.pumpAndSettle();
      expect(queued, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'follow up',
      );

      // Ctrl+Enter goes past the running turn instead of waiting for it.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(interrupted, <String>['follow up']);
      expect(queued, isEmpty);
      refresh(() {});
    },
  );

  testWidgets(
    'a failed send returns the prompt to the input',
    tags: const <String>['feature_test__turn_execution__widget'],
    (tester) async {
      var fail = true;
      await tester.pumpWidget(
        _harness(
          composer: SessionComposer(
            enabled: true,
            onSubmit: (_) async {
              if (fail) throw Exception('offline');
            },
            bar: _bar(),
          ),
        ),
      );

      await tester.enterText(find.byKey(inputKey), 'keep me');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'keep me',
      );
      expect(
        find.byKey(const ValueKey('session-composer-attachment-error')),
        findsOneWidget,
      );

      fail = false;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'the settings toolbar drops labels, then chips, as width runs out',
    tags: const <String>['feature_test__session_lifecycle__widget'],
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;

      const chips = <String>[
        'session-composer-agent',
        'session-composer-model',
        'session-composer-permission',
        'session-composer-mode',
      ];
      const overflowKey = ValueKey<String>('session-composer-overflow');

      Future<void> pumpAt(double width) async {
        tester.view.physicalSize = Size(width, 800);
        await tester.pumpWidget(
          _harness(
            composer: SessionComposer(
              key: ValueKey<double>(width),
              enabled: true,
              onSubmit: (_) {},
              bar: _bar(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      // Wide: every chip keeps its label.
      await pumpAt(1400);
      expect(tester.takeException(), isNull);
      for (final chip in chips) {
        expect(find.byKey(ValueKey<String>(chip)), findsOneWidget);
      }
      expect(find.byKey(overflowKey), findsNothing);
      final labelled = tester.getSize(
        find.byKey(const ValueKey('session-composer-mode')),
      );

      // Narrow: the chips are still all there, as icons.
      await pumpAt(420);
      expect(tester.takeException(), isNull);
      for (final chip in chips) {
        expect(find.byKey(ValueKey<String>(chip)), findsOneWidget);
      }
      expect(
        tester
            .getSize(find.byKey(const ValueKey('session-composer-mode')))
            .width,
        lessThan(labelled.width),
      );

      // Narrower still: whatever cannot fit moves into one menu.
      await pumpAt(200);
      expect(tester.takeException(), isNull);
      expect(find.byKey(overflowKey), findsOneWidget);
      expect(
        find.byKey(const ValueKey('session-composer-mode')),
        findsNothing,
      );
      // The attach and send actions are reachable at every width.
      expect(
        find.byKey(const ValueKey('session-composer-attach')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('session-composer-send')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the composer names no shortcut it does not implement',
    tags: const <String>['feature_test__turn_execution__widget'],
    (tester) async {
      await tester.pumpWidget(
        _harness(
          composer: SessionComposer(
            enabled: true,
            onSubmit: (_) {},
            bar: _bar(),
          ),
        ),
      );

      expect(find.textContaining('Ctrl+L'), findsNothing);
    },
  );

  testWidgets(
    'the context meter appears only once a window is known',
    tags: const <String>['feature_test__tool_context_budget__widget'],
    (tester) async {
      const meterKey = ValueKey<String>('session-composer-context-meter');

      // A provider that never advertised a window would make any percentage a
      // fiction, so nothing is drawn at all.
      await tester.pumpWidget(
        _harness(
          composer: SessionComposer(
            enabled: true,
            contextTokens: 4000,
            onSubmit: (_) {},
            bar: _bar(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(meterKey), findsNothing);

      for (final expected in <(int, TRStatusVariant)>[
        (32000, TRStatusVariant.neutral),
        (170000, TRStatusVariant.warning),
        (196000, TRStatusVariant.danger),
      ]) {
        await tester.pumpWidget(
          _harness(
            composer: SessionComposer(
              enabled: true,
              contextTokens: expected.$1,
              contextWindow: 200000,
              onSubmit: (_) {},
              bar: _bar(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final meter = tester.widget<TRMeter>(find.byKey(meterKey));
        expect(meter.variant, expected.$2, reason: '${expected.$1} tokens');
        expect(meter.max, 200000);
        expect(meter.value, expected.$1);
      }
    },
  );
}

Widget _harness({
  required Widget composer,
  TargetPlatform platform = TargetPlatform.linux,
}) => ProviderScope(
  overrides: [
    appServicesProvider.overrideWithValue(fakeAppServices(FakeCoderApi())),
  ],
  child: MaterialApp(
    theme: testLightTheme.copyWith(platform: platform),
    locale: testLocale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Align(alignment: Alignment.bottomCenter, child: composer),
    ),
  ),
);

SessionComposerBar _bar() => SessionComposerBar(
  hostId: 'server',
  definitions: const <AgentDefinitionDto>[],
  agentDefinitionId: null,
  selection: null,
  onAgentChanged: (_) {},
  onModelChanged: (_) {},
  mode: SessionMode.normal,
  onModeChanged: (_) {},
);
