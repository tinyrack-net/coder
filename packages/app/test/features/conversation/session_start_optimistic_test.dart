import 'package:app/src/app/composition/app_primitives.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/conversation/application/pending_turns_controller.dart';
import 'package:app/src/features/conversation/presentation/chat_timeline_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/localization.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Tinest',
    rootPath: '/repos/tinest',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  final checkout = WorktreeDto(
    id: 'checkout',
    workspaceId: workspace.id,
    name: 'main',
    path: workspace.rootPath,
    branch: 'main',
    head: 'abc',
    kind: WorktreeKind.checkout,
    isTinestOwned: false,
    createdAt: now,
  );
  final location = WorktreeRoute(
    hostId: 'server',
    workspaceId: workspace.id,
    worktreeId: checkout.id,
  ).location;

  Future<GoRouter> pumpDraft(WidgetTester tester, FakeTinestApi api) async {
    final router = GoRouter(initialLocation: location, routes: $appRoutes);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(fakeAppServices(api)),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            size: tester.view.physicalSize / tester.view.devicePixelRatio,
          ),
          child: MaterialApp.router(
            theme: testLightTheme,
            darkTheme: testDarkTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'a failed first turn keeps the prompt in the queued list',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      )..startTurnError = Exception('daemon rejected the turn');
      final router = await pumpDraft(tester, api);
      addTearDown(router.dispose);

      const prompt = 'Prompt that must not be lost';
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        prompt,
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      for (var frame = 0; frame < 8; frame += 1) {
        await tester.pump();
      }

      // The chat room opened despite the failure, and the prompt survived
      // into the queued-turn list rather than disappearing.
      expect(find.byType(ChatTimelineView).hitTestable(), findsOneWidget);
      expect(api.attemptedPrompts, contains(prompt));
      expect(
        find.byKey(const ValueKey<String>('queued-turn-0')).hitTestable(),
        findsOneWidget,
      );
      expect(find.text(prompt, findRichText: true), findsWidgets);
    },
    tags: const <String>['feature_test__workspace_async_loading__widget'],
  );

  test('the pending first-turn registry records and forgets prompts', () {
    final container = ProviderContainer(
      overrides: [
        appClockProvider.overrideWithValue(_FixedClock(now)),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(pendingFirstTurnsProvider.notifier)
      ..put('session-1', 'Hello');
    final entry = container.read(pendingFirstTurnsProvider)['session-1']!;
    expect(entry.prompt, 'Hello');
    expect(entry.createdAt, now);
    expect(entry.failed, isFalse);
    notifier.markFailed('session-1');
    expect(
      container.read(pendingFirstTurnsProvider)['session-1']!.failed,
      isTrue,
    );
    // Marking an unknown id is a no-op rather than an error.
    notifier
      ..markFailed('session-unknown')
      ..clear('session-1');
    expect(container.read(pendingFirstTurnsProvider), isEmpty);
    // Clearing an unknown id is a no-op rather than an error.
    notifier.clear('session-unknown');
    expect(container.read(pendingFirstTurnsProvider), isEmpty);
  });
}

final class _FixedClock implements AppClock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}
