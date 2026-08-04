import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_coder_api.dart';
import 'support/localization.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/repos/coder',
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
    isCoderOwned: false,
    createdAt: now,
  );
  final agent = SessionDto(
    id: 'session',
    worktreeId: checkout.id,
    title: 'Session',
    agentDefinitionId: 'coder',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    createdAt: now,
    updatedAt: now,
  );

  TimelineEventDto approvalEvent(int index) {
    final approval = ApprovalRequestDto(
      id: 'approval-$index',
      sessionId: agent.id,
      turnId: 'turn',
      toolCallId: 'call-$index',
      toolName: 'apply_patch',
      risk: ToolRisk.write,
      arguments: <String, dynamic>{'patch': 'diff $index'},
      // A long preview is what makes one card tall enough to matter.
      preview: List<String>.generate(
        40,
        (line) => 'preview line $line of approval $index',
      ).join('\n'),
      status: ApprovalStatus.pending,
      createdAt: now,
    );
    return TimelineEventDto(
      sessionId: agent.id,
      sequence: index + 1,
      type: 'approval.requested',
      data: <String, dynamic>{'approval': approval.toJson()},
      createdAt: now,
    );
  }

  testWidgets(
    'pending approvals scroll instead of overflowing the conversation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[agent],
        timelines: <String, List<TimelineEventDto>>{
          agent.id: <TimelineEventDto>[
            for (var index = 0; index < 3; index += 1) approvalEvent(index),
          ],
        },
      );
      final router = GoRouter(
        initialLocation:
            '/workspaces/server/${workspace.id}/${checkout.id}'
            '/sessions/${agent.id}',
        routes: $appRoutes,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp.router(
            theme: testLightTheme,
            darkTheme: testDarkTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Three tall approvals cannot fit above the composer, so the pane has to
      // scroll them rather than paint past its own bottom edge.
      expect(find.text('승인 필요 · apply_patch'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__turn_execution__widget'],
  );
}
