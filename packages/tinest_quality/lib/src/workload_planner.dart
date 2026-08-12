/// Test-suite workload used to divide a global process budget.
final class PackageWorkload {
  /// Creates one named package workload.
  const PackageWorkload({required this.name, required this.suites});

  /// Pub package name.
  final String name;

  /// Number of independently runnable test suites.
  final int suites;
}

/// Allocates [jobs] proportionally while keeping every package runnable.
Map<String, int> allocatePackageJobs(
  List<PackageWorkload> workloads,
  int jobs,
) {
  if (jobs <= 0) throw ArgumentError.value(jobs, 'jobs', 'must be positive');
  if (workloads.isEmpty) return const <String, int>{};
  if (workloads.any((workload) => workload.suites <= 0)) {
    throw ArgumentError.value(
      workloads,
      'workloads',
      'suites must be positive',
    );
  }
  final allocations = <String, int>{
    for (final workload in workloads) workload.name: 1,
  };
  final remaining = jobs - workloads.length;
  if (remaining <= 0) return allocations;
  final totalSuites = workloads.fold<int>(
    0,
    (sum, workload) => sum + workload.suites,
  );
  final remainders = <({String name, double remainder})>[];
  for (final workload in workloads) {
    final exact = remaining * workload.suites / totalSuites;
    final whole = exact.floor();
    allocations[workload.name] = allocations[workload.name]! + whole;
    remainders.add((name: workload.name, remainder: exact - whole));
  }
  var assigned = allocations.values.fold<int>(0, (sum, value) => sum + value);
  remainders.sort((left, right) {
    final remainder = right.remainder.compareTo(left.remainder);
    return remainder == 0 ? left.name.compareTo(right.name) : remainder;
  });
  for (var index = 0; assigned < jobs; index += 1) {
    final name = remainders[index % remainders.length].name;
    allocations[name] = allocations[name]! + 1;
    assigned += 1;
  }
  return allocations;
}
