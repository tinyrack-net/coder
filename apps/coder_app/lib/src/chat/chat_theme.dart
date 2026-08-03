import 'package:flutter/material.dart';

/// Diff line colors, which Material's [ColorScheme] does not define.
@immutable
final class ChatDiffColors extends ThemeExtension<ChatDiffColors> {
  /// Creates diff colors.
  const ChatDiffColors({
    required this.addedBackground,
    required this.addedForeground,
    required this.removedBackground,
    required this.removedForeground,
  });

  /// Colors used by the light theme.
  factory ChatDiffColors.light() => const ChatDiffColors(
    addedBackground: Color(0xffe3f5e5),
    addedForeground: Color(0xff17612a),
    removedBackground: Color(0xfffbe3e4),
    removedForeground: Color(0xff8c1d1d),
  );

  /// Colors used by the dark theme.
  factory ChatDiffColors.dark() => const ChatDiffColors(
    addedBackground: Color(0xff17311d),
    addedForeground: Color(0xff8fd79c),
    removedBackground: Color(0xff3a1c1e),
    removedForeground: Color(0xfff2a5a5),
  );

  /// Background of an added line.
  final Color addedBackground;

  /// Text color of an added line.
  final Color addedForeground;

  /// Background of a removed line.
  final Color removedBackground;

  /// Text color of a removed line.
  final Color removedForeground;

  @override
  ChatDiffColors copyWith({
    Color? addedBackground,
    Color? addedForeground,
    Color? removedBackground,
    Color? removedForeground,
  }) => ChatDiffColors(
    addedBackground: addedBackground ?? this.addedBackground,
    addedForeground: addedForeground ?? this.addedForeground,
    removedBackground: removedBackground ?? this.removedBackground,
    removedForeground: removedForeground ?? this.removedForeground,
  );

  @override
  ChatDiffColors lerp(ThemeExtension<ChatDiffColors>? other, double t) {
    if (other is! ChatDiffColors) return this;
    return ChatDiffColors(
      addedBackground: Color.lerp(addedBackground, other.addedBackground, t)!,
      addedForeground: Color.lerp(addedForeground, other.addedForeground, t)!,
      removedBackground: Color.lerp(
        removedBackground,
        other.removedBackground,
        t,
      )!,
      removedForeground: Color.lerp(
        removedForeground,
        other.removedForeground,
        t,
      )!,
    );
  }
}

/// Returns the diff colors of the active theme, falling back to the light set.
ChatDiffColors chatDiffColorsOf(BuildContext context) {
  final theme = Theme.of(context);
  return theme.extension<ChatDiffColors>() ??
      (theme.brightness == Brightness.dark
          ? ChatDiffColors.dark()
          : ChatDiffColors.light());
}

/// Monospace text style shared by tool titles, code, and diffs.
TextStyle chatMonospaceStyle(BuildContext context, {Color? color}) =>
    (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const <String>['Courier New', 'Menlo'],
      color: color,
      height: 1.45,
    );
