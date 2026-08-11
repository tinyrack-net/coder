import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/sessions/application/session_tabs_controller.dart';
import 'package:app/src/features/terminals/application/terminal_session_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terminal_session_leases.g.dart';

/// Terminal identities one checkout currently shows as tabs.
///
/// Deliberately a provider rather than a getter on the tabs state: it is the
/// key the leases below are derived from, and it has to be able to hold the
/// previous answer across a reload frame.
@riverpod
class OpenTerminalIds extends _$OpenTerminalIds {
  // Riverpod keeps one notifier instance per element across rebuilds, so this
  // outlives every rebuild of [build] and goes away only with the element.
  Set<String> _last = const <String>{};

  @override
  Set<String> build(WorkspaceSelection selection) {
    final tabs = ref.watch(sessionTabsControllerProvider(selection));
    // `value` rather than `asData`: it retains the last data across a reload,
    // and a reload frame must never read as "the user closed every terminal".
    final data = tabs.value;
    if (data == null) return _last;
    final next = <String>{
      for (final entry in data.tabs.values)
        if (entry.target case TerminalTabTarget(:final terminalId)) terminalId,
    };
    // Returning the identical instance when nothing changed is what keeps a
    // tab switch — which republishes the whole tab registry — from churning
    // the leases below. `Notifier` has no `updateShouldNotify` to override, so
    // identity is the only lever here.
    if (next.length == _last.length && next.containsAll(_last)) return _last;
    return _last = Set<String>.unmodifiable(next);
  }
}

/// Holds one lease per open terminal tab, and does nothing else.
///
/// Terminal sessions must outlive their pane: switching tabs, splitting a
/// pane, or scrolling a tab off screen unmounts the view, and none of those
/// may reset the emulator. Something therefore has to decide when a session
/// really is over, and that decision belongs in the provider graph rather than
/// in a widget. A widget that ends a lifetime has to do it from a lifecycle
/// callback, and `Ref.invalidate` schedules its refresh through `setState`, so
/// doing it from `didUpdateWidget` — which runs inside the build phase —
/// throws "setState() or markNeedsBuild() called during build".
///
/// Leasing instead makes that unreachable. A dropped lease ends the session by
/// auto-disposal, which Riverpod drains in a microtask, after the frame.
@riverpod
class TerminalSessionLeases extends _$TerminalSessionLeases {
  @override
  Set<String> build(WorkspaceSelection selection) {
    final ids = ref.watch(openTerminalIdsProvider(selection));
    for (final terminalId in ids) {
      // A lease, not an observation: the callback is empty on purpose, so a
      // terminal's output never rebuilds this provider. Riverpod drops the
      // previous build's listeners on rebuild, which means it performs the
      // set difference itself and there is no diffing code here to get wrong.
      ref.listen(
        terminalSessionControllerProvider(selection.hostId, terminalId),
        (_, _) {},
      );
    }
    return ids;
  }
}
