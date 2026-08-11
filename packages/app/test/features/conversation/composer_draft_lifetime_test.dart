@Tags(<String>['feature_test__session_lifecycle__unit'])
library;

import 'package:app/src/features/conversation/application/composer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/provider_lifetime_recorder.dart';

void main() {
  // Characterization, not an aspiration. The audit that produced the terminal
  // lease redesign flagged this family as the other unbounded `keepAlive`, but
  // nobody had confirmed it actually grows. It does: nothing per draft ever
  // ends, so the count below rises with every draft the user opens and is only
  // ever reset wholesale by the data reset in advanced settings.
  //
  // Left as it is on purpose. A draft outlives its tab by design — the
  // new-workspace composer holds one with no tab at all, and session creation
  // deliberately outlives the draft's promotion — so leasing it to the tab set
  // the way terminals are leased would discard input the user typed. That is a
  // worse failure than the growth it would fix, and it needs its own change
  // with its own tests. `ArchitectureVerifier._keepAliveProviderOwners` records
  // the same thing, which is what keeps "later" from becoming "never".
  test('every composer draft is retained for the life of the process', () {
    final lifetimes = ProviderLifetimeRecorder();
    final container = ProviderContainer(
      observers: <ProviderObserver>[lifetimes],
    );
    addTearDown(container.dispose);

    final drafts = <SessionComposerDraftControllerProvider>[
      for (var index = 0; index < 5; index += 1)
        sessionComposerDraftControllerProvider(
          'server',
          'checkout',
          'draft:$index',
        ),
    ];
    for (final draft in drafts) {
      // Reading is all a composer does; there is no matching close.
      container.read(draft.notifier).selectAgent('agent');
    }

    expect(drafts.where(lifetimes.isAlive), hasLength(5));
  });
}
