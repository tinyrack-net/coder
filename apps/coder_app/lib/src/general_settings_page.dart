import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Languages the app offers, keyed by language tag, in menu order.
///
/// Each one is named in its own script rather than in the active UI language,
/// so a reader who cannot read the current language can still find their own.
const Map<String, String> languageEndonyms = <String, String>{
  'ko': '한국어',
  'en': 'English',
};

/// App-wide preferences that do not belong to any single daemon.
class GeneralSettingsPage extends ConsumerWidget {
  /// Creates the general settings page.
  const GeneralSettingsPage({this.embedded = false, super.key});

  /// Whether the unified settings shell supplies navigation chrome.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final body = ListView(
      padding: const EdgeInsets.all(24),
      children: const <Widget>[
        _LanguageCard(),
        SizedBox(height: 24),
        _StartupCard(),
      ],
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsCategoryGeneral)),
      body: body,
    );
  }
}

/// Login-item preferences, shown only where the app can register one.
class _StartupCard extends ConsumerWidget {
  const _StartupCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final autostart = ref.watch(autostartProvider);
    // Mobile and plain widget tests have no login items, so offering a switch
    // that silently does nothing would be worse than offering none.
    if (autostart == null) return const SizedBox.shrink();
    final settings = ref
        .watch(hostRegistryControllerProvider)
        .asData
        ?.value
        .settings;
    final controller = ref.read(hostRegistryControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.generalStartupSection,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                key: const ValueKey<String>('general-settings-start-at-boot'),
                title: Text(l10n.generalStartupAtBootLabel),
                subtitle: Text(l10n.generalStartupAtBootDescription),
                value: settings?.startAtBoot ?? true,
                onChanged: settings == null
                    ? null
                    : (enabled) async {
                        await controller.setStartAtBoot(enabled: enabled);
                        await autostart.apply(
                          enabled: enabled,
                          minimized: settings.startMinimizedAtBoot,
                        );
                      },
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const ValueKey<String>(
                  'general-settings-start-minimized',
                ),
                title: Text(l10n.generalStartupMinimizedLabel),
                subtitle: Text(l10n.generalStartupMinimizedDescription),
                value: settings?.startMinimizedAtBoot ?? true,
                // Only a login launch can start minimized, so the choice is
                // meaningless while the app is not registered to launch.
                onChanged: settings == null || !settings.startAtBoot
                    ? null
                    : (minimized) async {
                        await controller.setStartMinimizedAtBoot(
                          enabled: minimized,
                        );
                        await autostart.apply(
                          enabled: settings.startAtBoot,
                          minimized: minimized,
                        );
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.generalStartupCloseNotice,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref
        .watch(hostRegistryControllerProvider)
        .asData
        ?.value
        .settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.generalLanguageSection,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DropdownButtonFormField<String?>(
                  key: const ValueKey<String>('general-settings-language'),
                  initialValue: settings?.localeTag,
                  decoration: InputDecoration(
                    labelText: l10n.generalLanguageLabel,
                  ),
                  items: <DropdownMenuItem<String?>>[
                    // A null tag follows the system locale.
                    DropdownMenuItem<String?>(
                      child: Text(l10n.generalLanguageSystem),
                    ),
                    for (final entry in languageEndonyms.entries)
                      DropdownMenuItem<String?>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: settings == null
                      ? null
                      : (tag) => ref
                            .read(hostRegistryControllerProvider.notifier)
                            .setLocaleTag(tag),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.generalLanguageDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
