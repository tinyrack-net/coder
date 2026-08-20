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
    // A session can no longer clear its permission mode back to an inherited
    // value, so an omitted mode is the only way to leave it unchanged and it
    // needs no has-flag to tell "clear" apart from "untouched".
    expect(decoded.permissionMode, isNull);
    expect(
      SessionSettingsPatchDto.fromJson(
        jsonDecode(
          jsonEncode(
            const SessionSettingsPatchDto(
              permissionMode: PermissionMode.workspaceWrite,
            ).toJson(),
          ),
        ) as Map<String, dynamic>,
      ).permissionMode,
      PermissionMode.workspaceWrite,
    );
    expect(sessionsUpdateSettingsProcedure.name, 'sessions.updateSettings');
  });
}
