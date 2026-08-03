/// Slug used when a prompt carries no characters a Git branch may hold.
const String defaultWorktreeBranchName = 'session';

/// Longest generated slug before a de-duplication suffix is appended.
const int maxWorktreeBranchNameLength = 40;

final RegExp _unsafe = RegExp('[^a-z0-9._-]+');
final RegExp _repeatedDash = RegExp('-+');
final RegExp _edges = RegExp(r'^[-/.]+|[-/.]+$');

/// Derives a Git-safe branch name from the first prompt of a new workspace.
///
/// The rules mirror the daemon's own normalization so the branch keeps the name
/// shown to the user, and [existingBranchNames] is used to pick a free slug
/// instead of letting the daemon reject a duplicate worktree path.
String deriveWorktreeBranchName(
  String prompt, {
  Iterable<String> existingBranchNames = const <String>[],
}) {
  final base = _slug(prompt);
  final taken = existingBranchNames.map(_slug).toSet();
  if (!taken.contains(base)) return base;
  for (var suffix = 2; ; suffix += 1) {
    final candidate = '$base-$suffix';
    if (!taken.contains(candidate)) return candidate;
  }
}

String _slug(String value) {
  final line = value
      .split('\n')
      .map((entry) => entry.trim())
      .firstWhere((entry) => entry.isNotEmpty, orElse: () => '');
  var slug = line
      .toLowerCase()
      .replaceAll(_unsafe, '-')
      .replaceAll(_repeatedDash, '-')
      .replaceAll(_edges, '');
  if (slug.length > maxWorktreeBranchNameLength) {
    final cutsMidWord = slug[maxWorktreeBranchNameLength] != '-';
    slug = slug.substring(0, maxWorktreeBranchNameLength);
    final lastSeparator = slug.lastIndexOf('-');
    // Prefer a word boundary, but keep a long unbroken slug rather than
    // shrinking it to nothing.
    if (cutsMidWord && lastSeparator > 0) {
      slug = slug.substring(0, lastSeparator);
    }
    slug = slug.replaceAll(_edges, '');
  }
  // The daemon rejects these outright, so never send them.
  if (slug.endsWith('.lock')) slug = '$slug-branch';
  if (slug.isEmpty || slug.contains('..')) return defaultWorktreeBranchName;
  return slug;
}
