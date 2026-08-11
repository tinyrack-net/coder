import 'package:app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/localization.dart';

void main() {
  testWidgets(
    'the wide bar always keeps every setting label',
    tags: const <String>['feature_test__session_lifecycle__widget'],
    (tester) async {
      await _pump(
        tester,
        width: 1024,
        chips: _chips(model: 'Claude Opus 4.6 (extended thinking, 1M context)'),
      );

      expect(find.text('Agent'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
      expect(
        find.textContaining('Claude Opus 4.6'),
        findsOneWidget,
        reason: 'the long model remains a labelled control',
      );

      final model = tester.getSize(find.byKey(_modelKey)).width;
      final natural = _naturalWidth(
        tester,
        'Claude Opus 4.6 (extended thinking, 1M context)',
      );
      expect(
        model,
        greaterThan(
          TRControlMetrics.heightOf(TRUiSize.sm),
        ),
        reason: 'the model remains wider than an icon-only control',
      );
      expect(model, lessThan(natural));
    },
  );

  testWidgets(
    'the row is built at the size it is given',
    tags: const <String>['feature_test__session_lifecycle__widget'],
    (tester) async {
      await _pump(tester, width: 900, chips: _chips(model: 'Sonnet 4.6'));

      for (final key in <ValueKey<String>>[_agentKey, _modelKey, _modeKey]) {
        expect(
          tester.getSize(find.byKey(key)).height,
          TRControlMetrics.heightOf(TRUiSize.sm),
          reason: '${key.value} follows the row size',
        );
      }
    },
  );
}

const _agentKey = ValueKey<String>('composer-chip-agent');
const _modelKey = ValueKey<String>('composer-chip-model');
const _modeKey = ValueKey<String>('composer-chip-mode');

List<ComposerChipSpec> _chips({required String model}) => <ComposerChipSpec>[
  ComposerChipSpec(
    valueKey: _agentKey,
    icon: TinestIcons.agent,
    label: 'Agent',
    tooltip: 'Select agent',
    menuChildren: <Widget>[
      TRMenuItem(onPressed: () {}, child: const Text('Claude')),
    ],
  ),
  ComposerChipSpec(
    valueKey: _modelKey,
    icon: TinestIcons.memory,
    label: model,
    tooltip: 'Select model',
    menuChildren: <Widget>[
      TRMenuItem(onPressed: () {}, child: Text(model)),
    ],
  ),
  ComposerChipSpec(
    valueKey: _modeKey,
    icon: TinestIcons.checklist,
    label: 'Plan',
    tooltip: 'Toggle plan mode',
    onPressed: (_) {},
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required List<ComposerChipSpec> chips,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: testLightTheme,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ComposerChipBar(
              chips: chips,
              uiSize: TRUiSize.sm,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Width the label alone would take, in the style a chip renders it in.
double _naturalWidth(WidgetTester tester, String label) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: TRControlMetrics.labelStyleOf(TRUiSize.sm),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}
