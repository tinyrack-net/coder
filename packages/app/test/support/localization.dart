import 'package:app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Light Tinyrack theme used by every widget-test harness.
final ThemeData testLightTheme = TinyrackTheme.light();

/// Dark Tinyrack theme used by every widget-test harness.
final ThemeData testDarkTheme = TinyrackTheme.dark();

/// Finds an accessible Tinyrack icon action or menu trigger by its label.
Finder findAccessibleAction(String label) => find.byWidgetPredicate(
  (widget) =>
      (widget is TRIconButton && widget.label == label) ||
      (widget is TRMenu && widget.label == label) ||
      (widget is Icon && widget.semanticLabel == label),
  description: 'Tinyrack action labelled "$label"',
);

/// Locale every test renders in unless it is exercising the language setting.
///
/// Pinning it keeps assertions independent of the host machine's locale.
const Locale testLocale = Locale('ko');

/// Strings for [testLocale], for tests that call presentation helpers directly.
final AppLocalizations testL10n = lookupAppLocalizations(testLocale);

/// Delegates every test app needs to resolve [AppLocalizations].
const Iterable<LocalizationsDelegate<dynamic>> testLocalizationsDelegates =
    AppLocalizations.localizationsDelegates;

/// Locales every test app supports.
const Iterable<Locale> testSupportedLocales = AppLocalizations.supportedLocales;
