import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Product layout measurements composed from public Tinyrack design tokens.
abstract final class CoderLayoutMetrics {
  /// Width below which list-detail surfaces show one pane at a time.
  static const double compactBreakpoint =
      TRMeasurements.measureXl + TRMeasurements.measureXl;

  /// Maximum width of a settings page's primary content column.
  static const double settingsContentMaxWidth = compactBreakpoint;

  /// Maximum width of a session's conversation timeline and composer column.
  ///
  /// The timeline owns an [TRSpacing.extraLarge] inset on each side, leaving
  /// two [TRMeasurements.measureXl] measures for the readable message body.
  static const double conversationContentMaxWidth =
      TRMeasurements.measureXl * 2 + TRSpacing.extraLarge * 2;

  /// Maximum width of a compact settings empty-state message.
  static const double settingsEmptyStateMaxWidth =
      TRMeasurements.measureXl +
      TRMeasurements.measureLg +
      TRSpacing.fourExtraLarge;

  /// Width of the global settings navigation pane.
  static const double settingsSidebarWidth =
      TRMeasurements.measureMd + TRSpacing.threeExtraLarge;

  /// Width of a settings collection in a list-detail surface.
  static const double settingsCollectionWidth =
      TRMeasurements.measureLg + TRSpacing.twoExtraLarge;

  /// Square size of the brand mark on the boot splash.
  static const double bootBrandMarkSize = TRMeasurements.measureXs;
}
