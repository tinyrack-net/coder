import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/app/app_identity.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/hosts/application/host_controller.dart';
import 'package:app/src/features/hosts/application/relay_devices_controller.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/pairing_intent.dart';
import 'package:app/src/features/hosts/presentation/host_labels.dart';
import 'package:app/src/shared/presentation/coder_icons.dart';
import 'package:app/src/shared/presentation/coder_page_shell.dart';
import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:app/src/shared/presentation/workspace_skeletons.dart';
import 'package:client/client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:protocol/protocol.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Chooses a relay-first or advanced direct daemon connection.
class ConnectDaemonPage extends StatelessWidget {
  /// Creates the connection method page.
  const ConnectDaemonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cameraSupported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return _PairingTaskShell(
      title: l10n.relayConnectDaemonTitle,
      child: SettingsSection(
        title: l10n.relayConnectDaemonTitle,
        banner: TRAlert(
          title: TRText.inherit(l10n.relayConnectDaemonTitle),
          description: TRText.inherit(l10n.relayConnectDaemonDescription),
          icon: const Icon(CoderIcons.lock),
          variant: TRStatusVariant.info,
        ),
        children: <Widget>[
          if (cameraSupported)
            _ConnectionMethod(
              key: const ValueKey<String>('connect-daemon-scan'),
              icon: CoderIcons.scanQr,
              title: l10n.relayPairScan,
              description: l10n.relayConnectScanDescription,
              onTap: () => const PairingScanRoute().push<void>(context),
            ),
          _ConnectionMethod(
            key: const ValueKey<String>('connect-daemon-paste'),
            icon: CoderIcons.paste,
            title: l10n.relayConnectPasteTitle,
            description: l10n.relayConnectPasteDescription,
            onTap: () => const PairingLinkRoute().push<void>(context),
          ),
          _ConnectionMethod(
            key: const ValueKey<String>('connect-daemon-direct'),
            icon: CoderIcons.link,
            title: l10n.relayAdvancedDirect,
            description: l10n.relayConnectDirectDescription,
            onTap: () => const AdvancedNewHostRoute().push<void>(context),
          ),
        ],
      ),
    );
  }
}

class _ConnectionMethod extends StatelessWidget {
  const _ConnectionMethod({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TRCard(
    padding: TRCardPadding.none,
    child: SettingsRow(
      leading: Icon(icon),
      title: TRText.inherit(title),
      description: TRText.inherit(description),
      control: const Icon(CoderIcons.chevronRight),
      onTap: onTap,
    ),
  );
}

/// Accepts a connection link and opens the shared offer review page.
class PairingLinkPage extends ConsumerStatefulWidget {
  /// Creates the link entry page.
  const PairingLinkPage({super.key});

  @override
  ConsumerState<PairingLinkPage> createState() => _PairingLinkPageState();
}

class _PairingLinkPageState extends ConsumerState<PairingLinkPage> {
  final _link = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _PairingTaskShell(
      title: l10n.relayConnectPasteTitle,
      child: SettingsSection.form(
        title: l10n.relayConnectPasteTitle,
        children: <Widget>[
          if (_error != null)
            TRAlert(
              title: TRText.inherit(l10n.appSettingsConnectionFailed),
              description: TRText.inherit(_error!),
              icon: const Icon(CoderIcons.error),
              variant: TRStatusVariant.danger,
            ),
          TRTextField(
            key: const ValueKey<String>('relay-pair-link'),
            controller: _link,
            keyboardType: TextInputType.url,
            label: l10n.relayPairLink,
            placeholder: 'https://coder.tinyrack.net/pair#offer=…',
            onSubmitted: (_) => _review(),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TRButton(
              key: const ValueKey<String>('relay-pair-review'),
              intent: TRIntent.primary,
              onPressed: _review,
              child: TRText.inherit(l10n.relayPairAction),
            ),
          ),
        ],
      ),
    );
  }

  void _review() {
    final uri = Uri.tryParse(_link.text.trim());
    try {
      if (uri == null) throw const FormatException();
      PairingIntent.parse(uri, nowUtc: ref.read(appClockProvider).nowUtc());
      unawaited(context.push<void>(uri.toString()));
    } on FormatException {
      setState(
        () => _error = AppLocalizations.of(
          context,
        ).relayPairInvalid(AppIdentity.displayName),
      );
    }
  }
}

/// Scans a daemon's one-time connection QR code with the native camera.
class PairingScanPage extends ConsumerStatefulWidget {
  /// Creates the camera scanner page.
  const PairingScanPage({super.key});

