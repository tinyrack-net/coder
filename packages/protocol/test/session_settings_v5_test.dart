import 'dart:convert';

import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('session settings patch preserves omitted and explicit-null fields', () {
    const patch = SessionSettingsPatchDto(
      hasModel: true,
      hasModelControls: true,
    );

    final decoded = SessionSettingsPatchDto.fromJson(
      jsonDecode(jsonEncode(patch.toJson())) as Map<String, dynamic>,
    );

    expect(decoded.hasModel, isTrue);
    expect(decoded.model, isNull);
    expect(decoded.hasModelControls, isTrue);
    expect(decoded.modelControls, isEmpty);
    expect(decoded.hasPermissionMode, isFalse);
    expect(decoded.toJson(), isNot(contains('mode')));
    expect(sessionsUpdateSettingsProcedure.name, 'sessions.updateSettings');
  });
}
