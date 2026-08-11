import 'package:app/src/shared/presentation/coder_layout_metrics.dart';
import 'package:flutter/widgets.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Selects Coder's semantic control density from the available window width.
///
/// The product owns the responsive policy while `tinyrack_ui` owns the
/// geometry of each density. This deliberately follows the existing compact
/// breakpoint on every platform instead of guessing from an input device.
class CoderControlDensity extends StatelessWidget {
  /// Creates the responsive density boundary around [child].
  const CoderControlDensity({required this.child, super.key});

  /// The application subtree that inherits the selected control density.
  final Widget child;

  @override
  Widget build(BuildContext context) => TRControlDensityScope(
    density:
        MediaQuery.sizeOf(context).width < CoderLayoutMetrics.compactBreakpoint
        ? TRControlDensity.comfortable
        : TRControlDensity.standard,
    child: child,
  );
}
