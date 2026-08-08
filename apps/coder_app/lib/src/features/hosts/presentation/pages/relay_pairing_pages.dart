import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/app/composition/app_providers.dart';
import 'package:coder_app/src/app/router/app_router.dart';
import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_app/src/shared/presentation/coder_page_shell.dart';
import 'package:coder_app/src/shared/presentation/settings_layout.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Registers this app as a device of a daemon using a one-time fragment URL.
class RemoteHostPairPage extends ConsumerStatefulWidget {
  /// Creates the relay pairing page.
  const RemoteHostPairPage({super.key});

  @override
  ConsumerState<RemoteHostPairPage> createState() => _RemoteHostPairPageState();
}

class _RemoteHostPairPageState extends ConsumerState<RemoteHostPairPage> {
  final _link = TextEditingController();
  final _deviceName = TextEditingController();
  bool _pairing = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_deviceName.text.isEmpty) {
      _deviceName.text = ref.read(appServicesProvider).clientKind;
    }
  }

  @override
  void dispose() {
    _link.dispose();
    _deviceName.dispose();
    super.dispose();
  }

  bool get _cameraSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        title: TRText.inherit(l10n.relayPairTitle),
      ),
      body: SettingsScaffold(
        children: <Widget>[
          SettingsSection.form(
            title: l10n.relayPairTitle,
            banner: TRAlert(
              title: TRText.inherit(l10n.relayPairTitle),
              description: TRText.inherit(l10n.relayPairDescription),
              icon: const Icon(CoderIcons.lock),
              variant: TRStatusVariant.info,
            ),
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
              ),
              TRTextField(
                key: const ValueKey<String>('relay-device-name'),
                controller: _deviceName,
                label: l10n.relayPairDeviceName,
              ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: TRSpacing.small,
                runSpacing: TRSpacing.extraSmall,
                children: <Widget>[
                  if (_cameraSupported)
                    TRButton(
                      key: const ValueKey<String>('relay-scan-qr'),
                      appearance: TRAppearance.outline,
                      onPressed: _pairing ? null : _scan,
                      child: TRText.inherit(l10n.relayPairScan),
                    ),
                  TRButton(
                    key: const ValueKey<String>('relay-pair-submit'),
                    intent: TRIntent.primary,
                    onPressed: _pairing ? null : _pair,
                    child: TRText.inherit(l10n.relayPairAction),
                  ),
                ],
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TRButton(
              appearance: TRAppearance.ghost,
              onPressed: () => const AdvancedNewHostRoute().replace(context),
              child: TRText.inherit(l10n.relayAdvancedDirect),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pair() async {
    final l10n = AppLocalizations.of(context);
    final url = Uri.tryParse(_link.text.trim());
    if (url == null ||
        url.scheme != 'https' ||
        url.host != 'coder.tinyrack.net' ||
        !url.fragment.startsWith('offer=')) {
      setState(() => _error = l10n.relayPairInvalid);
      return;
    }
    setState(() {
      _pairing = true;
      _error = null;
    });
    try {
      await ref
          .read(hostRegistryControllerProvider.notifier)
          .pairRemote(
            pairingUrl: url,
            deviceName: _deviceName.text.trim().isEmpty
                ? ref.read(appServicesProvider).clientKind
                : _deviceName.text.trim(),
          );
      if (mounted) const DaemonSettingsRoute().go(context);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().toLowerCase().contains('expired')
            ? l10n.relayPairExpired
            : '$error';
      });
    } finally {
      if (mounted) setState(() => _pairing = false);
    }
  }

  Future<void> _scan() async {
    final scanned = await showTRDialog<String>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: TRText.inherit(AppLocalizations.of(context).relayPairScan),
        content: AspectRatio(
          aspectRatio: 1,
          child: MobileScanner(
            onDetect: (capture) {
              final value = capture.barcodes.firstOrNull?.rawValue;
              if (value != null) Navigator.pop(context, value);
            },
            errorBuilder: (context, error, child) => TRAlert(
              title: TRText.inherit(
                AppLocalizations.of(context).relayPairScan,
              ),
              description: TRText.inherit(
                error.errorDetails?.message ?? '$error',
              ),
              icon: const Icon(CoderIcons.error),
              variant: TRStatusVariant.danger,
            ),
          ),
        ),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context),
            child: TRText.inherit(AppLocalizations.of(context).commonCancel),
          ),
        ],
      ),
    );
    if (scanned != null) {
      _link.text = scanned;
      await _pair();
    }
  }
}