  @override
  ConsumerState<PairingScanPage> createState() => _PairingScanPageState();
}

class _PairingScanPageState extends ConsumerState<PairingScanPage> {
  final _scanner = MobileScannerController();
  bool _handled = false;
  bool _cameraFailed = false;
  String? _scanError;

  @override
  void dispose() {
    unawaited(_scanner.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cameraSupported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return _PairingTaskShell(
      title: l10n.relayPairScan,
      child: SettingsSection(
        title: l10n.relayPairScan,
        children: <Widget>[
          if (_scanError != null)
            TRAlert(
              title: TRText.inherit(l10n.appSettingsConnectionFailed),
              description: TRText.inherit(_scanError!),
              icon: const Icon(CoderIcons.error),
              variant: TRStatusVariant.danger,
            ),
          if (!cameraSupported)
            TRAlert(
              title: TRText.inherit(l10n.relayPairScan),
              description: TRText.inherit(l10n.relayPairCameraUnavailable),
              icon: const Icon(CoderIcons.info),
              variant: TRStatusVariant.info,
            )
          else
            AspectRatio(
              aspectRatio: 1,
              child: MobileScanner(
                controller: _scanner,
                onDetect: _detected,
                errorBuilder: (context, error) {
                  _cameraFailed = true;
                  return TRAlert(
                    title: TRText.inherit(l10n.relayPairScan),
                    description: TRText.inherit(
                      l10n.relayPairCameraError(AppIdentity.displayName),
                    ),
                    icon: const Icon(CoderIcons.error),
                    variant: TRStatusVariant.danger,
                    actions: <Widget>[
                      TRButton(
                        key: const ValueKey<String>('relay-camera-retry'),
                        appearance: TRAppearance.outline,
                        onPressed: _retryCamera,
                        child: TRText.inherit(l10n.relayPairCameraRetry),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _retryCamera() async {
    if (!_cameraFailed) return;
    try {
      await _scanner.start();
      if (mounted) setState(() => _cameraFailed = false);
    } on MobileScannerException {
      if (mounted) {
        setState(
          () => _scanError = AppLocalizations.of(
            context,
          ).relayPairCameraError(AppIdentity.displayName),
        );
      }
    }
  }

  void _detected(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    final uri = raw == null ? null : Uri.tryParse(raw.trim());
    try {
      if (uri == null) throw const FormatException();
      PairingIntent.parse(uri, nowUtc: ref.read(appClockProvider).nowUtc());
      _handled = true;
      context.replace(uri.toString());
    } on FormatException {
      setState(
        () => _scanError = AppLocalizations.of(
          context,
        ).relayPairInvalid(AppIdentity.displayName),
      );
    }
  }
}

/// Reviews a locally validated offer before consuming its capability.
class PairOfferPage extends ConsumerStatefulWidget {
  /// Creates the review page for [pairingUrl].
  const PairOfferPage({required this.pairingUrl, super.key});

  /// Canonical URL including its fragment-only pairing capability.
  final Uri pairingUrl;

  @override
  ConsumerState<PairOfferPage> createState() => _PairOfferPageState();
}

class _PairOfferPageState extends ConsumerState<PairOfferPage> {
  final _deviceName = TextEditingController();
  PairingIntent? _intent;
  bool _pairing = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_deviceName.text.isEmpty) {
      _deviceName.text = ref.read(appServicesProvider).clientKind;
    }
    if (_intent == null && _error == null) {
      try {
        _intent = PairingIntent.parse(
          widget.pairingUrl,
          nowUtc: ref.read(appClockProvider).nowUtc(),
        );
      } on FormatException {
        _error = AppLocalizations.of(
          context,
        ).relayPairInvalid(AppIdentity.displayName);
      }
    }
  }

  @override
  void dispose() {
    _deviceName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final intent = _intent;
    return _PairingTaskShell(
      title: l10n.relayConfirmTitle,
      child: SettingsSection.form(
        title: l10n.relayConfirmTitle,
        banner: _error == null
            ? TRAlert(
                title: TRText.inherit(l10n.relayConfirmTitle),
                description: TRText.inherit(l10n.relayConfirmDescription),
                icon: const Icon(CoderIcons.lock),
                variant: TRStatusVariant.info,
              )
            : TRAlert(
                title: TRText.inherit(l10n.appSettingsConnectionFailed),
                description: TRText.inherit(_error!),
                icon: const Icon(CoderIcons.error),
                variant: TRStatusVariant.danger,
              ),
        children: <Widget>[
          if (intent != null) ...<Widget>[
            _PairingFact(
              label: l10n.relayConfirmDaemon,
              value: intent.serverId,
            ),
            _PairingFact(
              label: l10n.relayConfirmRelay,
              value: intent.relayUri.authority,
            ),
            _PairingFact(
              label: l10n.relayConfirmExpires,
              value: MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay.fromDateTime(intent.expiresAt.toLocal()),
              ),
            ),
            TRTextField(
              key: const ValueKey<String>('relay-device-name'),
              controller: _deviceName,
              label: l10n.relayPairDeviceName,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TRButton(
                key: const ValueKey<String>('relay-pair-submit'),
                intent: TRIntent.primary,
                loading: _pairing,
                loadingLabel: l10n.relayPairAction,
                onPressed: _pairing ? null : _pair,
                child: TRText.inherit(l10n.relayPairAction),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pair() async {
    final intent = _intent;
    if (intent == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _pairing = true;
      _error = null;
    });
    try {
      final profile = await ref
          .read(hostRegistryControllerProvider.notifier)
          .pairRemote(
            pairingUrl: intent.pairingUrl,
            deviceName: _deviceName.text.trim().isEmpty
                ? ref.read(appServicesProvider).clientKind
                : _deviceName.text.trim(),
          );
      if (mounted) DaemonConnectionsRoute(hostId: profile.id).go(context);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().toLowerCase().contains('expired')
            ? l10n.relayPairExpired
            : l10n.relayPairFailed;
      });
    } finally {
      if (mounted) setState(() => _pairing = false);
    }
  }
}

class _PairingFact extends StatelessWidget {
  const _PairingFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => TRCard(
    padding: TRCardPadding.none,
    child: SettingsRow(
      title: TRText.inherit(label),
      description: SelectionArea(child: TRText.inherit(value)),
      wrapsDescription: true,
    ),
  );
}

class _PairingTaskShell extends StatelessWidget {
  const _PairingTaskShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => CoderPageShell(
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
      title: TRText.inherit(title),
    ),
    body: SettingsScaffold(children: <Widget>[child]),
  );
}

/// Shows one daemon's transport, share offer, and approved relay devices.
class DaemonConnectionsPage extends ConsumerStatefulWidget {
  /// Creates the page for [hostId].
  const DaemonConnectionsPage({
    required this.hostId,
    this.embedded = false,
    super.key,
  });

  /// App-local daemon identifier.
  final String hostId;

  /// Whether the unified settings shell supplies page chrome.
  final bool embedded;

  @override
  ConsumerState<DaemonConnectionsPage> createState() =>
      _DaemonConnectionsPageState();
}

class _DaemonConnectionsPageState extends ConsumerState<DaemonConnectionsPage> {
  final _offerLink = TextEditingController();
  RelayPairingOfferDto? _offer;
  RelayStatusDto? _status;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _offerLink.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final devicesAsync = ref.watch(relayDevicesProvider(widget.hostId));
    final registry = ref.watch(hostRegistryControllerProvider).value;
    final runtime = registry?.runtimes[widget.hostId];
    final profile = registry?.profiles
        .where((item) => item.id == widget.hostId)
        .firstOrNull;
    final activeConnection = profile?.connections
        .where((connection) => connection.id == runtime?.activeConnectionId)
        .firstOrNull;
    final pathLabel = switch (activeConnection) {
      DirectHostConnection() => l10n.relayPathDirect,
      RelayHostConnection() => l10n.relayPathRelay,
      _ when runtime?.kind == HostKind.embedded => l10n.relayPathDirect,
      _ => null,
    };
    final body = SettingsScaffold(
      children: <Widget>[
        SettingsSection(
          title: l10n.settingsCategoryConnection,
          children: <Widget>[
            TRCard(
              padding: TRCardPadding.none,
              child: SettingsRow(
                leading: const Icon(CoderIcons.network),
                title: TRText.inherit(runtime?.label ?? widget.hostId),
                description: TRText.inherit(hostStatusText(l10n, runtime)),
                wrapsDescription: true,
                control: pathLabel == null && profile == null
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (pathLabel != null)
                            TRBadge(
                              variant: TRStatusVariant.info,
                              child: TRText.inherit(pathLabel),
                            ),
                          if (profile != null)
                            TRButton(
                              appearance: TRAppearance.ghost,
                              onPressed: () => EditHostRoute(
                                hostId: profile.id,
                              ).push<void>(context),
                              child: TRText.inherit(
                                l10n.appSettingsEditConnection,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
        SettingsSection.form(
          title: l10n.relayPairTitle,
          banner: _error == null
              ? TRAlert(
                  title: TRText.inherit(l10n.relayPairTitle),
                  description: TRText.inherit(l10n.relayDevicesDescription),
                  icon: const Icon(CoderIcons.lock),
                  variant: TRStatusVariant.info,
                )
              : TRAlert(
                  title: TRText.inherit(l10n.appSettingsConnectionFailed),
                  description: TRText.inherit(_error!),
                  icon: const Icon(CoderIcons.error),
                  variant: TRStatusVariant.danger,
                ),
          children: <Widget>[
            if (_status case RelayStatusDto(enabled: false))
              TRCard(
                padding: TRCardPadding.none,
                child: SettingsRow(
                  leading: const Icon(CoderIcons.cloud),
                  title: TRText.inherit(l10n.relayEnableTitle),
                  description: TRText.inherit(l10n.relayEnableDescription),
                  wrapsDescription: true,
                  control: TRButton(
                    key: const ValueKey<String>('relay-enable'),
                    intent: TRIntent.primary,
                    loading: _busy,
                    loadingLabel: l10n.relayEnableAction,
                    onPressed: _busy ? null : _enableAndCreate,
                    child: TRText.inherit(l10n.relayEnableAction),
                  ),
                ),
              )
            else if (_offer case final offer?) ...<Widget>[
              Center(
                child: TRQrCode(
                  data: offer.url,
                  semanticLabel: l10n.relayPairQrSemantics,
                  uiSize: TRUiSize.lg,
                ),
              ),
              TRTextField(
                controller: _offerLink,
                label: l10n.relayPairLink,
                readOnly: true,
              ),
              TRText.inherit(
                l10n.relayLinkExpires(
                  MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay.fromDateTime(offer.expiresAt.toLocal()),
                  ),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: TRSpacing.small,
                runSpacing: TRSpacing.extraSmall,
                children: <Widget>[
                  TRCopyButton(value: offer.url, idleLabel: l10n.commonCopy),
                  TRButton(
                    appearance: TRAppearance.outline,
                    onPressed: _busy
                        ? null
                        : () => unawaited(
                            SharePlus.instance.share(
                              ShareParams(text: offer.url),
                            ),
                          ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(CoderIcons.share),
                        const SizedBox(width: TRSpacing.extraSmall),
                        TRText(l10n.relayShare),
                      ],
                    ),
                  ),
                  TRButton(
                    key: const ValueKey<String>('relay-create-offer'),
                    intent: TRIntent.primary,
                    loading: _busy,
                    loadingLabel: l10n.relayRefreshLink,
                    onPressed: _busy ? null : _createOffer,
                    child: TRText.inherit(l10n.relayRefreshLink),
                  ),
                ],
              ),
            ] else if (_status?.enabled == true)
              const Center(child: TRSpinner()),
          ],
        ),
        _devicesSection(devicesAsync),
      ],
    );
    if (widget.embedded) return body;
    return CoderPageShell(
      appBar: CoderPageHeader(
        leading: TRIconButton(
          appearance: TRAppearance.ghost,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => closeTask(
            context,
            () => const DaemonSettingsRoute().go(context),
          ),
          icon: const Icon(CoderIcons.back),
        ),
        title: TRText.inherit(l10n.settingsCategoryConnection),
      ),
      body: body,
    );
  }

  Widget _devicesSection(AsyncValue<List<RelayDeviceDto>> devicesAsync) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.relayApprovedDevices,
      children: <Widget>[
        if (!devicesAsync.hasValue && devicesAsync.hasError)
          TRCard(
            padding: TRCardPadding.none,
            child: SettingsRow(
              title: TRText.inherit(l10n.appSettingsConnectionFailed),
              description: TRText.inherit('${devicesAsync.error}'),
            ),
          )
        else if (!devicesAsync.hasValue)
          TRCard(
            padding: TRCardPadding.none,
            child: Padding(
              padding: SettingsRow.contentPadding,
              child: ListRowsSkeleton(
                semanticLabel: l10n.settingsLoading,
                rows: 3,
              ),
            ),
          )
        else if (devicesAsync.requireValue.isEmpty)
          TRCard(
            padding: TRCardPadding.none,
            child: SettingsRow(title: TRText.inherit(l10n.relayNoDevices)),
          )
        else
          for (final device in devicesAsync.requireValue)
            TRCard(
              padding: TRCardPadding.none,
              child: SettingsRow(
                leading: const Icon(CoderIcons.computer),
                title: TRText.inherit(device.name),
                control: TRButton(
                  appearance: TRAppearance.ghost,
                  onPressed: _busy ? null : () => _revoke(device),
                  child: TRText.inherit(l10n.relayRevoke),
                ),
              ),
            ),
      ],
    );
  }

  Future<RelayApi> _relay() async {
    final registry = await ref.read(hostRegistryControllerProvider.future);
    final runtime = registry.runtimes[widget.hostId];
    if (runtime?.connected != true || runtime?.api == null) {
      throw const HostConnectionFailure.network(
        'Online daemon connection required.',
      );
    }
    return runtime!.api!.relay;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final status = await (await _relay()).getRelayStatus();
      if (!mounted) return;
      setState(() => _status = status);
      if (status.enabled) await _createOffer();
    } on Exception catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enableAndCreate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final relay = await _relay();
      final status = await relay.setRelayEnabled(enabled: true);
      final offer = await relay.createRelayPairingOffer();
      if (mounted) {
        _offerLink.text = offer.url;
        setState(() {
          _status = status;
          _offer = offer;
        });
      }
    } on Exception catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createOffer() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final offer = await (await _relay()).createRelayPairingOffer();
      if (mounted) {
        _offerLink.text = offer.url;
        setState(() => _offer = offer);
      }
    } on Exception catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(RelayDeviceDto device) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: TRText.inherit(l10n.relayRevokeTitle(device.name)),
        content: TRText.inherit(l10n.relayRevokeBody),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: TRText.inherit(l10n.commonCancel),
          ),
          TRButton(
            intent: TRIntent.primary,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(l10n.relayRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    final revoked = await ref
        .read(toastMessengerProvider)
        .run(
          () async => (await _relay()).revokeRelayDevice(device.id),
          failure: l10n.relayRevokeFailed,
          success: l10n.commonDeleted,
          id: 'relay-revoke',
        );
    if (revoked) ref.invalidate(relayDevicesProvider(widget.hostId));
    if (mounted) setState(() => _busy = false);
  }
}
