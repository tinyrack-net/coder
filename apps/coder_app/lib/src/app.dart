import 'dart:convert';

import 'package:coder_app/src/bootstrap.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/external_url_opener.dart';
import 'package:coder_app/src/settings_page.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'app.g.dart';

/// CoderApp defines a public contract.
class CoderApp extends StatelessWidget {
  /// Creates a [CoderApp].
  CoderApp({
    required this.bootstrap,
    this.externalUrlOpener = const PlatformExternalUrlOpener(),
    super.key,
  });

  /// The bootstrap public API member.
  final AppBootstrap bootstrap;

  /// Platform adapter used to open interactive authorization pages.
  final ExternalUrlOpener externalUrlOpener;

  late final GoRouter _router = GoRouter(routes: $appRoutes);

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      bootstrapProvider.overrideWithValue(bootstrap),
      externalUrlOpenerProvider.overrideWithValue(externalUrlOpener),
    ],
    child: MaterialApp.router(
      title: 'Tinyrack Coder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff625bff),
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff948dff),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      ),
      routerConfig: _router,
    ),
  );
}

@TypedGoRoute<HostRoute>(path: '/')
/// HostRoute defines a public contract.
class HostRoute extends GoRouteData with $HostRoute {
  /// Creates a [HostRoute].
  const HostRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HostPage();
}

@TypedGoRoute<DashboardRoute>(path: '/hosts/:hostId')
/// DashboardRoute defines a public contract.
class DashboardRoute extends GoRouteData with $DashboardRoute {
  /// Creates a [DashboardRoute].
  const DashboardRoute({required this.hostId});

  /// The hostId public API member.
  final String hostId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DashboardPage(hostId: hostId);
}

@TypedGoRoute<SettingsRoute>(path: '/hosts/:hostId/settings')
/// SettingsRoute defines a public contract.
class SettingsRoute extends GoRouteData with $SettingsRoute {
  /// Creates a [SettingsRoute].
  const SettingsRoute({required this.hostId});

  /// The hostId public API member.
  final String hostId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SettingsPage(hostId: hostId);
}

@TypedGoRoute<WorkspaceRoute>(
  path: '/hosts/:hostId/workspaces/:workspaceId',
)
/// WorkspaceRoute defines a public contract.
class WorkspaceRoute extends GoRouteData with $WorkspaceRoute {
  /// Creates a [WorkspaceRoute].
  const WorkspaceRoute({required this.hostId, required this.workspaceId});

  /// The hostId public API member.
  final String hostId;

  /// The workspaceId public API member.
  final String workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DashboardPage(hostId: hostId, workspaceId: workspaceId);
}

@TypedGoRoute<AgentRoute>(
  path: '/hosts/:hostId/workspaces/:workspaceId/agents/:agentId',
)
/// AgentRoute defines a public contract.
class AgentRoute extends GoRouteData with $AgentRoute {
  /// Creates a [AgentRoute].
  const AgentRoute({
    required this.hostId,
    required this.workspaceId,
    required this.agentId,
  });

  /// The hostId public API member.
  final String hostId;

  /// The workspaceId public API member.
  final String workspaceId;

  /// The agentId public API member.
  final String agentId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DashboardPage(hostId: hostId, workspaceId: workspaceId, agentId: agentId);
}

/// HostPage defines a public contract.
class HostPage extends ConsumerStatefulWidget {
  /// Creates a [HostPage].
  const HostPage({super.key});

  @override
  ConsumerState<HostPage> createState() => _HostPageState();
}

