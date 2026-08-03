import 'package:coder_protocol/coder_protocol.dart';

/// Remote branches preferred as the base of a new worktree, in order.
const List<String> preferredBaseBranches = <String>[
  'origin/main',
  'origin/master',
];

/// Picks the base branch a new worktree should start from.
///
/// Remote refs win so the branch starts from the latest upstream commit; the
/// checked-out local branch is the offline fallback.
String? defaultBaseBranch(List<GitBranchDto> branches) {
  if (branches.isEmpty) return null;
  for (final preferred in preferredBaseBranches) {
    final match = branches
        .where((branch) => branch.isRemote && branch.name == preferred)
        .firstOrNull;
    if (match != null) return match.name;
  }
  final remoteDefault = branches
      .where((branch) => branch.isRemote && branch.isDefault)
      .firstOrNull;
  if (remoteDefault != null) return remoteDefault.name;
  final current = branches
      .where((branch) => !branch.isRemote && branch.current)
      .firstOrNull;
  if (current != null) return current.name;
  return branches.first.name;
}
