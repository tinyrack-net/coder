import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../support/localization.dart';

Finder _dialogSurface(Type dialogType) => find.descendant(
  of: find.byType(dialogType),
  matching: find.byWidgetPredicate(
    (widget) => widget is Material && widget.type == MaterialType.card,
  ),
);

void main() {
  for (final dialog in <({String title, Widget widget})>[
    (
      title: 'Long dialog',
      widget: const TRDialog(
        title: TRText.inherit('Long dialog'),
        content: SizedBox(key: ValueKey<String>('long-body'), height: 600),
        actions: TRText.inherit('Done'),
      ),
    ),
    (
      title: 'Long alert dialog',
      widget: const TRAlertDialog(
        title: TRText.inherit('Long alert dialog'),
        content: SizedBox(key: ValueKey<String>('long-body'), height: 600),
        actions: <TRButton>[
          TRButton(onPressed: null, child: TRText.inherit('Done')),
        ],
      ),
    ),
  ]) {
    testWidgets(
      '${dialog.widget.runtimeType} owns body scrolling at the surface edge',
      (tester) async {
        tester.view.physicalSize = const Size(420, 320);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: testLightTheme,
            home: Scaffold(body: Center(child: dialog.widget)),
          ),
        );

        expect(tester.takeException(), isNull);
        final dialogType = dialog.widget.runtimeType;
        final surface = tester.getRect(_dialogSurface(dialogType));
        final scrollbar = tester.getRect(
          find.descendant(
            of: find.byType(dialogType),
            matching: find.byType(Scrollbar),
          ),
        );
        expect(scrollbar.right, surface.right - TRControlMetrics.borderWidth);
        expect(
          tester.getTopLeft(find.byKey(const ValueKey<String>('long-body'))).dx,
          surface.left + TRSpacing.medium + TRControlMetrics.borderWidth,
        );

        final titleTop = tester.getTopLeft(find.text(dialog.title)).dy;
        final actionTop = tester.getTopLeft(find.text('Done')).dy;
        final bodyTop = tester
            .getTopLeft(find.byKey(const ValueKey<String>('long-body')))
            .dy;
        final scrollable = tester.state<ScrollableState>(
          find.descendant(
            of: find.byType(dialogType),
            matching: find.byType(Scrollable),
          ),
        );
        scrollable.position.jumpTo(80);
        await tester.pump();

        expect(tester.getTopLeft(find.text(dialog.title)).dy, titleTop);
        expect(tester.getTopLeft(find.text('Done')).dy, actionTop);
        expect(
          tester.getTopLeft(find.byKey(const ValueKey<String>('long-body'))).dy,
          bodyTop - 80,
        );
      },
    );
  }
}
