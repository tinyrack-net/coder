import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_list_row.dart';
import 'package:coder_app/src/host_labels.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/remote_path.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Debounce applied to free-text path edits before querying the daemon.
const Duration directoryBrowserDebounce = Duration(milliseconds: 200);

/// Opens the daemon-side directory browser and returns the chosen path.
Future<String?> showDirectoryBrowser(
  BuildContext context, {
  required CoderApi api,
  required String initialPath,
}) => showTRDialog<String>(
  context: context,
  builder: (context) =>
      DirectoryBrowserDialog(api: api, initialPath: initialPath),
);

/// Walks daemon directories so a remote host can be browsed in the app.
class DirectoryBrowserDialog extends StatefulWidget {
  /// Creates the directory browser.
  const DirectoryBrowserDialog({
    required this.api,
    required this.initialPath,
    super.key,
  });

  /// Daemon whose filesystem is browsed.
  final CoderApi api;

  /// Directory listed when the dialog opens.
  final String initialPath;

  @override
  State<DirectoryBrowserDialog> createState() => _DirectoryBrowserDialogState();
}

class _DirectoryBrowserDialogState extends State<DirectoryBrowserDialog> {
  late final TextEditingController _path = TextEditingController(
    text: widget.initialPath,
  );
  List<DirectorySuggestionDto> _entries = const <DirectorySuggestionDto>[];
  bool _loading = true;
  String? _error;
  int _requestId = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    unawaited(_load(widget.initialPath));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _path.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parent = parentDirectoryPath(_path.text);
    return TRAlertDialog(
      title: Text(l10n.directoryBrowserTitle),
      content: SizedBox(
        width: 560,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TRTextField(
              key: const ValueKey('directory-browser-path'),
              controller: _path,
              autofocus: true,
              label: l10n.directoryBrowserPath,
              placeholder: '/home/you/repositories/project',
              onChanged: _onPathTyped,
            ),
            const SizedBox(height: 8),
            if (_loading) const TRProgress(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: ListView(
                children: <Widget>[
                  if (parent != null)
                    CoderListRow(
                      key: const ValueKey('directory-browser-parent'),
                      dense: true,
                      leading: const Icon(CoderIcons.uploadFolder),
                      title: const Text('..'),
                      onTap: () => unawaited(_open(parent)),
                    ),
                  for (final entry in _entries)
                    CoderListRow(
                      key: ValueKey('directory-browser-entry-${entry.path}'),
                      dense: true,
                      leading: const Icon(CoderIcons.folder),
                      title: Text(entry.name),
                      subtitle: Text(entry.path),
                      onTap: () => unawaited(_open(entry.path)),
                    ),
                  if (!_loading && _entries.isEmpty && _error == null)
                    CoderListRow(
                      dense: true,
                      title: Text(l10n.directoryBrowserEmpty),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <TRButton>[
        TRButton(
          appearance: TRAppearance.ghost,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TRButton(
          intent: TRIntent.primary,
          onPressed: () => Navigator.pop(context, _path.text.trim()),
          child: Text(l10n.directoryBrowserSelect),
        ),
      ],
    );
  }

  void _onPathTyped(String value) {
    _debounce?.cancel();
    _debounce = Timer(directoryBrowserDebounce, () => unawaited(_load(value)));
    setState(() {});
  }

  Future<void> _open(String path) async {
    _debounce?.cancel();
    _path.text = path;
    await _load(path);
  }

  Future<void> _load(String query) async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await widget.api.suggestDirectories(query, limit: 200);
      // A slower earlier request must never overwrite a newer listing.
      if (!mounted || id != _requestId) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } on CoderClientException catch (error) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }
}

/// Asks which daemon a new project should be registered on.
class DaemonPickerDialog extends StatelessWidget {
  /// Creates the daemon picker.
  const DaemonPickerDialog({required this.hosts, super.key});

  /// Online daemon runtimes offered to the user.
  final List<HostRuntimeSnapshot> hosts;

  @override
  Widget build(BuildContext context) => TRDialog(
    title: Text(AppLocalizations.of(context).directoryBrowserHostTitle),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final host in hosts)
          CoderListRow(
            onTap: () => Navigator.pop(context, host.id),
            leading: Icon(
              host.kind == HostKind.embedded
                  ? CoderIcons.computer
                  : CoderIcons.cloud,
            ),
            title: Text(hostLabel(AppLocalizations.of(context), host)),
          ),
      ],
    ),
  );
}

/// Picks the daemon to register on, skipping the prompt for a single host.
Future<String?> pickDaemonHost(
  BuildContext context,
  List<HostRuntimeSnapshot> online,
) async {
  if (online.isEmpty) return null;
  if (online.length == 1) return online.single.id;
  return showTRDialog<String>(
    context: context,
    builder: (context) => DaemonPickerDialog(hosts: online),
  );
}
