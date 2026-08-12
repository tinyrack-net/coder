import 'package:test/test.dart';
import 'package:tinest_quality/src/workload_planner.dart';

void main() {
  const workloads = <PackageWorkload>[
    PackageWorkload(name: 'daemon', suites: 61),
    PackageWorkload(name: 'app_support', suites: 18),
    PackageWorkload(name: 'client', suites: 8),
    PackageWorkload(name: 'protocol', suites: 5),
  ];

  for (final jobs in <int>[1, 4, 8, 32]) {
    test('allocates a bounded package plan for $jobs jobs', () {
      final allocation = allocatePackageJobs(workloads, jobs);

      expect(allocation.values, everyElement(greaterThanOrEqualTo(1)));
      if (jobs >= workloads.length) {
        expect(allocation.values.reduce((left, right) => left + right), jobs);
      }
      expect(allocation['daemon'], greaterThanOrEqualTo(allocation['client']!));
    });
  }

  test('equal fractional remainders are resolved by package name', () {
    final allocation = allocatePackageJobs(const <PackageWorkload>[
      PackageWorkload(name: 'zeta', suites: 1),
      PackageWorkload(name: 'alpha', suites: 1),
    ], 3);

    expect(allocation, <String, int>{'zeta': 1, 'alpha': 2});
  });
}
