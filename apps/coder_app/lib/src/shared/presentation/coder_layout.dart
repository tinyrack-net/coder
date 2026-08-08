import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Product-composite dimensions expressed entirely from public Tinyrack
/// scales.
///
/// These widths decide how Coder arranges its own panes; they are not reusable
/// control metrics and therefore do not belong in `tinyrack_ui`.
abstract final class CoderLayout {
  /// Width below which application panes use compact navigation.
  static const double compactBreakpoint = TRMeasurements.measureXl * 2;

  /// Width of the narrow top-level settings category rail.
  static const double settingsCategoryWidth =
      TRMeasurements.measureMd + TRSpacing.threeExtraLarge;

  /// Width of a settings feature's master list.
  static const double settingsListWidth =
      TRMeasurements.measureLg + TRSpacing.twoExtraLarge;

  /// Reading width of a dense settings form.
  static const double settingsReadingWidth = TRMeasurements.measureXl * 2;

  /// Reading width of explanatory settings prose.
  static const double settingsProseWidth =
      TRMeasurements.measureXl + TRMeasurements.overlayWidthSm;
}
