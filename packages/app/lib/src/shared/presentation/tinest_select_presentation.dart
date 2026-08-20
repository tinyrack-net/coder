import 'package:app/src/shared/presentation/tinest_bottom_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Tinest-owned responsive presentation policy for selection controls.
///
/// The design system owns each presentation's geometry and snapshots the
/// resolved value while a Select is open. Tinest only chooses which
/// presentation the next open uses.
abstract final class TinestSelectPresentation {
  /// Resolves a sheet below the compact boundary and a layer otherwise.
  static TRSelectPresentation resolve(BuildContext context) =>
      TRAdaptiveWidthClass.fromWidth(MediaQuery.sizeOf(context).width) ==
          TRAdaptiveWidthClass.compact
      ? const TRSelectPresentation.sheet(
          maxExtent: tinestBottomSheetMaxExtent,
          // Tinest keeps this sheet intrinsic until its content cap.
          // ignore: avoid_redundant_argument_values
          snapPoints: <double>[],
          // The handle remains the only surface-owned drawer drag target.
          // ignore: avoid_redundant_argument_values
          showDragHandle: true,
        )
      : const TRSelectPresentation.layer(
          // A content width would size every popup to its shortest option, so
          // the same control opens at a different width per host. One fixed
          // width keeps the option list readable wherever a Select is used.
          //
          // Height is deliberately unstated: the design system caps the option
          // list on its own axis, and restating it here would be Tinest owning
          // a number it has no reason to choose.
          width: TRLayerWidth.fixed(TRMeasurements.overlayWidthSm),
          // Bottom-start follows the trigger in either text direction.
          // ignore: avoid_redundant_argument_values
          placement: TRLayerPlacement.bottomStart,
          // Root overlay keeps the popup clear of nested product surfaces.
          // ignore: avoid_redundant_argument_values
          useRootOverlay: true,
        );
}
