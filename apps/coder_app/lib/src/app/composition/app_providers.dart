import 'package:coder_app/src/app/composition/app_primitives.dart';
import 'package:coder_app/src/app/composition/app_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Platform composition supplied by desktop or mobile entrypoints.
final appServicesProvider = Provider<AppServices>(
  (ref) => throw StateError('AppServices must be overridden.'),
);

/// Clock used by application controllers.
final appClockProvider = Provider<AppClock>((ref) => const SystemAppClock());

/// Identifier generator used by application controllers.
final appIdGeneratorProvider = Provider<AppIdGenerator>(
  (ref) => const UuidAppIdGenerator(),
);
