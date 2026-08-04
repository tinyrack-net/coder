import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_labels.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Daemon-independent app settings and remote host management.
class AppSettingsPage extends ConsumerWidget {
  /// Creates the global application settings page.
  const AppSettingsPage({this.embedded = false, super.key});

  /// Whether the unified settings shell supplies navigation chrome.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(hostRegistryControllerProvider);
    final supportsEmbedded = ref
        .read(appServicesProvider)
        .supportsEmbeddedDaemon;
    final body = state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('$error')),
      data: (registry) => _settingsBody(
        context,
        ref,
        registry,
        supportsEmbedded: supportsEmbedded,
      ),
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(l10n.appSettingsTitle),
      ),
      body: body,
    );
  }

  Widget _settingsBody(
    BuildContext context,
    WidgetRef ref,
    HostRegistryState registry, {
    required bool supportsEmbedded,
  }) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        if (supportsEmbedded) ...<Widget>[
          Text(
            l10n.appSettingsLocalSection,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  title: Text(l10n.embeddedDaemonName),
                  subtitle: Text(l10n.appSettingsEmbeddedSubtitle),
                  value: registry.settings.embeddedDaemonEnabled,
                  onChanged: (enabled) => _toggleEmbedded(
                    context,
                    ref,
                    currentlyEnabled: registry.settings.embeddedDaemonEnabled,
                    enabled: enabled,
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  key: const ValueKey<String>('embedded-daemon-exposure'),
                  title: Text(l10n.appSettingsExposure),
                  subtitle: Text(l10n.appSettingsExposureSubtitle),
                  value:
                      registry.settings.embeddedDaemonExposure ==
                      EmbeddedDaemonExposure.allInterfaces,
                  onChanged: _embeddedRestarting(registry)
                      ? null
                      : (enabled) => ref
                            .read(hostRegistryControllerProvider.notifier)
                            .setEmbeddedDaemonExposure(
                              enabled
                                  ? EmbeddedDaemonExposure.allInterfaces
                                  : EmbeddedDaemonExposure.loopback,
                            ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: <Widget>[
            Text(
              l10n.appSettingsRemoteSection,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            FilledButton.icon(
              onPressed: () => context.go('/settings/daemons/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.appSettingsAddRemote),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (registry.profiles.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.appSettingsNoRemotes),
            ),
          ),
        for (final profile in registry.profiles)
          _RemoteHostCard(
            profile: profile,
            runtime: registry.runtimes[profile.id],
          ),
      ],
    );
  }

  bool _embeddedRestarting(HostRegistryState registry) =>
      registry.settings.embeddedDaemonEnabled &&
      registry.runtimes[embeddedHostId]?.status == HostRuntimeStatus.connecting;

  Future<void> _toggleEmbedded(
    BuildContext context,
    WidgetRef ref, {
    required bool currentlyEnabled,
    required bool enabled,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (currentlyEnabled && !enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.appSettingsStopEmbeddedTitle),
          content: Text(l10n.appSettingsStopEmbeddedBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonStop),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref
        .read(hostRegistryControllerProvider.notifier)
        .setEmbeddedDaemonEnabled(enabled: enabled);
  }
}

class _RemoteHostCard extends ConsumerWidget {
  const _RemoteHostCard({required this.profile, required this.runtime});

  final RemoteDaemonProfile profile;
  final HostRuntimeSnapshot? runtime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            ListTile(
              leading: Icon(_statusIcon(runtime?.status)),
              title: Text(profile.label),
              subtitle: Text(
                '${profile.websocketUri}\n${hostStatusText(l10n, runtime)}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: l10n.appSettingsEditConnection,
                onPressed: () => context.go('/settings/daemons/${profile.id}'),
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(l10n.appSettingsAutoConnect),
              value: profile.autoConnect,
              onChanged: (enabled) => ref
                  .read(hostRegistryControllerProvider.notifier)
                  .setRemoteAutoConnect(profile.id, enabled: enabled),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                TextButton.icon(
                  onPressed: () => ref
                      .read(hostRegistryControllerProvider.notifier)
                      .reconnect(profile.id),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.appSettingsReconnect),
                ),
                if (runtime?.connected == true)
                  TextButton.icon(
                    onPressed: () => context.go(
                      '/settings/providers?hostId=${profile.id}',
                    ),
                    icon: const Icon(Icons.hub_outlined),
                    label: Text(l10n.appSettingsProviderSettings),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Add/edit form for one remote daemon profile.
class RemoteHostEditPage extends ConsumerStatefulWidget {
  /// Creates an add form when [hostId] is null, otherwise an edit form.
  const RemoteHostEditPage({this.hostId, super.key});

  /// Existing profile ID for edit mode.
  final String? hostId;

  @override
  ConsumerState<RemoteHostEditPage> createState() => _RemoteHostEditPageState();
}

class _RemoteHostEditPageState extends ConsumerState<RemoteHostEditPage> {
  final _label = TextEditingController();
  final _address = TextEditingController();
  final _token = TextEditingController();
  bool _autoConnect = true;
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _address.addListener(_addressChanged);
  }

  void _addressChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _address.removeListener(_addressChanged);
    _label.dispose();
    _address.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final registry = ref.watch(hostRegistryControllerProvider).asData?.value;
    final existing = registry?.profiles
        .where((profile) => profile.id == widget.hostId)
        .firstOrNull;
    if (!_initialized && (widget.hostId == null || registry != null)) {
      _initialized = true;
      if (existing != null) {
        _label.text = existing.label;
        _address.text = existing.websocketUri.toString();
        _autoConnect = existing.autoConnect;
      }
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/settings/daemons'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          existing == null
              ? l10n.appSettingsAddRemoteTitle
              : l10n.appSettingsEditRemoteTitle,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('remote-host-label'),
                controller: _label,
                decoration: InputDecoration(
                  labelText: l10n.commonName,
                  hintText: 'Production daemon',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('remote-host-address'),
                controller: _address,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.appSettingsAddress,
                  hintText: 'wss://coder.example.com/ws',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('remote-host-token'),
                controller: _token,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: existing == null
                      ? 'Bearer token'
                      : l10n.appSettingsNewToken,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.appSettingsAutoConnect),
                value: _autoConnect,
                onChanged: (value) => setState(() => _autoConnect = value),
              ),
              if (_error case final error?)
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (existing != null)
                    TextButton(
                      onPressed: _saving ? null : () => _delete(existing),
                      child: Text(l10n.commonDelete),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : () => _save(existing),
                    child: Text(_saving ? l10n.commonSaving : l10n.commonSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(RemoteDaemonProfile? existing) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(hostRegistryControllerProvider.notifier);
      if (existing == null) {
        await controller.addRemote(
          label: _label.text,
          address: _address.text,
          bearerToken: _token.text,
          autoConnect: _autoConnect,
        );
      } else {
        await controller.updateRemote(
          profileId: existing.id,
          label: _label.text,
          address: _address.text,
          autoConnect: _autoConnect,
          replacementBearerToken: _token.text.trim().isEmpty
              ? null
              : _token.text,
        );
      }
      if (mounted) context.go('/settings/daemons');
    } on HostConnectionFailure catch (failure) {
      if (!mounted) return;
      final message = hostConnectionFailureText(
        AppLocalizations.of(context),
        failure,
      );
      setState(() => _error = message);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(RemoteDaemonProfile profile) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.appSettingsDeleteTitle(profile.label)),
        content: Text(l10n.appSettingsDeleteBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(hostRegistryControllerProvider.notifier)
        .removeRemote(profile.id);
    if (mounted) context.go('/');
  }
}

IconData _statusIcon(HostRuntimeStatus? status) => switch (status) {
  HostRuntimeStatus.online => Icons.check_circle_outline,
  HostRuntimeStatus.connecting || HostRuntimeStatus.reconnecting => Icons.sync,
  HostRuntimeStatus.offline => Icons.cloud_off_outlined,
  HostRuntimeStatus.conflict => Icons.call_split,
  HostRuntimeStatus.error => Icons.error_outline,
  HostRuntimeStatus.idle || null => Icons.pause_circle_outline,
};
