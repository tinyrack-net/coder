import 'package:app/src/shared/presentation/tinest_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

Widget _host({required EdgeInsets padding, required Widget body}) =>
    MaterialApp(
      locale: testLocale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      theme: testLightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: const Size(400, 600),
          padding: padding,
          viewPadding: padding,
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
