/// Conformance suites every vendor and tool package inherits with one call.
///
/// A new provider plugin or tool capability registers itself and runs these
/// against its own implementation, so the invariants the daemon relies on are
/// enforced by the package that could break them instead of being rediscovered
/// downstream one failure at a time.
library;

export 'src/testing/conformance.dart';
