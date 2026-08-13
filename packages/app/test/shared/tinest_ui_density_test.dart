import 'package:app/src/shared/presentation/tinest_layout_metrics.dart';
import 'package:app/src/shared/presentation/tinest_ui_density.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

void main() {
  testWidgets('uses comfortable UI only below the compact breakpoint', (
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
    expect(_buttonHeight(tester), TRControlMetrics.heightOf(TRUiSize.xl));
    expect(_bodyFontSize(tester), 18);

    tester.view.physicalSize = const Size(
      TinestLayoutMetrics.compactBreakpoint,
      600,
    );
    await tester.pump();
    expect(_buttonHeight(tester), TRControlMetrics.heightOf(TRUiSize.md));
    expect(_bodyFontSize(tester), TRTypography.body.fontSize);

    tester.view.physicalSize = const Size(
      TinestLayoutMetrics.compactBreakpoint + 1,
      600,
    );
    await tester.pump();
    expect(_buttonHeight(tester), TRControlMetrics.heightOf(TRUiSize.md));
  });

  testWidgets('updates inherited UI size when the window is resized', (
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
    expect(_buttonHeight(tester), TRControlMetrics.heightOf(TRUiSize.xl));
    expect(_bodyFontSize(tester), 18);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not add a layout boundary above navigator overlays', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    expect(
      find.descendant(
        of: find.byType(TinestUiDensity),
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
  home: TinestUiDensity(
    child: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TRButton(
              uiSize: uiSize,
              onPressed: () {},
              child: const TRText.inherit('Continue'),
            ),
            const TRText('Readable'),
          ],
        ),
      ),
    ),
  ),
);

double _buttonHeight(WidgetTester tester) =>
    tester.getSize(find.byType(TRButton)).height;

double? _bodyFontSize(WidgetTester tester) =>
    tester.widget<Text>(find.text('Readable')).style?.fontSize;