class _HostPageState extends ConsumerState<HostPage> {
  final _address = TextEditingController(text: 'ws://127.0.0.1:7337/ws');
  final _token = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _address.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectionControllerProvider, (previous, next) {
      final current = next.asData?.value;
      final wasConnected = previous?.asData?.value?.connected == true;
      if (current?.connected == true && !wasConnected) {
        DashboardRoute(hostId: current!.serverInfo.serverId).go(context);
      }
    });
    final state = ref.watch(connectionControllerProvider);
    final connection = state.asData?.value;
    final connecting = state.isLoading || connection?.connecting == true;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Tinyrack Coder',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  ref.read(bootstrapProvider).canRegisterLocalWorkspace
                      ? '로컬 daemon을 시작하거나 원격 host에 연결합니다.'
                      : '모바일은 원격 daemon에만 연결합니다.',
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _address,
                  decoration: const InputDecoration(
                    labelText: 'Daemon WebSocket 주소',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _token,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Bearer token'),
                ),
                if (state.hasError) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    '${state.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: connecting
                      ? null
                      : () => ref
                            .read(connectionControllerProvider.notifier)
                            .connect(_address.text, _token.text),
                  icon: connecting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lan),
                  label: Text(connecting ? '연결 중…' : '연결'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// DashboardPage defines a public contract.
class DashboardPage extends ConsumerWidget {
  /// Creates a [DashboardPage].
  const DashboardPage({
    required this.hostId,
    this.workspaceId,
    this.agentId,
    super.key,
  });

  /// The hostId public API member.
  final String hostId;

  /// The workspaceId public API member.
  final String? workspaceId;

  /// The agentId public API member.
  final String? agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionControllerProvider).asData?.value;
    if (connection?.connected != true) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => const HostRoute().go(context),
            child: const Text('Host 연결로 돌아가기'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tinyrack Coder'),
        actions: <Widget>[
          IconButton(
            tooltip: '설정',
            onPressed: () => SettingsRoute(hostId: hostId).go(context),
            icon: const Icon(Icons.settings_outlined),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text(connection?.label ?? 'connected')),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1000) {
            return Row(
              children: <Widget>[
                SizedBox(
                  width: 270,
                  child: _WorkspacePane(
                    hostId: hostId,
                    selectedWorkspaceId: workspaceId,
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 280,
                  child: _AgentPane(
                    hostId: hostId,
                    workspaceId: workspaceId,
                    selectedAgentId: agentId,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _ConversationPane(
                    workspaceId: workspaceId,
                    agentId: agentId,
                  ),
                ),
              ],
            );
          }
          if (agentId != null) {
            return _ConversationPane(
              workspaceId: workspaceId,
              agentId: agentId,
            );
          }
          if (workspaceId != null) {
            return _AgentPane(
              hostId: hostId,
              workspaceId: workspaceId,
              selectedAgentId: agentId,
            );
          }
          return _WorkspacePane(
            hostId: hostId,
            selectedWorkspaceId: workspaceId,
          );
        },
      ),
    );
  }
}

class _WorkspacePane extends ConsumerWidget {
  const _WorkspacePane({
    required this.hostId,
    required this.selectedWorkspaceId,
  });

