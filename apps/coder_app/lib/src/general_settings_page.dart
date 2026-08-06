import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/coder_page_shell.dart';
import 'package:coder_app/src/coder_selection_row.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/settings/settings_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

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
    const body = SettingsScaffold(
      children: <Widget>[
        _AppearanceSection(),
        _LanguageSection(),
        _StartupSection(),
      ],
    );
    if (embedded) return body;
    return CoderPageShell(
      appBar: CoderPageHeader(
        title: TRText.inherit(l10n.settingsCategoryGeneral),
      ),
      body: body,
    );
  }
}

/// Login-item preferences, shown only where the app can register one.
class _StartupSection extends ConsumerWidget {
  const _StartupSection();

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
    return SettingsSection(
      title: l10n.generalStartupSection,
      description: l10n.generalStartupCloseNotice,
      children: <Widget>[
        CoderSwitchRow(
          key: const ValueKey<String>('general-settings-start-at-boot'),
          title: TRText.inherit(l10n.generalStartupAtBootLabel),
          subtitle: TRText.inherit(l10n.generalStartupAtBootDescription),
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
        CoderSwitchRow(
          key: const ValueKey<String>('general-settings-start-minimized'),
          title: TRText.inherit(l10n.generalStartupMinimizedLabel),
          subtitle: TRText.inherit(l10n.generalStartupMinimizedDescription),
          value: settings?.startMinimizedAtBoot ?? true,
          // Only a login launch can start minimized, so the choice is
          // meaningless while the app is not registered to launch.
          onChanged: settings == null || !settings.startAtBoot
              ? null
              : (minimized) async {
                  await controller.setStartMinimizedAtBoot(enabled: minimized);
                  await autostart.apply(
                    enabled: settings.startAtBoot,
                    minimized: minimized,
                  );
                },
        ),
      ],
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref
        .watch(hostRegistryControllerProvider)
        .asData
        ?.value
        .settings;
    return SettingsSection(
      title: l10n.generalAppearanceSection,
      children: <Widget>[
        SettingsRow(
          title: TRText.inherit(l10n.generalAppearanceLabel),
          description: TRText.inherit(l10n.generalAppearanceDescription),
          wrapsDescription: true,
          // The row title names the control, so the field drops its own label
          // and carries the accessible name here instead.
          control: Semantics(
            label: l10n.generalAppearanceLabel,
            container: true,
            child: TRSelect<AppThemeMode>.controlled(
              key: const ValueKey<String>('general-settings-theme-mode'),
              value: settings?.themeMode ?? AppThemeMode.system,
              enabled: settings != null,
              items: <TRSelectItem<AppThemeMode>>[
                for (final mode in AppThemeMode.values)
                  TRSelectItem<AppThemeMode>(
                    value: mode,
                    label: _appearanceLabel(l10n, mode),
                  ),
              ],
              // Every item carries a mode, so a cleared field can only mean
              // the app should go back to following the system.
              onValueChange: settings == null
                  ? null
                  : (mode) => ref
                        .read(hostRegistryControllerProvider.notifier)
                        .setThemeMode(mode ?? AppThemeMode.system),
            ),
          ),
        ),
      ],
    );
  }
}

String _appearanceLabel(AppLocalizations l10n, AppThemeMode mode) =>
    switch (mode) {
      AppThemeMode.system => l10n.generalAppearanceSystem,
      AppThemeMode.light => l10n.generalAppearanceLight,
      AppThemeMode.dark => l10n.generalAppearanceDark,
    };

class _LanguageSection extends ConsumerWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref
        .watch(hostRegistryControllerProvider)
        .asData
        ?.value
        .settings;
    return SettingsSection(
      title: l10n.generalLanguageSection,
      children: <Widget>[
        SettingsRow(
          title: TRText.inherit(l10n.generalLanguageLabel),
          description: TRText.inherit(l10n.generalLanguageDescription),
          wrapsDescription: true,
          control: Semantics(
            label: l10n.generalLanguageLabel,
            container: true,
            child: TRSelect<String?>.controlled(
              key: const ValueKey<String>('general-settings-language'),
              value: settings?.localeTag,
              enabled: settings != null,
              placeholder: l10n.generalLanguageSystem,
              items: <TRSelectItem<String?>>[
                // A null tag follows the system locale.
                TRSelectItem<String?>(
                  value: null,
                  label: l10n.generalLanguageSystem,
                ),
                for (final entry in languageEndonyms.entries)
                  TRSelectItem<String?>(
                    value: entry.key,
                    label: entry.value,
                  ),
              ],
              onValueChange: settings == null
                  ? null
                  : (tag) => ref
                        .read(hostRegistryControllerProvider.notifier)
                        .setLocaleTag(tag),
            ),
          ),
        ),
      ],
    );
  }
}
