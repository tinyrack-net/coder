import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

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
