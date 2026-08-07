import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/app/composition/app_providers.dart';
import 'package:coder_app/src/app/router/app_router.dart';
import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/presentation/host_labels.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_app/src/shared/presentation/coder_page_shell.dart';
import 'package:coder_app/src/shared/presentation/coder_selection_row.dart';
import 'package:coder_app/src/shared/presentation/settings_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

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
      loading: () => const Center(child: TRSpinner()),
      error: (error, stackTrace) => Center(child: TRText.inherit('$error')),
      data: (registry) => _settingsBody(
        context,
        ref,
        registry,
        supportsEmbedded: supportsEmbedded,
      ),
    );
    if (embedded) return body;
    return CoderPageShell(
      appBar: CoderPageHeader(
        leading: TRIconButton(
          key: const ValueKey<String>('app-settings-back-button'),
          appearance: TRAppearance.ghost,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () =>
              closeTask(context, () => const WorkspaceHomeRoute().go(context)),
          icon: const Icon(CoderIcons.back),
        ),
        title: TRText.inherit(l10n.appSettingsTitle),
      ),
      body: body,
    );
  }

  /// Builds the persistent alert for an embedded daemon that will not start.
  ///
  /// The guidance replaces the operating-system diagnostic, which no user can
  /// act on, so the copy action carries both: the guidance for the user and
  /// the diagnostic for whoever reads the bug report.
  Widget _embeddedFailureAlert(
    BuildContext context,
    WidgetRef ref,
    HostRuntimeSnapshot runtime, {
    required int port,
  }) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.appSettingsEmbeddedFailureTitle;
    final guidance = switch (runtime.errorReason) {
      HostFailureReason.embeddedPortInUse =>
        l10n.appSettingsEmbeddedPortConflict(port),
      _ => hostErrorText(l10n, runtime) ?? l10n.hostStatusError,
    };
    final diagnostic = runtime.error;
    return TRAlert(
      key: const ValueKey<String>('embedded-daemon-error'),
      title: TRText.inherit(title),
      description: SelectionArea(child: TRText.inherit(guidance)),
      icon: const Icon(CoderIcons.error),
      variant: TRStatusVariant.danger,
      actions: <Widget>[
        TRButton(
          appearance: TRAppearance.outline,
          onPressed: () => ref
              .read(hostRegistryControllerProvider.notifier)
              .reconnect(embeddedHostId),
          child: TRText.inherit(l10n.commonRetry),
        ),
        TRIconButton(
          key: const ValueKey<String>('embedded-daemon-error-copy'),
          appearance: TRAppearance.ghost,
          label: l10n.commonCopy,
          onPressed: () => Clipboard.setData(
            ClipboardData(
              text: <String>[
                title,
                guidance,
                if (diagnostic != null && diagnostic != guidance) diagnostic,
              ].join('\n'),
            ),
          ),
          icon: const Icon(CoderIcons.copy),
        ),
      ],
    );
  }

  Widget _settingsBody(
    BuildContext context,
    WidgetRef ref,
    HostRegistryState registry, {
    required bool supportsEmbedded,
  }) {
    final l10n = AppLocalizations.of(context);
    final embeddedRuntime = registry.runtimes[embeddedHostId];
    return SettingsScaffold(
      children: <Widget>[
        if (supportsEmbedded)
          SettingsSection(
            title: l10n.appSettingsLocalSection,
            banner:
                embeddedRuntime != null &&
                    embeddedRuntime.status == HostRuntimeStatus.error
                ? _embeddedFailureAlert(
                    context,
                    ref,
                    embeddedRuntime,
                    port: registry.settings.embeddedDaemonPort,
                  )
                : null,
            children: <Widget>[
              CoderSwitchRow(
                title: TRText.inherit(l10n.embeddedDaemonName),
                subtitle: TRText.inherit(
                  <String>[
                    l10n.appSettingsEmbeddedSubtitle,
                    if (embeddedRuntime != null &&
                        embeddedRuntime.status != HostRuntimeStatus.error)
                      hostStatusText(l10n, embeddedRuntime),
                  ].join('\n'),
                ),
                wrapsSubtitle: true,
                value: registry.settings.embeddedDaemonEnabled,
                onChanged: (enabled) => _toggleEmbedded(
                  context,
                  ref,
                  currentlyEnabled: registry.settings.embeddedDaemonEnabled,
                  enabled: enabled,
                ),
              ),
              CoderSwitchRow(
                key: const ValueKey<String>('embedded-daemon-exposure'),
                title: TRText.inherit(l10n.appSettingsExposure),
                subtitle: TRText.inherit(l10n.appSettingsExposureSubtitle),
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
              _EmbeddedPortEditor(
                port: registry.settings.embeddedDaemonPort,
                restarting: _embeddedRestarting(registry),
              ),
            ],
          ),
        SettingsSection.form(
          title: l10n.appSettingsRemoteSection,
          action: TRButton(
            key: const ValueKey<String>('app-settings-add-remote'),
            intent: TRIntent.primary,
            onPressed: () =>
                unawaited(const NewHostRoute().push<void>(context)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(CoderIcons.add),
                const SizedBox(width: TRSpacing.extraSmall),
                TRText(l10n.appSettingsAddRemote),
              ],
            ),
          ),
          children: <Widget>[
            if (registry.profiles.isEmpty)
              TRCard(
                padding: TRCardPadding.none,
                child: SettingsRow(
                  title: TRText.inherit(l10n.appSettingsNoRemotes),
                ),
              ),
            for (final profile in registry.profiles)
              _RemoteHostCard(
                profile: profile,
                runtime: registry.runtimes[profile.id],
              ),
          ],
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
      final confirmed = await showTRDialog<bool>(
        context: context,
        builder: (context) => TRAlertDialog(
          title: TRText.inherit(l10n.appSettingsStopEmbeddedTitle),
          content: TRText.inherit(l10n.appSettingsStopEmbeddedBody),
          actions: <TRButton>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: () => Navigator.pop(context, false),
              child: TRText.inherit(l10n.commonCancel),
            ),
            TRButton(
              intent: TRIntent.primary,
              onPressed: () => Navigator.pop(context, true),
              child: TRText.inherit(l10n.commonStop),
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

class _EmbeddedPortEditor extends ConsumerStatefulWidget {
  const _EmbeddedPortEditor({required this.port, required this.restarting});

  final int port;
  final bool restarting;

  @override
  ConsumerState<_EmbeddedPortEditor> createState() =>
      _EmbeddedPortEditorState();
}

class _EmbeddedPortEditorState extends ConsumerState<_EmbeddedPortEditor> {
  double? _draftPort;
  bool _applying = false;

  int? get _validPort {
    final value = _draftPort;
    if (value == null || value != value.truncateToDouble()) return null;
    final port = value.toInt();
    return port >= 1 && port <= 65535 ? port : null;
  }

  @override
  void initState() {
    super.initState();
    _draftPort = widget.port.toDouble();
  }

  @override
  void didUpdateWidget(_EmbeddedPortEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.port != widget.port) {
      _draftPort = widget.port.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final port = _validPort;
    final changed = port != null && port != widget.port;
    return Padding(
      padding: SettingsRow.contentPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TRNumberField.controlled(
              key: const ValueKey<String>('embedded-daemon-port'),
              value: _draftPort,
              enabled: !_applying && !widget.restarting,
              errorText: _draftPort != null && port == null
                  ? l10n.appSettingsEmbeddedPortInvalid
                  : null,
              helperText: l10n.appSettingsEmbeddedPortHelp,
              label: l10n.appSettingsEmbeddedPort,
              smallStep: 1,
              scrubbable: false,
              onValueChange: (value) => setState(() => _draftPort = value),
            ),
          ),
          const SizedBox(width: TRSpacing.small),
          TRButton(
            key: const ValueKey<String>('embedded-daemon-port-apply'),
            intent: TRIntent.primary,
            onPressed: changed && !_applying && !widget.restarting
                ? () => _apply(port)
                : null,
            child: TRText.inherit(l10n.appSettingsEmbeddedPortApply),
          ),
        ],
      ),
    );
  }

  Future<void> _apply(int port) async {
    setState(() => _applying = true);
    try {
      await ref
          .read(hostRegistryControllerProvider.notifier)
          .setEmbeddedDaemonPort(port);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }
}

/// One remote daemon: its address, its auto-connect choice, and its actions.
///
/// A daemon is a compound entity with actions of its own, so it keeps its own
/// card. Sharing one card across every daemon leaves no boundary between them
/// and makes "the reconnect button of this daemon" unaddressable.
class _RemoteHostCard extends ConsumerWidget {
  const _RemoteHostCard({required this.profile, required this.runtime});

  final RemoteDaemonProfile profile;
  final HostRuntimeSnapshot? runtime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return TRCard(
      padding: TRCardPadding.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SettingsRow(
            leading: Icon(hostStatusIcon(runtime?.status)),
            title: TRText.inherit(profile.label),
            description: TRText.inherit(
              '${profile.websocketUri}\n${hostStatusText(l10n, runtime)}',
            ),
            wrapsDescription: true,
            control: TRIconButton(
              appearance: TRAppearance.ghost,
              label: l10n.appSettingsEditConnection,
              onPressed: () => unawaited(
                EditHostRoute(hostId: profile.id).push<void>(context),
              ),
              icon: const Icon(CoderIcons.edit),
            ),
          ),
          CoderSwitchRow(
            title: TRText.inherit(l10n.appSettingsAutoConnect),
            value: profile.autoConnect,
            onChanged: (enabled) => ref
                .read(hostRegistryControllerProvider.notifier)
                .setRemoteAutoConnect(profile.id, enabled: enabled),
          ),
          Padding(
            // Sharing the row inset keeps the actions on the same trailing edge
            // as the controls above them.
            padding: SettingsRow.contentPadding,
            // A Wrap rather than a Row: on a narrow window the two actions do
            // not fit on one line. It right-aligns correctly here because the
            // surrounding column stretches it to the card width.
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: TRSpacing.small,
              runSpacing: TRSpacing.extraSmall,
              children: <Widget>[
                TRButton(
                  appearance: TRAppearance.ghost,
                  onPressed: () => ref
                      .read(hostRegistryControllerProvider.notifier)
                      .reconnect(profile.id),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(CoderIcons.refresh),
                      const SizedBox(width: TRSpacing.extraSmall),
                      TRText(l10n.appSettingsReconnect),
                    ],
                  ),
                ),
                if (runtime?.connected == true)
                  TRButton(
                    appearance: TRAppearance.ghost,
                    onPressed: () => ProviderSettingsRoute(
                      hostId: profile.id,
                    ).replace(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(CoderIcons.network),
                        const SizedBox(width: TRSpacing.extraSmall),
                        TRText(l10n.appSettingsProviderSettings),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
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
    return CoderPageShell(
      appBar: CoderPageHeader(
        leading: TRIconButton(
          key: const ValueKey<String>('remote-host-back-button'),
          appearance: TRAppearance.ghost,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => closeTask(
            context,
            () => const DaemonSettingsRoute().go(context),
          ),
          icon: const Icon(CoderIcons.back),
        ),
        title: TRText.inherit(
          existing == null
              ? l10n.appSettingsAddRemoteTitle
              : l10n.appSettingsEditRemoteTitle,
        ),
      ),
      body: SettingsScaffold(
        children: <Widget>[
          SettingsSection.form(
            // Not the page title again: the header above already names the
            // form, and a section heading is drawn larger than it.
            title: l10n.appSettingsRemoteDetails,
            banner: _error == null
                ? null
                : TRAlert(
                    title: TRText.inherit(l10n.appSettingsConnectionFailed),
                    description: TRText.inherit(_error!),
                    icon: const Icon(CoderIcons.error),
                    variant: TRStatusVariant.danger,
                  ),
            children: <Widget>[
              TRTextField(
                key: const ValueKey<String>('remote-host-label'),
                controller: _label,
                label: l10n.commonName,
                placeholder: 'Production daemon',
              ),
              TRTextField(
                key: const ValueKey<String>('remote-host-address'),
                controller: _address,
                keyboardType: TextInputType.url,
                label: l10n.appSettingsAddress,
                placeholder: 'wss://coder.example.com/ws',
              ),
              TRTextField(
                key: const ValueKey<String>('remote-host-token'),
                controller: _token,
                obscureText: true,
                label: existing == null
                    ? l10n.appSettingsBearerToken
                    : l10n.appSettingsNewToken,
              ),
            ],
          ),
          SettingsSection(
            title: l10n.appSettingsConnectionBehaviour,
            children: <Widget>[
              CoderSwitchRow(
                title: TRText.inherit(l10n.appSettingsAutoConnect),
                value: _autoConnect,
                onChanged: (value) => setState(() => _autoConnect = value),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (existing != null) ...<Widget>[
                TRButton(
                  appearance: TRAppearance.ghost,
                  onPressed: _saving ? null : () => _delete(existing),
                  child: TRText.inherit(l10n.commonDelete),
                ),
                const SizedBox(width: TRSpacing.small),
              ],
              TRButton(
                intent: TRIntent.primary,
                onPressed: _saving ? null : () => _save(existing),
                child: TRText.inherit(
                  _saving ? l10n.commonSaving : l10n.commonSave,
                ),
              ),
            ],
          ),
        ],
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
      if (mounted) {
        closeTask(context, () => const DaemonSettingsRoute().go(context));
      }
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
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: TRText.inherit(l10n.appSettingsDeleteTitle(profile.label)),
        content: TRText.inherit(l10n.appSettingsDeleteBody),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: TRText.inherit(l10n.commonCancel),
          ),
          TRButton(
            intent: TRIntent.primary,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(hostRegistryControllerProvider.notifier)
        .removeRemote(profile.id);
    // Deleting the daemon being edited invalidates the settings task that was
    // opened for it, so this clears the stack rather than popping into it.
    if (mounted) const WorkspaceHomeRoute().go(context);
  }
}