/// Relay activation, offer generation, and approved-device management.
class DaemonDevicesPage extends ConsumerStatefulWidget {
  /// Creates the page for [hostId].
  const DaemonDevicesPage({required this.hostId, super.key});

  /// App-local daemon identifier.
  final String hostId;

  @override
  ConsumerState<DaemonDevicesPage> createState() => _DaemonDevicesPageState();
}

class _DaemonDevicesPageState extends ConsumerState<DaemonDevicesPage> {
  RelayPairingOfferDto? _offer;
  List<RelayDeviceDto>? _devices;
  String? _error;
  bool _busy = false;
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connected = ref
        .watch(hostRegistryControllerProvider)
        .value
        ?.runtimes[widget.hostId]
        ?.connected;
    if (connected == true && _devices == null && !_refreshing) {
      _refreshing = true;
      unawaited(_refresh());
    }
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
        title: TRText.inherit(l10n.relayDevicesTitle),
      ),
      body: SettingsScaffold(
        children: <Widget>[
          SettingsSection.form(
            title: l10n.relayDevicesTitle,
            banner: _error == null
                ? TRAlert(
                    title: TRText.inherit(l10n.relayDevicesTitle),
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
              if (_offer case final offer?) ...<Widget>[
                Center(
                  child: TRQrCode(
                    data: offer.url,
                    semanticLabel: l10n.relayPairQrSemantics,
                    uiSize: TRUiSize.lg,
                  ),
                ),
                SelectionArea(child: TRText.inherit(offer.url)),
                TRText.inherit(
                  l10n.relayLinkExpires(
                    MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay.fromDateTime(offer.expiresAt.toLocal()),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TRCopyButton(
                    value: offer.url,
                    idleLabel: l10n.commonCopy,
                  ),
                ),
              ],
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TRButton(
                  key: const ValueKey<String>('relay-create-offer'),
                  intent: TRIntent.primary,
                  onPressed: _busy ? null : _createOffer,
                  child: TRText.inherit(l10n.relayCreateLink),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: l10n.relayApprovedDevices,
            children: <Widget>[
              if (_devices == null)
                TRCard(
                  padding: TRCardPadding.none,
                  child: SettingsRow(
                    title: TRText.inherit(l10n.settingsLoading),
                  ),
                )
              else if (_devices!.isEmpty)
                TRCard(
                  padding: TRCardPadding.none,
                  child: SettingsRow(
                    title: TRText.inherit(l10n.relayNoDevices),
                  ),
                )
              else
                for (final device in _devices!)
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
          ),
        ],
      ),
    );
  }

  Future<RelayApi> _relay() async {
    final registry = await ref.read(hostRegistryControllerProvider.future);
    return connectedHostApi(registry.runtimes[widget.hostId]).relay;
  }

  Future<void> _refresh() async {
    try {
      final devices = await (await _relay()).listRelayDevices();
      if (mounted) setState(() => _devices = devices);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _createOffer() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final relay = await _relay();
      final status = await relay.getRelayStatus();
      if (!status.enabled) await relay.setRelayEnabled(enabled: true);
      final offer = await relay.createRelayPairingOffer();
      if (mounted) setState(() => _offer = offer);
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
    try {
      await (await _relay()).revokeRelayDevice(device.id);
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
