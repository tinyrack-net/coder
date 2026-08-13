import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// The band behind a diff line, or null for an unchanged one.
Color? chatDiffSurface(BuildContext context, {required bool? added}) =>
    switch (added) {
      null => null,
      true => context.tinyrackTheme.surfaceForStatus(TRStatusVariant.success),
      false => context.tinyrackTheme.surfaceForStatus(TRStatusVariant.danger),
    };

/// The foreground of a diff line, or null for an unchanged one.
TRTextColor chatDiffForeground({required bool? added}) => switch (added) {
  null => TRTextColor.muted,
  true => TRTextColor.success,
  false => TRTextColor.danger,
};
