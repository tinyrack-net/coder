import 'dart:convert';

import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('session settings patch preserves omitted and explicit-null fields', () {
    const patch = SessionSettingsPatchDto(
      hasModel: true,
      hasReasoningEffort: true,
      mode: SessionMode.plan,
    );

    final decoded = SessionSettingsPatchDto.fromJson(
      jsonDecode(jsonEncode(patch.toJson())) as Map<String, dynamic>,
    );

    expect(decoded.hasModel, isTrue);
    expect(decoded.model, isNull);
    expect(decoded.hasReasoningEffort, isTrue);
    expect(decoded.reasoningEffort, isNull);
    expect(decoded.hasPermissionMode, isFalse);
    expect(decoded.mode, SessionMode.plan);
    expect(RpcMethod.sessionUpdateSettings, 'sessions.updateSettings');
  });
}
