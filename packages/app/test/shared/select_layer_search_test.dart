import 'package:app/src/app/router/app_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../support/fake_tinest_api.dart';
import '../support/router_harness.dart';

Finder get _queryField => find.byType(TRTextField);

TextEditingController _query(WidgetTester tester) =>
    tester.widget<TRTextField>(_queryField).controller!;

/// Opens the language Select on the routed general settings page.
///
/// Tinest opens Selects into the root overlay, and an overlay child resolves
/// its focus parent outside the widget tree it is written in. That is the shape
/// that stopped delivering text editing keys to the query field, so the
/// expectations below go through the real router rather than a bare host.
Future<void> _openLanguageSelect(WidgetTester tester) async {
  final api = FakeTinestApi();
  addTearDown(api.close);
  await pumpRoutedApp(
    tester,
    api,
    initialLocation: const GeneralSettingsRoute().location,
  );
  await tester.tap(
    find.byKey(const ValueKey<String>('general-settings-language')),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'backspace erases a character from the Select layer query',
    tags: const <String>['feature_test__settings_language__widget'],
    (tester) async {
      await _openLanguageSelect(tester);

      // A host delivers printable characters over the text input channel and
      // Backspace as a key event. Only the key event proves the query field is
      // still reached by the app's text editing shortcuts.
      await tester.enterText(_queryField, 'kor');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(_query(tester).text, 'ko');
    },
  );

  testWidgets(
    'select all then delete clears the Select layer query',
    tags: const <String>['feature_test__settings_language__widget'],
    (tester) async {
      await _openLanguageSelect(tester);

      await tester.enterText(_queryField, 'kor');
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();

      expect(_query(tester).text, isEmpty);
    },
  );
}