  final String hostId;
  final String? selectedWorkspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspacesControllerProvider);
    final controller = ref.read(workspacesControllerProvider.notifier);
    final canRegister = ref
        .read(connectionControllerProvider.notifier)
        .canRegisterLocalWorkspace;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListTile(
          title: const Text('Workspaces'),
          trailing: canRegister
              ? IconButton(
                  tooltip: '로컬 workspace 등록',
                  onPressed: () async {
                    final path = await getDirectoryPath(
                      confirmButtonText: 'Workspace 선택',
                    );
                    if (path == null || !context.mounted) return;
                    final workspace = await controller.register(path);
                    if (context.mounted) {
                      WorkspaceRoute(
                        hostId: hostId,
                        workspaceId: workspace.id,
                      ).go(context);
                    }
                  },
                  icon: const Icon(Icons.create_new_folder_outlined),
                )
              : null,
        ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('$error')),
            data: (workspaces) => workspaces.isEmpty
                ? const Center(child: Text('등록된 workspace가 없습니다.'))
                : ListView.builder(
                    itemCount: workspaces.length,
                    itemBuilder: (context, index) {
                      final item = workspaces[index];
                      return ListTile(
                        selected: item.id == selectedWorkspaceId,
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(item.name),
                        subtitle: Text(
                          item.rootPath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => WorkspaceRoute(
                          hostId: hostId,
                          workspaceId: item.id,
                        ).go(context),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _AgentPane extends ConsumerWidget {
  const _AgentPane({
    required this.hostId,
    required this.workspaceId,
    required this.selectedAgentId,
  });

  final String hostId;
  final String? workspaceId;
  final String? selectedAgentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentsControllerProvider(workspaceId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListTile(
          leading: MediaQuery.sizeOf(context).width < 1000
              ? IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
          title: const Text('Agents'),
          trailing: workspaceId == null
              ? null
              : IconButton(
                  tooltip: 'Agent 생성',
                  onPressed: () => _createAgent(context, ref, workspaceId!),
                  icon: const Icon(Icons.add),
                ),
        ),
        Expanded(
          child: workspaceId == null
              ? const Center(child: Text('Workspace를 선택하세요.'))
              : state.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(child: Text('$error')),
                  data: (agents) => agents.isEmpty
                      ? const Center(child: Text('새 agent를 만들어 시작하세요.'))
                      : ListView.builder(
                          itemCount: agents.length,
                          itemBuilder: (context, index) {
                            final agent = agents[index];
                            return ListTile(
                              selected: agent.id == selectedAgentId,
                              leading: Icon(_agentIcon(agent.status)),
                              title: Text(agent.title),
                              subtitle: Text(
                                '${agent.model} · ${agent.status.name}',
                              ),
                              onTap: () => AgentRoute(
                                hostId: hostId,
                                workspaceId: workspaceId!,
                                agentId: agent.id,
                              ).go(context),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  IconData _agentIcon(AgentStatus status) => switch (status) {
    AgentStatus.running => Icons.sync,
    AgentStatus.waitingForApproval => Icons.approval_outlined,
    AgentStatus.failed => Icons.error_outline,
    _ => Icons.smart_toy_outlined,
  };

  Future<void> _createAgent(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final controller = ref.read(agentsControllerProvider(workspaceId).notifier);
    final providerController = ref.read(
      providerSettingsControllerProvider.notifier,
    );
    final providerState = await ref.read(
      providerSettingsControllerProvider.future,
    );
    final connections = providerState?.connections
        .where(
          (connection) =>
              connection.status == ProviderConnectionStatus.connected ||
              connection.status == ProviderConnectionStatus.degraded,
        )
        .toList(growable: false);
    if (connections == null || connections.isEmpty) return;
    var connectionId = connections
        .where((connection) => connection.isDefault)
        .firstOrNull
        ?.id;
    connectionId ??= connections.first.id;
    await providerController.loadModels(connectionId);
    if (!context.mounted) return;
    final availableModels =
        ref
            .read(providerSettingsControllerProvider)
            .asData
            ?.value
            ?.models[connectionId] ??
        const <ProviderModelDto>[];
    final draft = await showDialog<_AgentDraft>(
      context: context,
      builder: (context) => _AgentDraftDialog(
        connections: connections,
        connectionId: connectionId!,
        models: availableModels,
        loadModels: (value) async {
          await providerController.loadModels(value);
          return ref
                  .read(providerSettingsControllerProvider)
                  .asData
                  ?.value
                  ?.models[value] ??
              const <ProviderModelDto>[];
        },
      ),
    );
    if (draft == null || !context.mounted) return;
    final agent = await controller.create(
      title: draft.title,
      providerConnectionId: draft.providerConnectionId,
      model: draft.model,
      reasoningEffort: draft.reasoningEffort,
      permissionMode: draft.permissionMode,
    );
    if (context.mounted) {
      AgentRoute(
        hostId: hostId,
        workspaceId: workspaceId,
        agentId: agent.id,
      ).go(context);
    }
  }
}

typedef _ModelLoader =
    Future<List<ProviderModelDto>> Function(
      String connectionId,
    );

final class _AgentDraft {
  const _AgentDraft({
    required this.title,
    required this.providerConnectionId,
    required this.model,
    required this.reasoningEffort,
    required this.permissionMode,
  });

  final String title;
  final String providerConnectionId;
  final String model;
  final String reasoningEffort;
  final PermissionMode permissionMode;
}

class _AgentDraftDialog extends StatefulWidget {
  const _AgentDraftDialog({
    required this.connections,
    required this.connectionId,
    required this.models,
    required this.loadModels,
  });

  final List<ProviderConnectionDto> connections;
  final String connectionId;
  final List<ProviderModelDto> models;
  final _ModelLoader loadModels;

  @override
  State<_AgentDraftDialog> createState() => _AgentDraftDialogState();
}

class _AgentDraftDialogState extends State<_AgentDraftDialog> {
  late final TextEditingController _title;
  late final TextEditingController _model;
  late String _connectionId;
  late List<ProviderModelDto> _models;
  PermissionMode _permission = PermissionMode.ask;
  var _reasoningEffort = 'medium';

  @override
  void initState() {
    super.initState();
    _connectionId = widget.connectionId;
    _models = widget.models;
    _title = TextEditingController(text: 'Coding session');
    _model = TextEditingController(
      text:
          widget.connections
              .where((item) => item.id == _connectionId)
              .firstOrNull
              ?.defaultModelId ??
          '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('새 agent'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: '이름'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _connectionId,
          decoration: const InputDecoration(labelText: 'API provider'),
          items: widget.connections
              .map(
                (value) => DropdownMenuItem(
                  value: value.id,
                  child: Text(value.displayName),
                ),
              )
              .toList(),
          onChanged: _selectProvider,
        ),
        const SizedBox(height: 12),
        DropdownMenu<String>(
          controller: _model,
          enableFilter: true,
          expandedInsets: EdgeInsets.zero,
          label: const Text('Model ID'),
          dropdownMenuEntries: _models
              .map(
                (item) => DropdownMenuEntry(value: item.id, label: item.label),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _reasoningEffort,
          decoration: const InputDecoration(labelText: 'Reasoning effort'),
          items: const <String>['none', 'low', 'medium', 'high', 'xhigh']
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) =>
              setState(() => _reasoningEffort = value ?? _reasoningEffort),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PermissionMode>(
          initialValue: _permission,
          decoration: const InputDecoration(labelText: 'Permission mode'),
          items: PermissionMode.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value.name),
                ),
              )
              .toList(),
          onChanged: (value) =>
              setState(() => _permission = value ?? PermissionMode.ask),
        ),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(onPressed: _submit, child: const Text('생성')),
    ],
  );

  Future<void> _selectProvider(String? value) async {
    if (value == null) return;
    final models = await widget.loadModels(value);
    if (!mounted) return;
    final provider = widget.connections
        .where((item) => item.id == value)
        .firstOrNull;
    setState(() {
      _connectionId = value;
      _models = models;
      _model.text = provider?.defaultModelId ?? '';
    });
  }

  void _submit() {
    final model = _model.text.trim();
    if (model.isEmpty) return;
    final title = _title.text.trim();
    Navigator.pop(
      context,
      _AgentDraft(
        title: title.isEmpty ? 'Coding session' : title,
        providerConnectionId: _connectionId,
        model: model,
        reasoningEffort: _reasoningEffort,
        permissionMode: _permission,
      ),
    );
  }
}

class _ConversationPane extends ConsumerStatefulWidget {
  const _ConversationPane({required this.workspaceId, required this.agentId});

  final String? workspaceId;
  final String? agentId;

  @override
  ConsumerState<_ConversationPane> createState() => _ConversationPaneState();
}

class _ConversationPaneState extends ConsumerState<_ConversationPane> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agents = ref
        .watch(agentsControllerProvider(widget.workspaceId))
        .asData
        ?.value;
    final selected = (agents ?? const <AgentDto>[])
        .where((item) => item.id == widget.agentId)
        .firstOrNull;
    if (widget.agentId == null || selected == null) {
      return const Center(child: Text('Agent를 선택하세요.'));
    }
    final busy =
        selected.status == AgentStatus.running ||
        selected.status == AgentStatus.waitingForApproval;
    final conversation = ref.watch(
      conversationControllerProvider(widget.agentId),
    );
    final conversationState = conversation.asData?.value;
    final displayTimeline = _coalesceAssistantDeltas(
      conversationState?.timeline ?? const <TimelineEventDto>[],
    );
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(selected.title),
          subtitle: Text(
            '${selected.providerConnectionId}/${selected.model} · '
            '${selected.reasoningEffort} · ${selected.permissionMode.name}',
          ),
          trailing: busy
              ? TextButton.icon(
                  onPressed: () => ref
                      .read(
                        conversationControllerProvider(widget.agentId).notifier,
                      )
                      .cancelTurn(),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('중지'),
                )
              : displayTimeline.isEmpty
              ? IconButton(
                  tooltip: 'Agent 모델 설정',
                  onPressed: () => _editAgentConfiguration(selected),
                  icon: const Icon(Icons.tune),
                )
              : null,
        ),
        const Divider(height: 1),
        Expanded(
          child: displayTimeline.isEmpty
              ? const Center(child: Text('요청을 입력해 coding agent를 시작하세요.'))
              : ListView.separated(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: displayTimeline.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final event =
                        displayTimeline[displayTimeline.length - index - 1];
                    return TimelineCard(event: event);
                  },
                ),
        ),
        for (final approval
            in conversationState?.approvals.values ??
                const <ApprovalRequestDto>[])
          ApprovalCard(approval: approval),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _composer,
                    minLines: 1,
                    maxLines: 8,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      hintText: '코딩 요청을 입력하세요…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: busy ? null : (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: busy ? null : _send,
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editAgentConfiguration(AgentDto agent) async {
    final workspaceId = widget.workspaceId;
    if (workspaceId == null) return;
    final controller = ref.read(agentsControllerProvider(workspaceId).notifier);
    final providerController = ref.read(
      providerSettingsControllerProvider.notifier,
    );
    final providerState = await ref.read(
      providerSettingsControllerProvider.future,
    );
    if (providerState == null) return;
    await providerController.loadModels(agent.providerConnectionId);
    if (!mounted) return;
    final models =
        ref
            .read(providerSettingsControllerProvider)
            .asData
            ?.value
            ?.models[agent.providerConnectionId] ??
        const <ProviderModelDto>[];
    final draft = await showDialog<_AgentConfigurationDraft>(
      context: context,
      builder: (context) => _AgentConfigurationDialog(
        agent: agent,
        connections: providerState.connections,
        models: models,
        loadModels: (connectionId) async {
          await providerController.loadModels(connectionId);
          return ref
                  .read(providerSettingsControllerProvider)
                  .asData
                  ?.value
                  ?.models[connectionId] ??
              const <ProviderModelDto>[];
        },
      ),
    );
    if (draft == null) return;
    await controller.updateConfiguration(
      agentId: agent.id,
      providerConnectionId: draft.providerConnectionId,
      model: draft.model,
      reasoningEffort: draft.reasoningEffort,
    );
  }

  Future<void> _send() async {
    final text = _composer.text;
    if (text.trim().isEmpty) return;
    _composer.clear();
    await ref
        .read(conversationControllerProvider(widget.agentId).notifier)
        .startTurn(text);
  }

  List<TimelineEventDto> _coalesceAssistantDeltas(
    List<TimelineEventDto> events,
  ) {
    final result = <TimelineEventDto>[];
    for (final event in events) {
      if (event.type == 'assistant.delta' &&
          result.isNotEmpty &&
          result.last.type == 'assistant.delta' &&
          result.last.turnId == event.turnId) {
        final previous = result.removeLast();
        result.add(
          previous.copyWith(
            data: <String, dynamic>{
              'text':
                  '${previous.data['text'] as String? ?? ''}'
                  '${event.data['text'] as String? ?? ''}',
            },
          ),
        );
      } else {
        result.add(event);
      }
    }
    return result;
  }
}

final class _AgentConfigurationDraft {
  const _AgentConfigurationDraft({
    required this.providerConnectionId,
    required this.model,
    required this.reasoningEffort,
  });

  final String providerConnectionId;
  final String model;
  final String reasoningEffort;
}

class _AgentConfigurationDialog extends StatefulWidget {
  const _AgentConfigurationDialog({
    required this.agent,
    required this.connections,
    required this.models,
    required this.loadModels,
  });

  final AgentDto agent;
  final List<ProviderConnectionDto> connections;
  final List<ProviderModelDto> models;
  final _ModelLoader loadModels;

  @override
  State<_AgentConfigurationDialog> createState() =>
      _AgentConfigurationDialogState();
}

class _AgentConfigurationDialogState extends State<_AgentConfigurationDialog> {
  late final TextEditingController _model;
  late String _connectionId;
  late String _reasoningEffort;
  late List<ProviderModelDto> _models;

  @override
  void initState() {
    super.initState();
    _connectionId = widget.agent.providerConnectionId;
    _reasoningEffort = widget.agent.reasoningEffort;
    _models = widget.models;
    _model = TextEditingController(text: widget.agent.model);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Agent 모델 설정'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: _connectionId,
          decoration: const InputDecoration(labelText: 'API provider'),
          items: widget.connections
              .where(
                (item) =>
                    item.status == ProviderConnectionStatus.connected ||
                    item.status == ProviderConnectionStatus.degraded,
              )
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(item.displayName),
                ),
              )
              .toList(),
          onChanged: _selectProvider,
        ),
        const SizedBox(height: 12),
        DropdownMenu<String>(
          controller: _model,
          enableFilter: true,
          expandedInsets: EdgeInsets.zero,
          label: const Text('Model ID'),
          dropdownMenuEntries: _models
              .map(
                (item) => DropdownMenuEntry(value: item.id, label: item.label),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _reasoningEffort,
          decoration: const InputDecoration(labelText: 'Reasoning effort'),
          items: const <String>['none', 'low', 'medium', 'high', 'xhigh']
              .map(
                (item) => DropdownMenuItem(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: (value) =>
              setState(() => _reasoningEffort = value ?? _reasoningEffort),
        ),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(onPressed: _submit, child: const Text('저장')),
    ],
  );

  Future<void> _selectProvider(String? value) async {
    if (value == null) return;
    final models = await widget.loadModels(value);
    if (!mounted) return;
    final provider = widget.connections
        .where((item) => item.id == value)
        .firstOrNull;
    setState(() {
      _connectionId = value;
      _models = models;
      _model.text = provider?.defaultModelId ?? '';
    });
  }

  void _submit() {
    final model = _model.text.trim();
    if (model.isEmpty) return;
    Navigator.pop(
      context,
      _AgentConfigurationDraft(
        providerConnectionId: _connectionId,
        model: model,
        reasoningEffort: _reasoningEffort,
      ),
    );
  }
}

/// Renders one persisted timeline event.
class TimelineCard extends StatelessWidget {
  /// Creates a [TimelineCard].
  const TimelineCard({required this.event, super.key});

  /// The event rendered by this card.
  final TimelineEventDto event;

  @override
  Widget build(BuildContext context) {
    final isUser = event.type == 'user.message';
    final isAssistant = event.type == 'assistant.delta';
    final text = event.data['text'] as String?;
    final display =
        text ?? const JsonEncoder.withIndent('  ').convert(event.data);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Card(
          color: isUser ? Theme.of(context).colorScheme.primaryContainer : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isUser
                      ? 'You'
                      : isAssistant
                      ? 'Assistant'
                      : event.type,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 5),
                if (isUser || isAssistant)
                  MarkdownBody(data: display)
                else
                  SelectableText(display),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders an actionable tool approval request.
class ApprovalCard extends ConsumerWidget {
  /// Creates an [ApprovalCard].
  const ApprovalCard({required this.approval, super.key});

  /// The pending approval rendered by this card.
  final ApprovalRequestDto approval;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '승인 필요 · ${approval.toolName}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SelectableText(
              approval.preview ??
                  const JsonEncoder.withIndent(
                    '  ',
                  ).convert(approval.arguments),
              maxLines: 12,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => ref
                      .read(
                        conversationControllerProvider(
                          approval.agentId,
                        ).notifier,
                      )
                      .resolveApproval(approval.id, approved: false),
                  child: const Text('거부'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => ref
                      .read(
                        conversationControllerProvider(
                          approval.agentId,
                        ).notifier,
                      )
                      .resolveApproval(approval.id, approved: true),
                  child: const Text('승인'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
