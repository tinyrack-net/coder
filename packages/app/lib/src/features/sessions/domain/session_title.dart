/// Fallback used when a prompt carries no readable title text.
const String defaultSessionTitle = 'Coding session';

/// Longest generated title before it is truncated with an ellipsis.
const int maxSessionTitleLength = 48;

/// Derives a session title from the first prompt typed into the composer.
///
/// The first non-empty line wins so a pasted multi-line request still reads as
/// one short tab label.
String deriveSessionTitle(String prompt) {
  final line = prompt
      .split('\n')
      .map((value) => value.replaceAll(RegExp(r'\s+'), ' ').trim())
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  if (line.isEmpty) return defaultSessionTitle;
  if (line.length <= maxSessionTitleLength) return line;
  return '${line.substring(0, maxSessionTitleLength - 1).trimRight()}…';
}
