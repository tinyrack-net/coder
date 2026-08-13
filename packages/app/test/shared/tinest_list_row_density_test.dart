import 'package:app/src/shared/presentation/tinest_list_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

void main() {
  testWidgets('adds vertical breathing room in comfortable density', (
    tester,
  ) async {
    await tester.pumpWidget(_host(TRUiDensity.standard));
    expect(
      _rowPadding(tester),
      const EdgeInsets.symmetric(
        horizontal: TRSpacing.small,
        vertical: TRSpacing.small,
      ),
    );

    await tester.pumpWidget(_host(TRUiDensity.comfortable));
    expect(
      _rowPadding(tester),
      const EdgeInsets.symmetric(
        horizontal: TRSpacing.small,
        vertical: TRSpacing.medium,
      ),
    );
    expect(
      DefaultTextStyle.of(
        tester.element(find.byKey(const ValueKey('row-title'))),
      ).style.fontSize,
      18,
    );
  });

  testWidgets('comfortable dense rows remain denser than regular rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TRUiDensity.comfortable,
        row: const TinestListRow(
          dense: true,
          title: TRText.inherit('Workspace'),
        ),
      ),
    );

    expect(
      _rowPadding(tester),
      const EdgeInsets.symmetric(
        horizontal: TRSpacing.small,
        vertical: TRSpacing.small,
      ),
    );
  });

  testWidgets('explicit row padding overrides comfortable density', (
    tester,
  ) async {
    const padding = EdgeInsets.all(TRSpacing.extraSmall);
    await tester.pumpWidget(
      _host(
        TRUiDensity.comfortable,
        row: const TinestListRow(
          contentPadding: padding,
          title: TRText.inherit('Workspace'),
        ),
      ),
    );

    expect(_rowPadding(tester), padding);
  });
}

Widget _host(
  TRUiDensity density, {
  Widget row = const TinestListRow(
    title: Text('Workspace', key: ValueKey('row-title')),
  ),
}) => MaterialApp(
  theme: TinyrackTheme.light(),
  home: Scaffold(
    body: TRUiDensityScope(density: density, child: row),
  ),
);

EdgeInsetsGeometry? _rowPadding(WidgetTester tester) => tester
    .widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(TinestListRow),
        matching: find.byWidgetPredicate(
          (widget) => widget is AnimatedContainer && widget.padding != null,
        ),
      ),
    )
    .padding;
