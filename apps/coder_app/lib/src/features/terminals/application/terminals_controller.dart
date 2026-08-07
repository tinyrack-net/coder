import 'dart:async';

import 'package:coder_app/src/app/composition/app_providers.dart';
import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terminals_controller.g.dart';

@riverpod
/// Loads and edits the daemon-wide shell inherited by project terminals.
class HostShellSettingsController extends _$HostShellSettingsController {
  @override
  Future<ShellSpecDto?> build(String hostId) async {
    final api = await watchHostApi(ref, hostId);
    return api.terminals.getTerminalShell();
  }

  /// Replaces or clears the daemon-wide terminal shell.
  Future<void> save(ShellSpecDto? shell) async {
    final api = await requireHostApi(ref, hostId);
    await api.terminals.setTerminalShell(shell);
    state = AsyncData<ShellSpecDto?>(shell);
  }
}

@riverpod
/// Owns the live terminal catalog for one connected worktree.
class TerminalsController extends _$TerminalsController {
  StreamSubscription<TerminalDto>? _events;

  @override
  Future<List<TerminalDto>> build(String hostId, String worktreeId) async {
    final runtime = (await ref.watch(
      hostRegistryControllerProvider.future,
    )).runtimes[hostId];
    if (runtime?.connected != true) return const <TerminalDto>[];
    final api = runtime!.api!;
    _events = api.terminals.terminalUpdates.listen((terminal) {
      if (terminal.worktreeId == worktreeId) {
        final current = state.asData?.value ?? const <TerminalDto>[];
        state = AsyncData<List<TerminalDto>>(<TerminalDto>[
          terminal,
          ...current.where((item) => item.id != terminal.id),
        ]);
      }
    });
    ref.onDispose(() => unawaited(_events?.cancel()));
    return api.terminals.listTerminals(worktreeId);
  }

  /// Creates a terminal with a standard initial character grid.
  Future<TerminalDto> create() async {
    final api = await requireHostApi(ref, hostId);
    final current = state.asData?.value ?? const <TerminalDto>[];
    final terminal = await api.terminals.createTerminal(
      id: ref.read(appIdGeneratorProvider).generate(),
      worktreeId: worktreeId,
      title: 'Terminal ${current.length + 1}',
      columns: 80,
      rows: 24,
    );
    state = AsyncData<List<TerminalDto>>(<TerminalDto>[terminal, ...current]);
    return terminal;
  }
}

/// Visible and selected session tabs for one worktree.
