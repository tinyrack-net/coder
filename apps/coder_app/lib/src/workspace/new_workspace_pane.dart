import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/attachment_ports.dart';
import 'package:coder_app/src/branch_defaults.dart';
import 'package:coder_app/src/branch_name.dart';
import 'package:coder_app/src/chat/chat_plan_actions.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_labels.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/session_composer.dart';
import 'package:coder_app/src/session_model_options.dart';
import 'package:coder_app/src/session_title.dart';
import 'package:coder_app/src/workspace/directory_browser.dart';
import 'package:coder_app/src/workspace/directory_picker_port.dart';
import 'package:coder_app/src/workspace/worktree_hook_report.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// One registered repository together with the daemon that owns it.
final class NewWorkspaceProject {
  /// Creates a selectable project.
  const NewWorkspaceProject({
    required this.hostId,
    required this.hostLabel,
    required this.workspace,
    required this.worktrees,
  });

  /// Daemon profile owning [workspace].
  final String hostId;

  /// User-visible daemon name.
  final String hostLabel;

  /// The registered repository.
  final WorkspaceDto workspace;

  /// Checkouts belonging to [workspace].
  final List<WorktreeDto> worktrees;

  /// Stable identity used by menu keys and selection.
  String get key => '$hostId\u0000${workspace.id}';
}

/// Flattens every online daemon catalog into selectable projects.
///
/// Takes [l10n] because the app owns the embedded daemon's name, and projects
/// are ordered by the name the user actually sees.
List<NewWorkspaceProject> collectProjects(
  AppLocalizations l10n,
  UnifiedWorkspaceCatalogState state,
) {
  final projects = <NewWorkspaceProject>[];
  for (final entry in state.catalogs.entries) {
    final host = state.hosts[entry.key];
    final label = host == null ? entry.key : hostLabel(l10n, host);
    for (final workspace in entry.value.workspaces) {
      projects.add(
        NewWorkspaceProject(
          hostId: entry.key,
          hostLabel: label,
          workspace: workspace,
          worktrees: entry.value.worktrees
              .where((item) => item.workspaceId == workspace.id)
              .toList(growable: false),
        ),
      );
    }
  }
  projects.sort((left, right) {
    final byHost = left.hostLabel.compareTo(right.hostLabel);
    return byHost != 0
        ? byHost
        : left.workspace.name.compareTo(right.workspace.name);
  });
  return List<NewWorkspaceProject>.unmodifiable(projects);
}

/// Centered composer that starts a session on a new or existing worktree.
class NewWorkspacePane extends ConsumerStatefulWidget {
  /// Creates the new-workspace composer.
  const NewWorkspacePane({
    required this.onStarted,
    this.showBack = false,
    this.onBack,
    super.key,
  });

  /// Called with the selection and session created by the first prompt.
  final void Function(WorkspaceSelection selection, SessionDto session)
  onStarted;

  /// Whether the mobile back affordance is shown.
  final bool showBack;

  /// Invoked by the mobile back affordance.
  final VoidCallback? onBack;

  @override
  ConsumerState<NewWorkspacePane> createState() => _NewWorkspacePaneState();
}

