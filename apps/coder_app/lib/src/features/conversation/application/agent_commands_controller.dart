import 'dart:async';

import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agent_commands_controller.g.dart';

@riverpod
/// Loads the agent commands one daemon offers, optionally for one project.
///
/// A null [AgentCommandsController.workspaceId] shows only the user-home and
/// daemon-config sources; naming a workspace layers its `.agents/commands` on
/// top.
class AgentCommandsController extends _$AgentCommandsController {
  StreamSubscription<ClientEvent>? _events;

  @override
  Future<List<AgentCommandDto>> build(
    String hostId,
    String? workspaceId,
  ) async {
    final api = await watchHostApi(ref, hostId);
    _events = api.events.listen((event) {
      if (event is CommandsChangedClientEvent) unawaited(refresh());
    });
    ref.onDispose(() => unawaited(_events?.cancel()));
    return api.listCommands(workspaceId: workspaceId);
  }

  /// Reloads the catalog from the daemon.
  Future<void> refresh() async {
    final api = await requireHostApi(ref, hostId);
    final commands = await api.listCommands(workspaceId: workspaceId);
    if (!ref.mounted) return;
    state = AsyncData<List<AgentCommandDto>>(commands);
  }
}
