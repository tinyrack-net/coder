/// Resource controls shared by Tinest quality commands.
final class QualityCommandOptions {
  /// Creates resolved common command options.
  const QualityCommandOptions({
    required this.jobs,
    required this.remaining,
    required this.reportPath,
  });

  /// Parses common options using CLI, environment, detected CPU precedence.
  factory QualityCommandOptions.parse(
    List<String> arguments, {
    required Map<String, String> environment,
    required int detectedJobs,
  }) {
    if (detectedJobs <= 0) {
      throw ArgumentError.value(
        detectedJobs,
        'detectedJobs',
        'must be positive',
      );
    }
    int? cliJobs;
    String? reportPath;
    final remaining = <String>[];
    for (final argument in arguments) {
      if (argument.startsWith('--jobs=')) {
        if (cliJobs != null) {
          throw const FormatException('--jobs may only be supplied once');
        }
        cliJobs = _positiveInt(argument.substring('--jobs='.length), '--jobs');
      } else if (argument.startsWith('--report=')) {
        if (reportPath != null) {
          throw const FormatException('--report may only be supplied once');
        }
        reportPath = argument.substring('--report='.length);
        if (reportPath.isEmpty) {
          throw const FormatException('--report requires a path');
        }
      } else {
        remaining.add(argument);
      }
    }
    final environmentValue = environment['TINEST_JOBS'];
    final environmentJobs = environmentValue == null
        ? null
        : _positiveInt(environmentValue, 'TINEST_JOBS');
    return QualityCommandOptions(
      jobs: cliJobs ?? environmentJobs ?? detectedJobs,
      remaining: List.unmodifiable(remaining),
      reportPath: reportPath,
    );
  }

  /// Effective global process budget.
  final int jobs;

  /// Command-specific arguments after common options are removed.
  final List<String> remaining;

  /// Optional machine-readable report destination.
  final String? reportPath;

  static int _positiveInt(String value, String source) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      throw FormatException('$source must be a positive integer');
    }
    return parsed;
  }
}
