import 'dart:async';

import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skills_controller.g.dart';

@riverpod
/// Loads and edits the skills one daemon offers, optionally for one project.
///
/// A null [SkillsController.workspaceId] shows only the built-in, user-home,
/// and daemon-config sources; naming a workspace layers its
/// `.agents/skills` on top.
class SkillsController extends _$SkillsController {
  StreamSubscription<void>? _events;

  @override
  Future<List<SkillDto>> build(String hostId, String? workspaceId) async {
    final api = await watchHostApi(ref, hostId);
    _events = api.prompts.skillChanges.listen((_) => unawaited(refresh()));
    ref.onDispose(() => unawaited(_events?.cancel()));
    return api.prompts.listSkills(workspaceId: workspaceId);
  }

  /// Reloads the catalog from the daemon.
  Future<void> refresh() async {
    final api = await requireHostApi(ref, hostId);
    final skills = await api.prompts.listSkills(workspaceId: workspaceId);
    if (!ref.mounted) return;
    state = AsyncData<List<SkillDto>>(skills);
  }

  /// Creates one skill in a writable source.
  Future<SkillDto> create({
    required String id,
    required SkillSource source,
    required String name,
    required String description,
    required String body,
  }) async {
    final api = await requireHostApi(ref, hostId);
    final created = await api.prompts.createSkill(
      id: id,
      source: source,
      name: name,
      description: description,
      body: body,
      workspaceId: workspaceId,
    );
    await refresh();
    return created;
  }

  /// Saves an edit, rejecting external-file races by default.
  Future<SkillDto> save(
    SkillDto skill, {
    required String expectedContentHash,
    bool force = false,
  }) async {
    final api = await requireHostApi(ref, hostId);
    final updated = await api.prompts.updateSkill(
      skill,
      expectedContentHash: expectedContentHash,
      force: force,
      workspaceId: workspaceId,
    );
    await refresh();
    return updated;
  }

  /// Archives one editable skill.
  Future<void> delete(String id) async {
    final api = await requireHostApi(ref, hostId);
    await api.prompts.deleteSkill(id, workspaceId: workspaceId);
    await refresh();
  }

  /// Turns one skill on or off.
  Future<SkillDto> setEnabled(String id, {required bool enabled}) async {
    final api = await requireHostApi(ref, hostId);
    final updated = await api.prompts.setSkillEnabled(
      id,
      enabled: enabled,
      workspaceId: workspaceId,
    );
    await refresh();
    return updated;
  }
}
