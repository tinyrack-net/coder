import 'package:app/src/shared/presentation/tinest_control_density.dart';
import 'package:app/src/shared/presentation/tinest_layout_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

void main() {
  testWidgets('uses comfortable controls only below the compact breakpoint', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    tester.view.physicalSize = const Size(
      TinestLayoutMetrics.compactBreakpoint - 1,
      600,
    );
    await tester.pumpWidget(_host());
    expect(_buttonHeight(tester), TRControlMetrics.heightOf(TRUiSize.lg));

    tester.view.physicalSize = const Size(
      TinestLayoutMetrics.compactBreakpoint,
      600,
    );
    await tester.pump();
    expect(_buttonHeight(tester), TRControlMetrics.heightOf(TRUiSize.md));

    tester.view.physicalSize = const Size(
      TinestLayoutMetrics.compactBreakpoint + 1,
      600,
    );
    await tester.pump();
    expect(_buttonHeight(tester), TRControlMetrics.heightOf(TRUiSize.md));
  });

  testWidgets('updates inherited control size when the window is resized', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 600);
    await tester.pumpWidget(_host());
    expect(_buttonHeight(tester), TRControlMetrics.heightOf(TRUiSize.md));

    tester.view.physicalSize = const Size(390, 600);
    await tester.pump();
    expect(_buttonHeight(tester), TRControlMetrics.heightOf(TRUiSize.lg));
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not add a layout boundary above navigator overlays', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    expect(
      find.descendant(
        of: find.byType(TinestControlDensity),
        matching: find.byType(LayoutBuilder),
      ),
      findsNothing,
    );
  });

  testWidgets('preserves an explicitly small control on a narrow screen', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 600);
    await tester.pumpWidget(_host(uiSize: TRUiSize.sm));

    expect(_buttonHeight(tester), TRControlMetrics.heightOf(TRUiSize.sm));
  });
}

Widget _host({TRUiSize? uiSize}) => MaterialApp(
  theme: TinyrackTheme.light(),
  home: TinestControlDensity(
    child: Scaffold(
      body: Center(
        child: TRButton(
          uiSize: uiSize,
          onPressed: () {},
          child: const TRText.inherit('Continue'),
        ),
      ),
    ),
  ),
);

double _buttonHeight(WidgetTester tester) =>
    tester.getSize(find.byType(TRButton)).height;
