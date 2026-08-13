import 'package:app/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter_localizations/flutter_localizations.dart' as legacy;
import 'package:material_ui/material_ui.dart';

/// Localization delegates for Tinest's mixed standalone and legacy UI tree.
///
/// Tinyrack UI uses the standalone Material and Cupertino packages, while
/// dependencies such as `flutter_markdown_plus` still build legacy in-SDK
/// Material widgets. Their localization interfaces are distinct Dart types,
/// so both delegate families must be present until the dependency tree is
/// fully standalone.
const Iterable<LocalizationsDelegate<dynamic>> tinestLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      cupertino.GlobalCupertinoLocalizations.delegate,
      legacy.GlobalMaterialLocalizations.delegate,
      legacy.GlobalCupertinoLocalizations.delegate,
      legacy.GlobalWidgetsLocalizations.delegate,
    ];
