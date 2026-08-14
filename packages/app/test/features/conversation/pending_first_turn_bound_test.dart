@Tags(<String>['feature_test__session_lifecycle__unit'])
library;

import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/features/conversation/application/pending_turns_controller.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/sessions/application/session_tabs_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../support/fake_tinest_api.dart';

final _now = DateTime.utc(2026, 8, 11);

SessionDto _session(String id) => SessionDto(
  id: id,
  worktreeId: 'checkout',
  title: id,
  status: SessionStatus.idle,
  agentDefinitionId: 'agent',
  origin: SessionOrigin.manual,
  model: const ModelSelectionDto(modelId: 'openai/gpt-5.6-sol'),
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  // `PendingFirstTurns` is a keepAlive map, so an entry nothing removes is
  // retained for the whole process. `markFailed` deliberately keeps the entry
  // so a mounting conversation pane can restore it in the composer — but if
  // the user closes the tab without ever opening that pane, nothing else was
  // reaching it. Closing the tab is the user saying they are done with it,
  // which makes it the bound this map was missing.
  test('closing a session tab forgets its pending first turn', () async {
    final api = FakeTinestApi(
      workspaces: <WorkspaceDto>[
        WorkspaceDto(
          id: 'workspace',
          name: 'Tinest',
          rootPath: '/repos/tinest',
          kind: WorkspaceKind.git,
          createdAt: _now,
        ),
      ],
      worktrees: <WorktreeDto>[
        WorktreeDto(
          id: 'checkout',
          workspaceId: 'workspace',
          name: 'main',
          path: '/repos/tinest',
          branch: 'main',
          head: 'abc',
          kind: WorktreeKind.checkout,
          isTinestOwned: false,
          createdAt: _now,
        ),
      ],
      agents: <SessionDto>[_session('session-a')],
    );
    final container = ProviderContainer(
      overrides: <Override>[
        appServicesProvider.overrideWithValue(fakeAppServices(api)),
      ],
    );
    addTearDown(container.dispose);

    const selection = WorkspaceSelection(
      hostId: 'server',
      workspaceId: 'workspace',
      worktreeId: 'checkout',
    );
    final tabs = sessionTabsControllerProvider(selection);
    // The tabs provider is auto-disposed, so a bare read would let it go while
    // its own async build is still in flight.
    final lease = container.listen(tabs, (_, _) {});
    addTearDown(lease.close);
    await container.read(tabs.future);
    container
        .read(pendingFirstTurnsProvider.notifier)
        .put('session-a', 'the prompt I typed');
    container.read(pendingFirstTurnsProvider.notifier).markFailed('session-a');
    expect(container.read(pendingFirstTurnsProvider), contains('session-a'));

    await container.read(tabs.notifier).close('session-a');

    expect(
      container.read(pendingFirstTurnsProvider),
      isNot(contains('session-a')),
    );
  });
}
