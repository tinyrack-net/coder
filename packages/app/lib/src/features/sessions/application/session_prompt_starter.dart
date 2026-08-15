import 'package:app/src/features/conversation/application/attachment_ports.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/sessions/application/session_starter.dart';
import 'package:protocol/protocol.dart';

/// Creates a session, opens its tab, and starts its first turn.
///
/// Harness-specific hand-off actions are plugin-owned in v5. This
/// transport-neutral helper remains shared by the draft and new-workspace
/// composers.
Future<SessionDto> startSessionWithPrompt(
  SessionStarter starter, {
  required WorkspaceSelection selection,
  required String agentDefinitionId,
  required String title,
  required String prompt,
  String? draftTabId,
  List<PendingAttachment> attachments = const <PendingAttachment>[],
  ModelSelectionDto? model,
  Map<String, ModelControlValueDto> modelControls =
      const <String, ModelControlValueDto>{},
  PermissionMode? permissionMode,
}) => starter.start(
  selection: selection,
  agentDefinitionId: agentDefinitionId,
  title: title,
  prompt: prompt,
  draftTabId: draftTabId,
  attachments: attachments,
  model: model,
  modelControls: modelControls,
  permissionMode: permissionMode,
);
