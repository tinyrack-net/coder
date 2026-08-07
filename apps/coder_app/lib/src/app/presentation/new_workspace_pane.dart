import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/app/composition/app_providers.dart';
import 'package:coder_app/src/features/agents/application/agent_definitions_controller.dart';
import 'package:coder_app/src/features/conversation/application/attachment_ports.dart';
import 'package:coder_app/src/features/conversation/application/composer_controller.dart';
import 'package:coder_app/src/features/conversation/domain/composer_commands.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_plan_actions.dart';
import 'package:coder_app/src/features/conversation/presentation/composer_client_commands.dart';
import 'package:coder_app/src/features/conversation/presentation/widgets/composer_completion_scope.dart';
import 'package:coder_app/src/features/conversation/presentation/widgets/composer_suggestions_overlay.dart';
import 'package:coder_app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/presentation/host_labels.dart';
import 'package:coder_app/src/features/providers/application/provider_settings_controller.dart';
import 'package:coder_app/src/features/providers/application/session_model_options.dart';
import 'package:coder_app/src/features/sessions/domain/session_title.dart';
import 'package:coder_app/src/features/workspace/application/directory_picker_port.dart';
import 'package:coder_app/src/features/workspace/application/workspace_controller.dart';
import 'package:coder_app/src/features/workspace/domain/branch_defaults.dart';
import 'package:coder_app/src/features/workspace/domain/branch_name.dart';
import 'package:coder_app/src/features/workspace/presentation/widgets/directory_browser.dart';
import 'package:coder_app/src/features/workspace/presentation/widgets/worktree_hook_report.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
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
      // The home workspace exists only to give project-less sessions a working
      // directory, so it is never one of the projects the user picks from.
      if (workspace.kind == WorkspaceKind.home) continue;
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
    final registryAsync = ref.watch(hostRegistryControllerProvider);
    final anyDaemonConnected =
        registryAsync.value?.runtimes.values.any((item) => item.connected) ??
        false;
    final catalogAsync = ref.watch(workspaceCatalogControllerProvider);
    final catalog = catalogAsync.value;
    final catalogLoading = catalogAsync.isLoading && !catalogAsync.hasValue;
    final projects = catalog == null
        ? const <NewWorkspaceProject>[]
        : collectProjects(AppLocalizations.of(context), catalog);
    // A null [_projectKey] means the user picked no project, which is the
    // starting state: the composer never adopts a project on its own.
    final project = projects
        .where((item) => item.key == _projectKey)
        .firstOrNull;
    // Without a project the session runs in the home folder of the daemon the
    // rest of the app is pointed at.
    final hostId = project?.hostId ?? ref.watch(activeHostIdProvider);
    final home = hostId == null ? null : catalog?.homeSelection(hostId);
    final isGitProject = project?.workspace.kind == WorkspaceKind.git;
    final showGitTargets = project != null && isGitProject;
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
    final agentsAsync = hostId == null
        ? null
        : ref.watch(agentDefinitionsControllerProvider(hostId));
    final agents = agentsAsync?.value;
    final agentsLoading =
        agentsAsync != null && agentsAsync.isLoading && !agentsAsync.hasValue;
    final definitions = selectableAgentDefinitions(
      agents?.definitions ?? const <AgentDefinitionDto>[],
    );
    final agent =
        definitions
            .where((item) => item.id == _draft(hostId)?.agentDefinitionId)
            .firstOrNull ??
        definitions.firstOrNull;
    final connectionsAsync = hostId == null
        ? null
        : ref.watch(providerSettingsControllerProvider(hostId));
    final connections = connectionsAsync?.value?.connections;
    final connectionsLoading =
        connectionsAsync != null &&
        connectionsAsync.isLoading &&
        !connectionsAsync.hasValue;
    final draft = _draft(hostId);
    final effective =
        draft?.model ??
        effectiveModelFor(
          definition: agent,
          connections: connections ?? const <ProviderConnectionDto>[],
          models:
              connectionsAsync?.value?.models ??
              const <String, List<ProviderModelDto>>{},
          defaultModel: connectionsAsync?.value?.defaultModel,
        );
    // A Git project can create the checkout on submit; every other target has
    // to already exist.
    final target = project == null
        ? home != null
        : isGitProject || worktree != null;
    final ready =
        hostId != null &&
        target &&
        agent != null &&
        effective != null &&
        !_submitting;
    void toggleMode() => _notifier(hostId)?.selectMode(
      draft?.mode == SessionMode.plan ? SessionMode.normal : SessionMode.plan,
    );
    // The completion is null only while no daemon is chosen, which is also the
    // state where the composer is disabled and has nothing to complete.
    Widget composer(ComposerCompletion? completion) => SessionComposer(
      enabled: ready,
      hint: _hint(
        AppLocalizations.of(context),
        projects,
        project,
        worktree,
        agent,
        effective,
        home: home,
        loading: catalogLoading || agentsLoading || connectionsLoading,
      ),
      header: _targets(
        projects: projects,
        project: project,
        home: home,
        worktree: worktree,
        branches: branches,
        showGitTargets: showGitTargets,
        baseBranch: baseBranch,
        anyDaemonConnected: anyDaemonConnected,
      ),
      bar: SessionComposerBar(
        hostId: hostId ?? '',
        definitions: definitions,
        agentDefinitionId: agent?.id,
        selection: effective,
        enabled: hostId != null && !_submitting,
        mode: draft?.mode ?? SessionMode.normal,
        onAgentChanged: (id) => _notifier(hostId)?.selectAgent(id),
        onModelChanged: (model, controls) {
          _notifier(hostId)?.selectModel(model);
          _notifier(hostId)?.selectModelControls(controls);
        },
        onModeChanged: (mode) => _notifier(hostId)?.selectMode(mode),
        modelControls:
            draft?.modelControls ?? const <String, ModelControlValueDto>{},
        onModelControlsChanged: (controls) =>
            _notifier(hostId)?.selectModelControls(controls),
        permissionMode: draft?.permissionMode,
        onPermissionModeChanged: (mode) =>
            _notifier(hostId)?.selectPermissionMode(mode),
      ),
      onModeToggled: hostId == null ? null : toggleMode,
      attachmentInput: ref.read(attachmentInputProvider),
      commands: completion?.commands ?? const <ComposerCommand>[],
      suggestions: completion?.suggestions ?? ComposerSuggestionsState.closed,
      onCompletionQueryChanged: completion?.onQueryChanged,
      onClientCommand: completion == null
          ? null
          : (invocation) => runSessionlessClientCommand(
              context,
              invocation,
              hostId: hostId!,
              onToggleMode: toggleMode,
            ),
      onSubmit: (submission) =>
          _submit(submission, project, home, worktree, agent!, draft!),
    );
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
                    child: TRText(
                      AppLocalizations.of(context).workspaceNewWorkspace,
                      variant: TRTextVariant.headingLg,
                    ),
                  ),
                  if (hostId == null)
                    composer(null)
                  else
                    ComposerCompletionScope(
                      hostId: hostId,
                      workspaceId: project?.workspace.id ?? home?.workspaceId,
                      // A Git project whose checkout is still to be created has
                      // no worktree to search, so it offers commands only.
                      worktreeId:
                          worktree?.id ??
                          (project == null ? home?.worktreeId : null),
                      excludedClientActions: sessionlessClientActions,
                      builder: (context, completion) => composer(completion),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  SessionComposerDraft? _draft(String? hostId) => hostId == null
      ? null
      : ref.watch(
          sessionComposerDraftControllerProvider(hostId, null, 'new-workspace'),
        );

  SessionComposerDraftController? _notifier(String? hostId) => hostId == null
      ? null
      : ref.read(
          sessionComposerDraftControllerProvider(
            hostId,
            null,
            'new-workspace',
          ).notifier,
        );

  String? _hint(
    AppLocalizations l10n,
    List<NewWorkspaceProject> projects,
    NewWorkspaceProject? project,
    WorktreeDto? worktree,
    AgentDefinitionDto? agent,
    SessionModelSelectionDto? model, {
    required WorkspaceSelection? home,
    required bool loading,
  }) {
    if (_error != null) return _error;
    if (loading) return null;
    if (project == null) {
      // A daemon configured without a user home publishes no home workspace,
      // so a project is the only thing left to start from.
      if (home != null) return null;
      return projects.isEmpty
          ? l10n.workspaceAddProjectFirst
          : l10n.workspaceSelectProject;
    }
    if (project.workspace.kind == WorkspaceKind.directory && worktree == null) {
      return l10n.workspaceCheckoutMissing;
    }
    if (agent == null) return '사용 가능한 primary Agent가 없습니다.';
    if (model == null) return '사용할 Provider와 모델을 먼저 선택하세요.';
    return null;
  }

  Widget _targets({
    required List<NewWorkspaceProject> projects,
    required NewWorkspaceProject? project,
    required WorkspaceSelection? home,
    required WorktreeDto? worktree,
    required List<GitBranchDto> branches,
    required bool showGitTargets,
    required String? baseBranch,
    required bool anyDaemonConnected,
  }) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: <Widget>[
        ComposerChip(
          valueKey: const ValueKey('new-workspace-project'),
          icon: CoderIcons.folder,
          // Without a home workspace the daemon cannot run a project-less
          // session, so the chip must not offer or advertise one.
          label:
              project?.workspace.name ??
              (home == null
                  ? '프로젝트'
                  : AppLocalizations.of(context).workspaceNoProjectOption),
          tooltip: '프로젝트 선택',
          menuChildren: _submitting || !anyDaemonConnected
              ? null
              : <Widget>[
                  if (home != null)
                    TRMenuItem(
                      key: const ValueKey('new-workspace-project-none'),
                      onPressed: () => _selectProject(null),
                      child: TRText.inherit(
                        AppLocalizations.of(context).workspaceNoProjectOption,
                      ),
                    ),
                  for (final item in projects)
                    TRMenuItem(
                      key: ValueKey('new-workspace-project-${item.key}'),
                      onPressed: () => _selectProject(item.key),
                      child: TRText.inherit(
                        '${item.workspace.name} · ${item.hostLabel}',
                      ),
                    ),
                  TRMenuItem(
                    key: const ValueKey('new-workspace-project-add'),
                    leadingIcon: const Icon(CoderIcons.addCircle),
                    onPressed: () => unawaited(_addProject()),
                    child: const TRText.inherit('추가'),
                  ),
                ],
        ),
        if (showGitTargets) ...<Widget>[
          const SizedBox(width: TRSpacing.small),
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
                      child: const TRText.inherit('New worktree'),
                    ),
                    for (final item in project.worktrees)
                      TRMenuItem(
                        key: ValueKey('new-workspace-worktree-${item.id}'),
                        onPressed: () => _selectWorktree(item.id),
                        child: TRText.inherit(item.branch ?? item.name),
                      ),
                  ],
          ),
          const SizedBox(width: TRSpacing.small),
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
                        child: TRText.inherit(branch.name),
                      ),
                    for (final branch in branches.where(
                      (branch) => !branch.isRemote,
                    ))
                      TRMenuItem(
                        key: ValueKey('new-workspace-branch-${branch.name}'),
                        onPressed: () => _selectBranch(branch.name),
                        child: TRText.inherit(branch.name),
                      ),
                  ],
          ),
        ],
      ],
    ),
  );

  /// Selects one project, or null to run the session in the home folder.
  void _selectProject(String? chosen) {
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
    NewWorkspaceProject? project,
    WorkspaceSelection? home,
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
      if (project == null) {
        // No project was picked, so the session runs in the home checkout the
        // daemon provisioned; there is no worktree to create.
        if (home == null) {
          setState(() {
            _error = AppLocalizations.of(context).workspaceDaemonRequired;
            _submitting = false;
          });
          return;
        }
        await _start(home, agent, draft, submission, seed);
        return;
      }
      var worktreeId = worktree?.id;
      if (worktreeId == null) {
        if (project.workspace.kind != WorkspaceKind.git) {
          setState(() {
            _error = AppLocalizations.of(context).workspaceCheckoutMissing;
            _submitting = false;
          });
          return;
        }
        final api = _hostApi(project.hostId);
        if (api == null) {
          setState(() {
            _error = AppLocalizations.of(context).workspaceDaemonRequired;
            _submitting = false;
          });
          return;
        }
        final created = await api.workspaces.createWorktree(
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
      await _start(
        WorkspaceSelection(
          hostId: project.hostId,
          workspaceId: project.workspace.id,
          worktreeId: worktreeId,
        ),
        agent,
        draft,
        submission,
        seed,
      );
    } on CoderClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _submitting = false;
      });
    }
  }

  /// Creates the session on [selection] and hands it to the caller.
  Future<void> _start(
    WorkspaceSelection selection,
    AgentDefinitionDto agent,
    SessionComposerDraft draft,
    ComposerSubmission submission,
    String seed,
  ) async {
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
