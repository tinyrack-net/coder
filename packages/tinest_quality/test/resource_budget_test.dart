import 'package:test/test.dart';
import 'package:tinest_quality/src/resource_budget.dart';

void main() {
  group('resolveQualityJobs', () {
    test('uses detected logical processors by default', () {
      final jobs = resolveQualityJobs(
        cliJobs: null,
        environment: const <String, String>{},
        detectedJobs: 32,
      );

      expect(jobs, 32);
    });

    test('CLI jobs override the environment', () {
      final jobs = resolveQualityJobs(
        cliJobs: 8,
        environment: const <String, String>{'TINEST_JOBS': '4'},
        detectedJobs: 32,
      );

      expect(jobs, 8);
    });

    test('uses a positive environment override', () {
      final jobs = resolveQualityJobs(
        cliJobs: null,
        environment: const <String, String>{'TINEST_JOBS': '4'},
        detectedJobs: 32,
      );

      expect(jobs, 4);
    });

    test('rejects invalid environment job counts', () {
      for (final value in <String>['0', '-1', 'many']) {
        expect(
          () => resolveQualityJobs(
            cliJobs: null,
            environment: <String, String>{'TINEST_JOBS': value},
            detectedJobs: 8,
          ),
          throwsFormatException,
        );
      }
    });
  });
}
