import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Back follows the surrounding text direction', (tester) async {
    Future<void> pump(TextDirection direction) => tester.pumpWidget(
      Directionality(
        textDirection: direction,
        child: Builder(
          builder: (context) => Icon(TinestIcons.backFor(context)),
        ),
      ),
    );

    await pump(TextDirection.ltr);
    expect(tester.widget<Icon>(find.byType(Icon)).icon, LucideIcons.arrowLeft);

    await pump(TextDirection.rtl);
    expect(tester.widget<Icon>(find.byType(Icon)).icon, LucideIcons.arrowRight);
  });
}
