import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

void main() {
  testWidgets('an open menubar menu draws no panel chrome around its surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TinyrackTheme.dark(),
        home: Scaffold(
          body: Center(
            child: TRMenubar(
              menus: <TRMenubarMenu>[
                TRMenubarMenu(
                  trigger: const Text('View'),
                  menuChildren: <Widget>[
                    TRMenuItem(
                      onPressed: () {},
                      child: const Text('Collapse sidebar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    final panel = find
        .ancestor(of: find.byType(TRMenuItem), matching: find.byType(Material))
        .first;
    final material = tester.widget<Material>(panel);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0);
    expect(
      tester.getRect(panel),
      tester.getRect(
        find.descendant(of: panel, matching: find.byType(Container)).first,
      ),
    );
  });
}
