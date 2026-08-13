@Tags(<String>['feature_test__session_goal__widget'])
library;

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/features/conversation/presentation/goal_status_bar.dart';
import 'package:app/src/shared/presentation/tinest_ui_density.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/localization.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8);

  GoalDto goal({
    GoalStatus status = GoalStatus.active,
    int? budget = 1000,
  }) => GoalDto(
    sessionId: 'session',
    goalId: 'goal',
    objective: 'Implement the complete persistent session goal flow',
    status: status,
    tokenBudget: budget,
    tokensUsed: 250,
    timeUsedSeconds: 42,
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('renders plan hold, progress, and responsive controls', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    GoalStatus? selected;
    await tester.pumpWidget(
      _harness(
        GoalStatusBar(
          goal: goal(),
          sessionMode: SessionMode.plan,
          onEdit: () {},
          onStatusChanged: (value) => selected = value,
          onClear: () {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('goal-status-bar')), findsOneWidget);
    expect(find.text(testL10n.goalPlanHold), findsAtLeast(1));
    expect(find.textContaining('Implement the complete'), findsOneWidget);
    expect(
      tester
          .widget<TRCard>(
            find.byKey(const ValueKey('goal-status-bar')),
          )
          .padding,
      TRCardPadding.md,
    );
    expect(tester.widget<TRBadge>(find.byType(TRBadge)).uiSize, isNull);
    expect(tester.widget<TRProgress>(find.byType(TRProgress)).uiSize, isNull);
    for (final button in tester.widgetList<TRIconButton>(
      find.byType(TRIconButton),
    )) {
      expect(button.uiSize, isNull);
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel(testL10n.goalPause));
    expect(selected, GoalStatus.paused);
  });

  testWidgets('completed goal offers edit and clear without resume', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        GoalStatusBar(
          goal: goal(status: GoalStatus.complete, budget: null),
          sessionMode: SessionMode.normal,
          onEdit: () {},
          onStatusChanged: (_) {},
          onClear: () {},
        ),
      ),
    );

    expect(find.text(testL10n.goalStatusComplete), findsOneWidget);
    expect(find.bySemanticsLabel(testL10n.goalEdit), findsOneWidget);
    expect(find.bySemanticsLabel(testL10n.goalClear), findsOneWidget);
    expect(find.bySemanticsLabel(testL10n.goalResume), findsNothing);
  });
}

Widget _harness(Widget child) => MaterialApp(
  theme: testLightTheme,
  locale: testLocale,
  localizationsDelegates: testLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: TinestUiDensity(child: Scaffold(body: child)),
);
