/// Longest generated title before it is truncated with an ellipsis.
const int maxSessionTitleLength = 48;

/// Derives a session title from the first prompt typed into the composer.
///
/// The first non-empty line wins so a pasted multi-line request still reads as
/// one short tab label.
///
/// [fallback] is supplied by the caller rather than read here so this stays a
/// pure domain function: the title is stored on the session, and only the
/// presentation layer knows which language the reader chose.
String deriveSessionTitle(String prompt, {required String fallback}) {
  final line = prompt
      .split('\n')
      .map((value) => value.replaceAll(RegExp(r'\s+'), ' ').trim())
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  if (line.isEmpty) return fallback;
  if (line.length <= maxSessionTitleLength) return line;
  return '${line.substring(0, maxSessionTitleLength - 1).trimRight()}…';
}
