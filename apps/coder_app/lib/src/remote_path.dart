/// Returns the parent of a daemon-side path, or null at the root.
///
/// The daemon may run on another platform, so its separator is not necessarily
/// the client's; both POSIX and Windows separators are accepted.
String? parentDirectoryPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return null;
  final normalized =
      trimmed.length > 1 && _isSeparator(trimmed[trimmed.length - 1])
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
  final index = _lastSeparator(normalized);
  if (index < 0) return null;
  if (index == 0) return normalized == '/' ? null : '/';
  return normalized.substring(0, index);
}

bool _isSeparator(String character) => character == '/' || character == r'\';

int _lastSeparator(String value) {
  final forward = value.lastIndexOf('/');
  final backward = value.lastIndexOf(r'\');
  return forward > backward ? forward : backward;
}
