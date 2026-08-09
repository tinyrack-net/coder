import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/features/conversation/application/attachment_ports.dart';
import 'package:app/src/features/conversation/application/composer_controller.dart';
import 'package:app/src/features/conversation/application/composer_suggestions.dart';
import 'package:app/src/features/conversation/application/conversation_controller.dart';
import 'package:app/src/features/conversation/domain/composer_commands.dart';
import 'package:app/src/features/conversation/presentation/composer_trigger.dart';
import 'package:app/src/features/conversation/presentation/widgets/composer_suggestions_overlay.dart';
import 'package:app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:app/src/shared/domain/fuzzy_match.dart';
import 'package:app/src/shared/presentation/coder_icons.dart';
import 'package:dropwell/dropwell.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/src/internal/focus_source.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_coder_api.dart';
import '../../support/localization.dart';

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
    'a queued prompt that stopped retrying shows why and stays actionable',
    tags: const <String>['feature_test__conversation_turn_queue__widget'],
    (tester) async {
      await tester.pumpWidget(
        _harness(
          composer: SessionComposer(
            enabled: true,
            busy: true,
            queued: const <QueuedTurn>[
              QueuedTurn(
                id: 'q0',
                text: 'follow up',
                attachments: <PendingAttachment>[],
                attempts: conversationDrainMaxAttempts,
                error: 'Exception: offline',
              ),
            ],
            onSubmit: (_) {},
            onQueue: (_) {},
            onQueuedEdit: (_) => null,
            onQueuedSendNow: (_) {},
            bar: _bar(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A prompt that has stopped trying must not read like one that is
      // simply waiting its turn, or nobody knows to act on it.
      final error = find.byKey(const ValueKey('queued-turn-0-error'));
      expect(error, findsOneWidget);
      expect(
        tester.widget<TRText>(error).color,
        TRTextColor.danger,
      );
      expect(find.textContaining('offline'), findsOneWidget);

      final queuedCard = find.byKey(const ValueKey('queued-turn-0'));
      final queueIcon = find.descendant(
        of: queuedCard,
        matching: find.byIcon(CoderIcons.queue),
      );
      final prompt = find.descendant(
        of: queuedCard,
        matching: find.text('follow up'),
      );
      expect(
        tester.getRect(queueIcon).center.dy,
        closeTo(tester.getRect(prompt).center.dy, 0.5),
      );

      // Both ways out stay open: the prompt is never stranded beyond reach.
      expect(
        tester
            .widget<TRIconButton>(
              find.byKey(const ValueKey('queued-turn-0-edit')),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<TRIconButton>(
              find.byKey(const ValueKey('queued-turn-0-send')),
            )
            .onPressed,
        isNotNull,
      );
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
    'the card carries the focus of everything it frames',
    tags: const <String>['feature_test__session_lifecycle__widget'],
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
      await tester.pumpAndSettle();

      bool ringed() => tester.widget<TRCard>(find.byType(TRCard)).focused;
      Color inputBorder() => tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byKey(inputKey),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .map((container) => container.foregroundDecoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.border!.top.color)
          .first;

      expect(ringed(), isFalse);

      await tester.tap(find.byKey(inputKey));
      await tester.pumpAndSettle();
      expect(ringed(), isTrue);
      expect(
        inputBorder(),
        Colors.transparent,
        reason: 'the card rings the group, so the field must not ring itself',
      );

      // Tabbing on to an action inside the card keeps the group ringed: the
      // prompt and its controls are one control to the reader.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(ringed(), isTrue);

      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(ringed(), isFalse);
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
              contextTokens: 100000,
              contextWindow: 200000,
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

      // Narrow: the chips are still all there, the trailing ones as icons.
      await pumpAt(300);
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
        find.byKey(
          const ValueKey<String>('session-composer-context-meter'),
        ),
        findsOneWidget,
      );
      // The overflow stands in the dense chip row beside the attach and send
      // icon buttons, so it takes their square geometry at the same size.
      expect(
        tester.getSize(find.byKey(overflowKey)),
        Size.square(TRControlMetrics.heightOf(TRUiSize.sm)),
      );
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
        (0, TRStatusVariant.neutral),
        (140000, TRStatusVariant.warning),
        (180000, TRStatusVariant.warning),
        (200000, TRStatusVariant.danger),
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
        final meter = tester.widget<TRRadialMeter>(find.byKey(meterKey));
        expect(meter.variant, expected.$2, reason: '${expected.$1} tokens');
        expect(meter.max, 100);
        expect(meter.value, expected.$1 / 2000);
        expect(meter.uiSize, TRUiSize.sm);
      }
    },
  );

  testWidgets(
    'hover opens context details and lazily loads current provider quota',
    tags: const <String>[
      'feature_test__tool_context_budget__widget',
      'feature_test__provider_usage__widget',
    ],
    (tester) async {
      var loads = 0;
      await tester.pumpWidget(
        _harness(
          composer: SessionComposer(
            enabled: true,
            contextTokens: 150000,
            contextWindow: 200000,
            totalCostUsd: 1.25,
            providerConnectionId: 'openai',
            onLoadProviderUsage: () async {
              loads += 1;
              return <ProviderUsageDto>[
                ProviderUsageDto(
                  connectionId: 'openai',
                  status: ProviderUsageStatus.available,
                  fetchedAt: DateTime.utc(2026),
                  provider: 'OpenAI',
                  plan: 'plus',
                  windows: const <ProviderUsageWindowDto>[
                    ProviderUsageWindowDto(
                      kind: ProviderUsageWindowKind.session,
                      usedPercent: 40,
                    ),
                  ],
                ),
              ];
            },
            onSubmit: (_) {},
            bar: _bar(),
          ),
        ),
      );

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(
        tester.getCenter(
          find.byKey(
            const ValueKey<String>('session-composer-context-meter'),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(loads, 1);
      expect(find.text('75% 사용'), findsOneWidget);
      expect(find.text('150K / 200K 토큰'), findsOneWidget);
      expect(find.text(r'세션 비용 $1.25'), findsOneWidget);
      expect(find.text('OpenAI · plus'), findsOneWidget);
      expect(find.text('세션 한도'), findsOneWidget);
      expect(loads, 1);
    },
  );

  testWidgets(
    'keyboard focus opens context details and loads quota once',
    tags: const <String>[
      'feature_test__tool_context_budget__widget',
      'feature_test__provider_usage__widget',
    ],
    (tester) async {
      var loads = 0;
      await tester.pumpWidget(
        _harness(
          composer: SessionComposer(
            enabled: true,
            contextTokens: 150000,
            contextWindow: 200000,
            providerConnectionId: 'openai',
            onLoadProviderUsage: () async {
              loads += 1;
              return const <ProviderUsageDto>[];
            },
            onSubmit: (_) {},
            bar: _bar(),
          ),
        ),
      );

      expect(find.text('컨텍스트 사용량'), findsNothing);
      final trigger = find.byKey(
        const ValueKey<String>('session-composer-context-trigger'),
      );
      final triggerFocus =
          tester
                .widgetList<Focus>(
                  find.descendant(of: trigger, matching: find.byType(Focus)),
                )
                .singleWhere(
                  (focus) =>
                      focus.focusNode?.debugLabel ==
                      'session-composer-context-trigger',
                )
                .focusNode!
            ..requestFocus();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(triggerFocus.hasFocus, isTrue);
      expect(loads, 1);
      expect(find.text('컨텍스트 사용량'), findsOneWidget);
    },
  );

  testWidgets(
    'a composer shows one keyboard ring and no pointer ring',
    tags: const <String>['feature_test__turn_execution__widget'],
    (tester) async {
      TRFocusSource.instance.debugReset();
      addTearDown(TRFocusSource.instance.debugReset);
      await tester.pumpWidget(
        _harness(
          composer: SessionComposer(
            enabled: true,
            onSubmit: (_) {},
            bar: _bar(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(inputKey));
      await tester.pumpAndSettle();

      final focus = Theme.of(
        tester.element(find.byKey(inputKey)),
      ).extension<TinyrackThemeData>()!.focus;
      List<BorderSide> rings() => tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.border?.top)
          .nonNulls
          .where((side) => side.color == focus)
          .toList();

      expect(rings(), isEmpty);

      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      TRFocusSource.instance.debugSetKeyboardModality(true);
      await tester.pumpAndSettle();
      expect(rings(), hasLength(1));
    },
  );

  testWidgets(
    'a file mention completes into the prompt instead of sending',
    tags: const <String>['feature_test__composer_file_mention__widget'],
    (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        _completionHarness(
          onSubmit: (submission) => submitted.add(submission.text),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(inputKey), 'read @li');
      await tester.pumpAndSettle();
      expect(find.text('lib/app.dart'), findsOneWidget);

      // Down then Enter picks the second row and splices it; nothing is sent.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(submitted, isEmpty);
      expect(
        tester.widget<TRTextField>(find.byKey(inputKey)).controller!.text,
        'read @lib/composer.dart ',
      );

      // With the list closed, Enter sends the completed prompt.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(submitted, <String>['read @lib/composer.dart']);
    },
  );

  testWidgets(
    'Enter waits for a mention whose list has not arrived yet',
    tags: const <String>['feature_test__composer_file_mention__widget'],
    (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        _completionHarness(
          onSubmit: (submission) => submitted.add(submission.text),
          // The search is debounced and asynchronous, so the list is not on
          // screen on the frame the user presses Enter.
          suppressList: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(inputKey), 'read @READ');
      await tester.pumpAndSettle();
      expect(find.text('README.md'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // The half-typed mention is neither sent nor lost.
      expect(submitted, isEmpty);
      expect(
        tester.widget<TRTextField>(find.byKey(inputKey)).controller!.text,
        'read @READ',
      );

      // A finished mention sends as usual.
      await tester.enterText(find.byKey(inputKey), 'read @README.md ');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(submitted, <String>['read @README.md']);
    },
  );

  testWidgets(
    'Escape closes the mention list and returns Enter to sending',
    tags: const <String>['feature_test__composer_file_mention__widget'],
    (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        _completionHarness(
          onSubmit: (submission) => submitted.add(submission.text),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(inputKey), 'read @li');
      await tester.pumpAndSettle();
      expect(find.text('lib/app.dart'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('lib/app.dart'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(submitted, <String>['read @li']);
    },
  );

  testWidgets(
    'an open list takes plain Tab but leaves the modified one alone',
    tags: const <String>['feature_test__composer_file_mention__widget'],
    (tester) async {
      var toggles = 0;
      await tester.pumpWidget(
        _completionHarness(
          onSubmit: (_) {},
          onModeToggled: () => toggles += 1,
        ),
      );
      await tester.pumpAndSettle();

      Future<void> shiftTab() async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
      }

      // Closed, Shift+Tab cycles the mode.
      await tester.enterText(find.byKey(inputKey), 'plain');
      await tester.pumpAndSettle();
      await shiftTab();
      expect(toggles, 1);

      // Open, it still does: a held modifier makes the key the host's, so the
      // list never takes the mode shortcut away.
      await tester.enterText(find.byKey(inputKey), '@li');
      await tester.pumpAndSettle();
      expect(find.text('lib/app.dart'), findsOneWidget);
      await shiftTab();
      expect(toggles, 2);
      expect(
        tester.widget<TRTextField>(find.byKey(inputKey)).controller!.text,
        '@li',
      );

      // Plain Tab is the list's, and commits the highlighted row.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(toggles, 2);
      expect(
        tester.widget<TRTextField>(find.byKey(inputKey)).controller!.text,
        '@lib/app.dart ',
      );
    },
  );

  testWidgets(
    'Shift+Enter opens a line even with the list open',
    tags: const <String>['feature_test__composer_file_mention__widget'],
    (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        _completionHarness(
          onSubmit: (submission) => submitted.add(submission.text),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(inputKey), 'read @li');
      await tester.pumpAndSettle();
      expect(find.text('lib/app.dart'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      // Neither committed nor sent: the newline belongs to the field.
      expect(submitted, isEmpty);
      expect(
        tester.widget<TRTextField>(find.byKey(inputKey)).controller!.text,
        'read @li',
      );
    },
  );

  testWidgets(
    'a client command runs in the app and never starts a turn',
    tags: const <String>['feature_test__composer_slash_command__widget'],
    (tester) async {
      final submitted = <String>[];
      final ran = <ClientCommandAction>[];
      await tester.pumpWidget(
        _completionHarness(
          onSubmit: (submission) => submitted.add(submission.text),
          onClientCommand: (invocation) async {
            ran.add(invocation.command.action!);
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(inputKey), '/cle');
      await tester.pumpAndSettle();
      expect(find.text('clear'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(ran, <ClientCommandAction>[ClientCommandAction.clear]);
      expect(submitted, isEmpty);
    },
  );

  testWidgets(
    'a client command with attachments is refused rather than dropped',
    tags: const <String>['feature_test__composer_slash_command__widget'],
    (tester) async {
      final ran = <ClientCommandAction>[];
      await tester.pumpWidget(
        _completionHarness(
          onSubmit: (_) {},
          attachmentInput: const _OneFileAttachmentInput(),
          onClientCommand: (invocation) async {
            ran.add(invocation.command.action!);
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('session-composer-attach')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(inputKey), '/clear');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(ran, isEmpty);
      expect(
        find.byKey(const ValueKey('session-composer-attachment-error')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a command with no handler submits as ordinary text',
    tags: const <String>['feature_test__composer_slash_command__widget'],
    (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        _completionHarness(
          onSubmit: (submission) => submitted.add(submission.text),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(inputKey), '/clear');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(submitted, <String>['/clear']);
    },
  );

  testWidgets(
    'a skill command is expanded into the prompt that is sent',
    tags: const <String>['feature_test__composer_slash_command__widget'],
    (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        _completionHarness(
          onSubmit: (submission) => submitted.add(submission.text),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(inputKey), '/commit split it');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(submitted, <String>['Use the "commit" skill.\n\nsplit it']);
    },
  );

  testWidgets(
    'an open list does not send on the Enter that ends a composition',
    tags: const <String>['feature_test__composer_file_mention__widget'],
    (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        _completionHarness(
          onSubmit: (submission) => submitted.add(submission.text),
        ),
      );
      await tester.pumpAndSettle();

      // A live Korean composition spanning the token: no list, and the Enter
      // that commits the composition must not send either.
      final field = tester.widget<TRTextField>(find.byKey(inputKey));
      field.controller!.value = const TextEditingValue(
        text: '@한',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(submitted, isEmpty);
    },
  );

  testWidgets(
    'file mention keyboard selection stays inside the scroll viewport',
    tags: const <String>['feature_test__composer_file_mention__widget'],
    (tester) async {
      await tester.pumpWidget(
        _completionHarness(
          onSubmit: (_) {},
          files: const <String>[
            'lib/01.dart',
            'lib/02.dart',
            'lib/03.dart',
            'lib/04.dart',
            'lib/05.dart',
            'lib/06.dart',
            'lib/07.dart',
            'lib/08.dart',
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(inputKey), '@');
      await tester.pumpAndSettle();

      final scrollArea = find.descendant(
        of: find.byType(TRInlineSuggestions<String>),
        matching: find.byType(TRScrollArea),
      );
      bool isVisible(String label) {
        final viewport = tester.getRect(scrollArea);
        final row = tester.getRect(find.text(label));
        return row.top >= viewport.top && row.bottom <= viewport.bottom;
      }

      expect(isVisible('lib/08.dart'), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(isVisible('lib/08.dart'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(isVisible('lib/01.dart'), isTrue);
    },
  );

  testWidgets(
    'slash command keyboard selection stays inside the scroll viewport',
    tags: const <String>['feature_test__composer_slash_command__widget'],
    (tester) async {
      await tester.pumpWidget(_completionHarness(onSubmit: (_) {}));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(inputKey), '/');
      await tester.pumpAndSettle();

      final scrollArea = find.descendant(
        of: find.byType(TRInlineSuggestions<String>),
        matching: find.byType(TRScrollArea),
      );
      bool isVisible(String label) {
        final viewport = tester.getRect(scrollArea);
        final row = tester.getRect(find.text(label));
        return row.top >= viewport.top && row.bottom <= viewport.bottom;
      }

      expect(isVisible('skills'), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(isVisible('skills'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(isVisible('new'), isTrue);
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
  onModelChanged: (_, _) {},
  mode: SessionMode.normal,
  onModeChanged: (_) {},
);

/// A composer wired to a fixed catalog, so the tests exercise the composer
/// rather than the daemon-backed providers behind it.
Widget _completionHarness({
  required void Function(ComposerSubmission submission) onSubmit,
  Future<bool> Function(ComposerCommandInvocation invocation)? onClientCommand,
  VoidCallback? onModeToggled,
  AttachmentInputPort? attachmentInput,
  bool suppressList = false,
  List<String> files = _files,
}) => _harness(
  composer: _CompletionHost(
    onSubmit: onSubmit,
    onClientCommand: onClientCommand,
    onModeToggled: onModeToggled,
    attachmentInput: attachmentInput,
    suppressList: suppressList,
    files: files,
  ),
);

const List<String> _files = <String>[
  'lib/app.dart',
  'lib/composer.dart',
  'README.md',
];

/// Holds the active token the way the real completion scope does.
class _CompletionHost extends StatefulWidget {
  const _CompletionHost({
    required this.onSubmit,
    this.onClientCommand,
    this.onModeToggled,
    this.attachmentInput,
    this.suppressList = false,
    this.files = _files,
  });

  final void Function(ComposerSubmission submission) onSubmit;
  final Future<bool> Function(ComposerCommandInvocation invocation)?
  onClientCommand;
  final VoidCallback? onModeToggled;
  final AttachmentInputPort? attachmentInput;
  final bool suppressList;
  final List<String> files;

  @override
  State<_CompletionHost> createState() => _CompletionHostState();
}

class _CompletionHostState extends State<_CompletionHost> {
  ComposerTrigger? _trigger;

  late final List<ComposerCommand> _commands = mergeComposerCommands(
    client: clientComposerCommands,
    agent: const <AgentCommandDto>[],
    skills: const <SkillDto>[
      SkillDto(
        id: 'commit',
        name: 'commit',
        description: 'Writes atomic commits.',
        source: SkillSource.config,
        sourcePath: '/config/skills/commit/SKILL.md',
        contentHash: 'hash',
        body: 'Stage related changes together.',
      ),
    ],
  );

  ComposerSuggestionsState get _suggestions {
    final trigger = _trigger;
    // Stands in for the window before a debounced search has resolved, when
    // the token is typed but the list is not on screen yet.
    if (trigger == null || widget.suppressList) {
      return ComposerSuggestionsState.closed;
    }
    if (trigger.kind == ComposerTriggerKind.command) {
      return ComposerSuggestionsState(
        trigger: trigger,
        items: commandSuggestions(_commands, trigger.query),
      );
    }
    final matches = <FileMatchDto>[
      for (final path in widget.files)
        if (fuzzyMatch(path, trigger.query) != null)
          FileMatchDto(
            relativePath: path,
            absolutePath: '/worktree/$path',
            name: path.split('/').last,
            isDirectory: false,
          ),
    ];
    return ComposerSuggestionsState(
      trigger: trigger,
      items: fileSuggestions(
        rankFileMatches(matches, trigger.query),
        trigger.query,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SessionComposer(
    enabled: true,
    commands: _commands,
    suggestions: _suggestions,
    onCompletionQueryChanged: (trigger) => setState(() => _trigger = trigger),
    onClientCommand: widget.onClientCommand,
    onModeToggled: widget.onModeToggled,
    attachmentInput: widget.attachmentInput,
    onSubmit: widget.onSubmit,
    bar: _bar(),
  );
}

/// Supplies exactly one attachment, so a command submission has something to
/// collide with.
final class _OneFileAttachmentInput implements AttachmentInputPort {
  const _OneFileAttachmentInput();

  @override
  bool get supportsDrop => false;

  @override
  Future<List<PendingAttachment>> pickFiles() async => <PendingAttachment>[
    PendingAttachment.fromBytes(
      fileName: 'notes.txt',
      mimeType: 'text/plain',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    ),
  ];

  @override
  Future<List<PendingAttachment>> pasteFiles() async =>
      const <PendingAttachment>[];

  @override
  Future<List<PendingAttachment>> droppedFiles(
    List<DropwellFile> files,
  ) async => const <PendingAttachment>[];
}
