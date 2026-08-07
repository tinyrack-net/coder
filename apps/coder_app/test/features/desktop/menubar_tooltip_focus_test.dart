import 'package:coder_app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

void main() {
  testWidgets(
    'a menubar menu stays open when a keyboard tooltip closes behind it',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TinyrackTheme.dark(),
          home: TRTooltipProvider(
            child: Scaffold(
              body: Column(
                children: <Widget>[
                  TRMenubar(
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
                  ComposerChip(
                    valueKey: const ValueKey<String>('project'),
                    icon: CoderIcons.folder,
                    label: 'Project',
                    tooltip: 'Select a project',
                    menuChildren: <Widget>[
                      TRMenuItem(onPressed: () {}, child: const Text('Add')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Tab traverses onto the project chip, which opens its tooltip after the
      // provider's open delay. The menubar triggers come first in traversal
      // order, so keep tabbing until the chip's tooltip shows.
      var reached = false;
      for (var attempt = 0; attempt < 10 && !reached; attempt += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        reached = find.text('Select a project').evaluate().isNotEmpty;
      }
      expect(
        reached,
        isTrue,
        reason: 'the chip tooltip should open on keyboard focus',
      );

      // Opening a menubar menu takes focus off the chip, so the tooltip starts
      // its close delay while the menu is open.
      await tester.tap(find.text('View'));
      await tester.pump();
      expect(
        find.text('Collapse sidebar'),
        findsOneWidget,
        reason: 'the menubar menu should open on tap',
      );

      // Past the tooltip close delay: dismissing the tooltip must not pull
      // focus back to the chip and dismiss the menu with it.
      await tester.pumpAndSettle();
      expect(
        find.text('Collapse sidebar'),
        findsOneWidget,
        reason: 'the menubar menu should survive the tooltip closing',
      );
    },
    tags: <String>['feature_test__desktop_window_chrome__widget'],
  );
}
