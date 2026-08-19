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

  test('the dominant package gets a share of the whole budget', () {
    // Measured on CI: `Dart tests` spent 454 of its 454 seconds in `daemon`,
    // which holds 73% of the suites but was handed 5 of 14 slots. Reserving one
    // slot per package first and splitting only what is left gives the long
    // pole a minority of a budget it is the only real claimant on, and the
    // seven short packages then idle their slots for the rest of the job.
    const packages = <PackageWorkload>[
      PackageWorkload(name: 'daemon', suites: 88),
      PackageWorkload(name: 'tinest_quality', suites: 9),
      PackageWorkload(name: 'agent', suites: 6),
      PackageWorkload(name: 'cli', suites: 5),
      PackageWorkload(name: 'client', suites: 5),
      PackageWorkload(name: 'protocol', suites: 4),
      PackageWorkload(name: 'relay', suites: 3),
      PackageWorkload(name: 'relay_protocol', suites: 2),
    ];
    final allocation = allocatePackageJobs(packages, 14);

    // Seven packages must each keep a slot to run at all, so seven is the most
    // daemon can hold, and the plan that finishes soonest gives it all of them:
    // 88 suites over 7 slots beats 88 over 5 while nothing else waits longer.
    expect(allocation['daemon'], 7);
    expect(allocation.values.reduce((left, right) => left + right), 14);
  });

  test('a lone package receives the entire budget', () {
    // This is what sharding a package into its own job relies on.
    final allocation = allocatePackageJobs(const <PackageWorkload>[
      PackageWorkload(name: 'daemon', suites: 88),
    ], 14);

    expect(allocation, <String, int>{'daemon': 14});
  });

  test('equal fractional remainders are resolved by package name', () {
    final allocation = allocatePackageJobs(const <PackageWorkload>[
      PackageWorkload(name: 'zeta', suites: 1),
      PackageWorkload(name: 'alpha', suites: 1),
    ], 3);

    expect(allocation, <String, int>{'zeta': 1, 'alpha': 2});
  });
}
