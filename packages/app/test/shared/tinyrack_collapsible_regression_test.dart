import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

void main() {
  testWidgets(
    'an open collapsible can change size when animations are disabled',
    (tester) async {
      final itemCount = ValueNotifier<int>(1);
      addTearDown(itemCount.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: TinyrackTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: ListView(
              children: <Widget>[
                ValueListenableBuilder<int>(
                  valueListenable: itemCount,
                  builder: (context, count, child) => TRCollapsible(
                    defaultOpen: true,
                    trigger: const Text('Workspace'),
                    content: Column(
                      children: <Widget>[
                        for (var index = 0; index < count; index++)
                          Text('Worktree $index'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      itemCount.value = 2;
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Worktree 1'), findsOneWidget);
    },
  );
}
