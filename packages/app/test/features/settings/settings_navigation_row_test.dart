import 'dart:ui' show Tristate;

import 'package:app/src/shared/presentation/settings_navigation_row.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

Widget _host(
  Widget child, {
  TRUiDensity density = TRUiDensity.standard,
  TextDirection textDirection = TextDirection.ltr,
}) => MaterialApp(
  theme: TinyrackTheme.light(),
  home: Directionality(
    textDirection: textDirection,
    child: Scaffold(
      body: TRUiDensityScope(
        density: density,
        child: SizedBox(width: 320, child: child),
      ),
    ),
  ),
);

AnimatedContainer _surface(WidgetTester tester, String label) =>
    tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

Color? _surfaceColor(WidgetTester tester, String label) =>
    (_surface(tester, label).decoration as BoxDecoration?)?.color;

void main() {
  testWidgets('points the destination chevron toward logical forward', (
    tester,
  ) async {
    Widget row() => SettingsNavigationRow(
      title: const Text('Project'),
      onPressed: () {},
    );

    await tester.pumpWidget(_host(row()));
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronLeft), findsNothing);

    await tester.pumpWidget(
      _host(row(), textDirection: TextDirection.rtl),
    );
    expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
  });

  testWidgets(
    'shares selected, hover, pressed, keyboard, and semantics behavior',
    (tester) async {
      var activations = 0;
      await tester.pumpWidget(
        _host(
          SettingsNavigationRow(
            title: const Text('Project'),
            selected: true,
            onPressed: () => activations += 1,
          ),
        ),
      );
      final theme = tester.element(find.text('Project')).tinyrackTheme;
      expect(_surfaceColor(tester, 'Project'), theme.surfaceHover);
      expect(
        tester.getSemantics(find.text('Project')).flagsCollection.isSelected,
        Tristate.isTrue,
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Project')));
      await tester.pumpAndSettle();
      await mouse.down(tester.getCenter(find.text('Project')));
      await tester.pump();
      expect(_surfaceColor(tester, 'Project'), theme.surfacePressed);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(activations, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(activations, 2);
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets('trailing control precedes chevron and does not navigate', (
    tester,
  ) async {
    var activations = 0;
    var changes = 0;
    await tester.pumpWidget(
      _host(
        SettingsNavigationRow(
          title: const Text('Skill'),
          trailing: TRSwitch(
            checked: false,
            onCheckedChange: (_) => changes += 1,
          ),
          onPressed: () => activations += 1,
        ),
      ),
    );

    final control = find.byType(TRSwitch);
    final chevron = find.byIcon(TinestIcons.chevronRight);
    expect(control, findsOneWidget);
    expect(chevron, findsOneWidget);
    expect(
      tester.getCenter(control).dx,
      lessThan(tester.getCenter(chevron).dx),
    );

    await tester.tap(control);
    await tester.pumpAndSettle();
    expect(changes, 1);
    expect(activations, 0);

    await tester.tap(find.text('Skill'));
    await tester.pumpAndSettle();
    expect(activations, 1);
  });

  testWidgets('inherits comfortable navigation geometry and typography', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SettingsNavigationRow(
          title: const Text('Project'),
          description: const Text('Repository settings'),
          leading: const Icon(
            TinestIcons.folder,
            key: ValueKey<String>('project-icon'),
          ),
          onPressed: () {},
        ),
        density: TRUiDensity.comfortable,
      ),
    );

    expect(_surface(tester, 'Project').constraints?.minHeight, 48);
    expect(
      DefaultTextStyle.of(tester.element(find.text('Project'))).style.fontSize,
      16,
    );
    expect(
      DefaultTextStyle.of(
        tester.element(find.text('Repository settings')),
      ).style.fontSize,
      14,
    );
    expect(
      IconTheme.of(
        tester.element(
          find.byKey(const ValueKey<String>('project-icon')),
        ),
      ).size,
      20,
    );
    expect(
      IconTheme.of(
        tester.element(find.byIcon(TinestIcons.chevronRight)),
      ).size,
      20,
    );
  });

  testWidgets('does not promise drill-down when the destination is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SettingsNavigationRow(
          title: Text('Unavailable skill'),
          enabled: false,
          onPressed: null,
        ),
      ),
    );

    expect(find.byIcon(TinestIcons.chevronRight), findsNothing);
  });
}
