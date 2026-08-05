import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_list_row.dart';
import 'package:coder_app/src/coder_selection_row.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// The literal reference syntax an MCP value may use.
///
/// Not localized: these are tokens the daemon parses, not prose.
const String mcpSecretSyntax = r'${secret:name}   ${env:NAME}';

/// Two-pane editor for one daemon's MCP servers.
class McpSettingsPage extends ConsumerStatefulWidget {
  /// Creates the MCP settings page.
  const McpSettingsPage({required this.hostId, this.worktreeId, super.key});

  /// Daemon whose servers are shown.
  final String hostId;

  /// Worktree whose repository-declared servers are shown, when one is open.
  final String? worktreeId;

  @override
  ConsumerState<McpSettingsPage> createState() => _McpSettingsPageState();
}

class _McpSettingsPageState extends ConsumerState<McpSettingsPage> {
  String? _selectedId;
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = mcpServersControllerProvider(
      widget.hostId,
      widget.worktreeId,
    );
    return ref
        .watch(provider)
        .when(
          loading: () => const Center(
            child: TRSpinner(uiSize: TRUiSize.md, label: 'Loading MCP servers'),
          ),
          error: (error, _) => Center(
            key: const ValueKey<String>('mcp-settings-error'),
            child: Text('$error'),
          ),
          data: (state) => _build(context, l10n, state),
        );
  }

  Widget _build(
    BuildContext context,
    AppLocalizations l10n,
    McpServersState state,
  ) {
    final selected = _creating
        ? null
        : state.servers
              .where((server) => server.config.id == _selectedId)
              .firstOrNull;
    final list = _ServerList(
      key: const ValueKey<String>('mcp-server-list'),
      state: state,
      selectedId: _creating ? null : _selectedId,
      onSelected: (id) => setState(() {
        _creating = false;
        _selectedId = id;
      }),
      onAdd: () => setState(() {
        _creating = true;
        _selectedId = null;
      }),
    );
    final detail = _creating
        ? _ServerEditor(
            key: const ValueKey<String>('mcp-server-editor-new'),
            hostId: widget.hostId,
            worktreeId: widget.worktreeId,
            existingIds: state.userServers
                .map((server) => server.config.id)
                .toSet(),
            onDone: (id) => setState(() {
              _creating = false;
              _selectedId = id;
            }),
          )
        : selected == null
        ? Center(child: Text(l10n.mcpSettingsSelectServer))
        : _ServerEditor(
            key: ValueKey<String>('mcp-server-editor-${selected.config.id}'),
            hostId: widget.hostId,
            worktreeId: widget.worktreeId,
            server: selected,
            existingIds: const <String>{},
            onDone: (id) => setState(() => _selectedId = id),
          );

    return LayoutBuilder(
      key: const ValueKey<String>('mcp-settings-page'),
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return selected == null && !_creating
              ? list
              : Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TRButton(
                        appearance: TRAppearance.ghost,
                        uiSize: TRUiSize.md,
                        onPressed: () => setState(() {
                          _creating = false;
                          _selectedId = null;
                        }),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(CoderIcons.back),
                            const SizedBox(width: TRSpacing.extraSmall),
                            Text(l10n.mcpSettingsHeading),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: detail),
                  ],
                );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(width: 300, child: list),
            const VerticalDivider(width: 1),
            Expanded(child: detail),
          ],
        );
      },
    );
  }
}

class _ServerList extends StatelessWidget {
  const _ServerList({
    required this.state,
    required this.selectedId,
    required this.onSelected,
    required this.onAdd,
    super.key,
  });

