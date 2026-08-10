import 'dart:async';

import 'package:app/src/features/hosts/application/host_controller.dart';
import 'package:client/client.dart';
import 'package:protocol/protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terminal_attach_controller.g.dart';

/// A live daemon attachment for one terminal.
final class TerminalAttachment {
  /// Creates an attachment result.
  const TerminalAttachment({required this.api, required this.replay});

  /// Connected API the attached pane writes input and resizes through.
  final CoderApi api;

  /// Scrollback recorded before this attachment, oldest first.
  final List<TerminalOutputDto> replay;
}

@Riverpod(retry: noAutomaticRetry)
/// Attaches to one daemon terminal and returns its replayed scrollback.
///
/// The terminal grid mounts immediately and overlays a visible connecting
/// state from this provider's loading phase, instead of presenting an empty
/// prompt that silently swallows keystrokes. Failures surface an explicit
/// retry, which re-runs this build via invalidation.
class TerminalAttachController extends _$TerminalAttachController {
  @override
  Future<TerminalAttachment> build(String hostId, String terminalId) async {
    // Selecting the connected API identity, rather than watching the whole
    // registry, keeps unrelated registry updates from re-attaching (and
    // re-replaying) an already live terminal.
    final api = watchHostConnection(ref, hostId).api;
    if (api == null) {
      // Stay loading until the daemon connects; the selector re-runs this
      // build as soon as a connected API appears.
      return Completer<TerminalAttachment>().future;
    }
    final attached = await api.terminals.attachTerminal(terminalId);
    return TerminalAttachment(api: api, replay: attached.replay);
  }
}