class _NewWorkspacePaneState extends ConsumerState<NewWorkspacePane> {
  String? _projectKey;
  String? _worktreeId;
  String? _baseBranch;
  bool _submitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    // `valueOrNull` keeps the last catalog while the provider refreshes, so a
    // host-registry change never flashes the empty state.
    final catalog = ref.watch(workspaceCatalogControllerProvider).value;
    final projects = catalog == null
        ? const <NewWorkspaceProject>[]
        : collectProjects(AppLocalizations.of(context), catalog);
    final project =
        projects.where((item) => item.key == _projectKey).firstOrNull ??
        projects.firstOrNull;
    final isGitProject = project?.workspace.kind == WorkspaceKind.git;
    final showGitTargets = project == null || isGitProject;
    final branches = project == null || !isGitProject
        ? const <GitBranchDto>[]
        : ref
                  .watch(
                    gitBranchesProvider(project.hostId, project.workspace.id),
                  )
                  .value ??
              const <GitBranchDto>[];
    // Remote refs win by default so a new branch starts from the latest push.
    final baseBranch = _baseBranch ?? defaultBaseBranch(branches);
    final worktree = project == null
        ? null
        : isGitProject
        ? project.worktrees.where((item) => item.id == _worktreeId).firstOrNull
        : _directoryCheckout(project);
    final agents = project == null
        ? null
        : ref.watch(agentDefinitionsControllerProvider(project.hostId)).value;
    final definitions = selectableAgentDefinitions(
      agents?.definitions ?? const <AgentDefinitionDto>[],
    );
    final agent =
        definitions
            .where((item) => item.id == _draft(project)?.agentDefinitionId)
            .firstOrNull ??
        definitions.firstOrNull;
    final connections = project == null
        ? null
        : ref
              .watch(providerSettingsControllerProvider(project.hostId))
              .value
              ?.connections;
    final draft = _draft(project);
    final effective =
        draft?.model ??
        (agent == null
            ? null
            : agentSelectionFor(
                agent,
                connections ?? const <ProviderConnectionDto>[],
              ));
    final ready =
        project != null &&
        (isGitProject || worktree != null) &&
        agent != null &&
        effective != null &&
        !_submitting;
    return Column(
      children: <Widget>[
        if (widget.showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: TRIconButton(
              appearance: TRAppearance.ghost,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: widget.onBack,
              icon: const Icon(CoderIcons.back),
            ),
          ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 4),
                    child: Text(
                      AppLocalizations.of(context).workspaceNewWorkspace,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  SessionComposer(
                    enabled: ready,
                    hint: _hint(projects, project, worktree, agent, effective),
                    header: _targets(
                      projects: projects,
                      project: project,
                      worktree: worktree,
                      branches: branches,
                      showGitTargets: showGitTargets,
                      baseBranch: baseBranch,
                    ),
                    bar: SessionComposerBar(
                      hostId: project?.hostId ?? '',
                      definitions: definitions,
                      agentDefinitionId: agent?.id,
                      selection: effective,
                      enabled: project != null && !_submitting,
                      mode: draft?.mode ?? SessionMode.normal,
                      onAgentChanged: (id) =>
                          _notifier(project)?.selectAgent(id),
                      onModelChanged: (model) =>
                          _notifier(project)?.selectModel(model),
                      onModeChanged: (mode) => _notifier(project)?.selectMode(
                        mode,
                      ),
                      reasoningEffort: draft?.reasoningEffort,
                      onReasoningEffortChanged: (effort) =>
                          _notifier(project)?.selectReasoningEffort(effort),
                      permissionMode: draft?.permissionMode,
                      onPermissionModeChanged: (mode) =>
                          _notifier(project)?.selectPermissionMode(mode),
                      serviceTier: draft?.serviceTier,
                      onServiceTierChanged: (tier) =>
                          _notifier(project)?.selectServiceTier(tier),
                    ),
                    onModeToggled: project == null
                        ? null
                        : () => _notifier(project)?.selectMode(
                            draft?.mode == SessionMode.plan
                                ? SessionMode.normal
                                : SessionMode.plan,
                          ),
                    attachmentInput: ref.read(attachmentInputProvider),
                    onSubmit: (submission) =>
                        _submit(submission, project!, worktree, agent!, draft!),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  SessionComposerDraft? _draft(NewWorkspaceProject? project) => project == null
      ? null
      : ref.watch(sessionComposerDraftControllerProvider(project.hostId, null));

  SessionComposerDraftController? _notifier(NewWorkspaceProject? project) =>
      project == null
      ? null
      : ref.read(
          sessionComposerDraftControllerProvider(project.hostId, null).notifier,
        );

  String? _hint(
    List<NewWorkspaceProject> projects,
    NewWorkspaceProject? project,
    WorktreeDto? worktree,
    AgentDefinitionDto? agent,
    SessionModelSelectionDto? model,
  ) {
    if (_error != null) return _error;
    if (projects.isEmpty) return '먼저 프로젝트를 추가하세요.';
    if (project == null) return '프로젝트를 선택하세요.';
    if (project.workspace.kind == WorkspaceKind.directory && worktree == null) {
      return '프로젝트 checkout을 찾을 수 없습니다.';
    }
    if (agent == null) return '사용 가능한 primary Agent가 없습니다.';
    if (model == null) return '사용할 Provider와 모델을 먼저 선택하세요.';
    return null;
  }

  Widget _targets({
    required List<NewWorkspaceProject> projects,
    required NewWorkspaceProject? project,
    required WorktreeDto? worktree,
    required List<GitBranchDto> branches,
    required bool showGitTargets,
    required String? baseBranch,
  }) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: <Widget>[
        ComposerChip(
          valueKey: const ValueKey('new-workspace-project'),
          icon: CoderIcons.folder,
          label: project?.workspace.name ?? '프로젝트',
          tooltip: '프로젝트 선택',
          menuChildren: _submitting
              ? null
              : <Widget>[
                  for (final item in projects)
                    TRMenuItem(
                      key: ValueKey('new-workspace-project-${item.key}'),
                      onPressed: () => _selectProject(item.key),
                      child: Text('${item.workspace.name} · ${item.hostLabel}'),
                    ),
                  TRMenuItem(
                    key: const ValueKey('new-workspace-project-add'),
                    leadingIcon: const Icon(CoderIcons.addCircle),
                    onPressed: () => unawaited(_addProject()),
                    child: const Text('추가'),
                  ),
                ],
        ),
        if (showGitTargets) ...<Widget>[
          const SizedBox(width: 8),
          ComposerChip(
            valueKey: const ValueKey('new-workspace-worktree'),
            icon: CoderIcons.branch,
            label: worktree == null
                ? 'New worktree'
                : (worktree.branch ?? worktree.name),
            tooltip: 'Worktree 선택',
            menuChildren: project == null || _submitting
                ? null
                : <Widget>[
                    TRMenuItem(
                      key: const ValueKey('new-workspace-worktree-new'),
                      onPressed: () => _selectWorktree(null),
                      child: const Text('New worktree'),
                    ),
                    for (final item in project.worktrees)
                      TRMenuItem(
                        key: ValueKey('new-workspace-worktree-${item.id}'),
                        onPressed: () => _selectWorktree(item.id),
                        child: Text(item.branch ?? item.name),
                      ),
                  ],
          ),
          const SizedBox(width: 8),
          ComposerChip(
            valueKey: const ValueKey('new-workspace-branch'),
            icon: CoderIcons.check,
            label: baseBranch ?? '기반 branch',
            tooltip: '기반 branch 선택',
            menuChildren: project == null || worktree != null || _submitting
                ? null
                : <Widget>[
                    for (final branch in branches.where(
                      (branch) => branch.isRemote,
                    ))
                      TRMenuItem(
                        key: ValueKey('new-workspace-branch-${branch.name}'),
                        onPressed: () => _selectBranch(branch.name),
                        child: Text(branch.name),
                      ),
                    for (final branch in branches.where(
                      (branch) => !branch.isRemote,
                    ))
                      TRMenuItem(
                        key: ValueKey('new-workspace-branch-${branch.name}'),
                        onPressed: () => _selectBranch(branch.name),
                        child: Text(branch.name),
                      ),
                  ],
          ),
        ],
      ],
    ),
  );

  void _selectProject(String chosen) {
    setState(() {
      _projectKey = chosen;
      _worktreeId = null;
      _baseBranch = null;
      _error = null;
    });
  }

  void _selectWorktree(String? chosen) {
    setState(() {
      _worktreeId = chosen;
      _error = null;
    });
  }

  void _selectBranch(String chosen) {
    setState(() => _baseBranch = chosen);
  }

  Future<void> _addProject() async {
    final registry = ref.read(hostRegistryControllerProvider).value;
    final online =
        registry?.runtimes.values
            .where((item) => item.connected)
            .toList(growable: false) ??
        const <HostRuntimeSnapshot>[];
    final hostId = await pickDaemonHost(context, online);
    if (hostId == null || !mounted) return;
    final host = online.singleWhere((item) => item.id == hostId);
    // Repositories almost always live under the home of the machine that owns
    // them, so both pickers start there. A daemon configured without a home
    // reports none, leaving the root as the only path known to exist there.
    final home = host.serverInfo?.homeDirectory;
    final picker = ref.read(directoryPickerProvider);
    // The embedded daemon shares this filesystem, so the operating system's
    // own chooser browses exactly the paths it can register.
    final path = host.kind == HostKind.embedded && picker != null
        ? await picker.pickDirectory(initialDirectory: home)
        : await showDirectoryBrowser(
            context,
            api: host.api!,
            initialPath: home ?? '/',
          );
    if (path == null || path.isEmpty || !mounted) return;
    try {
      final result = await ref
          .read(workspaceCatalogControllerProvider.notifier)
          .register(hostId, path);
      if (!mounted) return;
      setState(() {
        _projectKey = '$hostId\u0000${result.workspace.id}';
        _worktreeId = null;
        _baseBranch = null;
        _error = null;
      });
    } on CoderClientException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  Future<void> _submit(
    ComposerSubmission submission,
    NewWorkspaceProject project,
    WorktreeDto? worktree,
    AgentDefinitionDto agent,
    SessionComposerDraft draft,
  ) async {
    final seed = submission.text.isEmpty
        ? submission.attachments.first.fileName
        : submission.text;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      var worktreeId = worktree?.id;
      if (worktreeId == null) {
        if (project.workspace.kind != WorkspaceKind.git) {
          setState(() {
            _error = '프로젝트 checkout을 찾을 수 없습니다.';
            _submitting = false;
          });
          return;
        }
        final api = _hostApi(project.hostId);
        if (api == null) {
          setState(() {
            _error = 'Daemon 연결이 필요합니다.';
            _submitting = false;
          });
          return;
        }
        final created = await api.createWorktree(
          id: ref.read(appIdGeneratorProvider).generate(),
          workspaceId: project.workspace.id,
          mode: WorktreeCreateMode.newBranch,
          branchName: deriveWorktreeBranchName(
            seed,
            existingBranchNames: project.worktrees.map(
              (item) => item.branch ?? item.name,
            ),
          ),
          baseBranch: _baseBranch ?? defaultBaseBranch(_branches(project)),
        );
        // The routed pages read the catalog, so refresh before navigating.
        await ref
            .read(workspaceCatalogControllerProvider.notifier)
            .refreshHost(project.hostId);
        // The daemon removes a checkout whose setup failed. Surface the exact
        // hook output and keep the submission available for a corrected retry.
        if (failedWorktreeHook(created.hookRuns) != null) {
          if (mounted) {
            reportWorktreeHookFailure(context, created.hookRuns);
            setState(() => _submitting = false);
          }
          return;
        }
        worktreeId = created.worktree.id;
      }
      final selection = WorkspaceSelection(
        hostId: project.hostId,
        workspaceId: project.workspace.id,
        worktreeId: worktreeId,
      );
      final session = await startSessionWithPrompt(
        ref,
        selection: selection,
        agentDefinitionId: agent.id,
        title: deriveSessionTitle(seed),
        prompt: submission.text,
        attachments: submission.attachments,
        mode: draft.mode,
        model: draft.model,
      );
      if (!mounted) return;
      widget.onStarted(selection, session);
    } on CoderClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _submitting = false;
      });
    }
  }

  List<GitBranchDto> _branches(NewWorkspaceProject project) =>
      ref
          .read(gitBranchesProvider(project.hostId, project.workspace.id))
          .value ??
      const <GitBranchDto>[];

  WorktreeDto? _directoryCheckout(NewWorkspaceProject project) {
    final checkouts = project.worktrees
        .where((item) => item.kind == WorktreeKind.directory)
        .toList(growable: false);
    return checkouts.length == 1 ? checkouts.single : null;
  }

  CoderApi? _hostApi(String hostId) {
    final runtime = ref
        .read(hostRegistryControllerProvider)
        .value
        ?.runtimes[hostId];
    return runtime?.connected == true ? runtime!.api : null;
  }
}