  final McpServersState state;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final project = state.projectServers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.mcpSettingsHeading,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TRIconButton(
                appearance: TRAppearance.ghost,
                uiSize: TRUiSize.md,
                key: const ValueKey<String>('mcp-server-add'),
                label: l10n.mcpSettingsAdd,
                onPressed: onAdd,
                icon: const Icon(CoderIcons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: <Widget>[
              _SectionHeader(
                key: const ValueKey<String>('mcp-scope-section-user'),
                label: l10n.mcpSettingsScopeUser,
              ),
              if (state.userServers.isEmpty)
                CoderListRow(
                  key: const ValueKey<String>('mcp-server-list-empty'),
                  title: Text(l10n.mcpSettingsEmpty),
                ),
              for (final server in state.userServers)
                _ServerTile(
                  server: server,
                  selected: server.config.id == selectedId,
                  onTap: () => onSelected(server.config.id),
                ),
              if (project.isNotEmpty) ...<Widget>[
                _SectionHeader(
                  key: const ValueKey<String>('mcp-scope-section-project'),
                  label: l10n.mcpSettingsScopeProject,
                ),
                for (final server in project)
                  _ServerTile(
                    server: server,
                    selected: server.config.id == selectedId,
                    onTap: () => onSelected(server.config.id),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(label, style: Theme.of(context).textTheme.labelMedium),
  );
}

class _ServerTile extends StatelessWidget {
  const _ServerTile({
    required this.server,
    required this.selected,
    required this.onTap,
  });

  final McpServerStateDto server;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CoderListRow(
      key: ValueKey<String>('mcp-server-tile-${server.config.id}'),
      selected: selected,
      onTap: onTap,
      leading: _StatusDot(server: server),
      title: Text(server.config.id),
      subtitle: Text(
        server.shadowed
            ? l10n.mcpSettingsShadowed
            : '${mcpStatusLabel(l10n, server.status)} · '
                  '${l10n.mcpSettingsDiscoveredTools} '
                  '${server.tools.length}',
      ),
      trailing: server.scope == McpConfigScope.project
          ? const Icon(CoderIcons.lock, size: 18)
          : null,
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.server});

  final McpServerStateDto server;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (server.status == McpServerStatus.connecting) {
      return TRSpinner(
        key: ValueKey<String>('mcp-server-status-${server.config.id}'),
        uiSize: TRUiSize.md,
        label: 'Connecting MCP server',
      );
    }
    final color = switch (server.status) {
      McpServerStatus.ready => scheme.primary,
      McpServerStatus.failed => scheme.error,
      McpServerStatus.disabled || McpServerStatus.connecting => scheme.outline,
    };
    return Icon(
      CoderIcons.status,
      key: ValueKey<String>('mcp-server-status-${server.config.id}'),
      size: 12,
      color: color,
    );
  }
}

/// Returns the localized label for [status].
String mcpStatusLabel(AppLocalizations l10n, McpServerStatus status) =>
    switch (status) {
      McpServerStatus.disabled => l10n.mcpSettingsStatusDisabled,
      McpServerStatus.connecting => l10n.mcpSettingsStatusConnecting,
      McpServerStatus.ready => l10n.mcpSettingsStatusReady,
      McpServerStatus.failed => l10n.mcpSettingsStatusFailed,
    };

class _ServerEditor extends ConsumerStatefulWidget {
  const _ServerEditor({
    required this.hostId,
    required this.worktreeId,
    required this.existingIds,
    required this.onDone,
    this.server,
    super.key,
  });

  final String hostId;
  final String? worktreeId;
  final Set<String> existingIds;
  final ValueChanged<String> onDone;
  final McpServerStateDto? server;

  @override
  ConsumerState<_ServerEditor> createState() => _ServerEditorState();
}

class _ServerEditorState extends ConsumerState<_ServerEditor> {
  late final TextEditingController _id;
  late final TextEditingController _command;
  late final TextEditingController _args;
  late final TextEditingController _cwd;
  late final TextEditingController _url;
  late final TextEditingController _env;
  late final TextEditingController _headers;
  late McpTransportKind _transport;
  late bool _enabled;
  bool _busy = false;
  String? _error;
  String? _notice;

  bool get _readOnly => widget.server?.scope == McpConfigScope.project;

  bool get _isNew => widget.server == null;

  @override
  void initState() {
    super.initState();
    final config = widget.server?.config;
    _id = TextEditingController(text: config?.id ?? '');
    _command = TextEditingController(text: config?.command ?? '');
    _args = TextEditingController(
      text: (config?.args ?? <String>[]).join('\n'),
    );
    _cwd = TextEditingController(text: config?.cwd ?? '');
    _url = TextEditingController(text: config?.url ?? '');
    _env = TextEditingController(text: formatMcpPairs(config?.env, '='));
    _headers = TextEditingController(
      text: formatMcpPairs(config?.headers, ': '),
    );
    _transport = config?.transport ?? McpTransportKind.stdio;
    _enabled = config?.enabled ?? true;
  }

  @override
  void dispose() {
    _id.dispose();
    _command.dispose();
    _args.dispose();
    _cwd.dispose();
    _url.dispose();
    _env.dispose();
    _headers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final server = widget.server;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        if (server != null && _readOnly)
          TRCard(
            padding: TRCardPadding.none,
            key: const ValueKey<String>('mcp-server-readonly'),
            child: CoderListRow(
              leading: const Icon(CoderIcons.lock),
              title: Text(l10n.mcpSettingsProjectReadOnly),
              subtitle: Text(
                l10n.mcpSettingsSource(server.sourcePath),
                key: ValueKey<String>('mcp-server-source-${server.config.id}'),
              ),
            ),
          ),
        if (server != null && server.shadowed)
          TRCard(
            padding: TRCardPadding.none,
            key: ValueKey<String>('mcp-server-shadowed-${server.config.id}'),
            variant: TRCardVariant.elevated,
            child: CoderListRow(
              leading: const Icon(CoderIcons.warning),
              title: Text(l10n.mcpSettingsShadowed),
            ),
          ),
        TRTextField(
          uiSize: TRUiSize.md,
          key: const ValueKey<String>('mcp-field-id'),
          controller: _id,
          enabled: _isNew,
          label: l10n.mcpSettingsServerId,
        ),
        const SizedBox(height: 16),
        TRToggleGroup(
          key: const ValueKey<String>('mcp-transport-selector'),
          value: <String>[_transport.name],
          disabled: _readOnly,
          children: <TRToggle>[
            TRToggle(
              value: McpTransportKind.stdio.name,
              uiSize: TRUiSize.md,
              child: Text(l10n.mcpSettingsTransportStdio),
            ),
            TRToggle(
              value: McpTransportKind.http.name,
              uiSize: TRUiSize.md,
              child: Text(l10n.mcpSettingsTransportHttp),
            ),
          ],
          onValueChange: (value) => setState(
            () => _transport = McpTransportKind.values.byName(value.first),
          ),
        ),
        const SizedBox(height: 16),
        if (_transport == McpTransportKind.stdio) ...<Widget>[
          TRTextField(
            uiSize: TRUiSize.md,
            key: const ValueKey<String>('mcp-field-command'),
            controller: _command,
            enabled: !_readOnly,
            label: l10n.mcpSettingsCommand,
          ),
          const SizedBox(height: 16),
          TRTextField(
            uiSize: TRUiSize.md,
            key: const ValueKey<String>('mcp-field-args'),
            controller: _args,
            enabled: !_readOnly,
            minLines: 2,
            maxLines: 6,
            label: l10n.mcpSettingsArgs,
          ),
          const SizedBox(height: 16),
          TRTextField(
            uiSize: TRUiSize.md,
            key: const ValueKey<String>('mcp-field-cwd'),
            controller: _cwd,
            enabled: !_readOnly,
            label: l10n.mcpSettingsWorkingDirectory,
          ),
          const SizedBox(height: 16),
          TRTextField(
            uiSize: TRUiSize.md,
            key: const ValueKey<String>('mcp-field-env'),
            controller: _env,
            enabled: !_readOnly,
            minLines: 2,
            maxLines: 6,
            label: l10n.mcpSettingsEnvironment,
          ),
        ] else ...<Widget>[
          TRTextField(
            uiSize: TRUiSize.md,
            key: const ValueKey<String>('mcp-field-url'),
            controller: _url,
            enabled: !_readOnly,
            label: l10n.mcpSettingsUrl,
          ),
          const SizedBox(height: 16),
          TRTextField(
            uiSize: TRUiSize.md,
            key: const ValueKey<String>('mcp-field-headers'),
            controller: _headers,
            enabled: !_readOnly,
            minLines: 2,
            maxLines: 6,
            label: l10n.mcpSettingsHeaders,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.mcpSettingsSecretHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          mcpSecretSyntax,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 16),
        CoderSwitchRow(
          key: const ValueKey<String>('mcp-field-enabled'),
          value: _enabled,
          onChanged: _readOnly
              ? null
              : (value) => setState(() => _enabled = value),
          title: Text(l10n.mcpSettingsEnabled),
        ),
        if (_error case final error?) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            error,
            key: const ValueKey<String>('mcp-editor-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_notice case final notice?) ...<Widget>[
          const SizedBox(height: 8),
          Text(notice, key: const ValueKey<String>('mcp-editor-notice')),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            if (!_readOnly)
              TRButton(
                intent: TRIntent.primary,
                uiSize: TRUiSize.md,
                key: const ValueKey<String>('mcp-server-save'),
                onPressed: _busy ? null : _save,
                child: Text(MaterialLocalizations.of(context).saveButtonLabel),
              ),
            if (!_readOnly)
              TRButton(
                appearance: TRAppearance.outline,
                uiSize: TRUiSize.md,
                key: const ValueKey<String>('mcp-server-test'),
                onPressed: _busy ? null : _test,
                child: Text(l10n.mcpSettingsTest),
              ),
            if (!_readOnly)
              TRButton(
                appearance: TRAppearance.ghost,
                uiSize: TRUiSize.md,
                key: const ValueKey<String>('mcp-secret-set'),
                onPressed: _busy ? null : _promptForSecret,
                child: Text(l10n.mcpSettingsSecretSet),
              ),
            if (!_readOnly && !_isNew)
              TRButton(
                appearance: TRAppearance.ghost,
                uiSize: TRUiSize.md,
                key: const ValueKey<String>('mcp-server-delete'),
                onPressed: _busy ? null : _delete,
                child: Text(l10n.mcpSettingsDelete),
              ),
          ],
        ),
        if (server != null) ...<Widget>[
          const SizedBox(height: 24),
          Text(
            l10n.mcpSettingsDiscoveredTools,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (server.tools.isEmpty)
            Text(l10n.mcpSettingsNoTools)
          else
            for (final tool in server.tools)
              CoderListRow(
                key: ValueKey<String>('mcp-tool-tile-${tool.toolId}'),
                dense: true,
                title: Text(tool.toolId),
                subtitle: Text(tool.description),
              ),
          if (server.error case final error?) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              error,
              key: ValueKey<String>('mcp-server-error-${server.config.id}'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (server.diagnostics.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            TRCollapsible(
              key: const ValueKey<String>('mcp-server-diagnostics'),
              trigger: Text(l10n.mcpSettingsDiagnostics),
              content: Column(
                children: <Widget>[
                  for (final line in server.diagnostics)
                    CoderListRow(dense: true, title: Text(line)),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  McpServerConfigDto? _edited(AppLocalizations l10n) {
    final id = _id.text.trim();
    if (!isValidMcpServerId(id) ||
        (_isNew && widget.existingIds.contains(id))) {
      setState(() => _error = l10n.mcpSettingsServerIdInvalid);
      return null;
    }
    return McpServerConfigDto(
      id: id,
      transport: _transport,
      enabled: _enabled,
      command: _transport == McpTransportKind.stdio
          ? _command.text.trim()
          : null,
      args: _transport == McpTransportKind.stdio
          ? parseMcpLines(_args.text)
          : const <String>[],
      env: _transport == McpTransportKind.stdio
          ? parseMcpPairs(_env.text, '=')
          : const <String, String>{},
      cwd: _transport == McpTransportKind.stdio && _cwd.text.trim().isNotEmpty
          ? _cwd.text.trim()
          : null,
      url: _transport == McpTransportKind.http ? _url.text.trim() : null,
      headers: _transport == McpTransportKind.http
          ? parseMcpPairs(_headers.text, ':')
          : const <String, String>{},
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final edited = _edited(l10n);
    if (edited == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final controller = ref.read(
        mcpServersControllerProvider(widget.hostId, widget.worktreeId).notifier,
      );
      if (_isNew) {
        await controller.add(edited);
      } else {
        await controller.save(edited);
      }
      if (!mounted) return;
      widget.onDone(edited.id);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    final l10n = AppLocalizations.of(context);
    final edited = _edited(l10n);
    if (edited == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final result = await ref
          .read(
            mcpServersControllerProvider(
              widget.hostId,
              widget.worktreeId,
            ).notifier,
          )
          .test(edited);
      if (!mounted) return;
      setState(() {
        if (result.status == McpServerStatus.ready) {
          _notice = l10n.mcpSettingsTestSucceeded(result.tools.length);
        } else {
          _error = l10n.mcpSettingsTestFailed(result.error ?? '');
        }
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = l10n.mcpSettingsTestFailed('$error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final id = widget.server!.config.id;
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        key: const ValueKey<String>('mcp-delete-dialog'),
        title: Text(l10n.mcpSettingsDelete),
        content: Text(l10n.mcpSettingsDeleteConfirm(id)),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            uiSize: TRUiSize.md,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TRButton(
            intent: TRIntent.primary,
            uiSize: TRUiSize.md,
            key: const ValueKey<String>('mcp-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.mcpSettingsDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(
            mcpServersControllerProvider(
              widget.hostId,
              widget.worktreeId,
            ).notifier,
          )
          .remove(id);
      if (mounted) widget.onDone('');
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _promptForSecret() async {
    final secret = await showTRDialog<({String key, String value})>(
      context: context,
      builder: (context) => const _SecretDialog(),
    );
    if (secret == null || !mounted) return;
    try {
      await ref
          .read(
            mcpServersControllerProvider(
              widget.hostId,
              widget.worktreeId,
            ).notifier,
          )
          .setSecret(secret.key, secret.value);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }
}

/// Collects one secret, owning the controllers for as long as it is shown.
class _SecretDialog extends StatefulWidget {
  const _SecretDialog();

  @override
  State<_SecretDialog> createState() => _SecretDialogState();
}

class _SecretDialogState extends State<_SecretDialog> {
  final TextEditingController _key = TextEditingController();
  final TextEditingController _value = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TRAlertDialog(
      key: const ValueKey<String>('mcp-secret-dialog'),
      title: Text(l10n.mcpSettingsSecretSet),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TRTextField(
              uiSize: TRUiSize.md,
              key: const ValueKey<String>('mcp-secret-key'),
              controller: _key,
              label: l10n.mcpSettingsSecretKey,
            ),
            TRTextField(
              uiSize: TRUiSize.md,
              key: const ValueKey<String>('mcp-secret-value'),
              controller: _value,
              obscureText: true,
              label: l10n.mcpSettingsSecretValue,
            ),
          ],
        ),
      ),
      actions: <TRButton>[
        TRButton(
          appearance: TRAppearance.ghost,
          uiSize: TRUiSize.md,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TRButton(
          intent: TRIntent.primary,
          uiSize: TRUiSize.md,
          key: const ValueKey<String>('mcp-secret-save'),
          onPressed: () {
            final key = _key.text.trim();
            if (key.isEmpty) return;
            Navigator.of(
              context,
            ).pop((key: key, value: _value.text));
          },
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
        ),
      ],
    );
  }
}

/// Whether [id] can be namespaced into `mcp__<server>__<tool>`.
bool isValidMcpServerId(String id) =>
    id.isNotEmpty &&
    id.length <= 40 &&
    !id.contains('__') &&
    RegExp(r'^[a-z0-9][a-z0-9_-]*$').hasMatch(id);

/// Splits a multi-line field into trimmed, non-empty entries.
List<String> parseMcpLines(String text) => <String>[
  for (final line in text.split('\n'))
    if (line.trim().isNotEmpty) line.trim(),
];

/// Parses `key<separator>value` lines into a map.
Map<String, String> parseMcpPairs(String text, String separator) {
  final entries = <String, String>{};
  for (final line in parseMcpLines(text)) {
    final index = line.indexOf(separator);
    if (index <= 0) continue;
    entries[line.substring(0, index).trim()] = line
        .substring(index + separator.length)
        .trim();
  }
  return entries;
}

/// Renders a map back into editable `key<separator>value` lines.
String formatMcpPairs(Map<String, String>? entries, String separator) =>
    (entries ?? const <String, String>{}).entries
        .map((entry) => '${entry.key}$separator${entry.value}')
        .join('\n');
