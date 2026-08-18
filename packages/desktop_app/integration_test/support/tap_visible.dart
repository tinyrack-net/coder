import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_until.dart';

/// Taps [finder] through the part of it the render view can actually hit.
///
/// Desktop window and text metrics can position an edge-adjacent control so
/// its center lands a fraction of a pixel outside the root render view. The
/// control's visible portion remains interactive, but `tester.tap` aims at the
/// center, silently misses, and the miss surfaces later as an unrelated
/// timeout. This helper waits until some part of [finder] is hit-testable and
/// taps that point instead.
Future<void> tapVisible(
  WidgetTester tester,
  Finder finder,
  String description, {
  Duration budget = e2eWaitBudget,
}) async {
  Offset? tapPoint;
  await pumpUntilCondition(
    tester,
    () {
      if (finder.evaluate().length != 1) return false;
      final targetRect = tester.getRect(finder);
      if (targetRect.isEmpty) return false;
      final viewRect = tester.binding.renderViews.single.paintBounds;
      final visibleRect = targetRect.intersect(viewRect);
      if (visibleRect.isEmpty) return false;

      final candidate = visibleRect.center;
      final alignment = Alignment(
        ((candidate.dx - targetRect.left) / targetRect.width) * 2 - 1,
        ((candidate.dy - targetRect.top) / targetRect.height) * 2 - 1,
      );
      if (finder.hitTestable(at: alignment).evaluate().length != 1) {
        return false;
      }
      tapPoint = candidate;
      return true;
    },
    'the visible part of $description to be hit-testable',
    budget: budget,
  );
  await tester.tapAt(tapPoint!);
}
