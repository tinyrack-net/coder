import 'package:test/test.dart';
import 'package:tinest_quality/src/resource_budget.dart';

void main() {
  group('QualityCommandOptions', () {
    test('uses detected logical processors by default', () {
      final options = QualityCommandOptions.parse(
        const <String>['--check'],
        environment: const <String, String>{},
        detectedJobs: 32,
      );

      expect(options.jobs, 32);
      expect(options.remaining, const <String>['--check']);
      expect(options.reportPath, isNull);
    });

    test('CLI jobs override the environment', () {
      final options = QualityCommandOptions.parse(
        const <String>['--jobs=8', '--report=timings.json', '--check'],
        environment: const <String, String>{'TINEST_JOBS': '4'},
        detectedJobs: 32,
      );

      expect(options.jobs, 8);
      expect(options.reportPath, 'timings.json');
      expect(options.remaining, const <String>['--check']);
    });

    test('uses a positive environment override', () {
      final options = QualityCommandOptions.parse(
        const <String>[],
        environment: const <String, String>{'TINEST_JOBS': '4'},
        detectedJobs: 32,
      );

      expect(options.jobs, 4);
    });

    test('rejects zero, negative, and non-numeric job counts', () {
      for (final value in <String>['0', '-1', 'many']) {
        expect(
          () => QualityCommandOptions.parse(
            <String>['--jobs=$value'],
            environment: const <String, String>{},
            detectedJobs: 8,
          ),
          throwsFormatException,
        );
      }
    });
  });
}
