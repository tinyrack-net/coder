import 'dart:convert';
import 'dart:io';

/// The verification scope selected for a pull request.
enum CiChangeScope {
  /// Documentation changes do not need the quality matrix.
  docsOnly('docs-only'),

  /// Changes are confined to the independently deployed relay package.
  relayOnly('relay-only'),

  /// Changes are confined to the Flutter application package.
  appOnly('app-only'),

  /// Shared, mixed, or unknown changes require every quality gate.
  full('full');

  const CiChangeScope(this.outputValue);

  /// Stable value written to the GitHub Actions output.
  final String outputValue;

  /// Classifies the changed files reported for a pull request.
  ///
  /// An empty or malformed listing is deliberately treated as [full]. Shared
  /// packages, including `relay_protocol`, also remain in [full] because their
  /// reverse dependencies cross the relay/application boundary.
  static CiChangeScope forPullRequest(Iterable<String> changedFiles) {
    final files = changedFiles
        .map((file) => file.trim())
        .where((file) => file.isNotEmpty)
        .toList(growable: false);
    if (files.isEmpty) return full;
    if (files.every(_isDocumentation)) return docsOnly;
    if (files.every((file) => file.startsWith('packages/relay/'))) {
      return relayOnly;
    }
    if (files.every((file) => file.startsWith('packages/app/'))) {
      return appOnly;
    }
    return full;
  }

  static bool _isDocumentation(String file) =>
      file.startsWith('docs/') || file.endsWith('.md');
}

/// Reads one changed path per line and prints its conservative PR CI scope.
Future<void> main() async {
  final files = await stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .toList();
  stdout.writeln(CiChangeScope.forPullRequest(files).outputValue);
}
