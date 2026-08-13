import 'dart:convert';

import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('session settings only carries a concrete model replacement', () {
    const patch = SessionSettingsPatchDto(
      model: ModelSelectionDto(modelId: 'openai/gpt-5.2'),
      hasModelControls: true,
      mode: SessionMode.plan,
    );

    final encoded = patch.toJson();
    final decoded = SessionSettingsPatchDto.fromJson(
      jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
    );

    expect(encoded, isNot(contains('hasModel')));
    expect(
      decoded.model,
      const ModelSelectionDto(modelId: 'openai/gpt-5.2'),
    );
    expect(decoded.hasModelControls, isTrue);
    expect(decoded.modelControls, isEmpty);
    expect(decoded.hasPermissionMode, isFalse);
    expect(decoded.mode, SessionMode.plan);
    expect(sessionsUpdateSettingsProcedure.name, 'sessions.updateSettings');
  });
}
