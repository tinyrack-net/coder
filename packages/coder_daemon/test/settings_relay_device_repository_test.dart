import 'dart:convert';

import 'package:coder_daemon/src/features/relay/application/relay_pairing_service.dart';
import 'package:coder_daemon/src/features/relay/infrastructure/settings_relay_device_repository.dart';
import 'package:coder_daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:test/test.dart';

void main() {
  test(
    'SQLite settings adapter round-trips, replaces, and deletes devices',
    () async {
      final settings = _Settings();
      final repository = SettingsRelayDeviceRepository(settings);
      expect(await repository.list(), isEmpty);
      expect(await repository.get('missing'), isNull);

      final registered = RelayApprovedDevice(
        id: 'phone',
        name: 'Phone',
        publicKey: List<int>.filled(32, 4),
        registeredAt: DateTime.utc(2026, 8, 8),
        lastConnectedAt: null,
      );
      await repository.upsert(registered);
      expect((await repository.get('phone'))!.name, 'Phone');

      final connected = RelayApprovedDevice(
        id: 'phone',
        name: 'Renamed',
        publicKey: List<int>.filled(32, 4),
        registeredAt: registered.registeredAt,
        lastConnectedAt: DateTime.utc(2026, 8, 9),
      );
      await repository.upsert(connected);
      final listed = await repository.list();
      expect(listed, hasLength(1));
      expect(listed.single.name, 'Renamed');
      expect(listed.single.lastConnectedAt, DateTime.utc(2026, 8, 9));

      await repository.delete('phone');
      expect(await repository.list(), isEmpty);
    },
  );

  test('SQLite settings adapter rejects malformed persisted data', () async {
    final settings = _Settings();
    final repository = SettingsRelayDeviceRepository(settings);
    settings.value = '{}';
    await expectLater(repository.list(), throwsFormatException);
    settings.value = jsonEncode(<Object>['bad']);
    await expectLater(repository.list(), throwsFormatException);
    settings.value = jsonEncode(<Object>[
      <String, Object>{'id': 1},
    ]);
    await expectLater(repository.list(), throwsFormatException);
  });
}

final class _Settings implements SettingsRepository {
  String? value;

  @override
  Future<String?> getValue(String key) async => value;

  @override
  Future<void> setValue(String key, String value) async {
    this.value = value;
  }
}
