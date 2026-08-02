import 'dart:convert';

import 'package:coder_protocol/coder_protocol.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'bootstrap.dart';
import 'controller.dart';
import 'settings_page.dart';

class CoderApp extends StatelessWidget {
  CoderApp({required this.bootstrap, super.key});

  final AppBootstrap bootstrap;

  late final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const HostPage()),
      GoRoute(
        path: '/hosts/:hostId',
        builder: (_, state) =>
            DashboardPage(hostId: state.pathParameters['hostId']!),
        routes: <RouteBase>[
          GoRoute(
            path: 'settings',
            builder: (_, state) =>
                SettingsPage(hostId: state.pathParameters['hostId']!),
          ),
          GoRoute(
            path: 'workspaces/:workspaceId',
            builder: (_, state) => DashboardPage(
              hostId: state.pathParameters['hostId']!,
              workspaceId: state.pathParameters['workspaceId'],
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'agents/:agentId',
                builder: (_, state) => DashboardPage(
                  hostId: state.pathParameters['hostId']!,
                  workspaceId: state.pathParameters['workspaceId'],
                  agentId: state.pathParameters['agentId'],
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [bootstrapProvider.overrideWithValue(bootstrap)],
    child: MaterialApp.router(
      title: 'Tinyrack Coder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff625bff),
          brightness: Brightness.light,
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
      themeMode: ThemeMode.system,
      routerConfig: _router,
    ),
  );
}

class HostPage extends ConsumerStatefulWidget {
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
    Future<void>.microtask(
      () => ref.read(coderControllerProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    _address.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(coderControllerProvider, (previous, next) {
      if (next.connected &&
          previous?.connected != true &&
          next.serverInfo != null) {
        context.go('/hosts/${next.serverInfo!.serverId}');
      }
    });
    final state = ref.watch(coderControllerProvider);
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
                if (state.error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: state.connecting
                      ? null
                      : () => ref
                            .read(coderControllerProvider.notifier)
                            .connect(_address.text, _token.text),
                  icon: state.connecting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lan),
                  label: Text(state.connecting ? '연결 중…' : '연결'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({
    required this.hostId,
    this.workspaceId,
    this.agentId,
    super.key,
  });

  final String hostId;
  final String? workspaceId;
  final String? agentId;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId ||
        oldWidget.agentId != widget.agentId)
      _sync();
  }

  void _sync() {
    Future<void>.microtask(() async {
      final controller = ref.read(coderControllerProvider.notifier);
      if (widget.workspaceId != null)
        await controller.selectWorkspace(widget.workspaceId!);
      if (widget.agentId != null) await controller.selectAgent(widget.agentId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coderControllerProvider);
    if (!state.connected) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/'),
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
            onPressed: () => context.go('/hosts/${widget.hostId}/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text(state.connectionLabel ?? 'connected')),
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
                  child: _WorkspacePane(hostId: widget.hostId),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 280,
                  child: _AgentPane(
                    hostId: widget.hostId,
                    workspaceId: widget.workspaceId,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _ConversationPane(agentId: widget.agentId)),
              ],
            );
          }
          if (widget.agentId != null)
            return _ConversationPane(agentId: widget.agentId);
          if (widget.workspaceId != null) {
            return _AgentPane(
              hostId: widget.hostId,
              workspaceId: widget.workspaceId,
            );
          }
          return _WorkspacePane(hostId: widget.hostId);
        },
      ),
    );
  }
}

class _WorkspacePane extends ConsumerWidget {
  const _WorkspacePane({required this.hostId});

  final String hostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coderControllerProvider);
    final controller = ref.read(coderControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListTile(
          title: const Text('Workspaces'),
          trailing: controller.canRegisterLocalWorkspace
              ? IconButton(
                  tooltip: '로컬 workspace 등록',
                  onPressed: () async {
                    final path = await getDirectoryPath(
                      confirmButtonText: 'Workspace 선택',
                    );
                    if (path == null || !context.mounted) return;
                    final workspace = await controller.registerWorkspace(path);
                    if (context.mounted) {
                      context.go('/hosts/$hostId/workspaces/${workspace.id}');
                    }
                  },
                  icon: const Icon(Icons.create_new_folder_outlined),
                )
              : null,
        ),
        Expanded(
          child: state.workspaces.isEmpty
              ? const Center(child: Text('등록된 workspace가 없습니다.'))
              : ListView.builder(
                  itemCount: state.workspaces.length,
                  itemBuilder: (context, index) {
                    final item = state.workspaces[index];
                    return ListTile(
                      selected: item.id == state.selectedWorkspaceId,
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(item.name),
                      subtitle: Text(
                        item.rootPath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () =>
                          context.go('/hosts/$hostId/workspaces/${item.id}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AgentPane extends ConsumerWidget {
  const _AgentPane({required this.hostId, required this.workspaceId});

  final String hostId;
  final String? workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coderControllerProvider);
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
              : state.agents.isEmpty
              ? const Center(child: Text('새 agent를 만들어 시작하세요.'))
              : ListView.builder(
                  itemCount: state.agents.length,
                  itemBuilder: (context, index) {
                    final agent = state.agents[index];
                    return ListTile(
                      selected: agent.id == state.selectedAgentId,
                      leading: Icon(_agentIcon(agent.status)),
                      title: Text(agent.title),
                      subtitle: Text('${agent.model} · ${agent.status.name}'),
                      onTap: () => context.go(
                        '/hosts/$hostId/workspaces/$workspaceId/agents/${agent.id}',
                      ),
                    );
                  },
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
    final controller = ref.read(coderControllerProvider.notifier);
    final appState = ref.read(coderControllerProvider);
    final catalog = appState.providerCatalog;
    if (catalog == null || catalog.providers.isEmpty) return;
    var providerId = catalog.defaultProviderId ?? catalog.providers.first.id;
    await controller.loadProviderModels(providerId);
    if (!context.mounted) return;
    var availableModels =
        ref.read(coderControllerProvider).providerModels[providerId] ??
        const <ProviderModelDto>[];
    final title = TextEditingController(text: 'Coding session');
    final model = TextEditingController(
      text:
          catalog.providers
              .where((item) => item.id == providerId)
              .firstOrNull
              ?.defaultModelId ??
          '',
    );
    var permission = PermissionMode.ask;
    var reasoningEffort = 'medium';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('새 agent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: '이름'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: providerId,
                decoration: const InputDecoration(labelText: 'API provider'),
                items: catalog.providers
                    .where((item) => item.enabled)
                    .map(
                      (value) => DropdownMenuItem(
                        value: value.id,
                        child: Text(value.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  providerId = value;
                  await controller.loadProviderModels(value);
                  availableModels =
                      ref.read(coderControllerProvider).providerModels[value] ??
                      const <ProviderModelDto>[];
                  final selectedProvider = catalog.providers
                      .where((item) => item.id == value)
                      .firstOrNull;
                  model.text = selectedProvider?.defaultModelId ?? '';
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              DropdownMenu<String>(
                controller: model,
                enableFilter: true,
                enableSearch: true,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Model ID'),
                dropdownMenuEntries: availableModels
                    .map(
                      (item) =>
                          DropdownMenuEntry(value: item.id, label: item.label),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: reasoningEffort,
                decoration: const InputDecoration(
                  labelText: 'Reasoning effort',
                ),
                items: const <String>['none', 'low', 'medium', 'high', 'xhigh']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => reasoningEffort = value ?? reasoningEffort),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PermissionMode>(
                initialValue: permission,
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
                    setState(() => permission = value ?? PermissionMode.ask),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('생성'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !context.mounted || model.text.trim().isEmpty) {
      title.dispose();
      model.dispose();
      return;
    }
    final agent = await controller.createAgent(
      workspaceId: workspaceId,
      title: title.text.trim().isEmpty ? 'Coding session' : title.text.trim(),
      providerId: providerId,
      model: model.text.trim(),
      reasoningEffort: reasoningEffort,
      permissionMode: permission,
    );
    title.dispose();
    model.dispose();
    if (context.mounted) {
      context.go('/hosts/$hostId/workspaces/$workspaceId/agents/${agent.id}');
    }
  }
}

class _ConversationPane extends ConsumerStatefulWidget {
  const _ConversationPane({required this.agentId});

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
    final state = ref.watch(coderControllerProvider);
    final selected = state.agents
        .where((item) => item.id == widget.agentId)
        .firstOrNull;
    if (widget.agentId == null || selected == null) {
      return const Center(child: Text('Agent를 선택하세요.'));
    }
    final busy =
        selected.status == AgentStatus.running ||
        selected.status == AgentStatus.waitingForApproval;
    final displayTimeline = _coalesceAssistantDeltas(state.timeline);
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(selected.title),
          subtitle: Text(
            '${selected.providerId}/${selected.model} · '
            '${selected.reasoningEffort} · ${selected.permissionMode.name}',
          ),
          trailing: busy
              ? TextButton.icon(
                  onPressed: () =>
                      ref.read(coderControllerProvider.notifier).cancelTurn(),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('중지'),
                )
              : state.timeline.isEmpty
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
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final event =
                        displayTimeline[displayTimeline.length - index - 1];
                    return _TimelineCard(event: event);
                  },
                ),
        ),
        for (final approval in state.approvals.values)
          _ApprovalCard(approval: approval),
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
    final controller = ref.read(coderControllerProvider.notifier);
    final catalog = ref.read(coderControllerProvider).providerCatalog;
    if (catalog == null) return;
    var providerId = agent.providerId;
    var reasoning = agent.reasoningEffort;
    await controller.loadProviderModels(providerId);
    if (!mounted) return;
    var models =
        ref.read(coderControllerProvider).providerModels[providerId] ??
        const <ProviderModelDto>[];
    final model = TextEditingController(text: agent.model);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agent 모델 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: providerId,
                decoration: const InputDecoration(labelText: 'API provider'),
                items: catalog.providers
                    .where((item) => item.enabled)
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  await controller.loadProviderModels(value);
                  providerId = value;
                  models =
                      ref.read(coderControllerProvider).providerModels[value] ??
                      const <ProviderModelDto>[];
                  model.text =
                      catalog.providers
                          .where((item) => item.id == value)
                          .firstOrNull
                          ?.defaultModelId ??
                      '';
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 12),
              DropdownMenu<String>(
                controller: model,
                enableFilter: true,
                enableSearch: true,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Model ID'),
                dropdownMenuEntries: models
                    .map(
                      (item) =>
                          DropdownMenuEntry(value: item.id, label: item.label),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: reasoning,
                decoration: const InputDecoration(
                  labelText: 'Reasoning effort',
                ),
                items: const <String>['none', 'low', 'medium', 'high', 'xhigh']
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => reasoning = value ?? reasoning),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    final modelId = model.text.trim();
    model.dispose();
    if (accepted != true || modelId.isEmpty) return;
    await controller.updateAgentConfiguration(
      agentId: agent.id,
      providerId: providerId,
      model: modelId,
      reasoningEffort: reasoning,
    );
  }

  Future<void> _send() async {
    final text = _composer.text;
    if (text.trim().isEmpty) return;
    _composer.clear();
    await ref.read(coderControllerProvider.notifier).startTurn(text);
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
                  '${previous.data['text'] as String? ?? ''}${event.data['text'] as String? ?? ''}',
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

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.event});

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

class _ApprovalCard extends ConsumerWidget {
  const _ApprovalCard({required this.approval});

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
                      .read(coderControllerProvider.notifier)
                      .resolveApproval(approval.id, false),
                  child: const Text('거부'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => ref
                      .read(coderControllerProvider.notifier)
                      .resolveApproval(approval.id, true),
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
