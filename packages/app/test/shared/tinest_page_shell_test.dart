import 'package:app/src/shared/presentation/tinest_page_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../support/localization.dart';

void main() {
  testWidgets('page surface stays edge to edge while content respects insets', (
    tester,
  ) async {
    const viewport = Size(400, 600);
    const insets = EdgeInsets.fromLTRB(20, 40, 10, 30);
    EdgeInsets? childPadding;

    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _host(
        padding: insets,
        body: Builder(
          builder: (context) {
            childPadding = MediaQuery.paddingOf(context);
            return const SizedBox.expand(key: ValueKey<String>('body'));
          },
        ),
      ),
    );

    final shell = find.byType(TRAppShell);
    final surface = find.descendant(
      of: find.byType(TinestPageShell),
      matching: find.byType(ColoredBox),
    );

    expect(tester.getRect(surface.first), Offset.zero & viewport);
    expect(tester.getRect(shell), const Rect.fromLTRB(20, 40, 390, 570));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('title'))).dy,
      greaterThanOrEqualTo(40),
    );
    expect(childPadding, EdgeInsets.zero);
  });

  testWidgets('zero-inset desktop layout remains full size', (tester) async {
    const viewport = Size(1200, 900);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _host(padding: EdgeInsets.zero, body: const SizedBox.expand()),
    );

    expect(
      tester.getRect(find.byType(TRAppShell)),
      Offset.zero & viewport,
    );
  });

  testWidgets(
    'mobile input and primary action remain above the software keyboard',
    (tester) async {
      const viewport = Size(390, 760);
      const safeArea = EdgeInsets.only(top: 24, bottom: 16);
      const keyboardHeight = 300.0;
      const fieldKey = ValueKey<String>('focused-input');
      const actionKey = ValueKey<String>('primary-action');

      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          padding: safeArea,
          viewInsets: const EdgeInsets.only(bottom: keyboardHeight),
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TRTextField(key: fieldKey),
                TRButton(
                  key: actionKey,
                  onPressed: () {},
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byKey(fieldKey));
      await tester.pump();

      final keyboardTop = viewport.height - safeArea.bottom - keyboardHeight;
      expect(tester.getTopLeft(find.byKey(const ValueKey('title'))).dy, 28);
      expect(
        tester.getBottomLeft(find.byKey(fieldKey)).dy,
        lessThanOrEqualTo(keyboardTop),
      );
      expect(
        tester.getBottomLeft(find.byKey(actionKey)).dy,
        lessThanOrEqualTo(keyboardTop),
      );
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__soft_keyboard_visibility__widget'],
  );
}

Widget _host({
  required EdgeInsets padding,
  required Widget body,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) => MaterialApp(
  locale: testLocale,
  localizationsDelegates: testLocalizationsDelegates,
  supportedLocales: testSupportedLocales,
  theme: testLightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      size: const Size(400, 600),
      padding: padding,
      viewPadding: padding,
      viewInsets: viewInsets,
    ),
    child: child!,
  ),
  home: TinestPageShell(
    appBar: const TinestPageHeader(
      title: Text('Title', key: ValueKey<String>('title')),
    ),
    body: body,
  ),
);
